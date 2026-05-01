#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "disable-prevention fetch returns valid JSON with data array" {
    run "$CORTEX" disable-prevention fetch
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.data | type == "array"' > /dev/null
    echo "$output" | jq -e '.total_count | type == "number"' > /dev/null
    echo "$output" | jq -e '.filter_count | type == "number"' > /dev/null
}

@test "disable-prevention fetch typed decode succeeds" {
    run "$CORTEX_TEST" disable-prevention fetch
    [ "$status" -eq 0 ]
}

@test "disable-prevention fetch-injection returns valid JSON with data array" {
    run "$CORTEX" disable-prevention fetch-injection
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.data | type == "array"' > /dev/null
    echo "$output" | jq -e '.total_count | type == "number"' > /dev/null
    echo "$output" | jq -e '.filter_count | type == "number"' > /dev/null
}

@test "disable-prevention fetch-injection typed decode succeeds" {
    run "$CORTEX_TEST" disable-prevention fetch-injection
    [ "$status" -eq 0 ]
}

@test "disable-prevention get-modules windows returns valid JSON array" {
    run "$CORTEX" disable-prevention get-modules windows
    [ "$status" -eq 0 ]
    echo "$output" | jq -e 'type == "array" and length > 0' > /dev/null
    echo "$output" | jq -e '.[0].module_id | type == "number"' > /dev/null
    echo "$output" | jq -e '.[0].name | type == "string" and length > 0' > /dev/null
}

@test "disable-prevention get-modules windows typed decode succeeds" {
    run "$CORTEX_TEST" disable-prevention get-modules windows
    [ "$status" -eq 0 ]
}

@test "disable-prevention get-modules linux typed decode succeeds" {
    run "$CORTEX_TEST" disable-prevention get-modules linux
    [ "$status" -eq 0 ]
}

@test "disable-prevention get-modules macos typed decode succeeds" {
    run "$CORTEX_TEST" disable-prevention get-modules macos
    [ "$status" -eq 0 ]
}
