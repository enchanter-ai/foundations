# vis

<p align="center">
  <img src="docs/assets/hero.png" alt="Vis mascot" width="1280">
</p>

<p>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-3fb950?style=for-the-badge"></a>
  <img alt="7 packages" src="https://img.shields.io/badge/Packages-7-bc8cff?style=for-the-badge">
  <img alt="33 conduct modules" src="https://img.shields.io/badge/Modules-33-58a6ff?style=for-the-badge">
  <img alt="12 engines" src="https://img.shields.io/badge/Engines-12-d29922?style=for-the-badge">
  <img alt="29 failure codes" src="https://img.shields.io/badge/F--codes-F01%E2%80%93F29-f0883e?style=for-the-badge">
  <a href="https://www.repostatus.org/#active"><img alt="Project Status: Active" src="https://www.repostatus.org/badges/latest/active.svg"></a>
</p>

> **An @enchanter-ai product — dependency-free, model-agnostic, dogfooded across the ecosystem.**

The behavioral substrate for building durable AI agents — conduct, engines, taxonomy, and the math behind all three.

**33 conduct modules. 12 engines. 29 failure codes. 9 recipes. Zero runtime dependencies.**

> A 12-line `paginate()` function has an off-by-one. The PR title says *"fix the off-by-one in pagination."* The agent rewrites it as a `Paginator` class, adds a docstring nobody asked for, renames `perPage` to `n`, and slips the actual one-character fix onto line 4. Type-check passes. Tests pass. The bug is fixed, but the codebase grew a new pattern nobody decided on, and the diff buries the fix under 30 lines of unsolicited refactor (F04 task drift).
>
> **vis** is the four-stance conduct rule (`think-first / simplicity / surgical / goal-driven`) that turns the same task into a one-line diff: `start = page * perPage` → `start = (page - 1) * perPage`. The rule existed before this PR — the agent never saw it. After `@shared/vis/packages/core/conduct/discipline.md` lands in `CLAUDE.md`, instinct shifts at the lexical level.
>
> Tokens loaded: ~700. Modules pulled: 1. Refactors prevented: every PR after.

## TL;DR

**In plain English:** Most agent stacks ship with prompts, tools, and hopes. The thing that actually keeps an agent from refactoring code you didn't ask it to touch, or pushing to main after you said not to, isn't another tool — it's a behavior rule that survives the long context. vis is the dependency-free pile of those rules, plus the math, taxonomy, and host recipes around them.

**Technically:** 33 conduct modules across 7 conduct packages (`core` / `skills` / `orchestration` / `safety` / `web` / `memory` / `cost`), plus a `hooks` package shipping 11 runtime advisory hooks (the **enchanter-hooks** plugin, installable via the vis marketplace). 12 algorithmic engines with paper-backed derivations (Aho-Corasick pattern detection, Shannon entropy, Beta-Bernoulli trust scoring, Markov drift, Hunt-Szymanski LCS, Zhang-Shasha tree-edit, Tarjan SCC, Wald SPRT, Jaccard-cosine boundary segmentation, contextual LLM bandit, agentproof DFA, sycophancy calibration). 29 named failure codes (F01–F29) with testable counters, mapped to a 5-axis hybrid taxonomy (memory / reflection / planning / action / system); per-code taxonomy detail files and 21 incident-response runbooks currently cover F01–F21. 9 adoption recipes (Claude Code, OpenAI Agents SDK, Cursor, LangChain, Pydantic-AI, BAML, raw system-prompt, eval-harnesses, stupid-agent-review). Zero runtime dependencies — pure prose + math, loadable into any system that accepts text instructions.

## Origin

**vis** takes its name from the **Latin word for binding-force** — the substrate that makes a rule load-bearing instead of merely descriptive. In Roman jurisprudence *vis* was the binding authority behind a contract; in tabletop tradition (Ars Magica) *vis* was the raw magical material no spell could compile without. Both meanings carry the same idea: foundational substance that higher abstractions rely on but rarely name. The framework is dogfooded — vis runs on its own conduct while editing its own conduct; refusing drift, sycophancy, and silent failure is part of the contract, not a goal.

The question this framework answers: *Is the rule actually load-bearing?*

## Who this is for

