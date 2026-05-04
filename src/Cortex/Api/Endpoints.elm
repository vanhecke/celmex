module Cortex.Api.Endpoints exposing
    ( SearchArgs, defaultSearchArgs
    , Endpoint, EndpointTags, ListResponse
    , EndpointDetail, OperationalStatusDetail, GetEndpointArgs, GetEndpointResponse
    , list
    , getEndpoint
    )

{-| Cortex endpoint inventory.

@docs SearchArgs, defaultSearchArgs
@docs Endpoint, EndpointTags, ListResponse
@docs EndpointDetail, OperationalStatusDetail, GetEndpointArgs, GetEndpointResponse
@docs list
@docs getEndpoint

-}

import Cortex.Decode exposing (andMap, optionalField, optionalList, reply)
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


{-| Arguments to [`getEndpoint`](#getEndpoint). Pass one or more agent IDs
in `endpointIdList`; the API returns a `Response` containing the matching
endpoints. Any other Cortex filter fields are appended via `extraFilters`
(each entry is `(field, operator, value)`); leave empty for the common case.
-}
type alias GetEndpointArgs =
    { endpointIdList : List String
    , extraFilters : List ( String, String, Encode.Value )
    }


{-| Envelope returned by [`getEndpoint`](#getEndpoint). The `endpoints`
list carries the rich [`EndpointDetail`](#EndpointDetail) shape, which is
strictly richer than the [`Endpoint`](#Endpoint) shape returned by
[`list`](#list).
-}
type alias GetEndpointResponse =
    { totalCount : Maybe Int
    , resultCount : Maybe Int
    , endpoints : List EndpointDetail
    }


{-| One endpoint as returned by `/public_api/v1/endpoints/get_endpoint`.
The wire shape is much richer than the `Endpoint` returned by `list` —
fields use the `endpoint_*` namespace rather than `agent_*`, and the
record carries OS, network, install, policy, content, and cloud
metadata not present in the list response.
-}
type alias EndpointDetail =
    { endpointId : String
    , endpointName : Maybe String
    , endpointType : Maybe String
    , endpointStatus : Maybe String
    , osType : Maybe String
    , osVersion : Maybe String
    , ip : List String
    , ipv6 : List String
    , publicIp : Maybe String
    , users : List String
    , domain : Maybe String
    , alias_ : Maybe String
    , firstSeen : Maybe Int
    , lastSeen : Maybe Int
    , contentVersion : Maybe String
    , installationPackage : Maybe String
    , activeDirectory : List String
    , installDate : Maybe Int
    , endpointVersion : Maybe String
    , isIsolated : Maybe String
    , isolatedDate : Maybe Int
    , groupName : List String
    , operationalStatus : Maybe String
    , operationalStatusDescription : Maybe String
    , operationalStatusDetails : List OperationalStatusDetail
    , scanStatus : Maybe String
    , contentReleaseTimestamp : Maybe Int
    , lastContentUpdateTime : Maybe Int
    , operatingSystem : Maybe String
    , macAddress : List String
    , assignedPreventionPolicy : Maybe String
    , assignedExtensionsPolicy : Maybe String
    , tokenHash : Maybe String
    , tags : Maybe EndpointTags
    , cloudProvider : Maybe String
    , cloudRegion : Maybe String
    , cloudProviderAccountId : Maybe String
    , cloudInstanceId : Maybe String
    , cloudId : Maybe String
    , contentStatus : Maybe String
    }


{-| One row of [`EndpointDetail.operationalStatusDetails`](#EndpointDetail).
A title + reason pair describing one operational caveat (e.g. "File
search and destroy status" / "Module is partially disabled by Adaptive
Policy due to high resource consumption").
-}
type alias OperationalStatusDetail =
    { title : Maybe String
    , reason : Maybe String
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


{-| POST /public\_api/v1/endpoints/get\_endpoint

Retrieve detailed information about one or more endpoints by agent ID.
The response shape is much richer than [`list`](#list)'s — see
[`EndpointDetail`](#EndpointDetail) for the full field set.

-}
getEndpoint : GetEndpointArgs -> Request GetEndpointResponse
getEndpoint args =
    let
        idFilter =
            Encode.object
                [ ( "field", Encode.string "endpoint_id_list" )
                , ( "operator", Encode.string "in" )
                , ( "value", Encode.list Encode.string args.endpointIdList )
                ]

        encodeExtra ( field, operator, value ) =
            Encode.object
                [ ( "field", Encode.string field )
                , ( "operator", Encode.string operator )
                , ( "value", value )
                ]

        filters =
            idFilter :: List.map encodeExtra args.extraFilters
    in
    Request.post
        [ "public_api", "v1", "endpoints", "get_endpoint" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object [ ( "filters", Encode.list identity filters ) ]
              )
            ]
        )
        (reply getEndpointResponseDecoder)



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


getEndpointResponseDecoder : Decoder GetEndpointResponse
getEndpointResponseDecoder =
    Decode.map3 GetEndpointResponse
        (optionalField "total_count" Decode.int)
        (optionalField "result_count" Decode.int)
        (Decode.oneOf
            [ Decode.field "endpoints" (Decode.list endpointDetailDecoder)
            , Decode.succeed []
            ]
        )


endpointDetailDecoder : Decoder EndpointDetail
endpointDetailDecoder =
    Decode.succeed EndpointDetail
        |> andMap (Decode.field "endpoint_id" Decode.string)
        |> andMap (optionalField "endpoint_name" Decode.string)
        |> andMap (optionalField "endpoint_type" Decode.string)
        |> andMap (optionalField "endpoint_status" Decode.string)
        |> andMap (optionalField "os_type" Decode.string)
        |> andMap (optionalField "os_version" Decode.string)
        |> andMap (optionalList "ip" Decode.string)
        |> andMap (optionalList "ipv6" Decode.string)
        |> andMap (optionalField "public_ip" Decode.string)
        |> andMap (optionalList "users" Decode.string)
        |> andMap (optionalField "domain" Decode.string)
        |> andMap (optionalField "alias" Decode.string)
        |> andMap (optionalField "first_seen" Decode.int)
        |> andMap (optionalField "last_seen" Decode.int)
        |> andMap (optionalField "content_version" Decode.string)
        |> andMap (optionalField "installation_package" Decode.string)
        |> andMap (optionalList "active_directory" Decode.string)
        |> andMap (optionalField "install_date" Decode.int)
        |> andMap (optionalField "endpoint_version" Decode.string)
        |> andMap (optionalField "is_isolated" Decode.string)
        |> andMap (optionalField "isolated_date" Decode.int)
        |> andMap (optionalList "group_name" Decode.string)
        |> andMap (optionalField "operational_status" Decode.string)
        |> andMap (optionalField "operational_status_description" Decode.string)
        |> andMap (optionalList "operational_status_details" operationalStatusDetailDecoder)
        |> andMap (optionalField "scan_status" Decode.string)
        |> andMap (optionalField "content_release_timestamp" Decode.int)
        |> andMap (optionalField "last_content_update_time" Decode.int)
        |> andMap (optionalField "operating_system" Decode.string)
        |> andMap (optionalList "mac_address" Decode.string)
        |> andMap (optionalField "assigned_prevention_policy" Decode.string)
        |> andMap (optionalField "assigned_extensions_policy" Decode.string)
        |> andMap (optionalField "token_hash" Decode.string)
        |> andMap (optionalField "tags" endpointTagsDecoder)
        |> andMap (optionalField "cloud_provider" Decode.string)
        |> andMap (optionalField "cloud_region" Decode.string)
        |> andMap (optionalField "cloud_provider_account_id" Decode.string)
        |> andMap (optionalField "cloud_instance_id" Decode.string)
        |> andMap (optionalField "cloud_id" Decode.string)
        |> andMap (optionalField "content_status" Decode.string)


operationalStatusDetailDecoder : Decoder OperationalStatusDetail
operationalStatusDetailDecoder =
    Decode.map2 OperationalStatusDetail
        (optionalField "title" Decode.string)
        (optionalField "reason" Decode.string)
