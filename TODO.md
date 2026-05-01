# Cortex API Implementation Tracker

Complete inventory of all API endpoints from the OpenAPI specs in `docs/cortex-api-openapi/`.

**Legend:**
- **View** = read-only (GET, or POST that fetches/searches data)
- **Edit** = mutating (creates, updates, deletes, triggers actions)
- `✓` in first column = implemented; `Elm` / `CLI` / `Test` columns show module / command / file (empty if not started)
- **Asserts** column tracks typed presence/value assertions in `cli/src/Cli/TestMain.elm`:
  - `✓` = assertions wired ・ `—` = no `Maybe` fields worth asserting (e.g. `Bool` responses)
  - `✗` = implemented but still uses bare `typed` (assertion backlog) ・ `skip` = mutating endpoint or raw `Encode.Value` pass-through
  - blank = endpoint not yet implemented

> `cloud-onboarding-papi.json` (136 endpoints) is a strict subset of `cortex-platform-papi.json` — omitted.
> `appsec-papi (1).json` (44 endpoints) is identical to `appsec-papi.json` — omitted.
> 9 endpoints appear in multiple specs (CWP / Trusted Images / Registry Connectors) — listed in each relevant section.
> Raw total across all 22 spec files: 521. After removing the 2 duplicate files: 341 listed below.

**Progress:** 58/341 endpoints implemented | 174 View | 167 Edit


## Cortex Platform

