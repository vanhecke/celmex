module Cortex.Api.Xql exposing
    ( Dataset, DatasetRange, Library, LibraryQuery, Quota
    , getDatasets, getLibrary, getQuota
    , QueryStatus(..), Timeframe(..)
    , StartQueryArgs, GetResultsArgs, QueryResults, StreamArgs
    , startQuery, getQueryResults, getQueryResultsStream
    , LookupAddArgs, LookupAddResult
    , LookupGetArgs, LookupGetResult
    , LookupRemoveArgs, LookupRemoveResult
    , lookupsAddData, lookupsGetData, lookupsRemoveData
    , LibraryInsertArgs, LibraryInsertQuery, LibraryInsertResult, LibraryInsertError
    , libraryInsert
    , LibraryDeleteCriteria(..), LibraryDeleteArgs, LibraryDeleteResult
    , libraryDelete
    )

{-| XQL: saved queries, available datasets, tenant quota counters, query
execution (async start/poll), and lookup-dataset row management.

@docs Dataset, DatasetRange, Library, LibraryQuery, Quota
@docs getDatasets, getLibrary, getQuota
@docs QueryStatus, Timeframe
@docs StartQueryArgs, GetResultsArgs, QueryResults, StreamArgs
@docs startQuery, getQueryResults, getQueryResultsStream
@docs LookupAddArgs, LookupAddResult
@docs LookupGetArgs, LookupGetResult
@docs LookupRemoveArgs, LookupRemoveResult
@docs lookupsAddData, lookupsGetData, lookupsRemoveData
@docs LibraryInsertArgs, LibraryInsertQuery, LibraryInsertResult, LibraryInsertError
@docs libraryInsert
@docs LibraryDeleteCriteria, LibraryDeleteArgs, LibraryDeleteResult
@docs libraryDelete

-}

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

    {- currentConcurrentActiveQueries is a runtime list of in-flight
       query descriptors (query_id + start time + caller). Shape varies
       per query type; preserved verbatim because the runtime payload
       is operational metadata rather than user-consumable data.
    -}
    , currentConcurrentActiveQueries : Encode.Value
    , currentConcurrentActiveQueriesCount : Maybe Int
    , maxDailyConcurrentActiveQueryCount : Maybe Int
    }


