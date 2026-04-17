module Cli.Encode.Issues exposing (encodeSearch)

import Cortex.Api.Issues exposing (SearchResponse)
import Json.Encode as Encode


encodeSearch : SearchResponse -> Encode.Value
encodeSearch r =
    Encode.object
        (List.filterMap identity
            [ Just ( "DATA", Encode.list identity r.data )
            , Maybe.map (\v -> ( "FILTER_COUNT", Encode.int v )) r.filterCount
            , Maybe.map (\v -> ( "TOTAL_COUNT", Encode.int v )) r.totalCount
            ]
        )
