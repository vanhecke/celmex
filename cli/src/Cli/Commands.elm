module Cli.Commands exposing
    ( Endpoint(..)
    , argvToEndpoint
    , endpointName
    , errorToString
    , usage
    )

import Cli.StandardFlags as StandardFlags
import Cortex.Api.Assets as Assets
import Cortex.Api.AuditLogs as AuditLogs
import Cortex.Api.Biocs as Biocs
import Cortex.Api.Cases as Cases
import Cortex.Api.Correlations as Correlations
import Cortex.Api.Endpoints as Endpoints
import Cortex.Api.Indicators as Indicators
import Cortex.Api.Issues as Issues
import Cortex.Api.ScheduledQueries as ScheduledQueries
import Cortex.Api.Xql as Xql
import Cortex.Error exposing (Error(..))
import Json.Decode as Decode
import Json.Encode as Encode


type Endpoint
    = Healthcheck
    | TenantInfo
    | CliVersion
    | EndpointsList Endpoints.SearchArgs
    | AuditLogsSearch AuditLogs.SearchArgs
    | AuditLogsAgentsReports
    | DistributionsGetVersions
    | DistributionsList
    | RbacGetUsers
    | AuthSettingsGet
    | DeviceControlGetViolations
    | AttackSurfaceGetRules
    | XqlGetQuota
    | XqlGetDatasets
    | XqlLibraryGet
    | XqlStartQuery Xql.StartQueryArgs
    | XqlQueryPoll Xql.StartQueryArgs Float
    | XqlGetResults Xql.GetResultsArgs
    | XqlGetResultsPoll Xql.GetResultsArgs Float
    | XqlGetResultsStream Xql.StreamArgs
    | XqlLookupsAddData Xql.LookupAddArgs
    | XqlLookupsGetData Xql.LookupGetArgs
    | XqlLookupsRemoveData Xql.LookupRemoveArgs
    | ScheduledQueriesList ScheduledQueries.SearchArgs
    | IndicatorsGet Indicators.SearchArgs
    | BiocsGet Biocs.SearchArgs
    | CorrelationsGet Correlations.SearchArgs
    | IssuesSearch Issues.SearchArgs
    | LegacyExceptionsGetModules
    | LegacyExceptionsFetch
    | ProfilesList String
    | ProfilesGetPolicy String
    | AgentConfigContentManagement
    | AgentConfigAutoUpgrade
    | AgentConfigWildfireAnalysis
    | AgentConfigCriticalEnvironmentVersions
    | AgentConfigAdvancedAnalysis
    | AgentConfigAgentStatus
    | AgentConfigInformativeBtpIssues
    | AgentConfigCortexXdrLogCollection
    | AgentConfigActionCenterExpiration
    | AgentConfigEndpointAdministrationCleanup
    | RbacGetRoles String
    | RbacGetUserGroups String
    | ApiKeysList
    | RiskScore String
    | RiskUsers
    | RiskHosts
    | CasesSearch Cases.SearchArgs
    | IssuesSchema
    | DisablePreventionFetch
    | DisablePreventionFetchInjection
    | AssetsList
    | AssetsSchema
    | AssetsExternalServices Assets.SearchArgs
    | AssetsInternetExposures Assets.SearchArgs
    | AssetsIpRanges Assets.SearchArgs
    | AssetsVulnerabilityTests Assets.SearchArgs
    | AssetsExternalWebsites Assets.SearchArgs
    | AssetsWebsitesLastAssessment
    | AssetGroupsList


