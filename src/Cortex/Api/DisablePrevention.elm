module Cortex.Api.DisablePrevention exposing
    ( FetchResponse
    , Module
    , fetchInjectionRules
    , fetchRules
    , getModules
    )

import Cortex.Decode exposing (optionalList, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Disable-prevention rule rows carry per-module exception criteria whose
shape varies by the prevention module being disabled; preserved as raw
JSON. Envelope mirrors `LegacyExceptions.fetch` (lowercase counters).
-}
type alias FetchResponse =
    { data : List Encode.Value
    , filterCount : Maybe Int
    , totalCount : Maybe Int
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


fetchResponseDecoder : Decoder FetchResponse
fetchResponseDecoder =
    Decode.map3 FetchResponse
        (optionalList "data" Decode.value)
        (Decode.maybe (Decode.field "filter_count" Decode.int))
        (Decode.maybe (Decode.field "total_count" Decode.int))


{-| A prevention module entry returned by `getModules`. The
`conditions_definition` JSON-Schema fragment varies by module and is preserved
as raw JSON.
-}
type alias Module =
    { moduleId : Maybe Int
    , name : Maybe String
    , description : Maybe String
    , profileType : Maybe String
    , conditionsDefinition : Maybe Encode.Value
    }


{-| POST /public\_api/v1/disable\_prevention/get\_modules

`platform` must be `windows`, `linux`, or `macos`.

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


moduleDecoder : Decoder Module
moduleDecoder =
    Decode.map5 Module
        (Decode.maybe (Decode.field "module_id" Decode.int))
        (Decode.maybe (Decode.field "name" Decode.string))
        (Decode.maybe (Decode.field "description" Decode.string))
        (Decode.maybe (Decode.field "profile_type" Decode.string))
        (Decode.maybe (Decode.field "conditions_definition" Decode.value))
