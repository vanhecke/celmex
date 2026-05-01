#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "issues search returns valid JSON with DATA array" {
    run "$CORTEX" issues search
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.DATA | type == "array"' > /dev/null
    echo "$output" | jq -e '.TOTAL_COUNT | type == "number"' > /dev/null
    echo "$output" | jq -e '.FILTER_COUNT | type == "number"' > /dev/null
    echo "$output" | jq -e '.DATA[0].id | type == "number"' > /dev/null
}

@test "issues search typed decode succeeds" {
    run "$CORTEX_TEST" issues search
    [ "$status" -eq 0 ]
}

@test "issues search --limit 1 caps DATA length" {
    run "$CORTEX" issues search --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.DATA | length <= 1' > /dev/null
}

@test "issues search --sort severity:desc succeeds" {
    run "$CORTEX" issues search --sort severity:desc --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "issues search invalid --filter exits non-zero" {
    run "$CORTEX" issues search --filter bad
    [ "$status" -ne 0 ]
}

@test "issues search invalid --extra JSON exits non-zero" {
    run "$CORTEX" issues search --extra foo=not-json
    [ "$status" -ne 0 ]
}

# Some tenants surface `issue/schema` access denials as HTTP 500 with a
# non-standard envelope; skip rather than fail when the schema isn't reachable.
skip_if_unsupported() {
    if [[ "$output" == *"feature not supported"* ]] \
        || [[ "$output" == *"HTTP 402"* ]] \
        || [[ "$output" == *"HTTP 500"* ]] \
        || [[ "$output" == *"Internal Server Error"* ]]; then
        skip "tenant does not support issue/schema"
    fi
}

@test "issues schema returns valid JSON" {
    run "$CORTEX" issues schema
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "issues schema typed decode succeeds" {
    run "$CORTEX_TEST" issues schema
    skip_if_unsupported
    [ "$status" -eq 0 ]
}
