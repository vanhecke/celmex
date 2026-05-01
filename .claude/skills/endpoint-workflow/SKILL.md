---
name: endpoint-workflow
description: Use when adding a new Cortex API endpoint to the SDK + CLI, or when reviewing/improving an existing endpoint implementation. Covers OpenAPI lookup, curl probing, SDK module, CLI wiring, content-validating BATS tests, tenant-unsupported gating, and TODO.md tracking. Trigger words include "add endpoint", "implement endpoint", "review endpoint", "audit endpoint", and any reference to a `/public_api/v1/...` path or `Cortex.Api.*` module.
---

# Endpoint Workflow

Repeatable methodology for adding or reviewing a Cortex API endpoint in this repo. Two modes share the same checklist:

- **Add mode**: implement a new endpoint end-to-end (SDK + CLI + tests + TODO.md).
- **Review mode**: audit an already-shipped endpoint against the same checklist and fix gaps in place.

The workflow ends with a commit. Phases 1–9 implement and verify; Phase 10 stages the touched files and writes the commit using the project's message style. Pushing stays a separate, explicit user step.

## Inputs to confirm before starting

- HTTP method + full path (e.g., `GET /public_api/v1/distributions/get_versions`).
- Which OpenAPI spec file under `docs/cortex-api-openapi/` describes it.
- Module placement: extend an existing `Cortex.Api.X` or create a new module.
- For review mode: which existing module/endpoint to audit.

If any of these are unclear, ask before proceeding.

---

## Phase 1 — Discover (OpenAPI)

Locate the path in the right spec under `docs/cortex-api-openapi/`. Specs are large (`cortex-platform-papi.json` is ~2.4MB) — grep for the path rather than reading the whole file.

Capture from the spec:
- Request body schema (required vs optional fields, nested objects).
- Response body schema (every field name + type).
- Path/query parameter list.
- Auth requirements (advanced API key vs standard).

Note any nested or weakly-typed objects → those become candidates for `Decode.value` to satisfy the "preserve every field" rule (CLAUDE.md).

## Phase 2 — Probe (curl against real tenant)

```
just curl <METHOD> <PATH> '<JSON_BODY>' | jq .
```

The recipe in `justfile` wraps `cli/bin/cortex-curl`, which signs the request with the credentials from `.envrc`. No Elm needed for this step.

Interpret the response:
- **2xx with data**: capture the sample → drives the decoder field list and the test assertions.
- **2xx with empty data**: still implement, but tests may need to skip if the tenant has no fixture.
- **HTTP 402 or 500**: endpoint is not enabled on this tenant. Implement anyway, but flag for `skip_if_unsupported` in tests AND annotate `TODO.md`.
- **HTTP 4xx for a missing param**: record which params are required → drives CLI argv parsing.

Save the sample JSON in your working memory; you will reference its keys repeatedly in Phases 3 and 6.

## Phase 3 — SDK module (`src/Cortex/Api/<Name>.elm`)

Follow the pattern in `src/Cortex/Api/Cli.elm` (simple GET) or `src/Cortex/Api/Distributions.elm` (nested types + many fields).

**Module skeleton:**

```elm
module Cortex.Api.Foo exposing (Foo, FooResponse, list)

{-| One-sentence description of what this module provides.

@docs Foo, FooResponse
@docs list

-}

import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
```

**Hard rules:**
- Module-level docstring with one `@docs` line per exposed symbol — required for `elm publish`.
- `{-| ... -}` doc comment immediately above every exposed type alias, custom type, and function (no blank line between doc and definition).
- Path is a `List String` of segments, no leading slash: `["public_api", "v1", "distributions", "get_versions"]`.
- Request constructor: `Request.get`, `Request.post`, or `Request.postEmpty`.
- **Decoders MUST capture every field from the API response** (CLAUDE.md). Strategies:
  - Optional fields: `Decode.maybe (Decode.field "field_name" Decoder)`.
  - Lists that may be absent: `Cortex.Decode.optionalList`.
  - Complex/nested or undocumented objects: `Decode.value` (raw JSON) — never silently drop.
- Records with >8 fields: use `Decode.mapN` then `|> andMap` for the rest (see `src/Cortex/Api/Distributions.elm` around line 101).
- Sub-API modules stay pure — no effects, no HTTP. They return `Request a`. Effects only flow through `Cortex.Client.send`/`sendWith`.

