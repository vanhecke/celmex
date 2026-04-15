module Cortex.Api.Correlations exposing
    ( CorrelationsResponse
    , encode
    , get
    )

import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Correlation rule objects contain ~20 variable fields including query text
and complex nested configuration. We decode them as raw JSON to preserve every
field without mirroring the whole Cortex correlation-rules schema.
-}
type alias CorrelationsResponse =
    { objectsCount : Maybe Int
    , objects : List Encode.Value
    , objectsType : Maybe String
    }


{-| POST /public\_api/v1/correlations/get

Response is top-level `{objects_count, objects, objects_type}` — NOT wrapped
in the usual `reply` envelope.

-}
get : Request CorrelationsResponse
get =
    Request.post
        [ "public_api", "v1", "correlations", "get" ]
        (Encode.object [ ( "request_data", Encode.object [] ) ])
        correlationsResponseDecoder


correlationsResponseDecoder : Decoder CorrelationsResponse
correlationsResponseDecoder =
    Decode.map3 CorrelationsResponse
        (Decode.maybe (Decode.field "objects_count" Decode.int))
        (Decode.oneOf
            [ Decode.field "objects" (Decode.list Decode.value)
            , Decode.succeed []
            ]
        )
        (Decode.maybe (Decode.field "objects_type" Decode.string))


encode : CorrelationsResponse -> Encode.Value
encode r =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "objects_count", Encode.int v )) r.objectsCount
            , Just ( "objects", Encode.list identity r.objects )
            , Maybe.map (\v -> ( "objects_type", Encode.string v )) r.objectsType
            ]
        )
