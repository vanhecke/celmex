# Cortex API Implementation Tracker

Complete inventory of all API endpoints from the OpenAPI specs in `docs/cortex-api-openapi/`.

**Legend:**
- **View** = read-only (GET, or POST that fetches/searches data)
- **Edit** = mutating (creates, updates, deletes, triggers actions)
- Elm / CLI / Test columns: `-` = not started, module/command/file name = done

> `cloud-onboarding-papi.json` duplicates `cortex-platform-papi.json` and `appsec-papi (1).json` duplicates `appsec-papi.json` — omitted.

**Progress:** 4/345 endpoints implemented | 180 View | 165 Edit


## Cortex Platform

Source: `cortex-platform-papi.json`

- [ ] `GET /public_api/v1/cli/releases/version` — Get the latest version of the Cortex CLI — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/xql/start_xql_query` — Start an XQL query — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/xql/get_query_results` — Get XQL query results — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/xql/get_quota` — Get XQL query Quota — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/xql/get_query_results_stream` — Get XQL query results Stream — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/distributions/get_versions` — Get Distribution version — **View** — Elm: - | CLI: - | Test: -
- [x] `POST /public_api/v1/endpoints/get_endpoints` — Get all Endpoints — **View** — Elm: Cortex.Api.Endpoints | CLI: endpoints list | Test: endpoints.bats
- [ ] `POST /public_api/v1/endpoints/get_policy` — Get Policy — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/endpoints/delete` — Delete Endpoints — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/distributions/create` — Create distributions — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/distributions/get_distributions` — Get Distributions — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/device_control/get_violations` — Get Violations — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/distributions/get_status` — Get Distribution status — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/distributions/get_dist_url` — Get Distribution URL — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/endpoints/update_agent_name` — Set an Endpoint Alias — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/tags/agents/assign` — Assign Tags — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/tags/agents/remove` — Remove Tags — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/endpoints/restore` — Restore File — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/actions/file_retrieval_details` — File Retrieval Details — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/hash_exceptions/allowlist` — Allow List Files — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/quarantine/status` — Get Quarantine Status — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/endpoints/quarantine` — Quarantine Files — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/hash_exceptions/blocklist` — Block List Files — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/endpoints/unisolate` — Unisolate Endpoints — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/endpoints/abort_scan` — Cancel Scan Endpoints — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/endpoints/scan` — Scan Endpoints — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/actions/get_action_status` — Get Action Status — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/scripts/run_snippet_code_script` — Run Snippet Code Script — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/scripts/run_script` — Run Script — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/scripts/get_script_metadata` — Get Script Metadata — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/scripts/get_script_execution_status` — Get Script Execution Status — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/scripts/get_scripts` — Get Scripts — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/scripts/get_script_execution_results` — Get Script Execution Results — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/scripts/get_script_execution_results_files` — Get Script Execution Result Files — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/scripts/get_script_code` — Get Script Code — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/indicators/insert_csv` — Insert Simple Indicators, CSV — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/indicators/insert_jsons` — Insert Simple Indicators, JSON — **Edit** — Elm: - | CLI: - | Test: -
- [x] `POST /public_api/v1/audits/management_logs` — Get Audit Management Log — **View** — Elm: Cortex.Api.AuditLogs | CLI: audit-logs search | Test: audit_logs.bats
- [x] `GET /public_api/v1/healthcheck` — System Health Check — **View** — Elm: Cortex.Api.Healthcheck | CLI: healthcheck | Test: healthcheck.bats
- [x] `POST /public_api/v1/system/get_tenant_info` — Get Tenant Info — **View** — Elm: Cortex.Api.TenantInfo | CLI: tenant-info | Test: tenant_info.bats
- [ ] `POST /public_api/v1/rbac/get_users` — Get Users — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/rbac/get_roles` — Get Roles — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/rbac/get_user_group` — Get User Groups — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/rbac/set_user_role` — Set a User Role — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/endpoints/get_endpoint` — Get Endpoint — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/get_risk_score` — Get Risk Score — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/get_risky_users` — Get Risky Users — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/get_risky_hosts` — Get Risky Hosts — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/endpoints/file_retrieval` — Retrieve File — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/endpoints/isolate` — Isolate Endpoints — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/audits/agents_reports` — Get Audit Agent Report — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/assets/get_external_service` — Get External Service — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/assets/get_external_services` — Get All Services — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/assets/get_assets_internet_exposure` — Get all Internet Exposures — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/assets/get_asset_internet_exposure` — Get Internet Exposure — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/assets/get_external_ip_address_ranges` — Get all External IP Address Ranges — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/assets/get_external_ip_address_range` — Get External IP Address Range — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/triage_endpoint` — Initiate Forensics Triage — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/assets/get_vulnerability_tests` — Get vulnerability tests — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/assets/bulk_update_vulnerability_tests` — Bulk Update Vulnerability Tests — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/dataset/define_dataset` — Define an XQL user dataset — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/dataset/get_created_datasets` — Get created XQL user datasets — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/dataset/delete_dataset` — Delete an XQL user dataset — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/xql/add_dataset` — Add Dataset — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v2/xql/delete_dataset` — Delete a dataset — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/xql/get_datasets` — Get all datasets — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/xql/lookups/add_data` — Add or update data in a lookup dataset — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/xql/lookups/remove_data` — Remove data from a lookup dataset — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/xql/lookups/get_data` — Get data from a lookup dataset — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/get_triage_presets` — Get triage presets — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/authentication-settings/create` — Create authentication settings for IdP SSO or metadata URL — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/authentication-settings/update` — Update authentication settings — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/authentication-settings/delete` — Delete authentication settings by domain — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/authentication-settings/get/settings` — Get authentication settings for all configured domains — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/authentication-settings/get/metadata` — Get IdP metadata — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/asm_management/upload_asm_data` — Upload assets to the inventory — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/assets/get_external_website` — Get Website Details — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/assets/get_external_websites` — Get all Websites — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/assets/get_external_websites/last_external_assessment` — Get Websites Last Assessment — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/integrations/syslog/create` — Create a syslog integration — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/integrations/syslog/get` — Get all or filtered syslog servers — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/integrations/syslog/update` — Update a syslog integration — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/integrations/syslog/delete` — Delete all or filtered syslog integrations — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/integrations/syslog/test` — Test syslog integration — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/distributions/delete` — Delete agent installation packages — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/get_attack_surface_rules` — Get all Attack Surface Rules — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/asm_management/remove_asm_data` — Remove Assets — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/scheduled_queries/list` — Get scheduled queries — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/scheduled_queries/insert` — Insert or update scheduled queries — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/scheduled_queries/delete` — Delete a scheduled query — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/xql_library/get` — Get XQL Queries — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/xql_library/insert` — Insert or update XQL queries — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/xql_library/delete` — Delete XQL Queries — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/indicators/get` — Get Indicators (IOCs) — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/indicators/insert` — Insert or update IOCs — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/indicators/delete` — Delete Indicators (IOCs) — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/bioc/get` — Get BIOCs — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/bioc/insert` — Insert or update BIOCs — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/bioc/delete` — Delete BIOCs — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/correlations/get` — Get Correlation Rules — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/correlations/insert` — Insert or update Correlation Rules — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/correlations/delete` — Delete Correlation Rules — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/playbooks/get` — Get a playbook — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/playbooks/insert` — Insert or update playbooks — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/playbooks/delete` — Delete a playbook — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/scripts/get` — Get a script — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/scripts/insert` — Insert or update a script — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/scripts/delete` — Delete a script — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/dashboards/get` — Get dashboards — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/dashboards/insert` — Insert or update dashboards — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/dashboards/delete` — Delete dashboards — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/widgets/get` — Get widgets — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/widgets/insert` — Insert or update widgets — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/widgets/delete` — Delete widgets — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/issue` — Create a new issue — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/issue/search` — Retrieve issues based on filters — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/issue/{issue-id}` — Update existing issue — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/issue/schema` — Retrieve issue schema — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/case/search` — Retrieve Cases based on filters — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/case/update/{case-id}` — Update existing case — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/case/artifacts/{case-id}` — Retrieve Case Artifacts by Case ID — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/entries/get` — Get War Room entries — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/entries/insert` — Add War Room entries — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/assets` — Get all or filtered assets — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/assets/{id}` — Get asset by ID — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/assets/{id}/raw_fields` — Get raw fields of asset by ID — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/assets/schema` — Get schema of asset inventory — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/assets/enum/{field_name}` — Get enum values of specified field — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/asset-groups` — Get all or filtered asset groups — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/asset-groups/create` — Create an Asset Group — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/asset-groups/update/{group_id}` — Update an Asset Group — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/asset-groups/delete/{group_id}` — Delete an Asset Group — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/api_keys/get_api_keys` — Get existing API keys — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/api_keys/generate` — Generate an API key — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/api_keys/delete` — Delete API keys — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/tags/agents/delete_permanently` — Delete Tags Permanently — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/endpoints/upgrade` — Upgrade Agents — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/endpoints/get_profiles` — Get endpoint security profiles — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/legacy_exceptions/get_modules` — Get Legacy Exceptions Modules — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/legacy_exceptions/fetch` — Fetch Legacy Exception Rules — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/legacy_exceptions/add` — Add Legacy Exception Rule — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/legacy_exceptions/edit` — Edit Legacy Exception Rule — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/legacy_exceptions/delete` — Delete Legacy Exception Rules — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/profiles/prevention/add` — Add Prevention Profile — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/profiles/add_signer_cn_to_allowlist` — Add Signer CN to Allowlist — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/profiles/prevention/edit` — Edit Prevention Profile — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/profiles/prevention/get_modules` — Get Prevention Profile Modules — **View** — Elm: - | CLI: - | Test: -

