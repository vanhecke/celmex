#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "assets list returns valid JSON with data array" {
    run "$CORTEX" assets list
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.data | type == "array"' > /dev/null
}

@test "assets list typed decode succeeds" {
    run "$CORTEX_TEST" assets list
    [ "$status" -eq 0 ]
}

@test "assets schema returns valid JSON with data array" {
    run "$CORTEX" assets schema
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.data | type == "array"' > /dev/null
}

@test "assets schema typed decode succeeds" {
    run "$CORTEX_TEST" assets schema
    [ "$status" -eq 0 ]
}

@test "assets external-services returns valid JSON with external_services array" {
    run "$CORTEX" assets external-services
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.external_services | type == "array"' > /dev/null
}

@test "assets external-services typed decode succeeds" {
    run "$CORTEX_TEST" assets external-services
    [ "$status" -eq 0 ]
}

@test "assets internet-exposures returns valid JSON" {
    run "$CORTEX" assets internet-exposures
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.assets_internet_exposure | type == "array"' > /dev/null
}

@test "assets internet-exposures typed decode succeeds" {
    run "$CORTEX_TEST" assets internet-exposures
    [ "$status" -eq 0 ]
}

@test "assets ip-ranges returns valid JSON" {
    run "$CORTEX" assets ip-ranges
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.external_ip_address_ranges | type == "array"' > /dev/null
}

@test "assets ip-ranges typed decode succeeds" {
    run "$CORTEX_TEST" assets ip-ranges
    [ "$status" -eq 0 ]
}

@test "assets vulnerability-tests returns valid JSON" {
    run "$CORTEX" assets vulnerability-tests
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.vulnerability_tests | type == "array"' > /dev/null
}

@test "assets vulnerability-tests typed decode succeeds" {
    run "$CORTEX_TEST" assets vulnerability-tests
    [ "$status" -eq 0 ]
}

@test "assets external-websites returns valid JSON" {
    run "$CORTEX" assets external-websites
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.websites | type == "array"' > /dev/null
}

@test "assets external-websites typed decode succeeds" {
    run "$CORTEX_TEST" assets external-websites
    [ "$status" -eq 0 ]
}

@test "assets websites-last-assessment returns valid JSON" {
    run "$CORTEX" assets websites-last-assessment
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.last_external_assessment' > /dev/null
}

@test "assets websites-last-assessment typed decode succeeds" {
    run "$CORTEX_TEST" assets websites-last-assessment
    [ "$status" -eq 0 ]
}