Source: `cortex-platform-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ✓ | GET | `/public_api/v1/cli/releases/version` | Get the latest version of the Cortex CLI | View | `Cortex.Api.Cli` | `cli version` | `cli_version.bats` | ✓ |
|  | POST | `/public_api/v1/xql/start_xql_query` | Start an XQL query | Edit |  |  |  |  |
|  | POST | `/public_api/v1/xql/get_query_results` | Get XQL query results | View |  |  |  |  |
| ✓ | POST | `/public_api/v1/xql/get_quota` | Get XQL query Quota | View | `Cortex.Api.Xql` | `xql get-quota` | `xql.bats` | ✓ |
|  | POST | `/public_api/v1/xql/get_query_results_stream` | Get XQL query results Stream | View |  |  |  |  |
| ✓ | POST | `/public_api/v1/distributions/get_versions` | Get Distribution version | View | `Cortex.Api.Distributions` | `distributions get-versions` | `distributions.bats` | ✗ |
| ✓ | POST | `/public_api/v1/endpoints/get_endpoints` | Get all Endpoints | View | `Cortex.Api.Endpoints` | `endpoints list` | `endpoints.bats` | ✗ |
| ✓ | POST | `/public_api/v1/endpoints/get_policy` | Get Policy | View | `Cortex.Api.Profiles` | `profiles get-policy` | `profiles.bats` | ✗ |
|  | POST | `/public_api/v1/endpoints/delete` | Delete Endpoints | Edit |  |  |  |  |
|  | POST | `/public_api/v1/distributions/create` | Create distributions | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/distributions/get_distributions` | Get Distributions | View | `Cortex.Api.Distributions` | `distributions list` | `distributions.bats` | ✗ |
| ✓ | POST | `/public_api/v1/device_control/get_violations` | Get Violations | View | `Cortex.Api.DeviceControl` | `device-control get-violations` | `device_control.bats` | ✓ |
| ✓ | POST | `/public_api/v1/distributions/get_status` | Get Distribution status | View | `Cortex.Api.Distributions` | `distributions get-status` | `distributions.bats` | ✗ |
| ✓ | POST | `/public_api/v1/distributions/get_dist_url` | Get Distribution URL | View | `Cortex.Api.Distributions` | `distributions get-dist-url` | `distributions.bats` | ✗ |
|  | POST | `/public_api/v1/endpoints/update_agent_name` | Set an Endpoint Alias | Edit |  |  |  |  |
|  | POST | `/public_api/v1/tags/agents/assign` | Assign Tags | Edit |  |  |  |  |
|  | POST | `/public_api/v1/tags/agents/remove` | Remove Tags | Edit |  |  |  |  |
|  | POST | `/public_api/v1/endpoints/restore` | Restore File | Edit |  |  |  |  |
|  | POST | `/public_api/v1/actions/file_retrieval_details` | File Retrieval Details | View |  |  |  |  |
|  | POST | `/public_api/v1/hash_exceptions/allowlist` | Allow List Files | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/quarantine/status` | Get Quarantine Status | View | `Cortex.Api.Quarantine` | `quarantine status` | `quarantine.bats` | ✗ |
|  | POST | `/public_api/v1/endpoints/quarantine` | Quarantine Files | Edit |  |  |  |  |
|  | POST | `/public_api/v1/hash_exceptions/blocklist` | Block List Files | Edit |  |  |  |  |
|  | POST | `/public_api/v1/endpoints/unisolate` | Unisolate Endpoints | Edit |  |  |  |  |
|  | POST | `/public_api/v1/endpoints/abort_scan` | Cancel Scan Endpoints | Edit |  |  |  |  |
|  | POST | `/public_api/v1/endpoints/scan` | Scan Endpoints | Edit |  |  |  |  |
|  | POST | `/public_api/v1/actions/get_action_status` | Get Action Status | View |  |  |  |  |
|  | POST | `/public_api/v1/scripts/run_snippet_code_script` | Run Snippet Code Script | Edit |  |  |  |  |
|  | POST | `/public_api/v1/scripts/run_script` | Run Script | Edit |  |  |  |  |
|  | POST | `/public_api/v1/scripts/get_script_metadata` | Get Script Metadata | View |  |  |  |  |
|  | POST | `/public_api/v1/scripts/get_script_execution_status` | Get Script Execution Status | View |  |  |  |  |
|  | POST | `/public_api/v1/scripts/get_scripts` | Get Scripts | View |  |  |  |  |
|  | POST | `/public_api/v1/scripts/get_script_execution_results` | Get Script Execution Results | View |  |  |  |  |
|  | POST | `/public_api/v1/scripts/get_script_execution_results_files` | Get Script Execution Result Files | View |  |  |  |  |
|  | POST | `/public_api/v1/scripts/get_script_code` | Get Script Code | View |  |  |  |  |
|  | POST | `/public_api/v1/indicators/insert_csv` | Insert Simple Indicators, CSV | Edit |  |  |  |  |
|  | POST | `/public_api/v1/indicators/insert_jsons` | Insert Simple Indicators, JSON | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/audits/management_logs` | Get Audit Management Log | View | `Cortex.Api.AuditLogs` | `audit-logs search` | `audit_logs.bats` | ✗ |
| ✓ | GET | `/public_api/v1/healthcheck` | System Health Check | View | `Cortex.Api.Healthcheck` | `healthcheck` | `healthcheck.bats` | ✓ |
| ✓ | POST | `/public_api/v1/system/get_tenant_info` | Get Tenant Info | View | `Cortex.Api.TenantInfo` | `tenant-info` | `tenant_info.bats` | ✓ |
| ✓ | POST | `/public_api/v1/rbac/get_users` | Get Users | View | `Cortex.Api.Rbac` | `rbac get-users` | `rbac.bats` | ✗ |
| ✓ | POST | `/public_api/v1/rbac/get_roles` | Get Roles | View | `Cortex.Api.Rbac` | `rbac get-roles` | `rbac.bats` | ✗ |
| ✓ | POST | `/public_api/v1/rbac/get_user_group` | Get User Groups | View | `Cortex.Api.Rbac` | `rbac get-user-groups` | `rbac.bats` | ✗ |
|  | POST | `/public_api/v1/rbac/set_user_role` | Set a User Role | Edit |  |  |  |  |
|  | POST | `/public_api/v1/endpoints/get_endpoint` | Get Endpoint | View |  |  |  |  |
| ✓ | POST | `/public_api/v1/get_risk_score` | Get Risk Score | View | `Cortex.Api.Risk` | `risk score` | `risk.bats` | ✗ |
| ✓ | POST | `/public_api/v1/get_risky_users` | Get Risky Users | View | `Cortex.Api.Risk` | `risk users` | `risk.bats` | ✗ |
| ✓ | POST | `/public_api/v1/get_risky_hosts` | Get Risky Hosts | View | `Cortex.Api.Risk` | `risk hosts` | `risk.bats` | ✗ |
|  | POST | `/public_api/v1/endpoints/file_retrieval` | Retrieve File | Edit |  |  |  |  |
|  | POST | `/public_api/v1/endpoints/isolate` | Isolate Endpoints | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/audits/agents_reports` | Get Audit Agent Report | View | `Cortex.Api.AuditLogs` | `audit-logs agents-reports` | `audit_logs_agents_reports.bats` | ✗ |
|  | POST | `/public_api/v1/assets/get_external_service` | Get External Service | View |  |  |  |  |
| ✓ | POST | `/public_api/v1/assets/get_external_services` | Get All Services | View | `Cortex.Api.Assets` | `assets external-services` | `assets.bats` | ✗ |
| ✓ | POST | `/public_api/v1/assets/get_assets_internet_exposure` | Get all Internet Exposures | View | `Cortex.Api.Assets` | `assets internet-exposures` | `assets.bats` | ✗ |
|  | POST | `/public_api/v1/assets/get_asset_internet_exposure` | Get Internet Exposure | View |  |  |  |  |
| ✓ | POST | `/public_api/v1/assets/get_external_ip_address_ranges` | Get all External IP Address Ranges | View | `Cortex.Api.Assets` | `assets ip-ranges` | `assets.bats` | ✗ |
|  | POST | `/public_api/v1/assets/get_external_ip_address_range` | Get External IP Address Range | View |  |  |  |  |
|  | POST | `/public_api/v1/triage_endpoint` | Initiate Forensics Triage | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/assets/get_vulnerability_tests` | Get vulnerability tests | View | `Cortex.Api.Assets` | `assets vulnerability-tests` | `assets.bats` | ✗ |
|  | POST | `/public_api/v1/assets/bulk_update_vulnerability_tests` | Bulk Update Vulnerability Tests | Edit |  |  |  |  |
|  | POST | `/public_api/v1/dataset/define_dataset` | Define an XQL user dataset | Edit |  |  |  |  |
|  | POST | `/public_api/v1/dataset/get_created_datasets` | Get created XQL user datasets | View |  |  |  |  |
|  | POST | `/public_api/v1/dataset/delete_dataset` | Delete an XQL user dataset | Edit |  |  |  |  |
|  | POST | `/public_api/v1/xql/add_dataset` | Add Dataset | Edit |  |  |  |  |
|  | POST | `/public_api/v2/xql/delete_dataset` | Delete a dataset | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/xql/get_datasets` | Get all datasets | View | `Cortex.Api.Xql` | `xql get-datasets` | `xql.bats` | ✗ |
|  | POST | `/public_api/v1/xql/lookups/add_data` | Add or update data in a lookup dataset | Edit |  |  |  |  |
|  | POST | `/public_api/v1/xql/lookups/remove_data` | Remove data from a lookup dataset | Edit |  |  |  |  |
|  | POST | `/public_api/v1/xql/lookups/get_data` | Get data from a lookup dataset | View |  |  |  |  |
| ✓ | POST | `/public_api/v1/get_triage_presets` | Get triage presets | View | `Cortex.Api.TriagePresets` | `triage-presets list` | `triage_presets.bats` | ✗ |
|  | POST | `/public_api/v1/authentication-settings/create` | Create authentication settings for IdP SSO or metadata URL | Edit |  |  |  |  |
|  | POST | `/public_api/v1/authentication-settings/update` | Update authentication settings | Edit |  |  |  |  |
|  | POST | `/public_api/v1/authentication-settings/delete` | Delete authentication settings by domain | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/authentication-settings/get/settings` | Get authentication settings for all configured domains | View | `Cortex.Api.AuthSettings` | `authentication-settings get` | `authentication_settings.bats` | ✓ |
|  | POST | `/public_api/v1/authentication-settings/get/metadata` | Get IdP metadata | View |  |  |  |  |
|  | POST | `/public_api/v1/asm_management/upload_asm_data` | Upload assets to the inventory | Edit |  |  |  |  |
|  | POST | `/public_api/v1/assets/get_external_website` | Get Website Details | View |  |  |  |  |
| ✓ | POST | `/public_api/v1/assets/get_external_websites` | Get all Websites | View | `Cortex.Api.Assets` | `assets external-websites` | `assets.bats` | ✗ |
| ✓ | POST | `/public_api/v1/assets/get_external_websites/last_external_assessment` | Get Websites Last Assessment | View | `Cortex.Api.Assets` | `assets websites-last-assessment` | `assets.bats` | ✗ |
|  | POST | `/public_api/v1/integrations/syslog/create` | Create a syslog integration | Edit |  |  |  |  |
|  | POST | `/public_api/v1/integrations/syslog/get` | Get all or filtered syslog servers | View |  |  |  |  |
|  | POST | `/public_api/v1/integrations/syslog/update` | Update a syslog integration | Edit |  |  |  |  |
|  | POST | `/public_api/v1/integrations/syslog/delete` | Delete all or filtered syslog integrations | Edit |  |  |  |  |
|  | POST | `/public_api/v1/integrations/syslog/test` | Test syslog integration | Edit |  |  |  |  |
|  | POST | `/public_api/v1/distributions/delete` | Delete agent installation packages | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/get_attack_surface_rules` | Get all Attack Surface Rules | View | `Cortex.Api.AttackSurface` | `attack-surface get-rules` | `attack_surface.bats` | ✓ |
|  | POST | `/public_api/v1/asm_management/remove_asm_data` | Remove Assets | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/scheduled_queries/list` | Get scheduled queries | View | `Cortex.Api.ScheduledQueries` | `scheduled-queries list` | `scheduled_queries.bats` | ✓ |
|  | POST | `/public_api/v1/scheduled_queries/insert` | Insert or update scheduled queries | Edit |  |  |  |  |
|  | POST | `/public_api/v1/scheduled_queries/delete` | Delete a scheduled query | Edit |  |  |  |  |
| ✓ | POST | `/public_api/xql_library/get` | Get XQL Queries | View | `Cortex.Api.Xql` | `xql-library get` | `xql.bats` | ✗ |
|  | POST | `/public_api/xql_library/insert` | Insert or update XQL queries | Edit |  |  |  |  |
|  | POST | `/public_api/xql_library/delete` | Delete XQL Queries | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/indicators/get` | Get Indicators (IOCs) | View | `Cortex.Api.Indicators` | `indicators get` | `indicators.bats` | ✓ |
|  | POST | `/public_api/v1/indicators/insert` | Insert or update IOCs | Edit |  |  |  |  |
|  | POST | `/public_api/v1/indicators/delete` | Delete Indicators (IOCs) | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/bioc/get` | Get BIOCs | View | `Cortex.Api.Biocs` | `bioc get` | `biocs.bats` | ✓ |
|  | POST | `/public_api/v1/bioc/insert` | Insert or update BIOCs | Edit |  |  |  |  |
|  | POST | `/public_api/v1/bioc/delete` | Delete BIOCs | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/correlations/get` | Get Correlation Rules | View | `Cortex.Api.Correlations` | `correlations get` | `correlations.bats` | ✓ |
|  | POST | `/public_api/v1/correlations/insert` | Insert or update Correlation Rules | Edit |  |  |  |  |
|  | POST | `/public_api/v1/correlations/delete` | Delete Correlation Rules | Edit |  |  |  |  |
|  | POST | `/public_api/v1/playbooks/get` | Get a playbook | View |  |  |  |  |
|  | POST | `/public_api/v1/playbooks/insert` | Insert or update playbooks | Edit |  |  |  |  |
|  | POST | `/public_api/v1/playbooks/delete` | Delete a playbook | Edit |  |  |  |  |
|  | POST | `/public_api/v1/scripts/get` | Get a script | View |  |  |  |  |
|  | POST | `/public_api/v1/scripts/insert` | Insert or update a script | Edit |  |  |  |  |
|  | POST | `/public_api/v1/scripts/delete` | Delete a script | Edit |  |  |  |  |
|  | POST | `/public_api/v1/dashboards/get` | Get dashboards | View |  |  |  |  |
|  | POST | `/public_api/v1/dashboards/insert` | Insert or update dashboards | Edit |  |  |  |  |
|  | POST | `/public_api/v1/dashboards/delete` | Delete dashboards | Edit |  |  |  |  |
|  | POST | `/public_api/v1/widgets/get` | Get widgets | View |  |  |  |  |
|  | POST | `/public_api/v1/widgets/insert` | Insert or update widgets | Edit |  |  |  |  |
|  | POST | `/public_api/v1/widgets/delete` | Delete widgets | Edit |  |  |  |  |
|  | POST | `/public_api/v1/issue` | Create a new issue | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/issue/search` | Retrieve issues based on filters | View | `Cortex.Api.Issues` | `issues search` | `issues.bats` | ✓ |
|  | POST | `/public_api/v1/issue/{issue-id}` | Update existing issue | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/issue/schema` | Retrieve issue schema (tenant-unsupported on this fixture) | View | `Cortex.Api.Issues` | `issues schema` | `issues.bats` | ✓ |
| ✓ | POST | `/public_api/v1/case/search` | Retrieve Cases based on filters | View | `Cortex.Api.Cases` | `cases search` | `cases.bats` | ✗ |
|  | POST | `/public_api/v1/case/update/{case-id}` | Update existing case | Edit |  |  |  |  |
|  | GET | `/public_api/v1/case/artifacts/{case-id}` | Retrieve Case Artifacts by Case ID | View |  |  |  |  |
|  | POST | `/public_api/v1/entries/get` | Get War Room entries | View |  |  |  |  |
|  | POST | `/public_api/v1/entries/insert` | Add War Room entries | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/assets` | Get all or filtered assets | View | `Cortex.Api.Assets` | `assets list` | `assets.bats` | ✗ |
|  | GET | `/public_api/v1/assets/{id}` | Get asset by ID | View |  |  |  |  |
|  | GET | `/public_api/v1/assets/{id}/raw_fields` | Get raw fields of asset by ID | View |  |  |  |  |
| ✓ | GET | `/public_api/v1/assets/schema` | Get schema of asset inventory | View | `Cortex.Api.Assets` | `assets schema` | `assets.bats` | ✗ |
|  | GET | `/public_api/v1/assets/enum/{field_name}` | Get enum values of specified field | View |  |  |  |  |
| ✓ | POST | `/public_api/v1/asset-groups` | Get all or filtered asset groups | View | `Cortex.Api.AssetGroups` | `asset-groups list` | `asset_groups.bats` | ✗ |
|  | POST | `/public_api/v1/asset-groups/create` | Create an Asset Group | Edit |  |  |  |  |
|  | POST | `/public_api/v1/asset-groups/update/{group_id}` | Update an Asset Group | Edit |  |  |  |  |
|  | POST | `/public_api/v1/asset-groups/delete/{group_id}` | Delete an Asset Group | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/api_keys/get_api_keys` | Get existing API keys | View | `Cortex.Api.ApiKeys` | `api-keys list` | `api_keys.bats` | ✗ |
|  | POST | `/public_api/v1/api_keys/generate` | Generate an API key | Edit |  |  |  |  |
|  | POST | `/public_api/v1/api_keys/delete` | Delete API keys | Edit |  |  |  |  |
|  | POST | `/public_api/v1/tags/agents/delete_permanently` | Delete Tags Permanently | Edit |  |  |  |  |
|  | POST | `/public_api/v1/endpoints/upgrade` | Upgrade Agents | Edit |  |  |  |  |
| ✓ | POST | `/public_api/v1/endpoints/get_profiles` | Get endpoint security profiles | View | `Cortex.Api.Profiles` | `profiles list` | `profiles.bats` | ✗ |
| ✓ | POST | `/public_api/v1/legacy_exceptions/get_modules` | Get Legacy Exceptions Modules | View | `Cortex.Api.LegacyExceptions` | `legacy-exceptions get-modules` | `legacy_exceptions.bats` | ✓ |
| ✓ | POST | `/public_api/v1/legacy_exceptions/fetch` | Fetch Legacy Exception Rules | View | `Cortex.Api.LegacyExceptions` | `legacy-exceptions fetch` | `legacy_exceptions.bats` | ✓ |
|  | POST | `/public_api/v1/legacy_exceptions/add` | Add Legacy Exception Rule | Edit |  |  |  |  |
|  | POST | `/public_api/v1/legacy_exceptions/edit` | Edit Legacy Exception Rule | Edit |  |  |  |  |
|  | POST | `/public_api/v1/legacy_exceptions/delete` | Delete Legacy Exception Rules | Edit |  |  |  |  |
|  | POST | `/public_api/v1/profiles/prevention/add` | Add Prevention Profile | Edit |  |  |  |  |
|  | POST | `/public_api/v1/profiles/add_signer_cn_to_allowlist` | Add Signer CN to Allowlist | Edit |  |  |  |  |
|  | POST | `/public_api/v1/profiles/prevention/edit` | Edit Prevention Profile | Edit |  |  |  |  |
|  | POST | `/public_api/v1/profiles/prevention/get_modules` | Get Prevention Profile Modules | View |  |  |  |  |

## Agent Configuration

Source: `agent-configurations-papi.yaml`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ✓ | GET | `/public_api/v1/configurations/agent/content_management` | Retrieve content management settings | View | `Cortex.Api.AgentConfig` | `agent-config content-management` | `agent_config.bats` | ✗ |
|  | POST | `/public_api/v1/configurations/agent/content_management/set` | Update content management settings | Edit |  |  |  |  |
| ✓ | GET | `/public_api/v1/configurations/agent/agent_status` | Retrieve agent status timeout settings | View | `Cortex.Api.AgentConfig` | `agent-config agent-status` | `agent_config.bats` | ✗ |
|  | POST | `/public_api/v1/configurations/agent/agent_status/set` | Update agent status timeout settings | View |  |  |  |  |
| ✓ | GET | `/public_api/v1/configurations/agent/auto_upgrade` | Retrieve agent auto-upgrade settings | View | `Cortex.Api.AgentConfig` | `agent-config auto-upgrade` | `agent_config.bats` | ✗ |
|  | POST | `/public_api/v1/configurations/agent/auto_upgrade/set` | Update agent auto-upgrade settings | Edit |  |  |  |  |
| ✓ | GET | `/public_api/v1/configurations/agent/wildfire_analysis` | Retrieve WildFire analysis settings | View | `Cortex.Api.AgentConfig` | `agent-config wildfire-analysis` | `agent_config.bats` | ✗ |
|  | POST | `/public_api/v1/configurations/agent/wildfire_analysis/set` | Update WildFire analysis settings | Edit |  |  |  |  |
| ✓ | GET | `/public_api/v1/configurations/agent/informative_btp_issues` | Retrieve informative BTP issues settings | View | `Cortex.Api.AgentConfig` | `agent-config informative-btp-issues` | `agent_config.bats` | ✗ |
|  | POST | `/public_api/v1/configurations/agent/informative_btp_issues/set` | Update informative BTP issues settings | Edit |  |  |  |  |
| ✓ | GET | `/public_api/v1/configurations/agent/cortex_xdr_log_collection` | Retrieve log collection settings | View | `Cortex.Api.AgentConfig` | `agent-config cortex-xdr-log-collection` | `agent_config.bats` | ✗ |
|  | POST | `/public_api/v1/configurations/agent/cortex_xdr_log_collection/set` | Update log collection settings | Edit |  |  |  |  |
| ✓ | GET | `/public_api/v1/configurations/agent/action_center_expiration` | Retrieve action center expiration settings | View | `Cortex.Api.AgentConfig` | `agent-config action-center-expiration` | `agent_config.bats` | ✗ |
|  | POST | `/public_api/v1/configurations/agent/action_center_expiration/set` | Update action center expiration settings | Edit |  |  |  |  |
| ✓ | GET | `/public_api/v1/configurations/agent/critical_environment_versions` | Retrieve critical environment versions settings | View | `Cortex.Api.AgentConfig` | `agent-config critical-environment-versions` | `agent_config.bats` | ✗ |
|  | POST | `/public_api/v1/configurations/agent/critical_environment_versions/set` | Update critical environment versions settings | View |  |  |  |  |
| ✓ | GET | `/public_api/v1/configurations/agent/advanced_analysis` | Retrieve advanced analysis settings | View | `Cortex.Api.AgentConfig` | `agent-config advanced-analysis` | `agent_config.bats` | ✗ |
|  | POST | `/public_api/v1/configurations/agent/advanced_analysis/set` | Update advanced analysis settings | Edit |  |  |  |  |
| ✓ | GET | `/public_api/v1/configurations/agent/endpoint_administration_cleanup` | Retrieve endpoint administration cleanup settings | View | `Cortex.Api.AgentConfig` | `agent-config endpoint-administration-cleanup` | `agent_config.bats` | ✗ |
|  | POST | `/public_api/v1/configurations/agent/endpoint_administration_cleanup/set` | Update endpoint administration cleanup settings | Edit |  |  |  |  |

## Compliance

Source: `compliance-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | POST | `/public_api/v1/compliance/get_assessment_profiles` | Get assessment profiles | View |  |  |  |  |
|  | POST | `/public_api/v1/compliance/get_assessment_profile` | Get assessment profile by ID | View |  |  |  |  |
|  | POST | `/public_api/v1/compliance/add_assessment_profile` | Add assessment profile | Edit |  |  |  |  |
|  | POST | `/public_api/v1/compliance/edit_assessment_profile` | Edit assessment profile | Edit |  |  |  |  |
|  | POST | `/public_api/v1/compliance/delete_assessment_profile` | Delete assessment profile | Edit |  |  |  |  |
|  | POST | `/public_api/v1/compliance/get_assessment_results` | Get assessment profile results | View |  |  |  |  |
|  | POST | `/public_api/v1/compliance/get_controls` | Get compliance controls | View |  |  |  |  |
|  | POST | `/public_api/v1/compliance/get_control` | Get compliance control by ID | View |  |  |  |  |
|  | POST | `/public_api/v1/compliance/add_control` | Add new control | Edit |  |  |  |  |
|  | POST | `/public_api/v1/compliance/edit_control` | Edit existing control | Edit |  |  |  |  |
|  | POST | `/public_api/v1/compliance/delete_control` | Delete control | Edit |  |  |  |  |
|  | POST | `/public_api/v1/compliance/add_rules_to_control` | Add compliance rules to a compliance control | Edit |  |  |  |  |
|  | POST | `/public_api/v1/compliance/delete_rules_from_control` | Delete rules from control | Edit |  |  |  |  |
|  | POST | `/public_api/v1/compliance/get_control_categories_and_subcategories` | Get categories and subcategories | View |  |  |  |  |
|  | POST | `/public_api/v1/compliance/get_control_by_revision` | Get control by revision | View |  |  |  |  |
|  | POST | `/public_api/v1/compliance/get_control_failed_results` | Get control failed results | View |  |  |  |  |
|  | POST | `/public_api/v1/compliance/get_rule_failed_results` | Get rule failed results | View |  |  |  |  |
|  | POST | `/public_api/v1/compliance/get_reports` | Get compliance reports | View |  |  |  |  |
|  | POST | `/public_api/v1/compliance/get_standards` | Get compliance standards | View |  |  |  |  |
|  | POST | `/public_api/v1/compliance/get_standard` | Get single standard by ID | View |  |  |  |  |
|  | POST | `/public_api/v1/compliance/add_standard` | Add new standard | Edit |  |  |  |  |
|  | POST | `/public_api/v1/compliance/edit_standard` | Edit existing standard | Edit |  |  |  |  |
|  | POST | `/public_api/v1/compliance/delete_standard` | Delete standard | Edit |  |  |  |  |
|  | POST | `/public_api/v1/compliance/get_assets` | Get compliance assets | View |  |  |  |  |

