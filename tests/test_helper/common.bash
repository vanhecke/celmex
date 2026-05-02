#!/usr/bin/env bash

: "${CORTEX_TENANT_URL:?set in .envrc}"
: "${CORTEX_API_KEY:?set in .envrc}"
: "${CORTEX_API_KEY_ID:?set in .envrc}"

CORTEX="./cli/bin/cortex"
CORTEX_TEST="./cli/bin/cortex-test"

# BATS_RUN_ID identifies one suite invocation. The Justfile exports it
# before calling bats so every parallel worker shares the same id; when
# bats is invoked directly the per-file BATS_FILE_TMPDIR pins it for
# the duration of that file.
if [[ -z "${BATS_RUN_ID:-}" ]]; then
    if [[ -n "${BATS_FILE_TMPDIR:-}" && -f "$BATS_FILE_TMPDIR/run-id" ]]; then
        BATS_RUN_ID="$(cat "$BATS_FILE_TMPDIR/run-id")"
    else
        # Underscore-only: many Cortex endpoints (e.g. xql dataset names)
        # silently coerce hyphens to underscores. Keeping the canonical
        # form underscore-native means what the test creates is what the
        # tenant stores, which is what the reaper searches for.
        BATS_RUN_ID="$(date +%s)_$(openssl rand -hex 2)"
        [[ -n "${BATS_FILE_TMPDIR:-}" ]] && \
            printf '%s' "$BATS_RUN_ID" > "$BATS_FILE_TMPDIR/run-id"
    fi
fi
export BATS_RUN_ID
