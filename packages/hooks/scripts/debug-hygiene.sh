#!/usr/bin/env bash
# debug-hygiene.sh — PostToolUse(Write|Edit) advisory hook. Code-hygiene counter.
#
# Flags leftover debug artifacts (console.log/debug, debugger, breakpoint, pdb/pry) in a
# just-written file. PostToolUse cannot block by design, so this is inherently advisory:
# writes to stderr, exits 0. Quiet — emits NOTHING unless a pattern is found. Self-contained.
set -uo pipefail

[[ -n "${CLAUDE_SUBAGENT:-}" ]] && exit 0

payload="$(cat 2>/dev/null || true)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[[ -z "$file" || ! -f "$file" ]] && exit 0

# Deterministic, high-signal debug-artifact patterns (not TODO/FIXME — too noisy to be useful).
hits="$(grep -nEi 'console\.(log|debug)\(|^\s*debugger;?\s*$|[^a-zA-Z_]breakpoint\(\)|pdb\.set_trace\(|binding\.pry|[^a-zA-Z_]print\("?DEBUG' "$file" 2>/dev/null | head -5 || true)"

if [[ -n "$hits" ]]; then
  {
    echo "[vis · debug-hygiene] possible leftover debug artifacts in $(basename "$file"):"
    echo "$hits"
    echo "Remove debug output before finishing, or confirm it's intentional."
  } >&2
fi

exit 0
