module Cortex.Api.Rbac exposing
    ( User
    , encodeUsers
    , getUsers
    )

import Cortex.Decode exposing (optionalList, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias User =
    { userEmail : String
    , userFirstName : Maybe String
    , userLastName : Maybe String
    , roleName : Maybe String
    , lastLoggedIn : Maybe Int
    , userType : Maybe String
    , groups : List Encode.Value
    , scope : List Encode.Value
    }


{-| POST /public\_api/v1/rbac/get\_users
-}
getUsers : Request (List User)
getUsers =
    Request.post
        [ "public_api", "v1", "rbac", "get_users" ]
        (Encode.object [])
        (reply (Decode.list userDecoder))


userDecoder : Decoder User
userDecoder =
    Decode.map8 User
        (Decode.field "user_email" Decode.string)
        (Decode.maybe (Decode.field "user_first_name" Decode.string))
        (Decode.maybe (Decode.field "user_last_name" Decode.string))
        (Decode.maybe (Decode.field "role_name" Decode.string))
        (Decode.maybe (Decode.field "last_logged_in" Decode.int))
        (Decode.maybe (Decode.field "user_type" Decode.string))
        (optionalList "groups" Decode.value)
        (optionalList "scope" Decode.value)


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
