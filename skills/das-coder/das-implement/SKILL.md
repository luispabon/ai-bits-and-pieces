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
5. Execute ready implementation steps — dispatch one sub-agent per step via the delegation model. Do not implement directly unless the step is marked `no_delegate`.
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
- `decisions`
- `approach`
- `files`
- `constraints`
- `acceptance`
- `verification`

`approach` is authoritative for *how* a step is built: delegated sub-agents follow it rather than re-deriving design (names, signatures, locations, data shapes, edge/error handling). A step's `decisions` list cites Key Decision IDs in `overview.md`; resolve them there and treat them as binding constraints on the implementation. When constructing a delegated task, pass the step's `approach` and the resolved text of its cited `decisions` into the sub-agent's context.

Optional fields:

- `depends_on`
- `parallel_group`
- `delegate_profile`
- `no_delegate`

If `delegate_profile` is present, treat it as the planner's explicit runtime-specific delegation preference for that step. Use it unless it is unavailable or unsafe for the step, and record any override in `execution.md`.

If `no_delegate` is set, the executor applies the step's changes inline without delegation. This is the only case where inline execution is permitted.

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

The executor acts only as an orchestrator. It performs these actions directly using the native tool for each — do not route through `Bash` when a dedicated tool exists:

- artifact loading — `Read` to load plan files; `grep` and `glob` to locate files
- `execution.md` creation and updates — `Write`
- branch checkout, worktree provisioning, merge/conflict handling, cleanup — `Bash` for git operations
- step scheduling and sub-agent dispatch
- verification orchestration — `Bash` for running checks; `Read` to inspect results
- reviewer handoff

Everything else is delegated.

### Implementation code restriction

The executor MUST NOT call file-mutation tools (`Edit`, `Write`, or `Bash` for file writes) on **implementation-scoped files** — the files listed in step `files` fields. All implementation edits, verification-failure fixes, and manual-verification issue fixes MUST be performed by delegated coding sub-agents. Doing so directly is a skill violation, not a fallback.

This restriction does not apply to executor-owned artifacts (`execution.md`, worktree provisioning, branch operations).

Before any implementation action, ask: have I dispatched a sub-agent for this step? If no — stop, provision the worktree, delegate.

## Delegation

The feature branch is owned by the executor. Implementation-scoped code must be changed only by delegated sub-agents (see Implementation code restriction above). The executor prefers the highest available delegation tier:

1. **Isolated delegation** (preferred): sub-agent works in a dedicated worktree on a temporary branch. Provides full isolation from the feature branch.
2. **Direct delegation** (fallback): sub-agent works directly on the feature branch. Used when worktrees are unavailable or provisioning fails.

There is no inline execution tier. If delegation itself is unavailable, stop and report a blocker. Exception: steps marked `no_delegate` in the plan are applied inline by the executor.

Prefer isolated delegation. Fall back to direct delegation only when `git worktree add` fails, worktree provisioning checks fail, or sub-agent dispatch returns an error for the worktree path. A judgment that isolation is unnecessary or that the edits are simple does not justify skipping to direct delegation — only concrete errors do.

### Worktree Provisioning Checks

After `git worktree add`, verify the worktree before dispatching:

1. `ls -d <worktree-path>` — confirm the directory was created.
2. `git -C <worktree-path> branch --show-current` — confirm it is on the expected temporary branch.

If either check fails, prune the entry with `git worktree remove <worktree-path>` and fall back to direct delegation.

### Isolated Delegation Steps

When using isolated delegation, the executor must:

1. create the temporary branch and worktree
2. verify the worktree is accessible (see provisioning checks above)
3. delegate the scoped task inside that worktree
4. require the sub-agent to commit on the temporary branch
5. review the result against the step contract
6. merge it back to the feature branch
7. run required verification for that point in the flow
8. update `execution.md`
9. close the sub-agent
10. delete the worktree and merged temporary branch

Sub-agents must not merge, rebase, clean up executor-owned git state, or commit directly to the feature branch.

### Direct Delegation Steps

When using direct delegation, the executor must:

1. delegate the scoped task on the feature branch
2. require the sub-agent to commit on the feature branch
3. review the result against the step contract
4. run required verification for that point in the flow
5. update `execution.md`
6. close the sub-agent

Record the concrete error that triggered the fallback in `execution.md`.

### Model Selection

Default to the cheapest/fastest concrete model or delegation profile available on the current runtime. When the runtime supports explicit sub-agent model or profile selection, the executor MUST pass that selection in the spawn/delegation call instead of relying on inherited defaults.

Do not omit the model or profile override merely because the chosen option is "the default" in prose. If the current runtime's sub-agents inherit the parent model by default, omitting the override is only allowed when the parent model is already the cheapest safe option or no cheaper safe option exists.

Only escalate to a higher tier when the step involves complex multi-file reasoning or ambiguous design decisions. Record the escalation reason in `execution.md`.

Before spawning any implementation or fix sub-agent, tell the user:

- which step or fix pass is being handed off
- which model or delegation profile will be used
- whether that model or profile is cheaper than, the same tier as, or more capable than the current runtime model
- whether a planner-provided `delegate_profile` is being used or overridden

Record the same model or profile decision in `execution.md`.

### Task Construction

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

Include the appropriate checklist verbatim in every delegated task that commits. The sub-agent must run all checks before `git commit`.

**Isolated delegation mode:**

1. `git branch --show-current` — must equal the temporary branch name given in the task. If it shows the feature branch, STOP and report without committing.
2. `git rev-parse --show-toplevel` — must equal the worktree path given in the task. If it shows a different path, STOP and report without committing.
3. `git status` — must show only files within the declared scope as modified. If unexpected files appear, STOP and report.

**Direct delegation mode:**

1. `git branch --show-current` — must equal the feature branch name given in the task. If it shows a different branch, STOP and report without committing.
2. `git status` — must show only files within the declared scope as modified. If unexpected files appear, STOP and report.

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
