module Cortex.Api.Cases exposing
    ( SearchArgs, defaultSearchArgs
    , Case, SearchResponse
    , search
    , Artifact, ArtifactBucket, CaseArtifact
    , getArtifacts
    )

{-| Cortex case search — incident-level groupings of issues — and per-case
artifact retrieval.

@docs SearchArgs, defaultSearchArgs
@docs Case, SearchResponse
@docs search
@docs Artifact, ArtifactBucket, CaseArtifact
@docs getArtifacts

-}

import Cortex.Decode exposing (andMap, optionalField, optionalList, reply)
import Cortex.Query as Query exposing (Filter, Range, Sort, Timeframe)
import Cortex.Request as Request exposing (Request)
import Cortex.RequestData as RequestData
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Arguments to [`search`](#search). All fields are optional; pass
[`defaultSearchArgs`](#defaultSearchArgs) for an unfiltered request. `extra`
is merged last into `request_data` and overrides any SDK-generated key on
collision — use it to reach fields the SDK has not modeled yet.
-}
type alias SearchArgs =
    { filters : List Filter
    , sort : Maybe Sort
    , range : Maybe Range
    , timeframe : Maybe Timeframe
    , extra : List ( String, Encode.Value )
    }


{-| A [`SearchArgs`](#SearchArgs) with no filters, sort, pagination, or
timeframe — equivalent to an unfiltered search.
-}
defaultSearchArgs : SearchArgs
defaultSearchArgs =
    { filters = []
    , sort = Nothing
    , range = Nothing
    , timeframe = Nothing
    , extra = []
    }


{-| Paginated envelope returned by [`search`](#search).
-}
type alias SearchResponse =
    { data : List Case
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| A single case (incident-level grouping of related issues).
-}
type alias Case =
    { caseId : Maybe Int
    , caseName : Maybe String
    , description : Maybe String
    , severity : Maybe String
    , statusProgress : Maybe String
    , resolveReason : Maybe String
    , resolveComment : Maybe String
    , isBlocked : Maybe Bool
    , starred : Maybe Bool
    , creationTime : Maybe Int
    , modificationTime : Maybe Int
    , resolvedTimestamp : Maybe Int
    , assignedUserMail : Maybe String
    , assignedUserPrettyName : Maybe String
    , issueCount : Maybe Int
    , lowSeverityIssueCount : Maybe Int
    , medSeverityIssueCount : Maybe Int
    , highSeverityIssueCount : Maybe Int
    , criticalSeverityIssueCount : Maybe Int
    , userCount : Maybe Int
    , hostCount : Maybe Int
    , wildfireHits : Maybe Int
    , aggregatedScore : Maybe Int
    , xdrUrl : Maybe String
    , caseDomain : Maybe String
    , hosts : List String
    , users : List String
    , issueCategories : List String
    , tags : List String
    , issueIds : List Int
    , assetIds : List String
    , assets : List String
    , mitreTacticsIdsAndNames : List String
    , mitreTechniquesIdsAndNames : List String

    {- customFields is a tenant-defined free-form object; keys are user-
       configured per-tenant. Cannot be typed at the SDK layer.
    -}
    , customFields : Maybe Encode.Value
    }


{-| POST /public\_api/v1/case/search

Search cases with optional filters, sorting, pagination, and timeframe.

-}
search : SearchArgs -> Request SearchResponse
search args =
    Request.post
        [ "public_api", "v1", "case", "search" ]
        (RequestData.encode Query.standard
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        (reply searchResponseDecoder)



-- DECODERS


searchResponseDecoder : Decoder SearchResponse
searchResponseDecoder =
    Decode.map3 SearchResponse
        (optionalList "DATA" caseDecoder)
        (Decode.maybe (Decode.field "FILTER_COUNT" Decode.int))
        (Decode.maybe (Decode.field "TOTAL_COUNT" Decode.int))


caseDecoder : Decoder Case
caseDecoder =
    Decode.succeed Case
        |> andMap (optionalField "case_id" Decode.int)
        |> andMap (optionalField "case_name" Decode.string)
        |> andMap (optionalField "description" Decode.string)
        |> andMap (optionalField "severity" Decode.string)
        |> andMap (optionalField "status_progress" Decode.string)
        |> andMap (optionalField "resolve_reason" Decode.string)
        |> andMap (optionalField "resolve_comment" Decode.string)
        |> andMap (optionalField "is_blocked" Decode.bool)
        |> andMap (optionalField "starred" Decode.bool)
        |> andMap (optionalField "creation_time" Decode.int)
        |> andMap (optionalField "modification_time" Decode.int)
        |> andMap (optionalField "resolved_timestamp" Decode.int)
        |> andMap (optionalField "assigned_user_mail" Decode.string)
        |> andMap (optionalField "assigned_user_pretty_name" Decode.string)
        |> andMap (optionalField "issue_count" Decode.int)
        |> andMap (optionalField "low_severity_issue_count" Decode.int)
        |> andMap (optionalField "med_severity_issue_count" Decode.int)
        |> andMap (optionalField "high_severity_issue_count" Decode.int)
        |> andMap (optionalField "critical_severity_issue_count" Decode.int)
        |> andMap (optionalField "user_count" Decode.int)
        |> andMap (optionalField "host_count" Decode.int)
        |> andMap (optionalField "wildfire_hits" Decode.int)
        |> andMap (optionalField "aggregated_score" Decode.int)
        |> andMap (optionalField "xdr_url" Decode.string)
        |> andMap (optionalField "case_domain" Decode.string)
        |> andMap (optionalList "hosts" Decode.string)
        |> andMap (optionalList "users" Decode.string)
        |> andMap (optionalList "issue_categories" Decode.string)
        |> andMap (optionalList "tags" Decode.string)
        |> andMap (optionalList "issue_ids" Decode.int)
        |> andMap (optionalList "asset_ids" Decode.string)
        |> andMap (optionalList "assets" Decode.string)
        |> andMap (optionalList "mitre_tactics_ids_and_names" Decode.string)
        |> andMap (optionalList "mitre_techniques_ids_and_names" Decode.string)
        {- Decoder escape: tenant-defined `custom_fields` map; shape varies
           per tenant configuration and is opaque to the SDK.
        -}
        |> andMap (optionalField "custom_fields" Decode.value)



-- CASE ARTIFACTS


{-| One element of the list returned by [`getArtifacts`](#getArtifacts) —
the network and file artifacts attached to a single case. The endpoint
returns a top-level JSON array of these (no `reply`/`DATA` envelope and
no `TOTAL_COUNT`/`FILTER_COUNT` counters at the outer layer, despite
what the OpenAPI spec implies).
-}
type alias CaseArtifact =
    { caseId : Maybe Int
    , networkArtifacts : Maybe ArtifactBucket
    , fileArtifacts : Maybe ArtifactBucket
    }


{-| Counted list of [`Artifact`](#Artifact) values; shared shape used for
both the network and file buckets inside a [`CaseArtifact`](#CaseArtifact).
-}
type alias ArtifactBucket =
    { totalCount : Maybe Int
    , data : List Artifact
    }


{-| One artifact entry inside an [`ArtifactBucket`](#ArtifactBucket).
Fields fall into three groups by wire shape:

  - shared (all artifacts): `caseId`, `type_`, `alertCount`, `isManual`
  - file artifacts only: `fileName`, `fileSha256`,
    `fileSignatureStatus`, `fileSignatureVendorName`,
    `fileWildfireVerdict`, `isMalicious`, `isProcess`, `lowConfidence`
  - network artifacts only: `networkDomain`, `networkRemoteIp`,
    `networkRemotePort`, `networkCountry`

`artifactId` is in the OpenAPI spec but has not been observed on live
responses; kept for forward-compat. All fields are `Maybe` since the
populated subset depends on the artifact `type_`.

-}
type alias Artifact =
    { artifactId : Maybe String
    , caseId : Maybe Int
    , type_ : Maybe String
    , alertCount : Maybe Int
    , isManual : Maybe Bool
    , fileName : Maybe String
    , fileSha256 : Maybe String
    , fileSignatureStatus : Maybe String
    , fileSignatureVendorName : Maybe String
    , fileWildfireVerdict : Maybe String
    , isMalicious : Maybe Bool
    , isProcess : Maybe Bool
    , lowConfidence : Maybe Bool
    , networkDomain : Maybe String
    , networkRemoteIp : Maybe String
    , networkRemotePort : Maybe Int
    , networkCountry : Maybe String
    }


{-| GET /public\_api/v1/case/artifacts/{case-id} — fetch the network and
file artifacts attached to a case. The response is a top-level JSON
array (no `reply` envelope, no `DATA`/`TOTAL_COUNT` counters at the
outer layer — the OpenAPI spec is wrong on both fronts).
-}
getArtifacts : Int -> Request (List CaseArtifact)
getArtifacts caseId =
    Request.get
        [ "public_api", "v1", "case", "artifacts", String.fromInt caseId ]
        (Decode.list caseArtifactDecoder)


caseArtifactDecoder : Decoder CaseArtifact
caseArtifactDecoder =
    Decode.map3 CaseArtifact
        (optionalField "case_id" Decode.int)
        (optionalField "network_artifacts" artifactBucketDecoder)
        (optionalField "file_artifacts" artifactBucketDecoder)


artifactBucketDecoder : Decoder ArtifactBucket
artifactBucketDecoder =
    Decode.map2 ArtifactBucket
        (Decode.maybe (Decode.field "TOTAL_COUNT" Decode.int))
        (optionalList "DATA" artifactDecoder)


artifactDecoder : Decoder Artifact
artifactDecoder =
    Decode.succeed Artifact
        |> andMap (optionalField "artifact_id" Decode.string)
        |> andMap (optionalField "case_id" Decode.int)
        |> andMap (optionalField "type" Decode.string)
        |> andMap (optionalField "alert_count" Decode.int)
        |> andMap (optionalField "is_manual" Decode.bool)
        |> andMap (optionalField "file_name" Decode.string)
        |> andMap (optionalField "file_sha256" Decode.string)
        |> andMap (optionalField "file_signature_status" Decode.string)
        |> andMap (optionalField "file_signature_vendor_name" Decode.string)
        |> andMap (optionalField "file_wildfire_verdict" Decode.string)
        |> andMap (optionalField "is_malicious" Decode.bool)
        |> andMap (optionalField "is_process" Decode.bool)
        |> andMap (optionalField "low_confidence" Decode.bool)
        |> andMap (optionalField "network_domain" Decode.string)
        |> andMap (optionalField "network_remote_ip" Decode.string)
        |> andMap (optionalField "network_remote_port" Decode.int)
        |> andMap (optionalField "network_country" Decode.string)
