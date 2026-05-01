---
name: todo-from-openapi
description: Use after updating an OpenAPI spec under `docs/cortex-api-openapi/` or after a new `Cortex.Api.*` module lands, to refresh the per-spec coverage tables and progress counter in TODO.md. Trigger words include "sync TODO", "regenerate TODO", "openapi coverage", and "endpoint coverage report".
---

# todo-from-openapi

Refreshes the auto-generated parts of `TODO.md` from the OpenAPI specs in `docs/cortex-api-openapi/` and the current state of `src/Cortex/Api/`. Manual prose, the legend, and per-row CLI / Test / Asserts columns are preserved.

## When to invoke

- A spec under `docs/cortex-api-openapi/` was added, removed, or had paths added/removed.
- A new `Cortex.Api.*` module was added or an existing one started serving more endpoints.
- The progress counter at the top of TODO.md feels stale.
- A user explicitly asks to sync, regenerate, or check TODO.md against the specs.

If just one endpoint was added in a single module, prefer hand-updating the row — running this script also re-renders other rows where the spec drifted, which is noisy in a small commit.

## How

```sh
just todo-sync     # rewrite TODO.md
just todo-check    # exit non-zero on drift (used in CI)
```

Both wrap `node .claude/skills/todo-from-openapi/sync.mjs`.

## What is regenerated

The script only writes between marker comments:

- `<!-- BEGIN AUTO: progress -->` … `<!-- END AUTO -->` — the `**Progress:**` line.
- `<!-- BEGIN AUTO: <spec-file> -->` … `<!-- END AUTO -->` — each per-spec table.

Anything outside markers (the H2 headings, `Source:` lines, legend, footnote prose) is left alone.

## How rows are produced

| Column | Source |
|---|---|
| ✓ | Set when the script finds a `Request.<helper>` call in `src/Cortex/Api/*.elm` whose path-segment list matches the spec's `(METHOD, path)`. |
| Method, Path | Spec. |
| Description | Spec's `summary` (fallback `operationId`). If the existing manual description has a trailing `(...)` annotation that the spec lacks (e.g. `(tenant-unsupported)`), it is preserved. |
| Type | Heuristic: `GET` is always `View`; `POST` is `View` if the summary starts with a read verb (`Get`, `List`, `Search`, `Retrieve`, `Find`, `Fetch`, `Return`) or the path matches a read-like prefix; otherwise `Edit`. The heuristic is intentionally simple — if it gets a row wrong, the right fix is usually a clearer spec summary. |
| Elm | Module name (e.g. `Cortex.Api.Quarantine`) of whichever file the matching `Request.<helper>` lives in. |
| CLI, Test, Asserts | **Preserved verbatim** from the existing row keyed by `(METHOD, path)`. The script never overwrites these — they are populated by hand as part of the [endpoint-workflow](../endpoint-workflow/SKILL.md). |

## Specs that are skipped

Two spec files in `docs/cortex-api-openapi/` are explicit duplicates per the TODO.md preamble and are not parsed:

- `cloud-onboarding-papi.json` — strict subset of `cortex-platform-papi.json`.
- `appsec-papi (1).json` — identical to `appsec-papi.json`.

If a new spec is added that should be skipped, update the `SKIP_SPECS` set in `sync.mjs`.

## Adding markers to a new section

When a brand-new spec arrives, add an H2 + `Source:` line + the marker pair manually:

```markdown
## My New API

Source: `my-new-api-papi.json`

<!-- BEGIN AUTO: my-new-api-papi.json -->
<!-- END AUTO -->
```

Then run `just todo-sync` to fill the table.

## What this skill does NOT do

- It does **not** populate the CLI, Test, or Asserts columns. Those are filled in by hand using the endpoint-workflow skill — they encode design decisions (CLI command name, test placement, assertion strategy) that the spec doesn't know about.
- It does **not** delete rows for endpoints removed from a spec. The marker block is fully replaced, so a removed endpoint just disappears from the regenerated table.
