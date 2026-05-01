#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "tenant-info returns valid JSON" {
    run "$CORTEX" tenant-info
    [ "$status" -eq 0 ]
    echo "$output" | jq -e 'type == "object"' > /dev/null
    echo "$output" | jq -e 'keys | length >= 10' > /dev/null
    echo "$output" | jq -e 'has("purchased_xsiam_premium")' > /dev/null
    echo "$output" | jq -e '.installed_prevent | type == "number"' > /dev/null
}

@test "tenant-info typed decode succeeds" {
    run "$CORTEX_TEST" tenant-info
    [ "$status" -eq 0 ]
}
