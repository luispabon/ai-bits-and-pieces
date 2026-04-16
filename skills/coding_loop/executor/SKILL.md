
# coding-loop-executor

```md
---
name: coding-loop-executor
description: Execute an approved coding plan in staged steps with tight scope control, planner-defined verification strategy, deferred automated verification by default, and mandatory isolated sub-agent dispatch when the runtime supports safe worktree execution. Use when planning is complete and the task should be implemented from the planner's artifacts.
---

# Coding Loop Executor

## Overview

Use this skill after the planner has produced an approved plan. Read the planning bundle, execute the staged steps with sub-agents, and keep changes small, reviewable, and aligned to the YAML plan.

Treat the planning folder and the planner-created execution branch as the authoritative sources of truth for the task. The executor must behave as if the planning folder, the execution branch, and the repository are the only authoritative context available at start.

## Input Contract

- Require one argument: the path to the feature planning folder.
- Stop immediately if the path is missing, does not exist, or does not contain the expected planning artifacts.
- Require both `overview.md` and `plan.yaml`.
- If only `overview.md` exists, stop and report that planning is incomplete.
- Do not treat missing `plan.yaml` as approval to infer the implementation plan.
- If `overview.md` and `plan.yaml` conflict materially, stop and report the conflict instead of guessing.
- Derive the expected execution branch name in the form `cl/YYYY-MM-DD_FEATURE_NAME` from the planning folder.
- Require the planner-created execution branch to already exist.
- If the expected execution branch is missing, stop and report incomplete planner handoff.
- If the execution branch has uncommitted planner-owned changes or other unexpected working tree changes at startup, stop and report unsafe or incomplete handoff.
- Treat the planning folder and planner-created execution branch as the authoritative source of truth for the task.

## Execution Phases

Follow this sequence strictly:

1. Input validation
2. Plan loading
3. Branch setup
4. Verification strategy loading
5. Step scheduling
6. Sub-agent implementation
7. Automated verification and fix loop
8. Manual verification checkpoint
9. Reviewer handoff

Do not skip forward. Do not reorder these phases.

## Execution Gates

These gates are mandatory:

- Do not execute anything unless both `overview.md` and `plan.yaml` exist.
- Do not modify code before checking out the execution branch.
- Do not execute any step until the plan has been parsed, verification strategy has been loaded, and the step is ready.
- Do not advance a dependent step until all of its dependencies are implemented and recorded.
- Do not proceed to automated verification until all planned implementation steps are recorded as `implemented`, unless the plan explicitly requires an earlier verification checkpoint.
- Do not proceed to reviewer handoff until:
  - all planned steps are recorded as `complete`
  - automated verification is passing
  - the user has either completed manual verification without issues or explicitly OKed the changes to continue
  - `execution.md` has been updated with the final executor state
  - the execution branch working tree is clean
- Stop and report blockers instead of widening scope.

## Executor-Owned Work

The executor itself owns orchestration-only work and must not hand it to implementation sub-agents:

- input validation
- plan loading
- branch checkout
- verification strategy loading
- dependency scheduling
- `execution.md` updates
- temporary branch provisioning
- worktree provisioning
- merge and conflict handling
- worktree and branch cleanup
- verification orchestration
- manual verification prompts
- reviewer handoff

Executor-owned work does not include:

- implementation edits for planned steps
- automated verification-failure fixes
- manual-verification issue fixes

Those belong to sub-agents whenever safe isolated sub-agent execution is available.

## Immutable Planner Inputs

During execution, treat `overview.md` and `plan.yaml` as immutable planner-owned inputs.

Do not edit `overview.md` or `plan.yaml` during execution unless the user explicitly requests replanning or planning corrections.

Do not use uncommitted planning changes as execution input.

## Execution Artifacts

The executor owns one required execution artifact under the planning folder:

- `execution.md`: the authoritative execution log

Create `execution.md` immediately after checking out the execution branch and before executing the first implementation step, if it does not already exist.

If `execution.md` already exists, treat it as prior executor state. Attempt to resume only when its recorded state is consistent with the execution branch and current planning artifacts. If `execution.md`, the branch state, and the planning artifacts conflict materially, stop and report the mismatch instead of guessing.

Update `execution.md` throughout execution. At minimum, record:

- active branch name
- loaded verification strategy and any later overrides
- current stage and step status
- step implementation completion
- step final completion
- verification runs and results
- fix plans created for verification failures
- manual verification rounds and user feedback
- deviations from plan
- blockers
- merge conflicts and how they were resolved
- sub-agents used, including step id and model
- temporary branches and worktrees created and cleaned up
- final executor handoff state

Do not write executor-owned artifacts outside the planning folder, except for code changes, git metadata, and isolated worktrees or branches used for execution.

## Plan Loading

1. Read `overview.md` and `plan.yaml` from the planning folder.
2. Parse the YAML plan into stages and steps, including:
   - `scope`
   - `files`
   - `constraints`
   - `depends_on`
   - `parallel_group`
   - `can_run_in_parallel`
   - `suggested_model`
   - `outputs`
   - `acceptance`
   - `handoff`
   - `verification`
3. Treat `overview.md` as the source of intent, scope, guardrails, and verification strategy.
4. Treat `plan.yaml` as the executable step graph.
5. If the plan cannot be parsed reliably, stop and report the problem.

## Branch Setup

1. Derive the expected execution branch name in the form `cl/YYYY-MM-DD_FEATURE_NAME` from the planning folder.
2. Require that branch to already exist.
3. Check out that branch before executing any steps.
4. If the expected branch does not exist, stop and report that planner handoff is incomplete.
5. If the checked-out branch is dirty at startup beyond safe executor initialization, stop and report unsafe handoff.
6. Create `execution.md` immediately after checking out the branch if it does not already exist.
7. Record the active branch name and initial execution state in `execution.md` before changing code.

## Verification Strategy Loading

Use the `## Verification Strategy` section in `overview.md` as the default source of truth for verification.

