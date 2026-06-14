#!/usr/bin/env bash
# append-only-log-edit-guard.sh — PreToolUse(Edit|MultiEdit) advisory. Counter to F14 (append-only ledger).
#
# Warns when an in-place Edit targets an append-only ledger (*.jsonl / *.ndjson, or a named
# artifacts/metrics/ledger/audit log). Such files take a NEW appended row — rewriting a prior row in
# place corrupts their history. Advisory: stderr + exit 0. Quiet unless the path matches. Self-contained.
set -uo pipefail

[[ -n "${CLAUDE_SUBAGENT:-}" ]] && exit 0

payload="$(cat 2>/dev/null || true)"
tool="$(printf '%s' "$payload" | jq -r '.tool_name // empty' 2>/dev/null || true)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[[ -z "$file" ]] && exit 0
case "$tool" in Edit|MultiEdit) ;; *) exit 0 ;; esac

if printf '%s' "$file" | grep -Eq '\.(jsonl|ndjson)$|(artifacts|metrics|ledger|audit)\.jsonl$'; then
  {
    echo "[vis F14 · append-only] $(basename "$file") looks like an append-only ledger."
    echo "An in-place Edit rewrites a prior row — append a NEW row instead, or you corrupt the ledger's history."
  } >&2
fi

exit 0
