module Cli.Encode.AssetGroups exposing (encode)

import Cortex.Api.AssetGroups exposing (AssetGroupsResponse)
import Json.Encode as Encode


encode : AssetGroupsResponse -> Encode.Value
encode r =
    Encode.object
        (List.filterMap identity
            [ Just ( "data", Encode.list identity r.data )
            , Maybe.map (\v -> ( "filter_count", Encode.int v )) r.filterCount
            , Maybe.map (\v -> ( "total_count", Encode.int v )) r.totalCount
            ]
        )
