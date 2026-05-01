#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "endpoints list returns valid JSON array" {
    run "$CORTEX" endpoints list
    [ "$status" -eq 0 ]
    echo "$output" | jq -e 'type == "array" and length > 0' > /dev/null
    echo "$output" | jq -e '.[0].agent_id | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.[0].host_name | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.[0].ip | type == "array" and length > 0' > /dev/null
    echo "$output" | jq -e '.[0].tags.server_tags | type == "array"' > /dev/null
    echo "$output" | jq -e '.[0].tags.endpoint_tags | type == "array"' > /dev/null
}

@test "endpoints list typed decode succeeds" {
    run "$CORTEX_TEST" endpoints list
    [ "$status" -eq 0 ]
}

@test "endpoints list --limit 1 succeeds" {
    run "$CORTEX" endpoints list --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "endpoints list invalid --filter exits non-zero" {
    run "$CORTEX" endpoints list --filter bad
    [ "$status" -ne 0 ]
}

@test "endpoints list invalid --extra JSON exits non-zero" {
    run "$CORTEX" endpoints list --extra foo=not-json
    [ "$status" -ne 0 ]
}
