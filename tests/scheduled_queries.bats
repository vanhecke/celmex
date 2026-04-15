#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "scheduled-queries list returns valid JSON with DATA array" {
    run "$CORTEX" scheduled-queries list
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.DATA | type == "array"' > /dev/null
}