Before executing implementation steps:

1. Read the `## Verification Strategy` section from `overview.md`.
2. Extract:
   - commands
   - cheap, medium, and expensive tiers
   - execution-stage verification timing
   - formatter fix-versus-check policy
   - any required exceptions or repo-mandated boundaries
3. Record the loaded strategy in `execution.md`.

Do not rediscover verification commands by default.

Only perform limited rediscovery when:

- the `## Verification Strategy` section is missing
- referenced commands are clearly invalid
- current repository reality materially contradicts the recorded strategy

If rediscovery is required:

- keep it shallow
- prefer the same bounded discovery order used by the planner
- record the reason and any updated commands in `execution.md`

## Verification Policy

Use the narrowest meaningful verification that gives sufficient confidence for the current phase.

Prefer, in order:

1. repo-mandated checks for the affected area
2. step-specific verification from `plan.yaml`
3. planner-recorded cheap checks scoped to the changed files or subsystem
4. broader medium or expensive checks when needed for confidence or required by repo policy

By default, do not run automated verification after each implementation sub-agent completes.

Instead, complete all planned implementation steps first, then run the discovered verification suite at the end of the implementation phase.

Run step-level or stage-level verification earlier only when at least one of the following is true:

- the plan explicitly requires verification at that step or stage
- the repository has mandatory step-level checks for the affected area
- the planner-recorded verification strategy explicitly requires it
- the executor identifies a high-risk change where deferring all verification would be unsafe

If a formatting tool supports safe automatic fixing, prefer the formatter's fix mode over a separate check mode for files in scope.

Do not run a formatter check and then a formatter fix when the fix command already provides equivalent validation signal.

Use formatter check mode only when fix mode is unavailable, unsafe, explicitly disallowed by repo policy, or would create excessive out-of-scope churn.

Prefer fixing or checking only touched files or the narrowest relevant package or subtree. Avoid repo-wide formatting unless repo policy explicitly requires it.

## Verification Outcomes

Treat verification results as follows:

- Failures must always be fixed or reported as blockers.
- Warnings in changed code, or warnings introduced by the current work, should be fixed when they can be resolved locally without broad architectural changes, material scope expansion, or unrelated cleanup.
- Pre-existing or unrelated warnings outside the changed scope should not automatically widen scope.
- If warnings are deferred, record them in `execution.md` with the reason they were not fixed.

## Step Contract

Treat each step in `plan.yaml` as a contract composed of:

- `objective`
- `scope`
- `files`
- `constraints`
- `outputs`
- `acceptance`
- `verification`

The executor must evaluate returned work against the step contract before merging it or marking the step implemented.

## Step Scheduling

Build a dependency graph and track each step using these states:

- `pending`
- `ready`
- `running`
- `implemented`
- `blocked`
- `complete`

