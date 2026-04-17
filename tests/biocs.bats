#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "bioc get returns valid JSON with objects array" {
    run "$CORTEX" bioc get
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.objects | type == "array"' > /dev/null
}

@test "bioc get typed decode succeeds" {
    run "$CORTEX_TEST" bioc get
    [ "$status" -eq 0 ]
}
