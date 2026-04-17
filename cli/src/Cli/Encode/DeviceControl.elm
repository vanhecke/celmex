module Cli.Encode.DeviceControl exposing (encodeViolations)

import Cortex.Api.DeviceControl exposing (ViolationsResponse)
import Json.Encode as Encode


encodeViolations : ViolationsResponse -> Encode.Value
encodeViolations r =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "total_count", Encode.int v )) r.totalCount
            , Maybe.map (\v -> ( "result_count", Encode.int v )) r.resultCount
            , Just ( "violations", Encode.list identity r.violations )
            ]
        )
