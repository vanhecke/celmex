module Cortex.Auth exposing
    ( Credentials, Stamp
    , credentials, stamp
    , sign, nonceGenerator
    )

{-| Advanced-API Auth signing for Cortex. Each authenticated request carries
a SHA-256 hash of `apiKey ++ nonce ++ timestamp` plus three sidecar headers.

@docs Credentials, Stamp
@docs credentials, stamp
@docs sign, nonceGenerator

-}

import Http
import Random
import SHA256


{-| Opaque container for an Advanced API key pair. Construct via
[`credentials`](#credentials); the raw `apiKey` is kept inaccessible to
prevent accidental logging.
-}
type Credentials
    = Credentials
        { apiKeyId : String
        , apiKey : String
        }


{-| Build a `Credentials` from the raw API Key ID and API Key strings
(typically sourced from `CORTEX_API_KEY_ID` / `CORTEX_API_KEY`).
-}
credentials : { apiKeyId : String, apiKey : String } -> Credentials
credentials =
    Credentials


{-| Opaque container for the timestamp + nonce pair that signs a single
request. The timestamp is milliseconds since epoch; the nonce is a random
string of at least 32 characters per the Cortex Advanced Auth spec.
-}
type Stamp
    = Stamp
        { timestamp : Int
        , nonce : String
        }


{-| Build a `Stamp` from a millis-since-epoch timestamp and a random nonce.
-}
stamp : { timestamp : Int, nonce : String } -> Stamp
stamp =
    Stamp


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
sign (Credentials c) (Stamp s) =
    let
        hashInput =
            c.apiKey ++ s.nonce ++ String.fromInt s.timestamp

        hash =
            SHA256.fromString hashInput |> SHA256.toHex
    in
    [ Http.header "Authorization" hash
    , Http.header "x-xdr-auth-id" c.apiKeyId
    , Http.header "x-xdr-timestamp" (String.fromInt s.timestamp)
    , Http.header "x-xdr-nonce" s.nonce
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
        |> Random.map String.concat
