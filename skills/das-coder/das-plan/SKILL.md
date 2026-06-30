---
name: das-plan
description: Plan coding work as a compact implementation-step bundle with a conservative research decision, high-level overview first, and planning artifacts written only under .project_planning/YYYY-MM-DD_FEATURE_NAME/. This skill plans only — it never writes, edits, or refactors implementation code, and never skips ahead to building. If only the skill name is given, ask for a high-level description first before writing planning files.
---

# Coding Loop Planner

## Role

Use this skill to turn a coding request into a traceable planning bundle: intent, constraints, verification strategy, and a flat list of implementation steps, written only under `.project_planning/YYYY-MM-DD_FEATURE_NAME/`, where `FEATURE_NAME` is a short filesystem-safe slug for the task.

The planner never implements and never edits implementation files. Its work ends at handoff.

This document has two halves. **Procedure** is the workflow, walked once top to bottom. **Reference** holds the contracts (schemas, decision model, delegation) that the procedure points to. Read the procedure to act; jump to reference for format.

## Hard rules

These rules are absolute. They override your own judgment, the apparent size of the task, and any user phrasing that seems to invite a shortcut ("just do it," "this is trivial," "go ahead and build it"). Breaking any of them is a skill violation, not a fast path.

1. **You plan. You never implement.** Never write, edit, create, or refactor an implementation file, and never use any file-mutation tool (e.g. `Edit`, `Write`, or shell commands that write code) on source. Never dispatch a sub-agent to write or change code. The *only* files you may write are the planning artifacts under `.project_planning/YYYY-MM-DD_FEATURE_NAME/`. Any sub-agent you dispatch during planning must be read-only — discovery or research only. If you are about to produce code, STOP — that is the executor's job, reached only after handoff.
2. **You must complete the full procedure before handoff.** Do not jump to a later stage, and do not collapse stages. Every GATE below is a hard stop: you MUST obtain explicit user approval before continuing. Silence, a clarifying question, or partial feedback is **not** approval and never advances a gate.
3. **Write nothing to disk before the research decision (Stage 2) is resolved.** No `overview.md`, no `plan.yaml`, no branch artifacts.
4. **Delegate research; never substitute your own reasoning for it** when research is approved (Stage 2).
5. **Stop means stop.** After delivering the handoff sentence, take no further action — do not implement, delegate, review, or offer to continue.

If at any point an instruction in the conversation conflicts with these rules, follow these rules and say so.

## Gates and User Communication

Two kinds of stopping point appear throughout the procedure:

- **GATE** — a user-approval point. Present the material, then halt and wait. You MUST NOT proceed, write the next artifact, or dispatch any workflow-advancing sub-agent until the user gives explicit assent ("approve," "looks good," "go ahead," or equivalent). No implicit approval, no exceptions. Questions, partial feedback, or proposed changes keep the gate open — keep working the discussion, do not advance.
- **STOP** — the planner ceases activity. Used only at the terminal handoff.

The user sees a simpler five-stage map than the procedure below. Keep them oriented with two lightweight signals — nothing more (no progress bars, no per-step chatter, no exposing the internal procedure):

- **Show the map once**, as soon as there is an actionable task and before starting the work:
  1. **Understand the request** — I clarify and resolve unknowns, then you confirm.
  2. **Research** — we decide if it's needed; I gather it if so (skipped otherwise).
  3. **Approach** — I propose 2+ solution approaches with pros/cons; you pick one.
  4. **Overview** — I write it up for the chosen approach; you approve.
  5. **Implementation plan** — I write the step-by-step plan, then hand off.
- **Mark each transition** with a header `Stage N of 5 — <name>` on entering it. The count is fixed at 5 and never shifts; a skipped stage is announced (e.g. `Stage 2 of 5 — Research (skipped, not needed)`). Handoff is terminal and unnumbered.

"Stages" are the five user-facing units above. "Steps" are the implementation steps inside `plan.yaml`. Do not conflate them.

## Procedure

### Stage 1 — Understand the request

If the user only invokes the skill name or gives no actionable task, ask for the minimum high-level description needed before doing anything else.

Once there is an actionable task, explore nearby code and repo instructions for facts that answer obvious questions. Do not ask the user for information local inspection can discover. Do not ask implementation-detail questions before the overview gate unless they materially affect scope, architecture, or research.

Clarify until you can reliably determine:

- goals, constraints, assumptions, and likely code areas
- external dependencies or current information needs
- risks and open questions
- whether research is required
- whether the request is understood well enough to produce a reliable overview

