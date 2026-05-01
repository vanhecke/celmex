module Cli.StandardFlags exposing (StandardArgs, empty, parse)

{-| Canonical CLI flag surface for Cortex list/search commands.

Every command that accepts the standard `filters` / `sort` /
`search_from`/`search_to` / `timeframe` envelope shares the flag set parsed
here. Command handlers call `parse` on the `( String, Maybe String )` list
produced by `Cli.Commands.splitArgs` and map the resulting `StandardArgs`
onto the endpoint-specific args record.

Recognised flags:

  - `--filter field=op=value` (repeatable) — `op` ∈
    `eq,neq,in,nin,contains,gt,gte,lt,lte`; for `in`/`nin` the `value` is
    comma-split into a list.
  - `--sort field:asc|desc`
  - `--limit N` — first N rows; mutually exclusive with `--range`
  - `--offset N` — with `--limit`, returns rows `[offset, offset+limit)`
  - `--range a:b` — rows `[a, b)` directly
  - `--from EPOCH_MS` / `--to EPOCH_MS` — absolute timeframe (both required
    together)
  - `--relative EPOCH_MS_DURATION` — relative timeframe; mutually exclusive
    with `--from`/`--to`
  - `--extra key=JSON` (repeatable) — escape hatch: RHS parsed as arbitrary
    JSON and merged into `request_data`

-}

import Cortex.Query as Query exposing (Filter, Range, Sort, Timeframe)
import Json.Decode as Decode
import Json.Encode as Encode


type alias StandardArgs =
    { filters : List Filter
    , sort : Maybe Sort
    , range : Maybe Range
    , timeframe : Maybe Timeframe
    , extra : List ( String, Encode.Value )
    }


empty : StandardArgs
empty =
    { filters = []
    , sort = Nothing
    , range = Nothing
    , timeframe = Nothing
    , extra = []
    }


parse : List ( String, Maybe String ) -> Result String StandardArgs
parse flags =
    Result.map5 StandardArgs
        (parseFilters flags)
        (parseSort flags)
        (parseRange flags)
        (parseTimeframe flags)
        (parseExtras flags)



-- FILTERS


parseFilters : List ( String, Maybe String ) -> Result String (List Filter)
parseFilters flags =
    allFlagValues "--filter" flags
        |> List.map parseOneFilter
        |> sequenceResults


parseOneFilter : String -> Result String Filter
parseOneFilter raw =
    case splitN 3 "=" raw of
        [ field, op, value ] ->
            if String.isEmpty field then
                Err ("--filter: empty field in '" ++ raw ++ "'")

            else
                buildFilter field op value

        _ ->
            Err ("--filter: expected 'field=op=value', got '" ++ raw ++ "'")


buildFilter : String -> String -> String -> Result String Filter
buildFilter field op value =
    case op of
        "eq" ->
            Ok (Query.eq field value)

        "neq" ->
            Ok (Query.neq field value)

        "in" ->
            Ok (Query.in_ field (commaSplit value))

        "nin" ->
            Ok (Query.nin field (commaSplit value))

        "contains" ->
            Ok (Query.contains field value)

        "gt" ->
            parseIntOp "--filter gt" value |> Result.map (Query.gt field)

        "gte" ->
            parseIntOp "--filter gte" value |> Result.map (Query.gte field)

        "lt" ->
            parseIntOp "--filter lt" value |> Result.map (Query.lt field)

        "lte" ->
            parseIntOp "--filter lte" value |> Result.map (Query.lte field)

        _ ->
            Err
                ("--filter: unknown operator '"
                    ++ op
                    ++ "' (expected eq|neq|in|nin|contains|gt|gte|lt|lte)"
                )


parseIntOp : String -> String -> Result String Int
parseIntOp context value =
    case String.toInt value of
        Just n ->
            Ok n

        Nothing ->
            Err (context ++ ": expected integer, got '" ++ value ++ "'")


commaSplit : String -> List String
commaSplit s =
    String.split "," s
        |> List.map String.trim
        |> List.filter (not << String.isEmpty)



-- SORT


parseSort : List ( String, Maybe String ) -> Result String (Maybe Sort)
parseSort flags =
    case flagValue "--sort" flags of
        Nothing ->
            Ok Nothing

        Just raw ->
            case String.split ":" raw of
                [ field, "asc" ] ->
                    Ok (Just (Query.asc field))

                [ field, "desc" ] ->
                    Ok (Just (Query.desc field))

                _ ->
                    Err ("--sort: expected 'field:asc' or 'field:desc', got '" ++ raw ++ "'")



-- RANGE


