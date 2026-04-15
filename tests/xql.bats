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

@test "xql get-datasets returns valid JSON array" {
    run "$CORTEX" xql get-datasets
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "array"' > /dev/null
}

@test "xql-library get returns valid JSON with xql_queries array" {
    run "$CORTEX" xql-library get
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.xql_queries | type == "array"' > /dev/null
}