## CSPM Policies

Source: `cspm-policies-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | POST | `/public_api/v1/policy` | Create Public Policy | Edit |  |  |  |  |
|  | POST | `/public_api/v1/policy/search` | List Public Policies | View |  |  |  |  |
|  | DELETE | `/public_api/v1/policy/{policy_id}` | Delete Public Policy | Edit |  |  |  |  |
|  | GET | `/public_api/v1/policy/{policy_id}` | Get Public Policy | View |  |  |  |  |
|  | PATCH | `/public_api/v1/policy/{policy_id}` | Update Public Policy | Edit |  |  |  |  |

## CWP (Cloud Workload Protection)

Source: `cwp-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | GET | `/public_api/v2/cwp/policies` | Get CWP Policies (v2) | View |  |  |  |  |
|  | POST | `/public_api/v2/cwp/policies` | Add CWP Policies (v2) | Edit |  |  |  |  |
|  | GET | `/public_api/v2/cwp/policies/{id}` | Get a CWP Policy by ID (v2) | View |  |  |  |  |
|  | PUT | `/public_api/v2/cwp/policies/{id}` | Update a CWP Policy by ID (v2) | Edit |  |  |  |  |
|  | GET | `/public_api/v1/cwp/policies` | Get CWP Policies (v1) | View |  |  |  |  |
|  | POST | `/public_api/v1/cwp/policies` | Add CWP Policies (v1) | Edit |  |  |  |  |
|  | DELETE | `/public_api/v1/cwp/policies/{id}` | Delete a CWP Policy by ID (v1) | Edit |  |  |  |  |
|  | GET | `/public_api/v1/cwp/policies/{id}` | Get a CWP Policy by ID (v1) | View |  |  |  |  |
|  | PUT | `/public_api/v1/cwp/policies/{id}` | Update a CWP Policy by ID (v1) | Edit |  |  |  |  |
|  | GET | `/public_api/v1/assets/{assetID}/sbom` | Get the SBOM of the specified asset | View |  |  |  |  |
|  | POST | `/public_api/v1/cwp/registry_onboarding/instances` | Create a registry connector | Edit |  |  |  |  |
|  | DELETE | `/public_api/v1/cwp/registry_onboarding/instances/{connectorID}` | Delete a registry connector | Edit |  |  |  |  |
|  | GET | `/public_api/v1/cwp/registry_onboarding/instances/{connectorID}` | Get a registry connector | View |  |  |  |  |
|  | PUT | `/public_api/v1/cwp/registry_onboarding/instances/{connectorID}` | Update a registry connector | Edit |  |  |  |  |

