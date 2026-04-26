module Cortex.RequestData exposing (Standard, empty, encode)

{-| Envelope builder for Cortex Advanced API endpoints that accept the
standard `filters` / `sort` / `search_from`/`search_to` / `timeframe` shape.

Endpoint modules take a typed args record, map it into a
[`Standard`](#Standard), and call [`encode`](#encode) with the appropriate
[`Cortex.Query.Dialect`](Cortex-Query#Dialect) — that single call produces
the full `{"request_data": {...}}` body. The `extra` field is an escape
hatch for endpoint-specific keys or new Cortex fields the SDK has not
modeled yet; its pairs are merged in last, so they override any
SDK-generated key on collision.

@docs Standard, empty, encode

-}

import Cortex.Query as Query exposing (Dialect, Filter, Range, Sort, Timeframe)
import Json.Encode as Encode


{-| The standard inner shape of `request_data`. Every field is optional at
the wire level — omitted `Maybe`s and the empty `filters`/`extra` lists drop
out of the encoded body.
-}
type alias Standard =
    { filters : List Filter
    , sort : Maybe Sort
    , range : Maybe Range
    , timeframe : Maybe Timeframe
    , extra : List ( String, Encode.Value )
    }


{-| A [`Standard`](#Standard) with no fields set — encodes to
`{"request_data": {}}` regardless of dialect.
-}
empty : Standard
empty =
    { filters = []
    , sort = Nothing
    , range = Nothing
    , timeframe = Nothing
    , extra = []
    }


{-| Encode a [`Standard`](#Standard) as the `{"request_data": {...}}`
envelope ready to hand to [`Cortex.Request.post`](Cortex-Request#post).

The [`Dialect`](Cortex-Query#Dialect) controls the wire shape of `filters`
and `sort` and which fields are emitted: the
[`Cortex.Query.standard`](Cortex-Query#standard) dialect emits flat
`{field, operator, value}` filters, a single `{field, keyword}` sort
object, and the optional `timeframe`; the
[`Cortex.Query.assetInventory`](Cortex-Query#assetInventory) dialect wraps
filters in `{AND: [...]}` with uppercase `SEARCH_FIELD`/`SEARCH_TYPE`/
`SEARCH_VALUE` keys, wraps sort in a one-element array of `{FIELD, ORDER}`,
and drops `timeframe` (the asset-inventory endpoint does not accept it).

`range` and `extra` behave identically across dialects.

-}
encode : Dialect -> Standard -> Encode.Value
encode dialect s =
    let
        rangeFields =
            case s.range of
                Just r ->
                    Query.encodeRange r

                Nothing ->
                    []

        inner =
            filtersField dialect s.filters
                ++ sortField dialect s.sort
                ++ rangeFields
                ++ timeframeField dialect s.timeframe
                ++ s.extra
    in
    Encode.object [ ( "request_data", Encode.object inner ) ]


filtersField : Dialect -> List Filter -> List ( String, Encode.Value )
filtersField dialect filters =
    if List.isEmpty filters then
        []

    else if dialect == Query.assetInventory then
        [ ( "filters"
          , Encode.object
                [ ( "AND", Encode.list (Query.encodeFilter dialect) filters ) ]
          )
        ]

    else
        [ ( "filters", Encode.list (Query.encodeFilter dialect) filters ) ]


sortField : Dialect -> Maybe Sort -> List ( String, Encode.Value )
sortField dialect maybeSort =
    case maybeSort of
        Nothing ->
            []

        Just sort ->
            if dialect == Query.assetInventory then
                [ ( "sort", Encode.list (Query.encodeSort dialect) [ sort ] ) ]

            else
                [ ( "sort", Query.encodeSort dialect sort ) ]


timeframeField : Dialect -> Maybe Timeframe -> List ( String, Encode.Value )
timeframeField dialect maybeTf =
    case maybeTf of
        Nothing ->
            []

        Just tf ->
            if dialect == Query.assetInventory then
                []

            else
                [ ( "timeframe", Query.encodeTimeframe tf ) ]
