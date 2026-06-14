#!/usr/bin/env bash
# post-write-validate.sh — PostToolUse(Write|Edit) advisory syntax check. Counter to F02/F14.
#
# After a write, fast-parse the file by extension and warn (same turn) if it doesn't parse.
# PostToolUse is advisory by design: stderr + exit 0, never blocks. Quiet — silent on success,
# unknown extension, or absent validator (fail-open). Self-contained; no side effects
# (ast.parse, not py_compile, so no __pycache__). Emits a clean one-line diagnostic.
set -uo pipefail

[[ -n "${CLAUDE_SUBAGENT:-}" ]] && exit 0

payload="$(cat 2>/dev/null || true)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[[ -z "$file" || ! -f "$file" ]] && exit 0

PY="$(command -v python3 || command -v python || true)"
err=""
case "$file" in
  *.py)
    [[ -n "$PY" ]] && err="$("$PY" - "$file" 2>&1 <<'PYEOF' || true
import ast, sys
try:
    ast.parse(open(sys.argv[1], encoding="utf-8").read())
except SyntaxError as e:
    print("line %s: %s" % (e.lineno, e.msg))
except Exception as e:
    print(str(e))
PYEOF
)"
    ;;
  *.json)
    if command -v jq >/dev/null 2>&1; then jq -e . "$file" >/dev/null 2>&1 || err="invalid JSON (jq parse failed)"; fi
    ;;
  *.sh)
    err="$(bash -n "$file" 2>&1 || true)"
    ;;
  *.toml)
    [[ -n "$PY" ]] && err="$("$PY" - "$file" 2>&1 <<'PYEOF' || true
import sys, tomllib
try:
    tomllib.load(open(sys.argv[1], "rb"))
except Exception as e:
    print(str(e))
PYEOF
)"
    ;;
  *)
    exit 0
    ;;
esac

if [[ -n "$err" ]]; then
  {
    echo "[vis · post-write-validate] $(basename "$file") may not parse:"
    printf '%s\n' "$err" | head -3
    echo "Fix the syntax before relying on it."
  } >&2
fi

exit 0