## IAM Platform

Source: `iam-platform-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | GET | `/platform/iam/v1/role` | List all roles | View |  |  |  |  |
|  | POST | `/platform/iam/v1/role` | Create a new role | Edit |  |  |  |  |
|  | DELETE | `/platform/iam/v1/role/{role_id}` | Delete an existing role | Edit |  |  |  |  |
|  | GET | `/platform/iam/v1/role/permission-config` | List all permission configs | View |  |  |  |  |
|  | GET | `/platform/iam/v1/user-group` | List all user groups | View |  |  |  |  |
|  | POST | `/platform/iam/v1/user-group` | Create a new user group | Edit |  |  |  |  |
|  | DELETE | `/platform/iam/v1/user-group/{group_id}` | Delete an existing user group | Edit |  |  |  |  |
|  | PATCH | `/platform/iam/v1/user-group/{group_id}` | Edit an existing user group | Edit |  |  |  |  |
|  | GET | `/platform/iam/v1/scope/{entity_type}/{entity_id}` | Retrieve an existing scope | View |  |  |  |  |
|  | PUT | `/platform/iam/v1/scope/{entity_type}/{entity_id}` | Edit an existing scope | Edit |  |  |  |  |
|  | GET | `/platform/iam/v1/user` | List all users | View |  |  |  |  |
|  | GET | `/platform/iam/v1/user/{user_email}` | Get user | View |  |  |  |  |
|  | PATCH | `/platform/iam/v1/user/{user_email}` | Edit an existing user | Edit |  |  |  |  |
|  | GET | `/platform/iam/v1/api-key/{api_key_id}` | Get API Key | View |  |  |  |  |
|  | PUT | `/platform/iam/v1/api-key/{api_key_id}` | Edit an API key | Edit |  |  |  |  |

## Vulnerability Intelligence

Source: `vulnerability-intelligence-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | POST | `/public_api/uvem/v1/get_vulnerabilities` | Get list of vulnerabilities | View |  |  |  |  |
|  | POST | `/public_api/uvem/v1/get_affected_software` | Get affected software | View |  |  |  |  |
|  | GET | `/public_api/uvem/v1/vulnerabilities` | Get vulnerability details | View |  |  |  |  |

