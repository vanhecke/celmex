Cortex XSIAM Platform Elm SDK + CLI — bootstrap plan

 Context

 Fresh repo (only .gitignore, docs/, and a previous-session temp-plan.md). We
 are building an Elm project that serves two consumers from one shared
 codebase:

 1. Library — publishable Elm package that Elm web apps can import.
 2. CLI binary — xsiam ... Node wrapper around Platform.worker, which also
 doubles as the integration-test driver.

 The target API is the Cortex XSIAM Platform APIs (v3.4, per
 docs/cortex-api-openapi/cortex-platform-papi.json info.title). The 22
 openapi specs under docs/cortex-api-openapi/ cover the platform surface:
 cortex-platform, cwp, dspm, ciem, iam-platform, appsec, cspm-policies,
 agent-configurations, asset-compliance, cloud-onboarding, compliance,
 managed-threat-detection, netscan, platform-external-application,
 platform-notifications, trusted-images-policies, uvem, vulnerability-intelligence,
 cwp-unmanaged-registry-connector, disable-injection-prevention-rule,
 disable-prevention-rule. Total: ~518 operations.

 Decisions locked in with the user (this session):

 - Authentication: Advanced API Auth — each request signs with
 SHA256(apiKey ++ nonce ++ String.fromInt timestampMillis) and sends four
 headers: Authorization (the hex hash), x-xdr-auth-id (the key ID),
 x-xdr-timestamp (millis since epoch), x-xdr-nonce (64-char random).
 The openapi specs only declare Authorization + x-xdr-auth-id because the
 advanced scheme is a client-side protocol layered on top.
 - Scope: Iterative curated subset. Hand-written — but only the
 endpoints we actually need, added on demand. One Elm module per sub-API; each
 module grows operation-by-operation as a PR cycle. No upfront 518-op blitz, no
 openapi codegen.
 - Bootstrap target: GET /public_api/v1/cli/releases/version from
 cortex-platform-papi.json. Returns { "version": "v1.2.3" }. No license
 gate, trivial decoder, exercises the full auth + transport + CLI stack.
 - Sub-APIs are hand-written, one Elm module each.
 - CLI lives in cli/ subdirectory with its own elm.json; root stays a
 publishable package.
 - Integration tests reuse the CLI binary, driven by a shell script + env vars.
 - Only integration testing against a real tenant. No unit tests.
 - elm-format enforced via Make target.
 - Secrets live in a local .envrc that is gitignored. Never commit them.

 Note on file duplicates: appsec-papi (1).json is byte-for-byte identical to
 appsec-papi.json. Treat only appsec-papi.json as canonical.

 ---
 Architecture

 src/  (elm.json: type=package)                cli/  (elm.json: type=application)
 ┌─────────────────────────────────────┐       ┌────────────────────────────────┐
 │ Cortex.Xsiam.Request (opaque)       │       │ Cli.Main   (Platform.worker)   │
 │ Cortex.Xsiam.Auth    (pure SHA256)  │       │ Cli.Commands (argv→Request)    │
 │ Cortex.Xsiam.Client  (send/sendWith)│←──────│ Cli.Ports   (stdout/stderr/exit)│
 │ Cortex.Xsiam.Error                  │  uses │                                │
 │ Cortex.Xsiam.Platform.CliReleases   │       └──────────┬─────────────────────┘
 │ (+ more sub-API modules added       │                  │
 │  on demand)                         │                  ▼
 └──────────────┬──────────────────────┘       ┌────────────────────────────────┐
                │                              │ cli/index.js                   │
       imported by                             │   xhr2 polyfill                │
                │                              │   Date.now + crypto.randomBytes│
                ▼                              │   argv → flags                 │
        Browser web apps                       │   ports → stdout/exit          │
                                               └──────────┬─────────────────────┘
                                                          │ driven by
                                                          ▼
                                               tests/integration.sh (bash)

 Key invariant: a Request a is a pure description (method, path, body,
 query, decoder). Effects — Time.now, Random.step, Http.task — only fire
 inside Cortex.Xsiam.Client.send. The same Request therefore works in a
 browser (library consumer) and in Node (CLI consumer), and every sub-API module
 is pure and trivially refactorable.

 Package purity constraint (from docs/guide.elm-lang.org — "Ports are for
 applications, not packages"): the library src/ must be pure Elm with no
 ports. All I/O happens in the CLI's cli/src/Cli/* tree or in the web-app
 consumer.

 ---
 File layout

 /Users/joris/Projects/celmex/
 ├── elm.json                          # type=package, exposed-modules list
 ├── src/
 │   └── Cortex/
 │       └── Xsiam/
 │           ├── Auth.elm              # signing primitives (pure)
 │           ├── Client.elm            # Config, send, sendWith, toRequestRecord
 │           ├── Error.elm             # Error type
 │           ├── Request.elm           # opaque Request a + builders
 │           └── Platform/
 │               └── CliReleases.elm   # FIRST sub-API module (version endpoint)
 ├── cli/
 │   ├── elm.json                      # type=application
 │   ├── src/
 │   │   └── Cli/
 │   │       ├── Main.elm              # Platform.worker entrypoint
 │   │       ├── Commands.elm          # subcommand dispatch
 │   │       └── Ports.elm             # stdout/stderr/exit ports
 │   ├── index.js                      # node wrapper + xhr2 polyfill
 │   └── bin/
 │       └── xsiam                     # shebang launcher → node ../index.js
 ├── tests/
 │   └── integration.sh                # bash driver, env-var auth, asserts on cli
 ├── docs/                             # already present: openapi specs + guides
 ├── .envrc.example                    # XSIAM_TENANT_URL, XSIAM_API_KEY, XSIAM_API_KEY_ID
 ├── .gitignore                        # add .envrc, elm-stuff/, node_modules/, cli/dist/
 ├── package.json                      # devDeps: xhr2; scripts: build, format, test
 ├── Makefile                          # format, build, test, clean
 ├── README.md                         # quickstart for library + CLI
 └── TEST.md                           # coverage table (endpoint × CLI cmd × tested?)

 Module hierarchy decision: Cortex.Xsiam.* at the top (matches the spec
 title "Cortex XSIAM Platform APIs"), with sub-APIs nested one level deeper
 under Cortex.Xsiam.Platform.* so that each openapi file maps to one folder
 there (Cortex.Xsiam.Platform.Cwp, .Dspm, .Iam, etc.). The core foundation
 (Auth, Client, Error, Request) stays flat under Cortex.Xsiam.* so
 consumers get import Cortex.Xsiam.Client.

 ---
 Library API design

 Cortex.Xsiam.Request (exposed opaquely)

 module Cortex.Xsiam.Request exposing
     ( Request, get, post, withQuery, map
     , toInternal  -- exposed only to Cortex.Xsiam.Client via a companion pattern
     )

 type Request a
     = Request
         { method : String              -- "GET" | "POST" | ...
         , path : List String           -- ["public_api","v1","cli","releases","version"]
         , query : List ( String, String )
         , body : Encode.Value           -- Encode.null for GET
         , decoder : Decoder a           -- response body decoder
         }

 get : List String -> Decoder a -> Request a
 post : List String -> Encode.Value -> Decoder a -> Request a
 withQuery : List ( String, String ) -> Request a -> Request a
 map : (a -> b) -> Request a -> Request b

 toInternal is exposed so Client can unpack the record; callers never touch
 it (Elm packages don't have true private exports, so this is the convention).

 Cortex.Xsiam.Auth (pure, exposed for advanced users)

 module Cortex.Xsiam.Auth exposing
     ( Credentials, Stamp, sign, nonceGenerator )

 type alias Credentials =
     { apiKeyId : String, apiKey : String }

 type alias Stamp =
     { timestamp : Int           -- millis since epoch
     , nonce : String            -- 64-char random
     }

 {-| Produce the four advanced-auth headers from creds + stamp.
     hash = SHA256.toHex (SHA256.fromString (apiKey ++ nonce ++ String.fromInt timestamp))
     Headers: Authorization=<hash>, x-xdr-auth-id=<keyId>,
              x-xdr-timestamp=<timestamp>, x-xdr-nonce=<nonce>
 -}
 sign : Credentials -> Stamp -> List Http.Header

 {-| Default nonce generator — 64 chars [A-Za-z0-9]. Good enough for uniqueness
     in browser-initiated calls (seeded from Time.now). The CLI prefers to source
     nonces from Node's crypto.randomBytes via sendWith. -}
 nonceGenerator : Random.Generator String

 SHA-256 dependency: TSFoster/elm-sha1 is SHA-1 only — wrong. Use
 ktonon/elm-crypto (published for 0.19, provides Crypto.Hash.sha256).
 Fallback: prozacchiwawa/elm-sha if ktonon/elm-crypto proves unavailable.
 Pin the choice in step 2 below after a quick package-registry check.

 Cortex.Xsiam.Client

 module Cortex.Xsiam.Client exposing
     ( Config, send, sendWith, toRequestRecord )

 type alias Config =
     { tenant : String                -- e.g. "https://api-joris.xdr.eu.paloaltonetworks.com"
     , credentials : Auth.Credentials
     }

 {-| Default send: derives timestamp from Time.now and nonce from elm/random.
     Suitable for browser apps. -}
 send : Config -> (Result Error a -> msg) -> Request a -> Cmd msg

 {-| Escape-hatch send: caller supplies the stamp. CLI uses this so the nonce
     comes from node's crypto.randomBytes (passed in via Elm flags). -}
 sendWith : Auth.Stamp -> Config -> (Result Error a -> msg) -> Request a -> Cmd msg

 {-| Pure record for consumers who want to drive Http themselves. -}
 toRequestRecord :
     Config
     -> Auth.Stamp
     -> Request a
     -> { method : String
        , headers : List Http.Header
        , url : String
        , body : Http.Body
        , decoder : Decoder a
        }

 send implementation pattern (uses Task.andThen chain so Time + Random
 happen before the HTTP fires):

 send config toMsg req =
     Time.now
         |> Task.map Time.posixToMillis
         |> Task.andThen
             (\ts ->
                 let
                     ( nonce, _ ) = Random.step Auth.nonceGenerator (Random.initialSeed ts)
                     rec = toRequestRecord config { timestamp = ts, nonce = nonce } req
                 in
                 Http.task
                     { method = rec.method
                     , headers = rec.headers
                     , url = rec.url
                     , body = rec.body
                     , resolver = Http.stringResolver (decodeXsiamResponse rec.decoder)
                     , timeout = Just 30000
                     }
             )
         |> Task.attempt toMsg

 Cortex.Xsiam.Error

 type Error
     = NetworkError
     | Timeout
     | BadStatus Int (Maybe ApiError)   -- ApiError parsed from err_msg/err_code body
     | BadBody String                    -- decoder failure, raw body included
     | BadUrl String

 type alias ApiError =
     { errCode : Maybe String            -- "NOT_FOUND" | "INTERNAL_ERROR" | http code
     , errMsg : String
     , errExtra : Maybe Value
     }

 Error-envelope handling: Client.send's string resolver first tries the
 payload decoder; on non-2xx status, it tries to decode the body as the two
 known error shapes (GenericReply from cortex-platform, PublicAPIErrorResponse
 from cwp — see Phase-1 findings). Whichever parses wins; otherwise Nothing.

 Cortex.Xsiam.Platform.CliReleases — first sub-API module (template)

 Every sub-API module follows this shape: request-param type(s), encoder(s),
 decoder(s), and a function that returns a Request a. No effects, no HTTP.

 module Cortex.Xsiam.Platform.CliReleases exposing (Version, getVersion)

 import Cortex.Xsiam.Request as Request exposing (Request)
 import Json.Decode as Decode exposing (Decoder)

 type alias Version =
     { version : String }

 {-| GET /public_api/v1/cli/releases/version
     Returns the latest Cortex CLI version. No body, no query params, no
     license gate. Ideal bootstrap smoke test. -}
 getVersion : Request Version
 getVersion =
     Request.get
         [ "public_api", "v1", "cli", "releases", "version" ]
         versionDecoder

 versionDecoder : Decoder Version
 versionDecoder =
     Decode.map Version (Decode.field "version" Decode.string)

 ---
 CLI design

 cli/elm.json

 {
     "type": "application",
     "source-directories": ["src", "../src"],
     "elm-version": "0.19.1",
     "dependencies": {
         "direct": {
             "elm/core": "1.0.5",
             "elm/json": "1.1.3",
             "elm/http": "2.0.0",
             "elm/time": "1.0.0",
             "elm/random": "1.0.0",
             "elm/bytes": "1.0.8",
             "ktonon/elm-crypto": "<pinned after step 2>"
         },
         "indirect": {}
     },
     "test-dependencies": { "direct": {}, "indirect": {} }
 }

 Note the "source-directories": ["src", "../src"] — the CLI app reads its own
 cli/src/Cli/*.elm and the library tree at ../src/, so it compiles both
 into one elm.js. This is how the CLI consumes the package without a
 round-trip through elm-package publishing.

 cli/src/Cli/Main.elm — Platform.worker

 Flags shape (JSON-decodable, passed in from Node):

 type alias Flags =
     { argv : List String         -- argv after the binary name
     , tenant : String            -- $XSIAM_TENANT_URL
     , apiKeyId : String          -- $XSIAM_API_KEY_ID
     , apiKey : String            -- $XSIAM_API_KEY
     , timestamp : Int            -- Date.now() from node
     , nonce : String             -- crypto.randomBytes(32).toString('hex')
     }

 The CLI uses Client.sendWith so the nonce comes from Node's
 crypto.randomBytes rather than Elm's Math.random-backed PRNG. Model holds
 Config, subscriptions are none, update handles GotResult msgs and emits
 stdout / stderr / exit port commands.

 cli/src/Cli/Ports.elm

 port module Cli.Ports exposing (stdout, stderr, exit)

 port stdout : String -> Cmd msg
 port stderr : String -> Cmd msg
 port exit : Int -> Cmd msg

 cli/src/Cli/Commands.elm

 dispatch : List String -> Result String (Cmd Msg)
 dispatch args =
     case args of
         [ "cli-version" ] ->
             Ok (runRequest GotVersion CliReleases.getVersion)

         _ ->
             Err (usage args)

 Each new sub-API PR adds one pattern-match arm + one GotX Msg constructor +
 one update branch that pretty-prints the result to stdout and exits 0. The
 dispatcher returns Cmd Msg rather than Request _ so each command can
 encode/pretty-print its response type independently.

 Output contract: stdout = pretty-printed JSON, stderr = error string, exit
 code = 0 on success / non-zero on failure. This is the stable interface the
 integration-test shell driver depends on.

 cli/index.js

 #!/usr/bin/env node
 global.XMLHttpRequest = require('xhr2');
 const crypto = require('crypto');
 const { Elm } = require('./dist/elm.js');

 const app = Elm.Cli.Main.init({
     flags: {
         argv: process.argv.slice(2),
         tenant: process.env.XSIAM_TENANT_URL || '',
         apiKeyId: process.env.XSIAM_API_KEY_ID || '',
         apiKey: process.env.XSIAM_API_KEY || '',
         timestamp: Date.now(),
         nonce: crypto.randomBytes(32).toString('hex'),
     },
 });

 app.ports.stdout.subscribe(s => process.stdout.write(s));
 app.ports.stderr.subscribe(s => process.stderr.write(s));
 app.ports.exit.subscribe(code => process.exit(code));

 cli/bin/xsiam

 #!/usr/bin/env sh
 exec node "$(dirname "$0")/../index.js" "$@"

 Build step compiles cli/src/Cli/Main.elm → cli/dist/elm.js.

 ---
 Integration testing

 tests/integration.sh

 #!/usr/bin/env bash
 set -euo pipefail

 : "${XSIAM_TENANT_URL:?set in .envrc}"
 : "${XSIAM_API_KEY:?set in .envrc}"
 : "${XSIAM_API_KEY_ID:?set in .envrc}"

 XSIAM=./cli/bin/xsiam
 PASS=0; FAIL=0

 run() {
     local name="$1"; shift
     if out=$("$XSIAM" "$@" 2>&1); then
         echo "PASS  $name"; PASS=$((PASS+1))
     else
         echo "FAIL  $name -- $out"; FAIL=$((FAIL+1))
     fi
 }

 run "cli/version"   cli-version
 # more rows added as sub-APIs land

 echo "---"; echo "$PASS passed, $FAIL failed"
 [ "$FAIL" -eq 0 ]

 Each new read-only endpoint adds one run line. Write endpoints stay
 commented out by default (license / safety) and TEST.md records why.

 TEST.md shape

 ┌──────────────────────┬───────────────────────────┬─────────────┬────────┬────────────────────────────┐
 │       Sub-API        │         Endpoint          │ CLI command │ Tested │           Notes            │
 ├──────────────────────┼───────────────────────────┼─────────────┼────────┼────────────────────────────┤
 │ Platform.CliReleases │ GET /cli/releases/version │ cli-version │ yes    │ read-only, no license gate │
 ├──────────────────────┼───────────────────────────┼─────────────┼────────┼────────────────────────────┤
 │ Platform.System      │ GET /healthcheck          │ -           │ no     │ requires Premium license   │
 ├──────────────────────┼───────────────────────────┼─────────────┼────────┼────────────────────────────┤
 │ Cwp                  │ GET /cwp/policies         │ -           │ no     │ not yet wired              │
 ├──────────────────────┼───────────────────────────┼─────────────┼────────┼────────────────────────────┤
 │ ...                  │                           │             │        │                            │
 └──────────────────────┴───────────────────────────┴─────────────┴────────┴────────────────────────────┘

 The table is updated in the same PR that adds each sub-API method. Many cells
 will say "no" at first — that is the whole point of tracking coverage.

 ---
 Tooling

 elm.json (root, package)

 {
     "type": "package",
     "name": "<github-user>/elm-cortex-xsiam",
     "summary": "Elm SDK for the Cortex XSIAM Platform REST API",
     "license": "MIT",
     "version": "1.0.0",
     "exposed-modules": [
         "Cortex.Xsiam.Auth",
         "Cortex.Xsiam.Client",
         "Cortex.Xsiam.Error",
         "Cortex.Xsiam.Request",
         "Cortex.Xsiam.Platform.CliReleases"
     ],
     "elm-version": "0.19.0 <= v < 0.20.0",
     "dependencies": {
         "elm/core": "1.0.0 <= v < 2.0.0",
         "elm/http": "2.0.0 <= v < 3.0.0",
         "elm/json": "1.0.0 <= v < 2.0.0",
         "elm/time": "1.0.0 <= v < 2.0.0",
         "elm/random": "1.0.0 <= v < 2.0.0",
         "elm/bytes": "1.0.0 <= v < 2.0.0",
         "ktonon/elm-crypto": "<pinned after step 2>"
     },
     "test-dependencies": {}
 }

 Makefile

 .PHONY: format build test clean

 format:
        elm-format src/ cli/src/ --yes

 build: format
        cd cli && elm make src/Cli/Main.elm --optimize --output=dist/elm.js

 test: build
        ./tests/integration.sh

 clean:
        rm -rf elm-stuff cli/elm-stuff cli/dist

 package.json

 {
     "name": "elm-cortex-xsiam-cli",
     "private": true,
     "bin": { "xsiam": "./cli/bin/xsiam" },
     "devDependencies": { "xhr2": "^0.2.1" },
     "scripts": {
         "build": "make build",
         "format": "make format",
         "test": "make test"
     }
 }

 .gitignore (append)

 elm-stuff/
 node_modules/
 cli/dist/
 .envrc

 .envrc.example

 export XSIAM_TENANT_URL="https://api-<tenant>.xdr.<region>.paloaltonetworks.com"
 export XSIAM_API_KEY_ID="<your key id>"
 export XSIAM_API_KEY="<your advanced api key>"

 The user already has working credentials; they go in a local .envrc
 (gitignored). direnv or manual source .envrc both work.

 ---
 Implementation order

 1. Repo skeleton: root elm.json (package), empty src/Cortex/Xsiam/,
 package.json, Makefile, .gitignore append, .envrc.example,
 README.md stub, TEST.md skeleton. elm-format installed.
 2. Pin SHA-256 package: elm install ktonon/elm-crypto from a throwaway
 elm.json to confirm availability and pinned version; record in root
 elm.json and cli/elm.json. If unavailable, fall back to
 prozacchiwawa/elm-sha.
 3. Library foundation:
   - Cortex.Xsiam.Error
   - Cortex.Xsiam.Request (opaque type + builders + toInternal)
   - Cortex.Xsiam.Auth (SHA-256 signing + nonce generator — hand-verify hash
 against a Python hashlib test vector)
   - Cortex.Xsiam.Client (Config, send, sendWith, toRequestRecord,
 XSIAM error-envelope parsing)
   - elm make clean from the library root.
 4. First sub-API: Cortex.Xsiam.Platform.CliReleases with getVersion,
 decoder for VersionObj (one string field).
 5. CLI scaffold:
   - cli/elm.json with source-directories: ["src", "../src"].
   - Cli.Ports, Cli.Main, Cli.Commands with one route (cli-version).
   - cli/index.js with xhr2 polyfill + crypto nonce.
   - cli/bin/xsiam launcher (chmod +x).
   - make build produces a working binary at cli/dist/elm.js.
 6. Smoke test against real tenant: ./cli/bin/xsiam cli-version returns
 {"version":"v..."} and exit 0. This validates auth, transport, decoder,
 and CLI plumbing end-to-end.
 7. Test harness: tests/integration.sh with the one passing assertion;
 make test green. Update TEST.md.
 8. Format pass: make format (zero diff); first commit.
 9. Iterate: each new sub-API method is a one-file PR that adds:
   - one function (or several) in the sub-API Elm module
   - one dispatch arm in cli/src/Cli/Commands.elm + one Msg
   - one line in tests/integration.sh (if read-only)
   - one row in TEST.md
 No foundation churn.

 ---
 Verification

 End-to-end smoke test once steps 1–7 land:

 make format          # zero diff
 make build           # compiles cli/dist/elm.js
 source .envrc        # local secrets, never committed
 ./cli/bin/xsiam cli-version   # → {"version":"v..."} to stdout, exit 0
 make test            # tests/integration.sh green

 Failure modes to watch during the smoke test:

 - 401 / 403 → signing wrong. Debug path: print the hash input and output
 from Elm, hand-compute hashlib.sha256((key+nonce+str(ts)).encode()).hexdigest()
 in Python, compare. Watch for: timestamp unit (must be millis, not seconds);
 hash as hex, not base64; header name casing; whether tenant URL has
 trailing slash (strip it).
 - BadBody → response shape differs from spec. Tighten decoder; check for
 the {"reply": ...} envelope some platform endpoints use (the version
 endpoint does not — it's bare — but many others do).
 - XMLHttpRequest is not defined → xhr2 polyfill must run before
 require('./dist/elm.js'). Order matters in cli/index.js.
 - Empty argv → process.argv.slice(2) drops node + script path. OK for
 the xsiam shim because it execs into node with the script as argv[1].
 - ktonon/elm-crypto not installable → fall back to prozacchiwawa/elm-sha
 and update the dependency block.

 ---
 Critical files (to read / create during implementation)

 - docs/cortex-api-openapi/cortex-platform-papi.json — source of truth for
 the bootstrap endpoint (/public_api/v1/cli/releases/version,
 VersionObj schema). Read during step 4.
 - docs/cortex-api-openapi/*.json / *.yaml — per-sub-API source of truth.
 Read one at a time during step 9 iterations.
 - docs/guide.elm-lang.org/ — Elm guidance; the relevant rules are
 "ports are for applications, not packages" and "use Task.perform for
 Time + Random chains".
 - src/Cortex/Xsiam/Auth.elm — signing correctness is the linchpin; the
 entire SDK is gated on this hash being computed the same way Cortex's
 gateway validates it.
 - src/Cortex/Xsiam/Client.elm — only module that touches Time/Random/Http.
 - cli/index.js — xhr2 polyfill MUST come before require('./dist/elm.js').
 - tests/integration.sh — coverage grows here; keep it shell-readable.
 - TEST.md — kept in sync per PR.
 - temp-plan.md — can be deleted once this plan lands in its first commit.

 ---
 Out of scope for bootstrap

 The following are deliberately deferred until after the v1 smoke test is green:

 - Any sub-API beyond CliReleases.getVersion.
 - Write endpoints (POST/PUT/DELETE) — license/safety concerns; enable per-method.
 - Pagination helpers — revisit once we hit the first paginated endpoint.
 - Handling non-JSON response types (none observed in Phase-1 scan).
 - Browser-specific demo app. The library is usable by any Elm app as soon as
 it's published; a demo is a separate deliverable.
 - Publishing to the Elm package registry. First iteration stays local.
 - CI. Integration tests hit a live tenant; CI would need tenant creds or a
 mock — out of scope for bootstrap.
