module Cli.Encode.ScheduledQueries exposing (encode)

import Cortex.Api.ScheduledQueries exposing (ScheduledQueriesResponse)
import Json.Encode as Encode


encode : ScheduledQueriesResponse -> Encode.Value
encode r =
    Encode.object
        (List.filterMap identity
            [ Just ( "DATA", Encode.list identity r.data )
            , Maybe.map (\v -> ( "FILTER_COUNT", Encode.int v )) r.filterCount
            , Maybe.map (\v -> ( "TOTAL_COUNT", Encode.int v )) r.totalCount
            ]
        )
