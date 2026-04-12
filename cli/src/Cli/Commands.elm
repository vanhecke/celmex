module Cli.Commands exposing (Msg(..), dispatch, handleResult)

import Cli.Ports as Ports
import Cortex.Api.AuditLogs as AuditLogs exposing (AuditLog, SearchResponse)
import Cortex.Api.Endpoints as Endpoints
import Cortex.Api.Healthcheck as Healthcheck
import Cortex.Api.TenantInfo as TenantInfo
import Cortex.Auth as Auth
import Cortex.Client as Client exposing (Config)
import Cortex.Error exposing (Error(..))
import Json.Encode as Encode


type Msg
    = GotAuditLogs (Result Error SearchResponse)
    | GotHealthcheck (Result Error Healthcheck.HealthcheckResponse)
    | GotTenantInfo (Result Error TenantInfo.TenantInfo)
    | GotEndpoints (Result Error Endpoints.ListResponse)


dispatch : Auth.Stamp -> Config -> List String -> Result String (Cmd Msg)
dispatch stamp config args =
    case args of
        [ "healthcheck" ] ->
            Ok (Client.sendWith stamp config GotHealthcheck Healthcheck.check)

        [ "tenant-info" ] ->
            Ok (Client.sendWith stamp config GotTenantInfo TenantInfo.get)

        [ "endpoints", "list" ] ->
            Ok (Client.sendWith stamp config GotEndpoints Endpoints.list)

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

        GotHealthcheck (Ok response) ->
            Cmd.batch
                [ Ports.stdout (Encode.encode 2 (encodeHealthcheck response) ++ "\n")
                , Ports.exit 0
                ]

        GotHealthcheck (Err err) ->
            Cmd.batch
                [ Ports.stderr (errorToString err ++ "\n")
                , Ports.exit 1
                ]

        GotTenantInfo (Ok response) ->
            Cmd.batch
                [ Ports.stdout (Encode.encode 2 response.raw ++ "\n")
                , Ports.exit 0
                ]

        GotTenantInfo (Err err) ->
            Cmd.batch
                [ Ports.stderr (errorToString err ++ "\n")
                , Ports.exit 1
                ]

        GotEndpoints (Ok response) ->
            Cmd.batch
                [ Ports.stdout (Encode.encode 2 (encodeListResponse response) ++ "\n")
                , Ports.exit 0
                ]

        GotEndpoints (Err err) ->
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


encodeHealthcheck : Healthcheck.HealthcheckResponse -> Encode.Value
encodeHealthcheck response =
    Encode.object
        [ ( "status", Encode.string response.status )
        ]


encodeListResponse : Endpoints.ListResponse -> Encode.Value
encodeListResponse response =
    Encode.object
        [ ( "endpoints", Encode.list encodeEndpoint response.endpoints )
        ]


encodeEndpoint : Endpoints.Endpoint -> Encode.Value
encodeEndpoint ep =
    Encode.object
        (List.filterMap identity
            [ Just ( "agent_id", Encode.string ep.agentId )
            , Maybe.map (\v -> ( "agent_status", Encode.string v )) ep.agentStatus
            , Maybe.map (\v -> ( "operational_status", Encode.string v )) ep.operationalStatus
            , Maybe.map (\v -> ( "host_name", Encode.string v )) ep.hostName
            , Maybe.map (\v -> ( "agent_type", Encode.string v )) ep.agentType
            , Just ( "ip", Encode.list Encode.string ep.ip )
            , Maybe.map (\v -> ( "last_seen", Encode.int v )) ep.lastSeen
            , Just ( "tags", ep.tags )
            , Just ( "users", Encode.list Encode.string ep.users )
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
        ++ "\n\nUsage:\n  cortex healthcheck           System health check\n  cortex tenant-info           Get tenant license and config info\n  cortex endpoints list        List all endpoints\n  cortex audit-logs search     Search audit management logs"
