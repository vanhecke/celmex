#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "rbac get-users returns valid JSON array" {
    run "$CORTEX" rbac get-users
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "array"' > /dev/null
}

@test "rbac get-users typed decode succeeds" {
    run "$CORTEX_TEST" rbac get-users
    [ "$status" -eq 0 ]
}
