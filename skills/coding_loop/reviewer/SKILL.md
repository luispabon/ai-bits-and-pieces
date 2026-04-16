---
name: coding-loop-reviewer
description: Review coding changes against the approved plan, identify concrete bugs, regressions, and plan-adherence gaps, and, when approved, run a batched sequential review-fix loop using isolated sub-agents before finalization. Use after execution and before finalization.
---

# Coding Loop Reviewer

## Overview

Use this skill after execution to compare the implemented tree against the approved plan, the recorded execution, and the actual repository state. Surface concrete findings, and, when needed and approved, run a tightly scoped sequential review-fix loop before handing off to finaliser.

Treat the planning folder and the current feature branch as the authoritative sources of truth for the task during review.

## Input Contract

- Require one argument: the path to the feature planning folder.
- Stop immediately if the path is missing, does not exist, or does not contain the expected planning artifacts.
- Require `overview.md`, `plan.yaml`, and `execution.md`.
- If any of those required artifacts are missing, stop and report incomplete chain handoff.
- Treat the planning folder as the authoritative source of truth for the task.
- Read the planning files in this order:
  - `overview.md` for the original request, high-level overview, decision log, and verification strategy
  - `plan.yaml` for the approved implementation contract, step order, and parallelism
  - `execution.md` for completed steps, deviations, verification strategy usage, and verification performed
  - any `research.md` or `research_*.md` files for background assumptions and technical findings
- Use the planning files plus the current repository state as the reference point for scope, intent, acceptance expectations, and implementation reality.
- Derive the expected feature branch name in the form `cl/YYYY-MM-DD_FEATURE_NAME` from the planning folder.
- Require that feature branch to already exist.
- If the expected feature branch is missing, stop and report incomplete executor handoff.
- If `execution.md` shows execution did not reach reviewer handoff readiness, stop and report incomplete executor handoff.
- If the feature branch has unexpected uncommitted changes at review start, stop and report unsafe handoff.

## Review Phases

Follow this sequence strictly:

1. Input validation
2. Artifact and repo-state loading
3. Review pass
4. Fix-plan checkpoint
5. Sequential review-fix loop
6. Final review pass
7. Finaliser handoff

Do not skip forward. Do not reorder these phases.

## Review Gates

These gates are mandatory:

- Do not review unless `overview.md`, `plan.yaml`, and `execution.md` exist.
- Do not edit code before a review pass has produced concrete findings that justify fixes.
- Do not execute fixes until the user has approved the proposed reviewer fix plan.
- Do not run review-fix work directly when safe isolated sub-agent execution is available.
- Do not advance to finaliser until:
  - review status is `pass` or `pass_with_notes`
  - all blocking findings have been resolved
  - `review.md` has been updated with the final reviewer state
  - the passing `review.md` update has been committed
  - the feature branch working tree is clean
- Stop and report blockers instead of widening scope.

## Reviewer-Owned Work

The reviewer itself owns orchestration-only work and must not hand it to review-fix sub-agents:

- input validation
- planning artifact loading
- feature branch validation
- repository diff inspection
- review analysis
- findings classification
- `review.md` updates
- temporary review-fix branch provisioning
- worktree provisioning
- merge and conflict handling
- worktree and branch cleanup
- verification orchestration after review-fix passes
- finaliser handoff

Reviewer-owned work does not include:

- reviewer-approved code fixes
- reviewer-approved test or verification fixes
- reviewer-approved minimal follow-up edits required to make those fixes coherent

Those belong to sub-agents whenever safe isolated sub-agent execution is available.

## Immutable Planner and Executor Inputs

During review, treat `overview.md`, `plan.yaml`, and `execution.md` as immutable chain-owned inputs.

Do not edit `overview.md`, `plan.yaml`, or `execution.md` during review unless the user explicitly requests replanning or correction of chain artifacts.

Do not use uncommitted planning or execution changes as review input.

## Review Artifacts

The reviewer owns one required review artifact under the planning folder:

