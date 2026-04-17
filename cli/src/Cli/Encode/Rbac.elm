module Cli.Encode.Rbac exposing (encodeUsers)

import Cortex.Api.Rbac exposing (User)
import Json.Encode as Encode


encodeUsers : List User -> Encode.Value
encodeUsers users =
    Encode.list encodeUser users


encodeUser : User -> Encode.Value
encodeUser user =
    Encode.object
        (List.filterMap identity
            [ Just ( "user_email", Encode.string user.userEmail )
            , Maybe.map (\v -> ( "user_first_name", Encode.string v )) user.userFirstName
            , Maybe.map (\v -> ( "user_last_name", Encode.string v )) user.userLastName
            , Maybe.map (\v -> ( "role_name", Encode.string v )) user.roleName
            , Maybe.map (\v -> ( "last_logged_in", Encode.int v )) user.lastLoggedIn
            , Maybe.map (\v -> ( "user_type", Encode.string v )) user.userType
            , Just ( "groups", Encode.list identity user.groups )
            , Just ( "scope", Encode.list identity user.scope )
            ]
        )
