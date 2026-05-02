#!/usr/bin/env bats

bats_require_minimum_version 1.7.0

setup() {
    load test_helper/common
    load test_helper/fixtures
}

teardown() {
    cleanup_drain
}

# Build a minimal valid correlation-rule payload (request_data array with
# one entry). The live API requires far more fields than the OpenAPI spec
# marks as optional, including suppression_*, mitre_defs, alert_fields,
# search_window, simple_schedule, crontab, etc. Suppression is disabled
# so suppression_duration / suppression_fields are explicitly null per
# server-side validation. is_enabled is false so the rule never fires
# against real telemetry while it exists.
make_correlation_items() {
    local name="$1"
    jq -c -n --arg n "$name" '[
        {
            name: $n,
            severity: "SEV_020_LOW",
            xql_query: "dataset = xdr_data | fields _time | limit 1",
            is_enabled: false,
            description: "",
            alert_name: $n,
            alert_category: "OTHER",
            alert_description: "",
            alert_fields: {},
            execution_mode: "SCHEDULED",
            mapping_strategy: "AUTO",
            search_window: "1 hours",
            simple_schedule: "60 minutes",
            timezone: "UTC",
            crontab: "0 * * * *",
            suppression_enabled: false,
            suppression_duration: null,
            suppression_fields: null,
            dataset: "alerts",
            user_defined_severity: null,
            user_defined_category: null,
            mitre_defs: {},
            investigation_query_link: "",
            drilldown_query_timeframe: "ALERT"
        }
    ]'
}

# Register a delete by name so cleanup_drain fires it on test teardown.
register_correlation_cleanup() {
    local name="$1"
    cleanup_register /public_api/v1/correlations/delete \
        "$(jq -c -n --arg n "$name" '{request_data:{filters:[{field:"name",operator:"EQ",value:$n}]}}')"
}

# --- correlations get (read-only) --------------------------------------------

@test "correlations get returns valid JSON with objects array" {
    run "$CORTEX" correlations get
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.objects | type == "array"' > /dev/null
    echo "$output" | jq -e '.objects_count | type == "number"' > /dev/null
    echo "$output" | jq -e '.objects_type | type == "string" and length > 0' > /dev/null
}

@test "correlations get typed decode succeeds" {
    run "$CORTEX_TEST" correlations get
    [ "$status" -eq 0 ]
}

@test "correlations get --limit 1 succeeds" {
    run "$CORTEX" correlations get --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "correlations get invalid --filter exits non-zero" {
    run "$CORTEX" correlations get --filter bad
    [ "$status" -ne 0 ]
}

@test "correlations get invalid --extra JSON exits non-zero" {
    run "$CORTEX" correlations get --extra foo=not-json
    [ "$status" -ne 0 ]
}

# --- correlations insert + delete round-trip ---------------------------------

@test "correlations insert + delete round-trip via CLI" {
    name="$(fixture_name roundtrip)"
    items="$(make_correlation_items "$name")"
    register_correlation_cleanup "$name"

    run "$CORTEX" correlations insert "$items"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.added_objects | length == 1' > /dev/null
    echo "$output" | jq -e '.added_objects[0].id | type == "number"' > /dev/null
    echo "$output" | jq -e '.added_objects[0].status | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.errors | length == 0' > /dev/null

    list_output="$("$CORTEX" correlations get --filter "name=eq=$name")"
    echo "$list_output" | jq -e --arg n "$name" '.objects | map(select(.name == $n)) | length == 1' > /dev/null

    run "$CORTEX" correlations delete --filter "name=eq=$name"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.objects_count == 1' > /dev/null
    echo "$output" | jq -e '.objects | length == 1' > /dev/null
    echo "$output" | jq -e '.objects[0] | type == "number"' > /dev/null

    list_after="$("$CORTEX" correlations get --filter "name=eq=$name")"
    echo "$list_after" | jq -e --arg n "$name" '.objects | map(select(.name == $n)) | length == 0' > /dev/null
}

@test "correlations insert typed decode succeeds" {
    name="$(fixture_name typed_insert)"
    items="$(make_correlation_items "$name")"
    run "$CORTEX_TEST" correlations insert "$items"
    [ "$status" -eq 0 ]
}

@test "correlations delete typed decode succeeds" {
    run "$CORTEX_TEST" correlations delete --filter "name=eq=clxtest_unused"
    [ "$status" -eq 0 ]
}

# --- argument handling -------------------------------------------------------

@test "correlations insert without JSON exits non-zero" {
    run --separate-stderr "$CORTEX" correlations insert
    [ "$status" -ne 0 ]
}

@test "correlations insert with invalid JSON exits non-zero" {
    run --separate-stderr "$CORTEX" correlations insert "not-json"
    [ "$status" -ne 0 ]
}

@test "correlations delete without --filter exits non-zero" {
    run --separate-stderr "$CORTEX" correlations delete
    [ "$status" -ne 0 ]
}

@test "correlations delete with malformed --filter exits non-zero" {
    run --separate-stderr "$CORTEX" correlations delete --filter bad
    [ "$status" -ne 0 ]
}

@test "correlations delete with unsupported operator exits non-zero" {
    run --separate-stderr "$CORTEX" correlations delete --filter "name=neq=foo"
    [ "$status" -ne 0 ]
}
