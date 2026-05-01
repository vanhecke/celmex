module Cortex.Api.AuthSettings exposing
    ( AuthSetting, Mappings, AdvancedSettings
    , get
    )

{-| Cortex tenant IdP/SSO authentication settings.

The `/public_api/v1/authentication-settings/get/settings` endpoint returns
a list of [`AuthSetting`](#AuthSetting) records — one per configured IdP /
domain. Most fields are `Maybe` because populated content varies sharply:
a tenant without SSO configured returns only the SP-side URLs, while a
fully-configured SAML integration populates the full IdP certificate,
issuer, SSO URL, and attribute mappings.

@docs AuthSetting, Mappings, AdvancedSettings
@docs get

-}

import Cortex.Decode exposing (andMap, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| One authentication-settings entry — typically one per configured IdP.
-}
type alias AuthSetting =
    { tenantId : Maybe String
    , name : Maybe String
    , domain : Maybe String
    , idpEnabled : Maybe Bool

    {- defaultRole / isAccountRole are spec'd as `nullable: true` with no
       declared type — the API may emit any JSON shape (string, object,
       null) depending on the role configuration. Preserved verbatim so
       downstream consumers can interpret per-tenant.
    -}
    , defaultRole : Maybe Encode.Value
    , isAccountRole : Maybe Encode.Value
    , idpCertificate : Maybe String
    , idpIssuer : Maybe String
    , idpSsoUrl : Maybe String
    , metadataUrl : Maybe String
    , mappings : Maybe Mappings
    , advancedSettings : Maybe AdvancedSettings
    , spEntityId : Maybe String
    , spLogoutUrl : Maybe String
    , spUrl : Maybe String
    }


{-| SAML attribute → Cortex field mappings used to populate user records
during SSO login.
-}
type alias Mappings =
    { email : Maybe String
    , firstname : Maybe String
    , groupName : Maybe String
    , lastname : Maybe String
    }


{-| Advanced SAML/SP configuration. Optional sub-record under each
[`AuthSetting`](#AuthSetting).
-}
type alias AdvancedSettings =
    { authnContextEnabled : Maybe Bool

    {- forceAuthn is spec'd as `nullable: true` with no type — preserved
       verbatim because the populated shape varies per IdP.
    -}
    , forceAuthn : Maybe Encode.Value
    , idpSingleLogoutUrl : Maybe String
    , relayState : Maybe String
    , serviceProviderPrivateKey : Maybe String
    , serviceProviderPublicCert : Maybe String
    }


{-| POST /public\_api/v1/authentication-settings/get/settings

Get all the authentication settings for every configured domain on the
tenant. Requires Instance Administrator permissions.

-}
get : Request (List AuthSetting)
get =
    Request.postEmpty
        [ "public_api", "v1", "authentication-settings", "get", "settings" ]
        decoder



-- DECODERS


decoder : Decoder (List AuthSetting)
decoder =
    Decode.oneOf
        [ reply (Decode.list authSettingDecoder)
        , Decode.succeed []
        ]


authSettingDecoder : Decoder AuthSetting
authSettingDecoder =
    Decode.succeed AuthSetting
        |> andMap (optionalField "tenant_id" Decode.string)
        |> andMap (optionalField "name" Decode.string)
        |> andMap (optionalField "domain" Decode.string)
        |> andMap (optionalField "idp_enabled" Decode.bool)
        |> andMap (optionalField "default_role" Decode.value)
        |> andMap (optionalField "is_account_role" Decode.value)
        |> andMap (optionalField "idp_certificate" Decode.string)
        |> andMap (optionalField "idp_issuer" Decode.string)
        |> andMap (optionalField "idp_sso_url" Decode.string)
        |> andMap (optionalField "metadata_url" Decode.string)
        |> andMap (optionalField "mappings" mappingsDecoder)
        |> andMap (optionalField "advanced_settings" advancedSettingsDecoder)
        |> andMap (optionalField "sp_entity_id" Decode.string)
        |> andMap (optionalField "sp_logout_url" Decode.string)
        |> andMap (optionalField "sp_url" Decode.string)


mappingsDecoder : Decoder Mappings
mappingsDecoder =
    Decode.map4 Mappings
        (optionalField "email" Decode.string)
        (optionalField "firstname" Decode.string)
        (optionalField "group_name" Decode.string)
        (optionalField "lastname" Decode.string)


advancedSettingsDecoder : Decoder AdvancedSettings
advancedSettingsDecoder =
    Decode.map6 AdvancedSettings
        (optionalField "authn_context_enabled" Decode.bool)
        (optionalField "force_authn" Decode.value)
        (optionalField "idp_single_logout_url" Decode.string)
        (optionalField "relay_state" Decode.string)
        (optionalField "service_provider_private_key" Decode.string)
        (optionalField "service_provider_public_cert" Decode.string)


optionalField : String -> Decoder a -> Decoder (Maybe a)
optionalField name d =
    Decode.maybe (Decode.field name d)
