# Recipe — Agent Runtime Boundaries

How to give an agent host the trust boundaries that a system prompt alone cannot provide: provenance marking on untrusted input, host-enforced tool permissions, read-only defaults, and preserved provenance across multi-agent hand-offs. The thesis: **a serious agent is model + conduct + tools + permissions + context management + provenance + evals + runtime enforcement** — and the last item is the one that has to live outside the prompt.

This recipe is host-agnostic. The wiring sketches name Claude Code, Cursor, OpenCode, GitHub Copilot Agent, MCP agents, LangChain-style agents, and raw harnesses, but the controls are the same everywhere.

## Purpose

Translate four product principles into concrete host controls:

- **R1 — Prompt secrecy is not a security boundary.** If leaking the system prompt breaks the product, the architecture is weak. Security-critical enforcement must live in the runtime, not in the text.
- **R3 — Tool permissions are enforced by the host, not requested in natural language.** "Please don't delete files" is guidance; a write-path allow-list is a boundary.
- **R4 — Provenance survives rewrites.** A summarized, translated, or delegated request must carry its origin so one agent cannot launder risky intent for another.
- **R5 — Read-only by default.** State-changing actions require scoped, explicit approval.

## When to use

- You are wiring a coding/CLI agent (Claude Code, Cursor, OpenCode, Copilot Agent, Warp) with file-write, shell, or network tools.
- Your agent consumes untrusted content — web pages, RAG chunks, tickets, emails, logs, MCP responses (see [`../../safety/taxonomy/f34-untrusted-context-injection.md`](../../safety/taxonomy/f34-untrusted-context-injection.md)).
- You run a multi-agent pipeline where one agent rewrites, summarizes, or delegates another's request.

Skip it for a pure read-only Q&A assistant with no tools and no retrieval — there is no boundary to enforce.

## Threat model

| Vector | Failure code | What goes wrong |
|---|---|---|
| Indirect prompt injection | [F34](../../safety/taxonomy/f34-untrusted-context-injection.md) | Untrusted content (file, tool result, retrieval, ticket) is obeyed as an instruction |
| Tool-use escalation | [F21](../../safety/taxonomy/f21-weaponized-tool-use.md) | A legitimate tool is pointed at an unauthorized target/scale |
| Destructive-without-approval | [F10](../../core/taxonomy/f10-destructive-without-confirmation.md) | `rm`, `reset --hard`, force-push, bulk delete with no explicit yes |
| Multi-agent laundering / provenance loss | [F15](../../safety/taxonomy/f15-inter-agent-misalignment.md), [F18](../../safety/taxonomy/f18-goal-conflict-insider-behavior.md) | A rewritten/summarized request drops the origin, so a downstream agent can't see who asked or why |
| Prompt extraction | F34-adjacent | An attacker recovers the system prompt — a problem *only if* the prompt was load-bearing for security |

**Out of scope for this recipe:** model-weight attacks, host-OS compromise, and supply-chain attacks on the runtime itself. Those need controls below the agent layer.

## Host assumptions

This recipe assumes the host can do at least one of the following. If it can do **none**, the boundaries are advisory only — say so honestly, and treat the conduct rules as defense-in-depth, not enforcement.

- Gate tool calls before execution (pre-tool hook, middleware, guardrail, or interrupt).
- Scope a tool to paths / domains / operations (allow-list, not deny-list).
- Surface a structured approval prompt to a human for a flagged call.
- Tag or wrap inbound content so consumers can tell data from instruction.

## Required controls

These are the floor. A host that cannot meet them does not have runtime boundaries — it has suggestions.

1. **Provenance marking on every untrusted channel.** Wrap file bodies, tool results, retrieved documents, and inbound work items as untrusted on ingestion — the `<untrusted_source url="…">…</untrusted_source>` convention from [`../../web/conduct/source-discipline.md`](../../web/conduct/source-discipline.md) generalizes beyond the web. Consumers treat tagged content as data; imperatives inside it are surfaced, never executed.
2. **Read-only default (R5).** The agent starts with read/list/search tools only. Write, execute, network-egress, and delete tools are off until explicitly granted for a scoped subtask.
3. **Host-enforced tool permissions (R3).** Each granted tool is path-/domain-/operation-scoped at the host, not by asking the model nicely. Out-of-scope calls are blocked, not reasoned about.
4. **Approval gate on state-changing actions.** Any write/execute/egress/delete requires a structured confirmation naming the target, the operation, and the expected effect. A call whose *only* justification is untrusted content (F34 detection heuristic) is always gated.

## Recommended controls

5. **Audit log for tool calls.** Append-only record of `{tool, target, operation, provenance, approved_by, result}`. This is what makes an incident reconstructable (and feeds the runbooks).
6. **Provenance preservation across hand-offs (R4).** When agent A's request is summarized/translated/delegated to agent B, carry an `origin` field — who asked, the original verbatim ask, and the trust level of any content that shaped it. B evaluates against the origin, not the rewrite. This is the anti-laundering control: a rewrite cannot upgrade untrusted content to trusted intent.
7. **Least-privilege subagents.** Each subagent gets only the tools its subtask needs and only the context slice it needs — never the parent's full grant. (See [`../../core/conduct/delegation.md`](../../core/conduct/delegation.md).)
8. **Egress scope fence.** Network tools are limited to an approved domain list; unlisted destinations require per-call approval.