argvToEndpoint : List String -> Result String Endpoint
argvToEndpoint args =
    case args of
        "xql" :: rest ->
            parseXql rest

        [ "healthcheck" ] ->
            Ok Healthcheck

        [ "tenant-info" ] ->
            Ok TenantInfo

        [ "cli", "version" ] ->
            Ok CliVersion

        "endpoints" :: "list" :: rest ->
            parseStandardSearch rest
                |> Result.map (\sa -> EndpointsList (toEndpointsArgs sa))

        "audit-logs" :: "search" :: rest ->
            parseStandardSearch rest
                |> Result.map (\sa -> AuditLogsSearch (toAuditLogsArgs sa))

        [ "audit-logs", "agents-reports" ] ->
            Ok AuditLogsAgentsReports

        [ "distributions", "get-versions" ] ->
            Ok DistributionsGetVersions

        [ "distributions", "list" ] ->
            Ok DistributionsList

        [ "rbac", "get-users" ] ->
            Ok RbacGetUsers

        [ "authentication-settings", "get" ] ->
            Ok AuthSettingsGet

        [ "device-control", "get-violations" ] ->
            Ok DeviceControlGetViolations

        [ "attack-surface", "get-rules" ] ->
            Ok AttackSurfaceGetRules

        [ "xql-library", "get" ] ->
            Ok XqlLibraryGet

        "scheduled-queries" :: "list" :: rest ->
            parseStandardSearch rest
                |> Result.map (\sa -> ScheduledQueriesList (toScheduledQueriesArgs sa))

        "indicators" :: "get" :: rest ->
            parseStandardSearch rest
                |> Result.map (\sa -> IndicatorsGet (toIndicatorsArgs sa))

        "bioc" :: "get" :: rest ->
            parseStandardSearch rest
                |> Result.map (\sa -> BiocsGet (toBiocsArgs sa))

        "correlations" :: "get" :: rest ->
            parseStandardSearch rest
                |> Result.map (\sa -> CorrelationsGet (toCorrelationsArgs sa))

        "issues" :: "search" :: rest ->
            parseStandardSearch rest
                |> Result.map (\sa -> IssuesSearch (toIssuesArgs sa))

        [ "legacy-exceptions", "get-modules" ] ->
            Ok LegacyExceptionsGetModules

        [ "legacy-exceptions", "fetch" ] ->
            Ok LegacyExceptionsFetch

        [ "profiles", "list", profileType ] ->
            Ok (ProfilesList profileType)

        [ "profiles", "get-policy", endpointId ] ->
            Ok (ProfilesGetPolicy endpointId)

        [ "agent-config", "content-management" ] ->
            Ok AgentConfigContentManagement

        [ "agent-config", "auto-upgrade" ] ->
            Ok AgentConfigAutoUpgrade

        [ "agent-config", "wildfire-analysis" ] ->
            Ok AgentConfigWildfireAnalysis

        [ "agent-config", "critical-environment-versions" ] ->
            Ok AgentConfigCriticalEnvironmentVersions

        [ "agent-config", "advanced-analysis" ] ->
            Ok AgentConfigAdvancedAnalysis

        [ "agent-config", "agent-status" ] ->
            Ok AgentConfigAgentStatus

        [ "agent-config", "informative-btp-issues" ] ->
            Ok AgentConfigInformativeBtpIssues

        [ "agent-config", "cortex-xdr-log-collection" ] ->
            Ok AgentConfigCortexXdrLogCollection

        [ "agent-config", "action-center-expiration" ] ->
            Ok AgentConfigActionCenterExpiration

        [ "agent-config", "endpoint-administration-cleanup" ] ->
            Ok AgentConfigEndpointAdministrationCleanup

        [ "rbac", "get-roles", roleName ] ->
            Ok (RbacGetRoles roleName)

        [ "rbac", "get-user-groups", groupName ] ->
            Ok (RbacGetUserGroups groupName)

        [ "api-keys", "list" ] ->
            Ok ApiKeysList

        [ "risk", "score", id ] ->
            Ok (RiskScore id)

        [ "risk", "users" ] ->
            Ok RiskUsers

        [ "risk", "hosts" ] ->
            Ok RiskHosts

        "cases" :: "search" :: rest ->
            parseStandardSearch rest
                |> Result.map (\sa -> CasesSearch (toCasesArgs sa))

        [ "issues", "schema" ] ->
            Ok IssuesSchema

        [ "disable-prevention", "fetch" ] ->
            Ok DisablePreventionFetch

        [ "disable-prevention", "fetch-injection" ] ->
            Ok DisablePreventionFetchInjection

        [ "assets", "list" ] ->
            Ok AssetsList

        [ "assets", "schema" ] ->
            Ok AssetsSchema

        "assets" :: "external-services" :: rest ->
            parseStandardSearch rest
                |> Result.map (\sa -> AssetsExternalServices (toAssetsArgs sa))

        "assets" :: "internet-exposures" :: rest ->
            parseStandardSearch rest
                |> Result.map (\sa -> AssetsInternetExposures (toAssetsArgs sa))

        "assets" :: "ip-ranges" :: rest ->
            parseStandardSearch rest
                |> Result.map (\sa -> AssetsIpRanges (toAssetsArgs sa))

        "assets" :: "vulnerability-tests" :: rest ->
            parseStandardSearch rest
                |> Result.map (\sa -> AssetsVulnerabilityTests (toAssetsArgs sa))

        "assets" :: "external-websites" :: rest ->
            parseStandardSearch rest
                |> Result.map (\sa -> AssetsExternalWebsites (toAssetsArgs sa))

        [ "assets", "websites-last-assessment" ] ->
            Ok AssetsWebsitesLastAssessment

        [ "asset-groups", "list" ] ->
            Ok AssetGroupsList

        _ ->
            Err (usage args)


