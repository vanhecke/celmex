module Cortex.Error exposing
    ( ApiError
    , Error(..)
    , decodeApiError
    )

import Cortex.Decode exposing (reply)
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

The body is parsed to a `Decode.Value` once up-front; each candidate decoder
is then attempted against that parsed value rather than re-parsing the
original string. Matters on large error bodies.

-}
decodeApiError : String -> Maybe ApiError
decodeApiError body =
    case Decode.decodeString Decode.value body of
        Err _ ->
            Nothing

        Ok parsed ->
            let
                tryDecode decoder =
                    Decode.decodeValue decoder parsed
                        |> Result.toMaybe
            in
            [ replyEnvelopeDecoder
            , directWithMetadataDecoder
            , directFlatDecoder
            , errorCodeMessageDecoder
            ]
                |> List.filterMap tryDecode
                |> List.head



-- Reply envelope: { "reply": { "err_code": ..., "err_msg": ..., "err_extra": ... } }


replyEnvelopeDecoder : Decoder ApiError
replyEnvelopeDecoder =
    reply apiErrorFieldsDecoder



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
