#!/usr/bin/env bash
# compact-checkpoint.sh — SessionStart(matcher: compact) advisory hook. Counter to F03.
#
# Re-injects a checkpoint-restate prompt immediately AFTER a context compaction — the one
# moment the model cannot self-time. PreCompact stdout is NOT model-visible; SessionStart
# fires with source=compact after compaction and ITS stdout IS injected as context, so the
# re-injection lives here. Advisory + fail-open (always exit 0). Skips in subagents.
# Self-contained (plugin-cache-safe: no paths outside the plugin root).
set -uo pipefail

[[ -n "${CLAUDE_SUBAGENT:-}" ]] && exit 0

cat <<'MSG'
[vis F03 · post-compaction checkpoint + obligation anchor] The context was just compacted.
Before the next tool call, re-establish the checkpoint (conduct: context.md § Checkpoint protocol):
  - GOAL: the current task's success criterion, in one line.
  - STATE: which files / branches are open, and the last VERIFIED step.
  - INVARIANTS: decisions/constraints that must NOT be re-litigated or silently dropped.
  - NEXT: the single next action.
Then re-anchor the OBLIGATIONS that compaction most often drops silently — restate each that applies:
  - APPROVALS: what the user explicitly approved, and the exact scope of that approval.
  - DENIED: approaches the user (or a guard) already ruled out — do not quietly revive them.
  - BOUNDARIES: security / safety / scope limits set this session that still bind.
  - VERIFICATION DEBT: claims made but not yet verified, and tests/checks owed before "done".
Restate these from the surviving context first. If any is unrecoverable from what remains,
say so and ask — do not guess across the compaction boundary.
MSG

exit 0