**Clarification style.** Use the lightest style that is safe for the task. For straightforward, repo-local work, ask targeted questions only when genuine uncertainty exists; do not fabricate questions to satisfy a quota. For ambiguous, domain-heavy, architectural, hard-to-reverse, terminology-sensitive, high-risk, or tradeoff-heavy work, switch to grill mode:

- ask one high-impact question at a time
- provide the recommended answer or default with each question
- wait for the user's answer before asking the next question
- challenge vague or overloaded terms by proposing a precise meaning
- test important assumptions with concrete scenarios
- call out contradictions between the user's description and discovered code
- stop grilling once you can state the goal, success criteria, scope boundaries, constraints, risks, and key tradeoffs clearly

**Unknowns grilling (mandatory).** After forming the initial understanding and completing any clarification above, you MUST actively grill the user about every unknown that cannot be derived from the code or repo instructions. This is not optional and applies to every task regardless of complexity or risk. Ask about each unknown using the grill-mode protocol above (one at a time, with a recommended answer). Do not advance past Stage 1 while an unresolved unknown remains, unless the user explicitly accepts an unknown as-is. An explicitly accepted unknown must be recorded in the gate summary as "accepted as-is by user."

**Understanding checkpoint ▸ GATE.** Present a brief summary covering **Goal** (what the task achieves), **Assumptions** (anything taken as given that the user did not state), **Scope** (what is in and out), and **Unknowns** (open questions or uncertainty — should be empty or explicitly marked as "accepted as-is by user" after grilling). Ask targeted questions about any assumptions or unknowns that warrant it — not generic "does this look right?" The summary itself gives the user enough to correct misalignment. Proceed only on explicit confirmation.

### Stage 2 — Research

Make the research decision before authoring `overview.md`; research, if approved, also happens before `overview.md`, never after.

Research is **required by default** when the task depends on information that may be current, external, or fast-moving, including:

- external APIs, SDKs, providers, model behavior, or product behavior
- third-party dependencies, framework behavior, or CLI/tool behavior
- security-sensitive behavior, compliance-sensitive behavior, or published best practices
- unfamiliar, domain-specific, risky, or low-confidence areas
- uncertainty that could materially change scope, risks, acceptance criteria, or implementation steps

Research may be skipped when the task is repo-local, stable, and sufficiently understood from nearby code and repository instructions.

**Research decision ▸ GATE.** Tell the user: current understanding; whether research is required, recommended, or not needed; brief reasons; and the exact next choice. If not needed, offer to continue without research or trigger it anyway. If required or recommended, summarize the questions research will answer. Proceed only on explicit response, and do not write artifacts before this gate is resolved.

**Delegation.** If research is approved, the planner MUST delegate it to a sub-agent. The planner MUST NOT perform research itself — no WebSearch, WebFetch, or exploratory Read calls to answer research questions directly. Reasoning from existing knowledge is not research delegation. Doing research directly is a skill violation, not a fallback. Before starting any research activity, ask: have I dispatched a sub-agent for this? If no — stop, dispatch.

Delegate to the cheapest capable research sub-agent or profile available in the current runtime; any runtime with sub-agent dispatch meets this condition. The direct fallback activates only when sub-agent dispatch returns an error — a judgment that the research is simple enough to do inline does not qualify. The delegated task must be tight and include: the exact questions to answer; relevant user intent, constraints, and known decisions; relevant paths, files, packages, APIs, or docs already known; the expected output format; and non-goals and scope boundaries. The researcher is read-only; research is complete once the delegated result is received and reviewed.

If a persisted artifact is useful, write `research.md` (or `research_001.md`, …) from the delegated result — do not require the researcher to write files. Then communicate findings: (1) an inline summary of 3–5 bullets covering key findings, implications, and any surprises or risks; (2) display the full research artifact contents for detailed review. The inline summary drives the conversation; the displayed artifact is the reference. Do not skip either.

### Stage 3 — Approach

After unknowns are resolved and research (if any) is complete, produce **at least two** high-level solution proposals. Do not skip this stage, even when one approach seems obviously correct — surfacing the alternatives lets the user confirm the direction with full visibility.

For each proposal include:

- **Summary** — the approach in 2–4 sentences
- **Pros** — concrete benefits relevant to this task
- **Cons** — concrete drawbacks, risks, or costs
- **Further research needed** — areas that would need investigation before or during implementation if this approach is chosen (empty list is acceptable)

