#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "correlations get returns valid JSON with objects array" {
    run "$CORTEX" correlations get
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.objects | type == "array"' > /dev/null
    echo "$output" | jq -e '.objects_count | type == "number"' > /dev/null
    echo "$output" | jq -e '.objects_type | type == "string" and length > 0' > /dev/null
}

@test "correlations get typed decode succeeds" {
    run "$CORTEX_TEST" correlations get
    [ "$status" -eq 0 ]
}

@test "correlations get --limit 1 succeeds" {
    run "$CORTEX" correlations get --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "correlations get invalid --filter exits non-zero" {
    run "$CORTEX" correlations get --filter bad
    [ "$status" -ne 0 ]
}

@test "correlations get invalid --extra JSON exits non-zero" {
    run "$CORTEX" correlations get --extra foo=not-json
    [ "$status" -ne 0 ]
}