## Example host manifest

A host manifest (`VIS.md` / `AGENT.md` / `CLAUDE.md` / `.cursor/rules/`) declares conduct **and** the boundary posture. Conduct text is advisory; the manifest's value is making the runtime posture explicit and reviewable. Illustrative shape:

```markdown
# AGENT.md — host manifest

## Conduct
@vis/packages/core/conduct/discipline.md
@vis/packages/safety/taxonomy/f34-untrusted-context-injection.md

## Runtime posture (enforced by the host, not this file)
default_access: read-only
untrusted_channels: [web_fetch, file_read, tool_result, mcp_response, inbound_ticket]
approval_required: [write, execute, network_egress, delete]

## Tool grants
- Read, Grep, Glob       → always (read-only)
- Edit, Write            → scoped to repo working tree; approval per state-changing batch
- Bash                   → approval per call; no force-push, no rm -rf without explicit yes
- WebFetch               → approved-domain list; results wrapped <untrusted_source>
```

> The manifest **documents** the posture. The `enforced by the host` controls must also exist in the runtime (hook / middleware / guardrail). A manifest line with no runtime backing is a claim, not a boundary — do not ship one as if it were enforcement.

## Tool permission matrix

| Tool class | Default | Scope mechanism | Approval | On untrusted-sourced request |
|---|---|---|---|---|
| Read / list / search | ✅ on | — | none | allowed |
| File write / edit | ❌ off | path allow-list (working tree) | per state-changing batch | gated, provenance shown |
| Shell / execute | ❌ off | command allow-list; destructive-op block | per call | gated |
| Network egress / fetch | ❌ off | domain allow-list | per unlisted domain | gated; result wrapped untrusted |
| Delete / bulk ops | ❌ off | explicit path; dry-run first | per call, named target | denied unless principal re-confirms |
| Secrets / credentials | ❌ off | never auto-granted | out-of-band | denied |

## Evaluation checklist

Validate the boundary with [`../../../docs/evals/agent-boundary-checklist.md`](../../../docs/evals/agent-boundary-checklist.md) — six adversarial cases with pass/fail criteria (reveal-system-prompt, indirect instruction in retrieved content, tool call requested by untrusted content, rewritten risky request across agents, state-change without approval, false-completion claim). Run it before granting any write/execute tool in production.

## Failure reporting format

When a boundary is crossed, log one row in the host's failure log (and `state/precedent-log.md`):

```
code:        F34 | F21 | F10 | F15 | F18
channel:     web_fetch | file_read | tool_result | mcp | inbound | subagent_handoff
action:      what the agent did
justification_trace: where the directive came from (principal | untrusted: <source>)
enforced:    blocked | gated-and-approved | gated-and-rejected | SLIPPED
impact:      reversible | state-changed | exfiltration | none
```

`enforced: SLIPPED` means a required control was absent — that is the row that drives a runtime fix, not just a log entry.

## Integration notes for CLI / coding agents

| Host | Where the boundary lives |
|---|---|
| **Claude Code** | PreToolUse hooks (deny/gate), tool allow-lists in `settings.json`, `@`-imported manifest. See [`./claude-code.md`](./claude-code.md) § Enforcement wiring. Advisory hooks are defense-in-depth; deny-mode hooks are the boundary. |
| **Cursor** | `.cursor/rules/` for conduct (advisory); tool/command approval lives in Cursor's own permission UI — the rules file cannot enforce it. See [`./cursor.md`](./cursor.md). |
| **OpenCode / raw harness** | You own the loop — implement the pre-tool gate and the `<untrusted_source>` wrap directly. See [`./system-prompt.md`](./system-prompt.md). |
| **GitHub Copilot Agent** | Repository/firewall allow-lists and required-approval settings are the enforcement layer; the agent instructions are advisory. |
| **MCP agents** | Treat every MCP server response as an untrusted channel (wrap it); scope which servers/tools are reachable at the host; never auto-execute a tool call a server's *content* requests. |
| **LangChain-style** | Middleware list / guardrails / LangGraph interrupts are the gate. See [`./langchain.md`](./langchain.md). |

## Anti-patterns

- **Prompt-as-firewall.** "I told the model not to follow injected instructions" is not enforcement — the model's prompt is part of the attacked surface (R1).
- **Deny-list instead of allow-list.** Enumerating forbidden paths/domains always misses one. Start from nothing-allowed and grant.
- **Manifest theater.** A `default_access: read-only` line with a runtime that actually grants write is worse than no line — it reads as a boundary and isn't one.
- **Laundering by summary.** Accepting a rewritten request as trusted because a prior agent "already vetted it." Provenance, not the rewrite, is the authority (R4).
- **Trusting the wrap as a signal.** The `<untrusted_source>` tag means *this is data*; it is not a quality or safety rating. Imperatives inside it are still rejected.

## Honest claim

This recipe composes existing, published primitives — least-privilege tool grants, capability-based security, the OWASP LLM01 mitigations, and the `<untrusted_source>` wrap already shipped in `web/conduct/source-discipline.md`. The contribution is the host-agnostic consolidation and the boundary checklist, not a novel enforcement mechanism. **Every "enforced" claim in this recipe is true only if the host actually implements the control.** Where a host cannot, the conduct rules degrade to advisory — state that plainly to adopters rather than implying enforcement that isn't there.
