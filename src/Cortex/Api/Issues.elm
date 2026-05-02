module Cortex.Api.Issues exposing
    ( SearchArgs, defaultSearchArgs
    , Issue, SearchResponse, IssueSchemaField
    , search, schema
    )

{-| Cortex issue records (alerts/incidents) and their tenant-defined schema.

The `/public_api/v1/issue/search` endpoint returns a paginated list of
[`Issue`](#Issue) records — each with ~50 normalized fields covering issue
identity, detection metadata, asset references, MITRE ATT&CK mapping,
status/resolution lifecycle, and assignment. The `/public_api/v1/issue/schema`
endpoint returns the field schema (`field_name`, `field_pretty_name`,
`data_type`) for every issue field — including custom fields the tenant has
defined.

@docs SearchArgs, defaultSearchArgs
@docs Issue, SearchResponse, IssueSchemaField
@docs search, schema

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
collision — use it for request fields the SDK has not modeled yet.
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


{-| Paginated response from [`search`](#search). The live API returns
`DATA`/`TOTAL_COUNT`/`FILTER_COUNT` (uppercase); the spec documents
`issues`/`total_count`/`result_count` (lowercase). Both are accepted.
-}
type alias SearchResponse =
    { data : List Issue
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| A single issue record. All fields are `Maybe` because population varies
by detection method, tenant, and feature flags. Field names use the live
wire format (dotted namespacing for `detection.*` / `status.*`), with
`oneOf` fallback to spec-form underscore names for forward compat.

`normalizedFields` (~70 XDM-prefixed forensic fields) and `customFields`
(tenant-defined arbitrary keys) are preserved verbatim — the former is
fully populated only for advanced detection methods and is best surfaced
as raw JSON until typed sub-records are added; the latter is unconstrained
per tenant configuration and cannot be typed at the SDK layer.

-}
type alias Issue =
    { id : Maybe Int
    , externalId : Maybe String
    , name : Maybe String
    , description : Maybe String
    , extendedDescription : Maybe String
    , initialEvidence : Maybe String
    , owner : Maybe String
    , domain : Maybe String
    , category : Maybe String
    , type_ : Maybe String
    , severity : Maybe String
    , detectionMethod : Maybe String
    , detectionRuleId : Maybe String
    , insertTime : Maybe Int
    , observationTime : Maybe Int
    , lastModified : Maybe Int
    , resolutionTime : Maybe Int
    , resolutionStatusModifiedTs : Maybe Int
    , statusProgress : Maybe String
    , statusResolutionReason : Maybe String
    , statusResolutionComment : Maybe String
    , assignedTo : Maybe String
    , assignedToPretty : Maybe String
    , isStarred : Maybe Bool
    , isExcluded : Maybe Bool
    , isExcepted : Maybe Bool
    , exceptionIds : List String
    , exceptionExpiration : Maybe Int
    , tags : List String
    , findings : List String
    , assetIds : List String
    , assetNames : List String
    , assetGroupIds : List Int
    , assetClasses : List String
    , assetCategories : List String
    , assetRegions : List String
    , assetProviders : List String
    , assetAccounts : List String
    , assetTypes : List String
    , assetExternalProviderIds : List String
    , assetCloudAccountNames : List String
    , mitreTactics : List String
    , mitreTechniques : List String
    , caseIds : List Int
    , remediation : Maybe String
    , impact : Maybe String
    , agenticResponseStatus : Maybe String
    , agenticAssistantId : Maybe String
    , agenticResponseConversationId : Maybe String
    , actionStatus : Maybe String

    {- normalizedFields holds ~70 documented `xdm.*`-prefixed forensic
       fields whose population depends on the detection method. Surfaced
       as raw JSON because typing all 70 fields explicitly would more
       than double this module's size; downstream consumers can drill
       into the JSON for the subset they need. Future work: split into
       a typed NormalizedFields sub-record once stable.
    -}
    , normalizedFields : Maybe Encode.Value

    {- customFields is a tenant-defined free-form object. Keys are not
       constrained by the API — each tenant configures its own custom
       fields. Cannot be typed at the SDK layer; preserved verbatim.
    -}
    , customFields : Maybe Encode.Value
    }


{-| One row of the issue field-schema response from [`schema`](#schema).
-}
type alias IssueSchemaField =
    { fieldName : Maybe String
    , fieldPrettyName : Maybe String
    , dataType : Maybe String
    }


{-| POST /public\_api/v1/issue/search

Retrieve issues matching the given filters, sort, pagination, and
timeframe. Returns a [`SearchResponse`](#SearchResponse) with the typed
[`Issue`](#Issue) records and pagination counts.

-}
search : SearchArgs -> Request SearchResponse
search args =
    Request.post
        [ "public_api", "v1", "issue", "search" ]
        (RequestData.encode Query.standard
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        (reply searchResponseDecoder)


{-| POST /public\_api/v1/issue/schema

Retrieve the issue field schema — every documented field, plus the
tenant's custom fields. Some tenants surface this as HTTP 500 when not
licensed.

-}
schema : Request (List IssueSchemaField)
schema =
    Request.postEmpty
        [ "public_api", "v1", "issue", "schema" ]
        (reply
            (Decode.oneOf
                [ Decode.field "data" (Decode.list issueSchemaFieldDecoder)
                , Decode.succeed []
                ]
            )
        )



-- DECODERS


searchResponseDecoder : Decoder SearchResponse
searchResponseDecoder =
    Decode.map3 SearchResponse
        (Decode.oneOf
            [ Decode.field "DATA" (Decode.list issueDecoder)
            , Decode.field "data" (Decode.list issueDecoder)
            , Decode.field "issues" (Decode.list issueDecoder)
            , Decode.succeed []
            ]
        )
        (Decode.maybe
            (Decode.oneOf
                [ Decode.field "FILTER_COUNT" Decode.int
                , Decode.field "filter_count" Decode.int
                , Decode.field "result_count" Decode.int
                ]
            )
        )
        (Decode.maybe
            (Decode.oneOf
                [ Decode.field "TOTAL_COUNT" Decode.int
                , Decode.field "total_count" Decode.int
                ]
            )
        )


issueDecoder : Decoder Issue
issueDecoder =
    Decode.succeed Issue
        |> andMap (optionalIntField "id")
        |> andMap (optionalStringField "external_id")
        |> andMap (optionalStringField "name")
        |> andMap (optionalStringField "description")
        |> andMap (optionalStringField "extended_description")
        |> andMap (optionalStringField "initial_evidence")
        |> andMap (optionalStringField "owner")
        |> andMap (optionalStringField "domain")
        |> andMap (optionalStringField "category")
        |> andMap (optionalStringField "type")
        |> andMap (optionalStringField "severity")
        |> andMap (optionalStringEither "detection.method" "detection_method")
        |> andMap (optionalStringEither "detection.rule_id" "detection_rule_id")
        |> andMap (optionalIntField "_insert_time")
        |> andMap (optionalIntField "observation_time")
        |> andMap (optionalIntEither "last_update_timestamp" "last_modified")
        |> andMap (optionalIntField "resolution_time")
        |> andMap (optionalIntField "resolution_status_modified_ts")
        |> andMap (optionalStringEither "status.progress" "status")
        |> andMap (optionalStringEither "status.resolution_reason" "status_resolution_reason")
        |> andMap (optionalStringEither "status.resolution_comment" "status_resolution_comment")
        |> andMap (optionalStringField "assigned_to")
        |> andMap (optionalStringField "assigned_to_pretty")
        |> andMap (optionalBoolField "is_starred")
        |> andMap (optionalBoolField "is_excluded")
        |> andMap (optionalBoolField "is_excepted")
        |> andMap (optionalList "exception_ids" Decode.string)
        |> andMap (optionalIntField "exception_expiration")
        |> andMap (optionalList "tags" Decode.string)
        |> andMap (optionalListEither "findings" "finding_ids" Decode.string)
        |> andMap (optionalList "asset_ids" Decode.string)
        |> andMap (optionalList "asset_names" Decode.string)
        |> andMap (optionalList "asset_group_ids" Decode.int)
        |> andMap (optionalList "asset_classes" Decode.string)
        |> andMap (optionalList "asset_categories" Decode.string)
        |> andMap (optionalList "asset_regions" Decode.string)
        |> andMap (optionalList "asset_providers" Decode.string)
        |> andMap (optionalList "asset_accounts" Decode.string)
        |> andMap (optionalList "asset_types" Decode.string)
        |> andMap (optionalList "asset_external_provider_ids" Decode.string)
        |> andMap (optionalList "asset_cloud_account_names" Decode.string)
        |> andMap (optionalList "mitre_tactics" Decode.string)
        |> andMap (optionalList "mitre_techniques" Decode.string)
        |> andMap (optionalList "case_ids" Decode.int)
        |> andMap (optionalStringField "remediation")
        |> andMap (optionalStringField "impact")
        |> andMap (optionalStringField "agentic_response_status")
        |> andMap (optionalStringField "agentic_assistant_id")
        |> andMap (optionalStringField "agentic_response_conversation_id")
        |> andMap (optionalStringField "action_status")
        |> andMap
            {- Decoder escape: tenant-defined `normalized_fields` map; shape varies
               per tenant configuration and is opaque to the SDK.
            -}
            (optionalField "normalized_fields" Decode.value)
        |> andMap
            {- Decoder escape: tenant-defined `custom_fields` map; shape varies
               per tenant and is opaque to the SDK.
            -}
            (optionalField "custom_fields" Decode.value)


issueSchemaFieldDecoder : Decoder IssueSchemaField
issueSchemaFieldDecoder =
    Decode.map3 IssueSchemaField
        (optionalStringField "field_name")
        (optionalStringField "field_pretty_name")
        (optionalStringField "data_type")



-- decode helpers


optionalStringField : String -> Decoder (Maybe String)
optionalStringField name =
    optionalField name Decode.string


optionalIntField : String -> Decoder (Maybe Int)
optionalIntField name =
    optionalField name Decode.int


optionalBoolField : String -> Decoder (Maybe Bool)
optionalBoolField name =
    optionalField name Decode.bool


optionalStringEither : String -> String -> Decoder (Maybe String)
optionalStringEither preferredName fallbackName =
    Decode.oneOf
        [ optionalField preferredName Decode.string
            |> Decode.andThen
                (\m ->
                    case m of
                        Just _ ->
                            Decode.succeed m

                        Nothing ->
                            optionalField fallbackName Decode.string
                )
        , optionalField fallbackName Decode.string
        ]


optionalIntEither : String -> String -> Decoder (Maybe Int)
optionalIntEither preferredName fallbackName =
    Decode.oneOf
        [ optionalField preferredName Decode.int
            |> Decode.andThen
                (\m ->
                    case m of
                        Just _ ->
                            Decode.succeed m

                        Nothing ->
                            optionalField fallbackName Decode.int
                )
        , optionalField fallbackName Decode.int
        ]


optionalListEither : String -> String -> Decoder a -> Decoder (List a)
optionalListEither preferredName fallbackName itemDecoder =
    Decode.oneOf
        [ Decode.field preferredName (Decode.list itemDecoder)
        , Decode.field fallbackName (Decode.list itemDecoder)
        , Decode.succeed []
        ]
