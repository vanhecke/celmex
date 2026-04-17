#!/usr/bin/env bash

: "${CORTEX_TENANT_URL:?set in .envrc}"
: "${CORTEX_API_KEY:?set in .envrc}"
: "${CORTEX_API_KEY_ID:?set in .envrc}"

CORTEX="./cli/bin/cortex"
CORTEX_TEST="./cli/bin/cortex-test"
