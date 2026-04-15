module Cortex.Api.Distributions exposing
    ( Distribution
    , DistributionsResponse
    , Versions
    , encodeDistributions
    , encodeVersions
    , getDistributions
    , getVersions
    )

import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| The OpenAPI spec only documents `windows`, `linux`, and `macos`, but the
live tenant also returns `container` and `serverless` arrays. Per CLAUDE.md
we capture every field the API returns.
-}
type alias Versions =
    { windows : List String
    , linux : List String
    , macos : List String
    , container : List String
    , serverless : List String
    }


type alias DistributionsResponse =
    { data : List Distribution
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


type alias Distribution =
    { distributionId : Maybe String
    , name : Maybe String
    , description : Maybe String
    , packageType : Maybe String
    , platform : Maybe String
    , agentVersion : Maybe String
    , status : Maybe String
    , tags : List String
    , eolTime : Maybe Int
    , createdBy : Maybe String
    , creationTime : Maybe Int
    , modificationTime : Maybe Int
    , supportedPackages : List String
    }


{-| POST /public\_api/v1/distributions/get\_versions
-}
getVersions : Request Versions
getVersions =
    Request.post
        [ "public_api", "v1", "distributions", "get_versions" ]
        (Encode.object [])
        (Decode.field "reply" versionsDecoder)


{-| POST /public\_api/v1/distributions/get\_distributions
-}
getDistributions : Request DistributionsResponse
getDistributions =
    Request.post
        [ "public_api", "v1", "distributions", "get_distributions" ]
        (Encode.object [ ( "request_data", Encode.object [] ) ])
        (Decode.field "reply" distributionsResponseDecoder)


versionsDecoder : Decoder Versions
versionsDecoder =
    Decode.map5 Versions
        (optionalList "windows" Decode.string)
        (optionalList "linux" Decode.string)
        (optionalList "macos" Decode.string)
        (optionalList "container" Decode.string)
        (optionalList "serverless" Decode.string)


distributionsResponseDecoder : Decoder DistributionsResponse
distributionsResponseDecoder =
    Decode.map3 DistributionsResponse
        (optionalList "data" distributionDecoder)
        (Decode.maybe (Decode.field "filter_count" Decode.int))
        (Decode.maybe (Decode.field "total_count" Decode.int))


distributionDecoder : Decoder Distribution
distributionDecoder =
    Decode.map8 Distribution
        (Decode.maybe (Decode.field "distribution_id" Decode.string))
        (Decode.maybe (Decode.field "name" Decode.string))
        (Decode.maybe (Decode.field "description" Decode.string))
        (Decode.maybe (Decode.field "package_type" Decode.string))
        (Decode.maybe (Decode.field "platform" Decode.string))
        (Decode.maybe (Decode.field "agent_version" Decode.string))
        (Decode.maybe (Decode.field "status" Decode.string))
        (optionalList "tags" Decode.string)
        |> andMap (Decode.maybe (Decode.field "eol_time" Decode.int))
        |> andMap (Decode.maybe (Decode.field "created_by" Decode.string))
        |> andMap (Decode.maybe (Decode.field "creation_time" Decode.int))
        |> andMap (Decode.maybe (Decode.field "modification_time" Decode.int))
        |> andMap (optionalList "supported_packages" Decode.string)


optionalList : String -> Decoder a -> Decoder (List a)
optionalList field itemDecoder =
    Decode.oneOf
        [ Decode.field field (Decode.list itemDecoder)
        , Decode.succeed []
        ]


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap valDecoder funcDecoder =
    Decode.map2 (\f v -> f v) funcDecoder valDecoder


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
