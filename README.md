# celmex

Elm SDK and CLI for the Cortex Platform REST API.

## Elm library

Install:

```bash
elm install vanhecke/celmex
```

Use:

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
send config GotAuditLogs (AuditLogs.search AuditLogs.defaultSearchArgs)
```

Every list/search endpoint takes a `SearchArgs` record carrying optional
filters, sort, pagination, timeframe, and an `extra` escape hatch — see
`Cortex.Query` for the filter/sort DSL and `Cortex.RequestData` for the
shared envelope.

## CLI

One-off (no install):

```bash
export CORTEX_TENANT_URL="https://api-yourfqdn.xdr.eu.paloaltonetworks.com"
export CORTEX_API_KEY_ID="..."
export CORTEX_API_KEY="..."

npx @vanhecke/celmex healthcheck
npx @vanhecke/celmex audit-logs search
```

Persistent install (adds `cortex` to your PATH):

```bash
npm install -g @vanhecke/celmex
cortex audit-logs search
```

### Environment contract

| Variable | Purpose |
|---|---|
| `CORTEX_TENANT_URL` | Your tenant API base URL |
| `CORTEX_API_KEY_ID` | Advanced API key ID |
| `CORTEX_API_KEY` | Advanced API key secret |

## Development

```bash
cp .envrc.example .envrc    # fill in credentials, then: source .envrc
npm install
just build                  # format + compile cli/dist/elm.js
just test                   # run BATS integration tests against a real tenant
just cli healthcheck        # rebuild if needed, then invoke ./cli/bin/cortex
just clean                  # remove build artifacts
```

## Releasing

```bash
just publish 1.0.1          # bump elm.json + package.json, tag, push, publish both
```
