# Context Budget — Proactive Token Discipline in Long Loops

Audience: any agent in a long-loop workflow — deep-research multi-phase fetchers, `/create` iteration in wixie, `/converge` in any plugin, lich review, hydra security walk, crow session-memory accumulator. How to keep the input-token side of the meter from compounding silently into a pricing-tier cliff or a runtime context-window error.

## The rule

In a naive agent loop, **input token cost grows quadratically**: each turn re-sends prior turns, and discovery work compounds the base. Empirical reports from production agentic coding systems converge on the same shape — 60–80% of coding-agent tokens go to *discovery* (reading files, searching, running grep) rather than the actual solve (arxiv 2604.27707 on production agentic memory analysis; Mindstudio agent-engineering postmortem; Augment Code "context engineering" writeup). The cost is not the per-call price — it is the accumulation across the loop.

The discipline this module names is **proactive context-window enforcement**: alert at >85% utilization *before* the API returns a context-exceeded error, and before crossing the pricing-tier threshold that doubles input cost. Branch on the alert — ask, skip, or compact. Silent compaction is the failure mode this module forbids.

## Why proactive, not reactive

| Mode | Where the check lives | Signal | Failure shape |
|---|---|---|---|
| Reactive | After an API error (`context_length_exceeded`) | Hard failure, mid-loop | Loop dies on turn N+1; user sees a stack trace; in-flight artifact corrupt |
| Reactive (pricing) | After the monthly bill | Cost spike | Bill is non-recoverable; learning is post-hoc |
| **Proactive** | Per-turn pre-dispatch, ≥ 85% utilization | Soft alert with three branches | Loop continues under explicit policy; the user is in the loop on the policy choice |

Reactive enforcement is the wrong abstraction for an agentic loop: by the time the API errors, the loop has already paid for the offending turn's input tokens. Proactive enforcement is the only enforcement that prevents the cost.

## Thresholds and branches

Per-turn pre-dispatch check, on a token estimator (model-specific tokenizer or harness-provided counter):

| Utilization | Action |
|---|---|
| < 70% | Proceed silently |
| 70–85% | Log advisory; no branch required; surface in turn-end summary |
| **> 85%** | **Alert and branch — do not dispatch the next turn until a branch is chosen** |
| > 95% | Hard halt; the loop has overrun its budget; escalate to principal |

The three permitted branches at the > 85% alert:

1. **ask-user** — surface the budget state and request a choice (compact / skip / continue with explicit acceptance of the cost). Default for high-stakes consumers (deploy-bar verdicts, irreversible writes).
2. **skip-and-note** — drop the planned tool dispatch for this turn, record `context-budget-skip` in the trace, continue with the artifact short of that step. Appropriate for non-load-bearing discovery work.
3. **compact** — invoke an explicit compaction step (summarize prior turns into a shorter representation, drop full tool outputs, retain only the load-bearing claims). **Compaction is never silent** — the compaction step appears in the trace with the pre-compact and post-compact token counts.

Picking a branch without recording which branch was picked is F31 (see below).

## Quadratic-loop discipline (the underlying shape)

The 60–80% discovery-share figure does not mean *the agent is wasteful* — it means **discovery is the dominant cost mode of a useful agent**, and discovery compounds when retried. The countermeasures are:

| Countermeasure | What it does |
|---|---|
| Cache discovery results within a session | A second `Grep` for the same pattern returns the cached match-set; a second `Read` of a file already in context returns a pointer not the body |
| Bound the per-turn discovery dispatch | Cap parallel reads at N; one large directory walk per turn maximum; explicit `--force` to override |
| Externalize stable knowledge | Briefings, MEMORY.md, learnings logs move stable findings out of per-turn context; per [`./substrate-consumption.md`](./substrate-consumption.md) the read is at session start, not every turn |
| Summarize tool outputs before re-sending | A 12 KB tool output that was already used does not need to be in context turn N+5; a 200-token summary suffices |

Production agentic systems that hold cost flat across a loop apply all four. Production agentic systems that don't pay quadratic prices.

## Failure modes

| Code | Signature | Counter |
|------|-----------|---------|
| F31 | Naive-accumulating-context-loop — long-loop workflow with no per-turn utilization check, no caching, no externalization; cost compounds quadratically | Wire the per-turn estimator; enforce the > 85% alert; cap discovery dispatch per turn |
| F31.1 | Reactive API-error context handling — loop dies on `context_length_exceeded`, no advance warning, in-flight artifact lost | Move the check from post-error to pre-dispatch; the > 85% alert fires *before* the failing turn |
| F31.2 | Silent compaction — agent compacts prior turns mid-loop without surfacing the action, downstream consumers see a different context than they expect | Compaction is explicit, logged, and pre-announced; a silent compact is a recoverable mid-loop edit, not a feature |
| F31.3 | Pricing-tier-cliff — loop accumulated across the input-pricing threshold (e.g., > 200K-context-tier surcharge) without an alert; cost doubled silently | The > 85% alert must include the pricing-tier check; the model's tier boundaries are part of the budget, not a separate concern |

## Cross-references

- [`./context.md`](./context.md) § Smallest-set rule, U-curve placement — this module names the per-turn enforcement; that one names the per-message placement within an existing budget.
- [`./substrate-consumption.md`](./substrate-consumption.md) — externalizing stable knowledge to briefings/MEMORY/learnings is the cross-session form of "summarize before re-sending."
- [`./failure-modes.md`](./failure-modes.md) § F31 — the taxonomic entry this module operationalises.
- [`../../web/conduct/web-fetch.md`](../../web/conduct/web-fetch.md) — per-fetch byte budgets are the same shape one layer down (single-tool budget rather than session-wide).

## Anti-patterns

- **No per-turn utilization estimate.** The loop runs blind. The first signal is an API error or a bill. Both are too late.
- **Silent compaction.** The downstream consumer sees a smaller context than the upstream producer wrote; the trace lies; debugging is impossible.
- **Treating > 85% as a hard halt.** The threshold is an *alert*, not a stop — the three branches are the contract. Hard-halt at 85% is brittle on a long-loop workflow that legitimately needs the headroom for one more dispatch.
- **No alert at all.** Reactive-only enforcement is permitted only in throwaway scripts. Production agentic loops have proactive enforcement or they have hidden costs.
- **Caching everything indiscriminately.** Stale cache on a fresh-critical surface (a release-day fetch, a model-snapshot check) is worse than re-fetching. Cache discovery; do not cache time-sensitive reads.
- **"We'll handle it when it errors."** Reactive enforcement against quadratic growth is asymptotically the wrong shape: each retry compounds the next turn's input cost. Proactive is the only shape that holds cost flat.
- **Externalizing only after the alert fires.** The substrate (briefings, MEMORY) is read at session *start*, per [`./substrate-consumption.md`](./substrate-consumption.md); moving the read to "when the budget pressures me" recreates the quadratic growth pattern around the substrate read itself.
- **Hiding compaction inside a tool wrapper.** Any compaction must appear in the trace as its own step with pre/post token counts. A tool that compacts as a side-effect of returning a result is a silent compaction in disguise.