**Field naming:** API uses snake_case (`enable_bandwidth_control`); Elm record fields use camelCase (`enableBandwidthControl`). Decoders bridge the two.

## Phase 4 — Register module

If the module is **new**, add it to `exposed-modules` in `src/elm.json` (alphabetical order). Skip if you only added a function to an already-exposed module.

Verify docs compile cleanly:

```
elm make --docs=docs.json
```

This is the same gate `just publish` runs — catching missing-docs errors here saves a failed release.

## Phase 5 — CLI wiring

Two files involved:

- `cli/src/Cli/Commands.elm`:
  - Add a variant to the `Endpoint` custom type.
  - Add a pattern match in `argvToEndpoint` for the argv shape. Use subcommand groups consistently (e.g., `["distributions", "get-versions"]`, `["agent-config", "content-management"]`).
  - **Path params** → positional argv after the subcommand (e.g., `distributions get-status <id>`).
  - **Query params** → flag parsing into a `SearchArgs`-style record (see Issues.elm for reference).
- `cli/src/Cli/Main.elm`: wire dispatch only if you introduced a new response shape that needs custom handling — most endpoints just route through the existing flow.

Keep CLI subcommand naming consistent: hyphenate snake_case (`get_versions` → `get-versions`).

## Phase 6 — BATS tests (`tests/<api_module>.bats`)

One BATS file per `Cortex.Api.*` module. For **every** endpoint, write at least these tests:

**1. Content-validating test** (uses `$CORTEX`):

```bash
@test "<api> <subcommand> returns expected fields" {
    run "$CORTEX" <subcommand> [args]
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.<field> | type == "<expected_type>"' > /dev/null
    echo "$output" | jq -e '.<another_field> | length > 0' > /dev/null
}
```

Assert **type and shape of actual fields** from the sample response. "Output is parseable JSON" alone is not enough — the test must catch a regression where the API returns a structurally different payload.

**2. Typed-decode test** (uses `$CORTEX_TEST`):

```bash
@test "<api> <subcommand> typed decode succeeds" {
    run "$CORTEX_TEST" <subcommand> [args]
    [ "$status" -eq 0 ]
}
```

This proves the Elm decoder accepts the real response without dropping fields. Exit code 0 means **both** structural decode AND any wired typed assertions (next sub-section) passed.

**2a. Typed presence/value assertions in `cli/src/Cli/TestMain.elm`**

Bare `typed` only catches the case where the decoder structurally fails (renamed/removed fields). It does **not** catch the case where a documented `Maybe` field decodes to `Nothing` because the API silently stopped returning it, or where a counter returns `0` for a field that should always be positive.

If the SDK record has documented `Maybe` fields the API is contractually expected to return, wire them through `typedAssert` instead of `typed`:

```elm
Commands.FooBar ->
    typedAssert Foo.bar
        (\r ->
            [ positive "totalCount" r.totalCount
            , nonNegative "skippedCount" r.skippedCount
            , nonBlank "tenantId" r.tenantId
            , nonEmpty "items" r.items
            ]
                ++ sampleFirst "items"
                    r.items
                    (\item ->
                        [ nonBlank "id" item.id
                        , present "createdAt" item.createdAt
                        ]
                    )
        )
```

The `XqlGetQuota` case in `cli/src/Cli/TestMain.elm` is the canonical worked example.

**Helper vocabulary** (all defined in `TestMain.elm`):

| Helper | Use for |
|---|---|
| `present "name" m` | `Maybe a` — only existence matters; value can be anything |
| `positive "name" m` | `Maybe number` — must be present AND `> 0` |
| `nonNegative "name" m` | `Maybe number` — must be present AND `>= 0` |
| `nonBlank "name" m` | `Maybe String` — must be present AND not `""` |
| `nonEmpty "name" xs` | `List a` — must have at least one element |
| `satisfies "name" pred "msg"` | escape hatch for one-off predicates (cross-field, ranges, enums) |
| `sampleFirst "name" xs (\x -> [...])` | sample head of a list and run typed checks on its fields |

The `Maybe`-aware helpers (`positive`, `nonNegative`, `nonBlank`) imply existence — no need to chain `present` first.

**Output on failure** is collapsed to one line per endpoint, naming each failed assertion and its reason:

```
fail: xql get-quota: licenseQuota: expected > 0; usedQuota: missing
```

