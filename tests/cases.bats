#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "cases search returns valid JSON with DATA array" {
    run "$CORTEX" cases search
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.DATA | type == "array"' > /dev/null
}

@test "cases search typed decode succeeds" {
    run "$CORTEX_TEST" cases search
    [ "$status" -eq 0 ]
}
