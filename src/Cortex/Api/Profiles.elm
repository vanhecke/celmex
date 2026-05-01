module Cortex.Api.Profiles exposing
    ( Profile, GetPolicyResponse
    , getProfiles, getPolicy
    )

{-| Cortex endpoint security profiles and per-endpoint policy lookups.

@docs Profile, GetPolicyResponse
@docs getProfiles, getPolicy

-}

import Cortex.Decode exposing (andMap, optionalList, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| A single endpoint security profile (prevention or extension).
-}
type alias Profile =
    { id : Maybe Int
    , uuid : Maybe String
    , name : Maybe String
    , type_ : Maybe String
    , platform : Maybe String
    , description : Maybe String
    , isDefault : Maybe Bool
    , isGlobal : Maybe Bool
    , isDisabled : Maybe Bool
    , usageCount : Maybe Int
    , associatedTargets : List String
    , createdBy : Maybe String
    , createdByPretty : Maybe String
    , creationTime : Maybe Int
    , modifiedBy : Maybe String
    , modifiedByPretty : Maybe String
    , modificationTime : Maybe Int

    {- modules is a per-module configuration map keyed by module name
       (e.g. `malware`, `exploit`, `restrictions`). Each value is a
       module-specific config object whose shape varies by module type
       and platform. Genuinely polymorphic; preserved verbatim.
    -}
    , modules : Maybe Encode.Value
    }


{-| Response from [`getPolicy`](#getPolicy).
-}
type alias GetPolicyResponse =
    { policyName : Maybe String
    }


{-| POST /public\_api/v1/endpoints/get\_profiles

Get endpoint security profiles of the requested type. The API requires
a `type` discriminator (`"prevention"` or `"extension"`); pass it via
the record argument.

-}
getProfiles : { type_ : String } -> Request (List Profile)
getProfiles { type_ } =
    Request.post
        [ "public_api", "v1", "endpoints", "get_profiles" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object [ ( "type", Encode.string type_ ) ]
              )
            ]
        )
        (reply (Decode.list profileDecoder))


{-| POST /public\_api/v1/endpoints/get\_policy

Get the policy name assigned to a single endpoint. Requires the endpoint
ID; pass it via the record argument.

-}
getPolicy : { endpointId : String } -> Request GetPolicyResponse
getPolicy { endpointId } =
    Request.post
        [ "public_api", "v1", "endpoints", "get_policy" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object [ ( "endpoint_id", Encode.string endpointId ) ]
              )
            ]
        )
        (reply getPolicyResponseDecoder)



-- DECODERS


profileDecoder : Decoder Profile
profileDecoder =
    Decode.succeed Profile
        |> andMap (Decode.maybe (Decode.field "id" Decode.int))
        |> andMap (Decode.maybe (Decode.field "uuid" Decode.string))
        |> andMap (Decode.maybe (Decode.field "name" Decode.string))
        |> andMap (Decode.maybe (Decode.field "type" Decode.string))
        |> andMap (Decode.maybe (Decode.field "platform" Decode.string))
        |> andMap (Decode.maybe (Decode.field "description" Decode.string))
        |> andMap (Decode.maybe (Decode.field "is_default" Decode.bool))
        |> andMap (Decode.maybe (Decode.field "is_global" Decode.bool))
        |> andMap (Decode.maybe (Decode.field "is_disabled" Decode.bool))
        |> andMap (Decode.maybe (Decode.field "usage_count" Decode.int))
        |> andMap (optionalList "associated_targets" Decode.string)
        |> andMap (Decode.maybe (Decode.field "created_by" Decode.string))
        |> andMap (Decode.maybe (Decode.field "created_by_pretty" Decode.string))
        |> andMap (Decode.maybe (Decode.field "creation_time" Decode.int))
        |> andMap (Decode.maybe (Decode.field "modified_by" Decode.string))
        |> andMap (Decode.maybe (Decode.field "modified_by_pretty" Decode.string))
        |> andMap (Decode.maybe (Decode.field "modification_time" Decode.int))
        |> andMap (Decode.maybe (Decode.field "modules" Decode.value))


getPolicyResponseDecoder : Decoder GetPolicyResponse
getPolicyResponseDecoder =
    Decode.map GetPolicyResponse
        (Decode.maybe (Decode.field "policy_name" Decode.string))