- `review.md`: the authoritative review log

Create `review.md` at the start of review if it does not already exist.

If `review.md` already exists, treat it as prior reviewer state. Attempt to resume only when its recorded state is consistent with the feature branch, current planning artifacts, and current repository state. If they conflict materially, stop and report the mismatch instead of guessing.

Update `review.md` throughout review. At minimum, record:

- scope reviewed
- inputs reviewed
- current branch name
- current review status
- findings by severity
- evidence for findings
- proposed fix plans
- approved fix plans
- fixes applied
- verification reruns and results
- deviations or blockers
- non-blocking notes
- final pass, fail, or pass-with-notes status
- finaliser handoff state

## Review.md Structure

`review.md` should use these sections:

- `## Scope Reviewed`
- `## Inputs Reviewed`
- `## Findings`
- `## Fix Plan`
- `## Fixes Applied`
- `## Verification`
- `## Final Status`

Preserve prior review passes and resolutions clearly. Do not silently overwrite earlier findings history.

## Branch Setup

1. Derive the expected feature branch name in the form `cl/YYYY-MM-DD_FEATURE_NAME` from the planning folder.
2. Require that branch to already exist.
3. Check out that branch before reviewing.
4. If the expected branch does not exist, stop and report incomplete executor handoff.
5. If the checked-out branch is dirty at startup beyond safe reviewer initialization, stop and report unsafe handoff.
6. Create `review.md` if it does not already exist.
7. Record the active branch name and initial review state in `review.md` before proceeding.

## Review Standard

Review by comparing these four things together:

- `overview.md` for original intent, constraints, boundaries, and verification strategy
- `plan.yaml` for the approved implementation contract
- `execution.md` for what the executor claims was done and how it was verified
- the actual repository state and implemented changes for what really landed

Treat them as follows:

- `overview.md` defines original intent and boundaries
- `plan.yaml` defines the approved implementation contract
- `execution.md` defines what executor claims was done and how it was verified
- repository state defines what actually landed

Reviewer findings come from mismatches between these, plus obvious correctness issues.

The reviewer must check:

- plan adherence
- scope adherence
- obvious bugs
- regressions
- missing or weak verification relative to the planner-defined verification strategy and repo expectations
- correctness of implementation against accepted intent
- conciseness and unnecessary repetition where it materially affects maintainability or correctness
- whether the implementation matches the approved acceptance expectations closely enough to hand off safely

Focus review on files and subsystems touched by the approved plan, execution record, and reviewer-fix changes, plus directly adjacent regression-risk areas.

Prefer evidence over speculation. Every finding should be supported by concrete evidence from code, diffs, plan mismatches, missing verification, or reproducible behavioural reasoning.

Keep the review focused on the current chain step. Do not reopen planning decisions unless the implementation clearly violates the approved plan in a way that cannot be resolved within reviewer scope.

## Findings Classification

Classify findings into these levels:

- `blocking` - must be fixed before finaliser handoff
- `non_blocking` - does not block handoff but should be recorded in `review.md`
- `informational` - useful note with no required action

Map findings to review status as follows:

- `fail` if any blocking findings exist
- `pass_with_notes` if no blocking findings exist but non-blocking findings remain
- `pass` if only informational findings or no findings remain

Only fixable blocking findings enter the reviewer fix plan by default.

A non-blocking finding may be included in the fix plan only when it is directly adjacent to a blocking fix and can be resolved safely with negligible additional scope.

Non-fixable blocking findings must be reported as blockers and stop the chain.

## Review Pass

During each review pass:

1. Load and compare `overview.md`, `plan.yaml`, `execution.md`, relevant research artifacts, and the actual repository state.
2. Identify concrete findings.
3. Classify findings by severity.
4. Assign stable ids to blocking findings and record them with supporting evidence in `review.md`.
5. Determine the current review status:
   - `fail` if blocking findings exist
   - `pass_with_notes` if no blocking findings exist but non-blocking findings remain
   - `pass` if only informational findings or no findings remain

