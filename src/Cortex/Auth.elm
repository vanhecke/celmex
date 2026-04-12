module Cortex.Auth exposing
    ( Credentials
    , Stamp
    , nonceGenerator
    , sign
    )

import Http
import Random
import SHA256


type alias Credentials =
    { apiKeyId : String
    , apiKey : String
    }


type alias Stamp =
    { timestamp : Int
    , nonce : String
    }


{-| Produce the four Advanced API Auth headers.

    hash =
        SHA256.toHex (SHA256.fromString (apiKey ++ nonce ++ String.fromInt timestamp))

Headers sent:

  - Authorization: the hex SHA-256 hash
  - x-xdr-auth-id: the API key ID
  - x-xdr-timestamp: millis since epoch (as string)
  - x-xdr-nonce: the nonce string

-}
sign : Credentials -> Stamp -> List Http.Header
sign creds stamp =
    let
        hashInput =
            creds.apiKey ++ stamp.nonce ++ String.fromInt stamp.timestamp

        hash =
            SHA256.fromString hashInput |> SHA256.toHex
    in
    [ Http.header "Authorization" hash
    , Http.header "x-xdr-auth-id" creds.apiKeyId
    , Http.header "x-xdr-timestamp" (String.fromInt stamp.timestamp)
    , Http.header "x-xdr-nonce" stamp.nonce
    ]


{-| Generate a 64-character random nonce from [A-Za-z0-9].
Suitable for browser use where crypto.randomBytes is unavailable.
The CLI uses Node's crypto.randomBytes instead.
-}
nonceGenerator : Random.Generator String
nonceGenerator =
    let
        chars =
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

        charGen =
            Random.int 0 (String.length chars - 1)
                |> Random.map
                    (\i ->
                        String.slice i (i + 1) chars
                    )
    in
    Random.list 64 charGen
        |> Random.map (String.join "")
