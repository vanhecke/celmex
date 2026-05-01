module Cortex.Api.TenantInfo exposing
    ( TenantInfo, Expiration(..)
    , PurchasedXsiamPremium, PurchasedAgents, PurchasedGb, PurchasedUsers, PurchasedWorkloads
    , get
    )

{-| Cortex tenant license, SKU, and add-on metadata.

The response from `/public_api/v1/system/get_tenant_info` is a wide record
of license expiration timestamps, installed/purchased counts, and nested
"purchased" sub-records describing each add-on. Every field is optional —
which fields are populated depends on the tenant's product mix.

Two notable wire-format quirks this module handles:

  - **Polymorphic expirations.** `*_expiration` fields are sometimes
    returned as the integer `0` (the add-on is not purchased), sometimes
    as a positive integer (a unix-epoch timestamp), and sometimes as a
    pre-formatted date string (e.g. `"Mar 19th 2027 23:59:59"`). Decoded
    into the [`Expiration`](#Expiration) union.

  - **Polymorphic `purchased_*` shapes.** Most `purchased_*` fields can
    be either the integer `0` (not purchased) or a small nested record
    listing the purchased capacity (`{ "users": 100, "gb": 100, ... }`).
    Decoded as `Maybe SomePurchasedShape` where `Nothing` covers both
    "field absent" and "integer 0".

@docs TenantInfo, Expiration
@docs PurchasedXsiamPremium, PurchasedAgents, PurchasedGb, PurchasedUsers, PurchasedWorkloads
@docs get

-}

import Cortex.Decode exposing (andMap, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)


{-| Full tenant licensing/configuration record. Every field is `Maybe` —
the API only emits fields relevant to the tenant's purchased products,
and field coverage varies between tenants and SKUs.
-}
type alias TenantInfo =
    { -- license expirations (polymorphic int | string per tenant)
      advancedAnalyticsExpiration : Maybe Expiration
    , agentixSoarExpiration : Maybe Expiration
    , agentixTimExpiration : Maybe Expiration
    , attackSurfaceManagementExpiration : Maybe Expiration
    , cloudPostureExpiration : Maybe Expiration
    , computeUnitExpiration : Maybe Expiration
    , dataLakeGbExpiration : Maybe Expiration
    , forensicsExpiration : Maybe Expiration
    , hostInsightsExpiration : Maybe Expiration
    , identityThreatExpiration : Maybe Expiration
    , preventExpiration : Maybe Expiration
    , proCloudExpiration : Maybe Expiration
    , proGbExpiration : Maybe Expiration
    , proPerEndpointExpiration : Maybe Expiration
    , threatIntelligenceManagementExpiration : Maybe Expiration
    , xsiamEpColdExpiration : Maybe Expiration
    , xsiamEpHotExpiration : Maybe Expiration
    , xsiamGbColdExpiration : Maybe Expiration
    , xsiamGbHotExpiration : Maybe Expiration
    , xsiamPremiumExpiration : Maybe Expiration
    , xthExpiration : Maybe Expiration

    -- enabled / installed / data-enabled counters
    , dataEnabledProCloud : Maybe Int
    , dataEnabledProPerEndpoint : Maybe Int
    , enabledForensics : Maybe Int
    , enabledHostInsights : Maybe Int
    , installedAgentixSoar : Maybe Int
    , installedAgentixTim : Maybe Int
    , installedCloudPosture : Maybe Int
    , installedDataLakeGb : Maybe Int
    , installedPrevent : Maybe Int
    , installedProCloud : Maybe Int
    , installedProGb : Maybe Int

    -- pure-integer purchased counts
    , purchasedAttackSurfaceManagement : Maybe Int
    , purchasedComputeUnit : Maybe Int
    , purchasedHostInsights : Maybe Int
    , purchasedPrevent : Maybe Int
    , purchasedThreatIntelligenceManagement : Maybe Int
    , purchasedXsiamEpCold : Maybe Int
    , purchasedXsiamEpHot : Maybe Int
    , purchasedXsiamGbCold : Maybe Int
    , purchasedXsiamGbHot : Maybe Int
    , purchasedXth : Maybe Int

    -- nested purchased records (Nothing = not purchased)
    , purchasedAgentixSoar : Maybe PurchasedUsers
    , purchasedAgentixTim : Maybe PurchasedUsers
    , purchasedCloudPosture : Maybe PurchasedWorkloads
    , purchasedDataLakeGb : Maybe PurchasedGb
    , purchasedProCloud : Maybe PurchasedAgents
    , purchasedProGb : Maybe PurchasedGb
    , purchasedProPerEndpoint : Maybe PurchasedAgents
    , purchasedXsiamPremium : Maybe PurchasedXsiamPremium
    }


{-| A license expiration as the API actually emits it.

  - `Disabled` — wire integer `0` (the add-on is not purchased).
  - `Timestamp` — wire positive integer (unix-epoch millis or seconds).
  - `DateString` — wire pre-formatted string (e.g. `"Mar 19th 2027 23:59:59"`).

-}
type Expiration
    = Disabled
    | Timestamp Int
    | DateString String


{-| `purchased_xsiam_premium` capacity breakdown.
-}
type alias PurchasedXsiamPremium =
    { users : Maybe Int
    , gb : Maybe Int
    , agents : Maybe Int
    }


{-| `purchased_pro_cloud` / `purchased_pro_per_endpoint` capacity.
-}
type alias PurchasedAgents =
    { agents : Maybe Int
    }


{-| `purchased_pro_gb` / `purchased_data_lake_gb` capacity.
-}
type alias PurchasedGb =
    { gb : Maybe Int
    }


{-| `purchased_agentix_soar` / `purchased_agentix_tim` capacity.
-}
type alias PurchasedUsers =
    { users : Maybe Int
    }


{-| `purchased_cloud_posture` capacity.
-}
type alias PurchasedWorkloads =
    { workloads : Maybe Int
    }


{-| POST /public\_api/v1/system/get\_tenant\_info

Retrieve license, SKU, and add-on metadata for the tenant. Response is
wrapped in the `reply` envelope; this function unwraps it and decodes
into [`TenantInfo`](#TenantInfo).

-}
get : Request TenantInfo
get =
    Request.postEmpty
        [ "public_api", "v1", "system", "get_tenant_info" ]
        decoder



-- DECODERS


decoder : Decoder TenantInfo
decoder =
    reply tenantInfoDecoder


tenantInfoDecoder : Decoder TenantInfo
tenantInfoDecoder =
    Decode.succeed TenantInfo
        |> andMap (expirationField "advanced_analytics_expiration")
        |> andMap (expirationField "agentix_soar_expiration")
        |> andMap (expirationField "agentix_tim_expiration")
        |> andMap (expirationField "attack_surface_management_expiration")
        |> andMap (expirationField "cloud_posture_expiration")
        |> andMap (expirationField "compute_unit_expiration")
        |> andMap (expirationField "data_lake_gb_expiration")
        |> andMap (expirationField "forensics_expiration")
        |> andMap (expirationField "host_insights_expiration")
        |> andMap (expirationField "identity_threat_expiration")
        |> andMap (expirationField "prevent_expiration")
        |> andMap (expirationField "pro_cloud_expiration")
        |> andMap (expirationField "pro_gb_expiration")
        |> andMap (expirationField "pro_per_endpoint_expiration")
        |> andMap (expirationField "threat_intelligence_management_expiration")
        |> andMap (expirationField "xsiam_ep_cold_expiration")
        |> andMap (expirationField "xsiam_ep_hot_expiration")
        |> andMap (expirationField "xsiam_gb_cold_expiration")
        |> andMap (expirationField "xsiam_gb_hot_expiration")
        |> andMap (expirationField "xsiam_premium_expiration")
        |> andMap (expirationField "xth_expiration")
        |> andMap (intField "data_enabled_pro_cloud")
        |> andMap (intField "data_enabled_pro_per_endpoint")
        |> andMap (intField "enabled_forensics")
        |> andMap (intField "enabled_host_insights")
        |> andMap (intField "installed_agentix_soar")
        |> andMap (intField "installed_agentix_tim")
        |> andMap (intField "installed_cloud_posture")
        |> andMap (intField "installed_data_lake_gb")
        |> andMap (intField "installed_prevent")
        |> andMap (intField "installed_pro_cloud")
        |> andMap (intField "installed_pro_gb")
        |> andMap (intField "purchased_attack_surface_management")
        |> andMap (intField "purchased_compute_unit")
        |> andMap (intField "purchased_host_insights")
        |> andMap (intField "purchased_prevent")
        |> andMap (intField "purchased_threat_intelligence_management")
        |> andMap (intField "purchased_xsiam_ep_cold")
        |> andMap (intField "purchased_xsiam_ep_hot")
        |> andMap (intField "purchased_xsiam_gb_cold")
        |> andMap (intField "purchased_xsiam_gb_hot")
        |> andMap (intField "purchased_xth")
        |> andMap (purchaseField "purchased_agentix_soar" purchasedUsersDecoder)
        |> andMap (purchaseField "purchased_agentix_tim" purchasedUsersDecoder)
        |> andMap (purchaseField "purchased_cloud_posture" purchasedWorkloadsDecoder)
        |> andMap (purchaseField "purchased_data_lake_gb" purchasedGbDecoder)
        |> andMap (purchaseField "purchased_pro_cloud" purchasedAgentsDecoder)
        |> andMap (purchaseField "purchased_pro_gb" purchasedGbDecoder)
        |> andMap (purchaseField "purchased_pro_per_endpoint" purchasedAgentsDecoder)
        |> andMap (purchaseField "purchased_xsiam_premium" purchasedXsiamPremiumDecoder)


expirationField : String -> Decoder (Maybe Expiration)
expirationField name =
    Decode.maybe (Decode.field name expirationDecoder)


expirationDecoder : Decoder Expiration
expirationDecoder =
    Decode.oneOf
        [ Decode.int
            |> Decode.map
                (\n ->
                    if n == 0 then
                        Disabled

                    else
                        Timestamp n
                )
        , Decode.string |> Decode.map DateString
        ]


intField : String -> Decoder (Maybe Int)
intField name =
    Decode.maybe (Decode.field name Decode.int)


{-| Decode a `purchased_*` field that may be either integer `0`
(not purchased) or a nested record (purchased, with details).
Collapses both "field absent" and "integer 0" to `Nothing`.
-}
purchaseField : String -> Decoder a -> Decoder (Maybe a)
purchaseField name objDecoder =
    Decode.maybe
        (Decode.field name
            (Decode.oneOf
                [ Decode.int |> Decode.map (always Nothing)
                , Decode.map Just objDecoder
                ]
            )
        )
        |> Decode.map (Maybe.withDefault Nothing)


purchasedXsiamPremiumDecoder : Decoder PurchasedXsiamPremium
purchasedXsiamPremiumDecoder =
    Decode.map3 PurchasedXsiamPremium
        (Decode.maybe (Decode.field "users" Decode.int))
        (Decode.maybe (Decode.field "gb" Decode.int))
        (Decode.maybe (Decode.field "agents" Decode.int))


purchasedAgentsDecoder : Decoder PurchasedAgents
purchasedAgentsDecoder =
    Decode.map PurchasedAgents
        (Decode.maybe (Decode.field "agents" Decode.int))


purchasedGbDecoder : Decoder PurchasedGb
purchasedGbDecoder =
    Decode.map PurchasedGb
        (Decode.maybe (Decode.field "gb" Decode.int))


purchasedUsersDecoder : Decoder PurchasedUsers
purchasedUsersDecoder =
    Decode.map PurchasedUsers
        (Decode.maybe (Decode.field "users" Decode.int))


purchasedWorkloadsDecoder : Decoder PurchasedWorkloads
purchasedWorkloadsDecoder =
    Decode.map PurchasedWorkloads
        (Decode.maybe (Decode.field "workloads" Decode.int))
