#!/usr/bin/env bats

setup() {
    load test_helper/common
}

@test "asset-groups list returns valid JSON with data array" {
    run "$CORTEX" asset-groups list
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.data | type == "array" and length > 0' > /dev/null
    echo "$output" | jq -e '.data[0]."XDM.ASSET_GROUP.ID" | type == "number"' > /dev/null
    echo "$output" | jq -e '.data[0]."XDM.ASSET_GROUP.NAME" | type == "string" and length > 0' > /dev/null
    echo "$output" | jq -e '.data[0]."XDM.ASSET_GROUP.TYPE" | type == "string" and length > 0' > /dev/null
}

@test "asset-groups list typed decode succeeds" {
    run "$CORTEX_TEST" asset-groups list
    [ "$status" -eq 0 ]
}
