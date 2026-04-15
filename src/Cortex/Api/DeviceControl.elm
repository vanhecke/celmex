module Cortex.Api.DeviceControl exposing
    ( ViolationsResponse
    , encodeViolations
    , getViolations
    )

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
    Request.post
        [ "public_api", "v1", "device_control", "get_violations" ]
        (Encode.object [ ( "request_data", Encode.object [] ) ])
        (Decode.field "reply" violationsResponseDecoder)


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


encodeViolations : ViolationsResponse -> Encode.Value
encodeViolations r =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "total_count", Encode.int v )) r.totalCount
            , Maybe.map (\v -> ( "result_count", Encode.int v )) r.resultCount
            , Just ( "violations", Encode.list identity r.violations )
            ]
        )
