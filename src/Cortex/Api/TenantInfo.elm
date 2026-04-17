module Cortex.Api.TenantInfo exposing
    ( TenantInfo
    , encode
    , get
    )

import Cortex.Decode exposing (reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| The tenant info response contains many optional license fields whose
presence varies by tenant configuration. We decode the full reply object
as raw JSON so the CLI can output it verbatim without losing any fields.
-}
type alias TenantInfo =
    { raw : Encode.Value
    }


{-| POST /public\_api/v1/system/get\_tenant\_info

Retrieve license and configuration info for the tenant.
Response uses the `reply` envelope.

-}
get : Request TenantInfo
get =
    Request.postEmpty
        [ "public_api", "v1", "system", "get_tenant_info" ]
        tenantInfoDecoder


tenantInfoDecoder : Decoder TenantInfo
tenantInfoDecoder =
    reply Decode.value
        |> Decode.map TenantInfo


encode : TenantInfo -> Encode.Value
encode info =
    info.raw
