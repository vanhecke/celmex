#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "bioc list returns valid JSON with objects array" {
    run "$CORTEX" bioc list
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.objects | type == "array"' > /dev/null
    echo "$output" | jq -e '.objects_count | type == "number"' > /dev/null
    echo "$output" | jq -e '.objects_type | type == "string" and length > 0' > /dev/null
}

@test "bioc list typed decode succeeds" {
    run "$CORTEX_TEST" bioc list
    [ "$status" -eq 0 ]
}

@test "bioc list --limit 1 succeeds" {
    run "$CORTEX" bioc list --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "bioc list invalid --filter exits non-zero" {
    run "$CORTEX" bioc list --filter bad
    [ "$status" -ne 0 ]
}

@test "bioc list invalid --extra JSON exits non-zero" {
    run "$CORTEX" bioc list --extra foo=not-json
    [ "$status" -ne 0 ]
}
