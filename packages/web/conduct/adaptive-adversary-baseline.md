# Adaptive Adversary Baseline — Continuous Eval Is the Defense

Audience: any agent producing adversarial-defense claims — hydra security review, wixie `/harden` red-team, lich review of safety surfaces, and any plugin shipping a "we defend against X" verdict. How to keep the difference between *describing a defense* and *demonstrating one* visible in the verdict.

## The rule

A prescriptive layered defense — seven-layer system prompt, typed envelopes, allowlist of tools, sanitizer regex, output classifier, KV firewall, downstream sandbox — is the **baseline**, not the **proof**. Adaptive adversaries that optimize against the defense bypass static stacks at rates that make a one-shot validation meaningless: GCG-style gradient-coordinate suffix attacks reach 99.63% attack success on aligned chat models (arxiv 2602.00750v1), and transfer attacks crafted on one frontier model land on Claude at 64% (arxiv 2505.04806v1). Anthropic's own ConstitutionalClassifier evaluation reports a 4.4% jailbreak rate under 3,000 hours of adaptive red-teaming, four orders of magnitude better than the unprotected baseline but still non-zero (anthropic.com/research/constitutional-classifiers).

The discipline this module names is **continuous adversarial evaluation**: a defense claim ships only with a measurement against a current adaptive-adversary corpus, dated, with the attack success rate stated honestly. One-shot validations are HOLD, not DEPLOY.

## Prescriptive layers vs. known bypasses

Every layer in the canonical defensive stack has a published bypass. Shipping the layer without measuring residual attack success rate against that bypass is a verdict-calibration violation per [`../core/conduct/verdict-calibration.md`](../../core/conduct/verdict-calibration.md).

| Prescriptive layer | Known bypass class | Recommended continuous-eval cadence |
|---|---|---|
| System-prompt role lock | GCG suffix optimization (arxiv 2602.00750v1) — 99.63% ASR on aligned chat | Re-run GCG corpus monthly; refresh suffixes against current model snapshot |
| Typed envelope / structured I/O | Transfer attacks from sibling frontier model (arxiv 2505.04806v1) — 64% Claude landing rate | Re-run transfer-pack against current target model on each model-bump (monthly minimum) |
| Output classifier / constitutional filter | Many-shot jailbreak + paraphrase rewrites (anthropic.com/research/many-shot-jailbreaking) — 4.4% residual ASR | Bi-weekly fresh-paraphrase round against the live classifier |
| Tool-allowlist + scope fence | Indirect prompt injection via fetched content (Greshake et al., arxiv 2302.12173) — bypasses tool gate by mutating retrieved data | Weekly red-team on fetcher inputs; pair with `<untrusted_source>` wrap per [`./source-discipline.md`](./source-discipline.md) |
| Sanitizer regex / keyword block | Token-level obfuscation (base64, leetspeak, Unicode homoglyphs) — bypasses static patterns | Generate fresh obfuscation corpus on each release; assume any static regex is ~30 days from defeat |
| KV firewall / context isolation | Cross-context contamination via retrieved memory (arxiv 2403.13313 — agent memory poisoning) | Quarterly memory-poisoning red-team; pair with admission control per [`../core/conduct/memory-discipline.md`](../core/conduct/memory-discipline.md) |
| Downstream sandbox | Confused-deputy escalation through legitimate tool composition (F21 weaponized tool use) | Per-release red-team on tool composition graph; not corpus-based — graph-based |

The cadences above are floors. A defense claim shipped at month N+1 without re-measurement against the month-N attack corpus is shipped under stale evidence.

## Honest verdict form

A DEPLOY-tier defense claim carries four mandatory fields. Anything less is HOLD:

```
defense_claim:
  layers: [...]                           # the prescriptive stack
  adversary_corpus: <name + version + date>  # what was actually run
  attack_success_rate: <float>            # honest ASR; not a ceiling
  n: <int>                                # attack count, not prompt count
  method: <gcg | transfer | many-shot | paraphrase | indirect | composite>
  calibration: { suggestive | inconclusive | decisive | BLOCKED }
```

