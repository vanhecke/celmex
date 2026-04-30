#!/usr/bin/env bats

setup() {
    load test_helper/common
}

# /public_api/v1/quarantine/status returns one entry per requested file with a
# boolean `status` (true = quarantined, false = not). The endpoint accepts any
# well-formed file query and reports `status: false` for files it does not
# know about, so a fixed fake input is enough to exercise the response shape.

FAKE_ENDPOINT_ID="0000000000000000000000000000abcd"
FAKE_FILE_PATH='C:\test\foo.exe'
FAKE_FILE_HASH="0000000000000000000000000000000000000000000000000000000000000000"

@test "quarantine status returns reply array with status booleans" {
    run "$CORTEX" quarantine status \
        "$FAKE_ENDPOINT_ID" "$FAKE_FILE_PATH" "$FAKE_FILE_HASH"
    [ "$status" -eq 0 ]
    echo "$output" | jq . > /dev/null
    echo "$output" | jq -e 'type == "array"' > /dev/null
    echo "$output" | jq -e 'length >= 1' > /dev/null
    echo "$output" | jq -e '.[0].status | type == "boolean"' > /dev/null
    echo "$output" | jq -e '.[0].endpoint_id | type == "string"' > /dev/null
    echo "$output" | jq -e '.[0].file_path | type == "string"' > /dev/null
    echo "$output" | jq -e '.[0].file_hash | type == "string"' > /dev/null
}

@test "quarantine status echoes the requested file fields back" {
    run "$CORTEX" quarantine status \
        "$FAKE_ENDPOINT_ID" "$FAKE_FILE_PATH" "$FAKE_FILE_HASH"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e --arg id "$FAKE_ENDPOINT_ID" \
        '.[0].endpoint_id == $id' > /dev/null
    echo "$output" | jq -e --arg h "$FAKE_FILE_HASH" \
        '.[0].file_hash == $h' > /dev/null
    # Unknown file → status MUST be false on a clean tenant.
    echo "$output" | jq -e '.[0].status == false' > /dev/null
}

@test "quarantine status typed decode succeeds" {
    run "$CORTEX_TEST" quarantine status \
        "$FAKE_ENDPOINT_ID" "$FAKE_FILE_PATH" "$FAKE_FILE_HASH"
    [ "$status" -eq 0 ]
}

# --- CLI argument handling ---

@test "quarantine status with missing args reports usage" {
    run "$CORTEX" quarantine status "$FAKE_ENDPOINT_ID"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown command"* ]] || [[ "$output" == *"Usage"* ]]
}

@test "quarantine status with too many args reports usage" {
    run "$CORTEX" quarantine status \
        "$FAKE_ENDPOINT_ID" "$FAKE_FILE_PATH" "$FAKE_FILE_HASH" extra
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown command"* ]] || [[ "$output" == *"Usage"* ]]
}

# --- Per-parameter test using a real endpoint id from the tenant ---

first_endpoint_id() {
    "$CORTEX" endpoints list 2>/dev/null \
        | jq -r '.[0].agent_id // empty'
}

@test "quarantine status with a real endpoint id still returns valid response" {
    eid="$(first_endpoint_id)"
    [ -n "$eid" ] || skip "no endpoints on this tenant"
    run "$CORTEX" quarantine status \
        "$eid" "$FAKE_FILE_PATH" "$FAKE_FILE_HASH"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e --arg id "$eid" \
        '.[0].endpoint_id == $id' > /dev/null
    echo "$output" | jq -e '.[0].status | type == "boolean"' > /dev/null
}
