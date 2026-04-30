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

@test "distributions get-versions typed decode succeeds" {
    run "$CORTEX_TEST" distributions get-versions
    [ "$status" -eq 0 ]
}

@test "distributions list returns valid JSON with data array" {
    run "$CORTEX" distributions list
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.data | type == "array"' > /dev/null
}

@test "distributions list typed decode succeeds" {
    run "$CORTEX_TEST" distributions list
    [ "$status" -eq 0 ]
}

# get-status / get-dist-url need a real distribution_id from the tenant.
# Pick the first one from `distributions list`; skip if none exist.
first_distribution() {
    "$CORTEX" distributions list 2>/dev/null \
        | jq -r '.data[0] // empty | "\(.distribution_id)\t\(.supported_packages[0])"'
}

@test "distributions get-status returns valid JSON with status" {
    pair="$(first_distribution)"
    [ -n "$pair" ] || skip "no distributions on this tenant"
    id="$(echo "$pair" | cut -f1)"
    run "$CORTEX" distributions get-status "$id"
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.status | type == "string"' > /dev/null
}

@test "distributions get-status typed decode succeeds" {
    pair="$(first_distribution)"
    [ -n "$pair" ] || skip "no distributions on this tenant"
    id="$(echo "$pair" | cut -f1)"
    run "$CORTEX_TEST" distributions get-status "$id"
    [ "$status" -eq 0 ]
}

@test "distributions get-dist-url returns valid JSON with distribution_url" {
    pair="$(first_distribution)"
    [ -n "$pair" ] || skip "no distributions on this tenant"
    id="$(echo "$pair" | cut -f1)"
    pkg="$(echo "$pair" | cut -f2)"
    [ -n "$pkg" ] || skip "distribution has no supported_packages"
    run "$CORTEX" distributions get-dist-url "$id" "$pkg"
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e '.distribution_url | type == "string"' > /dev/null
}

@test "distributions get-dist-url typed decode succeeds" {
    pair="$(first_distribution)"
    [ -n "$pair" ] || skip "no distributions on this tenant"
    id="$(echo "$pair" | cut -f1)"
    pkg="$(echo "$pair" | cut -f2)"
    [ -n "$pkg" ] || skip "distribution has no supported_packages"
    run "$CORTEX_TEST" distributions get-dist-url "$id" "$pkg"
    [ "$status" -eq 0 ]
}
