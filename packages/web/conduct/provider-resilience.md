# Provider Resilience — Cross-Provider Fallback Is the Discipline

Audience: any agent or plugin that depends on a third-party model or API provider in normal operation — every wixie skill (Anthropic API), lich review (model provider of choice), hydra security (model + WebFetch + MCP providers), pech precedent loops, robit / crow downstream consumers. How to keep a vendor-side outage from becoming a workflow-side hard-stop, and how to keep fallback paths honest by exercising them on a schedule.

## The rule

Most production LLM outages are **full-vendor outages**, not model-specific (thoughts.jock.pl operational-resilience writeup; corroborated by status.anthropic.com incident history and statuspage.openai.com). A failover within a single vendor (e.g., Anthropic Opus → Anthropic Sonnet) frequently does not help, because the underlying outage is in the vendor's serving fabric. The discipline this module names is **cross-provider fallback**: at least one tier of the fallback chain must terminate at a different vendor, not a different model from the same vendor.

A second-tier fallback to a **local model** is a *different* class of failure: local-model fallbacks risk "completes-with-wrong-answer" rather than "fails-cleanly" — the local model returns a plausible string the orchestrator may treat as authoritative. Local-model fallbacks are unsuitable as *sole* fallback for high-stakes work; they are valid as a low-confidence tier only, with the verdict bar downgraded explicitly.

Fallback paths that are never exercised silently rot — IAM permissions expire, schema drifts, the alternate vendor's API renames a field. The discipline includes a **quarterly chaos validation**: intentionally disable the primary key and verify the fallback completes the workflow end-to-end with the verdict bar adjusted.

## Fallback tiers

A production-grade fallback chain has three tiers, distinct in behavior:

| Tier | Example | Verdict bar | When it kicks in |
|---|---|---|---|
| **Cross-provider hot** | Anthropic primary → OpenAI / Google secondary; or vice versa | Same as primary if the secondary is in the same capability class for the task | Primary returns 5xx, rate-limit, or timeout > stated SLO |
| **Local-model warm** | A locally-served model (Llama, Qwen, Mistral) reachable from the workflow | Downgraded to PARTIAL or HOLD; never DEPLOY | All cross-provider tiers exhausted; high-stakes work routes to human-escalation instead |
| **Human-escalation** | A documented path to a human owner — file touch, alert, ticket | The verdict is *deferred*, not emitted | All model tiers exhausted on a load-bearing step |

A chain that goes Anthropic-primary → Anthropic-Haiku-fallback → done is **F33 single-provider dependency** — see below. The chain must cross a vendor boundary.

## Capability-class matching across providers

The cross-provider hot tier is only safe when the secondary provider is in the **same capability class** for the task. A fallback from a frontier reasoning model to a smaller-context cross-provider model is itself a verdict downgrade per [`../../core/conduct/capability-fidelity.md`](../core/conduct/capability-fidelity.md).

| Task class | Primary example | Cross-provider hot example | Notes |
|---|---|---|---|
| Long-context reasoning (> 200K) | Claude Opus 1M | Gemini 2.5 Pro long-context | Capability-class match if the context window suffices |
| Code generation w/ tool use | Claude Sonnet | GPT-4-class with function calling | Match on tool-use fidelity, not just code score |
| Cheap parallel classification | Claude Haiku | Gemini Flash, GPT-mini | Match on cost-tier and concurrency, not capability |
| Adversarial-defense surfaces | Provider-specific safety stack | **No equivalent — accept HOLD** | Defense surfaces are vendor-coupled; per [`./adaptive-adversary-baseline.md`](./adaptive-adversary-baseline.md), the eval is against the deployed stack, not the fallback's |

When no cross-provider equivalent exists in the capability class, the chain skips the hot tier and goes straight to local-warm → human-escalation, with the verdict downgraded.

## Chaos-validation cadence

Untested fallback paths rot. The discipline is **deliberate disabling of the primary** on a stated cadence:

| Surface | Cadence | What gets tested |
|---|---|---|
| Cross-provider hot tier | **Quarterly** | Disable the primary API key for one workflow run; verify the secondary completes end-to-end; record the verdict-class delta |
| Local-model warm tier | **Quarterly** | Disable both primary and secondary keys; verify the local model returns; verify the orchestrator downgrades verdict to PARTIAL/HOLD; verify it does not silently emit DEPLOY |
| Human-escalation path | **Per release + bi-annual** | Verify the escalation channel reaches a human; verify the human's expected reply path is unbroken |
| Cross-provider monoculture check | **Annually** | Audit that primary + hot secondary do not in fact share a backend (e.g., both routing through the same hyperscaler region with shared dependency) |

