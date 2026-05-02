module Cortex.Api.Indicators exposing
    ( SearchArgs, defaultSearchArgs
    , Indicator, IndicatorsResponse
    , get
    , InsertArgs, InsertResult, IndicatorChange, IndicatorError
    , insert
    , DeleteArgs, DeleteFilter, deleteFilter, DeleteResult
    , delete
    )

{-| Cortex threat intelligence indicators (IOCs).

@docs SearchArgs, defaultSearchArgs
@docs Indicator, IndicatorsResponse
@docs get
@docs InsertArgs, InsertResult, IndicatorChange, IndicatorError
@docs insert
@docs DeleteArgs, DeleteFilter, deleteFilter, DeleteResult
@docs delete

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
collision — e.g. the indicator endpoint's `extended_view` flag is reachable
through it.
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


{-| Envelope returned by [`get`](#get). Not wrapped in the standard `reply`.
-}
type alias IndicatorsResponse =
    { objectsCount : Maybe Int
    , objects : List Indicator
    , objectsType : Maybe String
    }


{-| A single threat-intelligence indicator (hash, domain, URL, IP, etc.).
-}
type alias Indicator =
    { ruleId : Maybe Int
    , indicator : Maybe String
    , type_ : Maybe String
    , severity : Maybe String
    , expirationDate : Maybe Int
    , defaultExpirationEnabled : Maybe Bool
    , comment : Maybe String

    {- reputation carries a per-source reputation map whose keys are
       arbitrary feed names (VirusTotal, Cortex Threat Intel, custom
       sources, etc.) and values are source-specific score objects.
       Genuinely free-form per tenant configuration; preserved verbatim.
    -}
    , reputation : Encode.Value

    {- reliability is a per-source reliability rating object with the
       same per-source-arbitrary-key shape as reputation. Same rationale.
    -}
    , reliability : Encode.Value
    }


{-| POST /public\_api/v1/indicators/get

Response is top-level `{objects_count, objects, objects_type}` — NOT wrapped
in the usual `reply` envelope.

-}
get : SearchArgs -> Request IndicatorsResponse
get args =
    Request.post
        [ "public_api", "v1", "indicators", "get" ]
        (RequestData.encode Query.standard
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        indicatorsResponseDecoder


indicatorsResponseDecoder : Decoder IndicatorsResponse
indicatorsResponseDecoder =
    Decode.map3 IndicatorsResponse
        (Decode.maybe (Decode.field "objects_count" Decode.int))
        (Decode.oneOf
            [ Decode.field "objects" (Decode.list indicatorDecoder)
            , Decode.succeed []
            ]
        )
        (Decode.maybe (Decode.field "objects_type" Decode.string))


indicatorDecoder : Decoder Indicator
indicatorDecoder =
    Decode.map8 Indicator
        (Decode.maybe (Decode.field "rule_id" Decode.int))
        (Decode.maybe (Decode.field "indicator" Decode.string))
        (Decode.maybe (Decode.field "type" Decode.string))
        (Decode.maybe (Decode.field "severity" Decode.string))
        (Decode.maybe (Decode.field "expiration_date" Decode.int))
        (Decode.maybe (Decode.field "default_expiration_enabled" Decode.bool))
        (Decode.maybe (Decode.field "comment" Decode.string))
        {- Decoder escape: polymorphic field — server returns either a
           string label or an object with sub-fields depending on the
           indicator type. Preserved verbatim.
        -}
        (Decode.oneOf
            [ Decode.field "reputation" Decode.value
            , Decode.succeed Encode.null
            ]
        )
        {- Decoder escape: polymorphic field — server returns either a
           string label or an object with sub-fields depending on the
           indicator type. Preserved verbatim.
        -}
        |> andMap
            (Decode.oneOf
                [ Decode.field "reliability" Decode.value
                , Decode.succeed Encode.null
                ]
            )



-- INSERT


{-| Arguments to [`insert`](#insert). `items` is the raw `request_data` array
of indicator objects — each entry must include at least `indicator`, `type`,
`severity`, and `comment`. The optional `reputation` / `reliability` fields
are polymorphic per source (see [`Indicator`](#Indicator)) so the SDK does
not type them ahead of time; callers build the JSON shape themselves and
pass it through. Pass an existing `rule_id` on an item to upsert that IOC
instead of inserting a new one.
-}
type alias InsertArgs =
    { items : Encode.Value
    }


{-| Outcome of an [`insert`](#insert) call. `addedObjects` lists the newly
created IOC IDs and the server's status string for each; `updatedObjects`
lists upserts; `errors` collects per-item failures the server flagged
without aborting the batch.
-}
type alias InsertResult =
    { addedObjects : List IndicatorChange
    , updatedObjects : List IndicatorChange
    , errors : List IndicatorError
    }


{-| One row in the [`InsertResult`](#InsertResult) `addedObjects` /
`updatedObjects` arrays — the rule ID the server assigned and the matching
human-readable status it returned.
-}
type alias IndicatorChange =
    { id : Int
    , status : String
    }


{-| One row in the [`InsertResult`](#InsertResult) `errors` array — the
zero-based index of the offending item in the request and the server's
human-readable rejection reason.
-}
type alias IndicatorError =
    { index : Int
    , status : String
    }


{-| POST /public\_api/v1/indicators/insert — insert or upsert a batch of
IOCs. The response carries the rule IDs of every IOC the server touched,
which a test can use to delete what it inserted.
-}
insert : InsertArgs -> Request InsertResult
insert args =
    Request.post
        [ "public_api", "v1", "indicators", "insert" ]
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


{-| One `{field, operator, value}` predicate accepted by `indicators/delete`.
The delete endpoint accepts only a constrained operator set (`EQ`, `NEQ`,
`IN`, `GTE`, `LTE`) and a closed field set (`indicator`, `type`, `severity`,
`expiration_date`, `default_expiration_enabled`, `comment`, `reputation`,
`reliability`); the SDK does not validate either — the server will reject
invalid combinations.
-}
type DeleteFilter
    = DeleteFilter { field : String, operator : String, value : Encode.Value }


{-| Build a [`DeleteFilter`](#DeleteFilter) from the raw triple. The
`operator` should already be one of the API's uppercase keywords (`EQ`,
`NEQ`, `IN`, `GTE`, `LTE`); the encoder writes it through verbatim.
-}
deleteFilter : { field : String, operator : String, value : Encode.Value } -> DeleteFilter
deleteFilter =
    DeleteFilter


{-| Outcome of a [`delete`](#delete) call. `objectsCount` is the number of
IOCs the server removed; `objects` is the list of rule IDs it removed.
-}
type alias DeleteResult =
    { objectsCount : Int
    , objects : List Int
    }


{-| POST /public\_api/v1/indicators/delete — remove every IOC matching the
filters.
-}
delete : DeleteArgs -> Request DeleteResult
delete args =
    Request.post
        [ "public_api", "v1", "indicators", "delete" ]
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
        (optionalList "added_objects" indicatorChangeDecoder)
        (optionalList "updated_objects" indicatorChangeDecoder)
        (optionalList "errors" indicatorErrorDecoder)


indicatorChangeDecoder : Decoder IndicatorChange
indicatorChangeDecoder =
    Decode.map2 IndicatorChange
        (Decode.field "id" Decode.int)
        (Decode.field "status" Decode.string)


indicatorErrorDecoder : Decoder IndicatorError
indicatorErrorDecoder =
    Decode.map2 IndicatorError
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
