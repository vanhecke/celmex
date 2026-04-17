module Cortex.Api.Cases exposing
    ( SearchResponse
    , search
    )

import Cortex.Decode exposing (optionalList, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Case records carry ~37 normalized fields plus tenant-defined
`custom_fields`, so we preserve them as raw JSON and only type the
paginated envelope counters — same tactic as `Issues.search`.
-}
type alias SearchResponse =
    { data : List Encode.Value
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| POST /public\_api/v1/case/search
-}
search : Request SearchResponse
search =
    Request.postEmpty
        [ "public_api", "v1", "case", "search" ]
        (reply searchResponseDecoder)


searchResponseDecoder : Decoder SearchResponse
searchResponseDecoder =
    Decode.map3 SearchResponse
        (optionalList "DATA" Decode.value)
        (Decode.maybe (Decode.field "FILTER_COUNT" Decode.int))
        (Decode.maybe (Decode.field "TOTAL_COUNT" Decode.int))
