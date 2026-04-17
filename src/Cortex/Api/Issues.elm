module Cortex.Api.Issues exposing
    ( SearchResponse
    , search
    )

import Cortex.Decode exposing (reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Issue records have ~50 normalized fields plus tenant-specific custom fields,
so we preserve them as raw JSON and only type the paginated envelope counters.
-}
type alias SearchResponse =
    { data : List Encode.Value
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| POST /public\_api/v1/issue/search
-}
search : Request SearchResponse
search =
    Request.postEmpty
        [ "public_api", "v1", "issue", "search" ]
        (reply searchResponseDecoder)


searchResponseDecoder : Decoder SearchResponse
searchResponseDecoder =
    Decode.map3 SearchResponse
        (Decode.oneOf
            [ Decode.field "DATA" (Decode.list Decode.value)
            , Decode.field "data" (Decode.list Decode.value)
            , Decode.succeed []
            ]
        )
        (Decode.maybe
            (Decode.oneOf
                [ Decode.field "FILTER_COUNT" Decode.int
                , Decode.field "filter_count" Decode.int
                ]
            )
        )
        (Decode.maybe
            (Decode.oneOf
                [ Decode.field "TOTAL_COUNT" Decode.int
                , Decode.field "total_count" Decode.int
                ]
            )
        )
