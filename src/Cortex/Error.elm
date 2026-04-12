module Cortex.Error exposing
    ( ApiError
    , Error(..)
    , decodeApiError
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type Error
    = NetworkError
    | Timeout
    | BadStatus Int (Maybe ApiError)
    | BadBody String
    | BadUrl String


type alias ApiError =
    { errCode : Maybe String
    , errMsg : String
    , errExtra : Maybe Encode.Value
    }


{-| Try multiple known error envelope shapes, in priority order.
Returns the first successful parse as an ApiError.
-}
decodeApiError : String -> Maybe ApiError
decodeApiError body =
    let
        decoders =
            [ replyEnvelopeDecoder
            , directWithMetadataDecoder
            , directFlatDecoder
            , errorCodeMessageDecoder
            ]

        tryDecode decoder =
            Decode.decodeString decoder body
                |> Result.toMaybe
    in
    List.filterMap tryDecode decoders
        |> List.head



-- Reply envelope: { "reply": { "err_code": ..., "err_msg": ..., "err_extra": ... } }


replyEnvelopeDecoder : Decoder ApiError
replyEnvelopeDecoder =
    Decode.field "reply" apiErrorFieldsDecoder



-- Direct with metadata: { "err_msg": ..., "metadata": { "code": ... } }


directWithMetadataDecoder : Decoder ApiError
directWithMetadataDecoder =
    Decode.map3 ApiError
        (Decode.at [ "metadata", "code" ] Decode.string |> Decode.map Just)
        (Decode.field "err_msg" Decode.string)
        (Decode.maybe (Decode.field "err_extra" Decode.value))



-- Direct flat: { "err_msg": ..., "err_extra": ... }


directFlatDecoder : Decoder ApiError
directFlatDecoder =
    apiErrorFieldsDecoder



-- ErrorCode + message: { "errorCode": ..., "message": ... }


errorCodeMessageDecoder : Decoder ApiError
errorCodeMessageDecoder =
    Decode.map3 ApiError
        (Decode.maybe (Decode.field "errorCode" Decode.string))
        (Decode.field "message" Decode.string)
        (Decode.succeed Nothing)


apiErrorFieldsDecoder : Decoder ApiError
apiErrorFieldsDecoder =
    Decode.map3 ApiError
        (Decode.maybe (Decode.field "err_code" apiErrorCodeDecoder))
        (Decode.field "err_msg" Decode.string)
        (Decode.maybe (Decode.field "err_extra" Decode.value))


{-| err\_code can be either a string or an integer in different APIs.
Normalize to String.
-}
apiErrorCodeDecoder : Decoder String
apiErrorCodeDecoder =
    Decode.oneOf
        [ Decode.string
        , Decode.int |> Decode.map String.fromInt
        ]
