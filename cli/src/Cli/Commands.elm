module Cli.Commands exposing (Msg(..), dispatch, handleResult)

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
            Ok (run Healthcheck.check Healthcheck.encode)

        [ "tenant-info" ] ->
            Ok (run TenantInfo.get TenantInfo.encode)

        [ "endpoints", "list" ] ->
            Ok (run Endpoints.list Endpoints.encode)

        [ "audit-logs", "search" ] ->
            Ok (run AuditLogs.search AuditLogs.encode)

        [ "audit-logs", "agents-reports" ] ->
            Ok (run AuditLogs.agentsReports AuditLogs.encodeAgentsReports)

        [ "cli", "version" ] ->
            Ok (run Cli.getVersion Cli.encode)

        [ "distributions", "get-versions" ] ->
            Ok (run Distributions.getVersions Distributions.encodeVersions)

        [ "distributions", "list" ] ->
            Ok (run Distributions.getDistributions Distributions.encodeDistributions)

        [ "rbac", "get-users" ] ->
            Ok (run Rbac.getUsers Rbac.encodeUsers)

        [ "xql", "get-quota" ] ->
            Ok (run Xql.getQuota Xql.encodeQuota)

        [ "xql", "get-datasets" ] ->
            Ok (run Xql.getDatasets Xql.encodeDatasets)

        [ "xql-library", "get" ] ->
            Ok (run Xql.getLibrary Xql.encodeLibrary)

        [ "device-control", "get-violations" ] ->
            Ok (run DeviceControl.getViolations DeviceControl.encodeViolations)

        [ "authentication-settings", "get" ] ->
            Ok (run AuthSettings.get AuthSettings.encode)

        [ "attack-surface", "get-rules" ] ->
            Ok (run AttackSurface.getRules AttackSurface.encode)

        [ "scheduled-queries", "list" ] ->
            Ok (run ScheduledQueries.list ScheduledQueries.encode)

        [ "indicators", "get" ] ->
            Ok (run Indicators.get Indicators.encode)

        [ "bioc", "get" ] ->
            Ok (run Biocs.get Biocs.encode)

        [ "correlations", "get" ] ->
            Ok (run Correlations.get Correlations.encode)

        [ "issues", "search" ] ->
            Ok (run Issues.search Issues.encodeSearch)

        [ "legacy-exceptions", "get-modules" ] ->
            Ok (run LegacyExceptions.getModules LegacyExceptions.encodeModules)

        [ "legacy-exceptions", "fetch" ] ->
            Ok (run LegacyExceptions.fetch LegacyExceptions.encodeFetch)

        [ "assets", "list" ] ->
            Ok (run Assets.list Assets.encodeAssets)

        [ "assets", "schema" ] ->
            Ok (run Assets.getSchema Assets.encodeSchema)

        [ "assets", "external-services" ] ->
            Ok (run Assets.getExternalServices Assets.encodeExternalServices)

        [ "assets", "internet-exposures" ] ->
            Ok (run Assets.getInternetExposures Assets.encodeInternetExposures)

        [ "assets", "ip-ranges" ] ->
            Ok (run Assets.getExternalIpRanges Assets.encodeExternalIpRanges)

        [ "assets", "vulnerability-tests" ] ->
            Ok (run Assets.getVulnerabilityTests Assets.encodeVulnerabilityTests)

        [ "assets", "external-websites" ] ->
            Ok (run Assets.getExternalWebsites Assets.encodeExternalWebsites)

        [ "assets", "websites-last-assessment" ] ->
            Ok (run Assets.getWebsitesLastAssessment Assets.encodeWebsitesLastAssessment)

        [ "asset-groups", "list" ] ->
            Ok (run AssetGroups.list AssetGroups.encode)

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
