module Cortex.Api.Cases exposing
    ( SearchArgs, defaultSearchArgs
    , Case, SearchResponse
    , search
    )

{-| Cortex case search — incident-level groupings of issues.

@docs SearchArgs, defaultSearchArgs
@docs Case, SearchResponse
@docs search

-}

import Cortex.Decode exposing (andMap, optionalList, reply)
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
        |> andMap (optionalField "custom_fields" Decode.value)


optionalField : String -> Decoder a -> Decoder (Maybe a)
optionalField name d =
    Decode.maybe (Decode.field name d)
