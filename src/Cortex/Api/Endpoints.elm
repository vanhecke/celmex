module Cortex.Api.Endpoints exposing
    ( SearchArgs, defaultSearchArgs
    , Endpoint, EndpointTags, ListResponse
    , list
    )

{-| Cortex endpoint inventory.

@docs SearchArgs, defaultSearchArgs
@docs Endpoint, EndpointTags, ListResponse
@docs list

-}

import Cortex.Decode exposing (andMap, optionalList, reply)
import Cortex.Query as Query exposing (Filter, Range, Sort, Timeframe)
import Cortex.Request as Request exposing (Request)
import Cortex.RequestData as RequestData
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Arguments to [`list`](#list). All fields are optional; pass
[`defaultSearchArgs`](#defaultSearchArgs) for an unfiltered request. `extra`
is merged last into `request_data` and overrides any SDK-generated key on
collision.
-}
type alias SearchArgs =
    { filters : List Filter
    , sort : Maybe Sort
    , range : Maybe Range
    , timeframe : Maybe Timeframe
    , extra : List ( String, Encode.Value )
    }


{-| A [`SearchArgs`](#SearchArgs) with no filters, sort, pagination, or
timeframe — equivalent to listing every endpoint on the tenant.
-}
defaultSearchArgs : SearchArgs
defaultSearchArgs =
    { filters = []
    , sort = Nothing
    , range = Nothing
    , timeframe = Nothing
    , extra = []
    }


{-| Envelope wrapping the endpoint list returned by [`list`](#list).
-}
type alias ListResponse =
    { endpoints : List Endpoint
    }


{-| A single Cortex endpoint (managed host running an agent).
-}
type alias Endpoint =
    { agentId : String
    , agentStatus : Maybe String
    , operationalStatus : Maybe String
    , hostName : Maybe String
    , agentType : Maybe String
    , ip : List String
    , lastSeen : Maybe Int
    , tags : Maybe EndpointTags
    , users : List String
    }


{-| The two tag buckets attached to an [`Endpoint`](#Endpoint) — one for
server-applied tags and one for endpoint-applied tags. The wire format
emits each as a list of strings (the spec's `items: { type: object }` is
looser than the live response).
-}
type alias EndpointTags =
    { serverTags : List String
    , endpointTags : List String
    }


{-| POST /public\_api/v1/endpoints/get\_endpoints

Retrieve a filtered list of endpoints (agents) on the tenant. Response uses
the `reply` envelope containing a flat array.

-}
list : SearchArgs -> Request ListResponse
list args =
    Request.post
        [ "public_api", "v1", "endpoints", "get_endpoints" ]
        (RequestData.encode Query.standard
            { filters = args.filters
            , sort = args.sort
            , range = args.range
            , timeframe = args.timeframe
            , extra = args.extra
            }
        )
        listResponseDecoder



-- DECODERS


listResponseDecoder : Decoder ListResponse
listResponseDecoder =
    reply (Decode.list endpointDecoder)
        |> Decode.map ListResponse


endpointDecoder : Decoder Endpoint
endpointDecoder =
    Decode.succeed Endpoint
        |> andMap (Decode.field "agent_id" Decode.string)
        |> andMap (Decode.maybe (Decode.field "agent_status" Decode.string))
        |> andMap (Decode.maybe (Decode.field "operational_status" Decode.string))
        |> andMap (Decode.maybe (Decode.field "host_name" Decode.string))
        |> andMap (Decode.maybe (Decode.field "agent_type" Decode.string))
        |> andMap (optionalList "ip" Decode.string)
        |> andMap (Decode.maybe (Decode.field "last_seen" Decode.int))
        |> andMap (Decode.maybe (Decode.field "tags" endpointTagsDecoder))
        |> andMap (optionalList "users" Decode.string)


endpointTagsDecoder : Decoder EndpointTags
endpointTagsDecoder =
    Decode.map2 EndpointTags
        (optionalList "server_tags" Decode.string)
        (optionalList "endpoint_tags" Decode.string)
