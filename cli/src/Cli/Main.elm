module Cli.Main exposing (main)

import Cli.Commands as Commands exposing (Endpoint)
import Cli.Flags as Flags
import Cli.Ports as Ports
import Cortex.Api.AgentConfig as AgentConfig
import Cortex.Api.ApiKeys as ApiKeys
import Cortex.Api.AssetGroups as AssetGroups
import Cortex.Api.Assets as Assets
import Cortex.Api.AttackSurface as AttackSurface
import Cortex.Api.AuditLogs as AuditLogs
import Cortex.Api.AuthSettings as AuthSettings
import Cortex.Api.Biocs as Biocs
import Cortex.Api.Cases as Cases
import Cortex.Api.Cli as Cli
import Cortex.Api.Correlations as Correlations
import Cortex.Api.DeviceControl as DeviceControl
import Cortex.Api.DisablePrevention as DisablePrevention
import Cortex.Api.Distributions as Distributions
import Cortex.Api.Endpoints as Endpoints
import Cortex.Api.Healthcheck as Healthcheck
import Cortex.Api.Indicators as Indicators
import Cortex.Api.Issues as Issues
import Cortex.Api.LegacyExceptions as LegacyExceptions
import Cortex.Api.Profiles as Profiles
import Cortex.Api.Quarantine as Quarantine
import Cortex.Api.Rbac as Rbac
import Cortex.Api.Risk as Risk
import Cortex.Api.ScheduledQueries as ScheduledQueries
import Cortex.Api.TenantInfo as TenantInfo
import Cortex.Api.TriagePresets as TriagePresets
import Cortex.Api.Xql as Xql
import Cortex.Auth as Auth
import Cortex.Client as Client exposing (Config)
import Cortex.Error exposing (Error)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Platform
import Process
import Task


type Model
    = Idle
    | Polling PollState


type alias PollState =
    { config : Config
    , queryId : String
    , limit : Maybe Int
    , format : Maybe String
    , intervalMs : Float
    }


type Msg
    = GotResponse (Result Error Encode.Value)
    | GotStartForPoll Config PollInit (Result Error String)
    | GotPollResult (Result Error Encode.Value)
    | PollTick


{-| Fields carried from the initial `--poll` startQuery dispatch into the
polling loop once the server returns a `query_id`.
-}
type alias PollInit =
    { limit : Maybe Int
    , format : Maybe String
    , intervalMs : Float
    }


main : Program Decode.Value Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        }


init : Decode.Value -> ( Model, Cmd Msg )
init flagsValue =
    case Decode.decodeValue Flags.decoder flagsValue of
        Ok flags ->
            let
                config =
                    Client.config
                        { tenant = flags.tenant
                        , credentials =
                            Auth.credentials
                                { apiKeyId = flags.apiKeyId
                                , apiKey = flags.apiKey
                                }
                        }

                stamp =
                    Auth.stamp
                        { timestamp = flags.timestamp
                        , nonce = flags.nonce
                        }
            in
            case Commands.argvToEndpoint flags.argv of
                Ok endpoint ->
                    run stamp config endpoint

                Err msg ->
                    ( Idle
                    , Cmd.batch
                        [ Ports.stderr (msg ++ "\n")
                        , Ports.exit 1
                        ]
                    )

        Err err ->
            ( Idle
            , Cmd.batch
                [ Ports.stderr ("Failed to decode flags: " ++ Decode.errorToString err ++ "\n")
                , Ports.exit 1
                ]
            )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotResponse result ->
            ( model, handleTerminal result )

        GotStartForPoll config init_ result ->
            case result of
                Ok queryId ->
                    let
                        state =
                            { config = config
                            , queryId = queryId
                            , limit = init_.limit
                            , format = init_.format
                            , intervalMs = init_.intervalMs
                            }
                    in
                    ( Polling state, sendPoll state )

                Err err ->
                    ( model
                    , Cmd.batch
                        [ Ports.stderr (Commands.errorToString err ++ "\n")
                        , Ports.exit 1
                        ]
                    )

        GotPollResult result ->
            case result of
                Ok value ->
                    if isPending value then
                        case model of
                            Polling state ->
                                ( model
                                , Process.sleep state.intervalMs
                                    |> Task.perform (always PollTick)
                                )

                            Idle ->
                                ( model, emitTerminal value )

                    else
                        ( model, emitTerminal value )

                Err err ->
                    ( model
                    , Cmd.batch
                        [ Ports.stderr (Commands.errorToString err ++ "\n")
                        , Ports.exit 1
                        ]
                    )

        PollTick ->
            case model of
                Polling state ->
                    ( model, sendPoll state )

                Idle ->
                    ( model, Cmd.none )


