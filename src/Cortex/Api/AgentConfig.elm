module Cortex.Api.AgentConfig exposing
    ( ContentManagement, AutoUpgrade, WildfireAnalysis, CriticalEnvironmentVersions
    , AdvancedAnalysis, AgentStatus, InformativeBtpIssues, CortexXdrLogCollection
    , ActionCenterExpiration, EndpointAdministrationCleanup
    , getContentManagement, getAutoUpgrade, getWildfireAnalysis, getCriticalEnvironmentVersions
    , getAdvancedAnalysis, getAgentStatus, getInformativeBtpIssues, getCortexXdrLogCollection
    , getActionCenterExpiration, getEndpointAdministrationCleanup
    )

{-| Read-only wrappers around the agent configuration GET endpoints under
`/public_api/v1/configurations/agent/*`. Each one returns a small, flat
settings object directly (no `reply` envelope). Source of truth:
`docs/cortex-api-openapi/agent-configurations-papi.yaml`.

@docs ContentManagement, AutoUpgrade, WildfireAnalysis, CriticalEnvironmentVersions
@docs AdvancedAnalysis, AgentStatus, InformativeBtpIssues, CortexXdrLogCollection
@docs ActionCenterExpiration, EndpointAdministrationCleanup

@docs getContentManagement, getAutoUpgrade, getWildfireAnalysis, getCriticalEnvironmentVersions
@docs getAdvancedAnalysis, getAgentStatus, getInformativeBtpIssues, getCortexXdrLogCollection
@docs getActionCenterExpiration, getEndpointAdministrationCleanup

-}

import Cortex.Request as Request exposing (Request)
import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)


{-| Content-update bandwidth and minor-version settings.
-}
type alias ContentManagement =
    { enableBandwidthControl : Maybe Bool
    , bandwidthInMbps : Maybe Int
    , enableMinorContentVersionUpdates : Maybe Bool
    }


{-| GET /public\_api/v1/configurations/agent/content\_management
-}
getContentManagement : Request ContentManagement
getContentManagement =
    Request.get
        [ "public_api", "v1", "configurations", "agent", "content_management" ]
        contentManagementDecoder


contentManagementDecoder : Decoder ContentManagement
contentManagementDecoder =
    Decode.map3 ContentManagement
        (Decode.maybe (Decode.field "enable_bandwidth_control" Decode.bool))
        (Decode.maybe (Decode.field "bandwidth_in_mbps" Decode.int))
        (Decode.maybe (Decode.field "enable_minor_content_version_updates" Decode.bool))


{-| Agent auto-upgrade parallelism setting.
-}
type alias AutoUpgrade =
    { amountOfParallelUpgrades : Maybe Int
    }


{-| GET /public\_api/v1/configurations/agent/auto\_upgrade
-}
getAutoUpgrade : Request AutoUpgrade
getAutoUpgrade =
    Request.get
        [ "public_api", "v1", "configurations", "agent", "auto_upgrade" ]
        autoUpgradeDecoder


autoUpgradeDecoder : Decoder AutoUpgrade
autoUpgradeDecoder =
    Decode.map AutoUpgrade
        (Decode.maybe (Decode.field "amount_of_parallel_upgrades" Decode.int))


{-| WildFire scoring toggle for benign verdicts.
-}
type alias WildfireAnalysis =
    { enableWildfireAnalysisScoringForBenignVerdicts : Maybe Bool
    }


{-| GET /public\_api/v1/configurations/agent/wildfire\_analysis
-}
getWildfireAnalysis : Request WildfireAnalysis
getWildfireAnalysis =
    Request.get
        [ "public_api", "v1", "configurations", "agent", "wildfire_analysis" ]
        wildfireAnalysisDecoder


wildfireAnalysisDecoder : Decoder WildfireAnalysis
wildfireAnalysisDecoder =
    Decode.map WildfireAnalysis
        (Decode.maybe (Decode.field "enable_wildfire_analysis_scoring_for_benign_verdicts" Decode.bool))


{-| Toggle for the critical-environment-versions enforcement.
-}
type alias CriticalEnvironmentVersions =
    { enabledCriticalEnvironmentVersions : Maybe Bool
    }


{-| GET /public\_api/v1/configurations/agent/critical\_environment\_versions
-}
getCriticalEnvironmentVersions : Request CriticalEnvironmentVersions
getCriticalEnvironmentVersions =
    Request.get
        [ "public_api", "v1", "configurations", "agent", "critical_environment_versions" ]
        criticalEnvironmentVersionsDecoder


criticalEnvironmentVersionsDecoder : Decoder CriticalEnvironmentVersions
criticalEnvironmentVersionsDecoder =
    Decode.map CriticalEnvironmentVersions
        (Decode.maybe (Decode.field "enabled_critical_environment_versions" Decode.bool))


{-| Advanced-analysis upload and exception-application toggles.
-}
type alias AdvancedAnalysis =
    { automaticallyUploadDefinedIssueDataFiles : Maybe Bool
    , automaticallyApplyAdvancedAnalysisExceptions : Maybe Bool
    }


