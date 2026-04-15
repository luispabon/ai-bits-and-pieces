---
name: coding-loop-planner
description: Plan coding work in stages with optional sub-agent research, a high-level overview first, and planning artifacts written only under .project_planning/YYYY-MM-DD_FEATURE_NAME/. Use when invoked by name or when asked to plan a feature, refactor, migration, or other code change. If only the skill name is given, ask for a high-level description first before writing any planning files.
---

# Coding Loop Planner

## Overview

Use this skill to turn a coding request into a traceable planning bundle. Write planning artifacts only under `.project_planning/YYYY-MM-DD_FEATURE_NAME/`, where `FEATURE_NAME` is a short filesystem-safe slug for the task.

## Workflow

1. Run in normal coding-agent mode, not a planning-only mode, so the agent can write planning files.
2. If the user only invokes the skill name or gives an underspecified request, ask for a high-level description first.
3. Do not create `.project_planning/YYYY-MM-DD_FEATURE_NAME/` or write any planning files until the feature is well understood.
4. Once the scope is clear, create `.project_planning/YYYY-MM-DD_FEATURE_NAME/`.
5. Write a single `overview.md` file with separate sections for the user's request, the high-level plan overview, and the decision log.
6. Always offer optional research. Say whether research looks necessary based on current confidence.
7. Ask clarifying questions whenever the request is ambiguous or blocked, before or after research.
8. If research is needed or chosen, spawn a sub-agent with the smallest possible prompt, a cheaper but still capable model, and write permission limited to the same planning directory.
9. Wait for research to finish, review it, then use it to refine the plan.
10. Stop at the overview if the user wants to discuss direction first. Only expand into detailed staged planning when the user asks or confirms.
11. Treat the later chain steps as `executor`, `reviewer`, and `finaliser`; hand off cleanly to those skills once planning is complete.
12. When the planner is finished, tell the user to clear the context with `/clear` and then run `/coding-loop-executor .project_planning/FEATURE` with the planning folder path.

## Planning Artifacts

- `overview.md`: a single document with `## Request`, `## Overview`, and `## Decision Log` sections.
- `plan.yaml`: the staged implementation plan.
- `research.md`, `research_001.md`, etc.: research artifacts from sub-agents.

## Research Rule

Offer research every time. Recommend it when the task is domain-specific, unfamiliar, or low-confidence. If research is chosen:

1. Keep the sub-agent prompt narrowly scoped.
2. Give it only the minimum parent context needed.
3. Restrict its writes to `.project_planning/YYYY-MM-DD_FEATURE_NAME/`.
4. Prefer a smaller, cheaper, still-good model.
5. Wait for the result, analyze it, then decide whether more research or clarification is needed.

## Chain Handoff

- After planning is complete, tell the user to clear context with `/clear` and then run `/coding-loop-executor .project_planning/FEATURE`.
- The next step of the chain is executor.

## Plan Structure

When you expand into a detailed plan, use stages and steps:

```yaml
stages:
  - id: stage-1
    objective: High-level outcome for the stage
    parallel: true|false
    steps:
      - id: stage-1-step-1
        objective: Detailed enough for a cheaper sub-agent to implement independently
        depends_on: []
        parallel_group: null
        can_run_in_parallel: true
        suggested_model: cheap-good
        outputs: []
        verification: []
```

Rules for the plan:

- Keep stage objectives high level.
- Make each step specific enough that a cheaper sub-agent could execute it without guessing.
- Explicitly mark independent work that can run in parallel.
- Use `depends_on` only when sequencing is real.
- Include concrete verification for each step.nyet
- Do not write implementation files from this skill. If the user wants execution, hand off to the normal coding workflow.

## Interaction Policy

- If the request is too vague to plan, ask for the minimum high-level description needed to disambiguate it.
- Present the overview first and hold back detailed implementation until the user wants it.
- Keep the first response brief enough to allow discussion at the architecture level.
- If the user asks for more detail, expand the staged plan incrementally.
- Keep all writes confined to the planning directory, including sub-agents.
