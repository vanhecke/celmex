module Cli.Commands exposing (Msg(..), dispatch, handleResult)

import Cli.Encode.AssetGroups as AssetGroupsEnc
import Cli.Encode.Assets as AssetsEnc
import Cli.Encode.AttackSurface as AttackSurfaceEnc
import Cli.Encode.AuditLogs as AuditLogsEnc
import Cli.Encode.AuthSettings as AuthSettingsEnc
import Cli.Encode.Biocs as BiocsEnc
import Cli.Encode.Cli as CliEnc
import Cli.Encode.Correlations as CorrelationsEnc
import Cli.Encode.DeviceControl as DeviceControlEnc
import Cli.Encode.Distributions as DistributionsEnc
import Cli.Encode.Endpoints as EndpointsEnc
import Cli.Encode.Healthcheck as HealthcheckEnc
import Cli.Encode.Indicators as IndicatorsEnc
import Cli.Encode.Issues as IssuesEnc
import Cli.Encode.LegacyExceptions as LegacyExceptionsEnc
import Cli.Encode.Rbac as RbacEnc
import Cli.Encode.ScheduledQueries as ScheduledQueriesEnc
import Cli.Encode.TenantInfo as TenantInfoEnc
import Cli.Encode.Xql as XqlEnc
import Cli.Ports as Ports
import Cortex.Api.AssetGroups as AssetGroups
import Cortex.Api.Assets as Assets
import Cortex.Api.AttackSurface as AttackSurface
import Cortex.Api.AuditLogs as AuditLogs
import Cortex.Api.AuthSettings as AuthSettings
import Cortex.Api.Biocs as Biocs
import Cortex.Api.Cli as Cli
import Cortex.Api.Correlations as Correlations
import Cortex.Api.DeviceControl as DeviceControl
import Cortex.Api.Distributions as Distributions
import Cortex.Api.Endpoints as Endpoints
import Cortex.Api.Healthcheck as Healthcheck
import Cortex.Api.Indicators as Indicators
import Cortex.Api.Issues as Issues
import Cortex.Api.LegacyExceptions as LegacyExceptions
import Cortex.Api.Rbac as Rbac
import Cortex.Api.ScheduledQueries as ScheduledQueries
import Cortex.Api.TenantInfo as TenantInfo
import Cortex.Api.Xql as Xql
import Cortex.Auth as Auth
import Cortex.Client as Client exposing (Config)
import Cortex.Error exposing (Error(..))
import Cortex.Request as Request exposing (Request)
import Json.Encode as Encode


type Msg
    = GotResponse (Result Error Encode.Value)


dispatch : Auth.Stamp -> Config -> List String -> Result String (Cmd Msg)
dispatch stamp config args =
    let
        run : Request a -> (a -> Encode.Value) -> Cmd Msg
        run req encoder =
            Client.sendWith stamp config GotResponse (Request.map encoder req)
    in
    case args of
        [ "healthcheck" ] ->
            Ok (run Healthcheck.check HealthcheckEnc.encode)

        [ "tenant-info" ] ->
            Ok (run TenantInfo.get TenantInfoEnc.encode)

        [ "endpoints", "list" ] ->
            Ok (run Endpoints.list EndpointsEnc.encode)

        [ "audit-logs", "search" ] ->
            Ok (run AuditLogs.search AuditLogsEnc.encode)

        [ "audit-logs", "agents-reports" ] ->
            Ok (run AuditLogs.agentsReports AuditLogsEnc.encodeAgentsReports)

        [ "cli", "version" ] ->
            Ok (run Cli.getVersion CliEnc.encode)

        [ "distributions", "get-versions" ] ->
            Ok (run Distributions.getVersions DistributionsEnc.encodeVersions)

        [ "distributions", "list" ] ->
            Ok (run Distributions.getDistributions DistributionsEnc.encodeDistributions)

        [ "rbac", "get-users" ] ->
            Ok (run Rbac.getUsers RbacEnc.encodeUsers)

        [ "xql", "get-quota" ] ->
            Ok (run Xql.getQuota XqlEnc.encodeQuota)

        [ "xql", "get-datasets" ] ->
            Ok (run Xql.getDatasets XqlEnc.encodeDatasets)

        [ "xql-library", "get" ] ->
            Ok (run Xql.getLibrary XqlEnc.encodeLibrary)

        [ "device-control", "get-violations" ] ->
            Ok (run DeviceControl.getViolations DeviceControlEnc.encodeViolations)

        [ "authentication-settings", "get" ] ->
            Ok (run AuthSettings.get AuthSettingsEnc.encode)

        [ "attack-surface", "get-rules" ] ->
            Ok (run AttackSurface.getRules AttackSurfaceEnc.encode)

        [ "scheduled-queries", "list" ] ->
            Ok (run ScheduledQueries.list ScheduledQueriesEnc.encode)

        [ "indicators", "get" ] ->
            Ok (run Indicators.get IndicatorsEnc.encode)

        [ "bioc", "get" ] ->
            Ok (run Biocs.get BiocsEnc.encode)

        [ "correlations", "get" ] ->
            Ok (run Correlations.get CorrelationsEnc.encode)

        [ "issues", "search" ] ->
            Ok (run Issues.search IssuesEnc.encodeSearch)

        [ "legacy-exceptions", "get-modules" ] ->
            Ok (run LegacyExceptions.getModules LegacyExceptionsEnc.encodeModules)

        [ "legacy-exceptions", "fetch" ] ->
            Ok (run LegacyExceptions.fetch LegacyExceptionsEnc.encodeFetch)

        [ "assets", "list" ] ->
            Ok (run Assets.list AssetsEnc.encodeAssets)

        [ "assets", "schema" ] ->
            Ok (run Assets.getSchema AssetsEnc.encodeSchema)

        [ "assets", "external-services" ] ->
            Ok (run Assets.getExternalServices AssetsEnc.encodeExternalServices)

        [ "assets", "internet-exposures" ] ->
            Ok (run Assets.getInternetExposures AssetsEnc.encodeInternetExposures)

        [ "assets", "ip-ranges" ] ->
            Ok (run Assets.getExternalIpRanges AssetsEnc.encodeExternalIpRanges)

        [ "assets", "vulnerability-tests" ] ->
            Ok (run Assets.getVulnerabilityTests AssetsEnc.encodeVulnerabilityTests)

        [ "assets", "external-websites" ] ->
            Ok (run Assets.getExternalWebsites AssetsEnc.encodeExternalWebsites)

        [ "assets", "websites-last-assessment" ] ->
            Ok (run Assets.getWebsitesLastAssessment AssetsEnc.encodeWebsitesLastAssessment)

        [ "asset-groups", "list" ] ->
            Ok (run AssetGroups.list AssetGroupsEnc.encode)

        _ ->
            Err (usage args)


handleResult : Msg -> Cmd msg
handleResult (GotResponse result) =
    case result of
        Ok value ->
            Cmd.batch
                [ Ports.stdout (Encode.encode 2 value ++ "\n")
                , Ports.exit 0
                ]

        Err err ->
            Cmd.batch
                [ Ports.stderr (errorToString err ++ "\n")
                , Ports.exit 1
                ]


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