parseXql : List String -> Result String Endpoint
parseXql sub =
    case sub of
        [ "get-quota" ] ->
            Ok XqlGetQuota

        [ "get-datasets" ] ->
            Ok XqlGetDatasets

        "query" :: rest ->
            parseXqlQueryCmd rest

        "get-results" :: rest ->
            parseXqlGetResultsCmd rest

        "get-results-stream" :: rest ->
            parseXqlStreamCmd rest

        "lookups" :: rest ->
            parseXqlLookups rest

        _ ->
            Err ("Unknown xql subcommand: xql " ++ String.join " " sub)


parseXqlQueryCmd : List String -> Result String Endpoint
parseXqlQueryCmd args =
    splitArgs [ "--poll" ] args
        |> Result.andThen
            (\( positionals, flags ) ->
                case positionals of
                    [ queryString ] ->
                        buildStartArgs queryString flags
                            |> Result.andThen
                                (\startArgs ->
                                    if hasFlag "--poll" flags then
                                        parseIntervalMs flags
                                            |> Result.map (XqlQueryPoll startArgs)

                                    else
                                        Ok (XqlStartQuery startArgs)
                                )

                    _ ->
                        Err "xql query: expected exactly one positional argument <QUERY>"
            )


parseXqlGetResultsCmd : List String -> Result String Endpoint
parseXqlGetResultsCmd args =
    splitArgs [ "--poll" ] args
        |> Result.andThen
            (\( positionals, flags ) ->
                case positionals of
                    [ queryId ] ->
                        buildResultsArgs queryId flags
                            |> Result.andThen
                                (\resArgs ->
                                    if hasFlag "--poll" flags then
                                        parseIntervalMs flags
                                            |> Result.map (XqlGetResultsPoll resArgs)

                                    else
                                        Ok (XqlGetResults resArgs)
                                )

                    _ ->
                        Err "xql get-results: expected exactly one positional argument <QUERY_ID>"
            )


parseXqlStreamCmd : List String -> Result String Endpoint
parseXqlStreamCmd args =
    splitArgs [ "--gzip" ] args
        |> Result.andThen
            (\( positionals, flags ) ->
                case positionals of
                    [ streamId ] ->
                        Ok
                            (XqlGetResultsStream
                                { streamId = streamId
                                , isGzipCompressed =
                                    if hasFlag "--gzip" flags then
                                        Just True

                                    else
                                        Nothing
                                }
                            )

                    _ ->
                        Err "xql get-results-stream: expected exactly one positional argument <STREAM_ID>"
            )


parseXqlLookups : List String -> Result String Endpoint
parseXqlLookups args =
    case args of
        "add-data" :: rest ->
            parseLookupsAdd rest

        "get-data" :: rest ->
            parseLookupsGet rest

        "remove-data" :: rest ->
            parseLookupsRemove rest

        _ ->
            Err "xql lookups: expected add-data | get-data | remove-data"


