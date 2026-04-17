module Cortex.Api.Biocs exposing
    ( BiocsResponse
    , get
    )

{-| Cortex behavioral indicators of compromise (BIOCs).

@docs BiocsResponse
@docs get

-}

import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| BIOC objects have ~15 variable fields including a nested `indicator` object
whose shape depends on the rule type. We decode the BIOC items as raw JSON so
every field is preserved without duplicating the whole Cortex BIOC schema here.
-}
type alias BiocsResponse =
    { objectsCount : Maybe Int
    , objects : List Encode.Value
    , objectsType : Maybe String
    }


{-| POST /public\_api/v1/bioc/get

Response is top-level `{objects_count, objects, objects_type}` — NOT wrapped
in the usual `reply` envelope.

-}
get : Request BiocsResponse
get =
    Request.post
        [ "public_api", "v1", "bioc", "get" ]
        (Encode.object [ ( "request_data", Encode.object [] ) ])
        biocsResponseDecoder


biocsResponseDecoder : Decoder BiocsResponse
biocsResponseDecoder =
    Decode.map3 BiocsResponse
        (Decode.maybe (Decode.field "objects_count" Decode.int))
        (Decode.oneOf
            [ Decode.field "objects" (Decode.list Decode.value)
            , Decode.succeed []
            ]
        )
        (Decode.maybe (Decode.field "objects_type" Decode.string))
