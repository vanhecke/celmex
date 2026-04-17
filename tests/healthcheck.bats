#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "healthcheck returns valid JSON with status" {
    run "$CORTEX" healthcheck
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.status' > /dev/null
}

@test "healthcheck typed decode succeeds" {
    run "$CORTEX_TEST" healthcheck
    [ "$status" -eq 0 ]
}
