#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "endpoints list returns valid JSON array" {
    run "$CORTEX" endpoints list
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "array"' > /dev/null
}

@test "endpoints list typed decode succeeds" {
    run "$CORTEX_TEST" endpoints list
    [ "$status" -eq 0 ]
}
