module Cortex.Decode exposing (reply, optionalList, andMap)

{-| Decoder helpers shared across `Cortex.Api.*` modules.

The Cortex Advanced API consistently wraps responses in a `{"reply": ...}`
envelope, several response shapes return lists that may be omitted when
empty, and pipeline-style decoders need an `andMap` once `Json.Decode.map8`
runs out of slots. Centralising these three primitives here keeps the
per-API modules focused on their own shapes.

@docs reply, optionalList, andMap

-}

import Json.Decode as Decode exposing (Decoder)


{-| Unwrap the `reply` envelope that Cortex wraps around every success response.
-}
reply : Decoder a -> Decoder a
reply inner =
    Decode.field "reply" inner


{-| Decode a list field, defaulting to the empty list when the field is absent.
-}
optionalList : String -> Decoder a -> Decoder (List a)
optionalList field itemDecoder =
    Decode.oneOf
        [ Decode.field field (Decode.list itemDecoder)
        , Decode.succeed []
        ]


{-| Pipeline-style helper to apply an additional decoder when `Decode.mapN`
runs out of positional slots.
-}
andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap valDecoder funcDecoder =
    Decode.map2 (\f v -> f v) funcDecoder valDecoder
