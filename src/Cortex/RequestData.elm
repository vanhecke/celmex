module Cortex.RequestData exposing (Standard, empty, encode)

{-| Envelope builder for Cortex Advanced API endpoints that accept the
standard `filters` / `sort` / `search_from`/`search_to` / `timeframe` shape.

Endpoint modules take a typed args record, map it into a
[`Standard`](#Standard), and call [`encode`](#encode) — that single call
produces the full `{"request_data": {...}}` body. The `extra` field is an
escape hatch for endpoint-specific keys or new Cortex fields the SDK has not
modeled yet; its pairs are merged in last, so they override any SDK-generated
key on collision.

@docs Standard, empty, encode

-}

import Cortex.Query as Query exposing (Filter, Range, Sort, Timeframe)
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
`{"request_data": {}}`.
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
-}
encode : Standard -> Encode.Value
encode s =
    let
        filtersField =
            if List.isEmpty s.filters then
                []

            else
                [ ( "filters", Encode.list Query.encodeFilter s.filters ) ]

        sortField =
            case s.sort of
                Just sort ->
                    [ ( "sort", Query.encodeSort sort ) ]

                Nothing ->
                    []

        rangeFields =
            case s.range of
                Just r ->
                    Query.encodeRange r

                Nothing ->
                    []

        timeframeField =
            case s.timeframe of
                Just tf ->
                    [ ( "timeframe", Query.encodeTimeframe tf ) ]

                Nothing ->
                    []

        inner =
            filtersField ++ sortField ++ rangeFields ++ timeframeField ++ s.extra
    in
    Encode.object [ ( "request_data", Encode.object inner ) ]
