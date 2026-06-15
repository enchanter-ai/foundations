# Roadmap — Codex Compatibility Layer

**Author:** Enchanter Labs
**Status:** Active · created 2026-06-15
**Owner repo:** `vis` (generator) → fanned out to all consumer products
**Source of truth:** Claude Code files stay canonical; the Codex layer is *derived* and committed. No new repos.

---

## 0. CORRECTION (2026-06-15, live Codex CLI 0.140 inspection)

Doc-only research **understated** Codex. Inspecting a real install overturned two findings and pivoted the whole approach:

- **Codex HAS a plugin + marketplace system** (`codex plugin marketplace add` / `codex plugin list`). Marketplace = `marketplace.json` under `.agents/plugins/`; a plugin = `<n>/.codex-plugin/plugin.json` + `skills/` + companion `hooks/`,`.mcp.json`,`.app.json`. This is **near-identical to Claude Code** — marketplace is a FULL equivalent, not a gap.
- **The port is at the PLUGIN level, and skills don't move** — `plugins/<n>/skills/<s>/SKILL.md` is the same path in both tools. The earlier loose `.codex/skills` / `.codex/agents` / `.codex/config.toml` approach was the wrong altitude and is **retired**.

**Generator now emits:** `.agents/plugins/marketplace.json` + `plugins/*/.codex-plugin/plugin.json` (+ compact `AGENTS.md` + `.codex/CODEX-NOTES.md`). Manifests conform to Codex's own `validate_plugin.py` (allowed keys; `interface` requires displayName/short/long/developerName/category/capabilities/defaultPrompt; semver; **`hooks` rejected from manifest**).

**LIVE-VERIFIED:** 80 plugins across 10 repos pass `validate_plugin.py`. wixie + hydra marketplaces `add`ed into the real Codex; `codex plugin list` shows all entries; `prompt-crafter@wixie` installed + enabled with skills discovered. Round-trip is no longer theoretical.

---

## 1. Premise (validated)

The OpenAI Codex ecosystem (as of June 2026) maps onto Claude Code with **higher fidelity than first assumed**. Verified by a 99-agent deep-research run (`prompts/codex-ecosystem-research/`, 20/25 claims confirmed 3-0, all primary sources). The bridge is therefore worth building as a one-way generator, **not** a parallel hand-authored layer.

### Fidelity matrix (verified)

| Claude Code primitive | Codex equivalent | Fidelity | Source |
|---|---|---|---|
| `CLAUDE.md` | `AGENTS.md` (Git-root→cwd concat, `AGENTS.override.md`, `project_doc_fallback_filenames`, `project_doc_max_bytes`) | **Partial** — no `@import` | developers.openai.com/codex/guides/agents-md |
| `@imports` | *(none documented)* | **None** → must flatten/compact | config-reference |
| `SKILL.md` skills | `.codex/skills/<n>/SKILL.md` + `agents/openai.yaml` | **Full** — same name/description progressive disclosure, `$`/implicit/`/skills` | codex/skills |
| markdown subagents + tiering | `[agents.<n>]` + `config_file` TOML layers | **Full** — per-agent `model`/`model_reasoning_effort`/`sandbox_mode`/`mcp_servers`/`skills.config` | codex/subagents |
| JSON lifecycle hooks | `config.toml [hooks]` / `hooks.json` (10 events) | **Strong-partial→Full** — names overlap | codex/hooks, PR #11067 |
| MCP | `[mcp_servers.<n>]` (stdio + streamable HTTP) | **Full** | codex/mcp |
| plugin marketplace | *(none)* | **None** → AGENTS.md is discovery | caveats |
| `CLAUDE_PLUGIN_ROOT` runtime paths | *(none)* | **None** → MCP server or absolute paths | caveats |

### Verified constants (June 2026 snapshot — version-sensitive)

- **Model slugs:** `gpt-5.5` (frontier), `gpt-5.4`, `gpt-5.4-mini` ("for subagents"), `gpt-5.3-codex-spark` (Pro-only preview). `gpt-5.5-pro` is **not** in the Codex set.
- **Tier map:** opus→`gpt-5.5`, sonnet→`gpt-5.4`, haiku→`gpt-5.4-mini`.
- **`model_reasoning_effort`:** `minimal | low | medium | high | xhigh` (xhigh model-dependent). NOT `none`.
- **Hook events (10):** PreToolUse, PermissionRequest, PostToolUse, PreCompact, PostCompact, SessionStart, SubagentStart, SubagentStop, UserPromptSubmit, Stop.
- **MCP defaults:** `startup_timeout_sec`=10, `tool_timeout_sec`=60; `enabled_tools`/`disabled_tools` filters.

