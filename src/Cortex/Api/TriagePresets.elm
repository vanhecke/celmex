module Cortex.Api.TriagePresets exposing
    ( TriagePreset, TriagePresetsResponse
    , list
    )

{-| Forensics triage presets — named, OS-scoped collections of artifacts the
endpoint agent collects when triggered. Read-only via the public API.

@docs TriagePreset, TriagePresetsResponse
@docs list

-}

import Cortex.Decode exposing (optionalList, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| A single triage preset description.
-}
type alias TriagePreset =
    { uuid : Maybe String
    , name : Maybe String
    , os : Maybe String
    , description : Maybe String
    , createdBy : Maybe String
    , type_ : Maybe String
    }


{-| Envelope returned by [`list`](#list).
-}
type alias TriagePresetsResponse =
    { triagePresets : List TriagePreset
    }


{-| POST /public\_api/v1/get\_triage\_presets
-}
list : Request TriagePresetsResponse
list =
    Request.post
        [ "public_api", "v1", "get_triage_presets" ]
        (Encode.object [ ( "request_data", Encode.object [] ) ])
        (reply triagePresetsResponseDecoder)


triagePresetsResponseDecoder : Decoder TriagePresetsResponse
triagePresetsResponseDecoder =
    Decode.map TriagePresetsResponse
        (optionalList "triage_presets" triagePresetDecoder)


triagePresetDecoder : Decoder TriagePreset
triagePresetDecoder =
    Decode.map6 TriagePreset
        (Decode.maybe (Decode.field "uuid" Decode.string))
        (Decode.maybe (Decode.field "name" Decode.string))
        (Decode.maybe (Decode.field "os" Decode.string))
        (Decode.maybe (Decode.field "description" Decode.string))
        (Decode.maybe (Decode.field "created_by" Decode.string))
        (Decode.maybe (Decode.field "type" Decode.string))
