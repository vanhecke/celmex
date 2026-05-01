module Cortex.Api.ApiKeys exposing
    ( ApiKey
    , GetApiKeysResponse
    , getApiKeys
    )

{-| Cortex advanced-API key management — list configured keys.

@docs ApiKey, GetApiKeysResponse
@docs getApiKeys

-}

import Cortex.Decode exposing (optionalList, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Paginated envelope returned by [`getApiKeys`](#getApiKeys): the
configured [`ApiKey`](#ApiKey) records plus the filter / total counts
from the standard Cortex paginated reply.
-}
type alias GetApiKeysResponse =
    { data : List ApiKey
    , filterCount : Maybe Int
    , totalCount : Maybe Int
    }


{-| A single advanced-API key record. Roles are role names, not IDs.
Time fields are Unix epoch milliseconds.
-}
type alias ApiKey =
    { id : Int
    , creationTime : Maybe Int
    , createdBy : Maybe String
    , userName : Maybe String
    , roles : List String
    , securityLevel : Maybe String
    , comment : Maybe String
    , expiration : Maybe Int
    }


{-| POST /public\_api/v1/api\_keys/get\_api\_keys

List existing API keys. The API requires a `filters` field; an empty list
fetches every key. Response uses the standard paginated envelope
(`DATA`, `FILTER_COUNT`, `TOTAL_COUNT`) inside the `reply` wrapper.

-}
getApiKeys : Request GetApiKeysResponse
getApiKeys =
    Request.post
        [ "public_api", "v1", "api_keys", "get_api_keys" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object [ ( "filters", Encode.list Encode.string [] ) ]
              )
            ]
        )
        (reply getApiKeysResponseDecoder)


getApiKeysResponseDecoder : Decoder GetApiKeysResponse
getApiKeysResponseDecoder =
    Decode.map3 GetApiKeysResponse
        (optionalList "DATA" apiKeyDecoder)
        (Decode.maybe (Decode.field "FILTER_COUNT" Decode.int))
        (Decode.maybe (Decode.field "TOTAL_COUNT" Decode.int))


apiKeyDecoder : Decoder ApiKey
apiKeyDecoder =
    Decode.map8 ApiKey
        (Decode.field "id" Decode.int)
        (Decode.maybe (Decode.field "creation_time" Decode.int))
        (Decode.maybe (Decode.field "created_by" Decode.string))
        (Decode.maybe (Decode.field "user_name" Decode.string))
        (optionalList "roles" Decode.string)
        (Decode.maybe (Decode.field "security_level" Decode.string))
        (Decode.maybe (Decode.field "comment" Decode.string))
        (Decode.maybe (Decode.field "expiration" Decode.int))
