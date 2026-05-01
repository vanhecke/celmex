#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "indicators get returns valid JSON with objects array" {
    run "$CORTEX" indicators get
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.objects | type == "array"' > /dev/null
    echo "$output" | jq -e '.objects_count | type == "number"' > /dev/null
    echo "$output" | jq -e '.objects_type | type == "string" and length > 0' > /dev/null
}

@test "indicators get typed decode succeeds" {
    run "$CORTEX_TEST" indicators get
    [ "$status" -eq 0 ]
}

@test "indicators get --limit 1 succeeds" {
    run "$CORTEX" indicators get --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "indicators get invalid --filter exits non-zero" {
    run "$CORTEX" indicators get --filter bad
    [ "$status" -ne 0 ]
}

@test "indicators get invalid --extra JSON exits non-zero" {
    run "$CORTEX" indicators get --extra foo=not-json
    [ "$status" -ne 0 ]
}