## UVEM (Vulnerability Management)

Source: `uvem-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | POST | `/public_api/uvm_public/v1/list_policies` | Get Policies List | View |  |  |  |  |
|  | POST | `/public_api/uvm_public/v1/create_policy` | Create Policy Public | Edit |  |  |  |  |
|  | PUT | `/public_api/uvm_public/v1/update_policy/{id}` | Update Policy | Edit |  |  |  |  |
|  | GET | `/public_api/uvm_public/v1/get_policy/{id}` | Get Policy By ID | View |  |  |  |  |
|  | DELETE | `/public_api/uvm_public/v1/delete_policy/{id}` | Delete Policy | Edit |  |  |  |  |
|  | POST | `/public_api/vulnerability-management/v1/scan` | Trigger Scan for an AssetId | Edit |  |  |  |  |

## NetScan

Source: `netscan-papi.yaml`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | GET | `/public_api/netscan/v1/scan/run` | Get scan run status | View |  |  |  |  |
|  | POST | `/public_api/netscan/v1/scan/run` | Launch a scan run | Edit |  |  |  |  |
|  | GET | `/public_api/netscan/v1/scan/run/{id}` | Get scan run status by ID | View |  |  |  |  |
|  | POST | `/public_api/netscan/v1/scan/run/{id}` | Launch a scan run by definition ID | Edit |  |  |  |  |
|  | POST | `/public_api/netscan/v1/scan/definition` | Create a scan definition | Edit |  |  |  |  |
|  | POST | `/public_api/netscan/v1/scan/run/{id}/command` | Send a command to a running scan | Edit |  |  |  |  |

## AppSec

Source: `appsec-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | GET | `/public_api/appsec/v1/application/configuration` | Get an application configuration | View |  |  |  |  |
|  | GET | `/public_api/appsec/v1/application` | Get applications | View |  |  |  |  |
|  | POST | `/public_api/appsec/v1/application` | Create an application | Edit |  |  |  |  |
|  | DELETE | `/public_api/appsec/v1/application/{applicationId}` | Delete an application | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/application/{applicationId}` | Get an application | View |  |  |  |  |
|  | PUT | `/public_api/appsec/v1/application/{applicationId}` | Update an application | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/policies` | List AppSec policies | View |  |  |  |  |
|  | POST | `/public_api/appsec/v1/policies` | Create an AppSec policy | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/rules` | Get AppSec rules | View |  |  |  |  |
|  | POST | `/public_api/appsec/v1/rules` | Create an AppSec rule | Edit |  |  |  |  |
|  | DELETE | `/public_api/appsec/v1/rules/{ruleId}` | Delete an AppSec rule | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/rules/{ruleId}` | Get an AppSec rule | View |  |  |  |  |
|  | PATCH | `/public_api/appsec/v1/rules/{ruleId}` | Modify an AppSec rule | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/rules/rule-labels` | Get AppSec rule labels | View |  |  |  |  |
|  | POST | `/public_api/appsec/v1/rules/validate` | Create an AppSec rule validation | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/repositories` | Get repositories | View |  |  |  |  |
|  | GET | `/public_api/appsec/v1/repositories/{assetId}` | Get a repository | View |  |  |  |  |
|  | GET | `/public_api/appsec/v1/repositories/{assetId}/scan-configuration` | Get a repository scan configuration | View |  |  |  |  |
|  | PUT | `/public_api/appsec/v1/repositories/{assetId}/scan-configuration` | Update a repository scan configuration | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/integrations` | Get AppSec Data Source | View |  |  |  |  |
|  | DELETE | `/public_api/appsec/v1/integrations/{id}` | Delete an AppSec Data Source | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/integrations/{id}` | Get an AppSec Data Source | View |  |  |  |  |
|  | PUT | `/public_api/appsec/v1/integrations/{id}` | Update an AppSec Data Source | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/repositories/{assetId}/branches` | Get AppSec repository branches | View |  |  |  |  |
|  | PUT | `/public_api/appsec/v1/repositories/{assetId}/branches` | Update an AppSec repository branch | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/scans/unscanned-repositories` | Get unscanned AppSec scan management repositories | View |  |  |  |  |
|  | GET | `/public_api/appsec/v1/sbom/repository/{repoId}` | Get an SBOM for the specified repository | View |  |  |  |  |
|  | GET | `/public_api/appsec/v1/sbom/organization/{orgName}` | Get all SBOMs for the specified organization | View |  |  |  |  |
|  | GET | `/public_api/appsec/v1/scans/periodic` | Get AppSec branch periodic scans | View |  |  |  |  |
|  | GET | `/public_api/appsec/v1/scans/pr` | Get AppSec Pull Request scans | View |  |  |  |  |
|  | GET | `/public_api/appsec/v1/scans/ci` | Get AppSec CI scans | View |  |  |  |  |
|  | GET | `/public_api/appsec/v1/scans/{scanId}/issues` | List AppSec scan issues | View |  |  |  |  |
|  | GET | `/public_api/appsec/v1/scans/{scanId}/findings` | List AppSec scan findings | View |  |  |  |  |
|  | POST | `/public_api/appsec/v1/scan/repository/{repositoryId}` | Rerun a repository scan | Edit |  |  |  |  |
|  | DELETE | `/public_api/appsec/v1/policies/{policyId}` | Delete an AppSec policy | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/policies/{policyId}` | Get an AppSec policy | View |  |  |  |  |
|  | PUT | `/public_api/appsec/v1/policies/{policyId}` | Update an AppSec policy | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/application/criteria/all` | Get all criteria | View |  |  |  |  |
|  | DELETE | `/public_api/appsec/v1/application/criteria/{criteriaId}` | Delete a Criteria | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/application/criteria/{criteriaId}` | Get a Criteria by ID | View |  |  |  |  |
|  | POST | `/public_api/appsec/v1/application/criteria` | Create a Criteria | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/issues/fix/{issueId}/fix_suggestion` | Get Fix Suggestion | View |  |  |  |  |
|  | POST | `/public_api/appsec/v1/issues/fix/trigger_fix_pull_request` | Trigger Fix Pull Request | Edit |  |  |  |  |
|  | GET | `/public_api/appsec/v1/issues/fix/{remediationId}` | Get Fix Status | View |  |  |  |  |