## Agent Configuration

Source: `agent-configurations-papi.yaml`

- [ ] `GET /public_api/v1/configurations/agent/content_management` — Retrieve content management settings — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/configurations/agent/content_management/set` — Update content management settings — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/configurations/agent/agent_status` — Retrieve agent status timeout settings — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/configurations/agent/agent_status/set` — Update agent status timeout settings — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/configurations/agent/auto_upgrade` — Retrieve agent auto-upgrade settings — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/configurations/agent/auto_upgrade/set` — Update agent auto-upgrade settings — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/configurations/agent/wildfire_analysis` — Retrieve WildFire analysis settings — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/configurations/agent/wildfire_analysis/set` — Update WildFire analysis settings — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/configurations/agent/informative_btp_issues` — Retrieve informative BTP issues settings — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/configurations/agent/informative_btp_issues/set` — Update informative BTP issues settings — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/configurations/agent/cortex_xdr_log_collection` — Retrieve log collection settings — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/configurations/agent/cortex_xdr_log_collection/set` — Update log collection settings — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/configurations/agent/action_center_expiration` — Retrieve action center expiration settings — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/configurations/agent/action_center_expiration/set` — Update action center expiration settings — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/configurations/agent/critical_environment_versions` — Retrieve critical environment versions settings — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/configurations/agent/critical_environment_versions/set` — Update critical environment versions settings — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/configurations/agent/advanced_analysis` — Retrieve advanced analysis settings — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/configurations/agent/advanced_analysis/set` — Update advanced analysis settings — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/configurations/agent/endpoint_administration_cleanup` — Retrieve endpoint administration cleanup settings — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/configurations/agent/endpoint_administration_cleanup/set` — Update endpoint administration cleanup settings — **Edit** — Elm: - | CLI: - | Test: -

## Compliance

Source: `compliance-papi.json`

- [ ] `POST /public_api/v1/compliance/get_assessment_profiles` — Get assessment profiles — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/get_assessment_profile` — Get assessment profile by ID — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/add_assessment_profile` — Add assessment profile — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/edit_assessment_profile` — Edit assessment profile — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/delete_assessment_profile` — Delete assessment profile — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/get_assessment_results` — Get assessment profile results — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/get_controls` — Get compliance controls — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/get_control` — Get compliance control by ID — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/add_control` — Add new control — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/edit_control` — Edit existing control — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/delete_control` — Delete control — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/add_rules_to_control` — Add compliance rules to a compliance control — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/delete_rules_from_control` — Delete rules from control — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/get_control_categories_and_subcategories` — Get categories and subcategories — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/get_control_by_revision` — Get control by revision — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/get_control_failed_results` — Get control failed results — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/get_rule_failed_results` — Get rule failed results — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/get_reports` — Get compliance reports — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/get_standards` — Get compliance standards — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/get_standard` — Get single standard by ID — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/add_standard` — Add new standard — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/edit_standard` — Edit existing standard — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/delete_standard` — Delete standard — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/compliance/get_assets` — Get compliance assets — **View** — Elm: - | CLI: - | Test: -

