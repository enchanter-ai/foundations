#!/usr/bin/env bash
# secret-scan.sh — PreToolUse(Write|Edit) advisory secret scanner.
#
# Scans the content about to be written for high-signal secret/credential patterns. Downgraded
# from the community BLOCKING idiom (gitleaks/exit-2) to vis advisory/fail-open: writes to
# stderr, exits 0 — never blocks the write. Quiet — emits NOTHING unless a pattern is found.
# Content inspection is not covered by Claude Code's built-in permission gating (clears
# smart-test criterion 4). Self-contained (plugin-cache-safe).
set -uo pipefail

[[ -n "${CLAUDE_SUBAGENT:-}" ]] && exit 0

payload="$(cat 2>/dev/null || true)"
# Write -> tool_input.content; Edit -> tool_input.new_string.
content="$(printf '%s' "$payload" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null || true)"
[[ -z "$content" ]] && exit 0

# High-signal, low-false-positive secret formats + a conservative generic assignment.
pattern='AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|ghp_[0-9A-Za-z]{36}|xox[baprs]-[0-9A-Za-z-]{10,}|AIza[0-9A-Za-z_-]{35}|(api[_-]?key|secret|token|passwd|password)[[:space:]]*[:=][[:space:]]*['"'"'"]?[A-Za-z0-9/+=_-]{16,}'

hits="$(printf '%s' "$content" | grep -nEi "$pattern" 2>/dev/null | head -5 || true)"

if [[ -n "$hits" ]]; then
  {
    echo "[vis · secret-scan] the content being written looks like it contains a secret/credential:"
    echo "$hits"
    echo "Do NOT hard-code secrets — use env vars / a secrets manager. Confirm it's a placeholder if intentional."
  } >&2
fi

exit 0
