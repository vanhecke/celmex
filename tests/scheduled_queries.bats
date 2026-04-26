#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "scheduled-queries list returns valid JSON with DATA array" {
    run "$CORTEX" scheduled-queries list
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.DATA | type == "array"' > /dev/null
}

@test "scheduled-queries list typed decode succeeds" {
    run "$CORTEX_TEST" scheduled-queries list
    [ "$status" -eq 0 ]
}

@test "scheduled-queries list --limit 1 succeeds" {
    run "$CORTEX" scheduled-queries list --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "scheduled-queries list invalid --filter exits non-zero" {
    run "$CORTEX" scheduled-queries list --filter bad
    [ "$status" -ne 0 ]
}

@test "scheduled-queries list invalid --extra JSON exits non-zero" {
    run "$CORTEX" scheduled-queries list --extra foo=not-json
    [ "$status" -ne 0 ]
}
