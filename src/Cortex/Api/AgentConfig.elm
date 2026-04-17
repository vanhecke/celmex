module Cortex.Api.AgentConfig exposing
    ( AdvancedAnalysis
    , AutoUpgrade
    , ContentManagement
    , CriticalEnvironmentVersions
    , WildfireAnalysis
    , getAdvancedAnalysis
    , getAutoUpgrade
    , getContentManagement
    , getCriticalEnvironmentVersions
    , getWildfireAnalysis
    )

{-| Read-only wrappers around the agent configuration GET endpoints under
`/public_api/v1/configurations/agent/*`. Each one returns a small, flat
settings object directly (no `reply` envelope). Source of truth:
`docs/cortex-api-openapi/agent-configurations-papi.yaml`.
-}

import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)


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
