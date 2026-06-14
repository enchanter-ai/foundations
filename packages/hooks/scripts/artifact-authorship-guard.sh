#!/usr/bin/env bash
# artifact-authorship-guard.sh — PreToolUse(Write|Edit) advisory. Authorship contract.
#
# Warns when a PUBLIC artifact (LICENSE, *.cff / CITATION, README, *.bib) is written with an
# author / copyright / alias line that does NOT credit "Enchanter Labs". GENERIC — it does not
# hardcode any individual's name or email; it simply flags authorship lines missing the org credit.
# Advisory: stderr + exit 0. Quiet unless an author line lacks the credit. Self-contained.
set -uo pipefail

[[ -n "${CLAUDE_SUBAGENT:-}" ]] && exit 0

payload="$(cat 2>/dev/null || true)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
content="$(printf '%s' "$payload" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null || true)"
[[ -z "$file" || -z "$content" ]] && exit 0

case "$(basename "$file")" in
  LICENSE|LICENSE.*|*.cff|CITATION.*|README.md|*.bib) ;;
  *) exit 0 ;;
esac

authlines="$(printf '%s' "$content" | grep -niE 'author|copyright|alias|\(c\)' | head -10 || true)"
[[ -z "$authlines" ]] && exit 0

if ! printf '%s' "$content" | grep -qi 'Enchanter Labs'; then
  {
    echo "[vis · authorship] $(basename "$file") has author/copyright lines that don't credit 'Enchanter Labs':"
    printf '%s\n' "$authlines" | head -4
    echo "Public-artifact authorship must read 'Enchanter Labs', not a personal handle/email."
  } >&2
fi

exit 0
