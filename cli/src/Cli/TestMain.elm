module Cli.TestMain exposing (main)

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
import Json.Decode as Decode
import Platform


{-| Integration test runner for the typed SDK decoders. Same argv surface as
`cortex`, but instead of emitting the response body it runs each endpoint
through its typed decoder, evaluates a list of typed presence/value
assertions against the decoded record, and reports `ok` / `fail` to
stdout / stderr.

A `fail` means either:

  - the tenant returned JSON that the library's typed decoder could not parse
    (library/API have drifted at the structural level), or
  - the decoder accepted the JSON but a documented field decoded to `Nothing`,
    `0`, `""`, etc. (library/API have drifted at the value level — fields
    silently disappeared or returned degenerate values).

Endpoints that haven't opted in to value-level assertions still pass through
`typed` and only catch the first failure mode.

-}
type alias Assertion =
    { name : String
    , reason : Maybe String
    }


present : String -> Maybe a -> Assertion
present name m =
    case m of
        Just _ ->
            { name = name, reason = Nothing }

        Nothing ->
            { name = name, reason = Just "missing" }


nonEmpty : String -> List a -> Assertion
nonEmpty name xs =
    if List.isEmpty xs then
        { name = name, reason = Just "empty list" }

    else
        { name = name, reason = Nothing }


positive : String -> Maybe number -> Assertion
positive name m =
    case m of
        Just v ->
            if v > 0 then
                { name = name, reason = Nothing }

            else
                { name = name, reason = Just "expected > 0" }

        Nothing ->
            { name = name, reason = Just "missing" }


nonNegative : String -> Maybe number -> Assertion
nonNegative name m =
    case m of
        Just v ->
            if v >= 0 then
                { name = name, reason = Nothing }

            else
                { name = name, reason = Just "expected >= 0" }

        Nothing ->
            { name = name, reason = Just "missing" }


nonBlank : String -> Maybe String -> Assertion
nonBlank name m =
    case m of
        Just s ->
            if String.isEmpty s then
                { name = name, reason = Just "expected non-empty string" }

            else
                { name = name, reason = Nothing }

        Nothing ->
            { name = name, reason = Just "missing" }


satisfies : String -> Bool -> String -> Assertion
satisfies name passed reason =
    if passed then
        { name = name, reason = Nothing }

    else
        { name = name, reason = Just reason }


sampleFirst : String -> List a -> (a -> List Assertion) -> List Assertion
sampleFirst listName xs check =
    case List.head xs of
        Just x ->
            List.map
                (\a -> { a | name = listName ++ "[0]." ++ a.name })
                (check x)

        Nothing ->
            [ { name = listName, reason = Just "empty — cannot sample element fields" } ]


