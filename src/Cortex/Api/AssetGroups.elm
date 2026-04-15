module Cortex.Api.AssetGroups exposing
    ( AssetGroupsResponse
    , encode
    , list
    )

import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Asset-group records use XDM.ASSET\_GROUP.\* uppercase dotted field names
and include complex filter/membership structures that vary per group. We
preserve each group as raw JSON to capture every field verbatim.
-}
type alias AssetGroupsResponse =
    { data : List Encode.Value
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| POST /public\_api/v1/asset-groups
-}
list : Request AssetGroupsResponse
list =
    Request.post
        [ "public_api", "v1", "asset-groups" ]
        (Encode.object [ ( "request_data", Encode.object [] ) ])
        (Decode.field "reply" responseDecoder)


responseDecoder : Decoder AssetGroupsResponse
responseDecoder =
    Decode.map3 AssetGroupsResponse
        (Decode.oneOf
            [ Decode.field "data" (Decode.list Decode.value)
            , Decode.field "DATA" (Decode.list Decode.value)
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


encode : AssetGroupsResponse -> Encode.Value
encode r =
    Encode.object
        (List.filterMap identity
            [ Just ( "data", Encode.list identity r.data )
            , Maybe.map (\v -> ( "filter_count", Encode.int v )) r.filterCount
            , Maybe.map (\v -> ( "total_count", Encode.int v )) r.totalCount
            ]
        )
