set dotenv-filename := ".envrc"
set positional-arguments

format:
    elm-format src/ cli/src/ --yes

build: format
    cd cli && elm make src/Cli/Main.elm --optimize --output=dist/elm.js
    cd cli && elm make src/Cli/TestMain.elm --optimize --output=dist/elm-test.js

# Run the full bats suite. JOBS sets bats's --jobs parallelism (default 1 =
# serial). For Claude/agentic coding sessions, prefer `just test 4` so the
# 180+ integration tests don't serialise the tenant round-trips. Tests are
# read-only against the tenant and safe to parallelise.
test JOBS='1': build
    bats --jobs {{JOBS}} tests/

# Run a single bats file (or any subset) AND the package-docs check.
# Useful when iterating on one endpoint — `just test-one tests/quarantine.bats`
# is much faster than the full suite, and the docs check catches the
# missing-docstring errors `bats` cannot see. Sufficient for adding or
# fixing a single endpoint; full `just test` is only needed when shared
# code (Cortex.Decode, Cortex.Request, CLI parser helpers, StandardFlags)
# has been touched. JOBS works the same as in `test`.
test-one FILE JOBS='1': build
    bats --jobs {{JOBS}} {{FILE}}
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

# Publish the Elm package to package.elm-lang.org.
# Requires a matching git tag (created by `just publish VERSION`) on origin.
publish-elm:
    elm publish

# Publish the CLI to npm. `prepublishOnly` in package.json triggers `just build`
# so the tarball always contains a freshly-compiled cli/dist/elm.js.
publish-npm:
    npm publish

# Pre-flight: verify every exposed Elm module is fully documented. Runs the
# same strictness check the Elm registry applies at publish time, so doc
# failures surface here instead of after the git tag has been pushed.
check-docs:
    elm make --docs=docs.json
    rm -f docs.json

# Bump both manifests to VERSION in lockstep, commit, tag, push, then publish
# to both registries. Run this from a clean `main` after `just test` passes.
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
    elm-format src/ cli/src/ --validate
    just check-docs
    just review
    just test 4
    npm version --no-git-tag-version {{VERSION}}
    sed -i '' 's/"version": "[^"]*"/"version": "{{VERSION}}"/' elm.json
    git add elm.json package.json package-lock.json
    git commit -m "chore: release {{VERSION}}"
    git tag {{VERSION}}
    git push origin main
    git push origin {{VERSION}}
    just publish-elm
    just publish-npm
