# Test Coverage

Integration tests run against a real Cortex tenant via `just test` (BATS, `tests/*.bats`). Each row records whether the wrapper has been **live-validated** against the current dev tenant or **skipped** because the tenant lacks the feature, license, or data needed.

The "Skipped" table is the to-do list for tenant validation: when these endpoints become reachable (richer tenant, add-on enabled, data populated), retest and confirm the typed decoder still parses every field — `cortex-test <cmd>` is the check.

Coverage today: **48 endpoints wrapped**, **37 live-validated**, **11 skipped**.

## Live (validated against current tenant)

| Module | Endpoint | CLI command | Notes |
|--------|----------|-------------|-------|
| Api.ApiKeys | POST /public_api/v1/api_keys/get_api_keys | `api-keys list` | |
| Api.AssetGroups | POST /public_api/v1/asset-groups | `asset-groups list` | |
| Api.Assets | POST /public_api/v1/assets | `assets list` | |
| Api.Assets | GET /public_api/v1/assets/schema | `assets schema` | |
| Api.Assets | POST /public_api/v1/assets/get_external_services | `assets external-services` | |
| Api.Assets | POST /public_api/v1/assets/get_assets_internet_exposure | `assets internet-exposures` | |
| Api.Assets | POST /public_api/v1/assets/get_external_ip_address_ranges | `assets ip-ranges` | |
| Api.Assets | POST /public_api/v1/assets/get_vulnerability_tests | `assets vulnerability-tests` | |
| Api.Assets | POST /public_api/v1/assets/get_external_websites | `assets external-websites` | |
| Api.Assets | POST /public_api/v1/assets/get_external_websites/last_external_assessment | `assets websites-last-assessment` | |
| Api.AttackSurface | POST /public_api/v1/get_attack_surface_rules | `attack-surface get-rules` | |
| Api.AuditLogs | POST /public_api/v1/audits/management_logs | `audit-logs search` | |
| Api.AuditLogs | POST /public_api/v1/audits/agents_reports | `audit-logs agents-reports` | |
| Api.AuthSettings | POST /public_api/v1/authentication-settings/get/settings | `authentication-settings get` | |
| Api.Biocs | POST /public_api/v1/bioc/get | `bioc get` | |
| Api.Cases | POST /public_api/v1/case/search | `cases search` | |
| Api.Cli | GET /public_api/v1/cli/releases/version | `cli version` | |
| Api.Correlations | POST /public_api/v1/correlations/get | `correlations get` | |
| Api.DeviceControl | POST /public_api/v1/device_control/get_violations | `device-control get-violations` | |
| Api.DisablePrevention | POST /public_api/v1/disable_prevention/fetch | `disable-prevention fetch` | |
| Api.DisablePrevention | POST /public_api/v1/disable_injection_prevention_rules/fetch | `disable-prevention fetch-injection` | |
| Api.Distributions | POST /public_api/v1/distributions/get_versions | `distributions get-versions` | |
| Api.Distributions | POST /public_api/v1/distributions/get_distributions | `distributions list` | |
| Api.Endpoints | POST /public_api/v1/endpoints/get_endpoints | `endpoints list` | |
| Api.Healthcheck | GET /public_api/v1/healthcheck | `healthcheck` | |
| Api.Indicators | POST /public_api/v1/indicators/get | `indicators get` | |
| Api.Issues | POST /public_api/v1/issue/search | `issues search` | |
| Api.LegacyExceptions | POST /public_api/v1/legacy_exceptions/get_modules | `legacy-exceptions get-modules` | |
| Api.LegacyExceptions | POST /public_api/v1/legacy_exceptions/fetch | `legacy-exceptions fetch` | |
| Api.Profiles | POST /public_api/v1/endpoints/get_policy | `profiles get-policy <id>` | test derives `<id>` from `endpoints list` |
| Api.Rbac | POST /public_api/v1/rbac/get_users | `rbac get-users` | |
| Api.Rbac | POST /public_api/v1/rbac/get_roles | `rbac get-roles <name>` | test derives `<name>` from `rbac get-users` |
| Api.ScheduledQueries | POST /public_api/v1/scheduled_queries/list | `scheduled-queries list` | |
| Api.TenantInfo | POST /public_api/v1/system/get_tenant_info | `tenant-info` | |
| Api.Xql | POST /public_api/v1/xql/get_quota | `xql get-quota` | |
| Api.Xql | POST /public_api/v1/xql/get_datasets | `xql get-datasets` | |
| Api.Xql | POST /public_api/xql_library/get | `xql-library get` | |

## Skipped (retry when tenant gains the feature/data)

| Module | Endpoint | CLI command | What's needed | Skip signal |
|--------|----------|-------------|---------------|-------------|
| Api.AgentConfig | GET /public_api/v1/configurations/agent/content_management | `agent-config content-management` | tenant with agent-configurations API enabled | HTTP 500 |
| Api.AgentConfig | GET /public_api/v1/configurations/agent/auto_upgrade | `agent-config auto-upgrade` | tenant with agent-configurations API enabled | HTTP 500 |
| Api.AgentConfig | GET /public_api/v1/configurations/agent/wildfire_analysis | `agent-config wildfire-analysis` | tenant with agent-configurations API enabled | HTTP 500 |
| Api.AgentConfig | GET /public_api/v1/configurations/agent/critical_environment_versions | `agent-config critical-environment-versions` | tenant with agent-configurations API enabled | HTTP 500 |
| Api.AgentConfig | GET /public_api/v1/configurations/agent/advanced_analysis | `agent-config advanced-analysis` | tenant with agent-configurations API enabled | HTTP 500 |
| Api.Issues | POST /public_api/v1/issue/schema | `issues schema` | tenant exposing issue schema endpoint | HTTP 500 |
| Api.Profiles | POST /public_api/v1/endpoints/get_profiles | `profiles list prevention`, `profiles list extension` | `profiles_view` permission and the `ALPHAFEATURES_PUBLIC_API_GET_POLICIES` feature flag | HTTP 402 |
| Api.Rbac | POST /public_api/v1/rbac/get_user_group | `rbac get-user-groups <name>` | at least one user group defined on the tenant | data gap (no `groups[]` on any user) |
| Api.Risk | POST /public_api/v1/get_risk_score | `risk score <id>` | Threat Intel Management add-on (or Cortex XSIAM Premium) | HTTP 500 "No identity threat" |
| Api.Risk | POST /public_api/v1/get_risky_users | `risk users` | Threat Intel Management add-on (or Cortex XSIAM Premium) | HTTP 500 "No identity threat" |
| Api.Risk | POST /public_api/v1/get_risky_hosts | `risk hosts` | Threat Intel Management add-on (or Cortex XSIAM Premium) | HTTP 500 "No identity threat" |
