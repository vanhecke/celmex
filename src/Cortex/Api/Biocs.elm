module Cortex.Api.Biocs exposing
    ( SearchArgs, defaultSearchArgs
    , Bioc, BiocsResponse
    , get
    )

{-| Cortex behavioral indicators of compromise (BIOCs).

@docs SearchArgs, defaultSearchArgs
@docs Bioc, BiocsResponse
@docs get

-}

import Cortex.Decode exposing (andMap, optionalList)
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


{-| Top-level envelope returned by [`get`](#get). Not wrapped in the
standard `reply`.
-}
type alias BiocsResponse =
    { objectsCount : Maybe Int
    , objects : List Bioc
    , objectsType : Maybe String
    }


{-| A single BIOC rule.
-}
type alias Bioc =
    { ruleId : Maybe Int
    , name : Maybe String
    , type_ : Maybe String
    , severity : Maybe String
    , status : Maybe String
    , comment : Maybe String
    , isXql : Maybe Bool
    , mitreTacticIdAndName : List String
    , mitreTechniqueIdAndName : List String

    {- indicator is a deeply nested investigation-rule schema specific to
       the BIOC's detection mechanism — PROCESS_EXECUTION_EVENT,
       FILE_EVENT, REGISTRY_EVENT, etc., each with its own filter AND/OR
       tree of SEARCH_FIELD/OPERATOR/VALUE rows. The shape is genuinely
       polymorphic per detection type and re-typing the whole investigation
       DSL belongs in a dedicated module. Preserved verbatim.
    -}
    , indicator : Maybe Encode.Value
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



-- DECODERS


biocsResponseDecoder : Decoder BiocsResponse
biocsResponseDecoder =
    Decode.map3 BiocsResponse
        (Decode.maybe (Decode.field "objects_count" Decode.int))
        (Decode.oneOf
            [ Decode.field "objects" (Decode.list biocDecoder)
            , Decode.succeed []
            ]
        )
        (Decode.maybe (Decode.field "objects_type" Decode.string))


biocDecoder : Decoder Bioc
biocDecoder =
    Decode.succeed Bioc
        |> andMap (optionalField "rule_id" Decode.int)
        |> andMap (optionalField "name" Decode.string)
        |> andMap (optionalField "type" Decode.string)
        |> andMap (optionalField "severity" Decode.string)
        |> andMap (optionalField "status" Decode.string)
        |> andMap (optionalField "comment" Decode.string)
        |> andMap (optionalField "is_xql" Decode.bool)
        |> andMap (optionalList "mitre_tactic_id_and_name" Decode.string)
        |> andMap (optionalList "mitre_technique_id_and_name" Decode.string)
        |> andMap (optionalField "indicator" Decode.value)


optionalField : String -> Decoder a -> Decoder (Maybe a)
optionalField name d =
    Decode.maybe (Decode.field name d)
