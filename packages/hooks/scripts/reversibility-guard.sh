#!/usr/bin/env bash
# reversibility-guard.sh — PreToolUse(Bash) advisory. Counter to F26 (reversibility blindness).
#
# Advisory caution on hard-to-reverse shell commands. This is the vis fail-open DOWNGRADE of the
# community blocking idiom (and an advisory COMPLEMENT to Claude Code's built-in permission
# gating, not a replacement): stderr + exit 0, never blocks. The delta over allow/deny is the
# reversibility framing + catching Bash-composed forms. Quiet — fires only on a match.
# Self-contained.
set -uo pipefail

[[ -n "${CLAUDE_SUBAGENT:-}" ]] && exit 0

payload="$(cat 2>/dev/null || true)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[[ -z "$cmd" ]] && exit 0

# Hard-to-reverse patterns (conservative, high-signal).
pattern='rm +-[a-zA-Z]*[rf]|git +reset +--hard|git +push +.*(--force|--force-with-lease|-f([[:space:]]|$))|git +clean +-[a-zA-Z]*f|git +checkout +--[[:space:]]|mkfs|[[:space:]]dd +if=|chmod +-R +777|truncate +-s +0|>[[:space:]]*/dev/sd|DROP +TABLE|DELETE +FROM|curl[^|]*\|[^|]*\b(bash|sh)\b'

if printf '%s' "$cmd" | grep -Eqi "$pattern"; then
  {
    echo "[vis F26 · reversibility] this command looks hard to reverse:"
    printf '  %s\n' "$cmd" | head -1
    echo "Confirm it's intended and you have a way back (backup / branch / --dry-run) first. Advisory only — not blocked."
  } >&2
fi

exit 0
