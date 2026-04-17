module Cortex.Api.AuthSettings exposing (get)

{-| Cortex tenant IdP/SSO authentication settings.

@docs get

-}

import Cortex.Decode exposing (reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| POST /public\_api/v1/authentication-settings/get/settings

Returns a raw list of authentication-settings objects (many nullable fields
whose shape varies by IdP configuration). We decode the reply as raw JSON
so every field is preserved verbatim.

-}
get : Request (List Encode.Value)
get =
    Request.postEmpty
        [ "public_api", "v1", "authentication-settings", "get", "settings" ]
        decoder


decoder : Decoder (List Encode.Value)
decoder =
    Decode.oneOf
        [ reply (Decode.list Decode.value)
        , Decode.succeed []
        ]