A step is `ready` only when all real dependencies in `depends_on` are implemented.

A step is `implemented` only when:

- its implementation work is finished
- its changes have been merged to the execution branch if it ran in a sub-agent worktree
- its temporary branch and worktree have been cleaned up
- its implementation outcome has been recorded in `execution.md`

A step is `complete` only when:

- it is already `implemented`
- any required earlier verification checkpoint for that step or stage has passed, if such a checkpoint exists
- the overall automated verification phase has passed
- its final completion has been recorded in `execution.md`

Use `implemented` to unlock dependent steps during the implementation phase. Use `complete` only for final execution completion and reviewer handoff readiness.

Use the plan's dependency data and `parallel_group` information to determine execution order.

Steps may run in parallel only when all of the following are true:

- the plan allows it
- `can_run_in_parallel` is true
- dependency requirements are satisfied
- `parallel_group` does not conflict with other running work
- the runtime can isolate the work safely

If isolated execution is unavailable or unsafe, preserve the same step order and scope boundaries when executing serially.

Record the current stage or step in `execution.md` before starting work on it.

## Isolated Sub-Agent Execution Model

The feature execution branch is owned by the executor. Sub-agents must never work directly on the feature branch.

When the runtime supports safe isolated execution, every implementation sub-agent and every fix sub-agent must run in its own dedicated git worktree attached to its own temporary branch created from the current feature branch.

The executor is fully responsible for the isolated branch lifecycle:

1. create the temporary step or fix branch from the current feature branch
2. create the dedicated worktree for that temporary branch
3. launch the sub-agent inside that worktree only
4. require the sub-agent to commit its changes on that temporary branch
5. review the returned work
6. merge the temporary branch back into the feature branch
7. resolve merge conflicts if needed
8. run any required verification checkpoint for that point in the flow
9. record the outcome in `execution.md`
10. delete the worktree
11. delete the merged temporary branch

Sub-agents must not:

- work in the feature branch checkout
- commit directly to the feature branch
- merge branches
- rebase the feature branch
- delete worktrees or branches
- perform cleanup of executor-owned git state

The same isolated worktree and temporary-branch flow applies to:

- planned implementation steps
- automated verification-fix passes
- manual-verification fix passes

Do not skip worktree creation, temporary branch creation, or sub-agent commits merely for convenience.

## Sub-Agent Dispatch

Sub-agent dispatch with dedicated worktree isolation is the default execution mode.

Each ready implementation step must be executed by a dedicated sub-agent in its own dedicated worktree and temporary branch when the runtime supports safe isolated execution.

Direct execution by the executor is a fallback only when the runtime cannot spawn sub-agents at all, cannot create isolated worktrees safely for the specific step or fix pass, or the work is purely executor-owned housekeeping. Direct execution is not allowed merely because the work appears small, routine, or convenient.

The executor must not satisfy a required sub-agent step using only its own direct edits when isolated sub-agent execution is available.

Implementation edits for planned steps belong to sub-agents, not the executor, whenever safe isolated sub-agent execution is available.

For each spawned implementation sub-agent:

1. Provision a temporary step branch from the current feature branch.
2. Provision a dedicated worktree attached to that temporary step branch.
3. Give it only the minimum context needed:
   - the current step
   - the step contract
   - the step handoff text
   - the relevant files
   - the constraints
   - the expected outputs
   - the verification strategy loaded from `overview.md`
   - any known coding standards, formatting rules, linting rules, test-running preferences, and repo instructions
4. Tell the sub-agent to do its own local preflight check for any additional applicable repo preferences before implementing.
5. If the sub-agent discovers a preference conflict, have it report back instead of guessing.
6. Choose the cheapest model likely to complete the step safely.
7. Before spawning the sub-agent, tell the user:
   - which step is being handed off
   - which model will be used
   - whether that model is cheaper than, the same tier as, or more capable than the current runtime model
   - whether the work is running in parallel or serially
8. Require the sub-agent to commit its changes on the temporary step branch inside its dedicated worktree.
9. Ask the sub-agent to use descriptive commit messages and keep commits to a minimum.
10. Prefer a single commit per sub-agent unless the work naturally requires more.

A sub-agent implementation step is not complete until:

- the executor created its temporary branch and dedicated worktree
- the sub-agent returned
- the sub-agent committed its changes on that temporary branch
- the returned work has been reviewed against the step contract
- the temporary branch has been merged back into the feature branch
- any merge conflicts have been resolved
- the worktree has been deleted
- the temporary branch has been deleted
- the implementation outcome has been recorded in `execution.md`

