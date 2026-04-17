#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "correlations get returns valid JSON with objects array" {
    run "$CORTEX" correlations get
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.objects | type == "array"' > /dev/null
}

@test "correlations get typed decode succeeds" {
    run "$CORTEX_TEST" correlations get
    [ "$status" -eq 0 ]
}