## CSPM Policies

Source: `cspm-policies-papi.json`

- [ ] `POST /public_api/v1/policy` — Create Public Policy — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/policy/search` — List Public Policies — **View** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /public_api/v1/policy/{policy_id}` — Delete Public Policy — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/policy/{policy_id}` — Get Public Policy — **View** — Elm: - | CLI: - | Test: -
- [ ] `PATCH /public_api/v1/policy/{policy_id}` — Update Public Policy — **Edit** — Elm: - | CLI: - | Test: -

## CWP (Cloud Workload Protection)

Source: `cwp-papi.json`

- [ ] `GET /public_api/v2/cwp/policies` — Get CWP Policies (v2) — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v2/cwp/policies` — Add CWP Policies (v2) — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v2/cwp/policies/{id}` — Get a CWP Policy by ID (v2) — **View** — Elm: - | CLI: - | Test: -
- [ ] `PUT /public_api/v2/cwp/policies/{id}` — Update a CWP Policy by ID (v2) — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/cwp/policies` — Get CWP Policies (v1) — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/cwp/policies` — Add CWP Policies (v1) — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /public_api/v1/cwp/policies/{id}` — Delete a CWP Policy by ID (v1) — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/cwp/policies/{id}` — Get a CWP Policy by ID (v1) — **View** — Elm: - | CLI: - | Test: -
- [ ] `PUT /public_api/v1/cwp/policies/{id}` — Update a CWP Policy by ID (v1) — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/assets/{assetID}/sbom` — Get the SBOM of the specified asset — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/cwp/registry_onboarding/instances` — Create a registry connector — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /public_api/v1/cwp/registry_onboarding/instances/{connectorID}` — Delete a registry connector — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/cwp/registry_onboarding/instances/{connectorID}` — Get a registry connector — **View** — Elm: - | CLI: - | Test: -
- [ ] `PUT /public_api/v1/cwp/registry_onboarding/instances/{connectorID}` — Update a registry connector — **Edit** — Elm: - | CLI: - | Test: -

## IAM Platform

Source: `iam-platform-papi.json`

- [ ] `GET /platform/iam/v1/role` — List all roles — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /platform/iam/v1/role` — Create a new role — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /platform/iam/v1/role/{role_id}` — Delete an existing role — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /platform/iam/v1/role/permission-config` — List all permission configs — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /platform/iam/v1/user-group` — List all user groups — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /platform/iam/v1/user-group` — Create a new user group — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /platform/iam/v1/user-group/{group_id}` — Delete an existing user group — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `PATCH /platform/iam/v1/user-group/{group_id}` — Edit an existing user group — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /platform/iam/v1/scope/{entity_type}/{entity_id}` — Retrieve an existing scope — **View** — Elm: - | CLI: - | Test: -
- [ ] `PUT /platform/iam/v1/scope/{entity_type}/{entity_id}` — Edit an existing scope — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /platform/iam/v1/user` — List all users — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /platform/iam/v1/user/{user_email}` — Get user — **View** — Elm: - | CLI: - | Test: -
- [ ] `PATCH /platform/iam/v1/user/{user_email}` — Edit an existing user — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /platform/iam/v1/api-key/{api_key_id}` — Get API Key — **View** — Elm: - | CLI: - | Test: -
- [ ] `PUT /platform/iam/v1/api-key/{api_key_id}` — Edit an API key — **Edit** — Elm: - | CLI: - | Test: -

## Vulnerability Intelligence

Source: `vulnerability-intelligence-papi.json`

- [ ] `POST /public_api/uvem/v1/get_vulnerabilities` — Get list of vulnerabilities — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/uvem/v1/get_affected_software` — Get affected software — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/uvem/v1/vulnerabilities` — Get vulnerability details — **View** — Elm: - | CLI: - | Test: -

## UVEM (Vulnerability Management)

Source: `uvem-papi.json`

- [ ] `POST /public_api/uvm_public/v1/list_policies` — Get Policies List — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/uvm_public/v1/create_policy` — Create Policy Public — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `PUT /public_api/uvm_public/v1/update_policy/{id}` — Update Policy — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/uvm_public/v1/get_policy/{id}` — Get Policy By ID — **View** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /public_api/uvm_public/v1/delete_policy/{id}` — Delete Policy — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/vulnerability-management/v1/scan` — Trigger Scan for an AssetId — **Edit** — Elm: - | CLI: - | Test: -

## NetScan

Source: `netscan-papi.yaml`

- [ ] `GET /public_api/netscan/v1/scan/run` — Get scan run status — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/netscan/v1/scan/run` — Launch a scan run — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/netscan/v1/scan/run/{id}` — Get scan run status by ID — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/netscan/v1/scan/run/{id}` — Launch a scan run by definition ID — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/netscan/v1/scan/definition` — Create a scan definition — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/netscan/v1/scan/run/{id}/command` — Send a command to a running scan — **Edit** — Elm: - | CLI: - | Test: -

