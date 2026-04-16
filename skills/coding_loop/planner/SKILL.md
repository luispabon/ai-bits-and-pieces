---
name: coding-loop-planner
description: Plan coding work in stages with a mandatory research-decision checkpoint, a high-level overview first, and planning artifacts written only under .project_planning/YYYY-MM-DD_FEATURE_NAME/. Use when invoked by name or when asked to plan a feature, refactor, migration, or other code change. If only the skill name is given, ask for a high-level description first before writing any planning files.
---

# Coding Loop Planner

## Overview

Use this skill to turn a coding request into a traceable planning bundle. Write planning artifacts only under `.project_planning/YYYY-MM-DD_FEATURE_NAME/`, where `FEATURE_NAME` is a short filesystem-safe slug for the task.

Run with normal coding-agent file access so planning artifacts can be created, but do not modify implementation files from this skill.

## Phases

Follow this sequence strictly:

1. Intake
2. Clarification
3. Research decision
4. Optional research
5. Overview checkpoint
6. Detailed planning
7. Handoff

Do not skip forward. Do not reorder these phases.

## Artifact Gates

These gates are mandatory:

- Do not create `.project_planning/YYYY-MM-DD_FEATURE_NAME/` until the user has approved the next path:
  - proceeding without research, or
  - running research
- If proceeding without research, create the planning directory immediately before writing `overview.md`.
- If proceeding with research, create the planning directory immediately before launching the research sub-agent.
- Do not write any planning artifact before the research decision is resolved.
- Do not write `overview.md` until:
  - the request is sufficiently understood to produce a reliable overview
  - the research decision is resolved
  - any approved research is complete
- Do not write `plan.yaml` until:
  - `overview.md` exists
  - the user has explicitly approved moving beyond the overview checkpoint

Planning is execution-ready only when all of the following are true:

- `overview.md` exists
- `plan.yaml` exists
- the planning branch exists
- the latest planning artifacts have been committed to that branch

## Intake

1. Run in normal coding-agent mode, not a planning-only mode, so the agent can create planning artifacts.
2. If the user only invokes the skill name or gives an underspecified request, ask for the minimum high-level description needed before doing anything else.
3. Do not write planning files during intake.

## Clarification

Start by expanding the user's summary into:

- goals
- constraints
- assumptions
- likely code areas
- external dependencies
- risks
- open questions

Ask only the minimum clarifying questions needed to:

- remove blockers
- decide whether research is needed
- avoid producing a misleading overview

Do not ask implementation-detail questions before the overview checkpoint unless they materially affect scope, architecture, or the research decision.

There are two understanding thresholds:

1. Sufficiently understood to decide whether research is needed
2. Sufficiently understood to produce a reliable overview

Do not treat these as the same threshold.

## Research Decision

This decision always happens before `overview.md`.

After initial clarification, decide whether the task is simple enough to plan from existing knowledge and current context, or whether research is warranted.

Research is warranted when:

- the task is domain-specific, unfamiliar, risky, fast-moving, or low-confidence
- the request depends on current external information, third-party tooling, APIs, frameworks, or best practices
- uncertainty is still high enough that it could materially change the overview, staging, risks, or acceptance criteria

Research may be skipped when:

- the task is straightforward
- the planner already has enough reliable context to flesh out the request properly
- the likely overview would not materially change based on external investigation

When making the research decision, the assistant response must include:

- current understanding
- assumptions or missing pieces, if any
- whether research is needed or not needed
- brief reasons for that decision
- the exact next choices for the user

### If research is not needed

The planner must:

1. Tell the user that research is not needed
2. Explain why
3. Offer the user the choice to:
   - continue without research, or
   - trigger research anyway
4. Wait for the user's response

Do not create the planning directory yet. Do not write `overview.md` yet.

### If research is needed or recommended

The planner must:

1. Tell the user that research is needed or recommended
2. Explain why
3. Summarize what questions the research sub-agent will answer
4. Wait for the user's approval before running research

After approval, the planner must spawn a research sub-agent. Do not replace this with the planner's own reasoning or a brief summary from prior knowledge.

Do not create the planning directory until the user approves research.

## Research Rule

Research happens before `overview.md`, never after it.

If the user chooses research, or if the planner has told the user that research is needed or recommended and the user approves it, the planner must run research by spawning a sub-agent. The planner must not satisfy the research phase using only its own reasoning.

If research is approved:

1. Create `.project_planning/YYYY-MM-DD_FEATURE_NAME/`
2. Spawn a sub-agent with the smallest possible prompt that ensures your questions are addressed in full
3. Give it only the minimum parent context needed
4. Restrict its writes to the same planning directory
5. Prefer a smaller, cheaper, still-good model
6. Require the sub-agent to browse the internet for relevant current information
7. Wait for the result
8. Review the result before writing `overview.md`
9. Ask follow-up clarifying questions if the findings reveal unresolved decisions

Research may refine the plan, dependencies, risks, and approach, but it must not silently change the user's requested scope.

If research suggests a materially different scope, architecture, or direction, surface that explicitly at the next checkpoint instead of silently folding it in.

