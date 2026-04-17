module Cli.Encode.Indicators exposing (encode)

import Cortex.Api.Indicators exposing (Indicator, IndicatorsResponse)
import Json.Encode as Encode


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
