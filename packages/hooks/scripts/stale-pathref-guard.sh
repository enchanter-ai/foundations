#!/usr/bin/env bash
# stale-pathref-guard.sh — PostToolUse(Write|Edit) advisory. Counter to F02 / F27.
#
# After writing a markdown doc, check that its @-imports and local markdown-link targets actually
# resolve to a file (relative to the doc's directory). Catches the silent CLAUDE.md @-import /
# dangling-pointer breakage that in-context conduct misses. Advisory: stderr + exit 0. Quiet
# unless a reference dangles. Self-contained.
set -uo pipefail

[[ -n "${CLAUDE_SUBAGENT:-}" ]] && exit 0

payload="$(cat 2>/dev/null || true)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[[ -z "$file" || ! -f "$file" ]] && exit 0
case "$file" in *.md|*.mdx) ;; *) exit 0 ;; esac

dir="$(dirname "$file")"
# Strip fenced code blocks (```), then inline code spans (`...`), so EXAMPLE paths in docs
# don't false-positive — only real prose @-imports and markdown links are checked.
prose="$(awk 'BEGIN{f=0} /^[[:space:]]*```/{f=!f; next} !f{print}' "$file" | sed 's/`[^`]*`//g')"
refs="$(printf '%s\n' "$prose" | grep -oE '@[A-Za-z0-9_./-]+\.(md|mdx|py|json|ya?ml|sh|ts|js)|\]\([A-Za-z0-9_./-]+\.(md|mdx|py|json|ya?ml|sh|ts|js)\)' 2>/dev/null \
  | sed -E 's/^\]\(//; s/\)$//; s/^@//' | sort -u || true)"
[[ -z "$refs" ]] && exit 0

miss=""
while IFS= read -r ref; do
  [[ -z "$ref" ]] && continue
  case "$ref" in http*|*://*) continue ;; esac
  [[ ! -e "$dir/$ref" && ! -e "$ref" ]] && miss="${miss}  ${ref}"$'\n'
done <<< "$refs"

if [[ -n "$miss" ]]; then
  {
    echo "[vis · stale-pathref] $(basename "$file") references targets that don't resolve:"
    printf '%s' "$miss" | head -6
    echo "Fix the path or create the target — broken @-imports / links fail silently."
  } >&2
fi

exit 0
