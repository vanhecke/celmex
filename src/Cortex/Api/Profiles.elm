module Cortex.Api.Profiles exposing
    ( GetPolicyResponse
    , getPolicy
    , getProfiles
    )

import Cortex.Decode exposing (reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| POST /public\_api/v1/endpoints/get\_profiles

Get endpoint security profiles of the requested type. The API requires
a `type` discriminator (`"prevention"` or `"extension"`); pass it via
the record argument.

Profile rows carry per-module configuration whose shape varies by profile
type and platform, so they are returned as raw JSON to capture every field
the tenant returns.

-}
getProfiles : { type_ : String } -> Request (List Encode.Value)
getProfiles { type_ } =
    Request.post
        [ "public_api", "v1", "endpoints", "get_profiles" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object [ ( "type", Encode.string type_ ) ]
              )
            ]
        )
        (reply (Decode.list Decode.value))


type alias GetPolicyResponse =
    { policyName : Maybe String
    }


{-| POST /public\_api/v1/endpoints/get\_policy

Get the policy name assigned to a single endpoint. Requires the endpoint
ID; pass it via the record argument.

-}
getPolicy : { endpointId : String } -> Request GetPolicyResponse
getPolicy { endpointId } =
    Request.post
        [ "public_api", "v1", "endpoints", "get_policy" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object [ ( "endpoint_id", Encode.string endpointId ) ]
              )
            ]
        )
        (reply getPolicyResponseDecoder)


getPolicyResponseDecoder : Decoder GetPolicyResponse
getPolicyResponseDecoder =
    Decode.map GetPolicyResponse
        (Decode.maybe (Decode.field "policy_name" Decode.string))
