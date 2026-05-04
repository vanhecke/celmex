#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "authentication-settings get returns valid JSON array" {
    run "$CORTEX" authentication-settings get
    [ "$status" -eq 0 ]
    echo "$output" | jq -e 'type == "array"' > /dev/null
    echo "$output" | jq -e 'length > 0' > /dev/null
    echo "$output" | jq -e '.[0].tenant_id | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.[0].sp_entity_id | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.[0].sp_url | type == "string" and length > 0' > /dev/null
}

@test "authentication-settings get typed decode succeeds" {
    run "$CORTEX_TEST" authentication-settings get
    [ "$status" -eq 0 ]
}

@test "authentication-settings get-metadata returns valid JSON with SP URLs" {
    run "$CORTEX" authentication-settings get-metadata
    [ "$status" -eq 0 ]
    echo "$output" | jq -e 'type == "object"' > /dev/null
    echo "$output" | jq -e '.tenant_id | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.sp_entity_id | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.sp_url | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.sp_logout_url | type == "string" and length > 0' > /dev/null
}

@test "authentication-settings get-metadata typed decode succeeds" {
    run "$CORTEX_TEST" authentication-settings get-metadata
    [ "$status" -eq 0 ]
}