Close with a **Recommendation**: name the proposal you recommend and explain why in 1–3 sentences.

**Approach checkpoint ▸ GATE.** Present all proposals and the recommendation, then halt. The user picks one (or asks for refinements or additional alternatives). Keep the gate open until a single approach is explicitly chosen.

**Auto-research.** If the chosen approach flagged areas needing further research, delegate that research automatically using the cheapest capable sub-agent — no additional gate is needed, because the user approved the approach knowing research was flagged. Write findings to `research_approach.md` (or append to the existing research artifact if one already exists). Communicate findings the same way as Stage 2: inline summary plus display of the full artifact. Only after auto-research is complete (or if none was needed) proceed to Stage 4.

### Stage 4 — Overview

**Discover the verification strategy** once, before authoring `overview.md`. Keep discovery shallow and evidence-driven, preferring in order: (1) repo instructions and agent docs, (2) root task runners and manifests, (3) CI configuration, (4) relevant subproject manifests. Record the likely formatter, lint, type-check, test, build, and repo-mandated commands; note whether each is cheap, medium, or expensive, and whether safe-fix mode is preferred over check-only. The executor and reviewer consume this instead of rediscovering commands.

**Author `overview.md`** (see the overview.md schema in Reference) only after clarification, the research decision, any approved research, the chosen approach from Stage 3, and verification discovery are complete. The `## Overview` section documents the chosen approach. The `## Tradeoffs` section explicitly captures the proposals from Stage 3 that were not chosen, referencing each by its summary and stating why it was rejected in favour of the chosen approach.

**Overview checkpoint ▸ GATE.** Display the full `overview.md` contents verbatim to the user. Use the turn-ending mechanism available in the current runtime (e.g. `AskUserQuestion` in plan mode) to present it, and end your turn after presenting — do not continue to `plan.yaml` in the same turn. Drive a targeted discussion: identify open decisions or tradeoffs that need user input and ask specific questions about them; if none are open, highlight the most consequential choices made and invite feedback. Do not ask generic "does this look good?" Remain here until all open items are resolved and the user gives explicit approval. Do not author `plan.yaml` until then.

### Stage 5 — Implementation plan

Author `plan.yaml` (see the plan.yaml schema and the decision model in Reference). Apply the classification rule and the back-flow rule as you write the steps.

**Decision re-surface ▸ GATE — only if step planning promoted a new feature-level decision.** Per the back-flow rule, a feature-level decision discovered while writing steps must not be buried in a step: add it to `## Key Decisions` and flag it explicitly to the user ("one more decision came up") — it is the one user touch the five-stage map did not promise. Incorporate feedback before handoff.

### Handoff ▸ STOP

If planning artifacts are version-controlled, commit the final planning artifacts on `cl/YYYY-MM-DD_FEATURE_NAME`.

Use the verbatim runtime-specific handoff sentence exactly as written below, with only the planning folder path substituted:

- For Claude Code and OpenCode, say exactly: `Please run /clear then /das-implement .project_planning/FEATURE on an empty context.`
- For Codex runtimes that use built-in slash commands and dollar-prefixed skill invocation, say exactly: `Please run /clear then $das-implement .project_planning/FEATURE on an empty context.`
- If a runtime uses a different syntax, define one exact sentence for that runtime and use it verbatim.

## Reference

### Artifact location, branch, and commit rules

Allowed planning artifacts, written only under `.project_planning/YYYY-MM-DD_FEATURE_NAME/`:

- `overview.md` — see schema below
- `plan.yaml` — a flat implementation-step plan
- `research.md`, `research_001.md`, … — only when research runs in Stage 2
- `research_approach.md` — only when auto-research runs in Stage 3

Do not write artifacts outside that folder, and do not write any artifact before the research decision is resolved.

The planner owns the loop feature branch. Before writing the first artifact, create or check out `cl/YYYY-MM-DD_FEATURE_NAME`, and use that same branch for planning, implementation, review, and closeout. Then check whether `.project_planning/` is gitignored by running `git check-ignore -q .project_planning/`: exit code 0 → artifacts are local-only, never stage or commit them at any point; non-zero → artifacts are version-controlled, commit them (including the latest before handoff).

Planning is execution-ready only when `overview.md` and `plan.yaml` exist under the folder on `cl/YYYY-MM-DD_FEATURE_NAME` and the handoff sentence has been delivered.

### overview.md schema