## AppSec

Source: `appsec-papi.json`

- [ ] `GET /public_api/appsec/v1/application/configuration` — Get an application configuration — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/application` — Get applications — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/appsec/v1/application` — Create an application — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /public_api/appsec/v1/application/{applicationId}` — Delete an application — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/application/{applicationId}` — Get an application — **View** — Elm: - | CLI: - | Test: -
- [ ] `PUT /public_api/appsec/v1/application/{applicationId}` — Update an application — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/policies` — List AppSec policies — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/appsec/v1/policies` — Create an AppSec policy — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/rules` — Get AppSec rules — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/appsec/v1/rules` — Create an AppSec rule — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /public_api/appsec/v1/rules/{ruleId}` — Delete an AppSec rule — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/rules/{ruleId}` — Get an AppSec rule — **View** — Elm: - | CLI: - | Test: -
- [ ] `PATCH /public_api/appsec/v1/rules/{ruleId}` — Modify an AppSec rule — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/rules/rule-labels` — Get AppSec rule labels — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/appsec/v1/rules/validate` — Create an AppSec rule validation — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/repositories` — Get repositories — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/repositories/{assetId}` — Get a repository — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/repositories/{assetId}/scan-configuration` — Get a repository scan configuration — **View** — Elm: - | CLI: - | Test: -
- [ ] `PUT /public_api/appsec/v1/repositories/{assetId}/scan-configuration` — Update a repository scan configuration — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/integrations` — Get AppSec Data Source — **View** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /public_api/appsec/v1/integrations/{id}` — Delete an AppSec Data Source — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/integrations/{id}` — Get an AppSec Data Source — **View** — Elm: - | CLI: - | Test: -
- [ ] `PUT /public_api/appsec/v1/integrations/{id}` — Update an AppSec Data Source — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/repositories/{assetId}/branches` — Get AppSec repository branches — **View** — Elm: - | CLI: - | Test: -
- [ ] `PUT /public_api/appsec/v1/repositories/{assetId}/branches` — Update an AppSec repository branch — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/scans/unscanned-repositories` — Get unscanned AppSec scan management repositories — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/sbom/repository/{repoId}` — Get an SBOM for the specified repository — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/sbom/organization/{orgName}` — Get all SBOMs for the specified organization — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/scans/periodic` — Get AppSec branch periodic scans — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/scans/pr` — Get AppSec Pull Request scans — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/scans/ci` — Get AppSec CI scans — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/scans/{scanId}/issues` — List AppSec scan issues — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/scans/{scanId}/findings` — List AppSec scan findings — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/appsec/v1/scan/repository/{repositoryId}` — Rerun a repository scan — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /public_api/appsec/v1/policies/{policyId}` — Delete an AppSec policy — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/policies/{policyId}` — Get an AppSec policy — **View** — Elm: - | CLI: - | Test: -
- [ ] `PUT /public_api/appsec/v1/policies/{policyId}` — Update an AppSec policy — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/application/criteria/all` — Get all criteria — **View** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /public_api/appsec/v1/application/criteria/{criteriaId}` — Delete a Criteria — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/application/criteria/{criteriaId}` — Get a Criteria by ID — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/appsec/v1/application/criteria` — Create a Criteria — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/issues/fix/{issueId}/fix_suggestion` — Get Fix Suggestion — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/appsec/v1/issues/fix/trigger_fix_pull_request` — Trigger Fix Pull Request — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/appsec/v1/issues/fix/{remediationId}` — Get Fix Status — **View** — Elm: - | CLI: - | Test: -

## DSPM (Data Security)

Source: `dspm-papi.json`

- [ ] `POST /public_api/v1/data-security/data-patterns` — Get data pattern inventory — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/data-security/objects/fields` — Get field inventory details — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/data-security/objects/files` — Get file inventory details — **View** — Elm: - | CLI: - | Test: -

## Platform Notifications

Source: `platform-notifications-papi.json`

- [ ] `GET /platform/notifications/v1/list-rules` — List all rules — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /platform/notifications/v1/rule` — Create a new rule — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /platform/notifications/v1/rule/{rule_uuid}` — Delete an existing Alert Notification Rule — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /platform/notifications/v1/rule/{rule_uuid}` — Retrieve a specific alert notification rule — **View** — Elm: - | CLI: - | Test: -
- [ ] `PUT /platform/notifications/v1/rule/{rule_uuid}` — Edit an existing Alert Notification Rule — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `PATCH /platform/notifications/v1/update-rule-status/{rule_uuid}` — Edit the status of an existing Alert Notification Rule — **Edit** — Elm: - | CLI: - | Test: -

