#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "indicators get returns valid JSON with objects array" {
    run "$CORTEX" indicators get
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.objects | type == "array"' > /dev/null
}

@test "indicators get typed decode succeeds" {
    run "$CORTEX_TEST" indicators get
    [ "$status" -eq 0 ]
}
