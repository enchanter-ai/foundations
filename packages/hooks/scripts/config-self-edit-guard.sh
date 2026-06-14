#!/usr/bin/env bash
# config-self-edit-guard.sh — PreToolUse(Write|Edit) advisory. Self-modification guard.
#
# Warns when the agent is about to edit its OWN startup/hook/plugin config — permissions,
# hooks, or plugin manifests. Built-in permission gating governs allow/deny on a path; it does
# not flag "this is the agent's own config" as a category. Advisory complement: stderr + exit 0,
# never blocks. Quiet — fires only on a config path. Self-contained.
set -uo pipefail

[[ -n "${CLAUDE_SUBAGENT:-}" ]] && exit 0

payload="$(cat 2>/dev/null || true)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[[ -z "$file" ]] && exit 0

config_re='(^|/)\.claude/settings(\.local)?\.json$|(^|/)\.claude-plugin/|/hooks/hooks\.json$|(^|/)\.mcp\.json$'

if printf '%s' "$file" | grep -Eq "$config_re"; then
  {
    echo "[vis · config-self-edit] editing agent startup/hook/plugin config: $file"
    echo "Self-modifying config (permissions, hooks, plugins, MCP) is high-consequence and is rarely what a task actually needs. Confirm it's deliberate and minimally scoped before proceeding."
  } >&2
fi

exit 0
