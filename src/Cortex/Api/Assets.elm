module Cortex.Api.Assets exposing
    ( AssetsResponse
    , CountedResponse
    , LastAssessment
    , SchemaEntry
    , WebsitesLastAssessment
    , getExternalIpRanges
    , getExternalServices
    , getExternalWebsites
    , getInternetExposures
    , getSchema
    , getVulnerabilityTests
    , getWebsitesLastAssessment
    , list
    )

import Cortex.Decode exposing (reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


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


type alias SchemaEntry =
    { fieldName : Maybe String
    , fieldPrettyName : Maybe String
    , dataType : Maybe String
    }


type alias WebsitesLastAssessment =
    { lastExternalAssessment : LastAssessment
    }


type alias LastAssessment =
    { status : Maybe Bool
    , time : Maybe Int
    }



-- ------- POST /public_api/v1/assets -------


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


getExternalServices : Request CountedResponse
getExternalServices =
    countedRequest
        [ "public_api", "v1", "assets", "get_external_services" ]
        "external_services"



-- ------- POST /public_api/v1/assets/get_assets_internet_exposure -------


getInternetExposures : Request CountedResponse
getInternetExposures =
    countedRequest
        [ "public_api", "v1", "assets", "get_assets_internet_exposure" ]
        "assets_internet_exposure"



-- ------- POST /public_api/v1/assets/get_external_ip_address_ranges -------


getExternalIpRanges : Request CountedResponse
getExternalIpRanges =
    countedRequest
        [ "public_api", "v1", "assets", "get_external_ip_address_ranges" ]
        "external_ip_address_ranges"



-- ------- POST /public_api/v1/assets/get_vulnerability_tests -------


getVulnerabilityTests : Request CountedResponse
getVulnerabilityTests =
    countedRequest
        [ "public_api", "v1", "assets", "get_vulnerability_tests" ]
        "vulnerability_tests"



-- ------- POST /public_api/v1/assets/get_external_websites -------


getExternalWebsites : Request CountedResponse
getExternalWebsites =
    countedRequest
        [ "public_api", "v1", "assets", "get_external_websites" ]
        "websites"



-- ------- POST /public_api/v1/assets/get_external_websites/last_external_assessment -------


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


countedRequest : List String -> String -> Request CountedResponse
countedRequest path itemKey =
    Request.postEmpty path
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
