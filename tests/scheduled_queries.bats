#!/usr/bin/env bats

bats_require_minimum_version 1.7.0

setup() {
    load test_helper/common
    load test_helper/fixtures
}

teardown() {
    cleanup_drain
}

# Register a delete by query_id so cleanup_drain fires it on test teardown.
register_scheduled_query_cleanup() {
    local query_id="$1"
    cleanup_register /public_api/v1/scheduled_queries/delete \
        "$(jq -c -n --arg q "$query_id" '{request_data:[$q]}')"
}

# --- scheduled-queries list (read-only) --------------------------------------

@test "scheduled-queries list returns valid JSON with DATA array" {
    run "$CORTEX" scheduled-queries list
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.DATA | type == "array"' > /dev/null
    echo "$output" | jq -e '.TOTAL_COUNT | type == "number"' > /dev/null
    echo "$output" | jq -e '.FILTER_COUNT | type == "number"' > /dev/null
}

@test "scheduled-queries list typed decode succeeds" {
    run "$CORTEX_TEST" scheduled-queries list
    [ "$status" -eq 0 ]
}

@test "scheduled-queries list --limit 1 succeeds" {
    run "$CORTEX" scheduled-queries list --limit 1
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
}

@test "scheduled-queries list invalid --filter exits non-zero" {
    run "$CORTEX" scheduled-queries list --filter bad
    [ "$status" -ne 0 ]
}

@test "scheduled-queries list invalid --extra JSON exits non-zero" {
    run "$CORTEX" scheduled-queries list --extra foo=not-json
    [ "$status" -ne 0 ]
}

# --- scheduled-queries insert + delete round-trip ----------------------------

@test "scheduled-queries insert + delete round-trip via CLI" {
    name="$(fixture_name roundtrip)"

    # --run-at sits well past 2100 so the one-shot trigger never actually
    # fires while the fixture is alive (epoch-ms 4677621540000 ≈ year 2118).
    run "$CORTEX" scheduled-queries insert "$name" "dataset = xdr_data | limit 1" \
        --relative 86400000 --run-at 4677621540000
    [ "$status" -eq 0 ]
    query_id="$(echo "$output" | jq -r 'keys[0]')"
    [ -n "$query_id" ]
    [ "$query_id" != "null" ]
    register_scheduled_query_cleanup "$query_id"

    echo "$output" | jq -e --arg q "$query_id" '.[$q].query_definition_name' > /dev/null
    echo "$output" | jq -e --arg q "$query_id" --arg n "$name" '.[$q].query_definition_name == $n' > /dev/null

    list_output="$("$CORTEX" scheduled-queries list)"
    echo "$list_output" | jq -e --arg n "$name" '.DATA | map(select(.query_definition_name == $n)) | length == 1' > /dev/null

    run "$CORTEX" scheduled-queries delete --id "$query_id"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e --arg q "$query_id" '.[$q] == true' > /dev/null

    list_after="$("$CORTEX" scheduled-queries list)"
    echo "$list_after" | jq -e --arg n "$name" '.DATA | map(select(.query_definition_name == $n)) | length == 0' > /dev/null
}

@test "scheduled-queries insert typed decode succeeds" {
    name="$(fixture_name typed_insert)"
    run "$CORTEX_TEST" scheduled-queries insert "$name" "dataset = xdr_data | limit 1" \
        --relative 86400000 --run-at 4677621540000
    [ "$status" -eq 0 ]
}

@test "scheduled-queries delete typed decode succeeds" {
    run "$CORTEX_TEST" scheduled-queries delete --id "clxtest_unused"
    [ "$status" -eq 0 ]
}

# --- argument handling -------------------------------------------------------

@test "scheduled-queries insert without args exits non-zero" {
    run --separate-stderr "$CORTEX" scheduled-queries insert
    [ "$status" -ne 0 ]
}

@test "scheduled-queries insert without --relative exits non-zero" {
    run --separate-stderr "$CORTEX" scheduled-queries insert "n" "q" --run-at 4677621540000
    [ "$status" -ne 0 ]
}

@test "scheduled-queries insert without --run-at exits non-zero" {
    run --separate-stderr "$CORTEX" scheduled-queries insert "n" "q" --relative 86400000
    [ "$status" -ne 0 ]
}

@test "scheduled-queries delete without --id exits non-zero" {
    run --separate-stderr "$CORTEX" scheduled-queries delete
    [ "$status" -ne 0 ]
}
