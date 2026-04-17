module Cli.Encode.Distributions exposing (encodeDistributions, encodeVersions)

import Cortex.Api.Distributions exposing (Distribution, DistributionsResponse, Versions)
import Json.Encode as Encode


encodeVersions : Versions -> Encode.Value
encodeVersions versions =
    Encode.object
        [ ( "windows", Encode.list Encode.string versions.windows )
        , ( "linux", Encode.list Encode.string versions.linux )
        , ( "macos", Encode.list Encode.string versions.macos )
        , ( "container", Encode.list Encode.string versions.container )
        , ( "serverless", Encode.list Encode.string versions.serverless )
        ]


encodeDistributions : DistributionsResponse -> Encode.Value
encodeDistributions response =
    Encode.object
        (List.filterMap identity
            [ Just ( "data", Encode.list encodeDistribution response.data )
            , Maybe.map (\v -> ( "filter_count", Encode.int v )) response.filterCount
            , Maybe.map (\v -> ( "total_count", Encode.int v )) response.totalCount
            ]
        )


encodeDistribution : Distribution -> Encode.Value
encodeDistribution d =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "distribution_id", Encode.string v )) d.distributionId
            , Maybe.map (\v -> ( "name", Encode.string v )) d.name
            , Maybe.map (\v -> ( "description", Encode.string v )) d.description
            , Maybe.map (\v -> ( "package_type", Encode.string v )) d.packageType
            , Maybe.map (\v -> ( "platform", Encode.string v )) d.platform
            , Maybe.map (\v -> ( "agent_version", Encode.string v )) d.agentVersion
            , Maybe.map (\v -> ( "status", Encode.string v )) d.status
            , Just ( "tags", Encode.list Encode.string d.tags )
            , Maybe.map (\v -> ( "eol_time", Encode.int v )) d.eolTime
            , Maybe.map (\v -> ( "created_by", Encode.string v )) d.createdBy
            , Maybe.map (\v -> ( "creation_time", Encode.int v )) d.creationTime
            , Maybe.map (\v -> ( "modification_time", Encode.int v )) d.modificationTime
            , Just ( "supported_packages", Encode.list Encode.string d.supportedPackages )
            ]
        )
