module Cli.Encode.Healthcheck exposing (encode)

import Cortex.Api.Healthcheck exposing (HealthcheckResponse)
import Json.Encode as Encode


encode : HealthcheckResponse -> Encode.Value
encode response =
    Encode.object
        [ ( "status", Encode.string response.status )
        ]
