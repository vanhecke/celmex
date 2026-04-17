module Cortex.Api.AuditLogs exposing
    ( AuditLog, SearchResponse, AgentsReportsResponse
    , search, agentsReports
    )

{-| Cortex tenant audit-log queries (management events and agent reports).

@docs AuditLog, SearchResponse, AgentsReportsResponse
@docs search, agentsReports

-}

import Cortex.Decode exposing (reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Paginated envelope returned by [`search`](#search).
-}
type alias SearchResponse =
    { totalCount : Int
    , resultCount : Int
    , data : List AuditLog
    }


{-| A single audit-management event (user action on the tenant).
-}
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
    Request.postEmpty
        [ "public_api", "v1", "audits", "management_logs" ]
        searchResponseDecoder


searchResponseDecoder : Decoder SearchResponse
searchResponseDecoder =
    reply
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
    Request.postEmpty
        [ "public_api", "v1", "audits", "agents_reports" ]
        (reply agentsReportsResponseDecoder)


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
