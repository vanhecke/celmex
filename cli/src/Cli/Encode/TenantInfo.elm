module Cli.Encode.TenantInfo exposing (encode)

import Cortex.Api.TenantInfo exposing (TenantInfo)
import Json.Encode as Encode


encode : TenantInfo -> Encode.Value
encode info =
    info.raw
