module Cortex.Api.LegacyExceptions exposing
    ( Module, FetchResponse, ExceptionRule
    , getModules, fetch
    )

{-| Legacy policy exception modules and the per-rule list of currently
configured exceptions.

Two endpoints:

  - [`getModules`](#getModules) — list every module type that _can_ be
    excepted (e.g. "Malware > Behavioral Threat Protection"), along with
    a JSON-Schema-style `conditions_definition` describing what condition
    shape that module accepts.

  - [`fetch`](#fetch) — list the exception rules currently configured on
    the tenant.

@docs Module, FetchResponse, ExceptionRule
@docs getModules, fetch

-}

import Cortex.Decode exposing (andMap, optionalList, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| One legacy-exception module type — a category of policy that can have
exceptions defined against it. `conditionsDefinition` is intentionally
opaque (see field comment).
-}
type alias Module =
    { moduleId : Maybe Int
    , prettyName : Maybe String
    , title : Maybe String
    , label : Maybe String
    , profileType : Maybe String
    , platforms : List String

    {- conditionsDefinition is a JSON-Schema-style description of the
       condition shape this module accepts. It is genuinely polymorphic
       across modules — every module defines its own custom condition
       schema (whitelistFolders, allow, whitelistSigners, process_exceptions,
       reverse-shell tuples, etc.) with module-specific properties and
       enums. Cannot be typed at the SDK layer; preserved verbatim so
       downstream consumers can introspect or re-emit per module type.
    -}
    , conditionsDefinition : Encode.Value
    }


{-| Paginated envelope returned by [`fetch`](#fetch).
-}
type alias FetchResponse =
    { data : List ExceptionRule
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| A single configured exception rule. `id` is a string (per spec — not
the integer identifier other Cortex endpoints use).
-}
type alias ExceptionRule =
    { id : Maybe String
    , ruleName : Maybe String
    , platform : Maybe String
    , conditions : Maybe String
    , module_ : Maybe Int
    , moduleName : Maybe String
    , description : Maybe String
    , generatingAlertId : Maybe Encode.Value
    , createdBy : Maybe String
    , modificationTime : Maybe Int
    , userEmail : Maybe String
    , status : Maybe String
    , profileIds : List Int
    , associatedTargets : List String
    , isInUserScope : Maybe Bool
    }


{-| POST /public\_api/v1/legacy\_exceptions/get\_modules

List every legacy-exception module type that can have rules defined
against it.

-}
getModules : Request (List Module)
getModules =
    Request.post
        [ "public_api", "v1", "legacy_exceptions", "get_modules" ]
        (Encode.object [])
        (reply (Decode.list moduleDecoder))


{-| POST /public\_api/v1/legacy\_exceptions/fetch

Retrieve the legacy exception rules currently configured on the tenant,
with optional filtering, sorting, and pagination.

-}
fetch : Request FetchResponse
fetch =
    Request.postEmpty
        [ "public_api", "v1", "legacy_exceptions", "fetch" ]
        (reply fetchResponseDecoder)



-- DECODERS


moduleDecoder : Decoder Module
moduleDecoder =
    Decode.map7 Module
        (optionalField "module_id" Decode.int)
        (optionalField "pretty_name" Decode.string)
        (optionalField "title" Decode.string)
        (optionalField "label" Decode.string)
        (optionalField "profile_type" Decode.string)
        (Decode.oneOf
            [ Decode.field "platforms" (Decode.list Decode.string)
            , Decode.succeed []
            ]
        )
        (Decode.oneOf
            [ Decode.field "conditions_definition" Decode.value
            , Decode.succeed Encode.null
            ]
        )


fetchResponseDecoder : Decoder FetchResponse
fetchResponseDecoder =
    Decode.map3 FetchResponse
        (Decode.oneOf
            [ Decode.field "DATA" (Decode.list exceptionRuleDecoder)
            , Decode.field "data" (Decode.list exceptionRuleDecoder)
            , Decode.succeed []
            ]
        )
        (Decode.maybe
            (Decode.oneOf
                [ Decode.field "FILTER_COUNT" Decode.int
                , Decode.field "filter_count" Decode.int
                ]
            )
        )
        (Decode.maybe
            (Decode.oneOf
                [ Decode.field "TOTAL_COUNT" Decode.int
                , Decode.field "total_count" Decode.int
                ]
            )
        )


exceptionRuleDecoder : Decoder ExceptionRule
exceptionRuleDecoder =
    Decode.succeed ExceptionRule
        |> andMap (optionalField "id" Decode.string)
        |> andMap (optionalField "rule_name" Decode.string)
        |> andMap (optionalField "platform" Decode.string)
        |> andMap (optionalField "conditions" Decode.string)
        |> andMap (optionalField "module" Decode.int)
        |> andMap (optionalField "module_name" Decode.string)
        |> andMap (optionalField "description" Decode.string)
        |> andMap (optionalField "generating_alert_id" Decode.value)
        |> andMap (optionalField "created_by" Decode.string)
        |> andMap (optionalField "modification_time" Decode.int)
        |> andMap (optionalField "user_email" Decode.string)
        |> andMap (optionalField "status" Decode.string)
        |> andMap (optionalList "profile_ids" Decode.int)
        |> andMap (optionalList "associated_targets" Decode.string)
        |> andMap (optionalField "is_in_user_scope" Decode.bool)


optionalField : String -> Decoder a -> Decoder (Maybe a)
optionalField name d =
    Decode.maybe (Decode.field name d)
