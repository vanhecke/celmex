#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "attack-surface get-rules returns valid JSON with rules array" {
    run "$CORTEX" attack-surface get-rules
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.attack_surface_rules | type == "array" and length > 0' > /dev/null
    echo "$output" | jq -e '.total_count | type == "number" and . > 0' > /dev/null
    echo "$output" | jq -e '.result_count | type == "number" and . > 0' > /dev/null
    echo "$output" | jq -e '.attack_surface_rules[0].attack_surface_rule_id | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.attack_surface_rules[0].priority | type == "string" and length > 0' > /dev/null
}

@test "attack-surface get-rules typed decode succeeds" {
    run "$CORTEX_TEST" attack-surface get-rules
    [ "$status" -eq 0 ]
}
