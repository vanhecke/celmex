module Cli.Encode.Cli exposing (encode)

import Cortex.Api.Cli exposing (VersionResponse)
import Json.Encode as Encode


encode : VersionResponse -> Encode.Value
encode response =
    Encode.object
        [ ( "version", Encode.string response.version )
        ]
