#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "xql get-quota returns valid JSON object" {
    run "$CORTEX" xql get-quota
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "object"' > /dev/null
}

@test "xql get-quota typed decode succeeds" {
    run "$CORTEX_TEST" xql get-quota
    [ "$status" -eq 0 ]
}

@test "xql get-datasets returns valid JSON array" {
    run "$CORTEX" xql get-datasets
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "array"' > /dev/null
}

@test "xql get-datasets typed decode succeeds" {
    run "$CORTEX_TEST" xql get-datasets
    [ "$status" -eq 0 ]
}

@test "xql-library get returns valid JSON with xql_queries array" {
    run "$CORTEX" xql-library get
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.xql_queries | type == "array"' > /dev/null
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
