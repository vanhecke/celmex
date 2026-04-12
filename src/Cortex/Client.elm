module Cortex.Client exposing
    ( Config
    , send
    , sendWith
    , toRequestRecord
    )

import Cortex.Auth as Auth
import Cortex.Error as Error exposing (Error(..))
import Cortex.Request as Request exposing (Request)
import Http
import Json.Decode as Decode exposing (Decoder)
import Random
import Task
import Time


type alias Config =
    { tenant : String
    , credentials : Auth.Credentials
    }


{-| Send a request using Time.now for the timestamp and elm/random for the nonce.
Suitable for browser apps.
-}
send : Config -> (Result Error a -> msg) -> Request a -> Cmd msg
send config toMsg req =
    Time.now
        |> Task.map Time.posixToMillis
        |> Task.andThen
            (\ts ->
                let
                    ( nonce, _ ) =
                        Random.step Auth.nonceGenerator (Random.initialSeed ts)

                    stamp =
                        { timestamp = ts, nonce = nonce }

                    rec =
                        toRequestRecord config stamp req
                in
                Http.task
                    { method = rec.method
                    , headers = rec.headers
                    , url = rec.url
                    , body = rec.body
                    , resolver = Http.stringResolver (resolveResponse rec.decoder)
                    , timeout = Just 30000
                    }
            )
        |> Task.attempt toMsg


{-| Send a request with a caller-supplied stamp. The CLI uses this so the nonce
comes from Node's crypto.randomBytes rather than Elm's PRNG.
-}
sendWith : Auth.Stamp -> Config -> (Result Error a -> msg) -> Request a -> Cmd msg
sendWith stamp config toMsg req =
    let
        rec =
            toRequestRecord config stamp req
    in
    Http.task
        { method = rec.method
        , headers = rec.headers
        , url = rec.url
        , body = rec.body
        , resolver = Http.stringResolver (resolveResponse rec.decoder)
        , timeout = Just 30000
        }
        |> Task.attempt toMsg


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
toRequestRecord config stamp req =
    let
        internal =
            Request.toInternal req

        url =
            buildUrl config.tenant internal.path internal.query

        headers =
            Auth.sign config.credentials stamp
                ++ [ Http.header "Content-Type" "application/json" ]

        body =
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
                ++ String.join "/" path

        queryString =
            case query of
                [] ->
                    ""

                params ->
                    "?"
                        ++ String.join "&"
                            (List.map (\( k, v ) -> k ++ "=" ++ v) params)
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
