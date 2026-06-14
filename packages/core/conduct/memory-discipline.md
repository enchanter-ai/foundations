# Memory Discipline — Production Memory Is Active Decision-Use, Not Passive Recall

Audience: any agent integrating with a cross-session memory or inference substrate — wixie's inference-engine, crow's session-memory accumulator, lich review's historical-precedent surface, any future-substrate consumer. How to distinguish memory systems that *change behavior* from ones that merely *retrieve plausible-sounding strings*.

## The rule

A memory system that scores well on passive-recall benchmarks but never changes downstream behavior is a retrieval index, not a memory. MemoryArena's analysis of agentic-memory benchmarks reports a 40–60% **active-use gap** between retrieval and decision-use (arxiv 2603.07670v1): the system can fetch the right fact when prompted to fetch, yet the agent's downstream action is unchanged whether the fetch happened or not. Current deployed "agentic memory" is mostly context-engineering with frozen weights — the model does not learn; the substrate gates what enters context (arxiv 2604.27707).

The discipline this module names is **active-decision evaluation** for memory: every memory benchmark, every admission policy, every consolidation step is scored on **whether the downstream decision changed**, not on whether the retrieval returned the relevant entry. Interpretable admission control beats opaque LLM-judge admission: feature-based admission (utility, confidence, novelty, recency, type-prior) is auditable and shows better generalization than LLM-policy admission on out-of-distribution memory pressures (arxiv 2603.04549).

## Passive recall vs. active decision-use

| Mode | What it measures | What it misses |
|---|---|---|
| **Passive recall** | Given a query, does the substrate return the relevant entry? | Whether the agent then *used* the entry to change its action |
| **Active decision-use** | Given the entry-in-context, did the agent's downstream action differ from the no-entry control? | Nothing — this is the contract |
| **Gap** | 40–60% on common agentic-memory benchmarks (arxiv 2603.07670v1) | The headline number a passive-recall benchmark publishes |

A memory system shipped against passive-recall numbers alone is **F32 ranked-on-passive-recall-only** (see below). The active-decision number is the floor; the recall number is supplementary.

## Production memory requirements

A substrate is production-ready when it surfaces all five:

| Requirement | What it does | Failure if absent |
|---|---|---|
| **Observability** | Every read and write is traced; an external auditor can answer "what did the agent see?" and "what did it write?" | Honest-numbers contract collapses; bugs in the substrate become silent posterior corruption |
| **Contradiction-detection** | When a new artifact contradicts a stored pattern (different signal, opposing counter), the conflict surfaces rather than overwrites | Decay alone cannot resolve contradictions; the newer write wins regardless of evidence weight |
| **Staleness management** | EMA decay with a stated half-life; retired-pattern surfacing per the substrate's mutation contract | Stale evidence ships as current advice; consumers cite retired patterns |
| **Privacy-compliant deletion** | A targeted-erase operation that purges an artifact + its derived posteriors atomically, with the trace recording the erase | GDPR / SOC2 / contractual deletion requests cannot be honored; the substrate becomes a compliance liability |
| **Admission control** | A policy gating which artifacts get written; ideally interpretable (feature-based) per below | Substrate accumulates noise; SPRT walks fragment; briefings drift toward verbose-low-signal |

The five together are the minimum. Crow, wixie's inference-engine, and any future substrate that wants to be relied on for cross-session reasoning ships all five or ships PARTIAL.

## Interpretable admission control

Per arxiv 2603.04549, interpretable feature-based admission outperforms opaque LLM-judge admission on out-of-distribution memory pressures (novel topic, adversarial submissions, distribution shift). The features that matter:

| Feature | Signal | Default weight |
|---|---|---|
| `utility` | Estimated downstream decision-use lift (active-decision contribution) | High |
| `confidence` | Posterior or calibration band of the underlying claim | High |
| `novelty` | Distance from nearest existing artifact in the substrate (avoid duplication) | Medium |
| `recency` | Timestamp freshness; subject to substrate decay half-life | Medium |
| `type-prior` | Per-category admission rate (e.g., process-discipline vs. operational-discipline) | Low |

Why interpretable wins on OOD: an LLM-judge admission policy is a learned function of the same model that produced the candidate artifact; on a novel distribution the judge inherits the same blind spots. A feature-based policy is at most a linear (or shallow-tree) function over auditable inputs; an auditor can trace why a given artifact was admitted or rejected.

