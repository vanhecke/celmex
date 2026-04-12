module Cli.Commands exposing (Msg(..), dispatch, handleResult)

import Cli.Ports as Ports
import Cortex.Api.AuditLogs as AuditLogs exposing (AuditLog, SearchResponse)
import Cortex.Auth as Auth
import Cortex.Client as Client exposing (Config)
import Cortex.Error exposing (Error(..))
import Json.Encode as Encode


type Msg
    = GotAuditLogs (Result Error SearchResponse)


dispatch : Auth.Stamp -> Config -> List String -> Result String (Cmd Msg)
dispatch stamp config args =
    case args of
        [ "audit-logs", "search" ] ->
            Ok (Client.sendWith stamp config GotAuditLogs AuditLogs.search)

        _ ->
            Err (usage args)


handleResult : Msg -> Cmd msg
handleResult msg =
    case msg of
        GotAuditLogs (Ok response) ->
            Cmd.batch
                [ Ports.stdout (Encode.encode 2 (encodeSearchResponse response) ++ "\n")
                , Ports.exit 0
                ]

        GotAuditLogs (Err err) ->
            Cmd.batch
                [ Ports.stderr (errorToString err ++ "\n")
                , Ports.exit 1
                ]


encodeSearchResponse : SearchResponse -> Encode.Value
encodeSearchResponse response =
    Encode.object
        [ ( "total_count", Encode.int response.totalCount )
        , ( "result_count", Encode.int response.resultCount )
        , ( "data"
          , Encode.list encodeAuditLog response.data
          )
        ]


encodeAuditLog : AuditLog -> Encode.Value
encodeAuditLog log =
    Encode.object
        (List.filterMap identity
            [ Just ( "AUDIT_ID", Encode.int log.auditId )
            , Maybe.map (\v -> ( "AUDIT_OWNER_NAME", Encode.string v )) log.ownerName
            , Maybe.map (\v -> ( "AUDIT_OWNER_EMAIL", Encode.string v )) log.ownerEmail
            , Maybe.map (\v -> ( "AUDIT_ENTITY", Encode.string v )) log.entity
            , Maybe.map (\v -> ( "AUDIT_RESULT", Encode.string v )) log.result
            , Maybe.map (\v -> ( "AUDIT_DESCRIPTION", Encode.string v )) log.description
            , Maybe.map (\v -> ( "AUDIT_INSERT_TIME", Encode.int v )) log.insertTime
            ]
        )


errorToString : Error -> String
errorToString err =
    case err of
        NetworkError ->
            "Network error"

        Timeout ->
            "Request timed out"

        BadStatus code maybeApiError ->
            case maybeApiError of
                Just apiErr ->
                    "HTTP " ++ String.fromInt code ++ ": " ++ apiErr.errMsg

                Nothing ->
                    "HTTP " ++ String.fromInt code

        BadBody detail ->
            "Bad response body: " ++ detail

        BadUrl url ->
            "Bad URL: " ++ url


usage : List String -> String
usage args =
    "Unknown command: "
        ++ String.join " " args
        ++ "\n\nUsage:\n  cortex audit-logs search    Search audit management logs"