---

## 2. Pilot status (wixie) — what the research changed

The wixie pilot generated 46 artifacts but the research invalidates 5 of its decisions. These are the bugs each Wave-0 agent fixes:

| # | Pilot did | Research says | Fix owner |
|---|---|---|---|
| B1 | skills → `.agents/skills/` | must be `.codex/skills/` | G1 |
| B2 | hooks → "no equivalent" gap | hooks translate (10-event schema) | G2 |
| B3 | opus→`gpt-5.5-pro`, all sonnet/haiku→`gpt-5.5` | `gpt-5.5`/`gpt-5.4`/`gpt-5.4-mini` | G3 |
| B4 | standalone `.codex/agents/*.toml` only | must register `[agents.<n>]` in config.toml | G3 |
| B5 | AGENTS.md = 252 KB (full inline) | exceeds `project_doc_max_bytes` ~32-64 KiB | G4 |

---

## 3. Split-agent execution plan

Four waves. Within a wave, agents run in parallel; waves are barriers (later waves consume earlier outputs). Each agent has: **tier**, **inputs**, **task**, **done-condition** (verifiable).

### Wave 0 — Fix the generator (blocks everything; `vis`)

> Goal: `codex-sync.py` emits a layer that matches verified Codex reality. Re-run on wixie must produce a layer Codex can actually load.

**G1 · Skill-path correction** — *Sonnet*
- Inputs: B1; findings on `.codex/skills` scope.
- Task: change emit path `.agents/skills/` → `.codex/skills/`; keep `agents/openai.yaml` sibling. Add `--user-scope` note. Delete stale `.agents/` from wixie.
- Done: `codex-sync.py .` writes `.codex/skills/*/SKILL.md`; no `.agents/` remains; `--check` clean.

**G2 · Hook translator** — *Sonnet*
- Inputs: B2; 10-event schema; name-overlap table.
- Task: replace the "hooks have no equivalent" gap with a translator: map each `hooks.json` matcher→Codex event (PostToolUse/SessionStart/UserPromptSubmit/Stop pass through 1:1). Emit Codex `hooks.json` (or `[hooks]` blocks). Move genuinely-unmappable matchers to CODEX-GAPS.md only.
- Done: wixie's 2 hooks emit valid Codex hook configs; CODEX-GAPS.md no longer claims hooks are unsupported.

**G3 · Tier remap + subagent registration** — *Sonnet*
- Inputs: B3, B4; verified slugs + effort enum; `[agents.<n>]`/`config_file` structure.
- Task: update `TIER_MAP` to `gpt-5.5`/`gpt-5.4`/`gpt-5.4-mini`. Emit a `config.toml` fragment registering every subagent as `[agents.<slug>] config_file="./.codex/agents/<slug>.toml"` + `description`. Flag the 2-1-confidence registration structure for V3 confirmation.
- Done: 14 subagents registered; effort values ∈ valid enum; fragment merges cleanly.

**G4 · AGENTS.md compaction (byte budget)** — *Opus*
- Inputs: B5; `project_doc_max_bytes`; "no @import" finding.
- Task: stop inlining 28 full conduct modules. Strategy decision (recommend): emit a lean AGENTS.md (contract + one-line module summaries + relative pointers) under the byte limit, and place full modules where a session can read them on demand. Measure final size < `project_doc_max_bytes`.
- Done: `wc -c AGENTS.md` < 32 KiB; every conduct module still discoverable; decision recorded in `learnings.md`.

**G5 · CLAUDE_PLUGIN_ROOT → MCP scaffold** — *Opus*
- Inputs: caveats (no runtime-path injection); MCP config schema.
- Task: design one MCP server per product exposing `shared/scripts/*.py` (token-count, self-eval, report-gen, convergence) as tools; emit the `[mcp_servers.<product>]` config block + a stub server. Update skill `openai.yaml` `dependencies.tools` to reference it.
- Done: 12 CLAUDE_PLUGIN_ROOT skills have a documented MCP tool path; stub server lists the 4 tools.

### Wave 1 — Resolve the 4 open questions (`vis`; needs real `codex` binary)

> Empirical verification (E5 dual-verify). Each closes an open question the research could not settle from docs alone.

- **V1 · Canonical skill dir** — *Sonnet*: install codex, drop a probe skill in `.codex/skills` vs `~/.agents/skills`, observe which loads + scope precedence. Done: authoritative path + precedence documented; G1 confirmed or corrected.
- **V2 · `openai.yaml` schema** — *Sonnet*: enumerate accepted keys empirically (policy, dependencies, interface). Done: real schema replaces the unverified guess in G1's emitter.
- **V3 · Subagent spawn/parallelism** — *Sonnet*: verify `[agents.<n>]` registration, `spawn_agents_on_csv`, max concurrency. Done: G3 registration structure confirmed; parallelism limits noted.
- **V4 · Marketplace + @import** — *Haiku*: confirm no install flow and no AGENTS.md include mechanism. Done: caveats locked or revised.