This does not mean "no LLM in the loop" — the *features* may be LLM-extracted (utility estimation, novelty distance). The admission *decision* should be a non-opaque function of those features, not a free-text LLM verdict.

## Consolidation channels

Memory at production scale moves through three channels:

| Channel | Trigger | What happens |
|---|---|---|
| **Write** | Agent emits via the substrate's documented entry point | Artifact enters with timestamp + fingerprint; admission policy gates |
| **Reconcile** | Periodic or pre-high-stakes-read | SPRT walks update posteriors; LLR-low patterns retire; briefings re-render |
| **Consolidate** | Cross-pattern compaction — many small artifacts on the same theme fold into a higher-LLR aggregate pattern | The aggregate inherits the children's evidence; the children remain in the log but stop driving briefings |

Skipping consolidate is the slow-burn failure: the catalog accumulates many small near-duplicates, none of which individually crosses the SPRT elevation threshold, none of which therefore appears in briefings — yet collectively they would. Consolidate on a periodic cadence (weekly minimum at production scale; per-reconcile at lower throughput).

## Failure modes

| Code | Signature | Counter |
|------|-----------|---------|
| F32 | Ranked-on-passive-recall-only — memory benchmark or admission evaluation reports retrieval@k without an active-decision delta | Require active-decision contribution as the headline; recall@k is supplementary |
| F32.1 | Opaque-LLM-admission-policy — admission decision is a free-text LLM verdict, not auditable feature-based | Move to interpretable features (utility, confidence, novelty, recency, type-prior); LLM may extract features but not own the verdict |
| F32.2 | No-contradiction-channel — a new artifact silently overwrites an opposing prior; conflict never surfaces | Detect contradiction (opposing counter, different signal on same fingerprint family) and emit a surfacing event before the write resolves |
| F32.3 | Skipped-consolidation — many small near-duplicate artifacts accumulate; aggregate signal never elevates; briefings under-recall | Periodic consolidate step on a stated cadence; verify post-consolidate that aggregate LLR exceeds child LLRs |

## Cross-references

- [`../../../shared/conduct/inference-substrate.md`](../../../shared/conduct/inference-substrate.md) — the substrate-specific mutation contract this module generalizes across substrates.
- [`./substrate-consumption.md`](./substrate-consumption.md) — read-side discipline; this module covers admission/consolidation/contradiction on the write-and-curation side.
- [`./precedent.md`](./precedent.md) — single-plugin precedent log; the write contract is the same shape one substrate down.
- [`./verdict-calibration.md`](./verdict-calibration.md) — a benchmark verdict ("memory system X scores Y") carries n, method, and a calibration qualifier; passive-recall-only fails the calibration contract.

## Anti-patterns

- **Citing a memory benchmark by recall@k alone.** The headline is `decision-delta`. A system with 95% recall@5 and 0% decision-delta is not a memory; it is a retrieval index.
- **Free-text LLM admission policies.** Opaque, expensive to audit, brittle on OOD. Move to feature-based admission with LLM-extracted features.
- **No contradiction surfacing.** Memory that overwrites silently has no contract; the newer write always wins regardless of evidence.
- **Decay as the only staleness mechanism.** Decay reduces weight; it does not retire. Wire explicit retirement + retirement-respect in the briefing renderer.
- **No targeted-erase path.** "We'll figure out deletion when we need it" is a compliance liability. Build deletion + posterior-recompute atomically; never let an erase leave derived posteriors orphaned.
- **Trusting passive-recall scores in a benchmark.** They are an upper bound on active-decision contribution, often much higher than the true downstream effect.
- **Skipping consolidate because reconcile already runs.** Different mechanisms: reconcile updates posteriors per-artifact; consolidate folds artifacts into aggregates. Both are required at production scale.
- **Pointing the admission policy at the same model that produced the candidate.** Same blind spots on the same OOD distribution; interpretable features are the OOD insurance.
- **Hand-editing a briefing to "fix" a missing signal.** Per the substrate mutation contract, every write goes through the engine. Hand-edits are overwritten on next reconcile; the missing signal is a contradiction-detection bug to fix in the admission policy, not a briefing artifact to patch.
