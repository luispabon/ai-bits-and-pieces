---
name: simple-plan-orchestrator-executor
description: Orchestrate the staged execution of a refactoring or implementation plan by dispatching sub-agents per stage via git worktrees, reviewing their output, and merging back into the current branch. Use this skill whenever the user asks to "run the plan", "execute the refactoring plan", "implement the stages", "orchestrate the plan", or points Claude at a plan file (e.g. .project_planning/*.md) and asks it to carry it out. Also triggers when the user says "oversee the implementation of [plan]", "dispatch agents for each stage", or any variant of "go through the plan step by step using sub-agents". This skill is intended for Claude Code only - it requires git, worktrees, and sub-agent spawning capabilities.

---

# Plan Orchestrator

This skill drives staged execution of a plan document. For each stage in the plan, you:

1. Create a git worktree scoped to that stage
2. Spawn a sub-agent with all context it needs
3. Review the sub-agent's changes for compliance
4. Request corrections if needed (iterating until satisfied)
5. Merge the worktree back into the current branch and clean up

You are the orchestrator - you do not implement changes directly. Sub-agents do the work; you coordinate, review, and integrate.

---

## Phase 0: Setup

Before touching any worktrees, read and internalise the plan.

### 0.1 Read the plan document

The user will point you at a plan file - typically in `.project_planning/`. Read it in full. Extract:

- The list of stages/steps in order
- For each stage: its title, category, affected files, dependencies on prior stages, acceptance criteria / verification steps
- Any global constraints or notes at the top of the plan

### 0.2 Confirm readiness

Before proceeding, verify:

```bash
# Confirm clean working tree
git status --short

# Confirm current branch
git branch --show-current

# Confirm worktree support is available
git worktree list
```

If the working tree is dirty, stop and tell the user. All orchestration assumes a clean base. If there are uncommitted changes, ask the user to commit or stash them first.

### 0.3 Log your state

Print a brief execution plan to the user before starting - list all stages you intend to execute in order, so the user can verify or override before you begin.

---

## Phase 1: Per-Stage Execution Loop

Repeat this sequence for each stage in the plan, in dependency order.

### 1.1 Create the worktree

```bash
# Derive a slug from the stage title, e.g. "Step 3: Extract shared types" -> "stage-03-extract-shared-types"
STAGE_SLUG="stage-<N>-<short-slug>"
WORKTREE_PATH="../.worktrees/${STAGE_SLUG}"

git worktree add "${WORKTREE_PATH}" -b "${STAGE_SLUG}"
```

Name the branch and directory consistently: `stage-<zero-padded-N>-<slug>`, where slug is the stage title lowercased, spaces replaced with hyphens, special characters stripped.

### 1.2 Prepare the sub-agent context

Compose a context package for the sub-agent. This must be self-contained - the sub-agent has no memory of prior conversation. Include:

**Mandatory context:**
- The full text of the current stage from the plan (problem statement, action, affected files, verification criteria)
- The list of stages that have already been completed (so the sub-agent understands what preconditions are met)
- The worktree path it must operate in
- The instruction to `cd` into the worktree before making any changes
- Any global constraints from the plan header (e.g. "preserve all existing behaviour", "do not modify test files")

**Optional but recommended:**
- Contents of the specific files the stage will touch (paste them in or instruct the sub-agent to read them first)
- The verification command(s) from the plan step so the sub-agent can self-check before handing back

**Sub-agent instruction template:**

```
You are implementing Stage <N> of a refactoring plan.

Your working directory is: <WORKTREE_PATH>
cd into it before making any changes.

## Stage goal
<paste stage title, problem, and action from plan>

## Files you will touch
<list>

## Completed prior stages (preconditions satisfied)
<list of completed stage titles>

## Global constraints
<any plan-level constraints>

## Verification
When done, run: <verification commands>
Confirm they pass before finishing.

Do not modify any files outside your working directory.

When your changes are complete and verification passes, commit everything with:
  git add -A && git commit -m "stage <N>: <stage title>"

Do not push. The orchestrator will handle the merge.
```

### 1.3 Dispatch the sub-agent

Spawn the sub-agent with the context package above. The sub-agent works in its worktree, makes all changes, runs verification, then returns.

Monitor for completion. If the sub-agent errors or times out, note the state before retrying.

### 1.4 Review the changes

Once the sub-agent completes, first verify it actually committed something:

```bash
cd "${WORKTREE_PATH}"

# Confirm at least one commit exists ahead of the base branch
git log HEAD ^<BASE_BRANCH> --oneline
```

If that log is empty, the sub-agent made no commits. Do not proceed to merge. Treat this as a failed attempt: send the sub-agent back with an explicit reminder that it must commit before finishing (see correction template in 1.5). Do not touch the worktree yourself.

Once commits are confirmed, inspect the work:

```bash
# See what changed across all commits in this worktree branch
git diff <BASE_BRANCH>...HEAD

# Run verification commands from the plan step
<verification commands>

# Run broader sanity checks appropriate to the project type
# e.g. for Go: go build ./... && go vet ./...
# e.g. for Node: npm test
# e.g. for Python: python -m pytest
```

Evaluate against the plan's stated acceptance criteria:
- Does the diff match what the plan asked for?
- Are there unexpected changes to files outside the stated scope?
- Do verification commands pass?
- Are there any obvious correctness issues (introduced bugs, removed behaviour)?

### 1.5 Request corrections if needed

If the review reveals deficiencies, do not merge. Instead, compose a correction request for the sub-agent:

```
Your implementation of Stage <N> has the following issues:

1. <specific issue, reference file and line if possible>
2. <specific issue>

Please:
- Fix issue 1 by doing <specific action>
- Fix issue 2 by doing <specific action>

After fixing, re-run: <verification commands>
```

Iterate (1.3 -> 1.5) until either:
- All acceptance criteria are met, OR
- You have iterated 3 times without resolution - at which point escalate to the user with a clear description of what is failing and why

### 1.6 Merge and clean up

Once satisfied:

```bash
# Return to original branch
cd <original repo root>
CURRENT_BRANCH=$(git branch --show-current)

# Merge the worktree branch
git merge --no-ff "${STAGE_SLUG}" -m "chore: stage <N> - <stage title>"

# Verify the worktree is clean before removing it (all commits merged, no uncommitted state)
git -C "${WORKTREE_PATH}" status --short
# If the above shows any output, STOP - do not remove the worktree. Investigate before proceeding.

# Only remove once confirmed clean
git worktree remove "${WORKTREE_PATH}"

# Delete the stage branch
git branch -d "${STAGE_SLUG}"
```

**NEVER use `git worktree remove --force` or `rm -rf` on a worktree directory.** If the worktree cannot be cleanly removed, stop and tell the user - there is uncommitted or unmerged work that must not be discarded.

Log a one-line completion note: `[Stage N complete] <title>`

---

## Phase 2: Completion

After all stages are merged:

1. Run the full project verification suite (build, test, lint) against the final state
2. Print a summary: stages completed, any stages skipped or escalated, final verification status
3. If all stages completed cleanly, report success. If any were escalated or skipped, list them clearly so the user knows what needs manual attention.

---

## Error handling and edge cases

**Merge conflicts**: If a merge produces conflicts, do not resolve them silently. Stop, describe the conflict to the user, and ask for guidance.

**Verification failures at merge time**: If a stage passed its own verification but breaks a broader test suite at merge time, this is a regression introduced by the interaction of multiple stages. Report it clearly with the diff context.

**Plan stages with no clear verification**: Some steps (e.g. comment cleanup, naming) have subjective acceptance criteria. For these, review the diff carefully yourself and use judgement. If uncertain, show the diff to the user before merging.

**Skipping stages**: If the user asks to skip a stage, record it as skipped (not complete) so that dependent stages are flagged.

**Long-running stages**: For stages that touch many files, the sub-agent may produce a large diff. Spot-check a representative sample rather than reviewing every line, but always run the full verification suite.

---

## Notes

- Never commit directly on the main branch during orchestration. All work happens in worktree branches, merged only after review.
- Never modify the plan document itself during execution unless the user explicitly asks you to update it with progress notes.
- Sub-agents are responsible for committing their own work inside the worktree. The orchestrator merges; it does not commit on the sub-agent's behalf.
- Never force-delete a worktree. If cleanup fails, escalate to the user.
- If the plan has a stage 0 or setup stage, execute it via worktree too - no special-casing.