parseLookupsAdd : List String -> Result String Endpoint
parseLookupsAdd args =
    splitArgs [] args
        |> Result.andThen
            (\( positionals, flags ) ->
                case positionals of
                    [ dataset, jsonStr ] ->
                        parseJsonValue jsonStr
                            |> Result.map
                                (\data ->
                                    XqlLookupsAddData
                                        { datasetName = dataset
                                        , keyFields = parseCommaList "--key-fields" flags
                                        , data = data
                                        }
                                )

                    _ ->
                        Err "xql lookups add-data: expected two positional arguments <DATASET> <JSON>"
            )


parseLookupsGet : List String -> Result String Endpoint
parseLookupsGet args =
    splitArgs [] args
        |> Result.andThen
            (\( positionals, flags ) ->
                case positionals of
                    [ dataset ] ->
                        Result.map2
                            (\limit filters ->
                                XqlLookupsGetData
                                    { datasetName = dataset
                                    , filters = filters
                                    , limit = limit
                                    }
                            )
                            (parseOptionalInt "--limit" flags)
                            (parseGetFilters flags)

                    _ ->
                        Err "xql lookups get-data: expected one positional argument <DATASET>"
            )


parseLookupsRemove : List String -> Result String Endpoint
parseLookupsRemove args =
    splitArgs [] args
        |> Result.andThen
            (\( positionals, flags ) ->
                case positionals of
                    [ dataset ] ->
                        parseRemoveFilters flags
                            |> Result.andThen
                                (\filters ->
                                    if List.isEmpty filters then
                                        Err "xql lookups remove-data: needs at least one --filter k=v"

                                    else
                                        Ok
                                            (XqlLookupsRemoveData
                                                { datasetName = dataset
                                                , filters = filters
                                                }
                                            )
                                )

                    _ ->
                        Err "xql lookups remove-data: expected one positional argument <DATASET>"
            )



-- ARGUMENT / FLAG HELPERS


splitArgs : List String -> List String -> Result String ( List String, List ( String, Maybe String ) )
splitArgs boolFlags args =
    let
        go remaining positionals flags =
            case remaining of
                [] ->
                    Ok ( List.reverse positionals, List.reverse flags )

                head :: rest ->
                    if String.startsWith "--" head then
                        if List.member head boolFlags then
                            go rest positionals (( head, Nothing ) :: flags)

                        else
                            case rest of
                                value :: more ->
                                    go more positionals (( head, Just value ) :: flags)

                                [] ->
                                    Err (head ++ ": expected a value")

                    else
                        go rest (head :: positionals) flags
    in
    go args [] []


hasFlag : String -> List ( String, Maybe String ) -> Bool
hasFlag name flags =
    List.any (\( n, _ ) -> n == name) flags


flagValue : String -> List ( String, Maybe String ) -> Maybe String
flagValue name flags =
    flags
        |> List.filterMap
            (\( n, v ) ->
                if n == name then
                    v

                else
                    Nothing
            )
        |> List.head


allFlagValues : String -> List ( String, Maybe String ) -> List String
allFlagValues name flags =
    List.filterMap
        (\( n, v ) ->
            if n == name then
                v

            else
                Nothing
        )
        flags


parseOptionalInt : String -> List ( String, Maybe String ) -> Result String (Maybe Int)
parseOptionalInt name flags =
    case flagValue name flags of
        Nothing ->
            Ok Nothing

        Just s ->
            case String.toInt s of
                Just n ->
                    Ok (Just n)

                Nothing ->
                    Err (name ++ ": expected integer, got " ++ s)


parseIntervalMs : List ( String, Maybe String ) -> Result String Float
parseIntervalMs flags =
    case flagValue "--interval" flags of
        Nothing ->
            Ok 2000

        Just s ->
            case String.toFloat s of
                Just n ->
                    Ok (n * 1000)

                Nothing ->
                    Err ("--interval: expected number of seconds, got " ++ s)


