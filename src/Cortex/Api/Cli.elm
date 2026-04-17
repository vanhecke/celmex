module Cortex.Api.Cli exposing
    ( VersionResponse
    , getVersion
    )

import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)


type alias VersionResponse =
    { version : String
    }


{-| GET /public\_api/v1/cli/releases/version

Get the latest version of the Cortex CLI.

-}
getVersion : Request VersionResponse
getVersion =
    Request.get
        [ "public_api", "v1", "cli", "releases", "version" ]
        versionResponseDecoder


versionResponseDecoder : Decoder VersionResponse
versionResponseDecoder =
    Decode.map VersionResponse
        (Decode.field "version" Decode.string)
