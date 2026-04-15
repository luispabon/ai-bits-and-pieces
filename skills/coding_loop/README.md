# Coding Loop

This directory documents the `coding_loop` skill family.

## Chain

The chain is ordered as:

`planner` -> `executor` -> `reviewer` -> `finaliser`

## Shared Contract

- Treat each skill as a single responsibility step in the chain.
- Preserve the same planning bundle across the chain unless a later step explicitly updates it.
- Keep work scoped to the current task and the current repository.
- If the input is too vague for the current step, ask the minimum clarifying question needed to continue.
- Later steps must receive the planning folder path explicitly. If it is missing, stop and ask for it before proceeding.
- The planning folder is the authoritative handoff boundary for the chain.

## Planner

- Gather the request.
- Ask for a high-level description if needed.
- Delay file creation until the feature is understood.
- Write the planning bundle and staged plan.
- When planning is complete, tell the user to clear context with `/clear` and to run `/coding-loop-executor .project_planning/FEATURE` next.

## Executor

- Consume the approved plan.
- Require the planning folder path before doing anything.
- Create branch `cl/YYYY-MM-DD_FEATURE_NAME` before executing steps.
- Give each implementation step its own worktree and merge it back after the sub-agent finishes.
- Resolve merge conflicts as they happen.
- Ask sub-agents to keep commits minimal, with one descriptive commit preferred unless more are needed.
- Implement only the current stage or step.
- Prefer isolated, incremental changes.
- Report blockers instead of guessing.
- When execution is complete, tell the user to clear context with `/clear` and to run `/coding-loop-reviewer .project_planning/FEATURE` next.

## Reviewer

- Review the implemented changes against the plan.
- Require the planning folder path before doing anything.
- Look for regressions, missing tests, or scope drift.
- Report findings before suggesting cleanup.
- When review is complete, tell the user to clear context with `/clear` and to run `/coding-loop-finaliser .project_planning/FEATURE` next.

## Finaliser

- Confirm the requested work is complete.
- Require the planning folder path before doing anything.
- Capture any residual risk, follow-up, or cleanup.
- Summarize the outcome clearly and concisely.
- When finalization is complete, tell the user that the loop is finished and clear context with `/clear` if they are starting a new loop.