## DSPM (Data Security)

Source: `dspm-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | POST | `/public_api/v1/data-security/data-patterns` | Get data pattern inventory | View |  |  |  |  |
|  | POST | `/public_api/v1/data-security/objects/fields` | Get field inventory details | View |  |  |  |  |
|  | POST | `/public_api/v1/data-security/objects/files` | Get file inventory details | View |  |  |  |  |

## Platform Notifications

Source: `platform-notifications-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | GET | `/platform/notifications/v1/list-rules` | List all rules | View |  |  |  |  |
|  | POST | `/platform/notifications/v1/rule` | Create a new rule | Edit |  |  |  |  |
|  | DELETE | `/platform/notifications/v1/rule/{rule_uuid}` | Delete an existing Alert Notification Rule | Edit |  |  |  |  |
|  | GET | `/platform/notifications/v1/rule/{rule_uuid}` | Retrieve a specific alert notification rule | View |  |  |  |  |
|  | PUT | `/platform/notifications/v1/rule/{rule_uuid}` | Edit an existing Alert Notification Rule | Edit |  |  |  |  |
|  | PATCH | `/platform/notifications/v1/update-rule-status/{rule_uuid}` | Edit the status of an existing Alert Notification Rule | Edit |  |  |  |  |

## External Applications

Source: `platform-external-application-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | GET | `/platform/integration/v1/external-application` | List all applications | View |  |  |  |  |
|  | POST | `/platform/integration/v1/external-application` | Create a new application | Edit |  |  |  |  |
|  | PUT | `/platform/integration/v1/external-application/{application_id}` | Update an existing application (full replacement) | Edit |  |  |  |  |
|  | DELETE | `/platform/integration/v1/external-application/{application_type}/id/{application_id}` | Delete an application | Edit |  |  |  |  |
|  | GET | `/platform/integration/v1/external-application/{application_type}/id/{application_id}` | Get External Application details by ID | View |  |  |  |  |

## Managed Threat Detection (MTH/MDR)

Source: `managed-threat-detection-papi.yaml`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | POST | `/public_api/v1/mth/child/add_comment` | Add a comment to an MTH/MDR report | Edit |  |  |  |  |
|  | POST | `/public_api/v1/mth/child/get_comments` | Get comments for MTH/MDR reports | View |  |  |  |  |
|  | POST | `/public_api/v1/mth/child/report/update/status` | Update report status | View |  |  |  |  |
|  | POST | `/public_api/v1/mth/child/report/update/assign` | Update report assignment | Edit |  |  |  |  |
|  | POST | `/public_api/v1/mth/child/get_reports_by_source_id` | Get reports by source ID | View |  |  |  |  |
|  | POST | `/public_api/v1/mth/child/get_reports_by_incident_id` | Get reports by incident ID | View |  |  |  |  |

## Disable Prevention Rules

Source: `disable-prevention-rule-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ✓ | POST | `/public_api/v1/disable_prevention/fetch` | Get Disable Prevention Rules | View | `Cortex.Api.DisablePrevention` | `disable-prevention fetch` | `disable_prevention.bats` | ✓ |
| ✓ | POST | `/public_api/v1/disable_prevention/get_modules` | Get Disable Prevention Modules | View | `Cortex.Api.DisablePrevention` | `disable-prevention get-modules` | `disable_prevention.bats` | ✓ |
|  | POST | `/public_api/v1/disable_prevention/add` | Add Disable Prevention Rule | Edit |  |  |  |  |
|  | POST | `/public_api/v1/disable_prevention/edit` | Edit Disable Prevention Rule | Edit |  |  |  |  |
|  | POST | `/public_api/v1/disable_prevention/delete` | Delete Disable Prevention Rules | Edit |  |  |  |  |

