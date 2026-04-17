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
import Cortex.Api.Rbac as Rbac
import Cortex.Api.Risk as Risk
import Cortex.Api.ScheduledQueries as ScheduledQueries
import Cortex.Api.TenantInfo as TenantInfo
import Cortex.Api.Xql as Xql
import Cortex.Auth as Auth
import Cortex.Client as Client exposing (Config)
import Cortex.Error exposing (Error)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Platform


type Msg
    = GotResponse (Result Error Encode.Value)


main : Program Decode.Value () Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        }


init : Decode.Value -> ( (), Cmd Msg )
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
                    ( (), run stamp config endpoint )

                Err msg ->
                    ( ()
                    , Cmd.batch
                        [ Ports.stderr (msg ++ "\n")
                        , Ports.exit 1
                        ]
                    )

        Err err ->
            ( ()
            , Cmd.batch
                [ Ports.stderr ("Failed to decode flags: " ++ Decode.errorToString err ++ "\n")
                , Ports.exit 1
                ]
            )


update : Msg -> () -> ( (), Cmd Msg )
update msg _ =
    ( (), handleResult msg )


run : Auth.Stamp -> Config -> Endpoint -> Cmd Msg
run stamp config endpoint =
    let
        raw : Request a -> Cmd Msg
        raw req =
            Client.sendWith stamp config GotResponse (Request.withDecoder rawDecoder req)
    in
    case endpoint of
        Commands.Healthcheck ->
            raw Healthcheck.check

        Commands.TenantInfo ->
            raw TenantInfo.get

        Commands.CliVersion ->
            raw Cli.getVersion

        Commands.EndpointsList ->
            raw Endpoints.list

        Commands.AuditLogsSearch ->
            raw AuditLogs.search

        Commands.AuditLogsAgentsReports ->
            raw AuditLogs.agentsReports

        Commands.DistributionsGetVersions ->
            raw Distributions.getVersions

        Commands.DistributionsList ->
            raw Distributions.getDistributions

        Commands.RbacGetUsers ->
            raw Rbac.getUsers

        Commands.AuthSettingsGet ->
            raw AuthSettings.get

        Commands.DeviceControlGetViolations ->
            raw DeviceControl.getViolations

        Commands.AttackSurfaceGetRules ->
            raw AttackSurface.getRules

        Commands.XqlGetQuota ->
            raw Xql.getQuota

        Commands.XqlGetDatasets ->
            raw Xql.getDatasets

        Commands.XqlLibraryGet ->
            raw Xql.getLibrary

        Commands.ScheduledQueriesList ->
            raw ScheduledQueries.list

        Commands.IndicatorsGet ->
            raw Indicators.get

        Commands.BiocsGet ->
            raw Biocs.get

        Commands.CorrelationsGet ->
            raw Correlations.get

        Commands.IssuesSearch ->
            raw Issues.search

        Commands.LegacyExceptionsGetModules ->
            raw LegacyExceptions.getModules

        Commands.LegacyExceptionsFetch ->
            raw LegacyExceptions.fetch

        Commands.ProfilesList profileType ->
            raw (Profiles.getProfiles { type_ = profileType })

        Commands.ProfilesGetPolicy endpointId ->
            raw (Profiles.getPolicy { endpointId = endpointId })

        Commands.AgentConfigContentManagement ->
            raw AgentConfig.getContentManagement

        Commands.AgentConfigAutoUpgrade ->
            raw AgentConfig.getAutoUpgrade

        Commands.AgentConfigWildfireAnalysis ->
            raw AgentConfig.getWildfireAnalysis

        Commands.AgentConfigCriticalEnvironmentVersions ->
            raw AgentConfig.getCriticalEnvironmentVersions

        Commands.AgentConfigAdvancedAnalysis ->
            raw AgentConfig.getAdvancedAnalysis

        Commands.RbacGetRoles roleName ->
            raw (Rbac.getRoles { roleNames = [ roleName ] })

        Commands.RbacGetUserGroups groupName ->
            raw (Rbac.getUserGroups { groupNames = [ groupName ] })

        Commands.ApiKeysList ->
            raw ApiKeys.getApiKeys

        Commands.RiskScore id ->
            raw (Risk.getRiskScore { id = id })

        Commands.RiskUsers ->
            raw Risk.getRiskyUsers

        Commands.RiskHosts ->
            raw Risk.getRiskyHosts

        Commands.CasesSearch ->
            raw Cases.search

        Commands.IssuesSchema ->
            raw Issues.schema

        Commands.DisablePreventionFetch ->
            raw DisablePrevention.fetchRules

        Commands.DisablePreventionFetchInjection ->
            raw DisablePrevention.fetchInjectionRules

        Commands.AssetsList ->
            raw Assets.list

        Commands.AssetsSchema ->
            raw Assets.getSchema

        Commands.AssetsExternalServices ->
            raw Assets.getExternalServices

        Commands.AssetsInternetExposures ->
            raw Assets.getInternetExposures

        Commands.AssetsIpRanges ->
            raw Assets.getExternalIpRanges

        Commands.AssetsVulnerabilityTests ->
            raw Assets.getVulnerabilityTests

        Commands.AssetsExternalWebsites ->
            raw Assets.getExternalWebsites

        Commands.AssetsWebsitesLastAssessment ->
            raw Assets.getWebsitesLastAssessment

        Commands.AssetGroupsList ->
            raw AssetGroups.list


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


handleResult : Msg -> Cmd Msg
handleResult (GotResponse result) =
    case result of
        Ok value ->
            Cmd.batch
                [ Ports.stdout (Encode.encode 2 value ++ "\n")
                , Ports.exit 0
                ]

        Err err ->
            Cmd.batch
                [ Ports.stderr (Commands.errorToString err ++ "\n")
                , Ports.exit 1
                ]
