#!/usr/bin/env node

/**
 * Refresh the auto-generated coverage tables in TODO.md from the OpenAPI
 * specs in docs/cortex-api-openapi/ and the current state of src/Cortex/Api/.
 *
 * Manual prose is preserved. Per-spec tables and the progress counter at the
 * top are regenerated between marker comments.
 *
 * Usage:
 *   node .claude/skills/todo-from-openapi/sync.mjs           # write
 *   node .claude/skills/todo-from-openapi/sync.mjs --check   # exit 1 on drift
 */

import { readFileSync, writeFileSync, readdirSync } from "node:fs";
import { join, basename } from "node:path";
import { parse as parseYaml } from "yaml";

const REPO = new URL("../../../", import.meta.url).pathname;
const SPECS_DIR = join(REPO, "docs/cortex-api-openapi");
const SDK_API_DIR = join(REPO, "src/Cortex/Api");
const TODO_PATH = join(REPO, "TODO.md");

// Spec files explicitly skipped per TODO.md preamble
const SKIP_SPECS = new Set([
  "cloud-onboarding-papi.json",
  "appsec-papi (1).json",
]);

const PROGRESS_BEGIN = "<!-- BEGIN AUTO: progress -->";
const PROGRESS_END = "<!-- END AUTO -->";
const sectionBegin = (spec) => `<!-- BEGIN AUTO: ${spec} -->`;
const SECTION_END = "<!-- END AUTO -->";

const TABLE_HEADER =
  "| ✓ | Method | Path | Description | Type | Elm | CLI | Test | Asserts |\n" +
  "| --- | --- | --- | --- | --- | --- | --- | --- | --- |";

// ---------------------------------------------------------------- spec parse

function loadSpec(file) {
  const path = join(SPECS_DIR, file);
  const raw = readFileSync(path, "utf8");
  return file.endsWith(".yaml") ? parseYaml(raw) : JSON.parse(raw);
}

// Heuristic: GET is always View; for POST we look at both the path shape
// (read-flavored prefixes) and the summary verb. Anything that says
// "get/list/search/retrieve/find/return" reads, anything that says
// "create/add/delete/update/set/insert/upsert/trigger/run/edit/remove" writes.
const READ_LIKE_PATH =
  /\/(get_|list|search|status|quota|metadata|fetch|read|management_logs|agents_reports)/;
const READ_VERB = /^(get |list |search |retrieve |find |return |fetch )/i;
const WRITE_VERB = /^(create |add |delete |update |set |insert |upsert |trigger |run |edit |remove |allow |block |quarantine |restore |isolate )/i;

function classify(method, path, summary) {
  if (method === "get") return "View";
  if (method === "post") {
    if (WRITE_VERB.test(summary)) return "Edit";
    if (READ_VERB.test(summary)) return "View";
    if (READ_LIKE_PATH.test(path)) return "View";
  }
  return "Edit";
}

function specEndpoints(spec) {
  const out = [];
  const paths = spec.paths ?? {};
  for (const [path, ops] of Object.entries(paths)) {
    for (const [method, op] of Object.entries(ops)) {
      if (!["get", "post", "put", "delete", "patch"].includes(method)) continue;
      const summary = (op.summary ?? op.operationId ?? "").trim();
      out.push({
        method: method.toUpperCase(),
        path,
        summary,
        type: classify(method, path, summary),
      });
    }
  }
  return out;
}

// --------------------------------------------------------- elm scan (SDK)

// Match `Request.get`/`Request.post`/`Request.postEmpty`/etc. followed by a
// single-line list of segments. Captures the helper name and the bracket
// contents. `postEmpty` and any future `*Empty` variant are normalized to
// their base HTTP verb. Segments may be string literals or Elm expressions
// (variables, function applications) for path parameters; the latter are
// normalized to `{*}` so they line up with OpenAPI parameter slots.
const ELM_ENDPOINT =
  /Request\.(getEmpty|postEmpty|putEmpty|deleteEmpty|get|post|put|delete|patch)\s*\n\s*\[\s*([^\]\n]+?)\s*\]/g;

function helperToMethod(helper) {
  return helper.replace(/Empty$/, "").toUpperCase();
}

function parseSegment(raw) {
  const literal = raw.match(/^"([^"]+)"$/);
  return literal ? literal[1] : "{*}";
}

function normalizeSpecPath(path) {
  return path.replace(/\{[^/}]+\}/g, "{*}");
}

function elmEndpoints() {
  const map = new Map(); // key = "METHOD /path"  →  module name
  for (const file of readdirSync(SDK_API_DIR)) {
    if (!file.endsWith(".elm")) continue;
    const moduleName = "Cortex.Api." + file.replace(/\.elm$/, "");
    const src = readFileSync(join(SDK_API_DIR, file), "utf8");
    for (const m of src.matchAll(ELM_ENDPOINT)) {
      const method = helperToMethod(m[1]);
      const segments = m[2].split(",").map((s) => parseSegment(s.trim()));
      const path = "/" + segments.join("/");
      map.set(`${method} ${path}`, moduleName);
    }
  }
  return map;
}

// ----------------------------------------------- preserve manual columns

