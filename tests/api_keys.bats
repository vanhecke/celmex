#!/usr/bin/env bats

setup() {
    load test_helper/common
}

skip_if_unsupported() {
    if [[ "$output" == *"feature not supported"* ]] \
        || [[ "$output" == *"HTTP 402"* ]]; then
        skip "tenant does not support this API"
    fi
}

@test "api-keys list returns valid JSON with DATA array" {
    run "$CORTEX" api-keys list
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.DATA | type == "array"' > /dev/null
}

@test "api-keys list typed decode succeeds" {
    run "$CORTEX_TEST" api-keys list
    skip_if_unsupported
    [ "$status" -eq 0 ]
}
