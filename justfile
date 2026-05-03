set dotenv-filename := ".envrc"
set positional-arguments

format:
    elm-format src/ cli/src/ --yes

build: format
    cd cli && elm make src/Cli/Main.elm --optimize --output=dist/elm.js
    cd cli && elm make src/Cli/TestMain.elm --optimize --output=dist/elm-test.js

# Run the full bats suite. JOBS sets bats's --jobs parallelism (default 1 =
# serial). For Claude/agentic coding sessions, prefer `just test 4` so the
# 180+ integration tests don't serialise the tenant round-trips. Read-only
# tests are safe to parallelise; write-endpoint tests follow the
# create→list→delete round-trip with `clxtest_` prefixed fixture names so
# parallel files cannot collide. See tests/SETUP_TEARDOWN.md.
#
# Sweeps `clxtest_*` orphans from the tenant before AND after the run so a
# crashed write-endpoint test cannot leave permanent fixtures behind. The
# glob `tests/*.bats` is non-recursive, so `tests/destructive/` is ignored
# here — those tests run individually via `just test-destructive`.
test JOBS='1': build
    just test-clean
    BATS_RUN_ID="$(date +%s)_$(openssl rand -hex 2)" bats --jobs {{JOBS}} tests/*.bats; status=$?; just test-clean; exit $status

# Sweep clxtest_* objects from the live tenant. Idempotent. Wired into
# `just test` automatically; invoke standalone for a manual cleanup.
test-clean:
    ./cli/bin/cortex-test-clean

# List or run destructive (Tier 2) tests one at a time.
#   just test-destructive          → list available destructive .bats files
#   just test-destructive <file>   → run that file (always --jobs 1)
# Argument can be a full path, a basename, or a name without the .bats
# suffix. `just test` never picks these up. See CLAUDE.md for what
# counts as destructive and why batch runs are not supported.
test-destructive *ARGS='':
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -z "${1:-}" ]; then
        echo "Destructive tests (run individually, one at a time):"
        if compgen -G 'tests/destructive/*.bats' >/dev/null; then
            ls -1 tests/destructive/*.bats | sed 's/^/  /'
        else
            echo "  (none yet)"
        fi
        echo ""
        echo "Usage: just test-destructive <file>"
        exit 0
    fi
    arg="$1"
    target=""
    for candidate in "$arg" "tests/destructive/$arg" "tests/destructive/$arg.bats"; do
        if [ -f "$candidate" ]; then target="$candidate"; break; fi
    done
    if [ -z "$target" ]; then
        echo "error: no destructive test matches '$arg'" >&2
        exit 1
    fi
    just test-clean
    BATS_RUN_ID="$(date +%s)_$(openssl rand -hex 2)" bats --jobs 1 "$target"; status=$?; just test-clean; exit $status

# Run a single bats file (or any subset) AND the package-docs check.
# Useful when iterating on one endpoint — `just test-one tests/quarantine.bats`
# is much faster than the full suite, and the docs check catches the
# missing-docstring errors `bats` cannot see. Sufficient for adding or
# fixing a single endpoint; full `just test` is only needed when shared
# code (Cortex.Decode, Cortex.Request, CLI parser helpers, StandardFlags)
# has been touched. JOBS works the same as in `test`.
test-one FILE JOBS='1': build
    BATS_RUN_ID="$(date +%s)_$(openssl rand -hex 2)" bats --jobs {{JOBS}} {{FILE}}
    elm make --docs=docs.json
    rm -f docs.json

cli *ARGS:
    @if [ ! -f cli/dist/elm.js ] || [ -n "$(find src cli/src elm.json cli/elm.json -newer cli/dist/elm.js 2>/dev/null)" ]; then just build; fi
    ./cli/bin/cortex "$@"

curl METHOD PATH BODY='':
    ./cli/bin/cortex-curl {{METHOD}} {{PATH}} '{{BODY}}'

clean:
    rm -rf elm-stuff cli/elm-stuff cli/dist

# Run elm-review against both projects (SDK package and CLI application).
# The CLI config ignores ../src so the SDK is reviewed once.
review:
    npx --yes elm-review
    cd cli && npx --yes elm-review

# Refresh TODO.md from the OpenAPI specs and src/Cortex/Api/. See
# .claude/skills/todo-from-openapi/ for what is/isn't regenerated.
todo-sync:
    node .claude/skills/todo-from-openapi/sync.mjs

# Same as todo-sync but read-only — exits non-zero if TODO.md drifts
# from what the script would produce. Suitable for CI.
todo-check:
    node .claude/skills/todo-from-openapi/sync.mjs --check

# Publish the Elm package to package.elm-lang.org.
# Requires a matching git tag (created by `just publish VERSION`) on origin.
publish-elm:
    elm publish

# Publish the CLI to npm. `prepublishOnly` in package.json triggers `just build`
# so the tarball always contains a freshly-compiled cli/dist/elm.js.
publish-npm: _npm-auth
    npm publish

# Verify npm auth is live, prompt `npm login` if the token is missing/expired.
# Stale tokens are why `npm publish` returns the misleading 404 on a scope you
# own — npm collapses 401-on-write to 404. Catching it here keeps `just publish`
# from getting halfway through (tag pushed, elm published) before noticing.
_npm-auth:
    #!/usr/bin/env bash
    set -euo pipefail
    if who="$(npm whoami 2>/dev/null)"; then
        echo "npm: logged in as $who"
        exit 0
    fi
    echo "npm: not authenticated — running 'npm login' (interactive)"
    npm login
    who="$(npm whoami)"
    echo "npm: logged in as $who"

# Pre-flight: verify every exposed Elm module is fully documented. Runs the
# same strictness check the Elm registry applies at publish time, so doc
# failures surface here instead of after the git tag has been pushed.
check-docs:
    elm make --docs=docs.json
    rm -f docs.json

# Bump both manifests to VERSION in lockstep, commit, tag, push, then publish
# to both registries. Run this from a clean `main` after `just test` passes.
#
# The release commit and tag are signed with the personal 1Password-managed
# key (`newkey2024`, ~/.ssh/joris_signing.pub) rather than the
# `claude_signing.pub` key Claude uses for routine commits. Releases are
# Joris's signature, not Claude's.
#
# Important: the FIRST publish to the Elm registry MUST use version 1.0.0 —
# the registry hard-rejects anything else for an unpublished package.
#   just publish 1.0.0   # initial
#   just publish 1.0.1   # subsequent
publish VERSION:
    @[ -z "$(git status --porcelain)" ] || { echo "error: working tree not clean"; exit 1; }
    @[ "$(git rev-parse --abbrev-ref HEAD)" = "main" ] || { echo "error: not on main"; exit 1; }
    git fetch origin main --quiet
    @[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "error: local main not in sync with origin/main"; exit 1; }
    @if npm view @vanhecke/celmex@{{VERSION}} version 2>/dev/null | grep -q .; then echo "error: @vanhecke/celmex@{{VERSION}} already published to npm"; exit 1; fi
    just _npm-auth
    elm-format src/ cli/src/ --validate
    just check-docs
    just review
    just test 4
    npm version --no-git-tag-version {{VERSION}}
    sed -i '' 's/"version": "[^"]*"/"version": "{{VERSION}}"/' elm.json
    git add elm.json package.json package-lock.json
    git -c user.signingkey=/Users/joris/.ssh/joris_signing.pub commit -m "chore: release {{VERSION}}"
    git -c user.signingkey=/Users/joris/.ssh/joris_signing.pub tag -s {{VERSION}} -m "release {{VERSION}}"
    git push origin main
    git push origin {{VERSION}}
    just publish-elm
    just publish-npm
