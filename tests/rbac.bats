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

@test "rbac get-roles returns valid JSON array for a known role" {
    role_name=$("$CORTEX" rbac get-users | jq -r '[.[] | .role_name // empty] | first // ""')
    [ -n "$role_name" ] || skip "no roles assigned to any user"
    run "$CORTEX" rbac get-roles "$role_name"
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    # The list-of-lists envelope is preserved in the raw output.
    echo "$output" | jq -e 'type == "array"' > /dev/null
}

@test "rbac get-roles typed decode succeeds" {
    role_name=$("$CORTEX" rbac get-users | jq -r '[.[] | .role_name // empty] | first // ""')
    [ -n "$role_name" ] || skip "no roles assigned to any user"
    run "$CORTEX_TEST" rbac get-roles "$role_name"
    skip_if_unsupported
    [ "$status" -eq 0 ]
}

@test "rbac get-user-groups returns valid JSON array for a known group" {
    group_name=$("$CORTEX" rbac get-users | jq -r '[.[] | .groups[]?] | first // ""')
    [ -n "$group_name" ] || skip "no user groups defined on tenant"
    run "$CORTEX" rbac get-user-groups "$group_name"
    skip_if_unsupported
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "array"' > /dev/null
}

@test "rbac get-user-groups typed decode succeeds" {
    group_name=$("$CORTEX" rbac get-users | jq -r '[.[] | .groups[]?] | first // ""')
    [ -n "$group_name" ] || skip "no user groups defined on tenant"
    run "$CORTEX_TEST" rbac get-user-groups "$group_name"
    skip_if_unsupported
    [ "$status" -eq 0 ]
}
