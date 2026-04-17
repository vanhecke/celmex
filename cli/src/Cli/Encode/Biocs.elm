module Cli.Encode.Biocs exposing (encode)

import Cortex.Api.Biocs exposing (BiocsResponse)
import Json.Encode as Encode


encode : BiocsResponse -> Encode.Value
encode r =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "objects_count", Encode.int v )) r.objectsCount
            , Just ( "objects", Encode.list identity r.objects )
            , Maybe.map (\v -> ( "objects_type", Encode.string v )) r.objectsType
            ]
        )
