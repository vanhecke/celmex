module Cortex.Api.AuditLogs exposing
    ( AuditLog
    , SearchResponse
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
