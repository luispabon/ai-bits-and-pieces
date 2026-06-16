---
name: das-implement
description: Execute an approved coding plan as serial-first implementation steps with tight scope control, planner-defined verification strategy, and mandatory sub-agent/worktree execution.
---

# Coding Loop Executor

## Overview

Use this skill after the planner has produced an approved planning bundle. Read `overview.md` and the flat `plan.yaml`, execute the implementation steps, and keep changes aligned to the approved plan.

Treat the planning folder, feature branch, and repository state as the authoritative context at execution start.

## Input Contract

- Require one argument: the feature planning folder.
- Require `overview.md` and `plan.yaml`.
- Stop if artifacts are missing, conflict materially, or cannot be parsed.
- Derive the expected branch as `cl/YYYY-MM-DD_FEATURE_NAME`.
- Require the expected branch to exist and be clean before implementation starts.
- Check whether `.project_planning/` is gitignored by running `git check-ignore -q .project_planning/`. If exit code is 0, planning artifacts are local-only — do not stage or commit them at any point during this workflow. If exit code is non-zero, planning artifacts are version-controlled — commit them as described below.
- Treat `overview.md` and `plan.yaml` as immutable planner-owned inputs unless the user explicitly requests replanning.

## Execution Flow

Follow this sequence:

1. Validate input artifacts and branch state.
2. Check out the expected feature branch.
3. Load verification strategy from `overview.md`.
4. Create or resume compact `execution.md`.
5. Execute ready implementation steps — dispatch one sub-agent per step via worktree. Do not implement directly.
6. Run planned verification and fix failures.
7. Ask for manual verification only when the plan or risk requires it.
8. If planning artifacts are version-controlled, commit final executor state. Hand off to review.

Stop and report blockers instead of widening scope.

## Execution Artifact

`execution.md` is a compact state file under the planning folder. It should record only:

- active branch
- loaded verification strategy or explicit overrides
- current, completed, blocked, and skipped steps
- sub-agents used, including step id, model or delegation profile, and escalation reason if any
- verification commands and results
- deviations, blockers, and manual verification notes
- final reviewer handoff status

Do not maintain a verbose event log. Keep it sufficient for reviewer handoff.

## Plan Loading

Parse `plan.yaml` as a flat list of implementation steps.

The top level must be:

```yaml
steps:
  - id: step-1
    title: ...
```

Expected step fields:

- `id`
- `title`
- `scope`
- `files`
- `constraints`
- `acceptance`
- `verification`

Optional fields:

- `depends_on`
- `parallel_group`
- `delegate_profile`

If `delegate_profile` is present, treat it as the planner's explicit runtime-specific delegation preference for that step. Use it unless it is unavailable or unsafe for the step, and record any override in `execution.md`.

Do not infer missing implementation plans from `overview.md` alone.

## Scheduling

Execute serially by default.

Use `depends_on` only to block a step until real prerequisites are implemented.

Use `parallel_group` only when all of these are true:

- the plan explicitly marks the steps as independent
- the runtime can isolate work safely
- parallelism is likely to save meaningful time
- coordination and merge risk are low

If any condition is not met, run the steps serially in plan order.

Track step states as `pending`, `ready`, `running`, `implemented`, `blocked`, or `complete`.

Use `implemented` to unlock dependencies. Use `complete` only after required verification has passed.

## Executor-Owned Work

The executor acts only as an orchestrator. The following are the only direct actions it takes — everything else is delegated:

- artifact loading
- branch checkout
- step scheduling
- `execution.md` updates
- temporary branch and worktree provisioning
- sub-agent dispatch
- merge/conflict handling
- temporary branch and worktree cleanup
- verification orchestration
- reviewer handoff

The executor MUST NOT call file-mutation tools (Edit, Write, or Bash for file changes) on implementation code. All implementation edits, verification-failure fixes, and manual-verification issue fixes MUST be performed by delegated coding sub-agents. Doing so directly is a skill violation, not a fallback.

Before any implementation action, ask: have I dispatched a sub-agent for this step? If no — stop, provision the worktree, delegate.

## Isolated Worktree Model

The feature branch is owned by the executor. Sub-agents must not work directly on it.

Every implementation or fix pass MUST run in a dedicated worktree attached to a temporary branch created from the current feature branch. This is mandatory, not a preference.

Safe isolated execution requires the runtime to delegate to sub-agents, create git worktrees, create temporary branches, and the repository state to be clean enough to provision them safely. Any runtime with sub-agent dispatch and git access meets these conditions.

The executor must:

