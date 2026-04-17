module Cortex.Api.DisablePrevention exposing
    ( FetchResponse
    , fetchInjectionRules
    , fetchRules
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
