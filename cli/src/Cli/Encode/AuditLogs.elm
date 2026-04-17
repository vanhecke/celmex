module Cli.Encode.AuditLogs exposing (encode, encodeAgentsReports)

import Cortex.Api.AuditLogs exposing (AgentsReportsResponse, AuditLog, SearchResponse)
import Json.Encode as Encode


encode : SearchResponse -> Encode.Value
encode response =
    Encode.object
        [ ( "total_count", Encode.int response.totalCount )
        , ( "result_count", Encode.int response.resultCount )
        , ( "data", Encode.list encodeAuditLog response.data )
        ]


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
