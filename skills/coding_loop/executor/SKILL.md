---
name: coding-loop-executor
description: Execute an approved coding plan in staged steps with tight scope control, early verification discovery, and mandatory sub-agent dispatch when the runtime supports safe isolated execution. Use when planning is complete and the task should be implemented from the planner's artifacts.
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
4. Verification discovery
5. Step scheduling
6. Sub-agent execution
7. Verification and fix loop
8. Manual verification checkpoint
9. Reviewer handoff

Do not skip forward. Do not reorder these phases.

## Execution Gates

These gates are mandatory:

- Do not execute anything unless both `overview.md` and `plan.yaml` exist.
- Do not modify code before checking out the execution branch.
- Do not execute any step until the plan has been parsed, verification discovery has completed, and the step is ready.
- Do not advance a dependent step until all of its dependencies are complete and recorded.
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
- verification discovery
- dependency scheduling
- `execution.md` updates
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
- discovered verification commands and chosen verification strategy
- current stage and step status
- step completion
- verification runs and results
- fix plans created for verification failures
- manual verification rounds and user feedback
- deviations from plan
- blockers
- merge conflicts and how they were resolved
- sub-agents used, including step id and model
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
3. Treat `overview.md` as the source of intent, scope, and guardrails.
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

## Verification Discovery

Before executing implementation steps, discover the verification commands and checks actually available in the repository.

Use a shallow, evidence-driven discovery pass. Prefer this order:

1. repo instructions and agent docs
2. root task runners and project manifests
3. CI configuration
4. relevant subproject manifests for the code areas in scope

Identify, when available:

- formatter commands
- lint checks
- type checks
- unit tests
- integration tests
- end-to-end tests
- build or compile validation
- any repo-mandated verification commands

Classify discovered checks into:

- cheap: suitable for frequent step-level runs
- medium: suitable for stage boundaries or focused subsystem validation
- expensive: suitable for end-of-run validation unless earlier use is clearly necessary

Keep verification discovery shallow and evidence-driven. Prefer a few high-signal files over broad repo exploration. Do not recursively inspect unrelated directories just to find more checks. Stop once there is enough evidence to determine the likely validation surface for the affected area.

If the plan's listed verification conflicts materially with the repo's actual available checks, stop and report the mismatch instead of inventing new verification.

Record the discovered commands and chosen verification tiers in `execution.md`. Do not repeatedly rediscover them unless the executor encounters clear evidence that the initial discovery was wrong.

## Verification Policy

Use the narrowest meaningful verification for each completed step.

Prefer, in order:

1. repo-mandated checks for the affected area
2. step-specific verification from `plan.yaml`
3. repo-discovered cheap checks scoped to the changed files or subsystem
4. broader medium or expensive checks when needed for confidence or required by repo policy

Run broader expensive checks near the manual verification checkpoint unless the step specifically requires them earlier.

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

The executor must evaluate returned work against the step contract before merging it or marking the step complete.

## Step Scheduling

Build a dependency graph and track each step using these states:

- `pending`
- `ready`
- `running`
- `blocked`
- `complete`

A step is `ready` only when all real dependencies in `depends_on` are complete.

A step is `complete` only when:

- its implementation work is finished
- its changes have been merged to the execution branch if it ran in a sub-agent worktree
- its required verification has run
- its outcome has been recorded in `execution.md`

Use the plan's dependency data and `parallel_group` information to determine execution order.

Steps may run in parallel only when all of the following are true:

- the plan allows it
- `can_run_in_parallel` is true
- dependency requirements are satisfied
- `parallel_group` does not conflict with other running work
- the runtime can isolate the work safely

If isolated execution is unavailable or unsafe, preserve the same step order and scope boundaries when executing serially.

Record the current stage or step in `execution.md` before starting work on it.

## Sub-Agent Dispatch

Sub-agent dispatch is the default execution mode.

Each ready implementation step must be executed by a dedicated sub-agent when the runtime supports safe isolated execution. Direct execution by the executor is a fallback only when the runtime cannot spawn sub-agents at all, cannot isolate the work safely for the specific step, or the work is purely executor-owned housekeeping. Direct execution is not allowed merely because the work appears small, routine, or convenient.

The executor must not satisfy a required sub-agent step using only its own direct edits when isolated sub-agent execution is available.

Implementation edits for planned steps belong to sub-agents, not the executor, whenever safe isolated sub-agent execution is available.

For each spawned implementation sub-agent:

1. Use a dedicated worktree when the runtime supports that safely.
2. Keep its writes isolated to that worktree.
3. Give it only the minimum context needed:
   - the current step
   - the step contract
   - the step handoff text
   - the relevant files
   - the constraints
   - the expected outputs
   - any known coding standards, formatting rules, linting rules, test-running preferences, and repo instructions
4. Tell the sub-agent to do its own local preflight check for any additional applicable repo preferences before implementing.
5. If the sub-agent discovers a preference conflict, have it report back instead of guessing.
6. Choose the cheapest model likely to complete the step safely.
7. Before spawning the sub-agent, tell the user:
   - which step is being handed off
   - which model will be used
   - whether that model is cheaper than, the same tier as, or more capable than the current runtime model
   - whether the work is running in parallel or serially
