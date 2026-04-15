#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "distributions get-versions returns valid JSON with OS arrays" {
    run "$CORTEX" distributions get-versions
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.windows | type == "array"' > /dev/null
    echo "$output" | jq -e '.linux | type == "array"' > /dev/null
    echo "$output" | jq -e '.macos | type == "array"' > /dev/null
}

@test "distributions list returns valid JSON with data array" {
    run "$CORTEX" distributions list
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.data | type == "array"' > /dev/null
}
