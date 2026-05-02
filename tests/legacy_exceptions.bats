#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "legacy-exceptions get-modules returns valid JSON array" {
    run "$CORTEX" legacy-exceptions get-modules
    [ "$status" -eq 0 ]
    echo "$output" | jq -e 'type == "array"' > /dev/null
    echo "$output" | jq -e 'length > 0' > /dev/null
    echo "$output" | jq -e '.[0].module_id | type == "number"' > /dev/null
    echo "$output" | jq -e '.[0].pretty_name | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.[0].platforms | type == "array" and length > 0' > /dev/null
}

@test "legacy-exceptions get-modules typed decode succeeds" {
    run "$CORTEX_TEST" legacy-exceptions get-modules
    [ "$status" -eq 0 ]
}

@test "legacy-exceptions list returns valid JSON with DATA array" {
    run "$CORTEX" legacy-exceptions list
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.DATA | type == "array"' > /dev/null
    echo "$output" | jq -e '.TOTAL_COUNT | type == "number"' > /dev/null
    echo "$output" | jq -e '.FILTER_COUNT | type == "number"' > /dev/null
}

@test "legacy-exceptions list typed decode succeeds" {
    run "$CORTEX_TEST" legacy-exceptions list
    [ "$status" -eq 0 ]
}
