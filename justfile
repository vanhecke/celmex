set dotenv-filename := ".envrc"

format:
    elm-format src/ cli/src/ --yes

build: format
    cd cli && elm make src/Cli/Main.elm --optimize --output=dist/elm.js

test: build
    bats tests/

cli *ARGS:
    @if [ ! -f cli/dist/elm.js ] || [ -n "$(find src cli/src elm.json cli/elm.json -newer cli/dist/elm.js 2>/dev/null)" ]; then just build; fi
    ./cli/bin/cortex {{ARGS}}

curl METHOD PATH BODY='':
    ./cli/bin/cortex-curl {{METHOD}} {{PATH}} '{{BODY}}'

clean:
    rm -rf elm-stuff cli/elm-stuff cli/dist
