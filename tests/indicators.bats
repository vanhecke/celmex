#!/usr/bin/env bats

bats_require_minimum_version 1.7.0

setup() {
    load test_helper/common
    load test_helper/fixtures
}

teardown() {
    cleanup_drain
}

# Build a minimal valid IOC payload (request_data array with one entry).
# Uses type=FILENAME so the fixture name slots into the indicator field
# without colliding with hash/IP/domain shapes.
make_indicator_items() {
    local name="$1"
    jq -c -n --arg n "$name" '[
        {
            indicator: $n,
            type: "FILENAME",
            severity: "SEV_020_LOW",
            comment: "",
            default_expiration_enabled: true,
            expiration_date: 0,
            reliability: null,
            reputation: null
        }
    ]'
}

# Register a delete by indicator so cleanup_drain fires it on test teardown.
register_indicator_cleanup() {
    local name="$1"
    cleanup_register /public_api/v1/indicators/delete \
        "$(jq -c -n --arg n "$name" '{request_data:{filters:[{field:"indicator",operator:"EQ",value:$n}]}}')"
}

# --- indicators get (read-only) ----------------------------------------------

@test "indicators get returns valid JSON with objects array" {
    run "$CORTEX" indicators get
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.objects | type == "array"' > /dev/null
    echo "$output" | jq -e '.objects_count | type == "number"' > /dev/null
    echo "$output" | jq -e '.objects_type | type == "string" and length > 0' > /dev/null
}

@test "indicators get typed decode succeeds" {
    run "$CORTEX_TEST" indicators get
    [ "$status" -eq 0 ]
}

@test "indicators get --limit 1 succeeds" {
    run "$CORTEX" indicators get --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "indicators get invalid --filter exits non-zero" {
    run "$CORTEX" indicators get --filter bad
    [ "$status" -ne 0 ]
}

@test "indicators get invalid --extra JSON exits non-zero" {
    run "$CORTEX" indicators get --extra foo=not-json
    [ "$status" -ne 0 ]
}

# --- indicators insert + delete round-trip -----------------------------------

@test "indicators insert + delete round-trip via CLI" {
    name="$(fixture_name roundtrip)"
    items="$(make_indicator_items "$name")"
    register_indicator_cleanup "$name"

    run "$CORTEX" indicators insert "$items"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.added_objects | length == 1' > /dev/null
    echo "$output" | jq -e '.added_objects[0].id | type == "number"' > /dev/null
    echo "$output" | jq -e '.added_objects[0].status | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.errors | length == 0' > /dev/null

    list_output="$("$CORTEX" indicators get --filter "indicator=eq=$name")"
    echo "$list_output" | jq -e --arg n "$name" '.objects | map(select(.indicator == $n)) | length == 1' > /dev/null

    run "$CORTEX" indicators delete --filter "indicator=eq=$name"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.objects_count == 1' > /dev/null
    echo "$output" | jq -e '.objects | length == 1' > /dev/null
    echo "$output" | jq -e '.objects[0] | type == "number"' > /dev/null

    list_after="$("$CORTEX" indicators get --filter "indicator=eq=$name")"
    echo "$list_after" | jq -e --arg n "$name" '.objects | map(select(.indicator == $n)) | length == 0' > /dev/null
}

@test "indicators insert typed decode succeeds" {
    name="$(fixture_name typed_insert)"
    items="$(make_indicator_items "$name")"
    run "$CORTEX_TEST" indicators insert "$items"
    [ "$status" -eq 0 ]
}

@test "indicators delete typed decode succeeds" {
    run "$CORTEX_TEST" indicators delete --filter "indicator=eq=clxtest_unused"
    [ "$status" -eq 0 ]
}

# --- argument handling -------------------------------------------------------

@test "indicators insert without JSON exits non-zero" {
    run --separate-stderr "$CORTEX" indicators insert
    [ "$status" -ne 0 ]
}

@test "indicators insert with invalid JSON exits non-zero" {
    run --separate-stderr "$CORTEX" indicators insert "not-json"
    [ "$status" -ne 0 ]
}

@test "indicators delete without --filter exits non-zero" {
    run --separate-stderr "$CORTEX" indicators delete
    [ "$status" -ne 0 ]
}

@test "indicators delete with malformed --filter exits non-zero" {
    run --separate-stderr "$CORTEX" indicators delete --filter bad
    [ "$status" -ne 0 ]
}

@test "indicators delete with unsupported operator exits non-zero" {
    run --separate-stderr "$CORTEX" indicators delete --filter "indicator=contains=foo"
    [ "$status" -ne 0 ]
}
