#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "audit-logs agents-reports returns valid JSON with data array" {
    run "$CORTEX" audit-logs agents-reports
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.data | type == "array"' > /dev/null
}

@test "audit-logs agents-reports typed decode succeeds" {
    run "$CORTEX_TEST" audit-logs agents-reports
    [ "$status" -eq 0 ]
}