If the review status is `pass` or `pass_with_notes`, skip the fix-plan checkpoint and proceed to finaliser handoff preparation.

## Fix-Plan Checkpoint

If a review pass identifies one or more fixable blocking findings:

1. Consolidate all currently known blocking fixes from that review pass into one detailed fix plan.
2. Scope that fix plan only to the findings from that review pass and directly necessary follow-up changes.
3. Map each planned fix to one or more blocking finding ids.
4. Record the proposed fix plan in `review.md`.
5. Present findings first, ordered by severity.
6. Present the proposed fix plan second.
7. Summarize what verification will be rerun after the review-fix pass.
8. Ask the user to confirm the fix plan before any files are edited.

Do not edit code before the user approves the fix plan.

One review pass produces at most one consolidated reviewer fix pass unless a real dependency boundary makes a single safe review-fix pass impossible.

## Isolated Review-Fix Execution Model

The feature branch is owned by the reviewer during the review stage. Review-fix sub-agents must never work directly on the feature branch.

When the runtime supports safe isolated execution, every approved reviewer fix pass must run in its own dedicated git worktree attached to its own temporary review-fix branch created from the current feature branch.

The reviewer is fully responsible for the isolated branch lifecycle:

1. create the temporary review-fix branch from the current feature branch
2. create the dedicated worktree for that temporary branch
3. launch the fix sub-agent inside that worktree only
4. require the sub-agent to commit its changes on that temporary branch
5. review the returned work
6. merge the temporary branch back into the feature branch
7. resolve merge conflicts if needed
8. rerun the relevant checks
9. update `review.md`
10. delete the worktree
11. delete the merged temporary branch

Review-fix sub-agents must not:

- work in the feature branch checkout
- commit directly to the feature branch
- merge branches
- rebase the feature branch
- delete worktrees or branches
- perform cleanup of reviewer-owned git state

Do not skip worktree creation, temporary branch creation, or sub-agent commits merely for convenience.

## Sequential Review-Fix Loop

The review-fix loop is sequential. Do not parallelize review-fix work.

When the user approves a reviewer fix plan:

1. Provision a temporary review-fix branch from the current feature branch.
2. Provision a dedicated worktree attached to that temporary review-fix branch.
3. Spawn one sub-agent for the whole approved fix plan when safe isolated execution is available.
4. Give it only the minimum context needed:
   - the current blocking findings
   - the approved fix plan
   - the relevant files
   - the constraints
   - the verification strategy from `overview.md`
   - any known coding standards, formatting rules, linting rules, test-running preferences, and repo instructions
   - the executor-recorded verification behaviour from `execution.md` when relevant
5. Tell the sub-agent to do its own local preflight check for any additional applicable repo preferences before implementing.
6. If the sub-agent discovers a preference conflict, have it report back instead of guessing.
7. Choose the cheapest model likely to complete the review-fix pass safely.
8. Before spawning the sub-agent, tell the user:
   - that a reviewer fix pass is being handed off
   - which model will be used
   - whether that model is cheaper than, the same tier as, or more capable than the current runtime model
9. Require the sub-agent to commit its changes on the temporary review-fix branch inside its dedicated worktree.
10. Prefer a single commit for the review-fix pass unless the work naturally requires more.

A review-fix pass is not complete until:

- the reviewer created its temporary branch and dedicated worktree
- the sub-agent returned
- the sub-agent committed its changes on that temporary branch
- the reviewer reviewed the returned work against the approved fix plan
- the temporary branch was merged back into the feature branch
- any merge conflicts were resolved
- the worktree was deleted
- the temporary branch was deleted
- relevant verification was rerun
- `review.md` was updated with the new state

If safe isolated sub-agent execution is unavailable, the reviewer may perform the approved fix plan directly, but only as a fallback. Direct review-fix execution is not allowed merely because the work appears small, routine, or convenient.

If direct fallback is required:

