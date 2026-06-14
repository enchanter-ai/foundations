#!/usr/bin/env bash
# machine-path-leak-guard.sh — PostToolUse(Write|Edit) advisory. Counter to F02 (portability leak).
#
# Warns when a git-TRACKED file gains machine-specific absolute path literals (C:\git, C:/git,
# /home/<user>/, /Users/<name>/, D:/dev). Skips untracked/scratch files. Advisory: stderr + exit 0.
# Quiet unless a hit. Self-contained.
set -uo pipefail

[[ -n "${CLAUDE_SUBAGENT:-}" ]] && exit 0

payload="$(cat 2>/dev/null || true)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[[ -z "$file" || ! -f "$file" ]] && exit 0

# Tracked files only — scratch/state/local files legitimately hold absolute paths.
git -C "$(dirname "$file")" ls-files --error-unmatch "$file" >/dev/null 2>&1 || exit 0

hits="$(grep -nE '([A-Za-z]:[\\/]git|[A-Za-z]:[\\/]dev|/home/[^/ "]+/|/Users/[^/ "]+/)' "$file" 2>/dev/null | head -5 || true)"
if [[ -n "$hits" ]]; then
  {
    echo "[vis · machine-path-leak] $(basename "$file") contains machine-specific absolute paths:"
    printf '%s\n' "$hits"
    echo "Use repo-relative or <repo-root>/ form so it's portable across machines."
  } >&2
fi

exit 0