parseCommaList : String -> List ( String, Maybe String ) -> List String
parseCommaList name flags =
    case flagValue name flags of
        Just s ->
            String.split "," s
                |> List.map String.trim
                |> List.filter (not << String.isEmpty)

        Nothing ->
            []


parseKeyValuePair : String -> Maybe ( String, String )
parseKeyValuePair s =
    case String.indexes "=" s of
        i :: _ ->
            let
                k =
                    String.slice 0 i s

                v =
                    String.dropLeft (i + 1) s
            in
            if String.isEmpty k then
                Nothing

            else
                Just ( k, v )

        [] ->
            Nothing


buildStartArgs : String -> List ( String, Maybe String ) -> Result String Xql.StartQueryArgs
buildStartArgs q flags =
    Result.map3
        (\rel from_ to_ -> ( rel, from_, to_ ))
        (parseOptionalInt "--relative" flags)
        (parseOptionalInt "--from" flags)
        (parseOptionalInt "--to" flags)
        |> Result.andThen
            (\( rel, fromMs, toMs ) ->
                buildTimeframe rel fromMs toMs
                    |> Result.map
                        (\tf ->
                            { query = q
                            , timeframe = tf
                            , tenants = parseCommaList "--tenants" flags
                            }
                        )
            )


buildTimeframe : Maybe Int -> Maybe Int -> Maybe Int -> Result String (Maybe Xql.Timeframe)
buildTimeframe rel fromMs toMs =
    case ( rel, fromMs, toMs ) of
        ( Nothing, Nothing, Nothing ) ->
            Ok Nothing

        ( Just ms, Nothing, Nothing ) ->
            Ok (Just (Xql.Relative ms))

        ( Nothing, Just f, Just t ) ->
            Ok (Just (Xql.Range { from = f, to = t }))

        ( Nothing, Just _, Nothing ) ->
            Err "xql query: --from requires --to"

        ( Nothing, Nothing, Just _ ) ->
            Err "xql query: --to requires --from"

        _ ->
            Err "xql query: use --relative OR --from/--to, not both"


buildResultsArgs : String -> List ( String, Maybe String ) -> Result String Xql.GetResultsArgs
buildResultsArgs qid flags =
    parseOptionalInt "--limit" flags
        |> Result.map
            (\limit ->
                { queryId = qid
                , pendingFlag = Nothing
                , limit = limit
                , format = flagValue "--format" flags
                }
            )


parseGetFilters : List ( String, Maybe String ) -> Result String (List (List ( String, String )))
parseGetFilters flags =
    allFlagValues "--filter" flags
        |> List.map
            (\raw ->
                case parseKeyValuePair raw of
                    Just kv ->
                        Ok [ kv ]

                    Nothing ->
                        Err ("--filter: invalid pair " ++ raw)
            )
        |> resultSequence


parseRemoveFilters : List ( String, Maybe String ) -> Result String (List ( String, String ))
parseRemoveFilters flags =
    allFlagValues "--filter" flags
        |> List.map
            (\raw ->
                case parseKeyValuePair raw of
                    Just kv ->
                        Ok kv

                    Nothing ->
                        Err ("--filter: invalid pair " ++ raw)
            )
        |> resultSequence


parseJsonValue : String -> Result String Encode.Value
parseJsonValue s =
    case Decode.decodeString Decode.value s of
        Ok v ->
            Ok v

        Err e ->
            Err ("invalid JSON: " ++ Decode.errorToString e)


resultSequence : List (Result e a) -> Result e (List a)
resultSequence results =
    List.foldr (\r acc -> Result.map2 (::) r acc) (Ok []) results


parseStandardSearch : List String -> Result String StandardFlags.StandardArgs
parseStandardSearch args =
    splitArgs [] args
        |> Result.andThen
            (\( positionals, flags ) ->
                if not (List.isEmpty positionals) then
                    Err ("unexpected positional arguments: " ++ String.join " " positionals)

                else
                    StandardFlags.parse flags
            )


toAuditLogsArgs : StandardFlags.StandardArgs -> AuditLogs.SearchArgs
toAuditLogsArgs sa =
    { filters = sa.filters
    , sort = sa.sort
    , range = sa.range
    , timeframe = sa.timeframe
    , extra = sa.extra
    }


