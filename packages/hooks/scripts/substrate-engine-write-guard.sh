#!/usr/bin/env bash
# substrate-engine-write-guard.sh — PreToolUse(Write|Edit) advisory. Counter to F24 / substrate contract.
#
# Warns on a direct write to inference-engine-owned state (catalog.json, artifacts.jsonl, a briefing,
# or the .lock). Those must be mutated only through inference-engine.py (emit / reconcile /
# render-briefing) — hand edits break the honest-numbers contract (atomic writes, fingerprints, SPRT).
# Advisory: stderr + exit 0. Quiet unless the path matches. Self-contained.
set -uo pipefail

[[ -n "${CLAUDE_SUBAGENT:-}" ]] && exit 0

payload="$(cat 2>/dev/null || true)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[[ -z "$file" ]] && exit 0

if printf '%s' "$file" | grep -Eq '/inference-engine/state/(catalog\.json|artifacts\.jsonl|\.lock)$|/inference-engine/state/briefings/.*\.md$'; then
  {
    echo "[vis F24 · substrate] $file is inference-engine-owned state."
    echo "Do NOT hand-edit it — route through inference-engine.py (emit / reconcile / render-briefing). Direct writes break the honest-numbers contract."
  } >&2
fi

exit 0
