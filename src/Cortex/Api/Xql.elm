module Cortex.Api.Xql exposing
    ( Dataset
    , DatasetRange
    , Library
    , LibraryQuery
    , Quota
    , getDatasets
    , getLibrary
    , getQuota
    )

import Cortex.Decode exposing (andMap, optionalList, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| The Cortex tenant returns quota counters as JSON numbers that may carry a
decimal component (e.g. `4015.0`), even though the OpenAPI schema documents
them as integers. We decode every quota field as Float so the values survive
roundtripping through the typed decoder without integer coercion dropping the
fractional part.

`dailyUsedQuota` is not listed in the OpenAPI schema but is returned by the
API in practice — per CLAUDE.md we capture every field the response contains.

-}
type alias Quota =
    { licenseQuota : Maybe Float
    , additionalPurchasedQuota : Maybe Float
    , usedQuota : Maybe Float
    , dailyUsedQuota : Maybe Float
    , evalQuota : Maybe Float
    , totalDailyRunningQueries : Maybe Int
    , totalDailyConcurrentRejectedQueries : Maybe Int
    , currentConcurrentActiveQueries : Encode.Value
    , currentConcurrentActiveQueriesCount : Maybe Int
    , maxDailyConcurrentActiveQueryCount : Maybe Int
    }


type alias Dataset =
    { datasetName : Maybe String
    , type_ : Maybe String
    , logUpdateType : Maybe String
    , lastUpdated : Maybe Int
    , totalDaysStored : Maybe Int
    , hotRange : Maybe DatasetRange
    , coldRange : Maybe DatasetRange
    , totalSizeStored : Maybe Int
    , averageDailySize : Maybe Int
    , totalEvents : Maybe Int
    , averageEventSize : Maybe Int
    , ttl : Maybe Int
    , defaultQueryTarget : Maybe Bool
    }


type alias DatasetRange =
    { from : Maybe Int
    , to : Maybe Int
    }


type alias Library =
    { queriesCount : Maybe Int
    , xqlQueries : List LibraryQuery
    }


type alias LibraryQuery =
    { id : Maybe Int
    , name : Maybe String
    , description : Maybe String
    , queryText : Maybe String
    , createdAt : Maybe Int
    , createdBy : Maybe String
    , createdByPretty : Maybe String
    , modifiedAt : Maybe Int
    , modifiedBy : Maybe String
    , modifiedByPretty : Maybe String
    , queryMetadata : Encode.Value
    , isPrivate : Maybe Bool
    , labels : List String
    }


{-| POST /public\_api/v1/xql/get\_quota
-}
getQuota : Request Quota
getQuota =
    Request.postEmpty
        [ "public_api", "v1", "xql", "get_quota" ]
        (reply quotaDecoder)


{-| POST /public\_api/v1/xql/get\_datasets
-}
getDatasets : Request (List Dataset)
getDatasets =
    Request.postEmpty
        [ "public_api", "v1", "xql", "get_datasets" ]
        (reply (Decode.list datasetDecoder))


{-| POST /public\_api/xql\_library/get
-}
getLibrary : Request Library
getLibrary =
    Request.postEmpty
        [ "public_api", "xql_library", "get" ]
        (reply libraryDecoder)


quotaDecoder : Decoder Quota
quotaDecoder =
    Decode.map8 Quota
        (Decode.maybe (Decode.field "license_quota" Decode.float))
        (Decode.maybe (Decode.field "additional_purchased_quota" Decode.float))
        (Decode.maybe (Decode.field "used_quota" Decode.float))
        (Decode.maybe (Decode.field "daily_used_quota" Decode.float))
        (Decode.maybe (Decode.field "eval_quota" Decode.float))
        (Decode.maybe (Decode.field "total_daily_running_queries" Decode.int))
        (Decode.maybe (Decode.field "total_daily_concurrent_rejected_queries" Decode.int))
        (Decode.oneOf
            [ Decode.field "current_concurrent_active_queries" Decode.value
            , Decode.succeed Encode.null
            ]
        )
        |> andMap (Decode.maybe (Decode.field "current_concurrent_active_queries_count" Decode.int))
        |> andMap (Decode.maybe (Decode.field "max_daily_concurrent_active_query_count" Decode.int))


datasetDecoder : Decoder Dataset
datasetDecoder =
    Decode.map8 Dataset
        (Decode.maybe (Decode.field "dataset_name" Decode.string))
        (Decode.maybe (Decode.field "type" Decode.string))
        (Decode.maybe (Decode.field "log_update_type" Decode.string))
        (Decode.maybe (Decode.field "last_updated" Decode.int))
        (Decode.maybe (Decode.field "total_days_stored" Decode.int))
        (Decode.maybe (Decode.field "hot_range" rangeDecoder))
        (Decode.maybe (Decode.field "cold_range" rangeDecoder))
        (Decode.maybe (Decode.field "total_size_stored" Decode.int))
        |> andMap (Decode.maybe (Decode.field "average_daily_size" Decode.int))
        |> andMap (Decode.maybe (Decode.field "total_events" Decode.int))
        |> andMap (Decode.maybe (Decode.field "average_event_size" Decode.int))
        |> andMap (Decode.maybe (Decode.field "ttl" Decode.int))
        |> andMap (Decode.maybe (Decode.field "default_query_target" Decode.bool))


rangeDecoder : Decoder DatasetRange
rangeDecoder =
    Decode.map2 DatasetRange
        (Decode.maybe (Decode.field "from" Decode.int))
        (Decode.maybe (Decode.field "to" Decode.int))


libraryDecoder : Decoder Library
libraryDecoder =
    Decode.map2 Library
        (Decode.maybe (Decode.field "queries_count" Decode.int))
        (optionalList "xql_queries" libraryQueryDecoder)


libraryQueryDecoder : Decoder LibraryQuery
libraryQueryDecoder =
    Decode.map8 LibraryQuery
        (Decode.maybe (Decode.field "id" Decode.int))
        (Decode.maybe (Decode.field "name" Decode.string))
        (Decode.maybe (Decode.field "description" Decode.string))
        (Decode.maybe (Decode.field "query_text" Decode.string))
        (Decode.maybe (Decode.field "created_at" Decode.int))
        (Decode.maybe (Decode.field "created_by" Decode.string))
        (Decode.maybe (Decode.field "created_by_pretty" Decode.string))
        (Decode.maybe (Decode.field "modified_at" Decode.int))
        |> andMap (Decode.maybe (Decode.field "modified_by" Decode.string))
        |> andMap (Decode.maybe (Decode.field "modified_by_pretty" Decode.string))
        |> andMap
            (Decode.oneOf
                [ Decode.field "query_metadata" Decode.value
                , Decode.succeed Encode.null
                ]
            )
        |> andMap (Decode.maybe (Decode.field "is_private" Decode.bool))
        |> andMap (optionalList "labels" Decode.string)
