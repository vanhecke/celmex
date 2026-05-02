module Cortex.Api.AuditLogs exposing
    ( SearchArgs, defaultSearchArgs
    , AuditLog, SearchResponse
    , AgentReport, AgentsReportsResponse
    , search, agentsReports
    )

{-| Cortex tenant audit-log queries — both human-driven management events
and agent-emitted reports.

Two endpoints, two record shapes:

  - [`search`](#search) — management actions (an admin changed a setting,
    an API key was created, etc.). Records have UPPERCASE-prefixed
    `AUDIT_*` fields.

  - [`agentsReports`](#agentsReports) — agent-side events (policy updates,
    scan completions, errors). Records have UPPERCASE field names with
    floating-point millisecond timestamps.

@docs SearchArgs, defaultSearchArgs
@docs AuditLog, SearchResponse
@docs AgentReport, AgentsReportsResponse
@docs search, agentsReports

-}

import Cortex.Decode exposing (andMap, optionalField, optionalList, reply)
import Cortex.Query as Query exposing (Filter, Range, Sort, Timeframe)
import Cortex.Request as Request exposing (Request)
import Cortex.RequestData as RequestData
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Arguments to [`search`](#search). All fields are optional; pass
[`defaultSearchArgs`](#defaultSearchArgs) for an unfiltered request. `extra`
is merged last into `request_data` and overrides any SDK-generated key on
collision.
-}
type alias SearchArgs =
    { filters : List Filter
    , sort : Maybe Sort
    , range : Maybe Range
    , timeframe : Maybe Timeframe
    , extra : List ( String, Encode.Value )
    }


{-| A [`SearchArgs`](#SearchArgs) with no filters, sort, pagination, or
timeframe.
-}
defaultSearchArgs : SearchArgs
defaultSearchArgs =
    { filters = []
    , sort = Nothing
    , range = Nothing
    , timeframe = Nothing
    , extra = []
    }


{-| Paginated envelope returned by [`search`](#search).
-}
type alias SearchResponse =
    { totalCount : Int
    , resultCount : Int
    , data : List AuditLog
    }


{-| A single audit-management event (a user/system action against the
tenant). Field names mirror the wire format's `AUDIT_*` UPPERCASE shape.
-}
type alias AuditLog =
    { auditId : Int
    , ownerName : Maybe String
    , ownerEmail : Maybe String
    , entity : Maybe String
    , entitySubtype : Maybe String
    , severity : Maybe String
    , result : Maybe String
    , reason : Maybe String
    , description : Maybe String
    , insertTime : Maybe Int
    , hostname : Maybe String
    , assetNames : Maybe String

    {- AUDIT_ASSET_JSON varies per audit type — sometimes null, sometimes
       a structured object describing the asset acted on. Preserved
       verbatim because the populated shape depends on the entity type.
    -}
    , assetJson : Maybe Encode.Value
    , sessionId : Maybe String
    , caseId : Maybe Int
    , link : Maybe String
    , sourceIp : Maybe String
    , userAgent : Maybe String
    , userRoles : List String
    , objectId : Maybe String
    }


{-| Paginated envelope returned by [`agentsReports`](#agentsReports).
-}
type alias AgentsReportsResponse =
    { totalCount : Maybe Int
    , resultCount : Maybe Int
    , data : List AgentReport
    }


{-| A single agent report (an event emitted by an installed XDR agent).
Field names mirror the wire format's UPPERCASE shape. Timestamps are
emitted as floating-point milliseconds (not integers).
-}
type alias AgentReport =
    { timestamp : Maybe Float
    , receivedTime : Maybe Float
    , endpointId : Maybe String
    , endpointName : Maybe String
    , domain : Maybe String
    , category : Maybe String
    , type_ : Maybe String
    , subType : Maybe String
    , severity : Maybe String
    , result : Maybe String
    , reason : Maybe String
    , description : Maybe String
    , xdrVersion : Maybe String
    }


{-| POST /public\_api/v1/audits/management\_logs

Retrieve audit management logs. Filters, pagination and timeframe are
carried in [`SearchArgs`](#SearchArgs); pass
[`defaultSearchArgs`](#defaultSearchArgs) to get all results.

-}
search : SearchArgs -> Request SearchResponse
search args =
    Request.post
        [ "public_api", "v1", "audits", "management_logs" ]
        (RequestData.encode Query.standard
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        searchResponseDecoder


{-| POST /public\_api/v1/audits/agents\_reports

Retrieve agent-emitted reports — policy updates, scan completions, error
notifications, etc. Each row carries timestamps as floating-point
milliseconds.

-}
agentsReports : Request AgentsReportsResponse
agentsReports =
    Request.postEmpty
        [ "public_api", "v1", "audits", "agents_reports" ]
        (reply agentsReportsResponseDecoder)



-- DECODERS


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
    Decode.succeed AuditLog
        |> andMap (Decode.field "AUDIT_ID" Decode.int)
        |> andMap (optionalField "AUDIT_OWNER_NAME" Decode.string)
        |> andMap (optionalField "AUDIT_OWNER_EMAIL" Decode.string)
        |> andMap (optionalField "AUDIT_ENTITY" Decode.string)
        |> andMap (optionalField "AUDIT_ENTITY_SUBTYPE" Decode.string)
        |> andMap (optionalField "AUDIT_SEVERITY" Decode.string)
        |> andMap (optionalField "AUDIT_RESULT" Decode.string)
        |> andMap (optionalField "AUDIT_REASON" Decode.string)
        |> andMap (optionalField "AUDIT_DESCRIPTION" Decode.string)
        |> andMap (optionalField "AUDIT_INSERT_TIME" Decode.int)
        |> andMap (optionalField "AUDIT_HOSTNAME" Decode.string)
        |> andMap (optionalField "AUDIT_ASSET_NAMES" Decode.string)
        |> andMap (optionalField "AUDIT_ASSET_JSON" Decode.value)
        |> andMap (optionalField "AUDIT_SESSION_ID" Decode.string)
        |> andMap (optionalField "AUDIT_CASE_ID" Decode.int)
        |> andMap (optionalField "AUDIT_LINK" Decode.string)
        |> andMap (optionalField "AUDIT_SOURCE_IP" Decode.string)
        |> andMap (optionalField "AUDIT_USER_AGENT" Decode.string)
        |> andMap (optionalList "AUDIT_USER_ROLES" Decode.string)
        |> andMap (optionalField "AUDIT_OBJECT_ID" Decode.string)


agentsReportsResponseDecoder : Decoder AgentsReportsResponse
agentsReportsResponseDecoder =
    Decode.map3 AgentsReportsResponse
        (Decode.maybe (Decode.field "total_count" Decode.int))
        (Decode.maybe (Decode.field "result_count" Decode.int))
        (Decode.oneOf
            [ Decode.field "data" (Decode.list agentReportDecoder)
            , Decode.succeed []
            ]
        )


agentReportDecoder : Decoder AgentReport
agentReportDecoder =
    Decode.succeed AgentReport
        |> andMap (optionalField "TIMESTAMP" Decode.float)
        |> andMap (optionalField "RECEIVEDTIME" Decode.float)
        |> andMap (optionalField "ENDPOINTID" Decode.string)
        |> andMap (optionalField "ENDPOINTNAME" Decode.string)
        |> andMap (optionalField "DOMAIN" Decode.string)
        |> andMap (optionalField "CATEGORY" Decode.string)
        |> andMap (optionalField "TYPE" Decode.string)
        |> andMap (optionalField "SUBTYPE" Decode.string)
        |> andMap (optionalField "SEVERITY" Decode.string)
        |> andMap (optionalField "RESULT" Decode.string)
        |> andMap (optionalField "REASON" Decode.string)
        |> andMap (optionalField "DESCRIPTION" Decode.string)
        |> andMap (optionalField "XDRVERSION" Decode.string)
