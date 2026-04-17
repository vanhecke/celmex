# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-17

First published release. The Elm registry requires packages to start at 1.0.0
regardless of upstream development history; the feature set below accumulated
across the pre-publish 2.x development line on `main`.

### Added
- 17 view endpoints for best-practice tenant assessments.
- `cortex-test` binary: typed-decoder integration runner for validating API
  response shapes against a live tenant.

### Changed
- CLI encoders replaced with raw JSON passthrough — the CLI no longer
  re-encodes API payloads; it streams the upstream JSON as-is.
- Cortex SDK public API hardened for 2.0.0. Breaking changes from 1.x in
  exposed module surface; see module docs.
- API decoder helpers consolidated into `Cortex.Decode`; URL query encoding
  fixed to correctly escape reserved characters.

### Fixed
- URL query string encoding for request parameters containing reserved
  characters (`&`, `=`, `+`, spaces).
