module Cortex.Api.ScheduledQueries exposing
    ( SearchArgs, defaultSearchArgs
    , ScheduledQuery, Schedule, ScheduledQueriesResponse
    , list
    , InsertArgs, QueryDefinition, ScheduleSpec(..), CronSpec, InsertedQuery, InsertResult
    , insert
    , DeleteArgs, DeleteOutcome(..), DeleteResult
    , delete
    )

{-| Cortex scheduled XQL queries configured on the tenant.

@docs SearchArgs, defaultSearchArgs
@docs ScheduledQuery, Schedule, ScheduledQueriesResponse
@docs list
@docs InsertArgs, QueryDefinition, ScheduleSpec, CronSpec, InsertedQuery, InsertResult
@docs insert
@docs DeleteArgs, DeleteOutcome, DeleteResult
@docs delete

-}

import Cortex.Decode exposing (andMap, optionalField, reply)
import Cortex.Query as Query exposing (Filter, Range, Sort, Timeframe)
import Cortex.Request as Request exposing (Request)
import Cortex.RequestData as RequestData
import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Arguments to [`list`](#list). All fields are optional; pass
[`defaultSearchArgs`](#defaultSearchArgs) for an unfiltered request. `extra`
is merged last into `request_data` and overrides any SDK-generated key on
collision — the endpoint's `extended_view` and `list_ids` fields are
reachable through it.
-}
type alias SearchArgs =
    { filters : List Filter
    , sort : Maybe Sort
    , range : Maybe Range
    , timeframe : Maybe Timeframe
    , extra : List ( String, Encode.Value )
    }


{-| A [`SearchArgs`](#SearchArgs) with no filters, sort, pagination, or
timeframe.
-}
defaultSearchArgs : SearchArgs
defaultSearchArgs =
    { filters = []
    , sort = Nothing
    , range = Nothing
    , timeframe = Nothing
    , extra = []
    }


{-| Paginated envelope returned by [`list`](#list).
-}
type alias ScheduledQueriesResponse =
    { data : List ScheduledQuery
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| One scheduled XQL query configured on the tenant.
-}
type alias ScheduledQuery =
    { queryDefId : Maybe String
    , queryDefinitionName : Maybe String
    , xql : Maybe String
    , enable : Maybe Bool
    , schedule : Maybe Schedule

    {- timeframe is documented as `{ relativeTime: ? }` but the
       relativeTime value is polymorphic (string label like "asdasdasd"
       in one example, int milliseconds 86400000 in another), and the
       object is sometimes empty. Preserved verbatim until the wire
       format stabilises.
    -}
    , timeframe : Maybe Encode.Value

    {- tenants is `nullable object` per spec — populated only for MSSP
       (managed-security) configurations with a tenant-specific shape
       that varies per integration. Preserved verbatim.
    -}
    , tenants : Maybe Encode.Value
    }


{-| Trigger schedule for a [`ScheduledQuery`](#ScheduledQuery). All
fields optional — only the subset relevant to the trigger type is
populated. `triggerType = "date"` populates `runDate`; `"cron"` populates
`startDate` / `endDate` / `hour` / `minute` / `second` / `dayOfWeek` /
`week` / `month`.
-}
type alias Schedule =
    { triggerType : Maybe String
    , runDate : Maybe Int
    , startDate : Maybe Int
    , endDate : Maybe Int
    , hour : Maybe String
    , minute : Maybe String
    , second : Maybe String
    , dayOfWeek : Maybe String
    , week : Maybe String
    , month : Maybe String
    }


{-| POST /public\_api/v1/scheduled\_queries/list

Retrieve scheduled XQL queries currently configured on the tenant, with
optional filters and pagination. Requires Instance Administrator
permissions.

-}
list : SearchArgs -> Request ScheduledQueriesResponse
list args =
    Request.post
        [ "public_api", "v1", "scheduled_queries", "list" ]
        (RequestData.encode Query.standard
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        (reply responseDecoder)



-- DECODERS


responseDecoder : Decoder ScheduledQueriesResponse
responseDecoder =
    Decode.map3 ScheduledQueriesResponse
        (Decode.oneOf
            [ Decode.field "DATA" (Decode.list scheduledQueryDecoder)
            , Decode.field "data" (Decode.list scheduledQueryDecoder)
            , Decode.succeed []
            ]
        )
        (Decode.maybe
            (Decode.oneOf
                [ Decode.field "FILTER_COUNT" Decode.int
                , Decode.field "filter_count" Decode.int
                ]
            )
        )
        (Decode.maybe
            (Decode.oneOf
                [ Decode.field "TOTAL_COUNT" Decode.int
                , Decode.field "total_count" Decode.int
                ]
            )
        )


scheduledQueryDecoder : Decoder ScheduledQuery
scheduledQueryDecoder =
    Decode.succeed ScheduledQuery
        |> andMap (optionalField "query_def_id" Decode.string)
        |> andMap (optionalField "query_definition_name" Decode.string)
        |> andMap (optionalField "xql" Decode.string)
        |> andMap (optionalField "enable" Decode.bool)
        |> andMap (optionalField "schedule" scheduleDecoder)
        {- Decoder escape: free-form timeframe selector; shape varies per
           query (relative window, absolute range, etc.) and is opaque.
        -}
        |> andMap (optionalField "timeframe" Decode.value)
        {- Decoder escape: free-form tenants selector; shape varies per
           query (single tenant, list, predicate, etc.) and is opaque.
        -}
        |> andMap (optionalField "tenants" Decode.value)


scheduleDecoder : Decoder Schedule
scheduleDecoder =
    Decode.succeed Schedule
        |> andMap (optionalField "trigger_type" Decode.string)
        |> andMap (optionalField "run_date" Decode.int)
        |> andMap (optionalField "start_date" Decode.int)
        |> andMap (optionalField "end_date" Decode.int)
        |> andMap (optionalField "hour" Decode.string)
        |> andMap (optionalField "minute" Decode.string)
        |> andMap (optionalField "second" Decode.string)
        |> andMap (optionalField "day_of_week" Decode.string)
        |> andMap (optionalField "week" Decode.string)
        |> andMap (optionalField "month" Decode.string)



-- INSERT


{-| Arguments to [`insert`](#insert). `queries` is the batch of definitions
to send.
-}
type alias InsertArgs =
    { queries : List QueryDefinition
    }


{-| One query definition to insert. `relativeTimeMs` is the rolling-window
size that the query inspects on every run, in epoch-milliseconds (e.g.
`86400000` for the last 24 hours).
-}
type alias QueryDefinition =
    { name : String
    , xql : String
    , relativeTimeMs : Int
    , schedule : ScheduleSpec
    }


{-| Trigger schedule for an inserted query. `OneShot` runs the query a
single time at `runAtMs` (epoch-milliseconds, must be in the future);
`Cron` runs on a recurring crontab-style schedule.
-}
type ScheduleSpec
    = OneShot { runAtMs : Int }
    | Cron CronSpec


{-| Cron-style trigger fields. Each `Maybe String` carries either a single
value (e.g. `"5"`) or a comma-separated list / `*` wildcard accepted by
the Cortex scheduler. `startDate` / `endDate` bound the active window in
epoch-milliseconds; the other fields are minute/hour/etc.
-}
type alias CronSpec =
    { startDate : Maybe Int
    , endDate : Maybe Int
    , hour : Maybe String
    , minute : Maybe String
    , second : Maybe String
    , dayOfWeek : Maybe String
    , week : Maybe String
    , month : Maybe String
    }


{-| The server-echoed definition returned in the [`InsertResult`](#InsertResult)
dict, keyed by the assigned `query_id`. `timeframe` stays opaque for the
same reasons as [`ScheduledQuery`](#ScheduledQuery)`.timeframe`.
-}
type alias InsertedQuery =
    { name : Maybe String
    , xql : Maybe String

    {- Decoder escape: timeframe selector echoed verbatim — the
       relativeTime field is polymorphic across the live tenant (string
       label vs int milliseconds vs empty object).
    -}
    , timeframe : Maybe Encode.Value
    , schedule : Maybe Schedule
    }


{-| Outcome of an [`insert`](#insert) call: a `Dict` keyed by the assigned
`query_id` (e.g. `"qc_1683461522_18780"`) → the echoed definition. Empty
for a request that was rejected before any item was processed.
-}
type alias InsertResult =
    Dict String InsertedQuery


{-| POST /public\_api/v1/scheduled\_queries/insert — insert a batch of
scheduled XQL queries. The server assigns each query a fresh ID; consult
the keys of the returned [`InsertResult`](#InsertResult) to delete or
manage them later.
-}
insert : InsertArgs -> Request InsertResult
insert args =
    Request.post
        [ "public_api", "v1", "scheduled_queries", "insert" ]
        (Encode.object
            [ ( "request_data", Encode.list encodeQueryDefinition args.queries ) ]
        )
        (reply insertResultDecoder)



-- DELETE


{-| Arguments to [`delete`](#delete). `ids` may be the assigned `query_id`
strings or the human-readable `query_definition_name` values; the API
accepts either.
-}
type alias DeleteArgs =
    { ids : List String
    }


{-| Per-id outcome inside [`DeleteResult`](#DeleteResult). `Deleted` is the
server's `true` reply; `DeleteFailed` carries the human-readable rejection
reason.
-}
type DeleteOutcome
    = Deleted
    | DeleteFailed String


{-| Outcome of a [`delete`](#delete) call: a `Dict` keyed by the same
`ids` the caller submitted → success/failure.
-}
type alias DeleteResult =
    Dict String DeleteOutcome


{-| POST /public\_api/v1/scheduled\_queries/delete — remove scheduled
queries by id or by name.
-}
delete : DeleteArgs -> Request DeleteResult
delete args =
    Request.post
        [ "public_api", "v1", "scheduled_queries", "delete" ]
        (Encode.object
            [ ( "request_data", Encode.list Encode.string args.ids ) ]
        )
        (reply deleteResultDecoder)



-- INSERT/DELETE ENCODERS


encodeQueryDefinition : QueryDefinition -> Encode.Value
encodeQueryDefinition q =
    Encode.object
        [ ( "query_definition_name", Encode.string q.name )
        , ( "xql", Encode.string q.xql )
        , ( "timeframe"
          , Encode.object [ ( "relativeTime", Encode.int q.relativeTimeMs ) ]
          )
        , ( "schedule", encodeScheduleSpec q.schedule )
        ]


encodeScheduleSpec : ScheduleSpec -> Encode.Value
encodeScheduleSpec spec =
    case spec of
        OneShot { runAtMs } ->
            Encode.object
                [ ( "trigger_type", Encode.string "date" )
                , ( "run_date", Encode.int runAtMs )
                ]

        Cron cron ->
            Encode.object
                (( "trigger_type", Encode.string "cron" )
                    :: List.filterMap identity
                        [ Maybe.map (\v -> ( "start_date", Encode.int v )) cron.startDate
                        , Maybe.map (\v -> ( "end_date", Encode.int v )) cron.endDate
                        , Maybe.map (\v -> ( "hour", Encode.string v )) cron.hour
                        , Maybe.map (\v -> ( "minute", Encode.string v )) cron.minute
                        , Maybe.map (\v -> ( "second", Encode.string v )) cron.second
                        , Maybe.map (\v -> ( "day_of_week", Encode.string v )) cron.dayOfWeek
                        , Maybe.map (\v -> ( "week", Encode.string v )) cron.week
                        , Maybe.map (\v -> ( "month", Encode.string v )) cron.month
                        ]
                )



-- INSERT/DELETE DECODERS


insertResultDecoder : Decoder InsertResult
insertResultDecoder =
    Decode.dict insertedQueryDecoder


insertedQueryDecoder : Decoder InsertedQuery
insertedQueryDecoder =
    Decode.map4 InsertedQuery
        (optionalField "query_definition_name" Decode.string)
        (optionalField "xql" Decode.string)
        {- Decoder escape: timeframe selector echoed verbatim — see the
           field-level comment on InsertedQuery.
        -}
        (optionalField "timeframe" Decode.value)
        (optionalField "schedule" scheduleDecoder)


deleteResultDecoder : Decoder DeleteResult
deleteResultDecoder =
    Decode.dict deleteOutcomeDecoder


deleteOutcomeDecoder : Decoder DeleteOutcome
deleteOutcomeDecoder =
    Decode.oneOf
        [ Decode.bool
            |> Decode.map
                (\b ->
                    if b then
                        Deleted

                    else
                        DeleteFailed "false"
                )
        , Decode.string |> Decode.map DeleteFailed
        ]
