#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "legacy-exceptions get-modules returns valid JSON array" {
    run "$CORTEX" legacy-exceptions get-modules
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "array"' > /dev/null
}

@test "legacy-exceptions fetch returns valid JSON with DATA array" {
    run "$CORTEX" legacy-exceptions fetch
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.DATA | type == "array"' > /dev/null
}