toEndpointsArgs : StandardFlags.StandardArgs -> Endpoints.SearchArgs
toEndpointsArgs sa =
    { filters = sa.filters
    , sort = sa.sort
    , range = sa.range
    , timeframe = sa.timeframe
    , extra = sa.extra
    }


toBiocsArgs : StandardFlags.StandardArgs -> Biocs.SearchArgs
toBiocsArgs sa =
    { filters = sa.filters
    , sort = sa.sort
    , range = sa.range
    , timeframe = sa.timeframe
    , extra = sa.extra
    }


toCorrelationsArgs : StandardFlags.StandardArgs -> Correlations.SearchArgs
toCorrelationsArgs sa =
    { filters = sa.filters
    , sort = sa.sort
    , range = sa.range
    , timeframe = sa.timeframe
    , extra = sa.extra
    }


toIndicatorsArgs : StandardFlags.StandardArgs -> Indicators.SearchArgs
toIndicatorsArgs sa =
    { filters = sa.filters
    , sort = sa.sort
    , range = sa.range
    , timeframe = sa.timeframe
    , extra = sa.extra
    }


toScheduledQueriesArgs : StandardFlags.StandardArgs -> ScheduledQueries.SearchArgs
toScheduledQueriesArgs sa =
    { filters = sa.filters
    , sort = sa.sort
    , range = sa.range
    , timeframe = sa.timeframe
    , extra = sa.extra
    }


toAssetsArgs : StandardFlags.StandardArgs -> Assets.SearchArgs
toAssetsArgs sa =
    { filters = sa.filters
    , sort = sa.sort
    , range = sa.range
    , timeframe = sa.timeframe
    , extra = sa.extra
    }


toIssuesArgs : StandardFlags.StandardArgs -> Issues.SearchArgs
toIssuesArgs sa =
    { filters = sa.filters
    , sort = sa.sort
    , range = sa.range
    , timeframe = sa.timeframe
    , extra = sa.extra
    }


toCasesArgs : StandardFlags.StandardArgs -> Cases.SearchArgs
toCasesArgs sa =
    { filters = sa.filters
    , sort = sa.sort
    , range = sa.range
    , timeframe = sa.timeframe
    , extra = sa.extra
    }


