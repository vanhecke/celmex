module Cortex.Api.Correlations exposing
    ( SearchArgs, defaultSearchArgs
    , Correlation, CorrelationsResponse
    , get
    , InsertArgs, InsertResult, CorrelationChange, CorrelationError
    , insert
    , DeleteArgs, DeleteFilter, deleteFilter, DeleteResult
    , delete
    )

{-| Cortex correlation rules — XQL queries that produce alerts on a
schedule or in real time.

@docs SearchArgs, defaultSearchArgs
@docs Correlation, CorrelationsResponse
@docs get
@docs InsertArgs, InsertResult, CorrelationChange, CorrelationError
@docs insert
@docs DeleteArgs, DeleteFilter, deleteFilter, DeleteResult
@docs delete

-}

import Cortex.Decode exposing (andMap, optionalField, optionalList)
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

    {- Decoder escape: open-ended per spec; preserved as raw string.
       The spec declares `objects_type: type: string` with no enum.
    -}
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
        {- Decoder escape: per-rule field projection map; keys depend on the
           XQL query the rule emits and cannot be typed at the SDK layer.
        -}
        |> andMap (optionalField "alert_fields" Decode.value)
        |> andMap (optionalField "user_defined_severity" Decode.string)
        |> andMap (optionalField "user_defined_category" Decode.string)
        {- Decoder escape: free-form MITRE definitions map; keys are
           tactic/technique IDs whose values are tenant-defined.
        -}
        |> andMap (optionalField "mitre_defs" Decode.value)
        |> andMap (optionalField "investigation_query_link" Decode.string)
        |> andMap (optionalField "drilldown_query_timeframe" Decode.string)
        |> andMap (optionalField "mapping_strategy" Decode.string)



-- INSERT


{-| Arguments to [`insert`](#insert). `items` is the raw `request_data` array
of correlation-rule objects. The live API requires a much larger field set
than the published OpenAPI spec marks as optional (every scheduling /
suppression / MITRE field plus a few undocumented ones), so the SDK does
not type the item shape — callers supply the JSON they want sent. Pass an
existing `rule_id` on an item to upsert that rule instead of inserting a
new one.
-}
type alias InsertArgs =
    { items : Encode.Value
    }


{-| Outcome of an [`insert`](#insert) call. `addedObjects` lists the newly
created rule IDs and the server's status string for each; `updatedObjects`
lists upserts; `errors` collects per-item failures the server flagged
without aborting the batch.
-}
type alias InsertResult =
    { addedObjects : List CorrelationChange
    , updatedObjects : List CorrelationChange
    , errors : List CorrelationError
    }


{-| One row in the [`InsertResult`](#InsertResult) `addedObjects` /
`updatedObjects` arrays — the rule ID the server assigned and the matching
human-readable status it returned.
-}
type alias CorrelationChange =
    { id : Int
    , status : String
    }


{-| One row in the [`InsertResult`](#InsertResult) `errors` array — the
zero-based index of the offending item in the request and the server's
human-readable rejection reason.
-}
type alias CorrelationError =
    { index : Int
    , status : String
    }


{-| POST /public\_api/v1/correlations/insert — insert or upsert a batch of
correlation rules. The response carries the rule IDs of every rule the
server touched, which a test can use to delete what it inserted.
-}
insert : InsertArgs -> Request InsertResult
insert args =
    Request.post
        [ "public_api", "v1", "correlations", "insert" ]
        (Encode.object [ ( "request_data", args.items ) ])
        insertResultDecoder



-- DELETE


{-| Arguments to [`delete`](#delete). `filters` is AND-ed server-side; pass
multiple entries to narrow the match further. Build entries via
[`deleteFilter`](#deleteFilter) so the wire shape stays an SDK detail.
-}
type alias DeleteArgs =
    { filters : List DeleteFilter
    }


{-| One `{field, operator, value}` predicate accepted by
`correlations/delete`. The delete endpoint accepts the operator set
(`EQ`, `IN`, `GTE`, `LTE`) over a closed field set including `name`,
`severity`, `xql_query`, `is_enabled`, and the alert / scheduling /
suppression keys; the SDK does not validate either — the server will
reject invalid combinations.
-}
type DeleteFilter
    = DeleteFilter { field : String, operator : String, value : Encode.Value }


{-| Build a [`DeleteFilter`](#DeleteFilter) from the raw triple. The
`operator` should already be one of the API's uppercase keywords (`EQ`,
`IN`, `GTE`, `LTE`); the encoder writes it through verbatim.
-}
deleteFilter : { field : String, operator : String, value : Encode.Value } -> DeleteFilter
deleteFilter =
    DeleteFilter


{-| Outcome of a [`delete`](#delete) call. `objectsCount` is the number of
rules the server removed; `objects` is the list of rule IDs it removed.
-}
type alias DeleteResult =
    { objectsCount : Int
    , objects : List Int
    }


{-| POST /public\_api/v1/correlations/delete — remove every correlation
rule matching the filters.
-}
delete : DeleteArgs -> Request DeleteResult
delete args =
    Request.post
        [ "public_api", "v1", "correlations", "delete" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object
                    [ ( "filters", Encode.list encodeDeleteFilter args.filters ) ]
              )
            ]
        )
        deleteResultDecoder


insertResultDecoder : Decoder InsertResult
insertResultDecoder =
    Decode.map3 InsertResult
        (optionalList "added_objects" correlationChangeDecoder)
        (optionalList "updated_objects" correlationChangeDecoder)
        (optionalList "errors" correlationErrorDecoder)


correlationChangeDecoder : Decoder CorrelationChange
correlationChangeDecoder =
    Decode.map2 CorrelationChange
        (Decode.field "id" Decode.int)
        (Decode.field "status" Decode.string)


correlationErrorDecoder : Decoder CorrelationError
correlationErrorDecoder =
    Decode.map2 CorrelationError
        (Decode.field "index" Decode.int)
        (Decode.field "status" Decode.string)


deleteResultDecoder : Decoder DeleteResult
deleteResultDecoder =
    Decode.map2 DeleteResult
        (Decode.oneOf [ Decode.field "objects_count" Decode.int, Decode.succeed 0 ])
        (Decode.oneOf [ Decode.field "objects" (Decode.list Decode.int), Decode.succeed [] ])


encodeDeleteFilter : DeleteFilter -> Encode.Value
encodeDeleteFilter (DeleteFilter f) =
    Encode.object
        [ ( "field", Encode.string f.field )
        , ( "operator", Encode.string f.operator )
        , ( "value", f.value )
        ]
