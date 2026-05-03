#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load test_helper/common
}

@test "cases search returns valid JSON with DATA array" {
    run "$CORTEX" cases search
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.DATA | type == "array" and length > 0' > /dev/null
    echo "$output" | jq -e '.TOTAL_COUNT | type == "number"' > /dev/null
    echo "$output" | jq -e '.DATA[0].case_id | type == "number"' > /dev/null
    echo "$output" | jq -e '.DATA[0].case_name | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.DATA[0].severity | type == "string" and length > 0' > /dev/null
}

@test "cases search typed decode succeeds" {
    run "$CORTEX_TEST" cases search
    [ "$status" -eq 0 ]
}

@test "cases search --limit 1 caps DATA length" {
    run "$CORTEX" cases search --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.DATA | length <= 1' > /dev/null
}

@test "cases search --sort creation_time:desc succeeds" {
    run "$CORTEX" cases search --sort creation_time:desc --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "cases search invalid --filter exits non-zero" {
    run "$CORTEX" cases search --filter bad
    [ "$status" -ne 0 ]
}

@test "cases search invalid --extra JSON exits non-zero" {
    run "$CORTEX" cases search --extra foo=not-json
    [ "$status" -ne 0 ]
}

@test "cases search --filter unknown operator exits non-zero" {
    run "$CORTEX" cases search --filter severity=unknown=high
    [ "$status" -ne 0 ]
}

first_case_id() {
    "$CORTEX" cases search 2>/dev/null \
        | jq -r '.DATA[0].case_id // empty'
}

@test "cases artifacts returns top-level JSON array of case artifacts" {
    case_id="$(first_case_id)"
    [ -n "$case_id" ] || skip "no cases on this tenant"
    run "$CORTEX" cases artifacts "$case_id"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e 'type == "array"' > /dev/null
    if [ "$(echo "$output" | jq 'length')" -gt 0 ]; then
        echo "$output" | jq -e '.[0].case_id | type == "number"' > /dev/null
        echo "$output" | jq -e '.[0] | has("file_artifacts") and has("network_artifacts")' > /dev/null
    fi
}

@test "cases artifacts typed decode succeeds" {
    case_id="$(first_case_id)"
    [ -n "$case_id" ] || skip "no cases on this tenant"
    run "$CORTEX_TEST" cases artifacts "$case_id"
    [ "$status" -eq 0 ]
}

@test "cases artifacts non-numeric id exits non-zero" {
    run --separate-stderr "$CORTEX" cases artifacts not-a-number
    [ "$status" -ne 0 ]
}
