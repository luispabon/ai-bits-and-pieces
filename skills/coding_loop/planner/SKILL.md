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
5. Write `overview.md` with separate sections for the user's request, the high-level plan overview, and the decision log.
6. Reproduce the full `overview.md` contents in the assistant response immediately after writing it. Do not treat the file as an internal artifact only.
7. Use the displayed overview as a required discussion and approval checkpoint. Ask for corrections, missing detail, or approval to continue.
8. Do not write `plan.yaml`, start research, or hand off to executor until the user has explicitly asked to proceed beyond the overview checkpoint.
9. If the task is ambiguous, risky, or unfamiliar, recommend research as part of the overview discussion. If confidence is already high and the task is straightforward, skip research.
10. Ask clarifying questions whenever the request is ambiguous or blocked, before or after research.
11. If research is needed or chosen after the overview checkpoint, spawn a sub-agent with the smallest possible prompt, a cheaper but still capable model, and write permission limited to the same planning directory.
12. Wait for research to finish, review it, then use it to refine the plan.
13. Make it explicit that planning is not execution-ready until `plan.yaml` exists.
14. Write `plan.yaml` only after user approval and only when the task is detailed enough that executor steps can be run without guessing.
15. Treat the later chain steps as `executor`, `reviewer`, and `finaliser`; hand off cleanly to those skills once planning is complete.
16. When the planner is finished, give the user the planning folder path and the next skill to run. If the runtime supports slash commands, you may suggest `/clear` and `/coding-loop-executor .project_planning/FEATURE`.

## Planning Artifacts

- `overview.md`: a single document with `## Request`, `## Overview`, and `## Decision Log` sections.
- `plan.yaml`: the staged implementation plan.
- `research.md`, `research_001.md`, etc.: research artifacts from sub-agents.
- Planning is execution-ready only when both `overview.md` and `plan.yaml` exist.
- `overview.md` must be reproduced in the assistant response and discussed before `plan.yaml` is created.

## Overview Checkpoint

After writing `overview.md`:

1. Print its full contents directly in the assistant response.
2. Summarize the key decisions or open questions briefly.
3. Ask the user whether to adjust the overview or proceed.
4. Stop there until the user responds.

Do not create `plan.yaml` in the same turn unless the user explicitly asks to continue planning after seeing the overview text in the assistant response.

Do not satisfy this checkpoint by:

- running a shell command that prints the file
- referring the user to the file path
- giving only a summary or excerpt
- relying on tool transcript visibility

## Research Rule

Recommend research when the task is domain-specific, unfamiliar, or low-confidence. If research is chosen:

1. Keep the sub-agent prompt narrowly scoped.
2. Give it only the minimum parent context needed.
3. Restrict its writes to `.project_planning/YYYY-MM-DD_FEATURE_NAME/`.
4. Prefer a smaller, cheaper, still-good model.
5. Wait for the result, analyze it, then decide whether more research or clarification is needed.

## Chain Handoff

- After planning is complete, give the user the planning folder path and point them to executor. If the runtime supports slash commands, you may suggest `/clear` and `/coding-loop-executor .project_planning/FEATURE`.
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
```

Rules for the plan:

- Keep stage objectives high level.
- Make each step specific enough that it can be executed without guessing.
- Explicitly mark independent work that can run in parallel.
- Use `depends_on` only when sequencing is real.
- Include concrete files or code areas, constraints, outputs, acceptance criteria, handoff text, and verification for each step.
- Do not write implementation files from this skill. If the user wants execution, hand off to the normal coding workflow.

## Interaction Policy

- If the request is too vague to plan, ask for the minimum high-level description needed to disambiguate it.
- Present the overview first in the assistant response, not just on disk or via tool output, and hold back detailed implementation until the user wants it.
- Keep the first response brief enough to allow discussion at the architecture level.
- If the user asks for more detail, expand the staged plan incrementally.
- Keep all writes confined to the planning directory, including sub-agents.
