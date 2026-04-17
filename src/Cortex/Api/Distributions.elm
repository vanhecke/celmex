module Cortex.Api.Distributions exposing
    ( Distribution, DistributionsResponse, Versions
    , getDistributions, getVersions
    )

{-| Cortex agent installer distributions and available versions.

@docs Distribution, DistributionsResponse, Versions
@docs getDistributions, getVersions

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
