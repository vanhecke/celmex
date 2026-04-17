#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "audit-logs search returns valid JSON with results" {
    run "$CORTEX" audit-logs search
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.total_count >= 0' > /dev/null
    echo "$output" | jq -e '.result_count >= 0' > /dev/null
    echo "$output" | jq -e '.data | type == "array"' > /dev/null
}

@test "audit-logs search typed decode succeeds" {
    run "$CORTEX_TEST" audit-logs search
    [ "$status" -eq 0 ]
}

@test "unknown command exits non-zero" {
    run "$CORTEX" nonexistent
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
}
