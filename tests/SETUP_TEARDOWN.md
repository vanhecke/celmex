# Setup / teardown for write-endpoint tests

Tests that mutate the live Cortex tenant follow a **create → list → mutate → delete** round-trip. The contract below keeps the tenant clean even when tests crash and lets parallel runs coexist.

## Naming

Every fixture name uses the prefix:

```
clxtest_${BATS_RUN_ID}_${file}_${slug}
```

Underscore-separated throughout: several Cortex endpoints (notably `xql/add_dataset`) silently coerce hyphens to underscores, so the canonical form must already be underscore-native or what the test creates won't match what the tenant stores.

`fixture_name <slug>` from `tests/test_helper/fixtures.bash` builds it for you (the helper sanitizes the slug to `[a-zA-Z0-9_]`). The `clxtest_` prefix is what `cli/bin/cortex-test-clean` greps for — never change it.

## Two tiers

| Tier | Location | Run by | Notes |
| --- | --- | --- | --- |
| 1 — owned fixtures | `tests/*.bats` | `just test` | Self-contained round-trip; parallel-safe. |
| 2 — irreversible / high blast | `tests/destructive/*.bats` | `just test-destructive <file>` | One at a time, by hand. `just test` ignores the directory. |

## Per-file pattern (Tier 1)

```bash
#!/usr/bin/env bats
bats_require_minimum_version 1.7.0

setup_file() {
    load test_helper/common
    load test_helper/fixtures
    NAME="$(fixture_name lookup-basic)"
    cortex_post /public_api/v1/.../create \
        "$(jq -n --arg n "$NAME" '{request_data:{name:$n}}')"
    export NAME
}

setup() {
    load test_helper/common
    load test_helper/fixtures
}

@test "object appears in list" { … }

teardown() {
    cleanup_drain
}

teardown_file() {
    load test_helper/common
    load test_helper/fixtures
    cortex_post /public_api/v1/.../delete \
        "$(jq -n --arg n "$NAME" '{request_data:{name:$n}}')" || true
}
```

## In-test pattern (single round-trip)

When create+delete live in one `@test`, register the delete with `cleanup_register` immediately after the create. If the assertion in between fails, the per-test `teardown` calls `cleanup_drain` and the delete still fires:

```bash
@test "create then delete in one go" {
    NAME="$(fixture_name single)"
    cortex_post /public_api/v1/.../create '...'
    cleanup_register /public_api/v1/.../delete "$(jq -n --arg n "$NAME" '{request_data:{name:$n}}')"
    # assertions...
    # explicit delete is fine too; cleanup_drain is idempotent.
}
```

## Hard rules

- **No create-without-delete tests.** If the API can produce a tenant artifact but cannot remove it, do not write a test. Mark the row in `TODO.md`'s test column as `n/a (no delete)`.
- **No setup_file/teardown_file split for Tier 2.** Destructive tests put create+delete in the same `@test` so a teardown failure cannot orphan a fixture that's hard to clean up by hand.
- **Always use `fixture_name`** for any name written to the tenant. Never hardcode test names.
- **`bats_require_minimum_version 1.7.0`** in any file that uses `setup_file` / `teardown_file` / `BATS_FILE_TMPDIR`.

## Reaper

`cli/bin/cortex-test-clean` sweeps `clxtest_*` orphans before AND after `just test`. When a new write endpoint lands, register a `reap_<noun>` function in that script — it pairs the list endpoint with the delete endpoint. Until the reaper knows about an endpoint, only the test's own teardown can clean its fixtures, so a crash there leaks.
