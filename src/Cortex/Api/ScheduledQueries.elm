module Cortex.Api.ScheduledQueries exposing
    ( SearchArgs, defaultSearchArgs
    , ScheduledQuery, Schedule, ScheduledQueriesResponse
    , list
    )

{-| Cortex scheduled XQL queries configured on the tenant.

@docs SearchArgs, defaultSearchArgs
@docs ScheduledQuery, Schedule, ScheduledQueriesResponse
@docs list

-}

import Cortex.Decode exposing (andMap, reply)
import Cortex.Query as Query exposing (Filter, Range, Sort, Timeframe)
import Cortex.Request as Request exposing (Request)
import Cortex.RequestData as RequestData
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
        |> andMap (optionalField "timeframe" Decode.value)
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


optionalField : String -> Decoder a -> Decoder (Maybe a)
optionalField name d =
    Decode.maybe (Decode.field name d)