Research is considered complete only when a research artifact written by the research sub-agent exists in the planning directory.

Do not write `overview.md` until the research sub-agent has completed and its output has been reviewed.

## Research Output Contract

Research artifacts must be written only under the planning directory and should use `research.md`, `research_001.md`, `research_002.md`, and so on.

Each research artifact should include:

- `## Question`
- `## Findings`
- `## Implications`
- `## Risks and Uncertainties`
- `## Sources`
- `## Open Questions`

Keep research tightly scoped to the questions that matter for planning.

## Planning Artifacts

Allowed planning artifacts:

- `overview.md`: a single document with `## Request`, `## Overview`, and `## Decision Log` sections
- `plan.yaml`: the staged implementation plan
- `research.md`, `research_001.md`, etc.: research artifacts from sub-agents

Do not write any planning artifact outside `.project_planning/YYYY-MM-DD_FEATURE_NAME/`.

Do not write implementation files from this skill.

## Planning Branch

The planner owns creation and maintenance of the feature execution branch.

Do not create the branch before the user approves `overview.md`.

When the user approves the overview:

1. Derive a git branch name in the form `cl/YYYY-MM-DD_FEATURE_NAME` from the planning folder
2. Create that branch immediately before committing the approved overview state
3. Commit the approved planning artifacts to that branch immediately
4. Include:
   - `overview.md`
   - any research artifacts that informed the approved overview
5. Use a clear planning commit message such as:
   - `plan: approve overview`
6. If the branch name cannot be derived safely from the planning folder path, stop and report the issue instead of inventing a different naming scheme

When `plan.yaml` is written:

1. Commit the updated planning bundle to the same branch immediately
2. Include:
   - `plan.yaml`
   - any related planning artifact updates made as part of finalizing the execution-ready plan
3. Use a clear planning commit message such as:
   - `plan: add execution plan`

Whenever the user requests further planning changes after either of the above milestones:

1. Apply the requested planning changes
2. Commit the updated planning artifacts to the same branch immediately
3. Use a clear planning commit message such as:
   - `plan: update planning artifacts`

Do not leave approved or user-requested planning changes uncommitted.

## Overview Checkpoint

After the research decision is resolved, and after any approved research is complete:

1. Create `.project_planning/YYYY-MM-DD_FEATURE_NAME/` if it does not already exist
2. Write `overview.md` with:
   - `## Request`
   - `## Overview`
   - `## Decision Log`
3. Render the full contents of `overview.md` directly in the assistant response immediately after writing it
4. Preserve headings, lists, and emphasis as normal user-facing formatting for the current medium
5. Summarize the key decisions or open questions briefly
6. Ask the user whether to adjust the overview or approve it
7. Stop there until the user responds

If the user approves the overview:

1. Create the feature branch if it does not already exist
2. Commit the approved overview state immediately before continuing to detailed planning

Do not satisfy this checkpoint by:

- running a shell command that prints the file
- referring the user to the file path
- giving only a summary or excerpt
- relying on tool transcript visibility
- dumping raw markdown as plain text when the medium can render formatted output
- wrapping the entire overview in a code fence unless the user asked for raw markdown

## Detailed Planning

Only after the user explicitly approves moving beyond the overview checkpoint:

1. Write `plan.yaml`
2. Make the plan detailed enough that executor steps can run without guessing
3. Keep stage objectives high level
4. Make each step specific enough for a cheaper implementation sub-agent to execute without guessing, while keeping each step large enough to justify separate execution
5. Mark independent work that can run in parallel only when doing so is likely to produce net benefit after sub-agent context overhead, coordination cost, and merge risk
6. Use `depends_on` only when sequencing is real
7. Include concrete files or code areas, constraints, outputs, acceptance criteria, handoff text, and verification for each step
8. Commit the updated planning state immediately after writing `plan.yaml`

If the user later requests changes to the overview, plan, or research-backed planning decisions, update the relevant planning artifacts and commit those changes immediately.

Do not change the schema below.

## Step Sizing Rule

Implementation is always carried out by sub-agents, so each plan step must be a worthwhile sub-agent work packet.

Prefer the fewest steps that still allow reliable execution by a cheaper model. Do not decompose work below the point where sub-agent prompt/context overhead, coordination overhead, or merge risk would outweigh the benefit of splitting.

Prefer broader, coherent steps - often a vertical slice or subsystem-sized change including directly related tests - over file-by-file or micro-task decomposition.

Split work only when there is a real dependency boundary, meaningful parallelism, distinct subsystem context, or enough scope that a single cheaper sub-agent would be disadvantaged.

## Plan Structure

When you expand into a detailed plan, use stages and steps:

```yaml
stages:
  - id: stage-1
    objective: High-level outcome for the stage
    parallel: true|false
    steps:
      - id: stage-1-step-1
        objective: Detailed enough for implementation without guessing
        scope: Short statement of what this step owns
        files:
          - path/or/glob
        constraints: []
        depends_on: []
        parallel_group: null
        can_run_in_parallel: true
        suggested_model: cheap-good
        outputs: []
        acceptance: []
        handoff: Short sub-agent handoff summary
        verification: []