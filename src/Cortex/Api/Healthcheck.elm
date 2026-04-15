module Cortex.Api.Healthcheck exposing
    ( HealthcheckResponse
    , check
    , encode
    )

import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias HealthcheckResponse =
    { status : String
    }


{-| GET /public\_api/v1/healthcheck

Perform a health check of the Cortex environment.
Returns a simple status string (e.g. "available").

-}
check : Request HealthcheckResponse
check =
    Request.get
        [ "public_api", "v1", "healthcheck" ]
        healthcheckResponseDecoder


healthcheckResponseDecoder : Decoder HealthcheckResponse
healthcheckResponseDecoder =
    Decode.map HealthcheckResponse
        (Decode.field "status" Decode.string)


encode : HealthcheckResponse -> Encode.Value
encode response =
    Encode.object
        [ ( "status", Encode.string response.status )
        ]
