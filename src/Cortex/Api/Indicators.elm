module Cortex.Api.Indicators exposing
    ( Indicator
    , IndicatorsResponse
    , encode
    , get
    )

import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias IndicatorsResponse =
    { objectsCount : Maybe Int
    , objects : List Indicator
    , objectsType : Maybe String
    }


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
    Request.post
        [ "public_api", "v1", "indicators", "get" ]
        (Encode.object [ ( "request_data", Encode.object [] ) ])
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


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap valDecoder funcDecoder =
    Decode.map2 (\f v -> f v) funcDecoder valDecoder


encode : IndicatorsResponse -> Encode.Value
encode r =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "objects_count", Encode.int v )) r.objectsCount
            , Just ( "objects", Encode.list encodeIndicator r.objects )
            , Maybe.map (\v -> ( "objects_type", Encode.string v )) r.objectsType
            ]
        )


encodeIndicator : Indicator -> Encode.Value
encodeIndicator i =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "rule_id", Encode.int v )) i.ruleId
            , Maybe.map (\v -> ( "indicator", Encode.string v )) i.indicator
            , Maybe.map (\v -> ( "type", Encode.string v )) i.type_
            , Maybe.map (\v -> ( "severity", Encode.string v )) i.severity
            , Maybe.map (\v -> ( "expiration_date", Encode.int v )) i.expirationDate
            , Maybe.map (\v -> ( "default_expiration_enabled", Encode.bool v )) i.defaultExpirationEnabled
            , Maybe.map (\v -> ( "comment", Encode.string v )) i.comment
            , Just ( "reputation", i.reputation )
            , Just ( "reliability", i.reliability )
            ]
        )
