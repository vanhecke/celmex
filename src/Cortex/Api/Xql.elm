module Cortex.Api.Xql exposing
    ( Dataset
    , DatasetRange
    , Library
    , LibraryQuery
    , Quota
    , encodeDatasets
    , encodeLibrary
    , encodeQuota
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


encodeQuota : Quota -> Encode.Value
encodeQuota q =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "license_quota", Encode.float v )) q.licenseQuota
            , Maybe.map (\v -> ( "additional_purchased_quota", Encode.float v )) q.additionalPurchasedQuota
            , Maybe.map (\v -> ( "used_quota", Encode.float v )) q.usedQuota
            , Maybe.map (\v -> ( "daily_used_quota", Encode.float v )) q.dailyUsedQuota
            , Maybe.map (\v -> ( "eval_quota", Encode.float v )) q.evalQuota
            , Maybe.map (\v -> ( "total_daily_running_queries", Encode.int v )) q.totalDailyRunningQueries
            , Maybe.map (\v -> ( "total_daily_concurrent_rejected_queries", Encode.int v )) q.totalDailyConcurrentRejectedQueries
            , Just ( "current_concurrent_active_queries", q.currentConcurrentActiveQueries )
            , Maybe.map (\v -> ( "current_concurrent_active_queries_count", Encode.int v )) q.currentConcurrentActiveQueriesCount
            , Maybe.map (\v -> ( "max_daily_concurrent_active_query_count", Encode.int v )) q.maxDailyConcurrentActiveQueryCount
            ]
        )


encodeDatasets : List Dataset -> Encode.Value
encodeDatasets datasets =
    Encode.list encodeDataset datasets


encodeDataset : Dataset -> Encode.Value
encodeDataset d =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "dataset_name", Encode.string v )) d.datasetName
            , Maybe.map (\v -> ( "type", Encode.string v )) d.type_
            , Maybe.map (\v -> ( "log_update_type", Encode.string v )) d.logUpdateType
            , Maybe.map (\v -> ( "last_updated", Encode.int v )) d.lastUpdated
            , Maybe.map (\v -> ( "total_days_stored", Encode.int v )) d.totalDaysStored
            , Maybe.map (\v -> ( "hot_range", encodeRange v )) d.hotRange
            , Maybe.map (\v -> ( "cold_range", encodeRange v )) d.coldRange
            , Maybe.map (\v -> ( "total_size_stored", Encode.int v )) d.totalSizeStored
            , Maybe.map (\v -> ( "average_daily_size", Encode.int v )) d.averageDailySize
            , Maybe.map (\v -> ( "total_events", Encode.int v )) d.totalEvents
            , Maybe.map (\v -> ( "average_event_size", Encode.int v )) d.averageEventSize
            , Maybe.map (\v -> ( "ttl", Encode.int v )) d.ttl
            , Maybe.map (\v -> ( "default_query_target", Encode.bool v )) d.defaultQueryTarget
            ]
        )


encodeRange : DatasetRange -> Encode.Value
encodeRange r =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "from", Encode.int v )) r.from
            , Maybe.map (\v -> ( "to", Encode.int v )) r.to
            ]
        )


encodeLibrary : Library -> Encode.Value
encodeLibrary library =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "queries_count", Encode.int v )) library.queriesCount
            , Just ( "xql_queries", Encode.list encodeLibraryQuery library.xqlQueries )
            ]
        )


encodeLibraryQuery : LibraryQuery -> Encode.Value
encodeLibraryQuery q =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "id", Encode.int v )) q.id
            , Maybe.map (\v -> ( "name", Encode.string v )) q.name
            , Maybe.map (\v -> ( "description", Encode.string v )) q.description
            , Maybe.map (\v -> ( "query_text", Encode.string v )) q.queryText
            , Maybe.map (\v -> ( "created_at", Encode.int v )) q.createdAt
            , Maybe.map (\v -> ( "created_by", Encode.string v )) q.createdBy
            , Maybe.map (\v -> ( "created_by_pretty", Encode.string v )) q.createdByPretty
            , Maybe.map (\v -> ( "modified_at", Encode.int v )) q.modifiedAt
            , Maybe.map (\v -> ( "modified_by", Encode.string v )) q.modifiedBy
            , Maybe.map (\v -> ( "modified_by_pretty", Encode.string v )) q.modifiedByPretty
            , Just ( "query_metadata", q.queryMetadata )
            , Maybe.map (\v -> ( "is_private", Encode.bool v )) q.isPrivate
            , Just ( "labels", Encode.list Encode.string q.labels )
            ]
        )