After each isolated sub-agent step finishes:

1. Review the returned work against:
   - step scope
   - listed files or code area
   - constraints
   - expected outputs
   - acceptance criteria
   - obvious regressions
2. Merge the temporary branch back into the execution branch.
3. Resolve merge conflicts immediately if they occur.
4. Delete the worktree immediately after a successful merge.
5. Delete the merged temporary branch immediately after removing its worktree, using the safe merged-branch path.
6. Commit any executor-authored follow-up changes on the execution branch before continuing. This includes:
   - `execution.md` updates
   - conflict resolution
   - direct cleanup required outside the sub-agent branch

Executor-authored follow-up changes after a sub-agent merge must be limited to orchestration work such as `execution.md` updates, conflict resolution, and required cleanup outside the sub-agent branch. They must not include new implementation fixes or scope changes unless sub-agents are unavailable or unsafe.

If work must be executed directly instead of via sub-agents, preserve the same step boundaries in `execution.md` and commit each completed step or safe stage boundary on the execution branch.

## Automated Verification and Fix Loop

After all planned implementation steps are implemented, run the verification suite defined by the planner-recorded verification strategy and record the results in `execution.md`.

Do not run automated verification after each implementation sub-agent by default.

When a verification run identifies one or more actionable failures, the executor must consolidate all currently known fixes from that verification pass into one detailed fix plan and hand that single fix plan to one sub-agent when safe isolated execution is available.

Do not split one verification pass into multiple fix sub-agents unless the fix plan itself is blocked by a real dependency boundary that makes a single safe fix pass impossible.

If automated verification fails or exposes issues:

1. Do not fix the problems directly in the executor when safe sub-agent handoff is available.
2. Consolidate all actionable failures from that verification pass into one detailed fix plan.
3. Scope that fix plan only to the failures revealed by that verification pass.
4. Write the fix plan under the planning folder using a predictable filename such as:
   - `fix_plan_verification_pass_001.md`
   - `fix_plan_verification_pass_002.md`
5. Provision a temporary fix branch from the current feature branch.
6. Provision a dedicated worktree attached to that temporary fix branch.
7. Hand that single consolidated fix plan to one sub-agent using the same dispatch rules as for implementation steps.
8. Require the sub-agent to commit its changes on the temporary fix branch inside its dedicated worktree.
9. Review the result.
10. Merge the temporary fix branch back into the feature branch.
11. Resolve merge conflicts if needed.
12. Delete the worktree and temporary fix branch.
13. Rerun the relevant verification, starting with the smallest failing check that should now pass.
14. Rerun broader dependent checks only when required by repo policy or when the focused check passing is not sufficient confidence.
15. Record the outcome in `execution.md`.

Repeat that verification-fix loop until the relevant verification passes or a blocker must be reported.

A verification-fix cycle is complete only when:

- the consolidated fix plan has been written
- the executor created the temporary fix branch and dedicated worktree
- the fix sub-agent has returned, or the direct-fallback fix has been completed when sub-agents are unavailable or unsafe
- the fix sub-agent committed its changes on the temporary fix branch when sub-agents are used
- the executor reviewed the result
- the executor merged the temporary fix branch back into the feature branch
- the executor resolved any merge conflicts
- the executor deleted the worktree and temporary fix branch
- the relevant verification has been rerun
- the updated outcome has been recorded in `execution.md`

If the runtime cannot safely spawn a sub-agent, the executor may perform the consolidated fix plan directly, but it must still:

- create the fix plan first
- keep the fixes scoped to that verification pass
- avoid unrelated cleanup or scope expansion

Use the same dispatch rules for verification-fix work as for planned implementation steps.

When automated verification passes, record all planned steps as `complete` in `execution.md`, unless the plan explicitly defines a later completion point.

## Manual Verification Checkpoint

Manual verification happens only after all planned implementation work and automated verification and fix loops are complete, unless the plan explicitly requires an earlier manual stop.

After all planned implementation steps are complete and automated verification is passing:

1. Commit all completed implementation changes and the current `execution.md` update on the execution branch before pausing.
2. Ask the user to perform manual verification or explicitly OK the changes to continue.
3. Suggest concrete areas of interest for the user to inspect based on the work completed.
4. Stop there until the user responds.

The manual verification request must:

