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

@test "agent-config agent-status returns valid JSON object" {
    run "$CORTEX" agent-config agent-status
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "object"' > /dev/null
}

@test "agent-config agent-status typed decode succeeds" {
    run "$CORTEX_TEST" agent-config agent-status
    skip_if_unsupported
    [ "$status" -eq 0 ]
}

@test "agent-config informative-btp-issues returns valid JSON object" {
    run "$CORTEX" agent-config informative-btp-issues
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "object"' > /dev/null
}

@test "agent-config informative-btp-issues typed decode succeeds" {
    run "$CORTEX_TEST" agent-config informative-btp-issues
    skip_if_unsupported
    [ "$status" -eq 0 ]
}

@test "agent-config cortex-xdr-log-collection returns valid JSON object" {
    run "$CORTEX" agent-config cortex-xdr-log-collection
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "object"' > /dev/null
}

@test "agent-config cortex-xdr-log-collection typed decode succeeds" {
    run "$CORTEX_TEST" agent-config cortex-xdr-log-collection
    skip_if_unsupported
    [ "$status" -eq 0 ]
}

@test "agent-config action-center-expiration returns valid JSON object" {
    run "$CORTEX" agent-config action-center-expiration
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "object"' > /dev/null
}

@test "agent-config action-center-expiration typed decode succeeds" {
    run "$CORTEX_TEST" agent-config action-center-expiration
    skip_if_unsupported
    [ "$status" -eq 0 ]
}

@test "agent-config endpoint-administration-cleanup returns valid JSON object" {
    run "$CORTEX" agent-config endpoint-administration-cleanup
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "object"' > /dev/null
}

@test "agent-config endpoint-administration-cleanup typed decode succeeds" {
    run "$CORTEX_TEST" agent-config endpoint-administration-cleanup
    skip_if_unsupported
    [ "$status" -eq 0 ]
}