endpointName : Endpoint -> String
endpointName endpoint =
    case endpoint of
        Healthcheck ->
            "healthcheck"

        TenantInfo ->
            "tenant-info"

        CliVersion ->
            "cli version"

        EndpointsList _ ->
            "endpoints list"

        AuditLogsSearch _ ->
            "audit-logs search"

        AuditLogsAgentsReports ->
            "audit-logs agents-reports"

        DistributionsGetVersions ->
            "distributions get-versions"

        DistributionsList ->
            "distributions list"

        RbacGetUsers ->
            "rbac get-users"

        AuthSettingsGet ->
            "authentication-settings get"

        DeviceControlGetViolations ->
            "device-control get-violations"

        AttackSurfaceGetRules ->
            "attack-surface get-rules"

        XqlGetQuota ->
            "xql get-quota"

        XqlGetDatasets ->
            "xql get-datasets"

        XqlLibraryGet ->
            "xql-library get"

        XqlStartQuery _ ->
            "xql query"

        XqlQueryPoll _ _ ->
            "xql query --poll"

        XqlGetResults _ ->
            "xql get-results"

        XqlGetResultsPoll _ _ ->
            "xql get-results --poll"

        XqlGetResultsStream _ ->
            "xql get-results-stream"

        XqlLookupsAddData _ ->
            "xql lookups add-data"

        XqlLookupsGetData _ ->
            "xql lookups get-data"

        XqlLookupsRemoveData _ ->
            "xql lookups remove-data"

        ScheduledQueriesList _ ->
            "scheduled-queries list"

        IndicatorsGet _ ->
            "indicators get"

        BiocsGet _ ->
            "bioc get"

        CorrelationsGet _ ->
            "correlations get"

        IssuesSearch _ ->
            "issues search"

        LegacyExceptionsGetModules ->
            "legacy-exceptions get-modules"

        LegacyExceptionsFetch ->
            "legacy-exceptions fetch"

        ProfilesList profileType ->
            "profiles list " ++ profileType

        ProfilesGetPolicy _ ->
            "profiles get-policy"

        AgentConfigContentManagement ->
            "agent-config content-management"

        AgentConfigAutoUpgrade ->
            "agent-config auto-upgrade"

        AgentConfigWildfireAnalysis ->
            "agent-config wildfire-analysis"

        AgentConfigCriticalEnvironmentVersions ->
            "agent-config critical-environment-versions"

        AgentConfigAdvancedAnalysis ->
            "agent-config advanced-analysis"

        AgentConfigAgentStatus ->
            "agent-config agent-status"

        AgentConfigInformativeBtpIssues ->
            "agent-config informative-btp-issues"

        AgentConfigCortexXdrLogCollection ->
            "agent-config cortex-xdr-log-collection"

        AgentConfigActionCenterExpiration ->
            "agent-config action-center-expiration"

        AgentConfigEndpointAdministrationCleanup ->
            "agent-config endpoint-administration-cleanup"

        RbacGetRoles _ ->
            "rbac get-roles"

        RbacGetUserGroups _ ->
            "rbac get-user-groups"

        ApiKeysList ->
            "api-keys list"

        RiskScore _ ->
            "risk score"

        RiskUsers ->
            "risk users"

        RiskHosts ->
            "risk hosts"

        CasesSearch _ ->
            "cases search"

        IssuesSchema ->
            "issues schema"

        DisablePreventionFetch ->
            "disable-prevention fetch"

        DisablePreventionFetchInjection ->
            "disable-prevention fetch-injection"

        AssetsList ->
            "assets list"

        AssetsSchema ->
            "assets schema"

        AssetsExternalServices _ ->
            "assets external-services"

        AssetsInternetExposures _ ->
            "assets internet-exposures"

        AssetsIpRanges _ ->
            "assets ip-ranges"

        AssetsVulnerabilityTests _ ->
            "assets vulnerability-tests"

        AssetsExternalWebsites _ ->
            "assets external-websites"

        AssetsWebsitesLastAssessment ->
            "assets websites-last-assessment"

        AssetGroupsList ->
            "asset-groups list"


errorToString : Error -> String
errorToString err =
    case err of
        NetworkError ->
            "Network error"

        Timeout ->
            "Request timed out"

        BadStatus code maybeApiError ->
            case maybeApiError of
                Just apiErr ->
                    "HTTP " ++ String.fromInt code ++ ": " ++ apiErr.errMsg

                Nothing ->
                    "HTTP " ++ String.fromInt code

        BadBody detail ->
            "Bad response body: " ++ detail

        BadUrl url ->
            "Bad URL: " ++ url


