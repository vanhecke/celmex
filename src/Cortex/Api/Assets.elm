module Cortex.Api.Assets exposing
    ( SearchArgs, defaultSearchArgs
    , AssetsResponse, Asset, AssetCounts
    , SchemaEntry, EnumValue
    , ExternalService, ExternalServicesResponse
    , InternetExposure, InternetExposuresResponse
    , ExternalIpRange, ExternalIpRangesResponse
    , VulnerabilityTest, AffectedSoftware, VulnerabilityTestsResponse
    , ExternalWebsite, ExternalWebsitesResponse
    , LastAssessment, WebsitesLastAssessment
    , RawFieldsResponse, RawFieldsEntry
    , list, getAsset, getSchema, getRawFields, getEnum
    , getExternalServices, getExternalService
    , getInternetExposures, getInternetExposure
    , getExternalIpRanges, getExternalIpRange
    , getVulnerabilityTests
    , getExternalWebsites, getExternalWebsite, getWebsitesLastAssessment
    )

{-| Cortex asset inventory and external attack-surface views.

@docs SearchArgs, defaultSearchArgs
@docs AssetsResponse, Asset, AssetCounts
@docs SchemaEntry, EnumValue
@docs ExternalService, ExternalServicesResponse
@docs InternetExposure, InternetExposuresResponse
@docs ExternalIpRange, ExternalIpRangesResponse
@docs VulnerabilityTest, AffectedSoftware, VulnerabilityTestsResponse
@docs ExternalWebsite, ExternalWebsitesResponse
@docs LastAssessment, WebsitesLastAssessment
@docs RawFieldsResponse, RawFieldsEntry
@docs list, getAsset, getSchema, getRawFields, getEnum
@docs getExternalServices, getExternalService
@docs getInternetExposures, getInternetExposure
@docs getExternalIpRanges, getExternalIpRange
@docs getVulnerabilityTests
@docs getExternalWebsites, getExternalWebsite, getWebsitesLastAssessment

-}

