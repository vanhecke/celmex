module Cortex.Api.Risk exposing
    ( RiskScoreResponse
    , getRiskScore
    , getRiskyHosts
    , getRiskyUsers
    )

import Cortex.Decode exposing (optionalList, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias RiskScoreResponse =
    { type_ : Maybe String
    , id : Maybe String
    , score : Maybe Int
    , normRiskScore : Maybe Int
    , riskLevel : Maybe String
    , reasons : List Encode.Value
    , email : Maybe String
    }


{-| POST /public\_api/v1/get\_risk\_score

Get the risk score for a single user or endpoint. The API requires `id`
(user samAccount in `netBIOS/samAccount` form, or a Cortex agent ID); pass
it via the record argument.

-}
getRiskScore : { id : String } -> Request RiskScoreResponse
getRiskScore { id } =
    Request.post
        [ "public_api", "v1", "get_risk_score" ]
        (Encode.object
            [ ( "request_data"
              , Encode.object [ ( "id", Encode.string id ) ]
              )
            ]
        )
        (reply riskScoreDecoder)


riskScoreDecoder : Decoder RiskScoreResponse
riskScoreDecoder =
    Decode.map7 RiskScoreResponse
        (Decode.maybe (Decode.field "type" Decode.string))
        (Decode.maybe (Decode.field "id" Decode.string))
        (Decode.maybe (Decode.field "score" Decode.int))
        (Decode.maybe (Decode.field "norm_risk_score" Decode.int))
        (Decode.maybe (Decode.field "risk_level" Decode.string))
        (optionalList "reasons" Decode.value)
        (Decode.maybe (Decode.field "email" Decode.string))


{-| POST /public\_api/v1/get\_risky\_users

Returns the highest-risk users on the tenant. The per-row records mix typed
fields with a nested `reasons` list whose objects use spaced keys like
`"date created"`; rows are preserved as raw JSON to capture every field.

-}
getRiskyUsers : Request (List Encode.Value)
getRiskyUsers =
    Request.post
        [ "public_api", "v1", "get_risky_users" ]
        (Encode.object [])
        (reply (Decode.list Decode.value))


{-| POST /public\_api/v1/get\_risky\_hosts
-}
getRiskyHosts : Request (List Encode.Value)
getRiskyHosts =
    Request.post
        [ "public_api", "v1", "get_risky_hosts" ]
        (Encode.object [])
        (reply (Decode.list Decode.value))
