module Cortex.Api.AuthSettings exposing
    ( AuthSetting, Mappings, AdvancedSettings
    , Metadata
    , get
    , getMetadata
    )

{-| Cortex tenant IdP/SSO authentication settings.

The `/public_api/v1/authentication-settings/get/settings` endpoint returns
a list of [`AuthSetting`](#AuthSetting) records — one per configured IdP /
domain. Most fields are `Maybe` because populated content varies sharply:
a tenant without SSO configured returns only the SP-side URLs, while a
fully-configured SAML integration populates the full IdP certificate,
issuer, SSO URL, and attribute mappings.

The `/public_api/v1/authentication-settings/get/metadata` endpoint returns
the much smaller [`Metadata`](#Metadata) record — the four service-provider
URLs an external IdP needs in order to register the tenant as a SAML
service provider.

@docs AuthSetting, Mappings, AdvancedSettings
@docs Metadata
@docs get
@docs getMetadata

-}

import Cortex.Decode exposing (andMap, optionalField, reply)
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


{-| Service-provider metadata returned by [`getMetadata`](#getMetadata) —
the four URLs an external IdP needs in order to register the tenant as a
SAML service provider. The shape is much smaller than [`AuthSetting`](#AuthSetting):
no IdP-side fields, no mappings, no advanced settings.
-}
type alias Metadata =
    { tenantId : Maybe String
    , spEntityId : Maybe String
    , spUrl : Maybe String
    , spLogoutUrl : Maybe String
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


{-| POST /public\_api/v1/authentication-settings/get/metadata

Get the tenant's SAML service-provider metadata — the four URLs and
identifiers an external IdP needs in order to federate against this
tenant. Requires Instance Administrator permissions.

-}
getMetadata : Request Metadata
getMetadata =
    Request.postEmpty
        [ "public_api", "v1", "authentication-settings", "get", "metadata" ]
        (reply metadataDecoder)



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
        {- Decoder escape: IdP-specific role assignment value; shape varies
           per identity provider (string/object/array) and is opaque to the SDK.
        -}
        |> andMap (optionalField "default_role" Decode.value)
        {- Decoder escape: IdP-specific role-account discriminator; shape
           varies per identity provider and is opaque to the SDK.
        -}
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


metadataDecoder : Decoder Metadata
metadataDecoder =
    Decode.map4 Metadata
        (optionalField "tenant_id" Decode.string)
        (optionalField "sp_entity_id" Decode.string)
        (optionalField "sp_url" Decode.string)
        (optionalField "sp_logout_url" Decode.string)


advancedSettingsDecoder : Decoder AdvancedSettings
advancedSettingsDecoder =
    Decode.map6 AdvancedSettings
        (optionalField "authn_context_enabled" Decode.bool)
        {- Decoder escape: IdP-specific force-authentication flag; some
           providers send a bool, others a config object. Opaque to the SDK.
        -}
        (optionalField "force_authn" Decode.value)
        (optionalField "idp_single_logout_url" Decode.string)
        (optionalField "relay_state" Decode.string)
        (optionalField "service_provider_private_key" Decode.string)
        (optionalField "service_provider_public_cert" Decode.string)