Cadences are floors. A workflow that cannot afford the cadence ships PARTIAL with the stale-window stated, never DEPLOY.

## Local-model warm tier — the "completes-with-wrong-answer" hazard

Cross-provider fallbacks fail cleanly: the secondary returns its answer; the orchestrator treats it under that vendor's published reliability and accepts the result. Local-model fallbacks fail dirtier: the local model **returns something**, plausibly formatted, possibly wrong, and the orchestrator has no signal distinguishing "the primary is back and this is right" from "the primary is down and this is a 7B-parameter hallucination."

Three rules limit the damage:

1. **Verdict downgrade is automatic.** The chain knows it is on the local-warm tier; the verdict ceiling is PARTIAL or HOLD; DEPLOY is forbidden regardless of the local model's stated confidence.
2. **Output classifier is independent.** A separate light check (regex, schema validation, sanity bound) runs on the local-tier output and is allowed to FAIL the result even when the local model returned confidently.
3. **Trace records the tier.** Downstream consumers must see "this artifact was produced on the local-warm tier" so verdict-inflation does not occur at a downstream re-aggregation step.

## Failure modes

| Code | Signature | Counter |
|------|-----------|---------|
| F33 | Single-provider dependency — the entire fallback chain terminates inside one vendor | Cross at least one tier to a different vendor; verify with a chaos run |
| F33.1 | Untested-fallback-path — the chain exists in config but has never been exercised; on real outage the secondary IAM is expired or the schema drifted | Quarterly chaos validation; record the run in the trace |
| F33.2 | Local-model-silent-wrong-answer — local-warm tier returned a plausible-but-wrong artifact; the orchestrator emitted under the primary verdict bar | Hard rule: local-warm tier ceilings at PARTIAL/HOLD; independent output classifier must pass; trace records the tier |
| F33.3 | Provider-monoculture — primary and hot-secondary nominally cross vendors but in fact share a backend (same hyperscaler region with shared dependency, or shared upstream model provider) | Annual monoculture audit; trace the actual serving paths, not the contracted ones |
| F33.4 | Assumed-uptime — code paths assume the provider is up, no timeout, no retry budget, no fallback dispatch — outage manifests as a hung workflow | Wire explicit SLO timeout per provider; dispatch to next tier on timeout; never wait indefinitely |

## Cross-references

- [`../core/conduct/capability-fidelity.md`](../core/conduct/capability-fidelity.md) — when the fallback's capability class is below the primary's, the verdict bar moves with it; never ship under the original bar on a downgraded path.
- [`./adaptive-adversary-baseline.md`](./adaptive-adversary-baseline.md) — defense-surface verdicts are vendor-coupled; provider-fallback does not transfer the defense claim.
- [`./mcp-research-discipline.md`](./mcp-research-discipline.md) — MCP providers are themselves a third-party dependency surface; the chaos-cadence and monoculture-audit rules apply.
- [`../core/conduct/verdict-calibration.md`](../core/conduct/verdict-calibration.md) — verdicts emitted while on a fallback tier carry the tier in the calibration qualifier.

## Anti-patterns

- **Single-vendor fallback chain.** Anthropic-Opus → Anthropic-Sonnet → Anthropic-Haiku is one provider three times. The full-vendor outage takes them all down together.
- **Untested fallback.** A fallback path that has never been exercised is a config comment, not a fallback. The chaos cadence is the only proof.
- **Local-model as sole fallback for high-stakes work.** The "completes-with-wrong-answer" failure mode makes it unsuitable; either cross to another vendor or accept HOLD.
- **Assumed uptime.** Code that has no timeout on the primary, no retry budget, no fallback dispatch is fragile by construction. Wire the SLO timeout per provider explicitly.
- **No verdict downgrade on the local-warm tier.** A DEPLOY emitted on a local-model fallback is verdict inflation; the ceiling moves with the tier.
- **Trusting the contracted serving path.** Two "different vendors" that both route through the same hyperscaler region share fate. Monoculture-audit annually; trace the actual backend, not the contract.
- **Quarterly chaos validation skipped because "the fallback was tested at launch."** Permissions expire, schemas drift, vendor APIs deprecate fields. The cadence is the contract; one-shot validation is decoration.
- **Silent-fallback emission.** The trace must record which tier produced the artifact. Downstream re-aggregators who do not see the tier emit verdict inflation by default.
