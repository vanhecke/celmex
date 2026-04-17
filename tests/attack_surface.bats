#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "attack-surface get-rules returns valid JSON with rules array" {
    run "$CORTEX" attack-surface get-rules
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.attack_surface_rules | type == "array"' > /dev/null
}

@test "attack-surface get-rules typed decode succeeds" {
    run "$CORTEX_TEST" attack-surface get-rules
    [ "$status" -eq 0 ]
}