import Cortex.Decode exposing (andMap, optionalField, optionalList, reply)
import Cortex.Query as Query exposing (Filter, Range, Sort, Timeframe)
import Cortex.Request as Request exposing (Request)
import Cortex.RequestData as RequestData
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Arguments to the filtered asset list endpoints. All fields are
optional; pass [`defaultSearchArgs`](#defaultSearchArgs) for an unfiltered
request. `extra` is merged last into `request_data` and overrides any
SDK-generated key on collision.
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



-- ASSETS LIST


{-| Top-level envelope for the asset inventory list.
-}
type alias AssetsResponse =
    { data : List Asset
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| A single asset from the inventory. Field names mirror the wire
format's `xdm.asset.*` dotted-lowercase shape.
-}
type alias Asset =
    { id : Maybe String
    , strongId : Maybe String
    , name : Maybe String
    , externalProviderId : Maybe String
    , provider : Maybe String
    , realm : Maybe String
    , typeId : Maybe String
    , typeName : Maybe String
    , typeCategory : Maybe String
    , typeClass : Maybe String
    , cloudRegion : Maybe String
    , firstObserved : Maybe Int
    , lastObserved : Maybe Int
    , groupIds : List Int
    , hostIpv4Addresses : List String
    , relatedIssuesCritical : Maybe Int
    , relatedIssuesBreakdown : Maybe AssetCounts
    , relatedCasesCritical : Maybe Int
    , relatedCasesBreakdown : Maybe AssetCounts
    }


{-| Severity breakdown for an asset's related issues or cases.
-}
type alias AssetCounts =
    { critical : Maybe Int
    , high : Maybe Int
    , medium : Maybe Int
    , low : Maybe Int
    }



-- ASSETS SCHEMA


{-| One row of the asset inventory schema returned by [`getSchema`](#getSchema).
-}
type alias SchemaEntry =
    { fieldName : Maybe String
    , fieldPrettyName : Maybe String
    , dataType : Maybe String
    }


{-| One enum value returned by [`getEnum`](#getEnum) — a wire identifier
plus its human-friendly display label (e.g. `{name = Just "AWS",
prettyName = Just "AWS"}`).
-}
type alias EnumValue =
    { name : Maybe String
    , prettyName : Maybe String
    }



-- EXTERNAL SERVICES


{-| Paginated envelope returned by [`getExternalServices`](#getExternalServices).
-}
type alias ExternalServicesResponse =
    { totalCount : Maybe Int
    , resultCount : Maybe Int
    , externalServices : List ExternalService
    }


{-| A single externally-reachable service (open port + protocol on a
discovered IP). Tenant returned no services on this fixture; full field
list is the spec's `external_services` item shape (~20 fields, mostly
optional). Sub-objects like `details` and `service_classifications` are
preserved as Encode.Value with inline justification.
-}
type alias ExternalService =
    { serviceId : Maybe String
    , serviceName : Maybe String
    , serviceType : Maybe String
    , ipAddress : List String
    , externallyDetectedProviders : List String
    , externallyInferredCves : List String
    , isActive : Maybe String
    , firstObserved : Maybe Int
    , lastObserved : Maybe Int
    , protocol : Maybe String
    , port_ : Maybe Int
    , domain : List String
    , activeClassifications : List String
    , inactiveClassifications : List String
    , discoveryType : Maybe String
    , businessUnits : List String
    , tags : List String

    {- details is a service-type-specific blob (TLS handshake info, HTTP
       headers, banner bytes, etc.). Genuinely free-form per service
       type; preserved verbatim.
    -}
    , details : Maybe Encode.Value
    }



-- INTERNET EXPOSURES


{-| Paginated envelope returned by [`getInternetExposures`](#getInternetExposures).
-}
type alias InternetExposuresResponse =
    { totalCount : Maybe Int
    , resultCount : Maybe Int
    , assetsInternetExposure : List InternetExposure
    }


{-| One internet-exposure record (an asset reachable from the public
internet).
-}
type alias InternetExposure =
    { assetId : Maybe String
    , name : Maybe String
    , type_ : Maybe String
    , ipAddress : Maybe String
    , ipv6Address : Maybe String
    , domain : Maybe String
    , externallyDetectedProviders : List String
    , externallyInferredCves : List String
    , externallyInferredVulnerabilityScore : Maybe Float
    , businessUnits : List String
    , firstObserved : Maybe Int
    , lastObserved : Maybe Int
    , activeServices : Maybe Int
    , activeExternalServices : List String
    , tags : List String
    }



-- EXTERNAL IP RANGES


{-| Paginated envelope returned by [`getExternalIpRanges`](#getExternalIpRanges).
-}
type alias ExternalIpRangesResponse =
    { totalCount : Maybe Int
    , resultCount : Maybe Int
    , externalIpAddressRanges : List ExternalIpRange
    }


{-| One external IP-address range registered to or attributed to the
organization.
-}
type alias ExternalIpRange =
    { rangeId : Maybe String
    , firstIp : Maybe String
    , lastIp : Maybe String
    , ipsCount : Maybe Int
    , activeResponsiveIpsCount : Maybe Int
    , dateAdded : Maybe Int
    , annotations : List String
    , organizationHandles : List String
    , businessUnits : List String
    , tags : List String
    }



-- VULNERABILITY TESTS


{-| Paginated envelope returned by [`getVulnerabilityTests`](#getVulnerabilityTests).
-}
type alias VulnerabilityTestsResponse =
    { totalCount : Maybe Int
    , resultCount : Maybe Int
    , vulnerabilityTests : List VulnerabilityTest
    }


{-| One vulnerability-test definition (a CVE / scanner check the ASM
engine runs against discovered services).
-}
type alias VulnerabilityTest =
    { id : Maybe String
    , name : Maybe String
    , description : Maybe String
    , status : Maybe String
    , severityScore : Maybe Float
    , epssScore : Maybe Float
    , intrusiveLevel : Maybe String
    , countVulnerableServices : Maybe Int
    , vulnerabilityIds : List String
    , vendorNames : List String
    , cweIds : List String
    , references : List String
    , remediationGuidance : Maybe String
    , firstPublished : Maybe Int
    , created : Maybe Int
    , affectedSoftware : List AffectedSoftware
    }


{-| One affected-software entry under a [`VulnerabilityTest`](#VulnerabilityTest)
— a CPE plus version range describing which package versions the test
applies to.
-}
type alias AffectedSoftware =
    { name : Maybe String
    , vendor : Maybe String
    , product : Maybe String
    , version : Maybe String
    , versionStartIncluding : Maybe String
    , versionStartExcluding : Maybe String
    , versionEndIncluding : Maybe String
    , versionEndExcluding : Maybe String
    }



-- EXTERNAL WEBSITES


{-| Paginated envelope returned by [`getExternalWebsites`](#getExternalWebsites).
-}
type alias ExternalWebsitesResponse =
    { totalCount : Maybe Int
    , resultCount : Maybe Int
    , websites : List ExternalWebsite
    }


{-| One externally-reachable website (a URL the ASM engine has
discovered).
-}
type alias ExternalWebsite =
    { id : Maybe String
    , url : Maybe String
    , statusCode : Maybe Int
    , title : Maybe String
    , favicon : Maybe String
    , firstObserved : Maybe Int
    , lastObserved : Maybe Int
    , externallyDetectedProviders : List String
    , externallyInferredCves : List String
    , technologyMatches : List String
    , businessUnits : List String
    , tags : List String
    }



-- WEBSITES LAST ASSESSMENT


{-| Wrapper for the single `last_external_assessment` field returned by
[`getWebsitesLastAssessment`](#getWebsitesLastAssessment).
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



-- RAW FIELDS


{-| Top-level envelope returned by [`getRawFields`](#getRawFields).
-}
type alias RawFieldsResponse =
    { data : List RawFieldsEntry
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| One row of [`RawFieldsResponse`](#RawFieldsResponse)`.data`. Wraps the
single `xdm.asset.raw_fields` payload — the wrapper is preserved so the
record can grow if the API later adds peer fields next to the raw map.
The wire field name uses dot separators (`xdm.asset.raw_fields`),
matching the rest of the asset namespace; the OpenAPI spec misrenders
it as `xdm__asset__raw_fields`.
-}
type alias RawFieldsEntry =
    { {- Decoder escape: per-asset-type free-form map of category names
         (e.g. "Platform Discovery") to nested objects. The top-level
         categories AND their nested schemas vary entirely per asset
         type AND per cloud provider/source — no fixed schema can be
         expressed at the SDK layer. Often `null` for assets without
         provider-native discovery data (e.g. on-prem agents).
         Preserved verbatim.
      -}
      xdmAssetRawFields : Maybe Encode.Value
    }



-- ENDPOINTS


{-| POST /public\_api/v1/assets — the asset inventory list.
-}
list : Request AssetsResponse
list =
    Request.postEmpty
        [ "public_api", "v1", "assets" ]
        (reply assetsResponseDecoder)


{-| GET /public\_api/v1/assets/schema — list the tenant's asset schema.
-}
getSchema : Request (List SchemaEntry)
getSchema =
    Request.get
        [ "public_api", "v1", "assets", "schema" ]
        (Decode.at [ "reply", "data" ] (Decode.list schemaEntryDecoder))


{-| GET /public\_api/v1/assets/{id} — fetch one asset by its `xdm.asset.id`.

Returns an [`AssetsResponse`](#AssetsResponse) for symmetry with
[`list`](#list); the wire shape is the same envelope (a one-element
`data` array on success).

-}
getAsset : String -> Request AssetsResponse
getAsset id =
    Request.get
        [ "public_api", "v1", "assets", id ]
        (reply assetsResponseDecoder)


{-| GET /public\_api/v1/assets/{id}/raw\_fields — retrieve the raw,
provider-native fields for a single asset (the ungrouped JSON the
discovery source returned, before normalization to the XDM schema).
-}
getRawFields : String -> Request RawFieldsResponse
getRawFields id =
    Request.get
        [ "public_api", "v1", "assets", id, "raw_fields" ]
        (reply rawFieldsResponseDecoder)


{-| GET /public\_api/v1/assets/enum/{field\_name} — list the allowed
enum values for one schema field.

The `fieldName` argument must name an `ENUM`-typed field from
[`getSchema`](#getSchema) (e.g. `xdm.asset.provider`); other types
return a 500 error from the API.

-}
getEnum : String -> Request (List EnumValue)
getEnum fieldName =
    Request.get
        [ "public_api", "v1", "assets", "enum", fieldName ]
        (Decode.at [ "reply", "data" ] (Decode.list enumValueDecoder))


{-| POST /public\_api/v1/assets/get\_external\_services — externally reachable services.
-}
getExternalServices : SearchArgs -> Request ExternalServicesResponse
getExternalServices args =
    Request.post
        [ "public_api", "v1", "assets", "get_external_services" ]
        (RequestData.encode Query.standard
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        (reply (countedDecoder "external_services" externalServiceDecoder ExternalServicesResponse))


{-| POST /public\_api/v1/assets/get\_external\_service — fetch one or
more external services by service ID. Up to 20 IDs per call.

Returns the matching [`ExternalService`](#ExternalService) records
directly (no `total_count` envelope — the singular endpoints wrap their
items in a `details` array which the SDK strips).

-}
getExternalService : { serviceIdList : List String } -> Request (List ExternalService)
getExternalService { serviceIdList } =
    Request.post
        [ "public_api", "v1", "assets", "get_external_service" ]
        (singularRequestBody "service_id_list" serviceIdList)
        (reply (detailsDecoder externalServiceDecoder))


{-| POST /public\_api/v1/assets/get\_assets\_internet\_exposure — assets exposed to the public internet.
-}
getInternetExposures : SearchArgs -> Request InternetExposuresResponse
getInternetExposures args =
    Request.post
        [ "public_api", "v1", "assets", "get_assets_internet_exposure" ]
        (RequestData.encode Query.standard
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        (reply (countedDecoder "assets_internet_exposure" internetExposureDecoder InternetExposuresResponse))


{-| POST /public\_api/v1/assets/get\_asset\_internet\_exposure — fetch
one or more internet-exposed assets by ASM asset ID.
-}
getInternetExposure : { asmIdList : List String } -> Request (List InternetExposure)
getInternetExposure { asmIdList } =
    Request.post
        [ "public_api", "v1", "assets", "get_asset_internet_exposure" ]
        (singularRequestBody "asm_id_list" asmIdList)
        (reply (detailsDecoder internetExposureDecoder))


{-| POST /public\_api/v1/assets/get\_external\_ip\_address\_ranges — discovered external IP ranges.
-}
getExternalIpRanges : SearchArgs -> Request ExternalIpRangesResponse
getExternalIpRanges args =
    Request.post
        [ "public_api", "v1", "assets", "get_external_ip_address_ranges" ]
        (RequestData.encode Query.standard
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        (reply (countedDecoder "external_ip_address_ranges" externalIpRangeDecoder ExternalIpRangesResponse))


{-| POST /public\_api/v1/assets/get\_external\_ip\_address\_range —
fetch one or more external IP-address ranges by range ID.
-}
getExternalIpRange : { rangeIdList : List String } -> Request (List ExternalIpRange)
getExternalIpRange { rangeIdList } =
    Request.post
        [ "public_api", "v1", "assets", "get_external_ip_address_range" ]
        (singularRequestBody "range_id_list" rangeIdList)
        (reply (detailsDecoder externalIpRangeDecoder))


{-| POST /public\_api/v1/assets/get\_vulnerability\_tests — vulnerability scanner results.
-}
getVulnerabilityTests : SearchArgs -> Request VulnerabilityTestsResponse
getVulnerabilityTests args =
    Request.post
        [ "public_api", "v1", "assets", "get_vulnerability_tests" ]
        (RequestData.encode Query.standard
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        (reply (countedDecoder "vulnerability_tests" vulnerabilityTestDecoder VulnerabilityTestsResponse))


{-| POST /public\_api/v1/assets/get\_external\_websites — externally reachable websites.
-}
getExternalWebsites : SearchArgs -> Request ExternalWebsitesResponse
getExternalWebsites args =
    Request.post
        [ "public_api", "v1", "assets", "get_external_websites" ]
        (RequestData.encode Query.standard
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        (reply (countedDecoder "websites" externalWebsiteDecoder ExternalWebsitesResponse))


{-| POST /public\_api/v1/assets/get\_external\_website — fetch one or
more external websites by website ID. Up to 20 IDs per call.
-}
getExternalWebsite : { websiteIdList : List String } -> Request (List ExternalWebsite)
getExternalWebsite { websiteIdList } =
    Request.post
        [ "public_api", "v1", "assets", "get_external_website" ]
        (singularRequestBody "website_id_list" websiteIdList)
        (reply (detailsDecoder externalWebsiteDecoder))


{-| POST /public\_api/v1/assets/get\_external\_websites/last\_external\_assessment —
status + timestamp of the most recent websites scan.
-}
getWebsitesLastAssessment : Request WebsitesLastAssessment
getWebsitesLastAssessment =
    Request.postEmpty
        [ "public_api", "v1", "assets", "get_external_websites", "last_external_assessment" ]
        websitesLastAssessmentDecoder



-- ENCODERS


singularRequestBody : String -> List String -> Encode.Value
singularRequestBody fieldName ids =
    Encode.object
        [ ( "request_data"
          , Encode.object [ ( fieldName, Encode.list Encode.string ids ) ]
          )
        ]



-- DECODERS


countedDecoder : String -> Decoder item -> (Maybe Int -> Maybe Int -> List item -> resp) -> Decoder resp
countedDecoder itemKey itemDecoder ctor =
    Decode.map3 ctor
        (Decode.maybe (Decode.field "total_count" Decode.int))
        (Decode.maybe (Decode.field "result_count" Decode.int))
        (Decode.oneOf
            [ Decode.field itemKey (Decode.list itemDecoder)
            , Decode.succeed []
            ]
        )


detailsDecoder : Decoder item -> Decoder (List item)
detailsDecoder itemDecoder =
    Decode.oneOf
        [ Decode.field "details" (Decode.list itemDecoder)
        , Decode.succeed []
        ]


assetsResponseDecoder : Decoder AssetsResponse
assetsResponseDecoder =
    Decode.map3 AssetsResponse
        (Decode.oneOf
            [ Decode.field "data" (Decode.list assetDecoder)
            , Decode.succeed []
            ]
        )
        (Decode.maybe (Decode.at [ "metadata", "filter_count" ] Decode.int))
        (Decode.maybe (Decode.at [ "metadata", "total_count" ] Decode.int))


assetDecoder : Decoder Asset
assetDecoder =
    Decode.succeed Asset
        |> andMap (optionalField "xdm.asset.id" Decode.string)
        |> andMap (optionalField "xdm.asset.strong_id" Decode.string)
        |> andMap (optionalField "xdm.asset.name" Decode.string)
        |> andMap (optionalField "xdm.asset.external_provider_id" Decode.string)
        |> andMap (optionalField "xdm.asset.provider" Decode.string)
        |> andMap (optionalField "xdm.asset.realm" Decode.string)
        |> andMap (optionalField "xdm.asset.type.id" Decode.string)
        |> andMap (optionalField "xdm.asset.type.name" Decode.string)
        |> andMap (optionalField "xdm.asset.type.category" Decode.string)
        |> andMap (optionalField "xdm.asset.type.class" Decode.string)
        |> andMap (optionalField "xdm.asset.cloud.region" Decode.string)
        |> andMap (optionalField "xdm.asset.first_observed" Decode.int)
        |> andMap (optionalField "xdm.asset.last_observed" Decode.int)
        |> andMap (optionalList "xdm.asset.group_ids" Decode.int)
        |> andMap (optionalList "xdm.host.ipv4_addresses" Decode.string)
        |> andMap (optionalField "xdm.asset.related_issues.critical_issues" Decode.int)
        |> andMap (optionalField "xdm.asset.related_issues.issues_breakdown" assetCountsDecoder)
        |> andMap (optionalField "xdm.asset.related_cases.critical_cases" Decode.int)
        |> andMap (optionalField "xdm.asset.related_cases.cases_breakdown" assetCountsDecoder)


assetCountsDecoder : Decoder AssetCounts
assetCountsDecoder =
    Decode.map4 AssetCounts
        (optionalField "critical" Decode.int)
        (optionalField "high" Decode.int)
        (optionalField "medium" Decode.int)
        (optionalField "low" Decode.int)


schemaEntryDecoder : Decoder SchemaEntry
schemaEntryDecoder =
    Decode.map3 SchemaEntry
        (optionalField "field_name" Decode.string)
        (optionalField "field_pretty_name" Decode.string)
        (optionalField "data_type" Decode.string)


enumValueDecoder : Decoder EnumValue
enumValueDecoder =
    Decode.map2 EnumValue
        (optionalField "NAME" Decode.string)
        (optionalField "PRETTY_NAME" Decode.string)


externalServiceDecoder : Decoder ExternalService
externalServiceDecoder =
    Decode.succeed ExternalService
        |> andMap (optionalField "service_id" Decode.string)
        |> andMap (optionalField "service_name" Decode.string)
        |> andMap (optionalField "service_type" Decode.string)
        |> andMap (optionalList "ip_address" Decode.string)
        |> andMap (optionalList "externally_detected_providers" Decode.string)
        |> andMap (optionalList "externally_inferred_cves" Decode.string)
        |> andMap (optionalField "is_active" Decode.string)
        |> andMap (optionalField "first_observed" Decode.int)
        |> andMap (optionalField "last_observed" Decode.int)
        |> andMap (optionalField "protocol" Decode.string)
        |> andMap (optionalField "port" Decode.int)
        -- ^ wire field is "port"; Elm record field is `port_` because port is reserved
        |> andMap (optionalList "domain" Decode.string)
        |> andMap (optionalList "active_classifications" Decode.string)
        |> andMap (optionalList "inactive_classifications" Decode.string)
        |> andMap (optionalField "discovery_type" Decode.string)
        |> andMap (optionalList "business_units_list" Decode.string)
        |> andMap (optionalList "tags" Decode.string)
        {- Decoder escape: per-asset-type `details` map; keys/shape vary
           with the asset's protocol/service and cannot be typed at the
           SDK layer.
        -}
        |> andMap (optionalField "details" Decode.value)


internetExposureDecoder : Decoder InternetExposure
internetExposureDecoder =
    Decode.succeed InternetExposure
        |> andMap (optionalField "asset_id" Decode.string)
        |> andMap (optionalField "name" Decode.string)
        |> andMap (optionalField "type" Decode.string)
        |> andMap (optionalField "ip_address" Decode.string)
        |> andMap (optionalField "ipv6_address" Decode.string)
        |> andMap (optionalField "domain" Decode.string)
        |> andMap (optionalList "externally_detected_providers" Decode.string)
        |> andMap (optionalList "externally_inferred_cves" Decode.string)
        |> andMap (optionalField "externally_inferred_vulnerability_score" Decode.float)
        |> andMap (optionalList "business_units_list" Decode.string)
        |> andMap (optionalField "first_observed" Decode.int)
        |> andMap (optionalField "last_observed" Decode.int)
        |> andMap (optionalField "active_services" Decode.int)
        |> andMap (optionalList "active_external_services" Decode.string)
        |> andMap (optionalList "tags" Decode.string)


externalIpRangeDecoder : Decoder ExternalIpRange
externalIpRangeDecoder =
    Decode.succeed ExternalIpRange
        |> andMap (optionalField "range_id" Decode.string)
        |> andMap (optionalField "first_ip" Decode.string)
        |> andMap (optionalField "last_ip" Decode.string)
        |> andMap (optionalField "ips_count" Decode.int)
        |> andMap (optionalField "active_responsive_ips_count" Decode.int)
        |> andMap (optionalField "date_added" Decode.int)
        |> andMap (optionalList "annotations" Decode.string)
        |> andMap (optionalList "organization_handles" Decode.string)
        |> andMap (optionalList "business_units_list" Decode.string)
        |> andMap (optionalList "tags" Decode.string)


vulnerabilityTestDecoder : Decoder VulnerabilityTest
vulnerabilityTestDecoder =
    Decode.succeed VulnerabilityTest
        |> andMap (optionalField "id" Decode.string)
        |> andMap (optionalField "name" Decode.string)
        |> andMap (optionalField "description" Decode.string)
        |> andMap (optionalField "status" Decode.string)
        |> andMap (optionalField "severity_score" Decode.float)
        |> andMap (optionalField "epss_score" Decode.float)
        |> andMap (optionalField "intrusive_level" Decode.string)
        |> andMap (optionalField "count_vulnerable_services" Decode.int)
        |> andMap (optionalList "vulnerability_ids" Decode.string)
        |> andMap (optionalList "vendor_names" Decode.string)
        |> andMap (optionalList "cwe_ids" Decode.string)
        |> andMap (optionalList "references" Decode.string)
        |> andMap (optionalField "remediation_guidance" Decode.string)
        |> andMap (optionalField "first_published" Decode.int)
        |> andMap (optionalField "created" Decode.int)
        |> andMap (optionalList "affected_software" affectedSoftwareDecoder)


affectedSoftwareDecoder : Decoder AffectedSoftware
affectedSoftwareDecoder =
    Decode.map8 AffectedSoftware
        (optionalField "NAME" Decode.string)
        (optionalField "VENDOR" Decode.string)
        (optionalField "PRODUCT" Decode.string)
        (optionalField "VERSION" Decode.string)
        (optionalField "VERSION_START_INCLUDING" Decode.string)
        (optionalField "VERSION_START_EXCLUDING" Decode.string)
        (optionalField "VERSION_END_INCLUDING" Decode.string)
        (optionalField "VERSION_END_EXCLUDING" Decode.string)


externalWebsiteDecoder : Decoder ExternalWebsite
externalWebsiteDecoder =
    Decode.succeed ExternalWebsite
        |> andMap (optionalField "id" Decode.string)
        |> andMap (optionalField "url" Decode.string)
        |> andMap (optionalField "status_code" Decode.int)
        |> andMap (optionalField "title" Decode.string)
        |> andMap (optionalField "favicon" Decode.string)
        |> andMap (optionalField "first_observed" Decode.int)
        |> andMap (optionalField "last_observed" Decode.int)
        |> andMap (optionalList "externally_detected_providers" Decode.string)
        |> andMap (optionalList "externally_inferred_cves" Decode.string)
        |> andMap (optionalList "technology_matches" Decode.string)
        |> andMap (optionalList "business_units_list" Decode.string)
        |> andMap (optionalList "tags" Decode.string)


websitesLastAssessmentDecoder : Decoder WebsitesLastAssessment
websitesLastAssessmentDecoder =
    Decode.map WebsitesLastAssessment
        (Decode.field "last_external_assessment" lastAssessmentDecoder)


lastAssessmentDecoder : Decoder LastAssessment
lastAssessmentDecoder =
    Decode.map2 LastAssessment
        (Decode.maybe (Decode.field "status" Decode.bool))
        (Decode.maybe (Decode.field "time" Decode.int))


rawFieldsResponseDecoder : Decoder RawFieldsResponse
rawFieldsResponseDecoder =
    Decode.map3 RawFieldsResponse
        (Decode.oneOf
            [ Decode.field "data" (Decode.list rawFieldsEntryDecoder)
            , Decode.succeed []
            ]
        )
        (Decode.maybe (Decode.at [ "metadata", "filter_count" ] Decode.int))
        (Decode.maybe (Decode.at [ "metadata", "total_count" ] Decode.int))


rawFieldsEntryDecoder : Decoder RawFieldsEntry
rawFieldsEntryDecoder =
    Decode.map RawFieldsEntry
        {- Decoder escape: free-form per-asset map; see RawFieldsEntry doc.
           Decode.maybe maps a wire `null` to `Nothing` so on-prem assets
           without provider-native discovery data still satisfy the decoder.
        -}
        (Decode.maybe (Decode.field "xdm.asset.raw_fields" Decode.value))
