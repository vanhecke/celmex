# Test Coverage

Integration tests run against a real Cortex tenant using BATS. Read-only endpoints are tested automatically; write endpoints require manual opt-in.

| Sub-API | Endpoint | CLI command | Tested | Notes |
|---------|----------|-------------|--------|-------|
| Api.AuditLogs | POST /public_api/v1/audits/management_logs | audit-logs search | yes | read-only, requires Premium+ license |
