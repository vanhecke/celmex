set dotenv-filename := ".envrc"
set positional-arguments

format:
    elm-format src/ cli/src/ --yes

build: format
    cd cli && elm make src/Cli/Main.elm --optimize --output=dist/elm.js
    cd cli && elm make src/Cli/TestMain.elm --optimize --output=dist/elm-test.js

test: build
    bats tests/

cli *ARGS:
    @if [ ! -f cli/dist/elm.js ] || [ -n "$(find src cli/src elm.json cli/elm.json -newer cli/dist/elm.js 2>/dev/null)" ]; then just build; fi
    ./cli/bin/cortex "$@"

curl METHOD PATH BODY='':
    ./cli/bin/cortex-curl {{METHOD}} {{PATH}} '{{BODY}}'

clean:
    rm -rf elm-stuff cli/elm-stuff cli/dist

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
publish VERSION: check-docs
    npm version --no-git-tag-version {{VERSION}}
    sed -i '' 's/"version": "[^"]*"/"version": "{{VERSION}}"/' elm.json
    git add elm.json package.json package-lock.json
    git commit -m "chore: release {{VERSION}}"
    git tag {{VERSION}}
    git push origin main
    git push origin {{VERSION}}
    just publish-elm
    just publish-npm
