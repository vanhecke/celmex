module Cortex.Query exposing
    ( Filter, eq, neq, in_, nin, contains, gt, gte, lt, lte, custom
    , Sort, asc, desc
    , Range, range, limit, offset
    , Timeframe, relative, between
    , Dialect, standard, assetInventory
    , encodeFilter, encodeSort, encodeRange, encodeTimeframe
    )

{-| Shared request-body building blocks used by Cortex list/search endpoints.

Most Advanced API endpoints accept a common set of fields inside
`request_data` — `filters`, `sort`, `search_from`/`search_to`, and a
`timeframe`. This module defines the opaque value types for those fields and
the constructors / encoders that build them. Endpoint modules combine these
into a [`Cortex.RequestData.Standard`](Cortex-RequestData#Standard) envelope
and hand it to [`Cortex.Request.post`](Cortex-Request#post).

Values are opaque so the wire format (operator keywords, `keyword: asc|desc`,
epoch-ms time windows) stays an implementation detail that can shift without
breaking callers.

A small number of endpoints — most notably the asset-inventory `POST
/public_api/v1/assets` and the cloud-API list endpoints — use a different
wire shape (`{SEARCH_FIELD, SEARCH_TYPE, SEARCH_VALUE}` with uppercase
operators, sort wrapped in an array, etc.). [`Dialect`](#Dialect) selects
which shape the encoders emit; endpoint modules pick the right value at the
call site.

@docs Filter, eq, neq, in_, nin, contains, gt, gte, lt, lte, custom
@docs Sort, asc, desc
@docs Range, range, limit, offset
@docs Timeframe, relative, between
@docs Dialect, standard, assetInventory
@docs encodeFilter, encodeSort, encodeRange, encodeTimeframe

-}

import Json.Encode as Encode



-- FILTER


{-| A single `{field, operator, value}` filter entry. Multiple filters sent on
one request are AND-ed together by the server.
-}
type Filter
    = Filter { field : String, operator : String, value : Encode.Value }


{-| Equality filter — `field == value`.
-}
eq : String -> String -> Filter
eq field value =
    Filter { field = field, operator = "eq", value = Encode.string value }


{-| Inequality filter — `field /= value`.
-}
neq : String -> String -> Filter
neq field value =
    Filter { field = field, operator = "neq", value = Encode.string value }


{-| Membership filter — `field` is one of the given values. Named with a
trailing underscore because `in` is a reserved word in Elm.
-}
in_ : String -> List String -> Filter
in_ field values =
    Filter { field = field, operator = "in", value = Encode.list Encode.string values }


{-| Non-membership filter — `field` is none of the given values.
-}
nin : String -> List String -> Filter
nin field values =
    Filter { field = field, operator = "nin", value = Encode.list Encode.string values }


{-| Substring filter — `field` contains `value`.
-}
contains : String -> String -> Filter
contains field value =
    Filter { field = field, operator = "contains", value = Encode.string value }


{-| Greater-than filter.
-}
gt : String -> Int -> Filter
gt field value =
    Filter { field = field, operator = "gt", value = Encode.int value }


{-| Greater-than-or-equal filter.
-}
gte : String -> Int -> Filter
gte field value =
    Filter { field = field, operator = "gte", value = Encode.int value }


{-| Less-than filter.
-}
lt : String -> Int -> Filter
lt field value =
    Filter { field = field, operator = "lt", value = Encode.int value }


{-| Less-than-or-equal filter.
-}
lte : String -> Int -> Filter
lte field value =
    Filter { field = field, operator = "lte", value = Encode.int value }


{-| Escape hatch for operators the SDK has not catalogued yet. The `operator`
string is passed through to the wire as-is, and `value` can be any JSON.
-}
custom : String -> String -> Encode.Value -> Filter
custom field operator value =
    Filter { field = field, operator = operator, value = value }


{-| Encode a [`Filter`](#Filter) in the given [`Dialect`](#Dialect)'s wire
representation. The Standard dialect emits `{field, operator, value}` with
lowercase operators; the AssetInventory dialect emits `{SEARCH_FIELD,
SEARCH_TYPE, SEARCH_VALUE}` with uppercase operators.
-}
encodeFilter : Dialect -> Filter -> Encode.Value
encodeFilter dialect (Filter f) =
    case dialect of
        Standard ->
            Encode.object
                [ ( "field", Encode.string f.field )
                , ( "operator", Encode.string f.operator )
                , ( "value", f.value )
                ]

        AssetInventory ->
            Encode.object
                [ ( "SEARCH_FIELD", Encode.string f.field )
                , ( "SEARCH_TYPE", Encode.string (String.toUpper f.operator) )
                , ( "SEARCH_VALUE", f.value )
                ]



-- SORT


{-| Sort directive — a field name and direction keyword.
-}
type Sort
    = Sort { field : String, keyword : String }


{-| Ascending sort on the given field.
-}
asc : String -> Sort
asc field =
    Sort { field = field, keyword = "asc" }


{-| Descending sort on the given field.
-}
desc : String -> Sort
desc field =
    Sort { field = field, keyword = "desc" }


{-| Encode a [`Sort`](#Sort) in the given [`Dialect`](#Dialect)'s wire
representation. The Standard dialect emits `{field, keyword: "asc"|"desc"}`;
the AssetInventory dialect emits `{FIELD, ORDER: "ASC"|"DESC"}` (the
enclosing array wrapping is applied by [`Cortex.RequestData.encode`](Cortex-RequestData#encode)).
-}
encodeSort : Dialect -> Sort -> Encode.Value
encodeSort dialect (Sort s) =
    case dialect of
        Standard ->
            Encode.object
                [ ( "field", Encode.string s.field )
                , ( "keyword", Encode.string s.keyword )
                ]

        AssetInventory ->
            Encode.object
                [ ( "FIELD", Encode.string s.field )
                , ( "ORDER", Encode.string (String.toUpper s.keyword) )
                ]



-- RANGE


{-| Pagination window over the result set. The server reads this as
`search_from` / `search_to` row indices (0-based, exclusive on the upper
bound).
-}
type Range
    = Range { from : Int, to : Int }


{-| Rows in `[from, to)`. Use [`limit`](#limit) for the common case of "first
N rows".
-}
range : Int -> Int -> Range
range from to =
    Range { from = from, to = to }


{-| First `n` rows — sugar for `range 0 n`.
-}
limit : Int -> Range
limit n =
    Range { from = 0, to = n }


{-| `n` rows starting at `start`.
-}
offset : Int -> Int -> Range
offset start n =
    Range { from = start, to = start + n }


{-| Encode a [`Range`](#Range) as the two-field `{search_from, search_to}`
pair expected inside `request_data`. Returned as a list so callers can splice
it into the enclosing object.
-}
encodeRange : Range -> List ( String, Encode.Value )
encodeRange (Range r) =
    [ ( "search_from", Encode.int r.from )
    , ( "search_to", Encode.int r.to )
    ]



-- TIMEFRAME


{-| Time window for list/search queries. [`relative`](#relative) is a
duration in epoch-milliseconds measured backward from "now"; [`between`](#between)
is an absolute `from`/`to` epoch-millisecond window.
-}
type Timeframe
    = RelativeMs Int
    | BetweenMs { from : Int, to : Int }


{-| Last `n` milliseconds — e.g. `relative 86400000` is the last 24 hours.
-}
relative : Int -> Timeframe
relative ms =
    RelativeMs ms


{-| Absolute window — inclusive epoch-millisecond bounds.
-}
between : Int -> Int -> Timeframe
between from to =
    BetweenMs { from = from, to = to }


{-| Encode a [`Timeframe`](#Timeframe) to its wire representation.
-}
encodeTimeframe : Timeframe -> Encode.Value
encodeTimeframe tf =
    case tf of
        RelativeMs ms ->
            Encode.object [ ( "relativeTime", Encode.int ms ) ]

        BetweenMs r ->
            Encode.object
                [ ( "from", Encode.int r.from )
                , ( "to", Encode.int r.to )
                ]



-- DIALECT


{-| Selects which `request_data` wire shape the encoders emit. Pick one with
[`standard`](#standard) (the default for almost every Cortex endpoint) or
[`assetInventory`](#assetInventory) (the `POST /public_api/v1/assets`
inventory endpoint and the cloud-API list endpoints, which use uppercase
`SEARCH_FIELD`/`SEARCH_TYPE`/`SEARCH_VALUE` filters and a sort array).
-}
type Dialect
    = Standard
    | AssetInventory


{-| The default dialect used by most Cortex Advanced API list/search
endpoints — `{field, operator, value}` filters and `{field, keyword}` sort.
-}
standard : Dialect
standard =
    Standard


{-| The asset-inventory dialect — `{SEARCH_FIELD, SEARCH_TYPE, SEARCH_VALUE}`
filters wrapped in `{AND: [...]}` and sort wrapped in a one-element array.
Timeframes are not supported by this dialect and are dropped silently.
-}
assetInventory : Dialect
assetInventory =
    AssetInventory
