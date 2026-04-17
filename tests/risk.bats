#!/usr/bin/env bats

setup() {
    load test_helper/common
}

# Risk endpoints require the Threat Intel Management add-on; tenants without
# it return HTTP 500 with "No identity threat" rather than a clean 402.
skip_if_unsupported() {
    if [[ "$output" == *"No identity threat"* ]] \
        || [[ "$output" == *"feature not supported"* ]] \
        || [[ "$output" == *"HTTP 402"* ]] \
        || [[ "$output" == *"HTTP 500"* ]]; then
        skip "tenant does not support identity-threat / risk APIs"
    fi
}

@test "risk users returns valid JSON array" {
    run "$CORTEX" risk users
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "array"' > /dev/null
}

@test "risk users typed decode succeeds" {
    run "$CORTEX_TEST" risk users
    skip_if_unsupported
    [ "$status" -eq 0 ]
}

@test "risk hosts returns valid JSON array" {
    run "$CORTEX" risk hosts
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "array"' > /dev/null
}

@test "risk hosts typed decode succeeds" {
    run "$CORTEX_TEST" risk hosts
    skip_if_unsupported
    [ "$status" -eq 0 ]
}

@test "risk score returns valid JSON for an endpoint id" {
    endpoint_id=$("$CORTEX" endpoints list | jq -r '.[0].agent_id')
    [ -n "$endpoint_id" ] && [ "$endpoint_id" != "null" ]
    run "$CORTEX" risk score "$endpoint_id"
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "risk score typed decode succeeds" {
    endpoint_id=$("$CORTEX" endpoints list | jq -r '.[0].agent_id')
    [ -n "$endpoint_id" ] && [ "$endpoint_id" != "null" ]
    run "$CORTEX_TEST" risk score "$endpoint_id"
    skip_if_unsupported
    [ "$status" -eq 0 ]
}
