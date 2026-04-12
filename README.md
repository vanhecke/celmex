# elm-cortex

Elm SDK and CLI for the Cortex Platform REST API.

## Library

Add `elm-cortex` to your Elm project's dependencies, then:

```elm
import Cortex.Client exposing (Config, send)
import Cortex.Auth exposing (Credentials)
import Cortex.Api.AuditLogs as AuditLogs

config : Config
config =
    { tenant = "https://api-yourfqdn.xdr.eu.paloaltonetworks.com"
    , credentials = { apiKeyId = "...", apiKey = "..." }
    }

-- Send a request
send config GotAuditLogs AuditLogs.search
```

## CLI

```bash
cp .envrc.example .envrc
# Fill in your credentials
source .envrc

npm install
just build
./cli/bin/cortex audit-logs search
```

## Development

```bash
just format    # elm-format all source files
just build     # compile CLI
just test      # run BATS integration tests against real tenant
just clean     # remove build artifacts
```
