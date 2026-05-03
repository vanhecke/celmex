#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load test_helper/common
}

first_case_id() {
    "$CORTEX" cases search 2>/dev/null | jq -r '.DATA[0].case_id // empty'
}

@test "entries get returns valid JSON with data array" {
    case_id="$(first_case_id)"
    [ -n "$case_id" ] || skip "no cases on this tenant"
    run "$CORTEX" entries get "CASE-${case_id}"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.data | type == "array"' > /dev/null
    echo "$output" | jq -e '.total | type == "number"' > /dev/null
}

@test "entries get typed decode succeeds" {
    case_id="$(first_case_id)"
    [ -n "$case_id" ] || skip "no cases on this tenant"
    run "$CORTEX_TEST" entries get "CASE-${case_id}"
    [ "$status" -eq 0 ]
}

@test "entries get without id exits non-zero" {
    run --separate-stderr "$CORTEX" entries get
    [ "$status" -ne 0 ]
}
