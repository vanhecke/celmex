module Cortex.Api.Rbac exposing
    ( User
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
