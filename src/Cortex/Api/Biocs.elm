module Cortex.Api.Biocs exposing
    ( SearchArgs, defaultSearchArgs
    , Bioc, BiocsResponse
    , list
    , InsertArgs, InsertResult, BiocChange
    , insert
    , DeleteArgs, DeleteFilter, deleteFilter, DeleteResult
    , delete
    )

{-| Cortex behavioral indicators of compromise (BIOCs).

@docs SearchArgs, defaultSearchArgs
@docs Bioc, BiocsResponse
@docs list
@docs InsertArgs, InsertResult, BiocChange
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


{-| Arguments to [`list`](#list). All fields are optional; pass
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


{-| Top-level envelope returned by [`list`](#list). Not wrapped in the
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
list : SearchArgs -> Request BiocsResponse
list args =
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



-- INSERT


{-| Arguments to [`insert`](#insert). `items` is the raw `request_data` array
of BIOC objects — each entry must include at least `name`, `type`, `severity`,
`status`, `is_xql`, and `indicator`. The `indicator` field is the deeply
nested investigation-rule DSL (see [`Bioc`](#Bioc)) so the SDK does not type
it ahead of time; callers build the JSON shape themselves and pass it through.
Pass an existing `rule_id` on an item to upsert that BIOC instead of
inserting a new one.
-}
type alias InsertArgs =
    { items : Encode.Value
    }


{-| Outcome of an [`insert`](#insert) call. `addedObjects` lists the newly
created BIOC IDs and the server's status string for each; `updatedObjects`
lists upserts; `errors` collects per-item failures the server flagged
without aborting the batch.
-}
type alias InsertResult =
    { addedObjects : List BiocChange
    , updatedObjects : List BiocChange
    , errors : List String
    }


{-| One row in the [`InsertResult`](#InsertResult) `addedObjects` /
`updatedObjects` arrays — the rule ID the server assigned and the matching
human-readable status it returned.
-}
type alias BiocChange =
    { id : Int
    , status : String
    }


{-| POST /public\_api/v1/bioc/insert — insert or upsert a batch of BIOCs.
The response carries the rule IDs of every BIOC the server touched, which a
test can use to delete what it inserted.
-}
insert : InsertArgs -> Request InsertResult
insert args =
    Request.post
        [ "public_api", "v1", "bioc", "insert" ]
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


{-| One `{field, operator, value}` predicate accepted by `bioc/delete`. The
delete endpoint accepts only a constrained operator set (`EQ`, `NEQ`, `IN`,
`GTE`, `LTE`) and a closed field set (`name`, `severity`, `type`, `is_xql`,
`comment`, `status`, `indicator`, `mitre_*`); the SDK does not validate
either — the server will reject invalid combinations.
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
BIOCs the server removed; `objects` is the list of rule IDs it removed.
-}
type alias DeleteResult =
    { objectsCount : Int
    , objects : List Int
    }


{-| POST /public\_api/v1/bioc/delete — remove every BIOC matching the
filters.
-}
delete : DeleteArgs -> Request DeleteResult
delete args =
    Request.post
        [ "public_api", "v1", "bioc", "delete" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object
                    [ ( "filters", Encode.list encodeDeleteFilter args.filters ) ]
              )
            ]
        )
        deleteResultDecoder



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
        {- Decoder escape: tenant-defined indicator object; shape depends
           on the BIOC rule type (XQL/process/network/...) and is opaque.
        -}
        |> andMap (optionalField "indicator" Decode.value)


insertResultDecoder : Decoder InsertResult
insertResultDecoder =
    Decode.map3 InsertResult
        (optionalList "added_objects" biocChangeDecoder)
        (optionalList "updated_objects" biocChangeDecoder)
        (optionalList "errors" Decode.string)


biocChangeDecoder : Decoder BiocChange
biocChangeDecoder =
    Decode.map2 BiocChange
        (Decode.field "id" Decode.int)
        (Decode.field "status" Decode.string)


deleteResultDecoder : Decoder DeleteResult
deleteResultDecoder =
    Decode.map2 DeleteResult
        (Decode.oneOf [ Decode.field "objects_count" Decode.int, Decode.succeed 0 ])
        (Decode.oneOf [ Decode.field "objects" (Decode.list Decode.int), Decode.succeed [] ])



-- ENCODERS


encodeDeleteFilter : DeleteFilter -> Encode.Value
encodeDeleteFilter (DeleteFilter f) =
    Encode.object
        [ ( "field", Encode.string f.field )
        , ( "operator", Encode.string f.operator )
        , ( "value", f.value )
        ]
