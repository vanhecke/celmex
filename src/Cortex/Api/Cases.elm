module Cortex.Api.Cases exposing
    ( SearchArgs, defaultSearchArgs
    , SearchResponse
    , search
    )

{-| Cortex case search.

@docs SearchArgs, defaultSearchArgs
@docs SearchResponse
@docs search

-}

import Cortex.Decode exposing (optionalList, reply)
import Cortex.Query exposing (Filter, Range, Sort, Timeframe)
import Cortex.Request as Request exposing (Request)
import Cortex.RequestData as RequestData
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Arguments to [`search`](#search). All fields are optional; pass
[`defaultSearchArgs`](#defaultSearchArgs) for an unfiltered request. `extra`
is merged last into `request_data` and overrides any SDK-generated key on
collision — use it to reach fields the SDK has not modeled yet.
-}
type alias SearchArgs =
    { filters : List Filter
    , sort : Maybe Sort
    , range : Maybe Range
    , timeframe : Maybe Timeframe
    , extra : List ( String, Encode.Value )
    }


{-| A [`SearchArgs`](#SearchArgs) with no filters, sort, pagination, or
timeframe — equivalent to an unfiltered search.
-}
defaultSearchArgs : SearchArgs
defaultSearchArgs =
    { filters = []
    , sort = Nothing
    , range = Nothing
    , timeframe = Nothing
    , extra = []
    }


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
search : SearchArgs -> Request SearchResponse
search args =
    Request.post
        [ "public_api", "v1", "case", "search" ]
        (RequestData.encode
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        (reply searchResponseDecoder)


searchResponseDecoder : Decoder SearchResponse
searchResponseDecoder =
    Decode.map3 SearchResponse
        (optionalList "DATA" Decode.value)
        (Decode.maybe (Decode.field "FILTER_COUNT" Decode.int))
        (Decode.maybe (Decode.field "TOTAL_COUNT" Decode.int))