1. create the temporary branch and worktree
2. verify the worktree is accessible (see provisioning checks below)
3. delegate the scoped task inside that worktree
4. require the sub-agent to commit on the temporary branch
5. review the result against the step contract
6. merge it back to the feature branch
7. run required verification for that point in the flow
8. update `execution.md`
9. close the sub-agent
10. delete the worktree and merged temporary branch

### Worktree Provisioning Checks

After `git worktree add`, verify the worktree before dispatching:

1. `ls -d <worktree-path>` — confirm the directory was created.
2. `git -C <worktree-path> branch --show-current` — confirm it is on the expected temporary branch.

If either check fails, prune the entry with `git worktree remove <worktree-path>` and activate the direct fallback.

Sub-agents must not merge, rebase, clean up executor-owned git state, or commit directly to the feature branch.

The direct fallback activates only when sub-agent dispatch returns an error, `git worktree add` fails with a real error, or worktree provisioning checks fail. A judgment that isolation is unnecessary or that the edits are simple does not qualify as a fallback condition. If direct execution is used as a fallback, record the concrete error in `execution.md` and preserve the same step boundaries.

## Delegation

Default to the cheapest/fastest concrete model or delegation profile available on the current runtime. When the runtime supports explicit sub-agent model or profile selection, the executor MUST pass that selection in the spawn/delegation call instead of relying on inherited defaults.

Do not omit the model or profile override merely because the chosen option is "the default" in prose. If the current runtime's sub-agents inherit the parent model by default, omitting the override is only allowed when the parent model is already the cheapest safe option or no cheaper safe option exists.

Only escalate to a higher tier when the step involves complex multi-file reasoning or ambiguous design decisions. Record the escalation reason in `execution.md`.

Before spawning any implementation or fix sub-agent, tell the user:

- which step or fix pass is being handed off
- which model or delegation profile will be used
- whether that model or profile is cheaper than, the same tier as, or more capable than the current runtime model
- whether a planner-provided `delegate_profile` is being used or overridden

Record the same model or profile decision in `execution.md`.

Every delegated task must be tight and self-contained. Include:

- the parent step id and goal
- relevant user intent and approved decisions
- scoped files, packages, or paths
- constraints, non-goals, and forbidden changes
- expected output and commit expectations
- verification to run or report
- the pre-commit checklist below

Do not pass broad conversation history or vague prompts. Do not make the delegated agent rediscover context the main agent already has.

### Pre-Commit Checklist

Include this checklist verbatim in every delegated task that commits. The sub-agent must run all checks before `git commit`:

1. `git branch --show-current` — must equal the temporary branch name given in the task. If it shows the feature branch, STOP and report without committing.
2. `git rev-parse --show-toplevel` — must equal the worktree path given in the task. If it shows a different path, STOP and report without committing.
3. `git status` — must show only files within the declared scope as modified. If unexpected files appear, STOP and report.

If any check fails, the sub-agent must not commit. It must report the mismatch and let the executor recover.

## Verification Policy

Before running linters, clean any linter cache that stores results by absolute path. Stale entries from deleted worktrees cause false positives (e.g. `golangci-lint cache clean` for Go projects).

Use the narrowest meaningful verification that gives sufficient confidence.

Prefer:

1. repo-mandated checks for the affected area
2. step-specific verification from `plan.yaml`
3. cheap planner-recorded checks scoped to changed files or subsystem
4. broader checks only when risk or repo policy requires them

By default, defer automated verification until all implementation steps are implemented. Run earlier verification only when the plan, repo policy, or risk requires it.

When safe fix mode is available and appropriate, prefer fix mode over check-only mode.

Fix mode is safe only when it is scoped to touched or relevant files, non-destructive, compatible with repo policy and approval requirements, and its changes can be reviewed before commit.

Failures must be fixed or reported as blockers. Do not widen scope for unrelated pre-existing warnings.

## Handoff

Reviewer handoff requires:

- all planned steps are implemented
- required verification is passing
- `execution.md` is updated with compact final state
- temporary branches/worktrees are cleaned up
- feature branch working tree is clean

Failed verification blocks reviewer handoff by default. Proceed to review with known blockers only if the user explicitly asks for review of a blocked implementation, and record that exception in `execution.md`.

If planning artifacts are version-controlled, commit the final executor state before handing off to review.

Use the verbatim runtime-specific handoff sentence exactly as written below, with only the planning folder path substituted.

- For Claude Code and OpenCode, say exactly: `Please run /clear then /das-review .project_planning/FEATURE on an empty context.`
- For Codex runtimes that use built-in slash commands and dollar-prefixed skill invocation, say exactly: `Please run /clear then $das-review .project_planning/FEATURE on an empty context.`
- If a runtime uses a different syntax, define one exact sentence for that runtime and use it verbatim.