{-| GET /public\_api/v1/configurations/agent/advanced\_analysis
-}
getAdvancedAnalysis : Request AdvancedAnalysis
getAdvancedAnalysis =
    Request.get
        [ "public_api", "v1", "configurations", "agent", "advanced_analysis" ]
        advancedAnalysisDecoder


advancedAnalysisDecoder : Decoder AdvancedAnalysis
advancedAnalysisDecoder =
    Decode.map2 AdvancedAnalysis
        (Decode.maybe (Decode.field "automatically_upload_defined_issue_data_files" Decode.bool))
        (Decode.maybe (Decode.field "automatically_apply_advanced_analysis_exceptions" Decode.bool))


{-| Timeouts (in days) governing license revocation and agent deletion
after lost connection.
-}
type alias AgentStatus =
    { licenseRevocationAfterLostConnection : Maybe Int
    , agentDeletionRetention : Maybe Int
    }


{-| GET /public\_api/v1/configurations/agent/agent\_status
-}
getAgentStatus : Request AgentStatus
getAgentStatus =
    Request.get
        [ "public_api", "v1", "configurations", "agent", "agent_status" ]
        agentStatusDecoder


agentStatusDecoder : Decoder AgentStatus
agentStatusDecoder =
    Decode.map2 AgentStatus
        (Decode.maybe (Decode.field "license_revocation_after_lost_connection" Decode.int))
        (Decode.maybe (Decode.field "agent_deletion_retention" Decode.int))


{-| Display toggle for informative BTP-rule issues.
-}
type alias InformativeBtpIssues =
    { displayUniqueAndInformativeBtpRules : Maybe Bool
    }


{-| GET /public\_api/v1/configurations/agent/informative\_btp\_issues
-}
getInformativeBtpIssues : Request InformativeBtpIssues
getInformativeBtpIssues =
    Request.get
        [ "public_api", "v1", "configurations", "agent", "informative_btp_issues" ]
        informativeBtpIssuesDecoder


informativeBtpIssuesDecoder : Decoder InformativeBtpIssues
informativeBtpIssuesDecoder =
    Decode.map InformativeBtpIssues
        (Decode.maybe (Decode.field "display_unique_and_informative_btp_rules" Decode.bool))


{-| Master toggle for Cortex XDR agent log collection.
-}
type alias CortexXdrLogCollection =
    { allowLogsCollection : Maybe Bool
    }


{-| GET /public\_api/v1/configurations/agent/cortex\_xdr\_log\_collection
-}
getCortexXdrLogCollection : Request CortexXdrLogCollection
getCortexXdrLogCollection =
    Request.get
        [ "public_api", "v1", "configurations", "agent", "cortex_xdr_log_collection" ]
        cortexXdrLogCollectionDecoder


cortexXdrLogCollectionDecoder : Decoder CortexXdrLogCollection
cortexXdrLogCollectionDecoder =
    Decode.map CortexXdrLogCollection
        (Decode.maybe (Decode.field "allow_logs_collection" Decode.bool))


{-| The action-center-expiration response is an open object whose keys are
action-type names (e.g. `isolate`, `scan`) and whose values are expiration
durations in hours. The OpenAPI schema declares `additionalProperties: integer`,
so we surface it as a raw `Dict` rather than a fixed record.
-}
type alias ActionCenterExpiration =
    Dict String Int


{-| GET /public\_api/v1/configurations/agent/action\_center\_expiration
-}
getActionCenterExpiration : Request ActionCenterExpiration
getActionCenterExpiration =
    Request.get
        [ "public_api", "v1", "configurations", "agent", "action_center_expiration" ]
        (Decode.dict Decode.int)


{-| Periodic duplicate-endpoint cleanup configuration: which identity
fields to match on, plus the recurrence interval in hours.
-}
type alias EndpointAdministrationCleanup =
    { periodicDuplicateCleanup : Maybe Bool
    , hostName : Maybe Bool
    , ip : Maybe Bool
    , mac : Maybe Bool
    , timeIntervalHours : Maybe Int
    }


{-| GET /public\_api/v1/configurations/agent/endpoint\_administration\_cleanup
-}
getEndpointAdministrationCleanup : Request EndpointAdministrationCleanup
getEndpointAdministrationCleanup =
    Request.get
        [ "public_api", "v1", "configurations", "agent", "endpoint_administration_cleanup" ]
        endpointAdministrationCleanupDecoder


endpointAdministrationCleanupDecoder : Decoder EndpointAdministrationCleanup
endpointAdministrationCleanupDecoder =
    Decode.map5 EndpointAdministrationCleanup
        (Decode.maybe (Decode.field "periodic_duplicate_cleanup" Decode.bool))
        (Decode.maybe (Decode.field "host_name" (Decode.nullable Decode.bool)) |> Decode.map (Maybe.andThen identity))
        (Decode.maybe (Decode.field "ip" (Decode.nullable Decode.bool)) |> Decode.map (Maybe.andThen identity))
        (Decode.maybe (Decode.field "mac" (Decode.nullable Decode.bool)) |> Decode.map (Maybe.andThen identity))
        (Decode.maybe (Decode.field "time_interval_hours" (Decode.nullable Decode.int)) |> Decode.map (Maybe.andThen identity))
