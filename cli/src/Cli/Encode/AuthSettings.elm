module Cli.Encode.AuthSettings exposing (encode)

import Json.Encode as Encode


encode : List Encode.Value -> Encode.Value
encode settings =
    Encode.list identity settings
