module Cortex.Api.Endpoints exposing
    ( Endpoint
    , ListResponse
    , list
    )

import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias ListResponse =
    { endpoints : List Endpoint
    }


type alias Endpoint =
    { agentId : String
    , agentStatus : Maybe String
    , operationalStatus : Maybe String
    , hostName : Maybe String
    , agentType : Maybe String
    , ip : List String
    , lastSeen : Maybe Int
    , tags : Encode.Value
    , users : List String
    }


{-| POST /public\_api/v1/endpoints/get\_endpoints

Retrieve a list of all endpoints (agents) on the tenant.
Response uses the `reply` envelope containing a flat array.

-}
list : Request ListResponse
list =
    Request.post
        [ "public_api", "v1", "endpoints", "get_endpoints" ]
        (Encode.object
            [ ( "request_data", Encode.object [] ) ]
        )
        listResponseDecoder


listResponseDecoder : Decoder ListResponse
listResponseDecoder =
    Decode.field "reply" (Decode.list endpointDecoder)
        |> Decode.map ListResponse


endpointDecoder : Decoder Endpoint
endpointDecoder =
    Decode.map8 Endpoint
        (Decode.field "agent_id" Decode.string)
        (Decode.maybe (Decode.field "agent_status" Decode.string))
        (Decode.maybe (Decode.field "operational_status" Decode.string))
        (Decode.maybe (Decode.field "host_name" Decode.string))
        (Decode.maybe (Decode.field "agent_type" Decode.string))
        (Decode.oneOf
            [ Decode.field "ip" (Decode.list Decode.string)
            , Decode.succeed []
            ]
        )
        (Decode.maybe (Decode.field "last_seen" Decode.int))
        (Decode.oneOf
            [ Decode.field "tags" Decode.value
            , Decode.succeed Encode.null
            ]
        )
        |> andMap
            (Decode.oneOf
                [ Decode.field "users" (Decode.list Decode.string)
                , Decode.succeed []
                ]
            )


{-| Pipeline-style helper to apply an additional decoder when map8 is not enough.
-}
andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap valDecoder funcDecoder =
    Decode.map2 (\f v -> f v) funcDecoder valDecoder