## External Applications

Source: `platform-external-application-papi.json`

- [ ] `GET /platform/integration/v1/external-application` — List all applications — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /platform/integration/v1/external-application` — Create a new application — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `PUT /platform/integration/v1/external-application/{application_id}` — Update an existing application (full replacement) — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /platform/integration/v1/external-application/{application_type}/id/{application_id}` — Delete an application — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /platform/integration/v1/external-application/{application_type}/id/{application_id}` — Get External Application details by ID — **View** — Elm: - | CLI: - | Test: -

## Managed Threat Detection (MTH/MDR)

Source: `managed-threat-detection-papi.yaml`

- [ ] `POST /public_api/v1/mth/child/add_comment` — Add a comment to an MTH/MDR report — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/mth/child/get_comments` — Get comments for MTH/MDR reports — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/mth/child/report/update/status` — Update report status — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/mth/child/report/update/assign` — Update report assignment — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/mth/child/get_reports_by_source_id` — Get reports by source ID — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/mth/child/get_reports_by_incident_id` — Get reports by incident ID — **View** — Elm: - | CLI: - | Test: -

## Disable Prevention Rules

Source: `disable-prevention-rule-papi.json`

- [ ] `POST /public_api/v1/disable_prevention/fetch` — Get Disable Prevention Rules — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/disable_prevention/get_modules` — Get Disable Prevention Modules — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/disable_prevention/add` — Add Disable Prevention Rule — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/disable_prevention/edit` — Edit Disable Prevention Rule — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/disable_prevention/delete` — Delete Disable Prevention Rules — **Edit** — Elm: - | CLI: - | Test: -