isPending : Encode.Value -> Bool
isPending value =
    Decode.decodeValue (Decode.field "status" Decode.string) value
        |> Result.map ((==) "PENDING")
        |> Result.withDefault False


emitTerminal : Encode.Value -> Cmd Msg
emitTerminal value =
    Cmd.batch
        [ Ports.stdout (Encode.encode 2 value ++ "\n")
        , Ports.exit 0
        ]


handleTerminal : Result Error Encode.Value -> Cmd Msg
handleTerminal result =
    case result of
        Ok value ->
            emitTerminal value

        Err err ->
            Cmd.batch
                [ Ports.stderr (Commands.errorToString err ++ "\n")
                , Ports.exit 1
                ]


sendPoll : PollState -> Cmd Msg
sendPoll state =
    Client.send state.config
        GotPollResult
        (pollRequest state)


pollRequest : PollState -> Request Encode.Value
pollRequest state =
    Xql.getQueryResults
        { queryId = state.queryId
        , pendingFlag = Nothing
        , limit = state.limit
        , format = state.format
        }
        |> Request.withDecoder rawDecoder


run : Auth.Stamp -> Config -> Endpoint -> ( Model, Cmd Msg )
run stamp config endpoint =
    let
        raw : Request a -> Cmd Msg
        raw req =
            Client.sendWith stamp config GotResponse (Request.withDecoder rawDecoder req)
    in
    case endpoint of
        Commands.Healthcheck ->
            ( Idle, raw Healthcheck.check )

        Commands.TenantInfo ->
            ( Idle, raw TenantInfo.get )

        Commands.CliVersion ->
            ( Idle, raw Cli.getVersion )

        Commands.EndpointsList args ->
            ( Idle, raw (Endpoints.list args) )

        Commands.AuditLogsSearch args ->
            ( Idle, raw (AuditLogs.search args) )

        Commands.AuditLogsAgentsReports ->
            ( Idle, raw AuditLogs.agentsReports )

        Commands.DistributionsGetVersions ->
            ( Idle, raw Distributions.getVersions )

        Commands.DistributionsList ->
            ( Idle, raw Distributions.getDistributions )

        Commands.DistributionsGetStatus id ->
            ( Idle, raw (Distributions.getStatus id) )

        Commands.DistributionsGetDistUrl id packageType ->
            ( Idle, raw (Distributions.getDistUrl { distributionId = id, packageType = packageType }) )

        Commands.TriagePresetsList ->
            ( Idle, raw TriagePresets.list )

        Commands.RbacGetUsers ->
            ( Idle, raw Rbac.getUsers )

        Commands.AuthSettingsGet ->
            ( Idle, raw AuthSettings.get )

        Commands.DeviceControlGetViolations ->
            ( Idle, raw DeviceControl.getViolations )

        Commands.AttackSurfaceGetRules ->
            ( Idle, raw AttackSurface.getRules )

        Commands.XqlGetQuota ->
            ( Idle, raw Xql.getQuota )

        Commands.XqlGetDatasets ->
            ( Idle, raw Xql.getDatasets )

        Commands.XqlLibraryGet ->
            ( Idle, raw Xql.getLibrary )

        Commands.XqlStartQuery args ->
            ( Idle
            , Client.sendWith stamp
                config
                GotResponse
                (Xql.startQuery args
                    |> Request.map
                        (\id -> Encode.object [ ( "query_id", Encode.string id ) ])
                )
            )

        Commands.XqlQueryPoll args intervalMs ->
            let
                init_ =
                    { limit = Nothing
                    , format = Nothing
                    , intervalMs = intervalMs
                    }
            in
            ( Idle
            , Client.sendWith stamp
                config
                (GotStartForPoll config init_)
                (Xql.startQuery args)
            )

        Commands.XqlGetResults args ->
            ( Idle, raw (Xql.getQueryResults args) )

        Commands.XqlGetResultsPoll args intervalMs ->
            let
                state =
                    { config = config
                    , queryId = args.queryId
                    , limit = args.limit
                    , format = args.format
                    , intervalMs = intervalMs
                    }
            in
            ( Polling state
            , Client.sendWith stamp config GotPollResult (pollRequest state)
            )

        Commands.XqlGetResultsStream args ->
            ( Idle, raw (Xql.getQueryResultsStream args) )

        Commands.XqlLookupsAddData args ->
            ( Idle, raw (Xql.lookupsAddData args) )

        Commands.XqlLookupsGetData args ->
            ( Idle, raw (Xql.lookupsGetData args) )

        Commands.XqlLookupsRemoveData args ->
            ( Idle, raw (Xql.lookupsRemoveData args) )

        Commands.ScheduledQueriesList args ->
            ( Idle, raw (ScheduledQueries.list args) )

        Commands.IndicatorsGet args ->
            ( Idle, raw (Indicators.get args) )

        Commands.BiocsGet args ->
            ( Idle, raw (Biocs.get args) )

        Commands.CorrelationsGet args ->
            ( Idle, raw (Correlations.get args) )

        Commands.IssuesSearch args ->
            ( Idle, raw (Issues.search args) )

        Commands.LegacyExceptionsGetModules ->
            ( Idle, raw LegacyExceptions.getModules )

        Commands.LegacyExceptionsFetch ->
            ( Idle, raw LegacyExceptions.fetch )

        Commands.ProfilesList profileType ->
            ( Idle, raw (Profiles.getProfiles { type_ = profileType }) )

        Commands.ProfilesGetPolicy endpointId ->
            ( Idle, raw (Profiles.getPolicy { endpointId = endpointId }) )

        Commands.AgentConfigContentManagement ->
            ( Idle, raw AgentConfig.getContentManagement )

        Commands.AgentConfigAutoUpgrade ->
            ( Idle, raw AgentConfig.getAutoUpgrade )

        Commands.AgentConfigWildfireAnalysis ->
            ( Idle, raw AgentConfig.getWildfireAnalysis )

        Commands.AgentConfigCriticalEnvironmentVersions ->
            ( Idle, raw AgentConfig.getCriticalEnvironmentVersions )

        Commands.AgentConfigAdvancedAnalysis ->
            ( Idle, raw AgentConfig.getAdvancedAnalysis )

        Commands.AgentConfigAgentStatus ->
            ( Idle, raw AgentConfig.getAgentStatus )

        Commands.AgentConfigInformativeBtpIssues ->
            ( Idle, raw AgentConfig.getInformativeBtpIssues )

        Commands.AgentConfigCortexXdrLogCollection ->
            ( Idle, raw AgentConfig.getCortexXdrLogCollection )

        Commands.AgentConfigActionCenterExpiration ->
            ( Idle, raw AgentConfig.getActionCenterExpiration )

        Commands.AgentConfigEndpointAdministrationCleanup ->
            ( Idle, raw AgentConfig.getEndpointAdministrationCleanup )

        Commands.RbacGetRoles roleName ->
            ( Idle, raw (Rbac.getRoles { roleNames = [ roleName ] }) )

        Commands.RbacGetUserGroups groupName ->
            ( Idle, raw (Rbac.getUserGroups { groupNames = [ groupName ] }) )

        Commands.ApiKeysList ->
            ( Idle, raw ApiKeys.getApiKeys )

        Commands.RiskScore id ->
            ( Idle, raw (Risk.getRiskScore { id = id }) )

        Commands.RiskUsers ->
            ( Idle, raw Risk.getRiskyUsers )

        Commands.RiskHosts ->
            ( Idle, raw Risk.getRiskyHosts )

        Commands.CasesSearch args ->
            ( Idle, raw (Cases.search args) )

        Commands.IssuesSchema ->
            ( Idle, raw Issues.schema )

        Commands.DisablePreventionFetch ->
            ( Idle, raw DisablePrevention.fetchRules )

        Commands.DisablePreventionFetchInjection ->
            ( Idle, raw DisablePrevention.fetchInjectionRules )

        Commands.DisablePreventionGetModules platform ->
            ( Idle, raw (DisablePrevention.getModules platform) )

        Commands.AssetsList ->
            ( Idle, raw Assets.list )

        Commands.AssetsSchema ->
            ( Idle, raw Assets.getSchema )

        Commands.AssetsExternalServices args ->
            ( Idle, raw (Assets.getExternalServices args) )

        Commands.AssetsInternetExposures args ->
            ( Idle, raw (Assets.getInternetExposures args) )

        Commands.AssetsIpRanges args ->
            ( Idle, raw (Assets.getExternalIpRanges args) )

        Commands.AssetsVulnerabilityTests args ->
            ( Idle, raw (Assets.getVulnerabilityTests args) )

        Commands.AssetsExternalWebsites args ->
            ( Idle, raw (Assets.getExternalWebsites args) )

        Commands.AssetsWebsitesLastAssessment ->
            ( Idle, raw Assets.getWebsitesLastAssessment )

        Commands.AssetGroupsList ->
            ( Idle, raw AssetGroups.list )

        Commands.QuarantineStatus query ->
            ( Idle, raw (Quarantine.getStatus [ query ]) )


{-| Most Cortex responses wrap their body in a top-level `reply` envelope,
but a handful (healthcheck, cli version, biocs, correlations, indicators)
do not. Unwrap when present, otherwise pass the value through.
-}
rawDecoder : Decoder Encode.Value
rawDecoder =
    Decode.oneOf
        [ Decode.field "reply" Decode.value
        , Decode.value
        ]
