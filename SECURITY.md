# Security policy

## Reporting a vulnerability

Email **joris@joris.be** with details of the vulnerability. Please include:

- Affected version (`@vanhecke/celmex` on npm, `vanhecke/celmex` on the Elm package registry).
- Reproduction steps or proof-of-concept.
- Whether the issue has been disclosed elsewhere.

You should receive an acknowledgement within 5 business days. Do not file a public GitHub issue for security reports.

## Supported versions

Only the latest published minor of `@vanhecke/celmex` (npm) and `vanhecke/celmex` (Elm) receives security fixes. Upgrades are typically additive (`Request a`-returning sub-API modules), so pinning is safe between patch releases.

## Scope

In scope:

- Credential handling in the SDK and CLI.
- Request signing (the advanced API key flow in `Cortex.Auth`).
- Anything that could leak `CORTEX_API_KEY` or `CORTEX_API_KEY_ID` — for example a code path that logs them, a misconfigured workflow that exposes them, or a packaging mistake that ships them.

Out of scope:

- Vulnerabilities in the Cortex tenant itself — please report those directly to Palo Alto Networks.
- Elm compiler issues.
- Transitive npm CVEs that `npm audit` already tracks; CI fails the build on high+ findings, and Dependabot opens upgrade PRs weekly.
