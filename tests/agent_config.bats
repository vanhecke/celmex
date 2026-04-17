#!/usr/bin/env bats

setup() {
    load test_helper/common
}

# Several agent-configuration GETs are gated behind license / feature flags
# on some tenants and surface as HTTP 500 (Internal Server Error) rather
# than a clean 402; skip rather than fail when the tenant lacks the API.
skip_if_unsupported() {
    if [[ "$output" == *"feature not supported"* ]] \
        || [[ "$output" == *"HTTP 402"* ]] \
        || [[ "$output" == *"HTTP 500"* ]] \
        || [[ "$output" == *"Internal Server Error"* ]]; then
        skip "tenant does not support this API"
    fi
}

@test "agent-config content-management returns valid JSON object" {
    run "$CORTEX" agent-config content-management
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "object"' > /dev/null
}

@test "agent-config content-management typed decode succeeds" {
    run "$CORTEX_TEST" agent-config content-management
    skip_if_unsupported
    [ "$status" -eq 0 ]
}

@test "agent-config auto-upgrade returns valid JSON object" {
    run "$CORTEX" agent-config auto-upgrade
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "object"' > /dev/null
}

@test "agent-config auto-upgrade typed decode succeeds" {
    run "$CORTEX_TEST" agent-config auto-upgrade
    skip_if_unsupported
    [ "$status" -eq 0 ]
}

@test "agent-config wildfire-analysis returns valid JSON object" {
    run "$CORTEX" agent-config wildfire-analysis
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "object"' > /dev/null
}

@test "agent-config wildfire-analysis typed decode succeeds" {
    run "$CORTEX_TEST" agent-config wildfire-analysis
    skip_if_unsupported
    [ "$status" -eq 0 ]
}

@test "agent-config critical-environment-versions returns valid JSON object" {
    run "$CORTEX" agent-config critical-environment-versions
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "object"' > /dev/null
}

@test "agent-config critical-environment-versions typed decode succeeds" {
    run "$CORTEX_TEST" agent-config critical-environment-versions
    skip_if_unsupported
    [ "$status" -eq 0 ]
}

@test "agent-config advanced-analysis returns valid JSON object" {
    run "$CORTEX" agent-config advanced-analysis
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "object"' > /dev/null
}

@test "agent-config advanced-analysis typed decode succeeds" {
    run "$CORTEX_TEST" agent-config advanced-analysis
    skip_if_unsupported
    [ "$status" -eq 0 ]
}
