module Cortex.Api.Biocs exposing
    ( SearchArgs, defaultSearchArgs
    , BiocsResponse
    , get
    )

{-| Cortex behavioral indicators of compromise (BIOCs).

@docs SearchArgs, defaultSearchArgs
@docs BiocsResponse
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
collision — e.g. `extended_view` is reachable through it.
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


{-| BIOC objects have ~15 variable fields including a nested `indicator` object
whose shape depends on the rule type. We decode the BIOC items as raw JSON so
every field is preserved without duplicating the whole Cortex BIOC schema here.
-}
type alias BiocsResponse =
    { objectsCount : Maybe Int
    , objects : List Encode.Value
    , objectsType : Maybe String
    }


{-| POST /public\_api/v1/bioc/get

Response is top-level `{objects_count, objects, objects_type}` — NOT wrapped
in the usual `reply` envelope.

-}
get : SearchArgs -> Request BiocsResponse
get args =
    Request.post
        [ "public_api", "v1", "bioc", "get" ]
        (RequestData.encode Query.standard
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        biocsResponseDecoder


biocsResponseDecoder : Decoder BiocsResponse
biocsResponseDecoder =
    Decode.map3 BiocsResponse
        (Decode.maybe (Decode.field "objects_count" Decode.int))
        (Decode.oneOf
            [ Decode.field "objects" (Decode.list Decode.value)
            , Decode.succeed []
            ]
        )
        (Decode.maybe (Decode.field "objects_type" Decode.string))