// Parse current TODO.md tables. Keyed by `METHOD /path`, value = the row's
// hand-curated columns we want to preserve: description annotations like
// "(tenant-unsupported)", and the CLI / Test / Asserts trio.
function existingManualColumns(todoText) {
  const map = new Map();
  const ROW =
    /^\|\s*[✓]?\s*\|\s*([A-Z]+)\s*\|\s*`([^`]+)`\s*\|\s*([^|]*?)\s*\|\s*[^|]*\|\s*[^|]*\|\s*([^|]*?)\s*\|\s*([^|]*?)\s*\|\s*([^|]*?)\s*\|/gm;
  for (const m of todoText.matchAll(ROW)) {
    const [, method, path, description, cli, test, asserts] = m;
    map.set(`${method} ${path}`, {
      description: description.trim(),
      cli: cli.trim(),
      test: test.trim(),
      asserts: asserts.trim(),
    });
  }
  return map;
}

// Extract a trailing parenthesized annotation like " (tenant-unsupported)" if
// the manual description has one and the spec summary does not — these are
// hand-curated notes worth preserving.
function annotationSuffix(specSummary, manualDescription) {
  if (!manualDescription) return "";
  const m = manualDescription.match(/(\s*\([^)]+\))$/);
  if (!m) return "";
  if (specSummary.endsWith(m[1])) return "";
  return m[1];
}

// --------------------------------------------------------- table render

function renderRow(ep, elm, manual) {
  const implemented = elm ? "✓" : "";
  const elmCol = elm ? "`" + elm + "`" : "";
  const cli = manual?.cli ?? "";
  const test = manual?.test ?? "";
  const asserts = manual?.asserts ?? "";
  const description = ep.summary + annotationSuffix(ep.summary, manual?.description);
  return `| ${implemented} | ${ep.method} | \`${ep.path}\` | ${description} | ${ep.type} | ${elmCol} | ${cli} | ${test} | ${asserts} |`;
}

function renderTable(endpoints, elmMap, manual) {
  const lines = [TABLE_HEADER];
  for (const ep of endpoints) {
    const elm = elmMap.get(`${ep.method} ${normalizeSpecPath(ep.path)}`);
    lines.push(renderRow(ep, elm, manual.get(`${ep.method} ${ep.path}`)));
  }
  return lines.join("\n");
}

// --------------------------------------------------- TODO.md replacement

function replaceBetween(text, beginMarker, endMarker, content) {
  const begin = text.indexOf(beginMarker);
  const end = text.indexOf(endMarker, begin >= 0 ? begin : 0);
  if (begin < 0 || end < 0) {
    throw new Error(
      `Missing markers in TODO.md: ${beginMarker} … ${endMarker}. Run sync once with --add-markers first.`,
    );
  }
  return (
    text.slice(0, begin + beginMarker.length) +
    "\n" +
    content +
    "\n" +
    text.slice(end)
  );
}

// ------------------------------------------------------------------ main

function main() {
  const args = new Set(process.argv.slice(2));
  const checkMode = args.has("--check");

  const elmMap = elmEndpoints();
  const todoBefore = readFileSync(TODO_PATH, "utf8");
  const manual = existingManualColumns(todoBefore);

  const specFiles = readdirSync(SPECS_DIR)
    .filter((f) => f.endsWith(".json") || f.endsWith(".yaml"))
    .filter((f) => !SKIP_SPECS.has(f))
    .sort();

  let totalEndpoints = 0;
  let totalImplemented = 0;
  let totalView = 0;
  let totalEdit = 0;
  let todoAfter = todoBefore;

  for (const file of specFiles) {
    let spec;
    try {
      spec = loadSpec(file);
    } catch (e) {
      console.error(`! ${file}: parse failed (${e.message}) — skipped`);
      continue;
    }
    const eps = specEndpoints(spec);
    totalEndpoints += eps.length;
    for (const ep of eps) {
      if (elmMap.has(`${ep.method} ${normalizeSpecPath(ep.path)}`))
        totalImplemented++;
      if (ep.type === "View") totalView++;
      else totalEdit++;
    }
    const begin = sectionBegin(file);
    if (todoAfter.includes(begin)) {
      todoAfter = replaceBetween(
        todoAfter,
        begin,
        SECTION_END,
        renderTable(eps, elmMap, manual),
      );
    }
  }

  const progressLine =
    `**Progress:** ${totalImplemented}/${totalEndpoints} endpoints implemented | ` +
    `${totalView} View | ${totalEdit} Edit`;
  if (todoAfter.includes(PROGRESS_BEGIN)) {
    todoAfter = replaceBetween(
      todoAfter,
      PROGRESS_BEGIN,
      PROGRESS_END,
      progressLine,
    );
  }

  if (checkMode) {
    if (todoBefore !== todoAfter) {
      console.error(
        "TODO.md is out of date. Run `node .claude/skills/todo-from-openapi/sync.mjs` to refresh.",
      );
      process.exit(1);
    }
    console.log("TODO.md is in sync.");
    return;
  }

  if (todoBefore === todoAfter) {
    console.log("TODO.md unchanged.");
    return;
  }
  writeFileSync(TODO_PATH, todoAfter);
  console.log(
    `TODO.md updated: ${totalImplemented}/${totalEndpoints} implemented (${totalView} View, ${totalEdit} Edit)`,
  );
}

main();
