module Cortex.Api.DisablePrevention exposing
    ( FetchResponse, Rule, Module
    , fetchRules, fetchInjectionRules, getModules
    )

{-| Cortex disable-prevention rules — exceptions that disable a specific
prevention module from running on selected processes / files / hashes.

Three endpoints:

  - [`fetchRules`](#fetchRules) — list configured disable-prevention rules.
  - [`fetchInjectionRules`](#fetchInjectionRules) — same shape, for the
    injection-prevention sibling resource.
  - [`getModules`](#getModules) — list disable-able modules for a given
    platform.

@docs FetchResponse, Rule, Module
@docs fetchRules, fetchInjectionRules, getModules

-}

import Cortex.Decode exposing (andMap, optionalField, optionalList, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Paginated envelope for both [`fetchRules`](#fetchRules) and
[`fetchInjectionRules`](#fetchInjectionRules).
-}
type alias FetchResponse =
    { data : List Rule
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| A single disable-prevention (or disable-injection-prevention) rule.
-}
type alias Rule =
    { ruleId : Maybe String
    , ruleName : Maybe String
    , description : Maybe String
    , platform : Maybe String

    {- conditions describes which processes / files / hashes this rule
       matches. The schema varies per module — every module type defines
       its own keyset (hash/path/command/signer for one module,
       process_name/parent for another). Genuinely polymorphic; preserved
       verbatim so downstream consumers can introspect per module.
    -}
    , conditions : Maybe Encode.Value
    , moduleIds : List Int
    , profileIds : List Int
    , scope : Maybe String
    , status : Maybe String
    , createdBy : Maybe String
    , userEmail : Maybe String
    , modificationTime : Maybe Int
    , associatedTargets : List String
    }


{-| One disable-able module type returned by [`getModules`](#getModules).
-}
type alias Module =
    { moduleId : Maybe Int
    , name : Maybe String
    , description : Maybe String
    , profileType : Maybe String

    {- conditions_definition is a JSON-Schema-style description of the
       condition shape this module accepts. Polymorphic across modules,
       same rationale as Rule.conditions above. Preserved verbatim.
    -}
    , conditionsDefinition : Maybe Encode.Value
    }


{-| POST /public\_api/v1/disable\_prevention/fetch
-}
fetchRules : Request FetchResponse
fetchRules =
    Request.postEmpty
        [ "public_api", "v1", "disable_prevention", "fetch" ]
        (reply fetchResponseDecoder)


{-| POST /public\_api/v1/disable\_injection\_prevention\_rules/fetch
-}
fetchInjectionRules : Request FetchResponse
fetchInjectionRules =
    Request.postEmpty
        [ "public_api", "v1", "disable_injection_prevention_rules", "fetch" ]
        (reply fetchResponseDecoder)


{-| POST /public\_api/v1/disable\_prevention/get\_modules

`platform` must be `windows`, `linux`, or `macos` (lowercase).

-}
getModules : String -> Request (List Module)
getModules platform =
    Request.post
        [ "public_api", "v1", "disable_prevention", "get_modules" ]
        (Encode.object
            [ ( "request_data", Encode.object [ ( "platform", Encode.string platform ) ] )
            ]
        )
        (reply (Decode.list moduleDecoder))



-- DECODERS


fetchResponseDecoder : Decoder FetchResponse
fetchResponseDecoder =
    Decode.map3 FetchResponse
        (optionalList "data" ruleDecoder)
        (Decode.maybe (Decode.field "filter_count" Decode.int))
        (Decode.maybe (Decode.field "total_count" Decode.int))


ruleDecoder : Decoder Rule
ruleDecoder =
    Decode.succeed Rule
        |> andMap (optionalField "rule_id" Decode.string)
        |> andMap (optionalField "rule_name" Decode.string)
        |> andMap (optionalField "description" Decode.string)
        |> andMap (optionalField "platform" Decode.string)
        |> andMap (optionalField "conditions" Decode.value)
        |> andMap (optionalList "module_ids" Decode.int)
        |> andMap (optionalList "profile_ids" Decode.int)
        |> andMap (optionalField "scope" Decode.string)
        |> andMap (optionalField "status" Decode.string)
        |> andMap (optionalField "created_by" Decode.string)
        |> andMap (optionalField "user_email" Decode.string)
        |> andMap (optionalField "modification_time" Decode.int)
        |> andMap (optionalList "associated_targets" Decode.string)


moduleDecoder : Decoder Module
moduleDecoder =
    Decode.map5 Module
        (optionalField "module_id" Decode.int)
        (optionalField "name" Decode.string)
        (optionalField "description" Decode.string)
        (optionalField "profile_type" Decode.string)
        (optionalField "conditions_definition" Decode.value)
