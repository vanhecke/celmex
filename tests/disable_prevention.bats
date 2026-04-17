#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "disable-prevention fetch returns valid JSON with data array" {
    run "$CORTEX" disable-prevention fetch
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.data | type == "array"' > /dev/null
}

@test "disable-prevention fetch typed decode succeeds" {
    run "$CORTEX_TEST" disable-prevention fetch
    [ "$status" -eq 0 ]
}

@test "disable-prevention fetch-injection returns valid JSON with data array" {
    run "$CORTEX" disable-prevention fetch-injection
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.data | type == "array"' > /dev/null
}

@test "disable-prevention fetch-injection typed decode succeeds" {
    run "$CORTEX_TEST" disable-prevention fetch-injection
    [ "$status" -eq 0 ]
}