## Disable Injection Prevention Rules

Source: `disable-injection-prevention-rule-papi.json`

- [ ] `POST /public_api/v1/disable_injection_prevention_rules/fetch` — Get Disable Injection and Prevention rules — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/disable_injection_prevention_rules/add` — Add Disable Injection and Prevention rule — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/disable_injection_prevention_rules/disable` — Disable Disable Injection and Prevention Rules — **Edit** — Elm: - | CLI: - | Test: -

## Trusted Images & CWP Rules

Source: `trusted-images-policies-papi.json`

- [ ] `DELETE /api/v1/policies` — Delete Policies — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /api/v1/policies` — Get Policies — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /api/v1/policies` — Add Policies — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `PUT /api/v1/policies` — Update Policies — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /api/v1/policies/disable` — Disable Policies — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /api/v1/policies/enable` — Enable Policies — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /api/v1/policies/{id}` — Get a Policy by ID — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /api/v1/rules/add` — Add (custom) Compliance rules — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /api/v1/rules/delete` — Delete (custom) CWP Rules — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `POST /api/v1/rules/fetch` — Get rules by IDs — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /api/v1/rules/get` — Get the Compliance Rules — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /api/v1/rules/get/{id}` — Get a rule by ID — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /api/v1/rules/lint/rego` — rego script linter — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /api/v1/rules/update` — Update (custom) Compliance rules — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /api/v2/policies` — Get Policies — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /api/v2/policies` — Add Policies — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `PUT /api/v2/policies` — Update Policies — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /api/v2/policies/{id}` — Get a Policy by ID — **View** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/cwp/policies` — Get Policies. — **View** — Elm: - | CLI: - | Test: -
- [ ] `POST /public_api/v1/cwp/policies` — Add Policy. — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /public_api/v1/cwp/policies/{id}` — Delete a Policy by ID — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/cwp/policies/{id}` — Get a Policy by ID. — **View** — Elm: - | CLI: - | Test: -
- [ ] `PUT /public_api/v1/cwp/policies/{id}` — Update a Policy by ID. — **Edit** — Elm: - | CLI: - | Test: -

## CWP Registry Connectors

Source: `cwp-unmanaged-registry-connector-papi.json`

- [ ] `POST /public_api/v1/cwp/registry_onboarding/instances` — Create a registry connector — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `DELETE /public_api/v1/cwp/registry_onboarding/instances/{connectorID}` — Delete a registry connector — **Edit** — Elm: - | CLI: - | Test: -
- [ ] `GET /public_api/v1/cwp/registry_onboarding/instances/{connectorID}` — Get a registry connector — **View** — Elm: - | CLI: - | Test: -
- [ ] `PUT /public_api/v1/cwp/registry_onboarding/instances/{connectorID}` — Update a registry connector — **Edit** — Elm: - | CLI: - | Test: -

## Asset Compliance

Source: `asset-compliance-papi.yaml`

- [ ] `POST /public_api/v1/compliance/get_asset` — Get asset compliance results — **View** — Elm: - | CLI: - | Test: -

## CIEM

Source: `ciem-papi.json`

- [ ] `POST /public_api/v1/ciem/access/search` — Search CIEM Access — **View** — Elm: - | CLI: - | Test: -
