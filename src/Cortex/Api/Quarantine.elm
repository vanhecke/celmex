module Cortex.Api.Quarantine exposing
    ( FileQuery, FileStatus
    , getStatus
    )

{-| Quarantine status lookup for files on Cortex-managed endpoints.

@docs FileQuery, FileStatus
@docs getStatus

-}

import Cortex.Decode exposing (reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| One file to look up, identified by the endpoint it lives on, its path, and
its SHA-256 hash.

The OpenAPI spec swaps the `file_path` and `file_hash` field descriptions, but
the wire format and example payload confirm `filePath` is the on-disk path and
`fileHash` is the SHA-256.

-}
type alias FileQuery =
    { endpointId : String
    , filePath : String
    , fileHash : String
    }


{-| Quarantine status of a single file, returned by [`getStatus`](#getStatus).

`status` is `Just True` when the file is quarantined on the endpoint, `Just
False` when it is not. All fields are wrapped in `Maybe` because the API
schema does not mark them required.

-}
type alias FileStatus =
    { endpointId : Maybe String
    , filePath : Maybe String
    , fileHash : Maybe String
    , status : Maybe Bool
    }


{-| POST /public\_api/v1/quarantine/status

Look up the quarantine status of one or more files. The API rejects an empty
list with HTTP 500, so callers should pass at least one [`FileQuery`](#FileQuery).

-}
getStatus : List FileQuery -> Request (List FileStatus)
getStatus files =
    Request.post
        [ "public_api", "v1", "quarantine", "status" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object
                    [ ( "files", Encode.list encodeFileQuery files ) ]
              )
            ]
        )
        (reply (Decode.list fileStatusDecoder))


encodeFileQuery : FileQuery -> Encode.Value
encodeFileQuery q =
    Encode.object
        [ ( "endpoint_id", Encode.string q.endpointId )
        , ( "file_path", Encode.string q.filePath )
        , ( "file_hash", Encode.string q.fileHash )
        ]


fileStatusDecoder : Decoder FileStatus
fileStatusDecoder =
    Decode.map4 FileStatus
        (Decode.maybe (Decode.field "endpoint_id" Decode.string))
        (Decode.maybe (Decode.field "file_path" Decode.string))
        (Decode.maybe (Decode.field "file_hash" Decode.string))
        (Decode.maybe (Decode.field "status" Decode.bool))
