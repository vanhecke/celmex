module Cortex.Api.LegacyExceptions exposing
    ( FetchResponse
    , Module
    , fetch
    , getModules
    )

import Cortex.Decode exposing (reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Module =
    { moduleId : Maybe Int
    , prettyName : Maybe String
    , title : Maybe String
    , label : Maybe String
    , profileType : Maybe String
    , platforms : List String
    , conditionsDefinition : Encode.Value
    }


{-| Legacy exception rules have many flexible fields (conditions structure,
profile associations, etc.) that vary by module type. We preserve each rule
as raw JSON and only type the paginated envelope counters.
-}
type alias FetchResponse =
    { data : List Encode.Value
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| POST /public\_api/v1/legacy\_exceptions/get\_modules

No request body required — send empty.

-}
getModules : Request (List Module)
getModules =
    Request.post
        [ "public_api", "v1", "legacy_exceptions", "get_modules" ]
        (Encode.object [])
        (reply (Decode.list moduleDecoder))


{-| POST /public\_api/v1/legacy\_exceptions/fetch
-}
fetch : Request FetchResponse
fetch =
    Request.postEmpty
        [ "public_api", "v1", "legacy_exceptions", "fetch" ]
        (reply fetchResponseDecoder)


moduleDecoder : Decoder Module
moduleDecoder =
    Decode.map7 Module
        (Decode.maybe (Decode.field "module_id" Decode.int))
        (Decode.maybe (Decode.field "pretty_name" Decode.string))
        (Decode.maybe (Decode.field "title" Decode.string))
        (Decode.maybe (Decode.field "label" Decode.string))
        (Decode.maybe (Decode.field "profile_type" Decode.string))
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
            [ Decode.field "DATA" (Decode.list Decode.value)
            , Decode.field "data" (Decode.list Decode.value)
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
