module Cli.Encode.Correlations exposing (encode)

import Cortex.Api.Correlations exposing (CorrelationsResponse)
import Json.Encode as Encode


encode : CorrelationsResponse -> Encode.Value
encode r =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "objects_count", Encode.int v )) r.objectsCount
            , Just ( "objects", Encode.list identity r.objects )
            , Maybe.map (\v -> ( "objects_type", Encode.string v )) r.objectsType
            ]
        )