- mention that automated verification is passing, if that is true
- suggest concrete areas to inspect based on the completed work
- allow the user either to report issues or to say OK and continue

Example structure:

`Automated verification is passing. Please manually verify the updated areas, especially <area 1>, <area 2>, and <area 3>. If you find issues, tell me what to fix. If everything looks good, reply OK to continue.`

If the user reports issues:

1. Consolidate all issues from that manual verification pass into one detailed fix plan.
2. Scope that fix plan only to the issues reported in that pass.
3. Write the fix plan under the planning folder using a predictable filename such as:
   - `manual_fix_plan_round_001.md`
   - `manual_fix_plan_round_002.md`
4. Provision a temporary manual-fix branch from the current feature branch.
5. Provision a dedicated worktree attached to that temporary manual-fix branch.
6. Hand that single fix plan to one sub-agent when safe isolated execution is available.
7. Require the sub-agent to commit its changes on the temporary manual-fix branch inside its dedicated worktree.
8. Review the result.
9. Merge the temporary manual-fix branch back into the feature branch.
10. Resolve merge conflicts if needed.
11. Delete the worktree and temporary manual-fix branch.
12. Rerun relevant verification.
13. Update `execution.md`.
14. Commit the new execution-branch state.
15. Ask for manual verification or OK again.

For each manual verification pass, group all user-reported issues into one fix plan and use one sub-agent to address that whole pass when the runtime supports it safely.

Do not silently skip manual verification. Do not proceed to reviewer handoff until this checkpoint is resolved.

## Shared Rules

- Keep implementation aligned to the approved plan.
- Do not re-plan unless the plan is clearly invalid or the user asks for replanning.
- Do not drift into review or finalization work unless explicitly handed off.
- Stop at reviewer handoff and do not perform reviewer duties in the same context.
- Do not guess when the planning folder is wrong or incomplete.
- Do not treat missing `plan.yaml` as approval to infer the implementation plan.
- Do not silently widen scope.
- Do not silently skip manual verification.
- Do not pause for manual verification or hand off to reviewer with uncommitted executor-owned changes on the execution branch.
- If a merge conflict can be resolved within the current step or fix scope and plan constraints, resolve it and record the resolution.
- If a merge conflict indicates incompatible parallel work, invalid plan assumptions, or scope ambiguity, stop and report the blocker instead of improvising a broader reconciliation.
- If the executor stops early because it cannot safely resolve leftover state, say so explicitly and ask the user what to do.

## Output and Reviewer Handoff

During execution, report meaningful progress. Before each spawned sub-agent, tell the user:

- step id or fix-pass id
- step objective or area
- files or code area in scope
- model name
- whether the model is cheaper than, the same tier as, or more capable than the current runtime model
- whether the work is running in parallel or serially

At the end of execution, the output must include:

- what changed
- verification strategy loaded from `overview.md` and any overrides
- verification performed
- any verification-fix plans that were created and handed to sub-agents
- manual verification rounds and the user's response, including any explicit OK to continue
- blockers, follow-up steps, or plan deviations
- which steps ran in parallel
- which model tier was used for sub-agents when relevant
- for every spawned sub-agent:
  - step id or fix-pass id
  - model name
  - whether it was cheaper than, the same tier as, or more capable than the current runtime model
- branch name
- temporary branches and worktrees created, merged, and deleted
- any merge conflicts that were handled
- confirmation that `execution.md` was updated
- confirmation that the final executor handoff state was committed

The next step of the chain is reviewer.

When execution is complete:

1. Tell the user explicitly that execution is complete only if:
   - all planned steps are complete
   - automated verification is passing
   - manual verification has either completed without issues or the user has explicitly OKed continuation
   - `execution.md` is up to date
2. Instruct the user to clear context first
3. Give the exact next command for the current runtime
4. Do not add any wording that implies review can continue from the current context

Use the verbatim runtime-specific handoff sentence exactly as written below, with only the planning folder path substituted.

- For Claude Code and OpenCode, say exactly: `Please run /clear then /coding-loop-reviewer .project_planning/FEATURE on an empty context.`
- For Codex runtimes that use built-in slash commands and dollar-prefixed skill invocation, say exactly: `Please run /clear then $coding-loop-reviewer .project_planning/FEATURE on an empty context.`
- If a runtime uses a different syntax, define one exact sentence for that runtime and use it verbatim.

Do not offer to continue into reviewer from the current context.