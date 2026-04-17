#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "issues search returns valid JSON with DATA array" {
    run "$CORTEX" issues search
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.DATA | type == "array"' > /dev/null
}

@test "issues search typed decode succeeds" {
    run "$CORTEX_TEST" issues search
    [ "$status" -eq 0 ]
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
