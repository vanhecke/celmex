module Cortex.Api.Indicators exposing
    ( Indicator, IndicatorsResponse
    , get
    )

{-| Cortex threat intelligence indicators (IOCs).

@docs Indicator, IndicatorsResponse
@docs get

-}

import Cortex.Decode exposing (andMap)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Envelope returned by [`get`](#get). Not wrapped in the standard `reply`.
-}
type alias IndicatorsResponse =
    { objectsCount : Maybe Int
    , objects : List Indicator
    , objectsType : Maybe String
    }


{-| A single threat-intelligence indicator (hash, domain, URL, IP, etc.).
The `reputation` and `reliability` fields carry per-source sub-objects whose
shape varies, so they are kept as raw JSON.
-}
type alias Indicator =
    { ruleId : Maybe Int
    , indicator : Maybe String
    , type_ : Maybe String
    , severity : Maybe String
    , expirationDate : Maybe Int
    , defaultExpirationEnabled : Maybe Bool
    , comment : Maybe String
    , reputation : Encode.Value
    , reliability : Encode.Value
    }


{-| POST /public\_api/v1/indicators/get

Response is top-level `{objects_count, objects, objects_type}` — NOT wrapped
in the usual `reply` envelope.

-}
get : Request IndicatorsResponse
get =
    Request.postEmpty
        [ "public_api", "v1", "indicators", "get" ]
        indicatorsResponseDecoder


indicatorsResponseDecoder : Decoder IndicatorsResponse
indicatorsResponseDecoder =
    Decode.map3 IndicatorsResponse
        (Decode.maybe (Decode.field "objects_count" Decode.int))
        (Decode.oneOf
            [ Decode.field "objects" (Decode.list indicatorDecoder)
            , Decode.succeed []
            ]
        )
        (Decode.maybe (Decode.field "objects_type" Decode.string))


indicatorDecoder : Decoder Indicator
indicatorDecoder =
    Decode.map8 Indicator
        (Decode.maybe (Decode.field "rule_id" Decode.int))
        (Decode.maybe (Decode.field "indicator" Decode.string))
        (Decode.maybe (Decode.field "type" Decode.string))
        (Decode.maybe (Decode.field "severity" Decode.string))
        (Decode.maybe (Decode.field "expiration_date" Decode.int))
        (Decode.maybe (Decode.field "default_expiration_enabled" Decode.bool))
        (Decode.maybe (Decode.field "comment" Decode.string))
        (Decode.oneOf
            [ Decode.field "reputation" Decode.value
            , Decode.succeed Encode.null
            ]
        )
        |> andMap
            (Decode.oneOf
                [ Decode.field "reliability" Decode.value
                , Decode.succeed Encode.null
                ]
            )
