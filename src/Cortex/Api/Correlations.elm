module Cortex.Api.Correlations exposing
    ( SearchArgs, defaultSearchArgs
    , CorrelationsResponse
    , get
    )

{-| Cortex correlation rules.

@docs SearchArgs, defaultSearchArgs
@docs CorrelationsResponse
@docs get

-}

import Cortex.Query as Query exposing (Filter, Range, Sort, Timeframe)
import Cortex.Request as Request exposing (Request)
import Cortex.RequestData as RequestData
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Arguments to [`get`](#get). All fields are optional; pass
[`defaultSearchArgs`](#defaultSearchArgs) for an unfiltered request. `extra`
is merged last into `request_data` and overrides any SDK-generated key on
collision.
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


{-| Correlation rule objects contain ~20 variable fields including query text
and complex nested configuration. We decode them as raw JSON to preserve every
field without mirroring the whole Cortex correlation-rules schema.
-}
type alias CorrelationsResponse =
    { objectsCount : Maybe Int
    , objects : List Encode.Value
    , objectsType : Maybe String
    }


{-| POST /public\_api/v1/correlations/get

Response is top-level `{objects_count, objects, objects_type}` — NOT wrapped
in the usual `reply` envelope.

-}
get : SearchArgs -> Request CorrelationsResponse
get args =
    Request.post
        [ "public_api", "v1", "correlations", "get" ]
        (RequestData.encode Query.standard
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        correlationsResponseDecoder


correlationsResponseDecoder : Decoder CorrelationsResponse
correlationsResponseDecoder =
    Decode.map3 CorrelationsResponse
        (Decode.maybe (Decode.field "objects_count" Decode.int))
        (Decode.oneOf
            [ Decode.field "objects" (Decode.list Decode.value)
            , Decode.succeed []
            ]
        )
        (Decode.maybe (Decode.field "objects_type" Decode.string))
