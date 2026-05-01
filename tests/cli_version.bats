#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "cli version returns valid JSON with version field" {
    run "$CORTEX" cli version
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.version | type == "string"' > /dev/null
    echo "$output" | jq -e '.version | length > 0' > /dev/null
}

@test "cli version typed decode succeeds" {
    run "$CORTEX_TEST" cli version
    [ "$status" -eq 0 ]
}
