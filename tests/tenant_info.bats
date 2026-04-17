#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "tenant-info returns valid JSON" {
    run "$CORTEX" tenant-info
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "object"' > /dev/null
}

@test "tenant-info typed decode succeeds" {
    run "$CORTEX_TEST" tenant-info
    [ "$status" -eq 0 ]
}