**Do not** add assertions for fields the OpenAPI spec marks optional/nullable, for `Encode.Value` pass-through fields, for mutating endpoints (those use `skip` in TestMain), or for fields whose values legitimately vary across tenants in ways the test can't predict.

If no `Maybe` fields are worth asserting on (e.g. `Healthcheck`'s `Bool` response), keep the bare `typed` and mark `—` in the `Asserts` column of TODO.md.

**3. Per-parameter test cases** (only for endpoints that accept CLI parameters):

For each parameter, write a test that derives a real input from a prior endpoint call. Pattern from `tests/distributions.bats` (see the `first_distribution` helper around line 35):

```bash
first_distribution() {
    "$CORTEX" distributions list 2>/dev/null \
        | jq -r '.data[0] // empty | "\(.distribution_id)\t..."'
}

@test "distributions get-status with real id" {
    pair="$(first_distribution)"
    [ -n "$pair" ] || skip "no distributions on this tenant"
    id="$(echo "$pair" | cut -f1)"
    run "$CORTEX" distributions get-status "$id"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.status' > /dev/null
}
```

Test setup: every BATS file starts with `load test_helper/common`. Common helpers live in `tests/test_helper/common.bash` and require `.envrc` with `CORTEX_TENANT_URL`, `CORTEX_API_KEY`, `CORTEX_API_KEY_ID`.

## Phase 7 — Tenant-unsupported handling

If the curl probe in Phase 2 returned HTTP 402 or 500, the endpoint is not enabled on the test tenant. Two follow-ups:

**a. In the test file**, define and use the helper (see `tests/agent_config.bats` lines 9–16):

```bash
skip_if_unsupported() {
    if [[ "$output" == *"HTTP 402"* ]] || [[ "$output" == *"HTTP 500"* ]]; then
        skip "tenant does not support this API"
    fi
}

@test "<api> <subcommand> returns valid response" {
    run "$CORTEX" <subcommand>
    skip_if_unsupported
    [ "$status" -eq 0 ]
    # ... content assertions
}
```

**b. In `TODO.md`**, annotate the row's Description column (or trailing parenthetical) with `tenant-unsupported` so the gap is visible at a glance and we don't keep re-probing it.

## Phase 8 — TODO.md update

Open `TODO.md`. Find the section for the OpenAPI spec your endpoint belongs to.

- Set `✓` in the first column of the endpoint's row.
- Fill the `Elm` column with the module name (e.g., `Cortex.Api.Distributions`).
- Fill the `CLI` column with the subcommand path (e.g., `distributions get-versions`).
- Fill the `Test` column with the test file (e.g., `distributions.bats`).
- Fill the `Asserts` column:
  - `✓` if you wired typed assertions in `TestMain.elm` (Phase 6, sub-section 2a).
  - `—` if the response has no `Maybe` fields worth asserting on.
  - `skip` if the endpoint is a mutating endpoint or raw `Encode.Value` pass-through (matches `skip` in TestMain).
  - `✗` only if you knowingly deferred the assertions — this is backlog, not a finished state.
- If tenant-unsupported, annotate the Description column.
- Update the progress tracker line near the top (e.g., `57/341 endpoints implemented`).

## Phase 9 — Verify

For a **single endpoint** (one or a few endpoints in one module):

```
just format
just test-one tests/<api_module>.bats
```

`just test-one FILE` runs that bats file AND `elm make --docs=docs.json` — a complete check for endpoint-scoped work. The full suite has 180+ tests and rebuilds + re-hits the tenant for every one; **do not run `just test` for a single-endpoint change.**

Only run the full suite when shared code has been touched:

- `src/Cortex/Decode.elm`, `src/Cortex/Request.elm`, `src/Cortex/Client.elm`, `src/Cortex/Auth.elm`, `src/Cortex/Query.elm`, `src/Cortex/RequestData.elm`
- `cli/src/Cli/Commands.elm` parser helpers (`splitArgs`, `parseStandardSearch`, etc. — variant additions don't count)
- `cli/src/Cli/StandardFlags.elm`, `cli/src/Cli/Main.elm` shared helpers
- `cli/index.js`, `cli/bin/*`

In that case:

```
just format
just test
```

`just test` includes `just build` and the docs check is implicit via `just test-one`'s separate flow — but for shared-code changes also run `elm make --docs=docs.json` once.

Once tests are green, gather the inputs Phase 10 needs:
- Files added/modified.
- Test results (counts, any skips with reasons).
- Updated coverage (`<old> → <new>/341`).

Bundle related endpoints from the same OpenAPI section into one commit when natural — that decision drives whether Phase 10 uses the singleton or batch message template.

## Phase 10 — Commit

Tests are green; land the work as one commit. The user already authorized this by invoking the skill — do **not** ask for confirmation here.

**Stage explicitly.** Never `git add -A` or `git add .` — those would sweep in `.envrc`, `docs.json`, or unrelated WIP. Add only the files this workflow touched, e.g.:

```
git add src/Cortex/Api/<Name>.elm src/elm.json \
        cli/src/Cli/Commands.elm cli/src/Cli/Main.elm cli/src/Cli/TestMain.elm \
        tests/<api>.bats TODO.md
```

Drop any path you didn't actually modify.

**Write the commit** using the templates from Phase 9 inputs, via HEREDOC so the trailer formats cleanly:

```
git commit -m "$(cat <<'EOF'
Add <verb> <name> endpoint

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Subject-line templates:
- Singleton (Add mode): `Add <verb> <name> endpoint`
- Batch (Add mode): `Add <N> <type> endpoints across <areas> (<old> → <new>/341 coverage)`
- Review mode: shift the verb — e.g. `Tighten <name> endpoint decoder`, `Add typed assertions for <name> endpoint`, `Audit <name> endpoint against OpenAPI spec`.

**Hard rules:**
- Never `--no-verify` and never `--no-gpg-sign`. If a pre-commit hook fails, the commit did not happen — fix the underlying issue, re-stage, and create a **new** commit. Do not `--amend`.
- Do not push. The user runs `git push` themselves once they've reviewed the landed commit.

After the commit succeeds, run `git status` to confirm a clean tree, then summarize for the user: new commit SHA, the message subject, files committed, test counts, and updated coverage (`<old> → <new>/341`).

---

## Review mode (existing endpoints)

Apply the same checklist to an already-shipped endpoint:

- **Phase 1**: re-read the OpenAPI spec for the endpoint. Diff the response schema against the current decoder — any fields silently dropped?
- **Phase 2**: probe with `just curl`. Compare keys in the live response to the decoder fields. If the spec and live disagree, prefer the live response and update both decoder and any spec-driven assumptions.
- **Phase 3**: check the SDK module — is the module-level docstring complete? `@docs` line for every exposed symbol? Per-symbol docs present? Decoder using `mapN`/`andMap` cleanly?
- **Phase 6**: do the tests assert content (specific field types/shapes), or just exit code 0? Per-parameter coverage for CLI args? Dynamic fixture pattern where applicable? Are documented `Maybe` fields wired as typed assertions in `cli/src/Cli/TestMain.elm`, using the strongest helper that fits (`positive` / `nonNegative` / `nonBlank` over a bare `present` where applicable)? Are list responses sampled with `sampleFirst`? If the `Asserts` column in `TODO.md` shows `✗`, this is the time to flip it to `✓`.
- **Phase 7/8**: if endpoint is tenant-unsupported, is `skip_if_unsupported` used AND the `TODO.md` row annotated?

Report findings first (concise list of gaps + severity), then fix in place. Same Phase 9 + 10 flow applies — review-mode commits use a verb like `Tighten`, `Audit`, or `Add typed assertions for` instead of `Add`.

---

## Reference files (read these for canonical patterns)

Don't re-document these in this skill — read the source for examples.

- `src/Cortex/Api/Cli.elm` — minimal GET module.
- `src/Cortex/Api/AgentConfig.elm` — module with multiple endpoints.
- `src/Cortex/Api/Distributions.elm` — nested types, `mapN` + `andMap`, optional fields.
- `cli/src/Cli/Commands.elm` — `Endpoint` variant + `argvToEndpoint` parsing.
- `cli/src/Cli/Main.elm` — flag decoding + dispatch.
- `tests/distributions.bats` — content validation + dynamic fixtures (`first_distribution` helper).
- `tests/agent_config.bats` — `skip_if_unsupported` pattern.
- `tests/test_helper/common.bash` — shared BATS setup.
- `TODO.md` — tracker columns and progress line.
- `justfile` — `format`, `build`, `test`, `curl`, `publish` recipes.
- `CLAUDE.md` — project-wide conventions and the "decode every field" rule.
