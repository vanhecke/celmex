#!/usr/bin/env bats

setup() {
    load test_helper/common
}

# Forensics triage presets require the Forensics add-on / XSIAM Premium
# license; tenants without it surface as HTTP 402 or "License is inactive".
skip_if_unlicensed() {
    if [[ "$output" == *"License is inactive"* ]] \
        || [[ "$output" == *"HTTP 402"* ]] \
        || [[ "$output" == *"feature not supported"* ]]; then
        skip "tenant does not have the Forensics add-on"
    fi
}

@test "triage-presets list returns valid JSON with triage_presets array" {
    run "$CORTEX" triage-presets list
    skip_if_unlicensed
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.triage_presets | type == "array"' > /dev/null
}

@test "triage-presets list typed decode succeeds" {
    run "$CORTEX_TEST" triage-presets list
    skip_if_unlicensed
    [ "$status" -eq 0 ]
}
