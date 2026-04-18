module Cortex.Api.Issues exposing
    ( SearchArgs, defaultSearchArgs
    , SearchResponse
    , search, schema
    )

{-| Cortex issue records (alerts/incidents) and their tenant-defined schema.

@docs SearchArgs, defaultSearchArgs
@docs SearchResponse
@docs search, schema

-}

import Cortex.Decode exposing (reply)
import Cortex.Query exposing (Filter, Range, Sort, Timeframe)
import Cortex.Request as Request exposing (Request)
import Cortex.RequestData as RequestData
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Arguments to [`search`](#search). All fields are optional; pass
[`defaultSearchArgs`](#defaultSearchArgs) for an unfiltered request. `extra`
is merged last into `request_data` and overrides any SDK-generated key on
collision — use it for fields the SDK has not modeled yet.
-}
type alias SearchArgs =
    { filters : List Filter
    , sort : Maybe Sort
    , range : Maybe Range
    , timeframe : Maybe Timeframe
    , extra : List ( String, Encode.Value )
    }


{-| A [`SearchArgs`](#SearchArgs) with no filters, sort, pagination, or
timeframe.
-}
defaultSearchArgs : SearchArgs
defaultSearchArgs =
    { filters = []
    , sort = Nothing
    , range = Nothing
    , timeframe = Nothing
    , extra = []
    }


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
search : SearchArgs -> Request SearchResponse
search args =
    Request.post
        [ "public_api", "v1", "issue", "search" ]
        (RequestData.encode
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        (reply searchResponseDecoder)


{-| POST /public\_api/v1/issue/schema

Returns the issue field schema (field names, types, allowed operators).
The schema is a large variable-shape object; surfaced as raw JSON so
callers can drill in to whichever parts they need.

-}
schema : Request Encode.Value
schema =
    Request.postEmpty
        [ "public_api", "v1", "issue", "schema" ]
        (reply Decode.value)


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
