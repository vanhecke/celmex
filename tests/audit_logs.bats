#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load test_helper/common
}

@test "audit-logs search returns valid JSON with results" {
    run "$CORTEX" audit-logs search
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.total_count | type == "number" and . > 0' > /dev/null
    echo "$output" | jq -e '.result_count | type == "number" and . > 0' > /dev/null
    echo "$output" | jq -e '.data | type == "array" and length > 0' > /dev/null
    echo "$output" | jq -e '.data[0].AUDIT_ID | type == "number"' > /dev/null
    echo "$output" | jq -e '.data[0].AUDIT_DESCRIPTION | type == "string" and length > 0' > /dev/null
}

@test "audit-logs search typed decode succeeds" {
    run "$CORTEX_TEST" audit-logs search
    [ "$status" -eq 0 ]
}

@test "audit-logs search --limit 1 caps data length" {
    run "$CORTEX" audit-logs search --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.data | length <= 1' > /dev/null
}

@test "audit-logs search --sort timestamp:desc succeeds" {
    run "$CORTEX" audit-logs search --sort timestamp:desc --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "audit-logs search invalid --filter exits non-zero" {
    run "$CORTEX" audit-logs search --filter bad
    [ "$status" -ne 0 ]
}

@test "audit-logs search invalid --extra JSON exits non-zero" {
    run "$CORTEX" audit-logs search --extra foo=not-json
    [ "$status" -ne 0 ]
}

@test "unknown command exits non-zero" {
    run --separate-stderr "$CORTEX" nonexistent
    [ "$status" -eq 1 ]
    [[ "$stderr" == *"Unknown command"* ]]
}
