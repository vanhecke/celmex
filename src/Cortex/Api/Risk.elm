module Cortex.Api.Risk exposing
    ( RiskScoreResponse, RiskyEntity, Reason
    , getRiskScore, listRiskyHosts, listRiskyUsers
    )

{-| Cortex identity-threat risk scoring for users and endpoints.

@docs RiskScoreResponse, RiskyEntity, Reason
@docs getRiskScore, listRiskyHosts, listRiskyUsers

-}

import Cortex.Decode exposing (optionalList, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Risk-score record for a single user or endpoint, returned by
[`getRiskScore`](#getRiskScore).
-}
type alias RiskScoreResponse =
    { type_ : Maybe String
    , id : Maybe String
    , score : Maybe Int
    , normRiskScore : Maybe Int
    , riskLevel : Maybe String
    , reasons : List Reason
    , email : Maybe String
    }


{-| One risky-user / risky-host entry returned by
[`listRiskyUsers`](#listRiskyUsers) / [`listRiskyHosts`](#listRiskyHosts).
Shape matches [`RiskScoreResponse`](#RiskScoreResponse) — `email` is
populated for user entries only.
-}
type alias RiskyEntity =
    { type_ : Maybe String
    , id : Maybe String
    , score : Maybe Int
    , normRiskScore : Maybe Int
    , riskLevel : Maybe String
    , reasons : List Reason
    , email : Maybe String
    }


{-| One reason contributing to a risk score. Note `dateCreated` decodes
from the spec's `"date created"` (with a space).
-}
type alias Reason =
    { dateCreated : Maybe String
    , description : Maybe String
    , severity : Maybe String
    , status : Maybe String
    , points : Maybe Int
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


{-| POST /public\_api/v1/get\_risky\_users

Returns the highest-risk users on the tenant.

-}
listRiskyUsers : Request (List RiskyEntity)
listRiskyUsers =
    Request.post
        [ "public_api", "v1", "get_risky_users" ]
        (Encode.object [])
        (reply (Decode.list riskyEntityDecoder))


{-| POST /public\_api/v1/get\_risky\_hosts

Returns the highest-risk endpoints on the tenant.

-}
listRiskyHosts : Request (List RiskyEntity)
listRiskyHosts =
    Request.post
        [ "public_api", "v1", "get_risky_hosts" ]
        (Encode.object [])
        (reply (Decode.list riskyEntityDecoder))



-- DECODERS


riskScoreDecoder : Decoder RiskScoreResponse
riskScoreDecoder =
    Decode.map7 RiskScoreResponse
        (Decode.maybe (Decode.field "type" Decode.string))
        (Decode.maybe (Decode.field "id" Decode.string))
        (Decode.maybe (Decode.field "score" Decode.int))
        (Decode.maybe (Decode.field "norm_risk_score" Decode.int))
        (Decode.maybe (Decode.field "risk_level" Decode.string))
        (optionalList "reasons" reasonDecoder)
        (Decode.maybe (Decode.field "email" Decode.string))


riskyEntityDecoder : Decoder RiskyEntity
riskyEntityDecoder =
    Decode.map7 RiskyEntity
        (Decode.maybe (Decode.field "type" Decode.string))
        (Decode.maybe (Decode.field "id" Decode.string))
        (Decode.maybe (Decode.field "score" Decode.int))
        (Decode.maybe (Decode.field "norm_risk_score" Decode.int))
        (Decode.maybe (Decode.field "risk_level" Decode.string))
        (optionalList "reasons" reasonDecoder)
        (Decode.maybe (Decode.field "email" Decode.string))


reasonDecoder : Decoder Reason
reasonDecoder =
    Decode.map5 Reason
        (Decode.maybe (Decode.field "date created" Decode.string))
        (Decode.maybe (Decode.field "description" Decode.string))
        (Decode.maybe (Decode.field "severity" Decode.string))
        (Decode.maybe (Decode.field "status" Decode.string))
        (Decode.maybe (Decode.field "points" Decode.int))
