#!/usr/bin/env bash
# evidence-gate.sh — Stop advisory. False-completion / fake-verification counter.
# Runtime check for the "false-completion claim" adversarial case in docs/evals/agent-boundary-checklist.md.
#
# At end of turn, scans the final assistant message for COMPLETION/VERIFICATION CLAIMS — "tests
# pass", "verified", "deployed", "lint clean", "all green", "confirmed working" — and, when it
# finds one, emits a quiet advisory that the claim should rest on a matching tool receipt from
# this session, not on confidence. Counters silent failure / false confidence (the "looks done"
# trap). In-context conduct can't self-time the final word — by the time the turn ends, the claim
# is already made; a deterministic Stop scan catches the unbacked assertion as it lands.
#
# LOAD-BEARING SAFETY: this hook NEVER emits additionalContext and NEVER blocks the stop — doing
# so would force the turn to continue (load-bearing + loop risk). It writes to stderr and exits 0:
# advisory to the human reviewer, fail-open, no re-trigger. Quiet — silent unless a claim appears.
# Self-contained. There is no session receipt ledger in this codebase, so the hook reminds rather
# than verifies; promote to a verifying gate only once a receipt ledger exists (see README Deferred).
set -uo pipefail

[[ -n "${CLAUDE_SUBAGENT:-}" ]] && exit 0

payload="$(cat 2>/dev/null || true)"
msg="$(printf '%s' "$payload" | jq -r '.assistant_message // empty' 2>/dev/null || true)"
[[ -z "$msg" || "$msg" == "null" ]] && exit 0

# High-signal completion/verification claims. Past-tense / state assertions, not future intent.
claim='\b(tests?|suite|ci|build|lint(er)?|type[- ]?check)\b.{0,30}\b(pass(ed|ing)?|green|clean|succeed(ed|s)?)\b'
claim="$claim"'|\b(all|everything)\b.{0,20}\b(pass(ed|ing)?|green|working|tested)\b'
claim="$claim"'|\b(verified|validated|confirmed working|deployed|shipped|released|fully fixed|now works|works correctly)\b'
claim="$claim"'|\bno (errors|failures|issues|regressions)\b'

printf '%s' "$msg" | grep -Eqi "$claim" || exit 0

{
  echo "[vis · evidence-gate] the final answer makes a completion/verification claim (e.g. tests pass / verified / deployed / lint clean)."
  echo "Confirm it rests on an actual tool receipt from THIS session — a real test run, build, lint, or deploy output — not on expectation."
  echo "If the claim was not executed and observed this session, downgrade the wording (\"should pass\" / \"not run\") so the verdict stays honest. Advisory only — turn not blocked."
} >&2

exit 0