- **Teams building production agents** who have watched type-check-passing PRs ship runtime regressions, and want a conduct layer that survives a 200-turn context.
- **Platform / infra engineers** wiring multiple agent frameworks (Claude Code, OpenAI Agents SDK, Cursor, LangChain) who need one source-of-truth for behavior, not seven divergent rule sets.
- **Reviewers tired of reviewing scope creep** from over-helpful agent edits, who want surgical-changes enforced upstream of the diff.
- **AI safety / alignment researchers** wanting a flat F-code taxonomy plus a 5-axis structural mapping that compounds across observations.
- **Adopters of a host framework** (LangChain, BAML, Pydantic-AI) who need concrete wiring recipes, not blog-post pseudocode.

Not for:

- Single-shot prompts or weekend prototypes — loading 33 conduct modules into a 300-token task is overkill.
- Teams who've never observed a production agent drift, hallucinate a tool call, or refuse a benign request. The framework grows by patterns named *after* observed failures; if you haven't seen any, you don't need the counter yet.

## Contents

- [Why this exists](#why-this-exists)
- [What's in the box](#whats-in-the-box)
- [Quickstart — 30 seconds](#quickstart--30-seconds)
- [Pick the modules that match your problem](#pick-the-modules-that-match-your-problem)
- [Wire it up](#wire-it-up)
- [What you actually get](#what-you-actually-get)
- [Before / after](#before--after)
- [Design principles](#design-principles)
- [What this won't do](#what-this-wont-do)
- [Resolved structural decisions](#resolved-structural-decisions)
- [Security & compliance roadmap](#security--compliance-roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

---

## Why this exists

Every team building agents rediscovers the same problems:

- *"Why did Claude push to main even though we said not to?"* — instruction attenuation in long contexts.
- *"Why does it keep refactoring code I didn't ask it to touch?"* — task drift, no surgical-changes rule.
- *"Why is this trust score swinging so wildly?"* — Beta-Bernoulli with no prior; one observation flips the verdict.
- *"Why is the same bug recurring across sessions?"* — no precedent log; the agent forgets what failed last week.
- *"Why did our test suite pass but the migration break in prod?"* — self-certification, no independent verification.
- *"Why does the subagent keep ignoring the rules we wrote?"* — descriptive prose doesn't enforce; conduct never reached the subagent.
- *"Why are two of our agents working at cross-purposes?"* — inter-agent misalignment, not in the original failure taxonomy.

The fixes for these are well-known to people who've shipped agents at scale. They're scattered across blog posts, internal docs, and folklore. **vis consolidates them into a single dependency-free framework.**

---

## What's in the box

The repo is a packages-monorepo. Each package owns a slice of the framework (conduct rules, engines, taxonomy, recipes, tests) so adopters can pull just the area they need.

```
vis/
├── packages/
│   ├── core/                        ← foundation: layering invariants + canonical taxonomy + ABI tooling
│   │   ├── conduct/                 ← 20 baseline behavior modules (discipline, context, verification,
│   │   │                              delegation, tool-use, hooks, precedent, precedent-freshness,
│   │   │                              tier-sizing, doubt-engine, failure-modes, capability-fidelity,
│   │   │                              verdict-calibration, metacognition, reversibility-foresight,
│   │   │                              prior-art-discovery, substrate-consumption, sunk-cost-iteration,
│   │   │                              context-budget)
│   │   ├── taxonomy/                ← F01–F14 (generation / action / reasoning) + axes.md
│   │   ├── runbooks/                ← F01–F14 incident-response runbooks
│   │   ├── scripts/                 ← conduct-abi-check.sh, conduct-sync.sh
│   │   ├── glossary.md              ← unified terminology
│   │   ├── anti-patterns.md         ← cross-cutting catalog of what not to do
│   │   └── CLAUDE.md                ← repo-level instructions for agents editing core
│   ├── skills/                      ← author-facing skill conduct + host recipes
│   │   ├── conduct/                 ← formatting.md, skill-authoring.md
│   │   └── recipes/                 ← 8 adoption recipes (claude-code, openai-agents, cursor,
│   │                                  langchain, pydantic-ai, baml, system-prompt,
│   │                                  stupid-agent-review)
│   ├── orchestration/               ← multi-agent + engines
│   │   ├── conduct/                 ← eval-driven-self-improvement, multi-turn-negotiation,
│   │   │                              task-decomposition, inference-substrate
│   │   ├── engines/                 ← 12 algorithmic primitives (pattern-detection, entropy-analysis,
│   │   │                              trust-scoring, drift-detection, lcs-alignment, tree-edit,
│   │   │                              scc, sprt, boundary-segmentation, llm-bandit, agentproof,
│   │   │                              calibration)
│   │   ├── docs/                    ← self-test.md (A/B fixture methodology), vis-lock-spec.md
│   │   └── templates/               ← bootstrap.sh / .ps1, sessionstart hook, vis-verify.yml
│   ├── safety/                      ← multi-agent + alignment cluster, compliance & operator wiring
│   │   ├── conduct/                 ← refusal-and-recovery.md
│   │   ├── taxonomy/                ← F15–F21 (multi-agent + alignment)
│   │   ├── runbooks/                ← F15–F21 incident-response runbooks
│   │   ├── compliance/              ← SOC 2, ISO 42001, FedRAMP, NIST AI RMF readiness
│   │   ├── security/                ← pentest + synthetic-fire artifacts
│   │   └── operator-wiring-2026-05/ ← Day-1 Datadog / Sentry / PagerDuty / Slack / Splunk wiring
│   ├── web/                         ← web-fetched-evidence discipline
│   │   └── conduct/                 ← web-fetch, research-pipeline, source-discipline,
│   │                                  citation-verification, mcp-research-discipline,
│   │                                  adaptive-adversary-baseline, provider-resilience
│   ├── memory/                      ← memory hygiene
│   │   └── conduct/                 ← memory-hygiene.md
│   ├── cost/                        ← cost + latency + eval harnesses
│   │   ├── conduct/                 ← cost-accounting.md, latency-budgeting.md
│   │   └── recipes/                 ← eval-harnesses.md
│   └── hooks/                        ← runtime advisory hooks (the enchanter-hooks plugin)
│       ├── hooks/hooks.json         ← 11 hooks: SessionStart(compact) / PreToolUse / PostToolUse
│       ├── scripts/                 ← compact-checkpoint, secret-scan, config-self-edit-guard,
│       │                              substrate-engine-write-guard, append-only-log-edit-guard,
│       │                              artifact-authorship-guard, reversibility-guard, debug-hygiene,
│       │                              post-write-validate, stale-pathref-guard, machine-path-leak-guard
│       └── .claude-plugin/          ← plugin.json (installable via the vis marketplace)
├── docs/                            ← cross-cutting docs: architecture overview, ADRs
│                                       (0001 four-layers, 0002 taxonomy expansion),
│                                       CROSS_REPO_VERSIONING.md
├── roadmap-2026/                    ← security & compliance engagement packages
├── install.sh                       ← one-liner installer (full | starter | minimal)
└── package.json                     ← changesets meta-package for cross-repo versioning
```

Counts as of the latest tag: **33 conduct modules** across core / skills / orchestration / safety / web / memory / cost · **12 engines** in `orchestration/engines/` · **29 failure codes** (F01–F29) defined in `core/conduct/failure-modes.md`; per-code taxonomy detail files and **21 runbooks** cover F01–F14 (core) and F15–F21 (safety) · **9 recipes** (8 in `skills/recipes/` + `cost/recipes/eval-harnesses.md`) · **11 runtime advisory hooks** in `hooks/` (the **enchanter-hooks** plugin).

---

## Quickstart — 30 seconds

One-liner installer (vendored copy at `./shared/vis`, no `.git` footprint):

```bash
curl -fsSL https://raw.githubusercontent.com/enchanter-ai/vis/main/install.sh | sh
```

Pick a smaller install if you want less surface:

```bash
curl -fsSL https://raw.githubusercontent.com/enchanter-ai/vis/main/install.sh | sh -s -- --mode starter   # packages/core + packages/skills + packages/web
curl -fsSL https://raw.githubusercontent.com/enchanter-ai/vis/main/install.sh | sh -s -- --mode minimal   # packages/core only
```

Or as a git submodule (history preserved, pinned via parent repo):

```bash
curl -fsSL https://raw.githubusercontent.com/enchanter-ai/vis/main/install.sh | sh -s -- --submodule
```

Full options: `install.sh --help`.

---

## Pick the modules that match your problem

Don't load everything. Start with the failure mode you're seeing, pull only the modules that counter it.

| You're seeing… | Pull these modules |
|---|---|
| Unsolicited refactors, scope creep | `discipline.md` |
| Rules ignored deep in long sessions | `discipline.md` + `context.md` |
| Test passes but prod breaks | `discipline.md` + `verification.md` |
| Subagents going rogue | `delegation.md` + `verification.md` |
| Same bug returns next week | `precedent.md` + `failure-modes.md` |
| Token costs spiraling | `tier-sizing.md` + `cost-accounting.md` |
| Working memory degrading across turns | `context.md` + `memory-hygiene.md` |
| Subagent doesn't inherit conduct | `delegation.md` (Conduct propagation) |
| Need runtime gates, not just rules | `hooks.md` (Starter patterns) + `packages/skills/recipes/claude-code.md` |
| Latency unpredictable in long workflows | `latency-budgeting.md` |
| Agent refuses benign requests / over-refuses | `refusal-and-recovery.md` |
| Want to learn from observed failures | `eval-driven-self-improvement.md` + `precedent.md` |
| User pressures across turns until you flip | `multi-turn-negotiation.md` + `doubt-engine.md` |
| Doubt-engine F01-counter prose isn't measurable | `packages/orchestration/engines/calibration.md` |
| Failure happened — need incident steps | `packages/core/runbooks/F<NN>.md` (F01–F14) or `packages/safety/runbooks/F<NN>.md` (F15–F21) |
| Want to A/B-validate a module's impact | `packages/orchestration/docs/self-test.md` |
| Evaluating agent conduct | `packages/cost/recipes/eval-harnesses.md` |

The **production starter pack** is `discipline.md` + `context.md` + `verification.md` + `failure-modes.md` — about 4k tokens, catches the long tail.

---

## Wire it up

### Claude Code

In your project's `CLAUDE.md`:

```markdown
- @shared/vis/packages/core/conduct/discipline.md
- @shared/vis/packages/core/conduct/verification.md
- @shared/vis/packages/core/conduct/tool-use.md
- @shared/vis/packages/core/conduct/failure-modes.md
```

For runtime enforcement (not just description), wire hooks per [`packages/skills/recipes/claude-code.md`](packages/skills/recipes/claude-code.md) § Enforcement wiring. The framework now includes copy-paste shell skeletons in [`packages/core/conduct/hooks.md`](packages/core/conduct/hooks.md) § Starter patterns — PreToolUse deny, PostToolUse inject, Stop notify. Or install them ready-made — `/plugin marketplace add enchanter-ai/vis` then `/plugin install enchanter-hooks@vis` — the **enchanter-hooks** plugin ships 11 advisory, fail-open hooks (post-compaction checkpoint, secret scan, config self-edit guard, substrate-engine-write guard, append-only-ledger guard, artifact-authorship guard, bash reversibility guard, debug-artifact hygiene, syntax validation, stale-pathref guard, machine-path-leak guard) that activate without editing `settings.json`.

### OpenAI Agents SDK

```python
from pathlib import Path
from agents import Agent

ROOT = Path("vendor/vis/packages/core/conduct")
modules = ["discipline", "verification", "tool-use", "delegation"]
instructions = "\n\n".join((ROOT / f"{m}.md").read_text() for m in modules)

agent = Agent(name="MyAgent", instructions=instructions, model="gpt-5", tools=[...])
```

Full guide: [`packages/skills/recipes/openai-agents.md`](packages/skills/recipes/openai-agents.md).

### Cursor

Drop pointer rules into `.cursor/rules/`:

```markdown
---
description: Coding discipline — think-first, simplicity, surgical, goal-driven
globs: ["**/*"]
alwaysApply: true
---

@.cursor/vis/packages/core/conduct/discipline.md
```

Full guide: [`packages/skills/recipes/cursor.md`](packages/skills/recipes/cursor.md).

### Anything else (raw API, llama.cpp, Ollama, …)

```python
system_prompt = "\n\n".join(
    (vis_root / "packages" / "core" / "conduct" / f"{m}.md").read_text()
    for m in ["discipline", "verification", "tool-use"]
)
```

Full guide: [`packages/skills/recipes/system-prompt.md`](packages/skills/recipes/system-prompt.md).

---

## What you actually get

### Behavior rules that survive long contexts

[`packages/core/conduct/`](packages/core/conduct/) ships twenty baseline modules; additional area-specific conduct lives under `packages/{skills,orchestration,safety,web,memory,cost}/conduct/`. The lightest pull-in is just `discipline.md` (~700 tokens) — four stances (think-first, simplicity, surgical, goal-driven) that catch the majority of unsolicited refactors, premature actions, and over-helpful substitutions.

A heavier pull-in adds `context.md` (U-curve placement, checkpoint protocol), `verification.md` (independent checks, dry-run for destructive ops), and `failure-modes.md` (the F-code taxonomy summary). That's the production starter pack.

For long-running multi-agent work, add `packages/memory/conduct/memory-hygiene.md` (selective-add over All-Add, prune triggers) and `packages/cost/conduct/cost-accounting.md` (budget gates expressed as delegation-prompt conditions, not runtime tooling).

### Subagents that actually inherit the rules

A conduct module the subagent never sees can't shape its behavior. [`packages/core/conduct/delegation.md`](packages/core/conduct/delegation.md) now documents three propagation patterns: **full inherit** (paste everything; safest, highest token cost), **whitelist inject** (only modules the tool whitelist touches; best signal-to-cost), and **discovery file** (a single `AGENTS.md` consumed at spawn; cross-tool portable). Pick by tier and lifetime.

### Cross-vendor schema alignment

[`packages/skills/conduct/skill-authoring.md`](packages/skills/conduct/skill-authoring.md) maps the framework's SKILL.md frontmatter against MCP, OpenAI Apps SDK, Cursor `.mdc`, and Claude Code subagent frontmatter. Adopters who already publish skills under one of those schemas can align without rewriting; adopters who don't get a recommended convention.

### Algorithmic primitives, with derivations

[`packages/orchestration/engines/`](packages/orchestration/engines/) is the math-grounded layer. Each engine has six required sections: Problem, Formula, Decision rule, Complexity, Implementation pattern, Failure modes. No vibe-coded scoring functions; if it ships in this folder, it has a paper reference and a Big-O.

| Engine | Use case |
|--------|----------|
| [`pattern-detection.md`](packages/orchestration/engines/pattern-detection.md) | Multi-pattern text scan in linear time (Aho-Corasick) |
| [`entropy-analysis.md`](packages/orchestration/engines/entropy-analysis.md) | Detect generated tokens / secrets without a pattern list (Shannon) |
| [`trust-scoring.md`](packages/orchestration/engines/trust-scoring.md) | Online posterior estimate of a probability (Beta-Bernoulli) |
| [`drift-detection.md`](packages/orchestration/engines/drift-detection.md) | Catch unproductive loops in event streams (Markov + EMA) |
| [`lcs-alignment.md`](packages/orchestration/engines/lcs-alignment.md) | Measure how much of an anchor sequence survived (Hunt-Szymanski) |
| [`tree-edit.md`](packages/orchestration/engines/tree-edit.md) | Quantify structural change between trees (Zhang-Shasha) |
| [`scc.md`](packages/orchestration/engines/scc.md) | Find dependency cycles in O(V+E) (Tarjan) |
| [`sprt.md`](packages/orchestration/engines/sprt.md) | Decide between two hypotheses with minimum samples (Wald SPRT) |
| [`boundary-segmentation.md`](packages/orchestration/engines/boundary-segmentation.md) | Cluster events into tasks (Jaccard + cosine + time-decay) |
| [`llm-bandit.md`](packages/orchestration/engines/llm-bandit.md) | Route each invocation to the optimal model tier by cost-adjusted reward (contextual MAB) |
| [`agentproof.md`](packages/orchestration/engines/agentproof.md) | Verify an agent workflow statically before execution — graph checks + temporal-policy DFA *(status: concept)* |
| [`calibration.md`](packages/orchestration/engines/calibration.md) | Sycophancy-rate calibration via progressive/regressive ratios — turns `doubt-engine.md` F01 prose into a measurable axis (SycEval) |

### A failure taxonomy that compounds

Free-text learning notes don't compound. Tagged ones do. [`packages/core/conduct/failure-modes.md`](packages/core/conduct/failure-modes.md) defines 29 canonical codes (F01–F29); the per-code taxonomy packages currently detail 21 of them, split across two packages — F01–F14 in [`packages/core/taxonomy/`](packages/core/taxonomy/) (generation / action / reasoning) and F15–F21 in [`packages/safety/taxonomy/`](packages/safety/taxonomy/) (multi-agent + alignment). Each code has a precise signature, a testable counter, and an escalation rule:

**Generation failures** — `packages/core/taxonomy/`
- F01 Sycophancy · F02 Fabrication · F03 Context decay · F04 Task drift · F05 Instruction attenuation

**Action failures** — `packages/core/taxonomy/`
- F06 Premature action · F07 Over-helpful substitution · F08 Tool mis-invocation · F09 Parallel race · F10 Destructive without confirmation

**Reasoning failures** — `packages/core/taxonomy/`
- F11 Reward hacking · F12 Degeneration loop · F13 Distractor pollution · F14 Version drift

**Multi-agent and alignment failures** — `packages/safety/taxonomy/`
- F15 Inter-agent misalignment · F16 Task-verification skip · F17 System-design brittleness · F18 Goal-conflict insider behavior · F19 Alignment faking *(awareness)* · F20 Sandbagging *(awareness)* · F21 Weaponized tool use

**Cross-session and build-discipline failures** — defined in `packages/core/conduct/failure-modes.md` (no per-code detail file yet)
- F22 Capability-absence substitution · F23 Sunk-cost iteration · F24 Substrate-blindness · F25 Verdict inflation · F26 Reversibility blindness · F27 Stale-precedent reliance · F28 Skill-discoverability failure · F29 Premise-unvalidated build

Tag every entry in your failure log with one code. Now you can aggregate. Now you can learn.

The multi-agent cluster (F15–F17) maps to the MAST taxonomy (arxiv 2503.13657); the alignment cluster (F18–F21) draws from Anthropic, OpenAI, and DeepMind safety research. F19 and F20 are awareness codes — log them if observed; the counter is red-team probes and blind capability evaluation, not runtime detection.

A parallel **5-axis layer** lives at [`packages/core/taxonomy/axes.md`](packages/core/taxonomy/axes.md) — every F-code is mapped to one of memory / reflection / planning / action / system (per AgentErrorTaxonomy, arxiv 2509.25370). Use flat codes for grep-able logs, axes for structural pressure analysis. The hybrid is intentional and documented in [`docs/adr/0002-taxonomy-expansion.md`](docs/adr/0002-taxonomy-expansion.md).

### Adoption guides, not just docs

Recipes give you the wiring for seven host platforms plus an eval-harness reference. No hand-waving — concrete file paths, concrete config, a verification step you can actually run. Host recipes live in [`packages/skills/recipes/`](packages/skills/recipes/); the eval-harness reference lives in [`packages/cost/recipes/`](packages/cost/recipes/).

| Recipe | What it covers |
|--------|----------------|
| [`claude-code.md`](packages/skills/recipes/claude-code.md) | `@`-imports, hook enforcement wiring, scope precedence |
| [`openai-agents.md`](packages/skills/recipes/openai-agents.md) | Python SDK integration, `Agent.clone()`, guardrail patterns |
| [`cursor.md`](packages/skills/recipes/cursor.md) | `.cursor/rules/` activation, scoped pull-ins |
| [`langchain.md`](packages/skills/recipes/langchain.md) | Middleware list enforcement, LangGraph interrupts, propagation |
| [`pydantic-ai.md`](packages/skills/recipes/pydantic-ai.md) | `Agent[Deps, Output]` generics, output validation, tool retries |
| [`baml.md`](packages/skills/recipes/baml.md) | Function-shaped LLM calls, Jinja prompt blocks, `BamlError` |
| [`system-prompt.md`](packages/skills/recipes/system-prompt.md) | Raw API / llama.cpp / Ollama wiring |
| [`eval-harnesses.md`](packages/cost/recipes/eval-harnesses.md) | Benchmark suite reference: τ²-bench, AgentDojo, AgentHarm, SYCON-Bench, etc. |
| [`stupid-agent-review.md`](packages/skills/recipes/stupid-agent-review.md) | Cheap-tier mechanical verifier auditing higher-tier output; the runtime behind A/B rule-efficacy testing |

---

## Before / after

A small but real example:

**Before** the conduct is loaded — agent context: *"fix the off-by-one in pagination":*

```diff
- function paginate(items, page, perPage) {
-   const start = page * perPage;
-   return items.slice(start, start + perPage);
- }
+ class Paginator {                          // unsolicited refactor (F04)
+   constructor(items) { this.items = items; }
+   /** Returns the requested page of items. */  // unsolicited docs (F04)
+   page(p, n) {
+     const start = (p - 1) * n;            // the actual fix
+     return this.items.slice(start, start + n);
+   }
+ }
```

**After** loading `packages/core/conduct/discipline.md`:

```diff
  function paginate(items, page, perPage) {
-   const start = page * perPage;
+   const start = (page - 1) * perPage;
    return items.slice(start, start + perPage);
  }
```

Same task. Surgical change. No drift.

---

## Design principles

1. **Model-agnostic.** Examples may name a vendor; modules don't bind to one. Tier names are `top-tier / mid-tier / low-tier`, never Opus / Sonnet / Haiku in the body.
2. **Drop-in or à la carte.** Pick the modules you want; ignore the rest. No required entry point.
3. **Zero runtime dependencies.** Pure prose + math. Loadable into any system that accepts text instructions. Engines ship pseudocode, not Python packages.
4. **Honest numbers.** Engine docs include failure modes alongside the math. We tell you when the algorithm is the wrong tool. New modules acknowledge unverified assumptions explicitly (e.g., `agentproof.md` is marked `status: concept`).
5. **Layered, not bundled.** Conduct rules don't embed engine math; engines don't make decisions; taxonomy doesn't run code; recipes don't invent rules. The layering is the discipline.

See [`docs/architecture/README.md`](docs/architecture/README.md) for the structure and [`docs/adr/0001-four-layers.md`](docs/adr/0001-four-layers.md) for why.

---

## What this won't do

- **Force the agent to obey.** Memorized rules attenuate over long contexts. For load-bearing rules, pair with a runtime hook — the [`packages/core/conduct/hooks.md`](packages/core/conduct/hooks.md) starter patterns are a real path to enforcement, not a wish.
- **Replace evals.** Conduct shifts default behavior on average; per-task evals still own task quality. See [`packages/cost/recipes/eval-harnesses.md`](packages/cost/recipes/eval-harnesses.md) for benchmarks targeting agent conduct specifically.
- **Provide reference implementations.** Engines describe the math; runnable code lives in adopter projects.
- **Compete with prompt-engineering tools.** This is a *foundation* — it composes with your prompts, doesn't replace them.

---

## Resolved structural decisions

Two architectural questions that earlier versions of the framework deferred have now been resolved:

- **Taxonomy structure (resolved 2026-05-05).** Flat F-codes (current) AND 5-axis modular structure (AgentErrorTaxonomy, arxiv 2509.25370) — both layers ship. Hybrid path: F01–F29 stays as the operational identifier; [`packages/core/taxonomy/axes.md`](packages/core/taxonomy/axes.md) maps each code to one of memory / reflection / planning / action / system. Documented in [`docs/adr/0002-taxonomy-expansion.md`](docs/adr/0002-taxonomy-expansion.md).
- **F19/F20 placement (resolved 2026-05-05).** Awareness codes stay in `packages/safety/taxonomy/` (alongside F15–F18 and F21) with explicit `(awareness)` flag at the top of each file. Adopters who don't need alignment-research codes can filter by tag rather than skip the package.

What remains genuinely external — and only adopters can close:

- **Self-test fixtures.** [`packages/orchestration/docs/self-test.md`](packages/orchestration/docs/self-test.md) ships the A/B fixture methodology; **19 of 19 modules** have shipped fixtures + **3 rounds of validation tests** as of 2026-05-06. On **Sonnet 4.6**: 5 of 19 show clear behavioral delta — **4 of those 5 replicate cleanly across 3+ runs** (`discipline` 3/3, `formatting` 4/4, `latency-budgeting` 3/3, `eval-driven-self-improvement` 3/3); the 5th (`context`) shows reliable module impact across 3 runs but variable operationalization (treatments apply different module-prescribed structural rules across runs). 12 show no Sonnet delta — confirmed as **training contamination by 2 OOD falsifiability tests** (synthetic modules with fabricated numerics + fabricated vocabulary; baselines did not reach for either). On **Haiku 4.5** (full 14 of 14 Sonnet-no-delta sample): **8 of 14 show measurable behavioral delta**. A previously-headlined "inverse delta" finding for `skill-authoring v2` was retracted after replication (3/3 reruns produced minimal tools — original was N=1 variance). The honest claim, now supported by 3 rounds of replication + 2 OOD controls + full-tier coverage: *modules act as documentation of behavior on Sonnet and as runtime guidance on Haiku.* See [`packages/orchestration/docs/self-test.md`](packages/orchestration/docs/self-test.md) § Validation rounds 1-3 for the full reading. [`packages/skills/recipes/stupid-agent-review.md`](packages/skills/recipes/stupid-agent-review.md) ships the runtime architecture; [`packages/orchestration/tests/runner.py`](packages/orchestration/tests/runner.py) ships a reference Python runner (syntax + fixture parsing validated; end-to-end API execution still adopter-side); [`.github/workflows/self-test.yml`](.github/workflows/self-test.yml) ships an example CI workflow.
- **Real-world adoption signal.** Until a downstream project reports on living with the conduct, every module is a hypothesis. The Sonnet/Haiku split data suggests adopters should weight module loading by their subject tier — full set load on Haiku, selective load on Sonnet.

---

## Security & compliance roadmap

The path from "pentested" to audit-grade 100/100 — phased, dependency-graphed, costed — lives in [`roadmap-2026/`](roadmap-2026/):

- [`MACRO_ROADMAP.md`](roadmap-2026/MACRO_ROADMAP.md) — Phase 0 (≤1wk inline criticals) through Phase 4 (FedRAMP ATO, 24mo+). Dependency graph, exit criteria per phase, year-1 cash envelope ($70k–$1M).
- [`pentest-engagement-package.md`](roadmap-2026/pentest-engagement-package.md) — 7-firm vendor comparison + RFP + kickoff checklist.
- [`soc2-engagement-package.md`](roadmap-2026/soc2-engagement-package.md) — 7-CPA-firm comparison + observation-start prerequisites.
- [`iso-42001-engagement-package.md`](roadmap-2026/iso-42001-engagement-package.md) — 10-cert-body comparison + Stage 1 application prep.
- [`fedramp-engagement-package.md`](roadmap-2026/fedramp-engagement-package.md) — Hosted control plane MVP design + 3PAO RFP.
- [`production-fire-and-tune-launch.md`](roadmap-2026/production-fire-and-tune-launch.md) — 3-cohort design-partner pilot playbook.
- [`operator-wiring-kickoff.md`](roadmap-2026/operator-wiring-kickoff.md) — Day-1 walkthrough for Datadog / Sentry / PagerDuty / Slack / Splunk wiring.
- [`alignment-research-watch.md`](roadmap-2026/alignment-research-watch.md) — Literature survey + blind-eval methodology for the research-frontier residuals.

Phase 0 (inline criticals — R-018/19/20) shipped in hydra `v2.0.1`. Phase 1+ requires external auditors, customer time, or operator credentials; the engagement packages above are the contract.

---

## Contributing

Issues and PRs welcome. The contribution bar:

- **New conduct module:** justify why it doesn't fit an existing module. Pick the package whose scope the module belongs to (core / skills / orchestration / safety / web / memory / cost). The framework is dependency-free; modules are prose, not packages.
- **New engine:** include reference, complexity, failure modes, and pseudocode. No language-specific runtime calls. Engines ship in `packages/orchestration/engines/`.
- **New failure code (F30+):** observed in 3+ independent contexts, testable counter, no overlap with existing codes. See [`packages/core/taxonomy/README.md`](packages/core/taxonomy/README.md) § How to extend. Multi-agent / alignment codes go in `packages/safety/taxonomy/`.
- **New recipe:** concrete adoption steps + a verification check. Host recipes go in `packages/skills/recipes/`.

See [`packages/core/CLAUDE.md`](packages/core/CLAUDE.md) for repo-level editing rules. The framework is dogfooded — contributors are expected to follow the conduct while editing the conduct.

---

## License

MIT. See [LICENSE](LICENSE). Use freely, including commercially. No warranty.

---

## Acknowledgments

Built on the shoulders of well-studied algorithms — Aho & Corasick, Shannon, Tarjan, Wald, Hunt & Szymanski, Zhang & Shasha, Jaccard, Salton — and the operational lessons of every engineer who's debugged an LLM agent in production. Recent additions draw on published research from Anthropic, OpenAI, DeepMind, Berkeley/Stanford (MAST), and the practitioner community surveyed at scale.

If your team adopts vis and finds something missing, [open an issue](https://github.com/enchanter-ai/vis/issues). The framework grows by accumulation of named patterns, not by speculation.
