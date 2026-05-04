#!/usr/bin/env bats

setup() {
    load test_helper/common
}

# get_profiles is gated behind a feature flag on some tenants; skip the test
# rather than fail when the API returns HTTP 402 / feature not supported.
skip_if_unsupported() {
    if [[ "$output" == *"feature not supported"* ]] || [[ "$output" == *"HTTP 402"* ]]; then
        skip "tenant does not support this API (HTTP 402)"
    fi
}

@test "profiles list prevention returns valid JSON array" {
    run "$CORTEX" profiles list prevention
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "array"' > /dev/null
}

@test "profiles list prevention typed decode succeeds" {
    run "$CORTEX_TEST" profiles list prevention
    skip_if_unsupported
    [ "$status" -eq 0 ]
}

@test "profiles list extension returns valid JSON array" {
    run "$CORTEX" profiles list extension
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "array"' > /dev/null
}

@test "profiles list extension typed decode succeeds" {
    run "$CORTEX_TEST" profiles list extension
    skip_if_unsupported
    [ "$status" -eq 0 ]
}

@test "profiles get-policy returns valid JSON with policy_name" {
    endpoint_id=$("$CORTEX" endpoints list | jq -r '.[0].agent_id')
    [ -n "$endpoint_id" ] && [ "$endpoint_id" != "null" ]
    run "$CORTEX" profiles get-policy "$endpoint_id"
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.policy_name | type == "string"' > /dev/null
}

@test "profiles get-policy typed decode succeeds" {
    endpoint_id=$("$CORTEX" endpoints list | jq -r '.[0].agent_id')
    [ -n "$endpoint_id" ] && [ "$endpoint_id" != "null" ]
    run "$CORTEX_TEST" profiles get-policy "$endpoint_id"
    [ "$status" -eq 0 ]
}

@test "profiles prevention get-modules Malware Windows returns module catalog" {
    run "$CORTEX" profiles prevention get-modules Malware Windows
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "array" and length > 0' > /dev/null
    echo "$output" | jq -e '.[0].id | type == "string"' > /dev/null
    echo "$output" | jq -e '.[0].profile_type == "Malware"' > /dev/null
    echo "$output" | jq -e '.[0].platform == "Windows"' > /dev/null
    echo "$output" | jq -e '.[0].schema | type == "object"' > /dev/null
}

@test "profiles prevention get-modules typed decode succeeds" {
    run "$CORTEX_TEST" profiles prevention get-modules Malware Windows
    skip_if_unsupported
    [ "$status" -eq 0 ]
}

@test "profiles prevention get-modules with invalid type fails clearly" {
    run "$CORTEX" profiles prevention get-modules malware Windows
    [ "$status" -ne 0 ]
}