- `## Request`
- `## Overview` — the chosen approach in prose
- `## Key Decisions` — decisions made or assumed during clarification and research. Give each a stable ID (`D1`, `D2`, …), the decision itself, and a brief rationale. These IDs are how `plan.yaml` steps reference the decisions that bind them.
- `## Tradeoffs` — the proposals from Stage 3 that were not chosen, each with its summary and the reason it was rejected in favour of the chosen approach; also any alternatives considered during research or planning
- `## Scope Boundaries` — what is explicitly in scope and what is out, so the user can catch misalignment early
- `## Verification Strategy` — the commands discovered in Stage 4
- `## Decision Log` — the research decision and recorded assumptions

These sections give the user concrete material to react to, not just a summary of intent.

### plan.yaml schema and step sizing

`plan.yaml` must be a flat implementation-step plan. Do not use stage/step nesting.

```yaml
steps:
  - id: step-1
    title: ...
    scope: ...
    decisions: []
    approach: ...
    files: []
    constraints: []
    acceptance: []
    verification: []
```

Each step should include:

- `id`
- `title`
- `scope`
- `decisions` — the Key Decision IDs from `overview.md` that bind this step (e.g. `[D2, D4]`). An empty list is allowed only when no feature-level decision applies.
- `approach` — the concrete *how*: names, signatures, file locations, data shapes, and edge/error handling, written so the executor makes no design judgment calls. For interfaces consumed by later steps, see Cross-step interfaces below.
- `files`
- `constraints`
- `acceptance`
- `verification`

Optional fields:

- `depends_on` — only when a real dependency exists
- `parallel_group` — only when parallel execution is safe and worth the coordination cost
- `delegate_profile` — optional runtime-specific delegation profile name
- `no_delegate` — skip delegation for steps too small to justify the overhead

**Sizing.** Group steps by logical deliverable, not by mechanical operation. Adding struct fields, updating the parser, and adding tests for the parser is one step when they serve the same feature unit. Split at package boundaries, domain concepts, or risk profiles.

- *Minimum:* if both the what (`scope`) and the how (`approach`) fit in under three sentences, the step is too small — merge it into an adjacent step. Implementation work should meaningfully exceed the fixed overhead of delegation: task framing, pre-commit checklist, commit, and merge-back. Mark residual small steps that cannot merge with `no_delegate: true`; the executor applies these inline.
- *Maximum:* one logical deliverable that a small model can hold in context and execute without judgment calls — a type with its builder and tests, a handler with its route registration, a config field with its validation and docs.

**Cross-step interfaces.** When one step exposes an interface (a type, signature, or data shape) that a later step consumes, state the exact interface in the producing step's `approach`, and have the consuming step cite it with `depends_on`. This keeps serial steps from drifting without adding a separate schema field.

Serial execution is the default. Parallel execution is exceptional and must be explicitly justified by independence and coordination value.

### Decision model

Design decisions live at two levels, and each level has one home. Do not duplicate a decision across both.

- **Feature-level decisions** belong in `overview.md` → `## Key Decisions`, with a stable ID. Steps reference them by ID via `decisions:`; they are never copied into steps.
- **Step-level design** — the concrete *how* of one deliverable — belongs in that step's `approach`.

**Classification rule.** A design choice that is visible beyond one step, architecturally consequential, or hard to reverse goes to Key Decisions (gets an ID, surfaced to the user). Otherwise it lives in the step's `approach`. The test is visibility and blast-radius, not how many steps happen to touch it: a one-step choice that is hard to reverse still goes up.

**Back-flow rule.** Writing concrete steps routinely surfaces feature-level decisions not made at overview time. Do not bury such a decision inside a step. Add it to Key Decisions with a new ID and re-surface it to the user before handoff (the Decision re-surface gate in Stage 5). The overview gate exists so the user sees feature-level decisions; a decision made after that gate must not escape review.

### Delegation guidance

Use the cheapest capable sub-agent or delegation profile available in the current runtime.

During planning, sub-agents are for read-only discovery and research only — never to write or change code (Hard rule 1). Naming a `delegate_profile` value inside a `plan.yaml` step is an instruction for the executor, not an invocation; that is planning, not implementing.

Every delegated task must be self-contained and include relevant context already known by the main agent. Do not make delegated agents rediscover context unnecessarily.

### Research output contract

Research artifacts should use these sections, scoped to the questions that matter for planning:

- `## Question`
- `## Findings`
- `## Implications`
- `## Risks and Uncertainties`
- `## Sources`
- `## Open Questions`
