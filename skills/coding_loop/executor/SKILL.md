---
name: coding-loop-executor
description: Execute an approved coding plan in staged steps with tight scope control. Use when planning is complete and the task should be implemented from the planner's artifacts.
---

# Coding Loop Executor

## Overview

Use this skill after the planner has produced an approved plan. Read the planning bundle, execute the staged steps with sub-agents, and keep changes small, reviewable, and aligned to the YAML plan.

## Input Contract

- Require one argument: the path to the feature planning folder.
- Fail immediately if the path is missing, does not exist, or does not contain the expected planning artifacts.
- Treat the planning folder as the authoritative source of truth for the task.

## Workflow

0. Require the planning folder path as input. If it is missing or invalid, stop and ask for the correct path.
1. Read `overview.md` and `plan.yaml` from the planning folder.
2. Parse the YAML plan into stages and steps, including `parallel`, `depends_on`, `parallel_group`, `can_run_in_parallel`, `suggested_model`, `outputs`, and `verification`.
3. Create a new git branch named `cl/YYYY-MM-DD_FEATURE_NAME` before executing any steps, deriving the date and feature name from the planning folder.
4. Confirm the current stage or step before changing code.
5. Build a dependency graph and identify the ready steps.
6. For each ready step, create a dedicated worktree and hand that worktree to a sub-agent.
7. Run independent steps in parallel when the plan allows it.
8. After each sub-agent finishes, merge the worktree back into the execution branch, delete the worktree, and resolve merge conflicts immediately if they occur.
9. Keep the executor focused on orchestration, not direct implementation.
10. Run the relevant verification for each completed step and record the result.
11. Stop and report blockers instead of widening scope.

## Sub-Agent Dispatch

- Hand off each implementation step to a sub-agent.
- Carry any known coding standards, formatting rules, linting rules, test-running preferences, and repo instructions into the sub-agent prompt.
- Tell each sub-agent to do its own local preflight check for any additional applicable preferences before implementing.
- If the sub-agent discovers a preference conflict, have it report back instead of guessing.
- Use a smaller, cheaper model when the step is routine and the plan does not require stronger reasoning.
- If the current runtime model is available, prefer a sub-agent model one tier cheaper when it is still likely to succeed.
- Keep the prompt narrow: the current step, the relevant files, and the expected outputs.
- Give the sub-agent only the minimum context needed to execute the step safely.
- Use the plan's `parallel_group` and dependency information to avoid unnecessary serialization.
- Give each sub-agent its own worktree and keep its writes isolated to that worktree.
- Merge each worktree back to the execution branch before moving to the next dependent step.
- Ask sub-agents to use descriptive commit messages and keep commits to a minimum.
- Prefer a single commit per sub-agent unless the work naturally requires more.

## Shared Rules

- Keep implementation aligned to the approved plan.
- Do not re-plan unless the plan is clearly invalid or the user asks for replanning.
- Do not drift into review or finalization work unless explicitly handed off.
- Do not guess when the planning folder is wrong or incomplete.

## Output

- Summarize what changed.
- Summarize verification performed.
- List any blockers, follow-up steps, or plan deviations.
- Note which steps ran in parallel and which model tier was used for sub-agents when relevant.
- Note the branch name and any merge conflicts that were handled.
- When execution is complete, tell the user to clear context with `/clear` and then run `/coding-loop-reviewer .project_planning/FEATURE`.
- The next step of the chain is reviewer.
