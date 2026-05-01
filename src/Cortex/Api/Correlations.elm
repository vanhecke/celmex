module Cortex.Api.Correlations exposing
    ( SearchArgs, defaultSearchArgs
    , Correlation, CorrelationsResponse
    , get
    )

{-| Cortex correlation rules — XQL queries that produce alerts on a
schedule or in real time.

@docs SearchArgs, defaultSearchArgs
@docs Correlation, CorrelationsResponse
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


{-| Top-level envelope returned by [`get`](#get). Not wrapped in the
standard `reply`.
-}
type alias CorrelationsResponse =
    { objectsCount : Maybe Int
    , objects : List Correlation
    , objectsType : Maybe String
    }


{-| A single correlation rule.
-}
type alias Correlation =
    { id : Maybe Int
    , name : Maybe String
    , description : Maybe String
    , severity : Maybe String
    , isEnabled : Maybe String
    , xqlQuery : Maybe String
    , dataset : Maybe String
    , executionMode : Maybe String
    , searchWindow : Maybe String
    , simpleSchedule : Maybe String
    , crontab : Maybe String
    , timezone : Maybe String
    , suppressionEnabled : Maybe Bool
    , suppressionDuration : Maybe String
    , suppressionFields : List String
    , alertName : Maybe String
    , alertCategory : Maybe String
    , alertDescription : Maybe String
    , alertDomain : Maybe String

    {- alertFields is a free-form template for the emitted alert; keys
       are field names supplied by the rule author (variable per rule).
       Preserved verbatim.
    -}
    , alertFields : Maybe Encode.Value
    , userDefinedSeverity : Maybe String
    , userDefinedCategory : Maybe String

    {- mitreDefs is a map keyed by MITRE tactic ID-and-name strings (e.g.
       "TA0005 - Defense Evasion") to a list of associated technique IDs.
       The keyset is dynamic per rule, so this stays opaque.
    -}
    , mitreDefs : Maybe Encode.Value
    , investigationQueryLink : Maybe String
    , drilldownQueryTimeframe : Maybe String
    , mappingStrategy : Maybe String
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



-- DECODERS


correlationsResponseDecoder : Decoder CorrelationsResponse
correlationsResponseDecoder =
    Decode.map3 CorrelationsResponse
        (Decode.maybe (Decode.field "objects_count" Decode.int))
        (Decode.oneOf
            [ Decode.field "objects" (Decode.list correlationDecoder)
            , Decode.succeed []
            ]
        )
        (Decode.maybe (Decode.field "objects_type" Decode.string))


correlationDecoder : Decoder Correlation
correlationDecoder =
    Decode.succeed Correlation
        |> andMap (optionalField "id" Decode.int)
        |> andMap (optionalField "name" Decode.string)
        |> andMap (optionalField "description" Decode.string)
        |> andMap (optionalField "severity" Decode.string)
        |> andMap (optionalField "is_enabled" Decode.string)
        |> andMap (optionalField "xql_query" Decode.string)
        |> andMap (optionalField "dataset" Decode.string)
        |> andMap (optionalField "execution_mode" Decode.string)
        |> andMap (optionalField "search_window" Decode.string)
        |> andMap (optionalField "simple_schedule" Decode.string)
        |> andMap (optionalField "crontab" Decode.string)
        |> andMap (optionalField "timezone" Decode.string)
        |> andMap (optionalField "suppression_enabled" Decode.bool)
        |> andMap (optionalField "suppression_duration" Decode.string)
        |> andMap (optionalList "suppression_fields" Decode.string)
        |> andMap (optionalField "alert_name" Decode.string)
        |> andMap (optionalField "alert_category" Decode.string)
        |> andMap (optionalField "alert_description" Decode.string)
        |> andMap (optionalField "alert_domain" Decode.string)
        |> andMap (optionalField "alert_fields" Decode.value)
        |> andMap (optionalField "user_defined_severity" Decode.string)
        |> andMap (optionalField "user_defined_category" Decode.string)
        |> andMap (optionalField "mitre_defs" Decode.value)
        |> andMap (optionalField "investigation_query_link" Decode.string)
        |> andMap (optionalField "drilldown_query_timeframe" Decode.string)
        |> andMap (optionalField "mapping_strategy" Decode.string)


optionalField : String -> Decoder a -> Decoder (Maybe a)
optionalField name d =
    Decode.maybe (Decode.field name d)
