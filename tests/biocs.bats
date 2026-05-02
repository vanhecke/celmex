#!/usr/bin/env bats

bats_require_minimum_version 1.7.0

setup() {
    load test_helper/common
    load test_helper/fixtures
}

teardown() {
    cleanup_drain
}

# Build a minimal valid BIOC payload (request_data array with one entry).
# Wraps the indicator DSL — a FILE_EVENT match on a sentinel string that
# never fires on real telemetry — so tests don't pollute detections.
make_bioc_items() {
    local name="$1"
    jq -c -n --arg n "$name" '[
        {
            name: $n,
            type: "EXECUTION",
            severity: "SEV_020_LOW",
            comment: "",
            status: "ENABLED",
            is_xql: false,
            indicator: {
                runOnCGO: false,
                investigationType: "FILE_EVENT",
                investigation: {
                    FILE_EVENT: {
                        filter: {
                            AND: [{
                                SEARCH_FIELD: "action_file_name",
                                SEARCH_TYPE: "EQ",
                                SEARCH_VALUE: "clxtest_marker",
                                EXTRA_FIELDS: [],
                                isExtended: false
                            }]
                        }
                    }
                }
            },
            mitre_tactic_id_and_name: [],
            mitre_technique_id_and_name: []
        }
    ]'
}

# Register a delete by name so cleanup_drain fires it on test teardown.
register_bioc_cleanup() {
    local name="$1"
    cleanup_register /public_api/v1/bioc/delete \
        "$(jq -c -n --arg n "$name" '{request_data:{filters:[{field:"name",operator:"EQ",value:$n}]}}')"
}

# --- bioc list (read-only) ---------------------------------------------------

@test "bioc list returns valid JSON with objects array" {
    run "$CORTEX" bioc list
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.objects | type == "array"' > /dev/null
    echo "$output" | jq -e '.objects_count | type == "number"' > /dev/null
    echo "$output" | jq -e '.objects_type | type == "string" and length > 0' > /dev/null
}

@test "bioc list typed decode succeeds" {
    run "$CORTEX_TEST" bioc list
    [ "$status" -eq 0 ]
}

@test "bioc list --limit 1 succeeds" {
    run "$CORTEX" bioc list --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "bioc list invalid --filter exits non-zero" {
    run "$CORTEX" bioc list --filter bad
    [ "$status" -ne 0 ]
}

@test "bioc list invalid --extra JSON exits non-zero" {
    run "$CORTEX" bioc list --extra foo=not-json
    [ "$status" -ne 0 ]
}

# --- bioc insert + delete round-trip -----------------------------------------

@test "bioc insert + delete round-trip via CLI" {
    name="$(fixture_name roundtrip)"
    items="$(make_bioc_items "$name")"
    register_bioc_cleanup "$name"

    run "$CORTEX" bioc insert "$items"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.added_objects | length == 1' > /dev/null
    echo "$output" | jq -e '.added_objects[0].id | type == "number"' > /dev/null
    echo "$output" | jq -e '.added_objects[0].status | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.errors | length == 0' > /dev/null

    list_output="$("$CORTEX" bioc list --filter "name=eq=$name")"
    echo "$list_output" | jq -e --arg n "$name" '.objects | map(select(.name == $n)) | length == 1' > /dev/null

    run "$CORTEX" bioc delete --filter "name=eq=$name"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.objects_count == 1' > /dev/null
    echo "$output" | jq -e '.objects | length == 1' > /dev/null
    echo "$output" | jq -e '.objects[0] | type == "number"' > /dev/null

    list_after="$("$CORTEX" bioc list --filter "name=eq=$name")"
    echo "$list_after" | jq -e --arg n "$name" '.objects | map(select(.name == $n)) | length == 0' > /dev/null
}

@test "bioc insert typed decode succeeds" {
    # TestMain skips actual dispatch for mutating endpoints — this verifies
    # the CLI parser accepts the same argv shape the runtime would use.
    name="$(fixture_name typed_insert)"
    items="$(make_bioc_items "$name")"
    run "$CORTEX_TEST" bioc insert "$items"
    [ "$status" -eq 0 ]
}

@test "bioc delete typed decode succeeds" {
    run "$CORTEX_TEST" bioc delete --filter "name=eq=clxtest_unused"
    [ "$status" -eq 0 ]
}

# --- argument handling -------------------------------------------------------

@test "bioc insert without JSON exits non-zero" {
    run --separate-stderr "$CORTEX" bioc insert
    [ "$status" -ne 0 ]
}

@test "bioc insert with invalid JSON exits non-zero" {
    run --separate-stderr "$CORTEX" bioc insert "not-json"
    [ "$status" -ne 0 ]
}

@test "bioc delete without --filter exits non-zero" {
    run --separate-stderr "$CORTEX" bioc delete
    [ "$status" -ne 0 ]
}

@test "bioc delete with malformed --filter exits non-zero" {
    run --separate-stderr "$CORTEX" bioc delete --filter bad
    [ "$status" -ne 0 ]
}

@test "bioc delete with unsupported operator exits non-zero" {
    run --separate-stderr "$CORTEX" bioc delete --filter "name=contains=foo"
    [ "$status" -ne 0 ]
}
