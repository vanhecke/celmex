module Cli.Encode.Endpoints exposing (encode)

import Cortex.Api.Endpoints exposing (Endpoint, ListResponse)
import Json.Encode as Encode


encode : ListResponse -> Encode.Value
encode response =
    Encode.object
        [ ( "endpoints", Encode.list encodeEndpoint response.endpoints )
        ]


encodeEndpoint : Endpoint -> Encode.Value
encodeEndpoint ep =
    Encode.object
        (List.filterMap identity
            [ Just ( "agent_id", Encode.string ep.agentId )
            , Maybe.map (\v -> ( "agent_status", Encode.string v )) ep.agentStatus
            , Maybe.map (\v -> ( "operational_status", Encode.string v )) ep.operationalStatus
            , Maybe.map (\v -> ( "host_name", Encode.string v )) ep.hostName
            , Maybe.map (\v -> ( "agent_type", Encode.string v )) ep.agentType
            , Just ( "ip", Encode.list Encode.string ep.ip )
            , Maybe.map (\v -> ( "last_seen", Encode.int v )) ep.lastSeen
            , Just ( "tags", ep.tags )
            , Just ( "users", Encode.list Encode.string ep.users )
            ]
        )
