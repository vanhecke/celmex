module Cortex.Api.Distributions exposing
    ( Distribution, DistributionsResponse, Versions
    , DistributionStatus, DistributionUrl
    , getDistributions, getVersions
    , getStatus, getDistUrl
    )

{-| Cortex agent installer distributions and available versions.

@docs Distribution, DistributionsResponse, Versions
@docs DistributionStatus, DistributionUrl
@docs getDistributions, getVersions
@docs getStatus, getDistUrl

-}

import Cortex.Decode exposing (andMap, optionalList, reply)
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


{-| Paginated envelope returned by [`getDistributions`](#getDistributions).
-}
type alias DistributionsResponse =
    { data : List Distribution
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| A single agent installer distribution.
-}
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
        (reply versionsDecoder)


{-| POST /public\_api/v1/distributions/get\_distributions
-}
getDistributions : Request DistributionsResponse
getDistributions =
    Request.postEmpty
        [ "public_api", "v1", "distributions", "get_distributions" ]
        (reply distributionsResponseDecoder)


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


{-| Build status of a distribution package, returned by [`getStatus`](#getStatus).
-}
type alias DistributionStatus =
    { status : Maybe String
    }


{-| Signed download URL for a distribution package, returned by [`getDistUrl`](#getDistUrl).
-}
type alias DistributionUrl =
    { distributionUrl : Maybe String
    }


{-| POST /public\_api/v1/distributions/get\_status
-}
getStatus : String -> Request DistributionStatus
getStatus distributionId =
    Request.post
        [ "public_api", "v1", "distributions", "get_status" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object [ ( "distribution_id", Encode.string distributionId ) ]
              )
            ]
        )
        (reply distributionStatusDecoder)


{-| POST /public\_api/v1/distributions/get\_dist\_url

`packageType` must match the platform of the distribution. Valid values include
`pkg` (macOS), `x86`/`x64`/`arm` (Windows), and `sh`/`rpm`/`deb` (Linux). The
[`Distribution`](#Distribution) record's `supportedPackages` field lists the
valid choices for a given distribution.

-}
getDistUrl : { distributionId : String, packageType : String } -> Request DistributionUrl
getDistUrl args =
    Request.post
        [ "public_api", "v1", "distributions", "get_dist_url" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object
                    [ ( "distribution_id", Encode.string args.distributionId )
                    , ( "package_type", Encode.string args.packageType )
                    ]
              )
            ]
        )
        (reply distributionUrlDecoder)


distributionStatusDecoder : Decoder DistributionStatus
distributionStatusDecoder =
    Decode.map DistributionStatus
        (Decode.maybe (Decode.field "status" Decode.string))


distributionUrlDecoder : Decoder DistributionUrl
distributionUrlDecoder =
    Decode.map DistributionUrl
        (Decode.maybe (Decode.field "distribution_url" Decode.string))


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
