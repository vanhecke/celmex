module Cli.Flags exposing (Flags, decoder)

import Json.Decode as Decode


type alias Flags =
    { argv : List String
    , tenant : String
    , apiKeyId : String
    , apiKey : String
    , timestamp : Int
    , nonce : String
    }


decoder : Decode.Decoder Flags
decoder =
    Decode.map6 Flags
        (Decode.field "argv" (Decode.list Decode.string))
        (Decode.field "tenant" Decode.string)
        (Decode.field "apiKeyId" Decode.string)
        (Decode.field "apiKey" Decode.string)
        (Decode.field "timestamp" Decode.int)
        (Decode.field "nonce" Decode.string)