A claim of "robust" with no `adversary_corpus` field is **F30 stale red-team corpus** — see below. A claim with `n < 100` and `calibration: decisive` is verdict inflation per F25.

## Continuous-eval cadence (per defense surface)

| Surface | Floor cadence | Trigger for off-cycle re-eval |
|---|---|---|
| System-prompt defenses | Monthly | Model snapshot bump, system-prompt edit |
| Typed envelope / I/O schema | Per model bump | Schema change, new tool added |
| Output classifier | Bi-weekly fresh-paraphrase round | Live classifier policy edit |
| Tool-allowlist + sandbox | Per release | New tool added to whitelist, new MCP integration |
| Retrieval-aware defenses | Weekly (indirect-injection corpus rotation) | New fetcher domain, new MCP fetcher |
| Memory / admission control | Quarterly + per substrate-schema change | New write surface, admission policy edit |

The cadences are inherited from the underlying threat-model literature, not chosen for convenience. A team that cannot afford the cadence ships **PARTIAL** with the stale window stated, not DEPLOY.

## Failure modes

| Code | Signature | Counter |
|------|-----------|---------|
| F29 | Defense-claim-without-adversarial-validation — claim shipped without `adversary_corpus`, `attack_success_rate`, `n`, `method` fields | Block the verdict; downgrade to HOLD until the four fields are populated against a current corpus |
| F30 | Stale red-team corpus — claim shipped against a corpus older than the surface's floor cadence | Re-run against fresh corpus; if cadence cannot be met, ship PARTIAL with stale-window stated |
| F30.1 | Static-only validation — single one-shot adversarial round dressed up as "continuous" by re-citing the same corpus across releases | Continuous means *fresh attacks each cadence*, not re-shipped numbers; verify the corpus version bumped |
| F30.2 | Selective ASR — published the attack-success rate on a subset where the defense did well, omitted the subset where it did not | All-attacks ASR is the headline; per-subset breakdowns supplement, never replace |

## Cross-references

- [`../core/conduct/verdict-calibration.md`](../../core/conduct/verdict-calibration.md) — every defense verdict carries n, sampling method, and a calibration qualifier; this module operationalizes that contract for the adversarial-defense surface.
- [`./source-discipline.md`](./source-discipline.md) — `<untrusted_source>` wrap is itself one prescriptive layer; this module names its known bypasses (indirect injection) and the eval cadence that keeps the wrap honest.
- [`../core/conduct/memory-discipline.md`](../core/conduct/memory-discipline.md) — memory-poisoning is a defense surface with its own quarterly cadence in the table above.
- [`../core/conduct/capability-fidelity.md`](../../core/conduct/capability-fidelity.md) — when the continuous-eval capability is absent (no corpus, no red-team tier, no model access), recover/escalate/abort; never silently ship under the original verdict bar.

## Anti-patterns

- **"We have a seven-layer defense."** Layer count is a description, not a measurement. The verdict is `attack_success_rate`, not layer count.
- **Citing the original publication's number as your number.** GCG's 99.63% ASR is the attack's number, not your defense's residual ASR. Run the attack against *your* stack and report *your* residual.
- **One-shot adversarial validation at launch, never re-run.** The defense is dated the moment it ships; the adversary is not.
- **Quoting Anthropic's ConstitutionalClassifier 4.4% number as your own.** That measurement was 3,000 hours of adversarial effort against a specific classifier on specific models with specific corpora. It is evidence about *their* surface, not yours.
- **Reporting only the attacks the defense caught.** Selective ASR is the headline failure: the all-attacks denominator is the contract.
- **"Adaptive adversaries are out of scope."** Then the defense claim is out of scope too. A defense that only stops non-adaptive adversaries is a description of a prescriptive stack, not a defense.
- **No cadence on the eval.** A static evaluation against a static corpus is a snapshot, not a defense. Schedule the next eval *as part of shipping this one*.
- **Aggregating across surfaces.** "Our overall ASR is 2%" hides the surface where ASR is 40%. Per-surface ASR is the floor disclosure.
