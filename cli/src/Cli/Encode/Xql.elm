module Cli.Encode.Xql exposing (encodeDatasets, encodeLibrary, encodeQuota)

import Cortex.Api.Xql exposing (Dataset, DatasetRange, Library, LibraryQuery, Quota)
import Json.Encode as Encode


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
