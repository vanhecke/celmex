#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "device-control get-violations returns valid JSON with violations array" {
    run "$CORTEX" device-control get-violations
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.violations | type == "array"' > /dev/null
}

@test "device-control get-violations typed decode succeeds" {
    run "$CORTEX_TEST" device-control get-violations
    [ "$status" -eq 0 ]
}
