# enchanter-hooks

vis-governed **advisory** Claude Code hooks — deterministic, fail-open enforcement of the
conduct substrate at lifecycle events that in-context conduct **cannot self-time**.

Distributed the native way: `enchanter-hooks` is a Claude Code plugin in the `vis` marketplace.
Installing it activates the hooks automatically — no `settings.json` editing.

```
/plugin marketplace add enchanter-ai/vis
/plugin install enchanter-hooks@vis
```

## Design contract

Every hook here obeys five rules (the "smart-test" — a hook that fails any is rejected, not shipped):

1. **Deterministic trigger** — fires on an unambiguous event (tool call / lifecycle), never fuzzy intent.
2. **Does what conduct can't** — earns its place by acting where in-context conduct structurally can't, or reliably misses.
3. **Advisory / fail-open** — injects or warns, **never blocks**; every script exits 0 (and on a malformed payload, does nothing).
4. **Not redundant** — doesn't re-implement Claude Code's built-in permission gating (or, where it complements it, adds a stated delta).
5. **Quiet** — emits *nothing* unless it has something to say, so it never becomes ignored wallpaper.

## Hooks (v0.6 — 11)

| Hook | Event | F-code | What it does |
|---|---|---|---|
| `compact-checkpoint` | `SessionStart(compact)` | F03 | Re-injects a goal/state/invariants checkpoint right after a compaction (the one moment the model can't self-time). |
| `secret-scan` | `PreToolUse(Write\|Edit)` | secret-exfil | Scans content about to be written for high-signal secret patterns; warns. |
| `config-self-edit-guard` | `PreToolUse(Write\|Edit)` | self-modification | Warns on edits to the agent's own startup/hook/plugin config (`.claude/settings.json`, `hooks.json`, `.claude-plugin/`, `.mcp.json`). |
| `substrate-engine-write-guard` | `PreToolUse(Write\|Edit)` | F24 | Warns on hand-writes to inference-engine state (`catalog.json`/`artifacts.jsonl`/briefings/`.lock`) — must go through the engine. |
| `artifact-authorship-guard` | `PreToolUse(Write\|Edit)` | authorship | Warns when a public artifact (LICENSE/`.cff`/README/`.bib`) has author lines that don't credit "Enchanter Labs". Generic — no hardcoded names. |
| `append-only-log-edit-guard` | `PreToolUse(Edit\|MultiEdit)` | F14 | Warns on an in-place Edit of an append-only ledger (`.jsonl`/`.ndjson`) — append a row instead. |
| `reversibility-guard` | `PreToolUse(Bash)` | F26 | Advisory caution on hard-to-reverse commands (`rm -rf`, force-push, `--hard`, `mkfs`, `curl\|sh`, `DROP TABLE`). |
| `debug-hygiene` | `PostToolUse(Write\|Edit)` | code-hygiene | Flags leftover debug artifacts (`console.log`/`debug`, `debugger`, `breakpoint()`, `pdb`/`pry`). |
| `post-write-validate` | `PostToolUse(Write\|Edit)` | F02/F14 | Fast-parses the written file (`.py`/`.json`/`.sh`/`.toml`) and warns on a syntax error, same turn. |
| `stale-pathref-guard` | `PostToolUse(Write\|Edit)` | F02/F27 | After writing a `.md`, checks its `@-imports` / local links actually resolve — the silent CLAUDE.md breakage. |
| `machine-path-leak-guard` | `PostToolUse(Write\|Edit)` | F02 | Warns when a git-tracked file gains machine-absolute paths (`C:\git`, `/Users/<n>/`) — use repo-relative form. |

Built in two passes: the first 6 from an open-web survey of agent-hook patterns; the last 5 from a
per-package mining sweep of the vis conduct substrate (each candidate gate-tested, deduped, and
verified against live repo evidence — e.g. `stale-pathref` against real `@-imports`, `authorship`
against a live `CITATION.cff` slip).

## Deferred (considered, did not clear the bar — or need a convention first)

- `claude-format-to-nonclaude-target`, `scratch-in-prompts-folder-guard` — wixie-`prompts/`-specific, not general vis; belong in a wixie-local hook set.
- `mcp-manifest-gate` — would warn on *every* MCP call until an `mcp-manifests/*.fingerprint.json` convention exists → wallpaper today. Revisit when that convention lands.
- `finish-checklist` (Stop), `substrate-injection` / `build-premise` (UserPromptSubmit) — fire every turn or rely on fuzzy intent. `build-premise` is superseded by the F29 *conduct* gate in `doubt-engine.md`.
- `backup-before-compact` — low value (transcripts are usually recoverable) + project-side file writes.
- egress-fence, write-scope-audit, subagent-spawn/budget counters, `learnings.md`/`SKILL.md` schema lints — failed "quiet" in practice, or cited contract files that don't exist in this codebase.

## Notes

- Scripts are **self-contained** (no references outside the plugin root) so they survive the
  plugin cache (`~/.claude/plugins/cache/`). Require `jq` + `bash`; `python3`/`python` for the
  syntax validators (fail-open if absent).
- `config-self-edit-guard`, `reversibility-guard`, and `substrate-engine-write-guard` are advisory
  **complements** to permission gating, not replacements — the delta is the self-config/substrate
  category and the reversibility framing.
- The `vis-drift` SessionStart hook is **not** shipped here — it is project-local (reads the
  consuming repo's `.vis-lock` against a sibling `../vis` checkout), which is not plugin-portable.
