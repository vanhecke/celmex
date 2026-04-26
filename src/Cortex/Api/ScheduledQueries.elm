module Cortex.Api.ScheduledQueries exposing
    ( SearchArgs, defaultSearchArgs
    , ScheduledQueriesResponse
    , list
    )

{-| Cortex scheduled XQL queries configured on the tenant.

@docs SearchArgs, defaultSearchArgs
@docs ScheduledQueriesResponse
@docs list

-}

import Cortex.Decode exposing (reply)
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


{-| Scheduled-query records contain a large, flexible set of fields (XQL text,
timeframe, tenants, trigger config, etc.) that vary by query type. We preserve
each record as raw JSON and only type the top-level envelope counters.
-}
type alias ScheduledQueriesResponse =
    { data : List Encode.Value
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| POST /public\_api/v1/scheduled\_queries/list
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


responseDecoder : Decoder ScheduledQueriesResponse
responseDecoder =
    Decode.map3 ScheduledQueriesResponse
        (Decode.oneOf
            [ Decode.field "DATA" (Decode.list Decode.value)
            , Decode.field "data" (Decode.list Decode.value)
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
