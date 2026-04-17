module Cortex.Api.DeviceControl exposing
    ( ViolationsResponse
    , getViolations
    )

import Cortex.Decode exposing (reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias ViolationsResponse =
    { totalCount : Maybe Int
    , resultCount : Maybe Int
    , violations : List Encode.Value
    }


{-| POST /public\_api/v1/device\_control/get\_violations
-}
getViolations : Request ViolationsResponse
getViolations =
    Request.postEmpty
        [ "public_api", "v1", "device_control", "get_violations" ]
        (reply violationsResponseDecoder)


violationsResponseDecoder : Decoder ViolationsResponse
violationsResponseDecoder =
    Decode.map3 ViolationsResponse
        (Decode.maybe (Decode.field "total_count" Decode.int))
        (Decode.maybe (Decode.field "result_count" Decode.int))
        (Decode.oneOf
            [ Decode.field "violations" (Decode.list Decode.value)
            , Decode.succeed []
            ]
        )
