#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "bioc get returns valid JSON with objects array" {
    run "$CORTEX" bioc get
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.objects | type == "array"' > /dev/null
    echo "$output" | jq -e '.objects_count | type == "number"' > /dev/null
    echo "$output" | jq -e '.objects_type | type == "string" and length > 0' > /dev/null
}

@test "bioc get typed decode succeeds" {
    run "$CORTEX_TEST" bioc get
    [ "$status" -eq 0 ]
}

@test "bioc get --limit 1 succeeds" {
    run "$CORTEX" bioc get --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "bioc get invalid --filter exits non-zero" {
    run "$CORTEX" bioc get --filter bad
    [ "$status" -ne 0 ]
}

@test "bioc get invalid --extra JSON exits non-zero" {
    run "$CORTEX" bioc get --extra foo=not-json
    [ "$status" -ne 0 ]
}
