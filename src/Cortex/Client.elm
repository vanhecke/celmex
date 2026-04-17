module Cortex.Client exposing
    ( Config, config, withTimeout
    , send, sendWith
    , toRequestRecord
    )

{-| Drives HTTP for the SDK. This is the only module with effects — every
`Cortex.Api.*` module produces a pure [`Request`](Cortex-Request#Request) that
is dispatched through `send` / `sendWith`.

@docs Config, config, withTimeout
@docs send, sendWith
@docs toRequestRecord

-}

import Cortex.Auth as Auth
import Cortex.Error as Error exposing (Error(..))
import Cortex.Request as Request exposing (Request)
import Http
import Json.Decode as Decode exposing (Decoder)
import Random
import Task exposing (Task)
import Time
import Url


{-| Opaque HTTP client configuration. Holds the tenant base URL, the API
credentials, and the per-request timeout. Construct via [`config`](#config)
and tweak with [`withTimeout`](#withTimeout).
-}
type Config
    = Config
        { tenant : String
        , credentials : Auth.Credentials
        , timeout : Float
        }


{-| Build a `Config` from the tenant base URL and credentials. The timeout
defaults to 30 seconds; change it with [`withTimeout`](#withTimeout).
-}
config : { tenant : String, credentials : Auth.Credentials } -> Config
config c =
    Config
        { tenant = c.tenant
        , credentials = c.credentials
        , timeout = 30000
        }


{-| Set a new per-request timeout, in milliseconds.
-}
withTimeout : Float -> Config -> Config
withTimeout ms (Config c) =
    Config { c | timeout = ms }


{-| Send a request using Time.now for the timestamp and elm/random for the nonce.
Suitable for browser apps.
-}
send : Config -> (Result Error a -> msg) -> Request a -> Cmd msg
send cfg toMsg req =
    Time.now
        |> Task.map Time.posixToMillis
        |> Task.andThen
            (\ts ->
                let
                    ( nonce, _ ) =
                        Random.step Auth.nonceGenerator (Random.initialSeed ts)

                    s =
                        Auth.stamp { timestamp = ts, nonce = nonce }
                in
                httpTask cfg s req
            )
        |> Task.attempt toMsg


{-| Send a request with a caller-supplied stamp. The CLI uses this so the nonce
comes from Node's crypto.randomBytes rather than Elm's PRNG.
-}
sendWith : Auth.Stamp -> Config -> (Result Error a -> msg) -> Request a -> Cmd msg
sendWith s cfg toMsg req =
    httpTask cfg s req
        |> Task.attempt toMsg


httpTask : Config -> Auth.Stamp -> Request a -> Task Error a
httpTask ((Config inner) as cfg) s req =
    let
        rec =
            toRequestRecord cfg s req
    in
    Http.task
        { method = rec.method
        , headers = rec.headers
        , url = rec.url
        , body = rec.body
        , resolver = Http.stringResolver (resolveResponse rec.decoder)
        , timeout = Just inner.timeout
        }


{-| Build a pure record from a Config, Stamp, and Request.
Useful for consumers who want to drive Http themselves.
-}
toRequestRecord :
    Config
    -> Auth.Stamp
    -> Request a
    ->
        { method : String
        , headers : List Http.Header
        , url : String
        , body : Http.Body
        , decoder : Decoder a
        }
toRequestRecord (Config cfg) s req =
    let
        internal =
            Request.toInternal req

        url =
            buildUrl cfg.tenant internal.path internal.query

        headers =
            Auth.sign cfg.credentials s
                ++ [ Http.header "Content-Type" "application/json" ]

        body =
            if internal.method == "GET" then
                Http.emptyBody

            else
                Http.jsonBody internal.body
    in
    { method = internal.method
    , headers = headers
    , url = url
    , body = body
    , decoder = internal.decoder
    }


buildUrl : String -> List String -> List ( String, String ) -> String
buildUrl tenant path query =
    let
        base =
            stripTrailingSlash tenant
                ++ "/"
                ++ String.join "/" (List.map Url.percentEncode path)

        queryString =
            case query of
                [] ->
                    ""

                params ->
                    "?"
                        ++ String.join "&"
                            (List.map
                                (\( k, v ) -> Url.percentEncode k ++ "=" ++ Url.percentEncode v)
                                params
                            )
    in
    base ++ queryString


stripTrailingSlash : String -> String
stripTrailingSlash s =
    if String.endsWith "/" s then
        String.dropRight 1 s

    else
        s


resolveResponse : Decoder a -> Http.Response String -> Result Error a
resolveResponse decoder response =
    case response of
        Http.BadUrl_ url ->
            Err (BadUrl url)

        Http.Timeout_ ->
            Err Timeout

        Http.NetworkError_ ->
            Err NetworkError

        Http.BadStatus_ metadata body ->
            Err (BadStatus metadata.statusCode (Error.decodeApiError body))

        Http.GoodStatus_ _ body ->
            case Decode.decodeString decoder body of
                Ok value ->
                    Ok value

                Err err ->
                    Err (BadBody (Decode.errorToString err))
