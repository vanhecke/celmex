# Cortex Elm SDK + CLI

## Project structure

- `src/Cortex/` — publishable Elm package (type=package). Pure Elm, no ports.
  - `Auth.elm` — SHA-256 advanced API auth signing
  - `Client.elm` — Config, send, sendWith (the only module with effects)
  - `Error.elm` — Error type with multi-envelope decoder
  - `Request.elm` — opaque Request type + builders
  - `Api/*.elm` — one module per sub-API (e.g., AuditLogs, Issues)
- `cli/` — Node CLI application (type=application, uses `Platform.worker`)
  - `cli/elm.json` has `source-directories: ["src", "../src"]` to compile both
  - `cli/index.js` — xhr2 polyfill (must come before elm.js require), crypto nonce
  - `cli/bin/cortex` — shebang launcher
  - `cli/bin/cortex-curl` — bash tool for raw authenticated API calls (no Elm needed)
- `tests/*.bats` — BATS integration tests against a real Cortex tenant
- `docs/cortex-api-openapi/` — OpenAPI specs (source of truth for API shapes)

## Build commands

```
just format    # elm-format all source files
just build     # format + compile cli/dist/elm.js
just test      # build + run BATS tests
just curl      # raw authenticated API call: just curl GET /public_api/v1/healthcheck | jq .
just clean     # remove elm-stuff and build artifacts
```

## Key conventions

- Product is "Cortex" (not "XSIAM" — that's a license tier). Module namespace: `Cortex.*`
- Sub-API modules under `Cortex.Api.*` are pure (no effects, no HTTP). They return `Request a`.
- All effects flow through `Cortex.Client.send` / `sendWith`
- Auth wire headers use `x-xdr-*` prefix (literal API header names, not branding)
- Environment variables: `CORTEX_TENANT_URL`, `CORTEX_API_KEY`, `CORTEX_API_KEY_ID`
- Secrets in `.envrc` (gitignored). Never commit credentials.
- SHA-256 via `folkertdev/elm-sha2` (v1.0.0)
- elm-format enforced on all source files
- Integration testing only (no unit tests). Tests hit a real tenant.
- API response decoders must parse **all** fields from the API response. Never drop data from incoming responses. Use `Decode.value` for complex/nested objects if needed, but always capture every field the API returns.
