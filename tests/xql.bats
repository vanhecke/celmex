#!/usr/bin/env bats

bats_require_minimum_version 1.7.0

setup() {
    load test_helper/common
    load test_helper/fixtures
}

teardown() {
    cleanup_drain
}

# Register a delete by name so cleanup_drain fires it on test teardown.
register_xql_library_cleanup() {
    local name="$1"
    cleanup_register /public_api/xql_library/delete \
        "$(jq -c -n --arg n "$name" '{request_data:{xql_query_names:[$n]}}')"
}

@test "xql get-quota returns valid JSON object" {
    run "$CORTEX" xql get-quota
    [ "$status" -eq 0 ]
    echo "$output" | jq -e 'type == "object"' > /dev/null
    echo "$output" | jq -e '.license_quota | type == "number"' > /dev/null
    echo "$output" | jq -e '.used_quota | type == "number"' > /dev/null
}

@test "xql get-quota typed decode succeeds" {
    run "$CORTEX_TEST" xql get-quota
    [ "$status" -eq 0 ]
}

@test "xql get-datasets returns valid JSON array" {
    run "$CORTEX" xql get-datasets
    [ "$status" -eq 0 ]
    echo "$output" | jq -e 'type == "array" and length > 0' > /dev/null
    echo "$output" | jq -e '.[0]."Dataset Name" | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.[0]."Type" | type == "string" and length > 0' > /dev/null
}

@test "xql get-datasets typed decode succeeds" {
    run "$CORTEX_TEST" xql get-datasets
    [ "$status" -eq 0 ]
}

@test "xql-library get returns valid JSON with xql_queries array" {
    run "$CORTEX" xql-library get
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.xql_queries | type == "array" and length > 0' > /dev/null
    echo "$output" | jq -e '.queries_count | type == "number" and . > 0' > /dev/null
    echo "$output" | jq -e '.xql_queries[0].xql_query_name | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.xql_queries[0].xql_query | type == "string" and length > 0' > /dev/null
}

@test "xql-library get typed decode succeeds" {
    run "$CORTEX_TEST" xql-library get
    [ "$status" -eq 0 ]
}

@test "xql query starts a query and returns a query_id" {
    run "$CORTEX" xql query "dataset = xdr_data | limit 1" --relative 86400000
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.query_id | type == "string"' > /dev/null
}

@test "xql query typed decode succeeds" {
    run "$CORTEX_TEST" xql query "dataset = xdr_data | limit 1" --relative 86400000
    [ "$status" -eq 0 ]
}

@test "xql query --poll returns final results" {
    run "$CORTEX" xql query --poll "dataset = xdr_data | limit 1" --relative 86400000
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.status' > /dev/null
    echo "$output" | jq -e '.status != "PENDING"' > /dev/null
}

@test "xql get-results returns status for a known query_id" {
    query_id=$("$CORTEX" xql query "dataset = xdr_data | limit 1" --relative 86400000 | jq -r .query_id)
    [ -n "$query_id" ]
    run "$CORTEX" xql get-results "$query_id"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.status | type == "string"' > /dev/null
}

@test "xql lookups get-data surfaces a valid response or a tenant error" {
    run "$CORTEX" xql lookups get-data celmex_nonexistent_probe
    # Either success (dataset exists) or a BadStatus (dataset missing) — both
    # exercise the CLI argv + raw-decoder path. A decoder / transport bug would
    # produce neither.
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# --- xql-library insert + delete round-trip ----------------------------------

@test "xql-library insert + delete round-trip via CLI" {
    name="$(fixture_name roundtrip)"
    register_xql_library_cleanup "$name"

    run "$CORTEX" xql-library insert "$name" "dataset = xdr_data | limit 1"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e --arg n "$name" '.xql_queries_added | index($n) | type == "number"' > /dev/null
    echo "$output" | jq -e '.errors | length == 0' > /dev/null

    list_output="$("$CORTEX" xql-library get)"
    echo "$list_output" | jq -e --arg n "$name" '.xql_queries | map(select(.xql_query_name == $n)) | length == 1' > /dev/null

    run "$CORTEX" xql-library delete --name "$name"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.queries_count == 1' > /dev/null
    echo "$output" | jq -e --arg n "$name" '.xql_query_names | index($n) | type == "number"' > /dev/null
    echo "$output" | jq -e '.errors | length == 0' > /dev/null

    list_after="$("$CORTEX" xql-library get)"
    echo "$list_after" | jq -e --arg n "$name" '.xql_queries | map(select(.xql_query_name == $n)) | length == 0' > /dev/null
}

@test "xql-library insert typed decode succeeds" {
    name="$(fixture_name typed_insert)"
    run "$CORTEX_TEST" xql-library insert "$name" "dataset = xdr_data | limit 1"
    [ "$status" -eq 0 ]
}

@test "xql-library delete typed decode succeeds" {
    run "$CORTEX_TEST" xql-library delete --name "clxtest_unused"
    [ "$status" -eq 0 ]
}

# --- argument handling -------------------------------------------------------

@test "xql-library insert without args exits non-zero" {
    run --separate-stderr "$CORTEX" xql-library insert
    [ "$status" -ne 0 ]
}

@test "xql-library insert with only one positional exits non-zero" {
    run --separate-stderr "$CORTEX" xql-library insert "name-only"
    [ "$status" -ne 0 ]
}

@test "xql-library delete without selector exits non-zero" {
    run --separate-stderr "$CORTEX" xql-library delete
    [ "$status" -ne 0 ]
}

@test "xql-library delete with both --name and --tag exits non-zero" {
    run --separate-stderr "$CORTEX" xql-library delete --name a --tag b
    [ "$status" -ne 0 ]
}
