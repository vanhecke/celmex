module Cortex.Api.AssetGroups exposing
    ( AssetGroup, AssetGroupsResponse, FilterPart
    , list
    )

{-| Cortex asset-group listings.

@docs AssetGroup, AssetGroupsResponse, FilterPart
@docs list

-}

import Cortex.Decode exposing (andMap, optionalField, optionalList, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Paginated envelope returned by [`list`](#list).
-}
type alias AssetGroupsResponse =
    { data : List AssetGroup
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| One asset group. Field names mirror the wire format's
`XDM.ASSET_GROUP.*` dotted-uppercase shape.
-}
type alias AssetGroup =
    { id : Maybe Int
    , name : Maybe String
    , type_ : Maybe String
    , description : Maybe String
    , filter : List FilterPart
    , creationTime : Maybe Int
    , createdBy : Maybe String
    , createdByPretty : Maybe String
    , lastUpdateTime : Maybe Int
    , modifiedBy : Maybe String
    , modifiedByPretty : Maybe String

    {- membershipPredicate is a deeply nested AND/OR boolean tree of
       SEARCH_FIELD/SEARCH_TYPE/SEARCH_VALUE rows that defines which
       assets match the group. The nesting depth and operand shape
       depend on the group's configuration; preserved verbatim because
       typing the predicate DSL belongs in a dedicated module.
    -}
    , membershipPredicate : Maybe Encode.Value
    , isUsedBySbac : Maybe Bool
    }


{-| One render-instruction in an [`AssetGroup`](#AssetGroup)'s filter
description. The filter is emitted as a flat list of parts the UI
concatenates (`attribute`, `operator`, `value`, `connector`).
-}
type alias FilterPart =
    { prettyName : Maybe String
    , dataType : Maybe String
    , renderType : Maybe String
    , entityMap : Maybe String
    , dmlType : Maybe String
    }


{-| POST /public\_api/v1/asset-groups

List configured asset groups on the tenant.

-}
list : Request AssetGroupsResponse
list =
    Request.postEmpty
        [ "public_api", "v1", "asset-groups" ]
        (reply responseDecoder)



-- DECODERS


responseDecoder : Decoder AssetGroupsResponse
responseDecoder =
    Decode.map3 AssetGroupsResponse
        (Decode.oneOf
            [ Decode.field "data" (Decode.list assetGroupDecoder)
            , Decode.field "DATA" (Decode.list assetGroupDecoder)
            , Decode.succeed []
            ]
        )
        (Decode.maybe
            (Decode.oneOf
                [ Decode.field "filter_count" Decode.int
                , Decode.at [ "metadata", "filter_count" ] Decode.int
                ]
            )
        )
        (Decode.maybe
            (Decode.oneOf
                [ Decode.field "total_count" Decode.int
                , Decode.at [ "metadata", "total_count" ] Decode.int
                ]
            )
        )


assetGroupDecoder : Decoder AssetGroup
assetGroupDecoder =
    Decode.succeed AssetGroup
        |> andMap (optionalField "XDM.ASSET_GROUP.ID" Decode.int)
        |> andMap (optionalField "XDM.ASSET_GROUP.NAME" Decode.string)
        |> andMap (optionalField "XDM.ASSET_GROUP.TYPE" Decode.string)
        |> andMap (optionalField "XDM.ASSET_GROUP.DESCRIPTION" Decode.string)
        |> andMap (optionalList "XDM.ASSET_GROUP.FILTER" filterPartDecoder)
        |> andMap (optionalField "XDM.ASSET_GROUP.CREATION_TIME" Decode.int)
        |> andMap (optionalField "XDM.ASSET_GROUP.CREATED_BY" Decode.string)
        |> andMap (optionalField "XDM.ASSET_GROUP.CREATED_BY_PRETTY" Decode.string)
        |> andMap (optionalField "XDM.ASSET_GROUP.LAST_UPDATE_TIME" Decode.int)
        |> andMap (optionalField "XDM.ASSET_GROUP.MODIFIED_BY" Decode.string)
        |> andMap (optionalField "XDM.ASSET_GROUP.MODIFIED_BY_PRETTY" Decode.string)
        {- Decoder escape: XDM membership predicate — a DSL expression tree
           whose shape varies per group type. Opaque to the SDK.
        -}
        |> andMap (optionalField "XDM.ASSET_GROUP.MEMBERSHIP_PREDICATE" Decode.value)
        |> andMap (optionalField "IS_USED_BY_SBAC" Decode.bool)


filterPartDecoder : Decoder FilterPart
filterPartDecoder =
    Decode.map5 FilterPart
        (optionalField "pretty_name" Decode.string)
        (optionalField "data_type" Decode.string)
        (optionalField "render_type" Decode.string)
        (optionalField "entity_map" Decode.string)
        (optionalField "dml_type" Decode.string)
