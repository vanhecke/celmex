#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "asset-groups list returns valid JSON with data array" {
    run "$CORTEX" asset-groups list
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.data | type == "array"' > /dev/null
}

@test "asset-groups list typed decode succeeds" {
    run "$CORTEX_TEST" asset-groups list
    [ "$status" -eq 0 ]
}
