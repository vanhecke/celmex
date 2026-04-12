format:
    elm-format src/ cli/src/ --yes

build: format
    cd cli && elm make src/Cli/Main.elm --optimize --output=dist/elm.js

test: build
    bats tests/

clean:
    rm -rf elm-stuff cli/elm-stuff cli/dist