8. Ask the sub-agent to use descriptive commit messages and keep commits to a minimum.
9. Prefer a single commit per sub-agent unless the work naturally requires more.

A sub-agent implementation step counts as finished only when:

- the sub-agent has returned
- its worktree has been reviewed against the step contract
- its changes have been merged back into the execution branch
- its worktree has been deleted
- its temporary step branch has been deleted after merge when no longer needed
- any merge conflicts have been resolved
- required verification has run
- the result has been recorded in `execution.md`

After each isolated sub-agent step finishes:

1. Review the returned work against:
   - step scope
   - listed files or code area
   - constraints
   - expected outputs
   - acceptance criteria
   - obvious regressions
2. Merge the worktree back into the execution branch.
3. Resolve merge conflicts immediately if they occur.
4. Delete the worktree immediately after a successful merge.
5. Delete the merged temporary step branch immediately after removing its worktree, using the safe merged-branch path.
6. Commit any executor-authored follow-up changes on the execution branch before continuing. This includes:
   - `execution.md` updates
   - conflict resolution
   - direct cleanup required outside the sub-agent branch

Executor-authored follow-up changes after a sub-agent merge must be limited to orchestration work such as `execution.md` updates, conflict resolution, and required cleanup outside the sub-agent branch. They must not include new implementation fixes or scope changes unless sub-agents are unavailable or unsafe.

If work must be executed directly instead of via sub-agents, preserve the same step boundaries in `execution.md` and commit each completed step or safe stage boundary on the execution branch.

## Verification and Fix Loop

Run the relevant verification for each completed step and record the result in `execution.md`.

When a verification run identifies one or more actionable failures, the executor must consolidate all currently known fixes from that verification pass into one detailed fix plan and hand that single fix plan to one sub-agent when safe isolated execution is available.

Do not split one verification pass into multiple fix sub-agents unless the fix plan itself is blocked by a real dependency boundary that makes a single safe fix pass impossible.

If verification fails or exposes issues:

1. Do not fix the problems directly in the executor when safe sub-agent handoff is available.
2. Consolidate all actionable failures from that verification pass into one detailed fix plan.
3. Scope that fix plan only to the failures revealed by that verification pass.
4. Write the fix plan under the planning folder using a predictable filename such as:
   - `fix_plan_<step-id>_001.md`
   - `fix_plan_<step-id>_002.md`
5. Hand that single consolidated fix plan to one sub-agent using the same dispatch rules as for implementation steps.
6. Review the result.
7. Rerun the relevant verification, starting with the smallest failing check that should now pass.
8. Rerun broader dependent checks only when required by repo policy or when the focused check passing is not sufficient confidence.
9. Record the outcome in `execution.md`.

Repeat that verification-fix loop until the relevant verification passes or a blocker must be reported.

A verification-fix cycle is complete only when:

- the consolidated fix plan has been written
- the fix sub-agent has returned, or the direct-fallback fix has been completed when sub-agents are unavailable or unsafe
- the relevant verification has been rerun
- the updated outcome has been recorded in `execution.md`

If the runtime cannot safely spawn a sub-agent, the executor may perform the consolidated fix plan directly, but it must still:

- create the fix plan first
- keep the fixes scoped to that verification pass
- avoid unrelated cleanup or scope expansion

Use the same dispatch rules for verification-fix work as for planned implementation steps.

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
4. Hand that single fix plan to one sub-agent when safe isolated execution is available.
5. Review the result.
6. Rerun relevant verification.
7. Update `execution.md`.
8. Commit the new execution-branch state.
9. Ask for manual verification or OK again.

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
- If a merge conflict can be resolved within the current step scope and plan constraints, resolve it and record the resolution.
- If a merge conflict indicates incompatible parallel work, invalid plan assumptions, or scope ambiguity, stop and report the blocker instead of improvising a broader reconciliation.
- If the executor stops early because it cannot safely resolve leftover state, say so explicitly and ask the user what to do.

## Output and Reviewer Handoff

During execution, report meaningful progress. Before each spawned sub-agent, tell the user:

- step id
- step objective or area
- files or code area in scope
- model name
- whether the model is cheaper than, the same tier as, or more capable than the current runtime model
- whether the work is running in parallel or serially

At the end of execution, the output must include:

- what changed
- verification discovery results and chosen verification strategy
- verification performed
- any verification-fix plans that were created and handed to sub-agents
- manual verification rounds and the user's response, including any explicit OK to continue
- blockers, follow-up steps, or plan deviations
- which steps ran in parallel
- which model tier was used for sub-agents when relevant
- for every spawned sub-agent:
  - step id
  - model name
  - whether it was cheaper than, the same tier as, or more capable than the current runtime model
- branch name
- any merge conflicts that were handled
- any temporary step branches that were deleted after merge
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