- keep the fixes scoped to the approved review-fix plan
- avoid unrelated cleanup or scope expansion
- preserve the same sequential fix-pass boundary in `review.md`
- commit the completed review-fix pass with a descriptive message tied to that pass

## Verification After Reviewer Fixes

Reuse the verification strategy recorded in `overview.md` by default.

Reuse the executor's recorded verification behaviour from `execution.md` when possible.

Do not rediscover verification commands from scratch unless the overview strategy is missing or clearly wrong, or the executor's recorded verification behaviour is clearly invalid.

After a reviewer fix pass:

1. rerun the smallest relevant checks first
2. rerun broader checks only when required by repo policy or when the focused checks are not sufficient confidence
3. record the verification reruns and results in `review.md`

Prefer token-conscious validation. Do not rerun broad expensive checks casually when narrower checks provide sufficient signal.

Block on missing verification only when the gap materially undermines confidence in changed behaviour or violates repo policy. Otherwise record it as a non-blocking note.

## Final Review Pass

After each approved review-fix pass:

1. restart the review from the top against the updated tree
2. compare the implementation again against `overview.md`, `plan.yaml`, `execution.md`, `review.md`, and the actual repository state
3. update `review.md` with the new findings and status
4. determine whether review now:
   - fails
   - passes with notes
   - passes cleanly

If new blocking findings exist and they arise directly from the approved reviewer fix pass or from still-unresolved prior review findings, another fix-plan checkpoint may begin.

If new issues would require broader replanning, scope expansion, or unrelated cleanup, stop and report the blocker instead of quietly widening scope.

## Shared Rules

- Review the execution output, not the planner intent alone.
- Use the approved plan as the contract, but judge against the actual repository state and executor record.
- Own the review-fix loop once the user confirms the fix plan.
- Do not advance to finalization until review is complete.
- Do not parallelize review-fix work.
- Do not widen scope into unrelated cleanup, refactors, or new features.
- Do not rewrite `plan.yaml` or reinterpret approved scope expansively during review.
- Ask only if ambiguity would materially change review correctness or safety.
- Prefer evidence over speculation.
- Do not hand off to finaliser with unresolved blocking findings.
- Do not hand off to finaliser with uncommitted reviewer-owned changes on the feature branch.
- If a merge conflict can be resolved within the approved review-fix scope, resolve it and record the resolution.
- If a merge conflict indicates scope ambiguity, invalid plan assumptions, or broader incompatibility, stop and report the blocker instead of improvising a wider reconciliation.
- Once review reaches `pass` or `pass_with_notes` and the final `review.md` update is committed, transition immediately into handoff mode.
- Do not reopen review or fix discussion on your own after passing. If the user asks for more review changes after pass, treat that as a new review pass, update `review.md`, and then hand off again.

## Output and Finaliser Handoff

During review, output should be structured as follows:

1. findings first, ordered by severity
2. short summary second
3. verification gaps or follow-up checks third
4. proposed fix plan and approval request fourth, if fixes are needed

Always confirm that `review.md` was updated with the current review state.

If review passes, confirm that the passing `review.md` update was committed before handoff.

The next step of the chain is finaliser.

When review is complete:

1. tell the user explicitly that review is complete only if:
   - review status is `pass` or `pass_with_notes`
   - all blocking findings have been resolved
   - `review.md` is up to date
   - the passing `review.md` update has been committed
2. instruct the user to clear context first
3. give the exact next command for the current runtime
4. do not add any wording that implies finalisation can continue from the current context

Use the verbatim runtime-specific handoff sentence exactly as written below, with only the planning folder path substituted.

- For Claude Code and OpenCode, say exactly: `Please run /clear then /coding-loop-finaliser .project_planning/FEATURE on an empty context.`
- For Codex runtimes that use built-in slash commands and dollar-prefixed skill invocation, say exactly: `Please run /clear then $coding-loop-finaliser .project_planning/FEATURE on an empty context.`
- If a runtime uses a different syntax, define one exact sentence for that runtime and use it verbatim.
