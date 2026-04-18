#!/usr/bin/env bats

# Parser coverage for Cli.StandardFlags. Every test here is a pure-parser
# check that exits non-zero before any network call; we only assert the exit
# code (text matches against stderr are race-prone with Node's async flush
# on process.exit). Positive/semantic coverage of each operator depends on
# per-tenant schema validity, so it lives in the endpoint-specific tests
# (cases.bats, issues.bats, audit_logs.bats) with a known-valid field.

setup() {
    load test_helper/common
}

@test "--filter without field=op=value is rejected" {
    run "$CORTEX" issues search --filter bad
    [ "$status" -ne 0 ]
}

@test "--filter unknown operator is rejected" {
    run "$CORTEX" issues search --filter severity=unknown=high
    [ "$status" -ne 0 ]
}

@test "--filter gt rejects non-integer value" {
    run "$CORTEX" issues search --filter creation_time=gt=notanumber
    [ "$status" -ne 0 ]
}

@test "--sort without field:direction is rejected" {
    run "$CORTEX" issues search --sort no_colon
    [ "$status" -ne 0 ]
}

@test "--sort with unknown direction is rejected" {
    run "$CORTEX" issues search --sort field:sideways
    [ "$status" -ne 0 ]
}

@test "--range with non-integer bound is rejected" {
    run "$CORTEX" issues search --range 0:oops
    [ "$status" -ne 0 ]
}

@test "--range and --limit are mutually exclusive" {
    run "$CORTEX" issues search --range 0:10 --limit 5
    [ "$status" -ne 0 ]
}

@test "--offset without --limit is rejected" {
    run "$CORTEX" issues search --offset 5
    [ "$status" -ne 0 ]
}

@test "--from without --to is rejected" {
    run "$CORTEX" issues search --from 0
    [ "$status" -ne 0 ]
}

@test "--to without --from is rejected" {
    run "$CORTEX" issues search --to 0
    [ "$status" -ne 0 ]
}

@test "--relative and --from/--to are mutually exclusive" {
    run "$CORTEX" issues search --relative 3600000 --from 0 --to 1
    [ "$status" -ne 0 ]
}

@test "--extra with invalid JSON is rejected" {
    run "$CORTEX" issues search --extra foo=not-json
    [ "$status" -ne 0 ]
}

@test "--extra without = is rejected" {
    run "$CORTEX" issues search --extra nokey
    [ "$status" -ne 0 ]
}
