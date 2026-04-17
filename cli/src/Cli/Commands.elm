module Cli.Commands exposing
    ( Endpoint(..)
    , argvToEndpoint
    , endpointName
    , errorToString
    , usage
    )

import Cortex.Error exposing (Error(..))


type Endpoint
    = Healthcheck
    | TenantInfo
    | CliVersion
    | EndpointsList
    | AuditLogsSearch
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
    | ScheduledQueriesList
    | IndicatorsGet
    | BiocsGet
    | CorrelationsGet
    | IssuesSearch
    | LegacyExceptionsGetModules
    | LegacyExceptionsFetch
    | AssetsList
    | AssetsSchema
    | AssetsExternalServices
    | AssetsInternetExposures
    | AssetsIpRanges
    | AssetsVulnerabilityTests
    | AssetsExternalWebsites
    | AssetsWebsitesLastAssessment
    | AssetGroupsList


argvToEndpoint : List String -> Result String Endpoint
argvToEndpoint args =
    case args of
        [ "healthcheck" ] ->
            Ok Healthcheck

        [ "tenant-info" ] ->
            Ok TenantInfo

        [ "cli", "version" ] ->
            Ok CliVersion

        [ "endpoints", "list" ] ->
            Ok EndpointsList

        [ "audit-logs", "search" ] ->
            Ok AuditLogsSearch

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

        [ "xql", "get-quota" ] ->
            Ok XqlGetQuota

        [ "xql", "get-datasets" ] ->
            Ok XqlGetDatasets

        [ "xql-library", "get" ] ->
            Ok XqlLibraryGet

        [ "scheduled-queries", "list" ] ->
            Ok ScheduledQueriesList

        [ "indicators", "get" ] ->
            Ok IndicatorsGet

        [ "bioc", "get" ] ->
            Ok BiocsGet

        [ "correlations", "get" ] ->
            Ok CorrelationsGet

        [ "issues", "search" ] ->
            Ok IssuesSearch

        [ "legacy-exceptions", "get-modules" ] ->
            Ok LegacyExceptionsGetModules

        [ "legacy-exceptions", "fetch" ] ->
            Ok LegacyExceptionsFetch

        [ "assets", "list" ] ->
            Ok AssetsList

        [ "assets", "schema" ] ->
            Ok AssetsSchema

        [ "assets", "external-services" ] ->
            Ok AssetsExternalServices

        [ "assets", "internet-exposures" ] ->
            Ok AssetsInternetExposures

        [ "assets", "ip-ranges" ] ->
            Ok AssetsIpRanges

        [ "assets", "vulnerability-tests" ] ->
            Ok AssetsVulnerabilityTests

        [ "assets", "external-websites" ] ->
            Ok AssetsExternalWebsites

        [ "assets", "websites-last-assessment" ] ->
            Ok AssetsWebsitesLastAssessment

        [ "asset-groups", "list" ] ->
            Ok AssetGroupsList

        _ ->
            Err (usage args)


endpointName : Endpoint -> String
endpointName endpoint =
    case endpoint of
        Healthcheck ->
            "healthcheck"

        TenantInfo ->
            "tenant-info"

        CliVersion ->
            "cli version"

        EndpointsList ->
            "endpoints list"

        AuditLogsSearch ->
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

        ScheduledQueriesList ->
            "scheduled-queries list"

        IndicatorsGet ->
            "indicators get"

        BiocsGet ->
            "bioc get"

        CorrelationsGet ->
            "correlations get"

        IssuesSearch ->
            "issues search"

        LegacyExceptionsGetModules ->
            "legacy-exceptions get-modules"

        LegacyExceptionsFetch ->
            "legacy-exceptions fetch"

        AssetsList ->
            "assets list"

        AssetsSchema ->
            "assets schema"

        AssetsExternalServices ->
            "assets external-services"

        AssetsInternetExposures ->
            "assets internet-exposures"

        AssetsIpRanges ->
            "assets ip-ranges"

        AssetsVulnerabilityTests ->
            "assets vulnerability-tests"

        AssetsExternalWebsites ->
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
            , "  cortex indicators get                       List indicators (IOCs)"
            , "  cortex bioc get                             List BIOCs"
            , "  cortex correlations get                     List correlation rules"
            , "  cortex issues search                        Search issues"
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
            ]
