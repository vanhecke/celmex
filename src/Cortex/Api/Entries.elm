module Cortex.Api.Entries exposing
    ( GetArgs, defaultGetArgs
    , Filter, defaultFilter
    , Entry, EntriesResponse
    , get
    )

{-| Cortex War Room entries — the timeline of notes, chats, attachments,
playbook task results, and other artifacts attached to a case or alert.

@docs GetArgs, defaultGetArgs
@docs Filter, defaultFilter
@docs Entry, EntriesResponse
@docs get

-}

import Cortex.Decode exposing (andMap, optionalField, optionalList)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Arguments to [`get`](#get). `id` is the case or alert identifier — for
cases prepend `"CASE-"` (e.g. `"CASE-3"`), for alerts use the bare numeric
ID. `filter` is optional; pass `Nothing` to retrieve all entries.
-}
type alias GetArgs =
    { id : String
    , filter : Maybe Filter
    }


{-| A [`GetArgs`](#GetArgs) targeting the given id with no filter applied.
-}
defaultGetArgs : String -> GetArgs
defaultGetArgs id =
    { id = id
    , filter = Nothing
    }


{-| Optional filter for narrowing the entries returned by [`get`](#get).
All fields are optional. `pagesize = Just 0` requests every entry.
`fromTime` is an RFC3339 timestamp. `categories` accepts the documented
enum values: `tags`, `chats`, `notes`, `attachments`, `incidentInfo`,
`commandAndResults`, `playbookTaskResult`, `playbookTaskStartAndDone`,
`playbookErrors`. `tags` filters when the `categories` list includes
`tags`.
-}
type alias Filter =
    { firstId : Maybe String
    , lastId : Maybe String
    , pagesize : Maybe Int
    , fromTime : Maybe String
    , categories : List String
    , tags : List String
    }


{-| A [`Filter`](#Filter) with no constraints — equivalent to omitting the
filter object on the wire.
-}
defaultFilter : Filter
defaultFilter =
    { firstId = Nothing
    , lastId = Nothing
    , pagesize = Nothing
    , fromTime = Nothing
    , categories = []
    , tags = []
    }


{-| Top-level envelope returned by [`get`](#get). Note: the response is
**not** wrapped in the usual `reply` envelope.
-}
type alias EntriesResponse =
    { total : Maybe Int
    , data : List Entry
    }


{-| One War Room entry — a note, chat message, attachment, command
output, playbook task result, or other timeline event. The spec marks
no fields as required, so all are `Maybe`. `note` is observed in real
responses (e.g. notes-category entries) but is not in the documented
properties block — captured here so the typed decoder does not silently
drop it.
-}
type alias Entry =
    { id : Maybe String
    , modified : Maybe String
    , created : Maybe String
    , user : Maybe String
    , parentContent : Maybe String
    , contents : Maybe String
    , format : Maybe String
    , investigationId : Maybe String
    , category : Maybe String
    , isTodo : Maybe Bool
    , note : Maybe Bool
    , tags : List String
    }


{-| POST /public\_api/v1/entries/get — fetch War Room entries for a case
or alert.
-}
get : GetArgs -> Request EntriesResponse
get args =
    Request.post
        [ "public_api", "v1", "entries", "get" ]
        (encodeBody args)
        entriesResponseDecoder



-- ENCODERS


encodeBody : GetArgs -> Encode.Value
encodeBody args =
    let
        baseFields =
            [ ( "id", Encode.string args.id ) ]

        withFilter =
            case args.filter of
                Just f ->
                    baseFields ++ [ ( "filter", encodeFilter f ) ]

                Nothing ->
                    baseFields
    in
    Encode.object withFilter


encodeFilter : Filter -> Encode.Value
encodeFilter f =
    let
        fields =
            List.filterMap identity
                [ Maybe.map (\v -> ( "firstID", Encode.string v )) f.firstId
                , Maybe.map (\v -> ( "lastID", Encode.string v )) f.lastId
                , Maybe.map (\v -> ( "pagesize", Encode.int v )) f.pagesize
                , Maybe.map (\v -> ( "fromTime", Encode.string v )) f.fromTime
                , if List.isEmpty f.categories then
                    Nothing

                  else
                    Just ( "categories", Encode.list Encode.string f.categories )
                , if List.isEmpty f.tags then
                    Nothing

                  else
                    Just ( "tags", Encode.list Encode.string f.tags )
                ]
    in
    Encode.object fields



-- DECODERS


entriesResponseDecoder : Decoder EntriesResponse
entriesResponseDecoder =
    Decode.map2 EntriesResponse
        (Decode.maybe (Decode.field "total" Decode.int))
        (optionalList "data" entryDecoder)


entryDecoder : Decoder Entry
entryDecoder =
    Decode.succeed Entry
        |> andMap (optionalField "id" Decode.string)
        |> andMap (optionalField "modified" Decode.string)
        |> andMap (optionalField "created" Decode.string)
        |> andMap (optionalField "user" Decode.string)
        |> andMap (optionalField "parentContent" Decode.string)
        |> andMap (optionalField "contents" Decode.string)
        |> andMap (optionalField "format" Decode.string)
        |> andMap (optionalField "investigationId" Decode.string)
        |> andMap (optionalField "category" Decode.string)
        |> andMap (optionalField "isTodo" Decode.bool)
        |> andMap (optionalField "note" Decode.bool)
        |> andMap (optionalList "tags" Decode.string)