parseRange : List ( String, Maybe String ) -> Result String (Maybe Range)
parseRange flags =
    let
        rangeFlag =
            flagValue "--range" flags

        limitFlag =
            flagValue "--limit" flags

        offsetFlag =
            flagValue "--offset" flags
    in
    case ( rangeFlag, limitFlag, offsetFlag ) of
        ( Nothing, Nothing, Nothing ) ->
            Ok Nothing

        ( Just raw, Nothing, Nothing ) ->
            parseRangePair raw |> Result.map Just

        ( Nothing, Just l, Nothing ) ->
            parseIntOp "--limit" l
                |> Result.map (\n -> Just (Query.limit n))

        ( Nothing, Just l, Just o ) ->
            Result.map2
                (\limit_ off -> Just (Query.offset off limit_))
                (parseIntOp "--limit" l)
                (parseIntOp "--offset" o)

        ( Nothing, Nothing, Just _ ) ->
            Err "--offset: requires --limit"

        ( Just _, _, _ ) ->
            Err "--range is mutually exclusive with --limit/--offset"


parseRangePair : String -> Result String Range
parseRangePair raw =
    case String.split ":" raw of
        [ a, b ] ->
            Result.map2 Query.range
                (parseIntOp "--range (from)" a)
                (parseIntOp "--range (to)" b)

        _ ->
            Err ("--range: expected 'from:to', got '" ++ raw ++ "'")



-- TIMEFRAME


parseTimeframe : List ( String, Maybe String ) -> Result String (Maybe Timeframe)
parseTimeframe flags =
    let
        rel =
            flagValue "--relative" flags

        from_ =
            flagValue "--from" flags

        to_ =
            flagValue "--to" flags
    in
    case ( rel, from_, to_ ) of
        ( Nothing, Nothing, Nothing ) ->
            Ok Nothing

        ( Just r, Nothing, Nothing ) ->
            parseIntOp "--relative" r
                |> Result.map (\ms -> Just (Query.relative ms))

        ( Nothing, Just f, Just t ) ->
            Result.map2
                (\from to -> Just (Query.between from to))
                (parseIntOp "--from" f)
                (parseIntOp "--to" t)

        ( Nothing, Just _, Nothing ) ->
            Err "--from: requires --to"

        ( Nothing, Nothing, Just _ ) ->
            Err "--to: requires --from"

        _ ->
            Err "--relative is mutually exclusive with --from/--to"



-- EXTRAS


parseExtras : List ( String, Maybe String ) -> Result String (List ( String, Encode.Value ))
parseExtras flags =
    allFlagValues "--extra" flags
        |> List.map parseOneExtra
        |> sequenceResults


parseOneExtra : String -> Result String ( String, Encode.Value )
parseOneExtra raw =
    case String.indexes "=" raw of
        [] ->
            Err ("--extra: expected 'key=JSON', got '" ++ raw ++ "'")

        i :: _ ->
            let
                key =
                    String.slice 0 i raw
            in
            if String.isEmpty key then
                Err ("--extra: empty key in '" ++ raw ++ "'")

            else
                let
                    jsonStr =
                        String.dropLeft (i + 1) raw
                in
                case Decode.decodeString Decode.value jsonStr of
                    Ok v ->
                        Ok ( key, v )

                    Err e ->
                        Err
                            ("--extra '"
                                ++ key
                                ++ "': invalid JSON value '"
                                ++ jsonStr
                                ++ "' — "
                                ++ Decode.errorToString e
                            )



-- HELPERS (duplicated from Cli.Commands to avoid a circular import)


flagValue : String -> List ( String, Maybe String ) -> Maybe String
flagValue name flags =
    flags
        |> List.filterMap
            (\( n, v ) ->
                if n == name then
                    v

                else
                    Nothing
            )
        |> List.head


allFlagValues : String -> List ( String, Maybe String ) -> List String
allFlagValues name flags =
    List.filterMap
        (\( n, v ) ->
            if n == name then
                v

            else
                Nothing
        )
        flags


{-| Split a string on `sep` into at most `n` parts (keeping the final part
raw). Used for `--filter field=op=value` where the value itself may contain
`=`.
-}
splitN : Int -> String -> String -> List String
splitN n sep s =
    if n <= 1 then
        [ s ]

    else
        case String.indexes sep s of
            [] ->
                [ s ]

            i :: _ ->
                String.slice 0 i s
                    :: splitN (n - 1) sep (String.dropLeft (i + String.length sep) s)


sequenceResults : List (Result e a) -> Result e (List a)
sequenceResults =
    List.foldr (\r acc -> Result.map2 (::) r acc) (Ok [])