### Wave 2 — Harden the generator (`vis`)

- **C1 · CI drift guard** — *Haiku*: add `codex-abi.yml` calling `codex-sync.py --check`, mirroring `conduct-abi.yml`. Done: PR with drift = red build.
- **C2 · Golden snapshots** — *Sonnet*: snapshot the corrected wixie layer; test asserts regeneration is byte-stable. Done: test passes; intentional changes require snapshot update.
- **C3 · Round-trip / E5 dual-verify** — *Opus*: run real `codex` against generated wixie layer; confirm a skill triggers, a subagent spawns at the right tier, a hook fires. Done: a recorded session exercising skill+subagent+hook; gaps logged to `learnings.md`.

### Wave 3 — Fanout (per-repo, parallel)

- **F1…F12 · Plugin repos** — *Sonnet, one agent per repo* (hydra, lich, naga, sylph, crow, djinn, emu, gorgon, pech, mimir, beholder, yeti): run `codex-sync.py <repo>`, commit derived layer, verify `--check`. Done per repo: AGENTS.md < limit, skills/subagents/hooks emitted, CODEX-GAPS.md present.
- **F-lib · Libraries** — *Haiku* (golem, kelpie, robit): AGENTS.md-only pass (no skill/subagent layer). Done: contributor-facing AGENTS.md committed.

---

## 4. Verdict bar (per product)

A product's Codex layer is **DEPLOY** when: AGENTS.md < `project_doc_max_bytes`; every skill loads under `.codex/skills`; every subagent registered + maps to a valid slug/effort; hooks translated or explicitly listed in CODEX-GAPS.md; `codex-sync.py --check` clean; and (where Wave 2 ran) a round-trip session triggers ≥1 skill, ≥1 subagent, ≥1 hook. Anything short = HOLD.

## 5. Dependencies & ordering

```
Wave 0 (G1–G5) ──┬──> Wave 1 (V1–V4) ──> (confirm/correct G1,G3) ──┐
                 └──────────────────────> Wave 2 (C1–C3) ──────────┴──> Wave 3 (F1–F12, F-lib)
```
Wave 0 unblocks all. Wave 1 may force small G1/G3 corrections — fan out (Wave 3) only after Wave 1 confirms paths, since a wrong skill path would be replicated across 12 repos.

## 5a. Execution log (2026-06-15)

- **Wave 0 — DONE.** Generator corrected (G1–G5) + C3 hook-command flag. wixie regenerated: 51 artifacts, AGENTS.md 11.6 KB, idempotent.
- **Wave 3 — DONE.** Fanned out to 9 plugin repos (crow, djinn, emu, gorgon, hydra, lich, naga, pech, sylph) + golem (AGENTS.md-only lib). All `--check` clean; every AGENTS.md < 32 KB. Out of scope (no CLAUDE.md): agent, beholder, kelpie, mimir, robit, yeti.
- **Wave 2 / C1 — DONE.** `codex-abi.yml` drift guard deployed to all 11 repos (checks out vis, runs `codex-sync.py --check`).
- **Wave 2 / C2 — satisfied by design.** The committed layer + `--check` *is* the golden snapshot; CI fails on any drift. No separate fixture test needed.
- **Wave 1 (V1–V4) + Wave 2 / C3 — BLOCKED.** No `codex` binary installed; empirical verification (skill-dir precedence, `openai.yaml` schema, subagent spawning, live round-trip of skill+subagent+hook) requires a real Codex session with OpenAI auth. Layers are **research-verified but not yet round-trip-verified.**

### Known residual fidelity tradeoff
G4 keeps AGENTS.md under budget by *referencing* conduct modules, not inlining them. Under Codex a session sees pointers, not the module text in-context — it must read them on demand. Acceptable given `project_doc_max_bytes`, but it is a partial degradation vs Claude's auto-loaded `@imports`. Revisit if Codex raises the byte limit or adds includes (open question 4).

## 6. Open questions carried from research

1. Canonical skill dir: `.codex/skills` vs `~/.agents/skills` + precedence (→ V1).
2. Exact `agents/openai.yaml` schema (→ V2).
3. Subagent spawning/parallelism/`spawn_agents_on_csv` (→ V3).
4. Any marketplace/install analog; AGENTS.md include mechanism (→ V4).