## Disable Injection Prevention Rules

Source: `disable-injection-prevention-rule-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ✓ | POST | `/public_api/v1/disable_injection_prevention_rules/fetch` | Get Disable Injection and Prevention rules | View | `Cortex.Api.DisablePrevention` | `disable-prevention fetch-injection` | `disable_prevention.bats` | ✓ |
|  | POST | `/public_api/v1/disable_injection_prevention_rules/add` | Add Disable Injection and Prevention rule | Edit |  |  |  |  |
|  | POST | `/public_api/v1/disable_injection_prevention_rules/disable` | Disable Disable Injection and Prevention Rules | Edit |  |  |  |  |

## Trusted Images & CWP Rules

Source: `trusted-images-policies-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | DELETE | `/api/v1/policies` | Delete Policies | Edit |  |  |  |  |
|  | GET | `/api/v1/policies` | Get Policies | View |  |  |  |  |
|  | POST | `/api/v1/policies` | Add Policies | Edit |  |  |  |  |
|  | PUT | `/api/v1/policies` | Update Policies | Edit |  |  |  |  |
|  | POST | `/api/v1/policies/disable` | Disable Policies | Edit |  |  |  |  |
|  | POST | `/api/v1/policies/enable` | Enable Policies | Edit |  |  |  |  |
|  | GET | `/api/v1/policies/{id}` | Get a Policy by ID | View |  |  |  |  |
|  | POST | `/api/v1/rules/add` | Add (custom) Compliance rules | Edit |  |  |  |  |
|  | POST | `/api/v1/rules/delete` | Delete (custom) CWP Rules | Edit |  |  |  |  |
|  | POST | `/api/v1/rules/fetch` | Get rules by IDs | View |  |  |  |  |
|  | GET | `/api/v1/rules/get` | Get the Compliance Rules | View |  |  |  |  |
|  | GET | `/api/v1/rules/get/{id}` | Get a rule by ID | View |  |  |  |  |
|  | POST | `/api/v1/rules/lint/rego` | rego script linter | View |  |  |  |  |
|  | POST | `/api/v1/rules/update` | Update (custom) Compliance rules | Edit |  |  |  |  |
|  | GET | `/api/v2/policies` | Get Policies | View |  |  |  |  |
|  | POST | `/api/v2/policies` | Add Policies | Edit |  |  |  |  |
|  | PUT | `/api/v2/policies` | Update Policies | Edit |  |  |  |  |
|  | GET | `/api/v2/policies/{id}` | Get a Policy by ID | View |  |  |  |  |
|  | GET | `/public_api/v1/cwp/policies` | Get Policies. | View |  |  |  |  |
|  | POST | `/public_api/v1/cwp/policies` | Add Policy. | Edit |  |  |  |  |
|  | DELETE | `/public_api/v1/cwp/policies/{id}` | Delete a Policy by ID | Edit |  |  |  |  |
|  | GET | `/public_api/v1/cwp/policies/{id}` | Get a Policy by ID. | View |  |  |  |  |
|  | PUT | `/public_api/v1/cwp/policies/{id}` | Update a Policy by ID. | Edit |  |  |  |  |

## CWP Registry Connectors

Source: `cwp-unmanaged-registry-connector-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | POST | `/public_api/v1/cwp/registry_onboarding/instances` | Create a registry connector | Edit |  |  |  |  |
|  | DELETE | `/public_api/v1/cwp/registry_onboarding/instances/{connectorID}` | Delete a registry connector | Edit |  |  |  |  |
|  | GET | `/public_api/v1/cwp/registry_onboarding/instances/{connectorID}` | Get a registry connector | View |  |  |  |  |
|  | PUT | `/public_api/v1/cwp/registry_onboarding/instances/{connectorID}` | Update a registry connector | Edit |  |  |  |  |

## Asset Compliance

Source: `asset-compliance-papi.yaml`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | POST | `/public_api/v1/compliance/get_asset` | Get asset compliance results | View |  |  |  |  |

## CIEM

Source: `ciem-papi.json`

| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | POST | `/public_api/v1/ciem/access/search` | Search CIEM Access | View |  |  |  |  |
