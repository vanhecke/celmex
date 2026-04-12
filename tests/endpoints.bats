#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "endpoints list returns valid JSON with endpoints array" {
    run "$CORTEX" endpoints list
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.endpoints | type == "array"' > /dev/null
}
