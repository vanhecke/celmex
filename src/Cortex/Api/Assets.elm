module Cortex.Api.Assets exposing
    ( SearchArgs, defaultSearchArgs
    , AssetsResponse, CountedResponse, LastAssessment, SchemaEntry, WebsitesLastAssessment
    , list, getSchema
    , getExternalIpRanges, getExternalServices, getExternalWebsites, getInternetExposures, getVulnerabilityTests, getWebsitesLastAssessment
    )

{-| Cortex asset inventory and external attack-surface views.

@docs SearchArgs, defaultSearchArgs
@docs AssetsResponse, CountedResponse, LastAssessment, SchemaEntry, WebsitesLastAssessment
@docs list, getSchema
@docs getExternalIpRanges, getExternalServices, getExternalWebsites, getInternetExposures, getVulnerabilityTests, getWebsitesLastAssessment

-}

import Cortex.Decode exposing (reply)
import Cortex.Query as Query exposing (Filter, Range, Sort, Timeframe)
import Cortex.Request as Request exposing (Request)
import Cortex.RequestData as RequestData
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Arguments to the filtered asset list endpoints
([`getExternalServices`](#getExternalServices),
[`getInternetExposures`](#getInternetExposures),
[`getExternalIpRanges`](#getExternalIpRanges),
[`getVulnerabilityTests`](#getVulnerabilityTests),
[`getExternalWebsites`](#getExternalWebsites)). All fields are optional;
pass [`defaultSearchArgs`](#defaultSearchArgs) for an unfiltered request.
`extra` is merged last into `request_data` and overrides any SDK-generated
key on collision.

[`list`](#list) (the asset inventory itself) does not yet take this
argument because the underlying endpoint uses a different
`request_data` shape; it remains an unfiltered call until the SDK gains an
asset-inventory dialect mapping.

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


{-| Generic paginated response shape shared by several asset endpoints. The
inner items vary so widely (external services, internet exposures, IP ranges,
vulnerability tests, websites) that each item is decoded as raw JSON to
preserve every field.
-}
type alias CountedResponse =
    { totalCount : Maybe Int
    , resultCount : Maybe Int
    , items : List Encode.Value
    }


{-| Response shape for POST /public\_api/v1/assets — the asset inventory list.
The top-level envelope contains metadata; each asset's xdm.asset.\* fields are
preserved as raw JSON.
-}
type alias AssetsResponse =
    { data : List Encode.Value
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| One row of the asset inventory schema returned by [`getSchema`](#getSchema).
-}
type alias SchemaEntry =
    { fieldName : Maybe String
    , fieldPrettyName : Maybe String
    , dataType : Maybe String
    }


{-| Wrapper for [`getWebsitesLastAssessment`](#getWebsitesLastAssessment)'s
single `last_external_assessment` field.
-}
type alias WebsitesLastAssessment =
    { lastExternalAssessment : LastAssessment
    }


{-| Status + timestamp pair used inside [`WebsitesLastAssessment`](#WebsitesLastAssessment).
-}
type alias LastAssessment =
    { status : Maybe Bool
    , time : Maybe Int
    }



-- ------- POST /public_api/v1/assets -------


{-| POST /public\_api/v1/assets — the asset inventory list.
-}
list : Request AssetsResponse
list =
    Request.postEmpty
        [ "public_api", "v1", "assets" ]
        (reply assetsResponseDecoder)


assetsResponseDecoder : Decoder AssetsResponse
assetsResponseDecoder =
    Decode.map3 AssetsResponse
        (Decode.oneOf
            [ Decode.field "data" (Decode.list Decode.value)
            , Decode.succeed []
            ]
        )
        (Decode.maybe (Decode.at [ "metadata", "filter_count" ] Decode.int))
        (Decode.maybe (Decode.at [ "metadata", "total_count" ] Decode.int))



-- ------- GET /public_api/v1/assets/schema -------


{-| GET /public\_api/v1/assets/schema — list the tenant's asset schema.
-}
getSchema : Request (List SchemaEntry)
getSchema =
    Request.get
        [ "public_api", "v1", "assets", "schema" ]
        (Decode.at [ "reply", "data" ] (Decode.list schemaEntryDecoder))


schemaEntryDecoder : Decoder SchemaEntry
schemaEntryDecoder =
    Decode.map3 SchemaEntry
        (Decode.maybe (Decode.field "field_name" Decode.string))
        (Decode.maybe (Decode.field "field_pretty_name" Decode.string))
        (Decode.maybe (Decode.field "data_type" Decode.string))



-- ------- POST /public_api/v1/assets/get_external_services -------


{-| POST /public\_api/v1/assets/get\_external\_services — externally reachable services.
-}
getExternalServices : SearchArgs -> Request CountedResponse
getExternalServices args =
    countedRequest
        [ "public_api", "v1", "assets", "get_external_services" ]
        "external_services"
        args



-- ------- POST /public_api/v1/assets/get_assets_internet_exposure -------


{-| POST /public\_api/v1/assets/get\_assets\_internet\_exposure — assets exposed to the public internet.
-}
getInternetExposures : SearchArgs -> Request CountedResponse
getInternetExposures args =
    countedRequest
        [ "public_api", "v1", "assets", "get_assets_internet_exposure" ]
        "assets_internet_exposure"
        args



-- ------- POST /public_api/v1/assets/get_external_ip_address_ranges -------


{-| POST /public\_api/v1/assets/get\_external\_ip\_address\_ranges — discovered external IP ranges.
-}
getExternalIpRanges : SearchArgs -> Request CountedResponse
getExternalIpRanges args =
    countedRequest
        [ "public_api", "v1", "assets", "get_external_ip_address_ranges" ]
        "external_ip_address_ranges"
        args



-- ------- POST /public_api/v1/assets/get_vulnerability_tests -------


{-| POST /public\_api/v1/assets/get\_vulnerability\_tests — vulnerability scanner results.
-}
getVulnerabilityTests : SearchArgs -> Request CountedResponse
getVulnerabilityTests args =
    countedRequest
        [ "public_api", "v1", "assets", "get_vulnerability_tests" ]
        "vulnerability_tests"
        args



-- ------- POST /public_api/v1/assets/get_external_websites -------


{-| POST /public\_api/v1/assets/get\_external\_websites — externally reachable websites.
-}
getExternalWebsites : SearchArgs -> Request CountedResponse
getExternalWebsites args =
    countedRequest
        [ "public_api", "v1", "assets", "get_external_websites" ]
        "websites"
        args



-- ------- POST /public_api/v1/assets/get_external_websites/last_external_assessment -------


{-| POST /public\_api/v1/assets/get\_external\_websites/last\_external\_assessment —
status + timestamp of the most recent websites scan.
-}
getWebsitesLastAssessment : Request WebsitesLastAssessment
getWebsitesLastAssessment =
    Request.postEmpty
        [ "public_api", "v1", "assets", "get_external_websites", "last_external_assessment" ]
        websitesLastAssessmentDecoder


websitesLastAssessmentDecoder : Decoder WebsitesLastAssessment
websitesLastAssessmentDecoder =
    Decode.map WebsitesLastAssessment
        (Decode.field "last_external_assessment" lastAssessmentDecoder)


lastAssessmentDecoder : Decoder LastAssessment
lastAssessmentDecoder =
    Decode.map2 LastAssessment
        (Decode.maybe (Decode.field "status" Decode.bool))
        (Decode.maybe (Decode.field "time" Decode.int))



-- ------- shared helpers for the "counted list" response shape -------


countedRequest : List String -> String -> SearchArgs -> Request CountedResponse
countedRequest path itemKey args =
    Request.post path
        (RequestData.encode Query.standard
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        (reply (countedResponseDecoder itemKey))


countedResponseDecoder : String -> Decoder CountedResponse
countedResponseDecoder itemKey =
    Decode.map3 CountedResponse
        (Decode.maybe (Decode.field "total_count" Decode.int))
        (Decode.maybe (Decode.field "result_count" Decode.int))
        (Decode.oneOf
            [ Decode.field itemKey (Decode.list Decode.value)
            , Decode.succeed []
            ]
        )
