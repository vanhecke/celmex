# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `Cortex.Query.Dialect` (opaque, with `standard` and `assetInventory`
  constructors) selects the wire shape that `Cortex.RequestData.encode`
  emits. The `assetInventory` dialect ships ready for the asset-inventory
  endpoint and future cloud-API list endpoints (`{SEARCH_FIELD,
  SEARCH_TYPE, SEARCH_VALUE}` filters wrapped in `{AND: [...]}`, sort as a
  one-element array, no `timeframe`).
- `SearchArgs` + `defaultSearchArgs` on `Cortex.Api.Endpoints`,
  `Cortex.Api.Biocs`, `Cortex.Api.Correlations`, `Cortex.Api.Indicators`,
  `Cortex.Api.ScheduledQueries`, and `Cortex.Api.Assets` — every
  list/search endpoint now accepts the same typed filters/sort/range/
  timeframe/extra record.
- CLI flag set (`--filter`, `--sort`, `--limit`, `--offset`, `--range`,
  `--from`, `--to`, `--relative`, `--extra`) extended to all migrated
  endpoint commands.

### Changed
- **BREAKING**: `Cortex.RequestData.encode` now takes a `Dialect`
  argument (`Cortex.Query.standard` matches previous behavior).
- **BREAKING**: `Cortex.Query.encodeFilter` and `Cortex.Query.encodeSort`
  now take a `Dialect` argument.
- **BREAKING**: `Cortex.Api.Endpoints.list`, `Cortex.Api.Biocs.get`,
  `Cortex.Api.Correlations.get`, `Cortex.Api.Indicators.get`,
  `Cortex.Api.ScheduledQueries.list`, and the five
  `Cortex.Api.Assets.get*` counted endpoints
  (`getExternalServices`, `getInternetExposures`, `getExternalIpRanges`,
  `getVulnerabilityTests`, `getExternalWebsites`) now take a `SearchArgs`
  argument. Pass `defaultSearchArgs` for the previous unfiltered
  behavior.
- `Cortex.Api.Assets.list` is unchanged — it uses the asset-inventory
  wire shape and will adopt `SearchArgs` in a future release.

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
