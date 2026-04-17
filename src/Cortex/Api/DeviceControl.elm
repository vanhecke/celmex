module Cortex.Api.DeviceControl exposing
    ( ViolationsResponse
    , getViolations
    )

{-| Cortex device-control policy violations.

@docs ViolationsResponse
@docs getViolations

-}

import Cortex.Decode exposing (reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Paginated envelope of raw violation rows returned by [`getViolations`](#getViolations).
Violations have too many variable fields to type exhaustively, so each row is preserved as JSON.
-}
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
