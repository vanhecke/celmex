module Cortex.Api.DeviceControl exposing
    ( ViolationsResponse, Violation
    , getViolations
    )

{-| Cortex device-control policy violations — events where a peripheral
device (USB stick, optical drive, etc.) was blocked by an endpoint policy.

@docs ViolationsResponse, Violation
@docs getViolations

-}

import Cortex.Decode exposing (reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)


{-| Paginated envelope returned by [`getViolations`](#getViolations).
-}
type alias ViolationsResponse =
    { totalCount : Maybe Int
    , resultCount : Maybe Int
    , violations : List Violation
    }


{-| A single device-control violation — a peripheral that was blocked
on an endpoint by policy. Every field is `Maybe` because the API may
omit fields that are not relevant to the violation type (e.g.
`product_id` may be empty for unidentified devices).
-}
type alias Violation =
    { violationId : Maybe Int
    , timestamp : Maybe Int
    , type_ : Maybe String
    , hostname : Maybe String
    , username : Maybe String
    , ip : Maybe String
    , endpointId : Maybe String
    , vendor : Maybe String
    , vendorId : Maybe String
    , product : Maybe String
    , productId : Maybe String
    , serial : Maybe String
    }


{-| POST /public\_api/v1/device\_control/get\_violations

Get device-control violations matching the optional filters in
`request_data`. An empty body returns up to 100 results.

-}
getViolations : Request ViolationsResponse
getViolations =
    Request.postEmpty
        [ "public_api", "v1", "device_control", "get_violations" ]
        (reply violationsResponseDecoder)



-- DECODERS


violationsResponseDecoder : Decoder ViolationsResponse
violationsResponseDecoder =
    Decode.map3 ViolationsResponse
        (Decode.maybe (Decode.field "total_count" Decode.int))
        (Decode.maybe (Decode.field "result_count" Decode.int))
        (Decode.oneOf
            [ Decode.field "violations" (Decode.list violationDecoder)
            , Decode.succeed []
            ]
        )


violationDecoder : Decoder Violation
violationDecoder =
    Decode.map8 Violation
        (optionalField "violation_id" Decode.int)
        (optionalField "timestamp" Decode.int)
        (optionalField "type" Decode.string)
        (optionalField "hostname" Decode.string)
        (optionalField "username" Decode.string)
        (optionalField "ip" Decode.string)
        (optionalField "endpoint_id" Decode.string)
        (optionalField "vendor" Decode.string)
        |> andMap (optionalField "vendor_id" Decode.string)
        |> andMap (optionalField "product" Decode.string)
        |> andMap (optionalField "product_id" Decode.string)
        |> andMap (optionalField "serial" Decode.string)


optionalField : String -> Decoder a -> Decoder (Maybe a)
optionalField name d =
    Decode.maybe (Decode.field name d)


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Cortex.Decode.andMap