usage : List String -> String
usage args =
    "Unknown command: "
        ++ String.join " " args
        ++ "\n\nUsage:\n"
        ++ String.join "\n"
            [ "  cortex healthcheck                          System health check"
            , "  cortex tenant-info                          Get tenant license and config info"
            , "  cortex cli version                          Get latest Cortex CLI version"
            , ""
            , "  cortex audit-logs search                    Search audit management logs"
            , "  cortex audit-logs agents-reports            Get agent event reports"
            , ""
            , "  cortex endpoints list                       List all endpoints"
            , "  cortex distributions get-versions           List all agent versions"
            , "  cortex distributions list                   List agent distributions"
            , ""
            , "  cortex rbac get-users                       List users"
            , "  cortex rbac get-roles <name>                Get details for a role by name"
            , "  cortex rbac get-user-groups <name>          Get details for a user group by name"
            , "  cortex api-keys list                        List API keys"
            , "  cortex authentication-settings get          Get IdP/SSO settings"
            , ""
            , "  cortex device-control get-violations        List device-control violations"
            , "  cortex attack-surface get-rules             List attack surface rules"
            , ""
            , "  cortex xql get-quota                        Get XQL query quota"
            , "  cortex xql get-datasets                     List XQL datasets"
            , "  cortex xql-library get                      List XQL library queries"
            , "  cortex scheduled-queries list               List scheduled queries"
            , ""
            , "  cortex xql query <QUERY> [flags]            Start an XQL query; prints query_id"
            , "    --poll                                      Poll until SUCCESS/FAIL, print results"
            , "    --interval <SECONDS>                        Poll interval (default 2)"
            , "    --relative <MS>                             Relative timeframe, e.g. 86400000"
            , "    --from <MS> --to <MS>                       Absolute epoch-ms timeframe"
            , "    --tenants a,b,c                             MSSP tenant IDs"
            , "  cortex xql get-results <QUERY_ID> [flags]   Fetch results for a query id"
            , "    --poll                                      Poll until SUCCESS/FAIL"
            , "    --interval <SECONDS>                        Poll interval (default 2)"
            , "    --limit <N>                                 Max rows"
            , "    --format json|csv                           Response format"
            , "  cortex xql get-results-stream <STREAM_ID>   Fetch streaming tail for >1000 rows"
            , "    --gzip                                      Request gzip-compressed response"
            , "  cortex xql lookups add-data <DATASET> <JSON>"
            , "    --key-fields a,b,c                          Identity fields for upsert"
            , "  cortex xql lookups get-data <DATASET>"
            , "    --filter k=v                                Repeatable; each one is a filter object"
            , "    --limit <N>"
            , "  cortex xql lookups remove-data <DATASET>"
            , "    --filter k=v                                Repeatable; combined as AND"
            , ""
            , "  cortex indicators get                       List indicators (IOCs)"
            , "  cortex bioc get                             List BIOCs"
            , "  cortex correlations get                     List correlation rules"
            , "  cortex issues search                        Search issues"
            , "  cortex issues schema                        Get issue field schema"
            , "  cortex cases search                         Search cases"
            , ""
            , "  cortex risk score <id>                      Get risk score for a user or endpoint"
            , "  cortex risk users                           List highest-risk users"
            , "  cortex risk hosts                           List highest-risk hosts"
            , ""
            , "  cortex disable-prevention fetch             List disable-prevention rules"
            , "  cortex disable-prevention fetch-injection   List disable-injection-prevention rules"
            , ""
            , "  cortex assets list                          List assets"
            , "  cortex assets schema                        Get asset inventory schema"
            , "  cortex assets external-services             List external services"
            , "  cortex assets internet-exposures            List internet exposures"
            , "  cortex assets ip-ranges                     List external IP ranges"
            , "  cortex assets vulnerability-tests           List vulnerability tests"
            , "  cortex assets external-websites             List external websites"
            , "  cortex assets websites-last-assessment      Get websites last assessment"
            , "  cortex asset-groups list                    List asset groups"
            , ""
            , "  cortex legacy-exceptions get-modules        List legacy exception modules"
            , "  cortex legacy-exceptions fetch              Fetch legacy exception rules"
            , ""
            , "  cortex profiles list <type>                 List endpoint security profiles (type: prevention|extension)"
            , "  cortex profiles get-policy <endpoint-id>    Get policy assigned to an endpoint"
            , ""
            , "  cortex agent-config content-management              Get content management settings"
            , "  cortex agent-config auto-upgrade                    Get agent auto-upgrade settings"
            , "  cortex agent-config wildfire-analysis               Get WildFire analysis settings"
            , "  cortex agent-config critical-environment-versions   Get critical environment versions settings"
            , "  cortex agent-config advanced-analysis               Get advanced analysis settings"
            , "  cortex agent-config agent-status                    Get agent status timeout settings"
            , "  cortex agent-config informative-btp-issues          Get informative BTP issues settings"
            , "  cortex agent-config cortex-xdr-log-collection       Get log collection settings"
            , "  cortex agent-config action-center-expiration        Get action center expiration settings"
            , "  cortex agent-config endpoint-administration-cleanup Get endpoint administration cleanup settings"
            ]
