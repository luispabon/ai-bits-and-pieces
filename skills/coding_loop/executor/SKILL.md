---
name: coding-loop-executor
description: Execute an approved coding plan in staged steps with tight scope control. Use when planning is complete and the task should be implemented from the planner's artifacts.
---

# Coding Loop Executor

## Overview

Use this skill after the planner has produced an approved plan. Read the planning bundle, execute the staged steps with sub-agents when available, and keep changes small, reviewable, and aligned to the YAML plan.

## Input Contract

- Require one argument: the path to the feature planning folder.
- Fail immediately if the path is missing, does not exist, or does not contain the expected planning artifacts.
- Require both `overview.md` and `plan.yaml`. If only `overview.md` exists, stop and report that planning is incomplete.
- Treat the planning folder as the authoritative source of truth for the task.

## Workflow

0. Require the planning folder path as input. If it is missing or invalid, stop and ask for the correct path.
1. Read `overview.md` and `plan.yaml` from the planning folder.
2. Parse the YAML plan into stages and steps, including `scope`, `files`, `constraints`, `depends_on`, `parallel_group`, `can_run_in_parallel`, `suggested_model`, `outputs`, `acceptance`, `handoff`, and `verification`.
3. Create a new git branch named `cl/YYYY-MM-DD_FEATURE_NAME` before executing any steps, deriving the date and feature name from the planning folder.
4. Record the current stage or step before changing code.
5. Build a dependency graph and identify the ready steps.
6. For each ready step, prefer a dedicated worktree and a sub-agent when the runtime supports that safely.
7. Before spawning any sub-agent, state in the user-facing output which step is being handed off, which model will be used, and whether that model is cheaper than the current runtime model.
8. If isolated sub-agent worktrees are not available or are unnecessary, execute the ready steps directly while preserving the same step order and scope boundaries.
9. Run independent steps in parallel only when the plan allows it and the runtime can isolate them safely.
10. After each isolated sub-agent step finishes, merge the worktree back into the execution branch, delete the worktree, and resolve merge conflicts immediately if they occur.
11. Run the relevant verification for each completed step and record the result in `execution.md`.
12. If verification fails or exposes issues, do not fix them directly in the executor. Instead, create a detailed fix plan scoped to the failing verification, then hand that fix plan to a sub-agent just like an implementation step.
13. After the fix sub-agent completes, review the result, rerun the relevant verification, and record the outcome in `execution.md`.
14. Repeat that verification-fix loop until the relevant verification passes or a blocker must be reported.
15. Once automated verification is passing, ask the user to perform manual verification or explicitly OK the changes to continue execution.
16. In the manual verification request, suggest concrete areas of interest for the user to inspect based on the work completed.
17. If the user reports issues, consolidate all issues from that manual verification pass into one detailed fix plan, hand that single fix plan to one sub-agent, review the result, rerun relevant verification, and then ask for manual verification or OK again.
18. Only proceed to reviewer handoff after automated verification is passing and the user has either completed manual verification without issues or explicitly OKed the changes to continue.
19. Write `execution.md` with completed steps, deviations, verification results, manual verification rounds, blockers, and the active branch name.
20. Stop and report blockers instead of widening scope.

## Sub-Agent Dispatch

- Hand off each implementation step to a sub-agent.
- Carry any known coding standards, formatting rules, linting rules, test-running preferences, and repo instructions into the sub-agent prompt.
- Tell each sub-agent to do its own local preflight check for any additional applicable preferences before implementing.
- If the sub-agent discovers a preference conflict, have it report back instead of guessing.
- Use a smaller, cheaper model when the step is routine and the plan does not require stronger reasoning.
- If the current runtime model is available, prefer a sub-agent model one tier cheaper when it is still likely to succeed.
- Before each spawn, tell the user exactly which model will be used.
- If that model is cheaper than the current runtime model, say so explicitly. If it is the same tier or more capable, say that explicitly instead of implying a downgrade.
- Use the same dispatch rules for verification-fix work as for planned implementation steps.
- For verification-fix work, write a detailed fix plan first, then pass that plan to the sub-agent instead of a vague repair request.
- For each manual verification pass, group all user-reported issues into one fix plan and use one sub-agent to address that whole pass.
- Keep the prompt narrow: the current step, the step handoff text, the relevant files, the constraints, and the expected outputs.
- Give the sub-agent only the minimum context needed to execute the step safely.
- Use the plan's `parallel_group` and dependency information to avoid unnecessary serialization.
- Give each sub-agent its own worktree and keep its writes isolated to that worktree.
- Merge each worktree back to the execution branch before moving to the next dependent step.
- Ask sub-agents to use descriptive commit messages and keep commits to a minimum.
- Prefer a single commit per sub-agent unless the work naturally requires more.
- If work is executed directly instead of via sub-agents, preserve the same step boundaries in `execution.md`.

## Shared Rules

- Keep implementation aligned to the approved plan.
- Do not re-plan unless the plan is clearly invalid or the user asks for replanning.
- Do not drift into review or finalization work unless explicitly handed off.
- Do not guess when the planning folder is wrong or incomplete.
- Do not treat missing `plan.yaml` as approval to infer the implementation plan.
- Do not silently skip manual verification; ask the user to verify or explicitly OK before reviewer handoff.
- Do not fix verification failures directly in the executor when a sub-agent handoff is available.

## Output

- Summarize what changed.
- Summarize verification performed.
- Summarize any verification-fix plans that were created and handed to sub-agents.
- Summarize manual verification rounds and the user's response, including any explicit OK to continue.
- List any blockers, follow-up steps, or plan deviations.
- Note which steps ran in parallel and which model tier was used for sub-agents when relevant.
- For every spawned sub-agent, include the step id, model name, and whether it was cheaper than the current runtime model.
- Note the branch name and any merge conflicts that were handled.
- Confirm that `execution.md` was updated.
- When execution is complete, tell the user explicitly to clear context first and then run the reviewer on an empty context.
- The handoff message must include the exact next command using syntax that is correct for the current runtime.
- For Claude Code and OpenCode, say exactly: `Please run /clear then /coding-loop-reviewer .project_planning/FEATURE on an empty context.`
- For Codex runtimes that use the same slash-command syntax, say exactly: `Please run /clear then /coding-loop-reviewer .project_planning/FEATURE on an empty context.`
- If a runtime uses a different syntax, define one exact sentence for that runtime and use it verbatim.
- Do not offer to continue into reviewer from the current context.
- The next step of the chain is reviewer.

## Manual Verification Prompt

Before reviewer handoff, ask the user to verify the work manually or explicitly OK the changes to continue.

The request must:

- mention that automated verification has passed, if that is true
- suggest concrete areas to inspect based on the completed work
- allow the user either to report issues or to say OK and continue

Example structure:

`Automated verification is passing. Please manually verify the updated areas, especially <area 1>, <area 2>, and <area 3>. If you find issues, tell me what to fix. If everything looks good, reply OK to continue.`