{-| A dataset available to XQL queries, with its retention ranges and size
stats. The wire format uses Title Case Spaced keys ("Dataset Name", "Last
Updated", "Total Events", etc.) — not snake\_case. `defaultQueryTarget` is
emitted as a string ("TRUE" / "FALSE"), not a boolean.
-}
type alias Dataset =
    { datasetName : Maybe String

    {- Decoder escape: open-ended per spec; preserved as raw string.
       Live tenants emit `SYSTEM` for built-in datasets, but the spec
       declares `type: string` with no enum — could grow new variants.
    -}
    , type_ : Maybe String

    {- Decoder escape: open-ended per spec; preserved as raw string.
       Live tenants emit `LOGS`, but the spec describes the field in
       prose ("Logs"/"State") with no closed enum.
    -}
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
    , defaultQueryTarget : Maybe String
    }


{-| Epoch-millisecond `from`/`to` range inside [`Dataset`](#Dataset).
-}
type alias DatasetRange =
    { from : Maybe Int
    , to : Maybe Int
    }


{-| Saved-query library returned by [`getLibrary`](#getLibrary).
-}
type alias Library =
    { queriesCount : Maybe Int
    , xqlQueries : List LibraryQuery
    }


{-| A single saved XQL query inside the [`Library`](#Library). The live wire
format uses `xql_query_name`, `xql_query`, and `xql_query_tags` for the
query name, body, and tags; OpenAPI-schema field names like `name`,
`query_text`, and `labels` are accepted as fallbacks.
-}
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

    {- queryMetadata is a per-query opaque metadata blob (UI render
       hints, owner attribution, etc.). Shape varies by query source;
       preserved verbatim.
    -}
    , queryMetadata : Maybe Encode.Value
    , isPrivate : Maybe Bool
    , labels : List String
    }


{-| Status of an async XQL query. `OtherStatus` is a forward-compatibility
escape hatch — the documented values are `PENDING` / `SUCCESS` / `FAIL`.
-}
type QueryStatus
    = Pending
    | Success
    | Fail
    | OtherStatus String


{-| Time window for a query. `Relative` is a duration in epoch-milliseconds
(e.g. `Relative 86400000` = last 24 hours); `Range` is an absolute
`from`/`to` epoch-millisecond window.
-}
type Timeframe
    = Relative Int
    | Range { from : Int, to : Int }


{-| Arguments to [`startQuery`](#startQuery). `tenants` is only meaningful in
MSSP multi-tenant deployments — leave it `[]` for a single-tenant query.
-}
type alias StartQueryArgs =
    { query : String
    , timeframe : Maybe Timeframe
    , tenants : List String
    }


{-| Arguments to [`getQueryResults`](#getQueryResults). `pendingFlag = Just
False` makes the server block until the query completes (subject to the
per-request HTTP timeout); the default `Nothing` / `Just True` returns
whatever status the server has right now.
-}
type alias GetResultsArgs =
    { queryId : String
    , pendingFlag : Maybe Bool
    , limit : Maybe Int
    , format : Maybe String
    }


{-| Typed decoding of a `get_query_results` response. `data` and `streamId`
are flattened up out of the nested `results` sub-object for ergonomic access.

The wire format exposes the per-tenant cost map under `query_cost_charged`
(not `query_cost` as the current OpenAPI revision documents) and includes a
`remaining_yearly_quota` counter alongside the daily `remaining_quota` — both
are captured here so the typed decoder doesn't silently drop real response
fields.

-}
type alias QueryResults =
    { status : QueryStatus
    , numberOfResults : Maybe Int

    {- queryCostCharged is a per-tenant cost map keyed by region or
       compute class (e.g. `{"us-east-1": 0.42}`). Keys vary per tenant
       deployment; preserved verbatim.
    -}
    , queryCostCharged : Maybe Encode.Value
    , remainingQuota : Maybe Float
    , remainingYearlyQuota : Maybe Float

    {- data is the user's XQL query result rows. The schema is determined
       by the user's `dataset = X | fields ...` clauses, so the row
       shape is genuinely polymorphic across queries. This is the
       canonical "preserve as Encode.Value" case.
    -}
    , data : List Encode.Value
    , streamId : Maybe String
    }


{-| Arguments to [`getQueryResultsStream`](#getQueryResultsStream). The
`stream_id` comes from a prior [`QueryResults`](#QueryResults) whose result
set exceeded the single-response `limit`.
-}
type alias StreamArgs =
    { streamId : String
    , isGzipCompressed : Maybe Bool
    }


{-| Arguments to [`lookupsAddData`](#lookupsAddData). Each row in `data`
should be an object mapping field names to string values (the lookup dataset
schema enforces per-field types server-side). With `keyFields = []` the
server inserts only; with non-empty `keyFields` the server upserts using
those fields as the identity.

`data` is `Encode.Value` because the lookup-dataset schema is user-defined
per dataset; the SDK cannot constrain the shape ahead of time.

-}
type alias LookupAddArgs =
    { datasetName : String
    , keyFields : List String
    , data : Encode.Value
    }


{-| Counts returned by [`lookupsAddData`](#lookupsAddData).
-}
type alias LookupAddResult =
    { added : Maybe Int
    , updated : Maybe Int
    , skipped : Maybe Int
    }


{-| Arguments to [`lookupsGetData`](#lookupsGetData). Each entry in `filters`
is a full object of AND-ed `(field, value)` pairs; multiple entries OR
together.
-}
type alias LookupGetArgs =
    { datasetName : String
    , filters : List (List ( String, String ))
    , limit : Maybe Int
    }


{-| Payload returned by [`lookupsGetData`](#lookupsGetData).
-}
type alias LookupGetResult =
    { {- data shape varies by the lookup dataset's user-defined schema
         (each dataset has its own field set). Preserved verbatim.
      -}
      data : Maybe Encode.Value
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| Arguments to [`lookupsRemoveData`](#lookupsRemoveData). `filters` is a
single AND-ed filter object (not the list-of-objects shape that
[`lookupsGetData`](#lookupsGetData) uses).
-}
type alias LookupRemoveArgs =
    { datasetName : String
    , filters : List ( String, String )
    }


{-| Row-count returned by [`lookupsRemoveData`](#lookupsRemoveData).
-}
type alias LookupRemoveResult =
    { deleted : Maybe Int
    }


{-| Arguments to [`libraryInsert`](#libraryInsert). `xqlQueries` is the
batch to insert or upsert. With `override = False` the server rejects any
entry whose name already exists; with `override = True` it upserts. `tags`
is an optional list of labels applied to every query in the batch.
-}
type alias LibraryInsertArgs =
    { xqlQueries : List LibraryInsertQuery
    , override : Bool
    , tags : List String
    }


{-| One row in [`LibraryInsertArgs`](#LibraryInsertArgs)`.xqlQueries`. The
SDK serialises `name` to `xql_query_name` and `query` to `xql_query` on
the wire.
-}
type alias LibraryInsertQuery =
    { name : String
    , query : String
    }


{-| Outcome of a [`libraryInsert`](#libraryInsert) call. `added` and
`updated` are the names of queries the server created or upserted; `errors`
is the list of per-item rejections (`{name, message}` pairs the API
returns as `[name, message]` two-element arrays).
-}
type alias LibraryInsertResult =
    { added : List String
    , updated : List String
    , errors : List LibraryInsertError
    }


{-| One row in the [`LibraryInsertResult`](#LibraryInsertResult) `errors`
array — the offending query name and the server's human-readable
rejection reason.
-}
type alias LibraryInsertError =
    { name : String
    , message : String
    }


{-| Selector for [`libraryDelete`](#libraryDelete). The API rejects any
request that combines names and tags, so the SDK forces callers to pick
one at compile time.
-}
type LibraryDeleteCriteria
    = ByNames (List String)
    | ByTags (List String)


{-| Arguments to [`libraryDelete`](#libraryDelete).
-}
type alias LibraryDeleteArgs =
    { criteria : LibraryDeleteCriteria
    }


{-| Outcome of a [`libraryDelete`](#libraryDelete) call. `queriesCount` is
the number of saved queries the server removed; `xqlQueryNames` is the
list of names it removed; `errors` is the list of free-form per-item
failure objects the server flagged without aborting the batch.
-}
type alias LibraryDeleteResult =
    { queriesCount : Int
    , xqlQueryNames : List String

    {- Decoder escape: the OpenAPI spec types delete errors as free-form
       `object[]` with no inner schema; the live API has not been
       observed emitting any concrete shape, so they are preserved
       verbatim until a sample drives a typed decoder.
    -}
    , errors : List Encode.Value
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


{-| POST /public\_api/v1/xql/start\_xql\_query — kicks off an XQL query and
returns the `query_id` string to poll with [`getQueryResults`](#getQueryResults).
-}
startQuery : StartQueryArgs -> Request String
startQuery args =
    Request.post
        [ "public_api", "v1", "xql", "start_xql_query" ]
        (encodeStartQueryBody args)
        (reply Decode.string)


{-| POST /public\_api/v1/xql/get\_query\_results — fetches the status and (when
ready) results for a previously-started query. If `status = Pending`, call
again after a short delay; if results exceeded the single-response `limit`,
continue fetching via [`getQueryResultsStream`](#getQueryResultsStream)
with the returned `streamId`.
-}
getQueryResults : GetResultsArgs -> Request QueryResults
getQueryResults args =
    Request.post
        [ "public_api", "v1", "xql", "get_query_results" ]
        (encodeGetResultsBody args)
        (reply queryResultsDecoder)


{-| POST /public\_api/v1/xql/get\_query\_results\_stream — pulls the tail of a
large result set. The response shape is not in the OpenAPI schema (the
Cortex API sends it chunked, optionally gzipped) so we pass it through as
raw JSON.
-}
getQueryResultsStream : StreamArgs -> Request Encode.Value
getQueryResultsStream args =
    Request.post
        [ "public_api", "v1", "xql", "get_query_results_stream" ]
        (encodeStreamBody args)
        {- Decoder escape: chunked / optionally gzipped result-stream payload
           with no published schema; passed through as raw JSON.
        -}
        Decode.value


{-| POST /public\_api/v1/xql/lookups/add\_data — insert or upsert rows into a
lookup dataset.
-}
lookupsAddData : LookupAddArgs -> Request LookupAddResult
lookupsAddData args =
    Request.post
        [ "public_api", "v1", "xql", "lookups", "add_data" ]
        (encodeLookupAddBody args)
        (maybeReply lookupAddResultDecoder)


{-| POST /public\_api/v1/xql/lookups/get\_data — query rows in a lookup
dataset with optional AND/OR-ed filter objects.
-}
lookupsGetData : LookupGetArgs -> Request LookupGetResult
lookupsGetData args =
    Request.post
        [ "public_api", "v1", "xql", "lookups", "get_data" ]
        (encodeLookupGetBody args)
        (maybeReply lookupGetResultDecoder)


{-| POST /public\_api/v1/xql/lookups/remove\_data — delete rows in a lookup
dataset matching the given filter object.
-}
lookupsRemoveData : LookupRemoveArgs -> Request LookupRemoveResult
lookupsRemoveData args =
    Request.post
        [ "public_api", "v1", "xql", "lookups", "remove_data" ]
        (encodeLookupRemoveBody args)
        (maybeReply lookupRemoveResultDecoder)


{-| POST /public\_api/xql\_library/insert — insert or upsert a batch of
saved XQL queries.
-}
libraryInsert : LibraryInsertArgs -> Request LibraryInsertResult
libraryInsert args =
    Request.post
        [ "public_api", "xql_library", "insert" ]
        (encodeLibraryInsertBody args)
        (reply libraryInsertResultDecoder)


{-| POST /public\_api/xql\_library/delete — remove saved XQL queries by
name or by tag.
-}
libraryDelete : LibraryDeleteArgs -> Request LibraryDeleteResult
libraryDelete args =
    Request.post
        [ "public_api", "xql_library", "delete" ]
        (encodeLibraryDeleteBody args)
        (reply libraryDeleteResultDecoder)



-- ENCODERS


encodeStartQueryBody : StartQueryArgs -> Encode.Value
encodeStartQueryBody args =
    let
        fields =
            List.filterMap identity
                [ Just ( "query", Encode.string args.query )
                , if List.isEmpty args.tenants then
                    Nothing

                  else
                    Just ( "tenants", Encode.list Encode.string args.tenants )
                , Maybe.map (\tf -> ( "timeframe", encodeTimeframe tf )) args.timeframe
                ]
    in
    Encode.object [ ( "request_data", Encode.object fields ) ]


encodeGetResultsBody : GetResultsArgs -> Encode.Value
encodeGetResultsBody args =
    let
        fields =
            List.filterMap identity
                [ Just ( "query_id", Encode.string args.queryId )
                , Maybe.map (\f -> ( "pending_flag", Encode.bool f )) args.pendingFlag
                , Maybe.map (\l -> ( "limit", Encode.int l )) args.limit
                , Maybe.map (\f -> ( "format", Encode.string f )) args.format
                ]
    in
    Encode.object [ ( "request_data", Encode.object fields ) ]


encodeStreamBody : StreamArgs -> Encode.Value
encodeStreamBody args =
    let
        fields =
            List.filterMap identity
                [ Just ( "stream_id", Encode.string args.streamId )
                , Maybe.map (\g -> ( "is_gzip_compressed", Encode.bool g )) args.isGzipCompressed
                ]
    in
    Encode.object [ ( "request_data", Encode.object fields ) ]


encodeTimeframe : Timeframe -> Encode.Value
encodeTimeframe tf =
    case tf of
        Relative ms ->
            Encode.object [ ( "relativeTime", Encode.int ms ) ]

        Range r ->
            Encode.object
                [ ( "from", Encode.int r.from )
                , ( "to", Encode.int r.to )
                ]


encodeLookupAddBody : LookupAddArgs -> Encode.Value
encodeLookupAddBody args =
    let
        fields =
            List.filterMap identity
                [ Just ( "dataset_name", Encode.string args.datasetName )
                , if List.isEmpty args.keyFields then
                    Nothing

                  else
                    Just ( "key_fields", Encode.list Encode.string args.keyFields )
                , Just ( "data", args.data )
                ]
    in
    Encode.object [ ( "request_data", Encode.object fields ) ]


encodeLookupGetBody : LookupGetArgs -> Encode.Value
encodeLookupGetBody args =
    let
        encodePairs : List ( String, String ) -> Encode.Value
        encodePairs pairs =
            Encode.object (List.map (\( k, v ) -> ( k, Encode.string v )) pairs)

        fields =
            List.filterMap identity
                [ Just ( "dataset_name", Encode.string args.datasetName )
                , if List.isEmpty args.filters then
                    Nothing

                  else
                    Just ( "filters", Encode.list encodePairs args.filters )
                , Maybe.map (\l -> ( "limit", Encode.int l )) args.limit
                ]
    in
    Encode.object [ ( "request_data", Encode.object fields ) ]


encodeLookupRemoveBody : LookupRemoveArgs -> Encode.Value
encodeLookupRemoveBody args =
    let
        filterObject =
            Encode.object
                (List.map (\( k, v ) -> ( k, Encode.string v )) args.filters)
    in
    Encode.object
        [ ( "request_data"
          , Encode.object
                [ ( "dataset_name", Encode.string args.datasetName )
                , ( "filters", filterObject )
                ]
          )
        ]


encodeLibraryInsertBody : LibraryInsertArgs -> Encode.Value
encodeLibraryInsertBody args =
    let
        encodeOne q =
            Encode.object
                [ ( "xql_query_name", Encode.string q.name )
                , ( "xql_query", Encode.string q.query )
                ]

        fields =
            List.filterMap identity
                [ Just ( "xql_queries", Encode.list encodeOne args.xqlQueries )
                , if args.override then
                    Just ( "xql_queries_override", Encode.bool True )

                  else
                    Nothing
                , if List.isEmpty args.tags then
                    Nothing

                  else
                    Just ( "xql_query_tags", Encode.list Encode.string args.tags )
                ]
    in
    Encode.object [ ( "request_data", Encode.object fields ) ]


encodeLibraryDeleteBody : LibraryDeleteArgs -> Encode.Value
encodeLibraryDeleteBody args =
    let
        criterionField =
            case args.criteria of
                ByNames names ->
                    ( "xql_query_names", Encode.list Encode.string names )

                ByTags tags ->
                    ( "xql_query_tags", Encode.list Encode.string tags )
    in
    Encode.object
        [ ( "request_data", Encode.object [ criterionField ] ) ]



-- DECODERS


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
        {- Decoder escape: server-defined per-query active-queries map;
           keys/values are tenant-scoped and not in the published schema.
           Preserved verbatim — see the same-rationale comment below.
        -}
        (Decode.oneOf
            [ Decode.field "current_concurrent_active_queries" Decode.value
            , Decode.succeed Encode.null
            ]
        )
        |> andMap (Decode.maybe (Decode.field "current_concurrent_active_queries_count" Decode.int))
        |> andMap (Decode.maybe (Decode.field "max_daily_concurrent_active_query_count" Decode.int))



{- Quota.currentConcurrentActiveQueries stays as bare Encode.Value rather
   than Maybe Encode.Value so the existing canonical typedAssert example
   in TestMain (XqlGetQuota) keeps its straightforward record-field shape.
-}


datasetDecoder : Decoder Dataset
datasetDecoder =
    Decode.succeed Dataset
        |> andMap (eitherStringField "Dataset Name" "dataset_name")
        |> andMap (eitherStringField "Type" "type")
        |> andMap (eitherStringField "Log Update Type" "log_update_type")
        |> andMap (eitherIntField "Last Updated" "last_updated")
        |> andMap (eitherIntField "Total Days Stored" "total_days_stored")
        |> andMap (eitherRangeField "Hot Range" "hot_range")
        |> andMap (eitherRangeField "Cold Range" "cold_range")
        |> andMap (eitherIntField "Total Size Stored" "total_size_stored")
        |> andMap (eitherIntField "Average Daily Size" "average_daily_size")
        |> andMap (eitherIntField "Total Events" "total_events")
        |> andMap (eitherIntField "Average Event Size" "average_event_size")
        |> andMap (eitherIntField "TTL" "ttl")
        |> andMap (eitherStringField "Default Query Target" "default_query_target")


eitherStringField : String -> String -> Decoder (Maybe String)
eitherStringField primary fallback =
    Decode.oneOf
        [ Decode.field primary Decode.string |> Decode.map Just
        , Decode.field fallback Decode.string |> Decode.map Just
        , Decode.succeed Nothing
        ]


eitherIntField : String -> String -> Decoder (Maybe Int)
eitherIntField primary fallback =
    Decode.oneOf
        [ Decode.field primary Decode.int |> Decode.map Just
        , Decode.field fallback Decode.int |> Decode.map Just
        , Decode.succeed Nothing
        ]


eitherRangeField : String -> String -> Decoder (Maybe DatasetRange)
eitherRangeField primary fallback =
    Decode.oneOf
        [ Decode.field primary rangeDecoder |> Decode.map Just
        , Decode.field fallback rangeDecoder |> Decode.map Just
        , Decode.succeed Nothing
        ]


rangeDecoder : Decoder DatasetRange
rangeDecoder =
    Decode.map2 DatasetRange
        (Decode.maybe (Decode.field "from" Decode.int))
        (Decode.maybe (Decode.field "to" Decode.int))


eitherListField : String -> String -> Decoder a -> Decoder (List a)
eitherListField primary fallback itemDecoder =
    Decode.oneOf
        [ Decode.field primary (Decode.list itemDecoder)
        , Decode.field fallback (Decode.list itemDecoder)
        , Decode.succeed []
        ]


libraryDecoder : Decoder Library
libraryDecoder =
    Decode.map2 Library
        (Decode.maybe (Decode.field "queries_count" Decode.int))
        (optionalList "xql_queries" libraryQueryDecoder)


libraryQueryDecoder : Decoder LibraryQuery
libraryQueryDecoder =
    Decode.succeed LibraryQuery
        |> andMap (Decode.maybe (Decode.field "id" Decode.int))
        |> andMap (eitherStringField "xql_query_name" "name")
        |> andMap (Decode.maybe (Decode.field "description" Decode.string))
        |> andMap (eitherStringField "xql_query" "query_text")
        |> andMap (Decode.maybe (Decode.field "created_at" Decode.int))
        |> andMap (Decode.maybe (Decode.field "created_by" Decode.string))
        |> andMap (Decode.maybe (Decode.field "created_by_pretty" Decode.string))
        |> andMap (Decode.maybe (Decode.field "modified_at" Decode.int))
        |> andMap (Decode.maybe (Decode.field "modified_by" Decode.string))
        |> andMap (Decode.maybe (Decode.field "modified_by_pretty" Decode.string))
        {- Decoder escape: free-form query metadata blob; shape varies per
           query and is not in the OpenAPI spec.
        -}
        |> andMap (Decode.maybe (Decode.field "query_metadata" Decode.value))
        |> andMap (Decode.maybe (Decode.field "is_private" Decode.bool))
        |> andMap (eitherListField "xql_query_tags" "labels" Decode.string)


statusDecoder : Decoder QueryStatus
statusDecoder =
    Decode.string
        |> Decode.map
            (\s ->
                case s of
                    "PENDING" ->
                        Pending

                    "SUCCESS" ->
                        Success

                    "FAIL" ->
                        Fail

                    other ->
                        OtherStatus other
            )


queryResultsDecoder : Decoder QueryResults
queryResultsDecoder =
    Decode.map7 QueryResults
        (Decode.field "status" statusDecoder)
        (Decode.maybe (Decode.field "number_of_results" Decode.int))
        {- Decoder escape: query-cost counter map keyed by data-source name
           with floating-point values; keys depend on the query and are
           tenant-scoped. Preserved verbatim.
        -}
        (Decode.maybe
            (Decode.oneOf
                [ Decode.field "query_cost_charged" Decode.value
                , Decode.field "query_cost" Decode.value
                ]
            )
        )
        (Decode.maybe (Decode.field "remaining_quota" Decode.float))
        (Decode.maybe (Decode.field "remaining_yearly_quota" Decode.float))
        {- Decoder escape: XQL result rows — shape is determined by the
           user-supplied query (`SELECT ...`) and cannot be typed at the
           SDK layer. Each row is preserved verbatim.
        -}
        (Decode.oneOf
            [ Decode.at [ "results", "data" ] (Decode.list Decode.value)
            , Decode.succeed []
            ]
        )
        (Decode.maybe (Decode.at [ "results", "stream_id" ] Decode.string))


{-| Lookup endpoints in the OpenAPI spec return their payload at the top
level, but individual tenants sometimes wrap it in the usual `reply`
envelope. Try both.
-}
maybeReply : Decoder a -> Decoder a
maybeReply inner =
    Decode.oneOf [ reply inner, inner ]


lookupAddResultDecoder : Decoder LookupAddResult
lookupAddResultDecoder =
    Decode.map3 LookupAddResult
        (Decode.maybe (Decode.field "added" Decode.int))
        (Decode.maybe (Decode.field "updated" Decode.int))
        (Decode.maybe (Decode.field "skipped" Decode.int))


lookupGetResultDecoder : Decoder LookupGetResult
lookupGetResultDecoder =
    Decode.map3 LookupGetResult
        {- Decoder escape: lookup-table rows whose columns are defined by
           the lookup schema the tenant provisioned. Opaque to the SDK.
        -}
        (Decode.maybe (Decode.field "data" Decode.value))
        (Decode.maybe (Decode.field "filter_count" Decode.int))
        (Decode.maybe (Decode.field "total_count" Decode.int))


lookupRemoveResultDecoder : Decoder LookupRemoveResult
lookupRemoveResultDecoder =
    Decode.map LookupRemoveResult
        (Decode.maybe (Decode.field "deleted" Decode.int))


libraryInsertResultDecoder : Decoder LibraryInsertResult
libraryInsertResultDecoder =
    Decode.map3 LibraryInsertResult
        (optionalList "xql_queries_added" Decode.string)
        (optionalList "xql_queries_updated" Decode.string)
        (optionalList "errors" libraryInsertErrorDecoder)


libraryInsertErrorDecoder : Decoder LibraryInsertError
libraryInsertErrorDecoder =
    {- The API serializes each error as a two-element array `[name,
       message]` rather than the object the spec implies. Decode that
       shape into a typed record.
    -}
    Decode.list Decode.string
        |> Decode.andThen
            (\xs ->
                case xs of
                    [ name, message ] ->
                        Decode.succeed { name = name, message = message }

                    _ ->
                        Decode.fail "expected [name, message] pair"
            )


libraryDeleteResultDecoder : Decoder LibraryDeleteResult
libraryDeleteResultDecoder =
    Decode.map3 LibraryDeleteResult
        (Decode.oneOf [ Decode.field "queries_count" Decode.int, Decode.succeed 0 ])
        (optionalList "xql_query_names" Decode.string)
        {- Decoder escape: per-spec error objects are free-form `object[]`
           with no inner schema; preserved verbatim until a sample drives
           a typed decoder.
        -}
        (optionalList "errors" Decode.value)
