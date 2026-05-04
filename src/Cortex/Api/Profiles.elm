module Cortex.Api.Profiles exposing
    ( Profile, GetPolicyResponse
    , PreventionModule
    , getProfiles, getPolicy
    , getPreventionModules
    )

{-| Cortex endpoint security profiles and per-endpoint policy lookups.

@docs Profile, GetPolicyResponse
@docs PreventionModule
@docs getProfiles, getPolicy
@docs getPreventionModules

-}

import Cortex.Decode exposing (andMap, optionalField, optionalList, reply)
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


{-| One prevention-profile module returned by
[`getPreventionModules`](#getPreventionModules) — a category of policy
behaviour that a prevention profile can configure (e.g. "Network Packet
Inspection Engine"). The wire `id` is a stable string slug
(`"networkSignature"`), not an integer.
-}
type alias PreventionModule =
    { id : Maybe String
    , profileType : Maybe String
    , platform : Maybe String
    , prettyName : Maybe String

    {- schema is a JSON-Schema-style description of the configuration
       shape this module accepts (mode enums, path arrays, etc.). The
       shape is module-specific and intentionally polymorphic across the
       28+ prevention modules. Preserved verbatim so downstream consumers
       can introspect or re-emit per module type.
    -}
    , schema : Maybe Encode.Value
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


{-| POST /public\_api/v1/profiles/prevention/get\_modules

List the prevention-profile module catalog for a given profile type and
platform. The two arguments must be capitalised exactly as the API
expects: `profileType` ∈ `Exploit`, `Malware`, `Restrictions`,
`Agent Settings`; `platform` ∈ `Windows`, `macOS`, `Linux`, `Android`,
`iOS`, `Serverless Function`. The OpenAPI spec documents lowercase
values, but the live API rejects them.

-}
getPreventionModules : { profileType : String, platform : String } -> Request (List PreventionModule)
getPreventionModules { profileType, platform } =
    Request.post
        [ "public_api", "v1", "profiles", "prevention", "get_modules" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object
                    [ ( "profile_type", Encode.string profileType )
                    , ( "platform", Encode.string platform )
                    ]
              )
            ]
        )
        (reply (Decode.list preventionModuleDecoder))


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
        {- Decoder escape: per-module configuration map keyed by module
           name. Each value is a module-specific config object whose shape
           varies by module type and platform. Genuinely polymorphic.
        -}
        |> andMap (Decode.maybe (Decode.field "modules" Decode.value))


getPolicyResponseDecoder : Decoder GetPolicyResponse
getPolicyResponseDecoder =
    Decode.map GetPolicyResponse
        (Decode.maybe (Decode.field "policy_name" Decode.string))


preventionModuleDecoder : Decoder PreventionModule
preventionModuleDecoder =
    Decode.map5 PreventionModule
        (optionalField "id" Decode.string)
        (optionalField "profile_type" Decode.string)
        (optionalField "platform" Decode.string)
        (optionalField "pretty_name" Decode.string)
        {- Decoder escape: per-module JSON-Schema-style configuration
           shape; varies entirely per module type and is opaque to the SDK.
        -}
        (optionalField "schema" Decode.value)
