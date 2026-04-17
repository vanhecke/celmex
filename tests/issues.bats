#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "issues search returns valid JSON with DATA array" {
    run "$CORTEX" issues search
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.DATA | type == "array"' > /dev/null
}

@test "issues search typed decode succeeds" {
    run "$CORTEX_TEST" issues search
    [ "$status" -eq 0 ]
}
