module Cortex.Api.Rbac exposing
    ( User, Role, UserGroup
    , getUsers, getRoles, getUserGroups
    )

{-| Cortex role-based access control: users, roles, and user groups.

@docs User, Role, UserGroup
@docs getUsers, getRoles, getUserGroups

-}

import Cortex.Decode exposing (andMap, optionalList, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| A Cortex RBAC user record.
-}
type alias User =
    { userEmail : String
    , userFirstName : Maybe String
    , userLastName : Maybe String
    , roleName : Maybe String
    , lastLoggedIn : Maybe Int
    , userType : Maybe String
    , groups : List String

    {- scope is polymorphic across tenants — sometimes a list of scope
       descriptors, sometimes a free-form object describing tenant /
       account / dataset boundaries. The populated shape depends on the
       MSSP / multi-tenant configuration. Preserved verbatim.
    -}
    , scope : Maybe Encode.Value
    }


{-| A Cortex RBAC role definition: permission list plus membership.
-}
type alias Role =
    { prettyName : Maybe String
    , description : Maybe String
    , permissions : List String
    , insertTime : Maybe Int
    , updateTime : Maybe Int
    , createdBy : Maybe String
    , groups : List String
    , users : List String

    {- tags is documented as free-form per role configuration —
       sometimes null, sometimes a structured object. Preserved
       verbatim.
    -}
    , tags : Maybe Encode.Value
    }


{-| A Cortex user-group definition, including member emails.
-}
type alias UserGroup =
    { groupName : Maybe String
    , prettyName : Maybe String
    , description : Maybe String
    , source : Maybe String
    , insertTime : Maybe Int
    , updateTime : Maybe Int
    , userEmail : List String
    }


{-| POST /public\_api/v1/rbac/get\_users
-}
getUsers : Request (List User)
getUsers =
    Request.post
        [ "public_api", "v1", "rbac", "get_users" ]
        (Encode.object [])
        (reply (Decode.list userDecoder))


{-| POST /public\_api/v1/rbac/get\_roles

The API requires `role_names` to contain at least one role name; pass
them via the record argument. The response is a list-of-lists envelope
which is flattened into a single `List Role`.

-}
getRoles : { roleNames : List String } -> Request (List Role)
getRoles { roleNames } =
    Request.post
        [ "public_api", "v1", "rbac", "get_roles" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object [ ( "role_names", Encode.list Encode.string roleNames ) ]
              )
            ]
        )
        (reply (Decode.list (Decode.list roleDecoder))
            |> Decode.map List.concat
        )


{-| POST /public\_api/v1/rbac/get\_user\_group

The API requires `group_names` to contain at least one group name; pass
them via the record argument.

-}
getUserGroups : { groupNames : List String } -> Request (List UserGroup)
getUserGroups { groupNames } =
    Request.post
        [ "public_api", "v1", "rbac", "get_user_group" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object [ ( "group_names", Encode.list Encode.string groupNames ) ]
              )
            ]
        )
        (reply (Decode.list userGroupDecoder))



-- DECODERS


userDecoder : Decoder User
userDecoder =
    Decode.map8 User
        (Decode.field "user_email" Decode.string)
        (Decode.maybe (Decode.field "user_first_name" Decode.string))
        (Decode.maybe (Decode.field "user_last_name" Decode.string))
        (Decode.maybe (Decode.field "role_name" Decode.string))
        (Decode.maybe (Decode.field "last_logged_in" Decode.int))
        (Decode.maybe (Decode.field "user_type" Decode.string))
        (optionalList "groups" Decode.string)
        {- Decoder escape: free-form RBAC scope map; tenant-defined keys
           (asset groups, tenant IDs, etc.) with arbitrary nesting.
        -}
        (Decode.maybe (Decode.field "scope" Decode.value))


roleDecoder : Decoder Role
roleDecoder =
    Decode.succeed Role
        |> andMap (Decode.maybe (Decode.field "pretty_name" Decode.string))
        |> andMap (Decode.maybe (Decode.field "description" Decode.string))
        |> andMap (optionalList "permissions" Decode.string)
        |> andMap (Decode.maybe (Decode.field "insert_time" Decode.int))
        |> andMap (Decode.maybe (Decode.field "update_time" Decode.int))
        |> andMap (Decode.maybe (Decode.field "created_by" Decode.string))
        |> andMap (optionalList "groups" Decode.string)
        |> andMap (optionalList "users" Decode.string)
        {- Decoder escape: free-form tags map; tenant-defined keys/values
           with no API-level schema.
        -}
        |> andMap (Decode.maybe (Decode.field "tags" Decode.value))


userGroupDecoder : Decoder UserGroup
userGroupDecoder =
    Decode.map7 UserGroup
        (Decode.maybe (Decode.field "group_name" Decode.string))
        (Decode.maybe (Decode.field "pretty_name" Decode.string))
        (Decode.maybe (Decode.field "description" Decode.string))
        (Decode.maybe (Decode.field "source" Decode.string))
        (Decode.maybe (Decode.field "insert_time" Decode.int))
        (Decode.maybe (Decode.field "update_time" Decode.int))
        (optionalList "user_email" Decode.string)
