module Cortex.Api.ScheduledQueries exposing
    ( ScheduledQueriesResponse
    , list
    )

import Cortex.Decode exposing (reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


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
list : Request ScheduledQueriesResponse
list =
    Request.postEmpty
        [ "public_api", "v1", "scheduled_queries", "list" ]
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
