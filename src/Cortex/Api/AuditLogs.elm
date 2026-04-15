module Cortex.Api.AuditLogs exposing
    ( AgentsReportsResponse
    , AuditLog
    , SearchResponse
    , agentsReports
    , encode
    , encodeAgentsReports
    , search
    )

import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias SearchResponse =
    { totalCount : Int
    , resultCount : Int
    , data : List AuditLog
    }


type alias AuditLog =
    { auditId : Int
    , ownerName : Maybe String
    , ownerEmail : Maybe String
    , entity : Maybe String
    , result : Maybe String
    , description : Maybe String
    , insertTime : Maybe Int
    }


{-| POST /public\_api/v1/audits/management\_logs

Retrieve audit management logs. Sends an empty request\_data to get all results.
Response uses the `reply` envelope.

-}
search : Request SearchResponse
search =
    Request.post
        [ "public_api", "v1", "audits", "management_logs" ]
        (Encode.object
            [ ( "request_data", Encode.object [] ) ]
        )
        searchResponseDecoder


searchResponseDecoder : Decoder SearchResponse
searchResponseDecoder =
    Decode.field "reply"
        (Decode.map3 SearchResponse
            (Decode.field "total_count" Decode.int)
            (Decode.field "result_count" Decode.int)
            (Decode.field "data" (Decode.list auditLogDecoder))
        )


auditLogDecoder : Decoder AuditLog
auditLogDecoder =
    Decode.map7 AuditLog
        (Decode.field "AUDIT_ID" Decode.int)
        (Decode.maybe (Decode.field "AUDIT_OWNER_NAME" Decode.string))
        (Decode.maybe (Decode.field "AUDIT_OWNER_EMAIL" Decode.string))
        (Decode.maybe (Decode.field "AUDIT_ENTITY" Decode.string))
        (Decode.maybe (Decode.field "AUDIT_RESULT" Decode.string))
        (Decode.maybe (Decode.field "AUDIT_DESCRIPTION" Decode.string))
        (Decode.maybe (Decode.field "AUDIT_INSERT_TIME" Decode.int))


encode : SearchResponse -> Encode.Value
encode response =
    Encode.object
        [ ( "total_count", Encode.int response.totalCount )
        , ( "result_count", Encode.int response.resultCount )
        , ( "data", Encode.list encodeAuditLog response.data )
        ]


{-| Agent reports have uppercase field names (TIMESTAMP, ENDPOINTID, DOMAIN,
CATEGORY, SUBTYPE, …) and some floating-point timestamps, so the report rows
are preserved as raw JSON to capture every field without duplicating the agent
event schema here.
-}
type alias AgentsReportsResponse =
    { totalCount : Maybe Int
    , resultCount : Maybe Int
    , data : List Encode.Value
    }


{-| POST /public\_api/v1/audits/agents\_reports
-}
agentsReports : Request AgentsReportsResponse
agentsReports =
    Request.post
        [ "public_api", "v1", "audits", "agents_reports" ]
        (Encode.object [ ( "request_data", Encode.object [] ) ])
        (Decode.field "reply" agentsReportsResponseDecoder)


agentsReportsResponseDecoder : Decoder AgentsReportsResponse
agentsReportsResponseDecoder =
    Decode.map3 AgentsReportsResponse
        (Decode.maybe (Decode.field "total_count" Decode.int))
        (Decode.maybe (Decode.field "result_count" Decode.int))
        (Decode.oneOf
            [ Decode.field "data" (Decode.list Decode.value)
            , Decode.succeed []
            ]
        )


encodeAgentsReports : AgentsReportsResponse -> Encode.Value
encodeAgentsReports r =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "total_count", Encode.int v )) r.totalCount
            , Maybe.map (\v -> ( "result_count", Encode.int v )) r.resultCount
            , Just ( "data", Encode.list identity r.data )
            ]
        )


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
