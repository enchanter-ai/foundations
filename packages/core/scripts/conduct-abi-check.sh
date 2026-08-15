#!/usr/bin/env bash
# Verify shared/conduct/ in this repo matches vis/conduct/ canonical.
# Usage: conduct-abi-check.sh [--strict] <path-to-canonical>
#
# Exit status:
#   0  validated OK, or legitimately not applicable (non-strict, no dir)
#   1  drift or missing modules
#   2  strict mode: no shared/conduct/ dir to validate
#
# VF-14: previously a repo with no shared/conduct/ dir printed a message and
# exited 0 — indistinguishable from "validated OK". The repos without the dir
# therefore reported success while validating nothing, so the check passed
# vacuously. Now "no dir" reports SKIPPED (not PASSED) and CONDUCT_ABI_STRICT=1
# (or --strict) turns it into a hard failure for repos that must carry conduct.
set -euo pipefail
STRICT="${CONDUCT_ABI_STRICT:-0}"
if [ "${1:-}" = "--strict" ]; then STRICT=1; shift; fi
CANONICAL="${1:-../vis/conduct}"
LOCAL="shared/conduct"
DRIFT=0
if [ ! -d "$LOCAL" ]; then
  if [ "$STRICT" = "1" ]; then
    echo "conduct-abi-check: FAIL — no $LOCAL/ to validate (strict mode)" >&2
    exit 2
  fi
  echo "conduct-abi-check: SKIPPED — no $LOCAL/ in this repo (nothing validated)" >&2
  exit 0
fi
for f in "$CANONICAL"/*.md; do
  base=$(basename "$f")
  if [ ! -f "$LOCAL/$base" ]; then echo "MISSING: $LOCAL/$base"; DRIFT=1; continue; fi
  diff -q "$f" "$LOCAL/$base" >/dev/null 2>&1 || { echo "DRIFT: $base"; DRIFT=1; }
done
[ "$DRIFT" = "0" ] && echo "conduct-abi-check: OK — $LOCAL matches canonical" >&2
exit $DRIFT
