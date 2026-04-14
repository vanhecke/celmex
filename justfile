set dotenv-filename := ".envrc"

format:
    elm-format src/ cli/src/ --yes

build: format
    cd cli && elm make src/Cli/Main.elm --optimize --output=dist/elm.js

test: build
    bats tests/

curl METHOD PATH BODY='':
    ./cli/bin/cortex-curl {{METHOD}} {{PATH}} '{{BODY}}'

clean:
    rm -rf elm-stuff cli/elm-stuff cli/dist
