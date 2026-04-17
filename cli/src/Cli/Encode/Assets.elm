module Cli.Encode.Assets exposing
    ( encodeAssets
    , encodeExternalIpRanges
    , encodeExternalServices
    , encodeExternalWebsites
    , encodeInternetExposures
    , encodeSchema
    , encodeVulnerabilityTests
    , encodeWebsitesLastAssessment
    )

import Cortex.Api.Assets exposing (AssetsResponse, CountedResponse, LastAssessment, SchemaEntry, WebsitesLastAssessment)
import Json.Encode as Encode


encodeAssets : AssetsResponse -> Encode.Value
encodeAssets r =
    Encode.object
        [ ( "data", Encode.list identity r.data )
        , ( "metadata"
          , Encode.object
                (List.filterMap identity
                    [ Maybe.map (\v -> ( "filter_count", Encode.int v )) r.filterCount
                    , Maybe.map (\v -> ( "total_count", Encode.int v )) r.totalCount
                    ]
                )
          )
        ]


encodeSchema : List SchemaEntry -> Encode.Value
encodeSchema entries =
    Encode.list encodeSchemaEntry entries


encodeSchemaEntry : SchemaEntry -> Encode.Value
encodeSchemaEntry e =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "field_name", Encode.string v )) e.fieldName
            , Maybe.map (\v -> ( "field_pretty_name", Encode.string v )) e.fieldPrettyName
            , Maybe.map (\v -> ( "data_type", Encode.string v )) e.dataType
            ]
        )


encodeExternalServices : CountedResponse -> Encode.Value
encodeExternalServices r =
    encodeCounted "external_services" r


encodeInternetExposures : CountedResponse -> Encode.Value
encodeInternetExposures r =
    encodeCounted "assets_internet_exposure" r


encodeExternalIpRanges : CountedResponse -> Encode.Value
encodeExternalIpRanges r =
    encodeCounted "external_ip_address_ranges" r


encodeVulnerabilityTests : CountedResponse -> Encode.Value
encodeVulnerabilityTests r =
    encodeCounted "vulnerability_tests" r


encodeExternalWebsites : CountedResponse -> Encode.Value
encodeExternalWebsites r =
    encodeCounted "websites" r


encodeWebsitesLastAssessment : WebsitesLastAssessment -> Encode.Value
encodeWebsitesLastAssessment r =
    Encode.object
        [ ( "last_external_assessment", encodeLastAssessment r.lastExternalAssessment )
        ]


encodeLastAssessment : LastAssessment -> Encode.Value
encodeLastAssessment a =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "status", Encode.bool v )) a.status
            , Maybe.map (\v -> ( "time", Encode.int v )) a.time
            ]
        )


encodeCounted : String -> CountedResponse -> Encode.Value
encodeCounted itemKey r =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "total_count", Encode.int v )) r.totalCount
            , Maybe.map (\v -> ( "result_count", Encode.int v )) r.resultCount
            , Just ( itemKey, Encode.list identity r.items )
            ]
        )
