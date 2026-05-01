# Proposal: Quality, security & reporting tooling for celmex

## Context

The Cortex Elm SDK + CLI is a public, published package (npm + Elm registry) that handles tenant API credentials. The current setup already covers the basics well: `elm-format --validate` in CI, `check-docs` before publish, BATS integration tests against a live tenant, `.envrc` properly gitignored, version bump in lockstep across both manifests.

What's missing is *defensive* tooling — automation that catches problems Joris would otherwise have to notice manually. Below is a tiered proposal of code-quality, security, and project-health additions, ordered by value-per-effort. Pick a tier (or specific items) to implement — the plan does not assume all of it lands.

---

## Tier 1 — Strong recommendation (high value, low friction)

### 1. **elm-review** (already initialized for the SDK; needs CLI coverage + meaningful packs)

Current state: `/review/` exists with one rule (`Yagger/elm-review-no-url-string-concatenation`). The CLI side at `cli/` has no review config. Plan below brings both sides up to a useful baseline and adds one custom rule for the architectural invariant in CLAUDE.md.

#### 1a. Topology — two review configs, one per Elm project

elm-review's official guidance is "run once per project". The repo has two Elm projects: the SDK package at `/` and the CLI application at `cli/` (whose `elm.json` source-directories include `../src`, so CLI review would re-analyze SDK files unless excluded).

Recommended layout:
- **`/review/`** (exists) — analyzes the SDK package. Strict rule set, including documentation rules required for `package.elm-lang.org`.
- **`/cli/review/`** (new) — analyzes only `cli/src/`. Uses `Review.Rule.ignoreErrorsForDirectories ["../src"]` on every rule so SDK files are excluded; the SDK config already covers them.
- `just review` runs both: `elm-review && elm-review --config cli/review` (or two recipes: `review-sdk`, `review-cli`).
- CI runs both between `format` and `compile`. `just publish` pre-flight runs both alongside `check-docs`.

#### 1b. Rule packs — what to install

All from the canonical maintainer (`jfmengels`) unless noted, all autofix-capable where applicable. Listed by tier within each side.

**SDK side (`/review/`)** — must be strict because the package is published:

| Pack | Rules used | Why |
|------|-----------|-----|
| `elm-review-unused` | `NoUnused.Variables`, `.CustomTypeConstructors`, `.CustomTypeConstructorArgs`, `.Exports`, `.Modules`, `.Parameters`, `.Patterns`, `.Dependencies` | Catches unused exposed symbols (matters for a public package), unused dependencies, dead code. Highest signal pack. |
| `elm-review-common` | `NoExposingEverything`, `NoImportingEverything`, `NoMissingTypeAnnotation`, `NoMissingTypeExpose`, `NoConfusingPrefixOperator`, `NoDeprecated`, `NoPrematureLetComputation` | Enforces explicit exposing lists (already the project's style) and full type annotations on top-level decls. |
| `elm-review-simplify` | `Simplify` | Single rule, large autofix surface — `if x then True else False` → `x`, etc. Lossless cleanups. |
| `elm-review-debug` | `NoDebug.Log`, `NoDebug.TodoOrToString` | Trivial to add. Stops `Debug.log` shipping in a published package. |
| `elm-review-documentation` | `Docs.ReviewAtDocs`, `Docs.NoMissing`, `Docs.ReviewLinksAndSections`, `Docs.UpToDateReadmeLinks` | **Project-specific high value.** CLAUDE.md describes the `@docs` discipline manually; this pack mechanizes it. `Docs.NoMissing` enforces docstrings on every exposed symbol — the same thing `elm publish` checks, but with better errors and earlier in the loop. `Docs.UpToDateReadmeLinks` catches version drift in README. |
| (kept) `Yagger/elm-review-no-url-string-concatenation` | existing rule | Already in place. |

**CLI side (`/cli/review/`)** — application, less strict:
- `elm-review-unused` (same set, drop `NoUnused.Exports` since CLI is `Platform.worker` with `main` as the only required export)
- `elm-review-common` (drop `NoMissingTypeExpose` — application-only)
- `elm-review-simplify`
- `elm-review-debug`
- (Optionally) `sparksp/elm-review-ports` — the CLI uses ports in `cli/src/Cli/Ports.elm`. This pack enforces port-naming and handler conventions. Add only if the port surface grows.

Skip on the CLI side: `elm-review-documentation` (CLI is not published).

#### 1c. One custom rule worth writing — `NoEffectsInApiModules`

CLAUDE.md states: *"Sub-API modules under `Cortex.Api.*` are pure (no effects, no HTTP). They return `Request a`. All effects flow through `Cortex.Client.send` / `sendWith`."*

Today this is enforced by code review. A custom rule turns it into a compile-time guard:

- **Visitor**: `Review.Rule.newModuleRuleSchema` + `withImportVisitor`
- **Predicate**: when the module being visited has a name matching `Cortex.Api.*`, forbid imports of `Cortex.Client` and `Http` (and `Elm.Http`, `Elm.Bytes.Http`, etc. — anything in the effect surface).
- **Error message**: "Cortex.Api modules must be pure. Move the call site to Cortex.Client or expose a `Request a` here."
- **Lives in**: `review/src/NoEffectsInApiModules.elm` (SDK side only — the CLI freely uses `Cortex.Client`).

This is ~50 lines of Elm. The rule API has good docs and the pattern (forbid imports in a namespace) is in the elm-review cookbook.

**Custom rules considered and rejected:**

- *Forbid `Decode.value` outside justified call sites* — the existing rule (in CLAUDE.md) has explicit exceptions (XQL, free-form maps) and requires a `{-| -}` justification. Encoding that nuance as an elm-review rule is brittle; `Encode.Value` discipline is better left to code review.
- *Require `defaultXArgs` for any exposed `XArgs` type* — naming-convention rules don't pay back the maintenance cost. Skip.

#### 1d. Wiring summary

- `just review` → runs both review configs
- `.github/workflows/ci.yml`: add a `review` job after `format`, before `compile`
- `just publish`: add `just review` to the pre-flight chain (alongside `check-docs`)
- Initial run will likely surface real findings — budget a one-off cleanup pass before turning CI enforcement on

### 2. **Secret scanning in CI (gitleaks)**
The project handles `CORTEX_API_KEY` / `CORTEX_API_KEY_ID`. A single `git add -A` mistake on `.envrc` would push real credentials. gitleaks is a single-job GitHub Action that scans the diff on every PR and the full history on push to main.

- Add `.github/workflows/gitleaks.yml` running `gitleaks/gitleaks-action@v2`
- ~5 lines of config; no maintenance

### 3. **Dependabot for npm + GitHub Actions**
Zero-effort dependency hygiene. The cli has `xhr2` (transitive: well-known but unmaintained) and the workflow pins action versions that drift. Dependabot opens PRs that CI either passes (merge) or fails (visible signal).

- Add `.github/dependabot.yml` with two ecosystems: `npm` (cli/) and `github-actions` (.github/workflows/)
- Weekly schedule, grouped minor/patch updates

### 4. **`just publish` safety guards**
The CLAUDE.md already documents the orphan-tag recovery procedure — that's a hint this has bitten before. Three small guards prevent the failure mode entirely:

- **Clean working tree check**: `git diff --quiet && git diff --cached --quiet || (echo "uncommitted changes" && exit 1)`
- **Run `just test` before tagging**: tests have to pass against the live tenant before any tag is pushed
- **Pre-flight version availability**: `npm view cortex-cli@$VERSION` should return empty; abort if it doesn't
- Optional: confirm branch is `main` and up-to-date with `origin/main`

Critical files to modify: [justfile](justfile) (publish recipe).

---

## Tier 2 — Solid value (moderate effort)

### 5. **`todo-from-openapi` skill** ⭐ (most project-specific)
[TODO.md](TODO.md) (501 lines) currently tracks per-API endpoint coverage by hand: which paths each spec exposes, which are implemented in `Cortex.Api.*`, what's left. That manual work is the highest-leverage candidate for automation.

Build this as a Claude Code skill (sibling to the existing `.claude/skills/endpoint-workflow/`):

- **Name**: `todo-from-openapi` (or `openapi-coverage-sync`)
- **Trigger**: invoked after spec updates in `docs/cortex-api-openapi/` or after a new endpoint module lands; mentioned in CLAUDE.md so it surfaces during endpoint work
- **Inputs**: `docs/cortex-api-openapi/*.{yaml,json}`, `src/Cortex/Api/**/*.elm`, current `TODO.md`
- **Process**:
  - Parse each OpenAPI spec → list of `(spec_file, path, method, summary)` tuples
  - Scan `src/Cortex/Api/` for implemented `/public_api/v1/...` endpoints (use the same conventions the `endpoint-workflow` skill encodes)
  - Diff against the existing TODO.md sections — preserve manual notes, update only the generated coverage tables
- **Output**: rewrites the relevant sections of TODO.md in place, leaves a summary on stdout (X new endpoints in spec, Y now implemented, Z removed)
- **Idempotent**: re-running with no changes is a no-op

Optionally a `just todo-sync` recipe wraps it for CLI use; a CI job can run it in `--check` mode and fail if TODO.md is out-of-date relative to the specs.

### 6. **`npm audit` in CI**
One line in the existing workflow: `cd cli && npm audit --audit-level=high`. Fails the build on high/critical CVEs in the dependency tree. Cheap.

---

## Tier 3 — Nice to have

### 7. **SECURITY.md**
Vulnerability disclosure policy at the repo root. For a security product's SDK, this is professional baseline. ~15 lines: how to report, expected response time, supported versions.

---

## Explicitly NOT proposing

These were considered and rejected:

- **Pre-commit hooks (husky/lefthook)** — `just format` is one command and CI validates. Pre-commit is friction without payoff for a solo project.
- **elm-coverage / unit testing** — the project explicitly chose integration-only testing. Don't push against that decision.
- **prettier/eslint for cli/index.js** — the file is tiny; linting it is theater.
- **Mutation testing, SBOM, CONTRIBUTING.md, CODE_OF_CONDUCT.md** — overkill for a small SDK.

---

## Critical files (Tier 1 only)

- [justfile](justfile) — add `review` recipe; harden `publish` recipe
- [.github/workflows/ci.yml](.github/workflows/ci.yml) — add `review` step, add `gitleaks` job (or separate workflow file)
- New: `review/elm.json`, `review/src/ReviewConfig.elm` (generated by `elm-review init`)
- New: `.github/dependabot.yml`
- New: `.github/workflows/gitleaks.yml` (or fold into ci.yml)
- Tier 2: New `.claude/skills/todo-from-openapi/SKILL.md` + supporting script(s)

## Verification

- Run `just review` locally → no warnings on the current codebase (may require initial cleanup)
- Open a PR with a deliberately committed fake `CORTEX_API_KEY=xxx` line → gitleaks job fails
- `just publish 99.99.99` on a dirty tree → exits before tagging
- Wait one week → dependabot opens PRs (or doesn't, if everything is current)
- Tier 2: run the coverage report → produces a sensible per-spec breakdown matching what's in TODO.md
