#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "authentication-settings get returns valid JSON array" {
    run "$CORTEX" authentication-settings get
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "array"' > /dev/null
}
