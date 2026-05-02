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
- `tests/*.bats` — BATS integration tests against a real Cortex tenant (Tier 1, run by `just test`)
- `tests/destructive/*.bats` — Tier 2 tests for irreversible/high-blast endpoints; run individually via `just test-destructive`
- `tests/test_helper/common.bash` — env-var loader + `BATS_RUN_ID` setup
- `tests/test_helper/fixtures.bash` — `fixture_name`, `cortex_post`, `cleanup_register`/`cleanup_drain` for write-endpoint tests
- `cli/bin/cortex-test-clean` — reaper that sweeps `clxtest_*` orphans from the tenant; runs before AND after `just test`
- `tests/SETUP_TEARDOWN.md` — short reference for the write-endpoint test contract
- `docs/cortex-api-openapi/` — OpenAPI specs (source of truth for API shapes)

## Build commands

```
just format         # elm-format all source files
just build          # format + compile cli/dist/elm.js
just test [JOBS]    # build + run BATS tests (JOBS = bats --jobs parallelism, default 1)
just test-clean     # sweep clxtest_* orphans from the tenant (auto-invoked by `just test`)
just test-destructive [FILE]   # list Tier 2 tests, or run one (always serial)
just review         # run elm-review on both SDK (`/review/`) and CLI (`/cli/review/`) configs
just curl           # raw authenticated API call: just curl GET /public_api/v1/healthcheck | jq .
just clean          # remove elm-stuff and build artifacts
just todo-sync      # refresh TODO.md coverage tables from OpenAPI specs (skill: todo-from-openapi)
just todo-check     # CI-mode todo-sync that exits non-zero on drift
elm make --docs=docs.json   # verify docs for the Elm package (required before `just publish`)
just publish VERSION        # bump manifests in lockstep, tag, push, publish to npm + elm
```

**Agentic testing:** Always run `just test 4` (not bare `just test`) during
coding sessions. The 180+ integration tests each round-trip the live tenant;
serial execution is the dominant time sink. `--jobs 4` is safe — Tier 1
write-endpoint tests use the per-file `clxtest_${BATS_RUN_ID}_…` prefix so
parallel files cannot collide on fixture names.

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
- API response decoders must parse **all** fields from the API response into typed Elm records. Never drop data, and never leave a payload as `Encode.Value` pass-through — typing IS the preservation. `Decode.value` is a last-resort escape hatch reserved for genuinely free-form maps, polymorphic shapes determined by user input (e.g., XQL query rows), or raw byte streams. See the `endpoint-workflow` skill (Phase 3 hard rules) for the full decoder typing contract.
- Every `Decode.value` reference must sit immediately next to a `{- Decoder escape: <reason> -}` block comment (typically on the line above the call inside a parenthesised group). Use a regular block comment, not a doc comment — `{-| -}` is doc-only and elm-format will strip or reject it inline. The `Decoder escape:` sentinel is enforced by `NoUndocumentedDecodeValue` in elm-review and lets any contributor `grep -rn "Decoder escape:"` for a complete catalog of opacity in the SDK. The same marker may guard preserved `Encode.Value` fields when typing them is genuinely impossible.

## Integration testing for write endpoints

The BATS suite hits a real tenant. To keep that tenant clean as we add the 171 mutating endpoints from `TODO.md`, write-endpoint tests follow a strict contract. Read [`tests/SETUP_TEARDOWN.md`](tests/SETUP_TEARDOWN.md) before adding one.

**Round-trip principle.** Any test for a destructive endpoint is `create → list → delete (→ list)`. The test creates its own fixture, asserts on it, deletes it, and (when applicable) confirms it's gone. We have **one** tenant; there is no separate lab tenant.

**Naming.** Every fixture name uses the `clxtest_${BATS_RUN_ID}_${file}_${slug}` prefix (underscore-separated — many Cortex endpoints silently coerce hyphens to underscores). Build it with `fixture_name <slug>` from `tests/test_helper/fixtures.bash`; the helper sanitizes the slug to `[a-zA-Z0-9_]`. Never hardcode names. The `clxtest_` marker is what the reaper greps for; do not change it.

**Two tiers, two invocations:**
- **Tier 1** — `tests/*.bats`. Default-on; run by `just test`. Use `setup_file`/`teardown_file` for shared fixtures, or `cleanup_register` + `cleanup_drain` for in-test create+delete. Requires `bats_require_minimum_version 1.7.0`.
- **Tier 2** — `tests/destructive/*.bats`. Irreversible / high-blast endpoints (`endpoints/delete`, `scripts/run_script`, `rbac/set_user_role`, etc.). `just test` ignores the directory. Run one at a time with `just test-destructive <file>`. Each Tier 2 test must contain create+delete in the same `@test` block (no setup_file/teardown_file split).

**Hard rules:**
- **No create-without-delete tests.** If the API can create a tenant artifact but not delete it, do **not** write a test for it. Mark the row in `TODO.md`'s test column as `n/a (no delete)`.
- **No batch destructive runs.** There is no `just test-destructive --all`. The structural gate (directory location) is the safety mechanism; do not propose flags that bypass it.
- **Every new write endpoint registers with the reaper.** Add a `reap_<noun>()` function to `cli/bin/cortex-test-clean` that lists then deletes its `clxtest_*` objects. Until that registration lands, only the test's own teardown can clean up — a crash leaks.

**Reaper.** `cli/bin/cortex-test-clean` is invoked before AND after `just test`. Idempotent and silent when there's nothing to reap. Standalone via `just test-clean`.

## Documentation requirements (Elm package)

`elm publish` rejects any exposed module that is not fully documented. Every new `Cortex.*` module added to `exposed-modules` in `elm.json` must ship with:

1. **A module-level docstring** between `module ... exposing (...)` and the first import. It must contain one `@docs` line per exposed symbol (grouping related symbols on one line is fine):
   ```elm
   module Cortex.Api.Foo exposing (Foo, FooResponse, list)

   {-| One-sentence description of what this module provides.

   @docs Foo, FooResponse
   @docs list

   -}

   import ...
   ```
2. **A `{-| ... -}` comment immediately above every exposed type alias, custom type, and function** — no blank line between the comment and the definition. Cross-reference other exposed symbols with `[`Name`](#Name)`.

`just publish` runs `just check-docs` (which invokes `elm make --docs=docs.json`) as a pre-flight so missing-docs errors surface before any commit/tag/push. `docs.json` is git-ignored.

## Publishing rules

- **Initial version must be 1.0.0.** The Elm registry hard-rejects any other starting version for an unpublished package, even if the npm side has already been bumped. Both manifests must stay in lockstep.
- `just publish VERSION` is the only entry point. It runs `check-docs`, bumps both manifests, commits, tags, pushes, then runs `elm publish` + `npm publish`.
- If `elm publish` fails **after** the tag has been pushed, the orphan tag must be cleaned up (`git push origin --delete v<version>` + `git tag -d v<version>`) and `main` rewound before re-attempting. Nothing is actually published to either registry until both publish commands succeed, so aborted attempts are recoverable as long as the tags are deleted.