type Msg
    = Decoded String (Result Error (List Assertion))


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
        name =
            Commands.endpointName endpoint

        typed : Request a -> Cmd Msg
        typed req =
            Client.sendWith stamp config (Decoded name) (Request.map (\_ -> []) req)

        typedAssert : Request a -> (a -> List Assertion) -> Cmd Msg
        typedAssert req checks =
            Client.sendWith stamp config (Decoded name) (Request.map checks req)

        skip : Cmd Msg
        skip =
            Cmd.batch
                [ Ports.stdout ("ok: " ++ name ++ " (typed test skipped)\n")
                , Ports.exit 0
                ]
    in
    case endpoint of
        Commands.Healthcheck ->
            typedAssert Healthcheck.check
                (\r ->
                    [ satisfies "status" (not (String.isEmpty r.status)) "blank status"
                    ]
                )

        Commands.TenantInfo ->
            typedAssert TenantInfo.get
                (\t ->
                    [ present "xsiamPremiumExpiration" t.xsiamPremiumExpiration
                    , present "purchasedXsiamPremium" t.purchasedXsiamPremium
                    , nonNegative "installedPrevent" t.installedPrevent
                    ]
                        ++ (case t.purchasedXsiamPremium of
                                Just p ->
                                    [ positive "purchasedXsiamPremium.users" p.users
                                    , positive "purchasedXsiamPremium.agents" p.agents
                                    , positive "purchasedXsiamPremium.gb" p.gb
                                    ]

                                Nothing ->
                                    []
                           )
                )

        Commands.CliVersion ->
            typedAssert Cli.getVersion
                (\r ->
                    [ satisfies "version" (not (String.isEmpty r.version)) "blank version"
                    ]
                )

        Commands.EndpointsList args ->
            typed (Endpoints.list args)

        Commands.AuditLogsSearch args ->
            typed (AuditLogs.search args)

        Commands.AuditLogsAgentsReports ->
            typed AuditLogs.agentsReports

        Commands.DistributionsGetVersions ->
            typed Distributions.getVersions

        Commands.DistributionsList ->
            typed Distributions.getDistributions

        Commands.DistributionsGetStatus id ->
            typed (Distributions.getStatus id)

        Commands.DistributionsGetDistUrl id packageType ->
            typed (Distributions.getDistUrl { distributionId = id, packageType = packageType })

        Commands.TriagePresetsList ->
            typed TriagePresets.list

        Commands.RbacGetUsers ->
            typed Rbac.getUsers

        Commands.AuthSettingsGet ->
            typedAssert AuthSettings.get
                (\settings ->
                    [ nonEmpty "settings" settings
                    ]
                        ++ sampleFirst "settings"
                            settings
                            (\s ->
                                [ nonBlank "tenantId" s.tenantId
                                , nonBlank "spEntityId" s.spEntityId
                                , nonBlank "spUrl" s.spUrl
                                , nonBlank "spLogoutUrl" s.spLogoutUrl
                                ]
                            )
                )

        Commands.DeviceControlGetViolations ->
            typedAssert DeviceControl.getViolations
                (\r ->
                    [ nonNegative "totalCount" r.totalCount
                    , nonNegative "resultCount" r.resultCount
                    ]
                        ++ (if List.isEmpty r.violations then
                                -- legitimately empty on tenants with no peripheral activity
                                []

                            else
                                sampleFirst "violations"
                                    r.violations
                                    (\v ->
                                        [ positive "violationId" v.violationId
                                        , present "timestamp" v.timestamp
                                        , nonBlank "endpointId" v.endpointId
                                        ]
                                    )
                           )
                )

        Commands.AttackSurfaceGetRules ->
            typedAssert AttackSurface.getRules
                (\r ->
                    [ positive "totalCount" r.totalCount
                    , positive "resultCount" r.resultCount
                    , nonEmpty "attackSurfaceRules" r.attackSurfaceRules
                    ]
                        ++ sampleFirst "attackSurfaceRules"
                            r.attackSurfaceRules
                            (\rule ->
                                [ nonBlank "attackSurfaceRuleName" rule.attackSurfaceRuleName
                                , nonBlank "attackSurfaceRuleId" rule.attackSurfaceRuleId
                                , nonBlank "enabledStatus" rule.enabledStatus
                                , nonBlank "priority" rule.priority
                                , nonBlank "category" rule.category
                                , nonBlank "description" rule.description
                                ]
                            )
                )

        Commands.XqlGetQuota ->
            typedAssert Xql.getQuota
                (\q ->
                    [ positive "licenseQuota" q.licenseQuota
                    , nonNegative "additionalPurchasedQuota" q.additionalPurchasedQuota
                    , nonNegative "usedQuota" q.usedQuota
                    , nonNegative "dailyUsedQuota" q.dailyUsedQuota
                    , nonNegative "evalQuota" q.evalQuota
                    , nonNegative "totalDailyRunningQueries" q.totalDailyRunningQueries
                    , nonNegative "totalDailyConcurrentRejectedQueries" q.totalDailyConcurrentRejectedQueries
                    , nonNegative "currentConcurrentActiveQueriesCount" q.currentConcurrentActiveQueriesCount
                    , nonNegative "maxDailyConcurrentActiveQueryCount" q.maxDailyConcurrentActiveQueryCount
                    ]
                )

        Commands.XqlGetDatasets ->
            typed Xql.getDatasets

        Commands.XqlLibraryGet ->
            typed Xql.getLibrary

        Commands.XqlStartQuery args ->
            typed (Xql.startQuery args)

        Commands.XqlQueryPoll args _ ->
            -- Only validate the initial startQuery typed decode; the polling
            -- loop is a CLI-runtime concern, not a decoder concern.
            typed (Xql.startQuery args)

        Commands.XqlGetResults args ->
            typed (Xql.getQueryResults args)

        Commands.XqlGetResultsPoll args _ ->
            typed (Xql.getQueryResults args)

        Commands.XqlGetResultsStream _ ->
            -- Response is raw Encode.Value; nothing to typed-decode.
            skip

        Commands.XqlLookupsAddData _ ->
            -- Mutating endpoint; do not exercise against live tenants in the
            -- typed test runner.
            skip

        Commands.XqlLookupsGetData args ->
            typed (Xql.lookupsGetData args)

        Commands.XqlLookupsRemoveData _ ->
            skip

        Commands.ScheduledQueriesList args ->
            typedAssert (ScheduledQueries.list args)
                (\r ->
                    [ nonNegative "totalCount" r.totalCount
                    , nonNegative "filterCount" r.filterCount
                    ]
                        ++ (if List.isEmpty r.data then
                                []

                            else
                                sampleFirst "data"
                                    r.data
                                    (\sq ->
                                        [ nonBlank "queryDefId" sq.queryDefId
                                        , nonBlank "queryDefinitionName" sq.queryDefinitionName
                                        , present "enable" sq.enable
                                        ]
                                    )
                           )
                )

        Commands.IndicatorsGet args ->
            typedAssert (Indicators.get args)
                (\r ->
                    [ nonNegative "objectsCount" r.objectsCount
                    , nonBlank "objectsType" r.objectsType
                    ]
                        ++ (if List.isEmpty r.objects then
                                []

                            else
                                sampleFirst "objects"
                                    r.objects
                                    (\ind ->
                                        [ positive "ruleId" ind.ruleId
                                        , nonBlank "indicator" ind.indicator
                                        , nonBlank "type" ind.type_
                                        , nonBlank "severity" ind.severity
                                        ]
                                    )
                           )
                )

        Commands.BiocsGet args ->
            typedAssert (Biocs.get args)
                (\r ->
                    [ nonNegative "objectsCount" r.objectsCount
                    , nonBlank "objectsType" r.objectsType
                    ]
                        ++ (if List.isEmpty r.objects then
                                []

                            else
                                sampleFirst "objects"
                                    r.objects
                                    (\b ->
                                        [ positive "ruleId" b.ruleId
                                        , nonBlank "name" b.name
                                        , nonBlank "type" b.type_
                                        , nonBlank "severity" b.severity
                                        ]
                                    )
                           )
                )

        Commands.CorrelationsGet args ->
            typedAssert (Correlations.get args)
                (\r ->
                    [ nonNegative "objectsCount" r.objectsCount
                    , nonBlank "objectsType" r.objectsType
                    ]
                        ++ (if List.isEmpty r.objects then
                                []

                            else
                                sampleFirst "objects"
                                    r.objects
                                    (\c ->
                                        [ positive "id" c.id
                                        , nonBlank "name" c.name
                                        , nonBlank "severity" c.severity
                                        , nonBlank "xqlQuery" c.xqlQuery
                                        ]
                                    )
                           )
                )

        Commands.IssuesSearch args ->
            typedAssert (Issues.search args)
                (\r ->
                    [ nonEmpty "data" r.data
                    , nonNegative "totalCount" r.totalCount
                    , nonNegative "filterCount" r.filterCount
                    ]
                        ++ sampleFirst "data"
                            r.data
                            (\issue ->
                                [ positive "id" issue.id
                                , present "observationTime" issue.observationTime
                                ]
                            )
                )

        Commands.LegacyExceptionsGetModules ->
            typedAssert LegacyExceptions.getModules
                (\modules ->
                    nonEmpty "modules" modules
                        :: sampleFirst "modules"
                            modules
                            (\m ->
                                [ positive "moduleId" m.moduleId
                                , nonBlank "prettyName" m.prettyName
                                , nonBlank "title" m.title
                                , nonBlank "profileType" m.profileType
                                , nonEmpty "platforms" m.platforms
                                ]
                            )
                )

        Commands.LegacyExceptionsFetch ->
            typedAssert LegacyExceptions.fetch
                (\r ->
                    [ nonNegative "totalCount" r.totalCount
                    , nonNegative "filterCount" r.filterCount
                    ]
                        ++ (if List.isEmpty r.data then
                                -- legitimately empty when no exceptions configured
                                []

                            else
                                sampleFirst "data"
                                    r.data
                                    (\rule ->
                                        [ nonBlank "id" rule.id
                                        , nonBlank "ruleName" rule.ruleName
                                        , nonBlank "status" rule.status
                                        ]
                                    )
                           )
                )

        Commands.ProfilesList profileType ->
            typed (Profiles.getProfiles { type_ = profileType })

        Commands.ProfilesGetPolicy endpointId ->
            typed (Profiles.getPolicy { endpointId = endpointId })

        Commands.AgentConfigContentManagement ->
            typed AgentConfig.getContentManagement

        Commands.AgentConfigAutoUpgrade ->
            typed AgentConfig.getAutoUpgrade

        Commands.AgentConfigWildfireAnalysis ->
            typed AgentConfig.getWildfireAnalysis

        Commands.AgentConfigCriticalEnvironmentVersions ->
            typed AgentConfig.getCriticalEnvironmentVersions

        Commands.AgentConfigAdvancedAnalysis ->
            typed AgentConfig.getAdvancedAnalysis

        Commands.AgentConfigAgentStatus ->
            typed AgentConfig.getAgentStatus

        Commands.AgentConfigInformativeBtpIssues ->
            typed AgentConfig.getInformativeBtpIssues

        Commands.AgentConfigCortexXdrLogCollection ->
            typed AgentConfig.getCortexXdrLogCollection

        Commands.AgentConfigActionCenterExpiration ->
            typed AgentConfig.getActionCenterExpiration

        Commands.AgentConfigEndpointAdministrationCleanup ->
            typed AgentConfig.getEndpointAdministrationCleanup

        Commands.RbacGetRoles roleName ->
            typed (Rbac.getRoles { roleNames = [ roleName ] })

        Commands.RbacGetUserGroups groupName ->
            typed (Rbac.getUserGroups { groupNames = [ groupName ] })

        Commands.ApiKeysList ->
            typed ApiKeys.getApiKeys

        Commands.RiskScore id ->
            typed (Risk.getRiskScore { id = id })

        Commands.RiskUsers ->
            typed Risk.getRiskyUsers

        Commands.RiskHosts ->
            typed Risk.getRiskyHosts

        Commands.CasesSearch args ->
            typed (Cases.search args)

        Commands.IssuesSchema ->
            typedAssert Issues.schema
                (\fields ->
                    nonEmpty "schemaFields" fields
                        :: sampleFirst "schemaFields"
                            fields
                            (\f ->
                                [ nonBlank "fieldName" f.fieldName
                                , nonBlank "dataType" f.dataType
                                ]
                            )
                )

        Commands.DisablePreventionFetch ->
            typedAssert DisablePrevention.fetchRules
                (\r ->
                    [ nonNegative "totalCount" r.totalCount
                    , nonNegative "filterCount" r.filterCount
                    ]
                        ++ (if List.isEmpty r.data then
                                []

                            else
                                sampleFirst "data"
                                    r.data
                                    (\rule ->
                                        [ nonBlank "ruleId" rule.ruleId
                                        , nonBlank "ruleName" rule.ruleName
                                        , nonBlank "status" rule.status
                                        ]
                                    )
                           )
                )

        Commands.DisablePreventionFetchInjection ->
            typedAssert DisablePrevention.fetchInjectionRules
                (\r ->
                    [ nonNegative "totalCount" r.totalCount
                    , nonNegative "filterCount" r.filterCount
                    ]
                        ++ (if List.isEmpty r.data then
                                []

                            else
                                sampleFirst "data"
                                    r.data
                                    (\rule ->
                                        [ nonBlank "ruleId" rule.ruleId
                                        , nonBlank "ruleName" rule.ruleName
                                        ]
                                    )
                           )
                )

        Commands.DisablePreventionGetModules platform ->
            typedAssert (DisablePrevention.getModules platform)
                (\modules ->
                    nonEmpty "modules" modules
                        :: sampleFirst "modules"
                            modules
                            (\m ->
                                [ positive "moduleId" m.moduleId
                                , nonBlank "name" m.name
                                ]
                            )
                )

        Commands.AssetsList ->
            typed Assets.list

        Commands.AssetsSchema ->
            typed Assets.getSchema

        Commands.AssetsExternalServices args ->
            typed (Assets.getExternalServices args)

        Commands.AssetsInternetExposures args ->
            typed (Assets.getInternetExposures args)

        Commands.AssetsIpRanges args ->
            typed (Assets.getExternalIpRanges args)

        Commands.AssetsVulnerabilityTests args ->
            typed (Assets.getVulnerabilityTests args)

        Commands.AssetsExternalWebsites args ->
            typed (Assets.getExternalWebsites args)

        Commands.AssetsWebsitesLastAssessment ->
            typed Assets.getWebsitesLastAssessment

        Commands.AssetGroupsList ->
            typed AssetGroups.list

        Commands.QuarantineStatus query ->
            typed (Quarantine.getStatus [ query ])


handleResult : Msg -> Cmd Msg
handleResult (Decoded name result) =
    case result of
        Ok assertions ->
            let
                failures =
                    List.filterMap
                        (\a -> Maybe.map (\r -> a.name ++ ": " ++ r) a.reason)
                        assertions
            in
            if List.isEmpty failures then
                Cmd.batch
                    [ Ports.stdout ("ok: " ++ name ++ "\n")
                    , Ports.exit 0
                    ]

            else
                Cmd.batch
                    [ Ports.stderr ("fail: " ++ name ++ ": " ++ String.join "; " failures ++ "\n")
                    , Ports.exit 1
                    ]

        Err err ->
            Cmd.batch
                [ Ports.stderr ("fail: " ++ name ++ ": " ++ Commands.errorToString err ++ "\n")
                , Ports.exit 1
                ]
