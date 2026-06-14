#!/usr/bin/env bash
# dependency-intent-receipt.sh — PreToolUse(Bash + Write|Edit) advisory. Supply-chain provenance counter.
#
# Fires when the agent adds or changes a dependency — either a package-install shell command
# (npm/pnpm/yarn/bun/pip/poetry/uv/go/cargo/gem) or an edit to a manifest/lockfile. Asks for a
# one-line dependency intent receipt (package · version · reason · source · relation to the task)
# BEFORE the dependency lands. This is the provenance the diff alone never records: WHY this
# package, pinned to WHAT, and how it serves the user's goal. Built-in permission gating governs
# allow/deny of the command; it does not attach intent/provenance. Advisory: stderr + exit 0,
# never blocks. Quiet — only on a real dependency event. Self-contained.
set -uo pipefail

[[ -n "${CLAUDE_SUBAGENT:-}" ]] && exit 0

payload="$(cat 2>/dev/null || true)"
tool="$(printf '%s' "$payload" | jq -r '.tool_name // empty' 2>/dev/null || true)"

hit=""
case "$tool" in
  Bash)
    cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
    [[ -z "$cmd" ]] && exit 0
    # Install/add subcommands only — not list/run/test/audit, which are benign.
    inst='(npm|pnpm|yarn|bun) +(install|i|add)( |$)|pip3? +install|python3? +-m +pip +install|poetry +add|uv +(add|pip +install)|go +get( |$)|cargo +(add|install)|gem +install'
    if printf '%s' "$cmd" | grep -Eqi "$inst"; then
      hit="$(printf '%s' "$cmd" | head -1)"
    fi
    ;;
  Write|Edit)
    file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
    [[ -z "$file" ]] && exit 0
    case "$(basename "$file")" in
      package.json|requirements*.txt|pyproject.toml|Cargo.toml|go.mod|Gemfile|setup.py|setup.cfg|environment.yml|environment.yaml) hit="$file" ;;
      package-lock.json|pnpm-lock.yaml|yarn.lock|Cargo.lock|go.sum|poetry.lock|uv.lock|Gemfile.lock) hit="$file (lockfile)" ;;
      *) exit 0 ;;
    esac
    ;;
  *) exit 0 ;;
esac

[[ -z "$hit" ]] && exit 0

{
  echo "[vis · dependency-intent] this changes project dependencies:"
  printf '  %s\n' "$hit"
  echo "State a dependency intent receipt before it lands — package · pinned version/range · why · source/registry · how it serves the user's goal. Unattributed deps are how supply-chain drift enters a repo."
} >&2

exit 0
