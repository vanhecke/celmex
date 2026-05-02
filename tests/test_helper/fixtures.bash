#!/usr/bin/env bash
# Fixture helpers for write-endpoint integration tests.
#
# Load AFTER test_helper/common (which sets BATS_RUN_ID and the
# $CORTEX / $CORTEX_TEST paths). Tests that mutate the live tenant must
# follow the create -> list -> delete round-trip described in
# tests/SETUP_TEARDOWN.md.

CORTEX_CURL="${CORTEX_CURL:-./cli/bin/cortex-curl}"

# fixture_name <slug>
#
# Emits a tenant-unique object name: clxtest_<run-id>_<file>_<slug>
# Underscore-only because some Cortex endpoints (xql dataset names)
# silently coerce hyphens to underscores. The clxtest_ prefix is what
# the reaper (cli/bin/cortex-test-clean) greps for, so DO NOT change
# it. <slug> is sanitized: any character outside [a-zA-Z0-9_] is
# replaced with _.
fixture_name() {
    local slug="$1"
    : "${BATS_RUN_ID:?BATS_RUN_ID not exported - load test_helper/common first}"
    local file safe_slug
    file="$(basename "${BATS_TEST_FILENAME:-unknown}" .bats)"
    safe_slug="${slug//[^a-zA-Z0-9_]/_}"
    printf 'clxtest_%s_%s_%s\n' "$BATS_RUN_ID" "$file" "$safe_slug"
}

# cortex_post <path> <json-body>
#
# Thin wrapper around cortex-curl POST. Echoes the response body. Does
# NOT check HTTP status - callers are responsible for asserting on the
# response shape. Use this in setup_file / teardown_file and round-trip
# tests where the CLI command for the endpoint may not exist yet.
cortex_post() {
    "$CORTEX_CURL" POST "$1" "${2:-}"
}

# cleanup_register <path> <json-body>
#
# Append a delete call to the per-test cleanup queue. Replayed in LIFO
# order by cleanup_drain (called from teardown). Use this in single-test
# round-trips where create+delete live in one @test - if an assertion
# fails between them, teardown still fires the delete.
#
# Scoped to BATS_TEST_TMPDIR (per-test) rather than BATS_FILE_TMPDIR
# because BATS >= 1.7 parallelises tests within a file by default; a
# shared per-file queue would race across concurrent tests, with one
# test's teardown draining another test's still-needed cleanups before
# the owning test finishes its own delete.
cleanup_register() {
    : "${BATS_TEST_TMPDIR:?BATS_TEST_TMPDIR unset - bats 1.7+ required}"
    local queue="$BATS_TEST_TMPDIR/cleanup-queue"
    # tab-separated: path \t body. body is base64'd to survive newlines.
    printf '%s\t%s\n' "$1" "$(printf '%s' "${2:-}" | base64)" >> "$queue"
}

# cleanup_drain
#
# Replay the cleanup queue in LIFO order, swallowing errors so one
# failed delete does not block the rest. Tests should call this from
# teardown(); it is a no-op when the queue is empty.
cleanup_drain() {
    local queue="${BATS_TEST_TMPDIR:-}/cleanup-queue"
    [[ -f "$queue" ]] || return 0
    local path body_b64 body
    while IFS=$'\t' read -r path body_b64; do
        [[ -n "$path" ]] || continue
        body="$(printf '%s' "$body_b64" | base64 -d)"
        cortex_post "$path" "$body" >/dev/null 2>&1 || true
    done < <(tac "$queue" 2>/dev/null || tail -r "$queue")
    : > "$queue"
}
