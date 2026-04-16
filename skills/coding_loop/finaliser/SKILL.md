---
name: coding-loop-finaliser
description: Close out a completed coding loop by validating final chain readiness, checking for leftover repository state, and optionally preparing and creating a PR or MR when the remote provider is supported. Use after review confirms the work is ready to finish.
---

# Coding Loop Finaliser

## Overview

Use this skill after review is complete and the work is ready to close. Validate that the coding loop actually reached finaliser-ready state, inspect the repository for leftover state, and optionally prepare and create a PR or MR when the remote provider is supported.

Treat the planning folder and the expected feature branch as the authoritative sources of truth for closeout.

## Input Contract

- Require one argument: the planning folder path in the form `.project_planning/YYYY-MM-DD_FEATURE_NAME/`.
- Stop immediately if the path is missing, does not exist, or does not contain the expected planning artifacts.
- Require `overview.md`, `execution.md`, and `review.md`.
- If any of those required artifacts are missing, stop and report incomplete chain handoff.
- Read the planning files in this order:
  - `overview.md` for the original request, high-level overview, and verification strategy
  - `execution.md` for completed implementation work, deviations, verification performed, and execution handoff state
  - `review.md` for final review findings, review status, and finaliser handoff readiness
- Derive the expected feature branch name in the form `cl/YYYY-MM-DD_FEATURE_NAME` from the planning folder.
- Require that feature branch to already exist.
- If the expected feature branch is missing, stop and report incomplete chain handoff.
- Treat the planning folder and expected feature branch as the authoritative source of truth for finalization.

## Finalisation Phases

Follow this sequence strictly:

1. Input validation
2. Artifact loading
3. Final readiness validation
4. Repository state inspection
5. Leftover resolution checkpoint
6. Remote and provider detection
7. PR or MR preparation checkpoint
8. PR or MR creation
9. Chain completion

Do not skip forward. Do not reorder these phases.

## Finalisation Gates

These gates are mandatory:

- Do not proceed unless `review.md` exists and shows review status `pass` or `pass_with_notes`.
- Do not proceed unless `execution.md` and `review.md` together indicate that the chain reached finaliser-ready state.
- Do not proceed with PR or MR preparation until the expected feature branch is checked out.
- Do not push or create a PR or MR while unresolved leftover files, worktrees, or branches remain, unless the user explicitly chooses how to handle them or explicitly chooses to proceed despite them.
- Do not attempt PR or MR creation before a required branch push succeeds.
- Do not create a PR or MR without explicit user confirmation.
- Stop and report blockers instead of reopening implementation or review work.

## Final Readiness Validation

Before inspecting repository leftovers, validate from chain artifacts that finalization is actually allowed.

The finaliser must confirm all of the following:

- `review.md` exists
- `review.md` shows review status `pass` or `pass_with_notes`
- `review.md` indicates blocking findings are resolved
- `execution.md` indicates execution reached reviewer handoff readiness
- `review.md` indicates finaliser handoff readiness
- the expected feature branch exists

If any of these checks fail, stop and report that finalization cannot proceed yet.

## Branch Setup

1. Derive the expected feature branch name in the form `cl/YYYY-MM-DD_FEATURE_NAME` from the planning folder.
2. Require that branch to already exist.
3. Check out that branch before continuing.
4. If the expected branch does not exist, stop and report incomplete chain handoff.
5. If the current branch does not match the expected feature branch and cannot be safely switched, stop and report the mismatch.

After branch setup, all repository inspection, push operations, and PR or MR actions must use the expected feature branch only.

## Repository State Inspection

Inspect the repository only enough to determine finalization readiness and leftover state.

Check for:

- uncommitted tracked changes
- untracked files
- leftover worktrees
- leftover temporary branches
- unexpected detached HEAD state
- current branch cleanliness

Do not deep-review code during finalization. Do not reopen reviewer analysis here.

For leftover worktrees, inspect only enough to determine:

- worktree path
- associated branch
- whether the worktree is clean or dirty
- whether unmerged or uncommitted work appears to exist
- whether the branch appears to be a loop-generated temporary branch

Do not deep-inspect the contents of leftover worktrees.

## Leftover Resolution Checkpoint

Classify leftover repository state into:

- uncommitted tracked changes
- untracked files
- leftover worktrees
- leftover temporary branches
- other unexpected git state

If no leftovers exist, proceed.

If leftovers exist:

1. List them clearly and briefly.
2. For uncommitted or untracked files, ask the user whether to:
   - commit them
   - discard them
   - keep them and stop finalization
3. For leftover worktrees, ask the user what to do about each one.
4. For leftover temporary branches, ask the user whether to:
   - keep them
   - delete them if safe
   - stop finalization

Do not guess how to resolve leftovers.

Do not delete ambiguous worktrees or branches without explicit user approval.

If the user approves deletion of a leftover temporary branch or worktree and it is clearly loop-generated and already merged, the finaliser may delete it.

If the branch or worktree is ambiguous, dirty, not clearly loop-generated, or not clearly merged, the finaliser must not delete it without explicit confirmation for that specific item.

Do not proceed to push or PR or MR creation until leftover state is resolved or the user explicitly chooses to proceed.

If the user chooses to keep unresolved leftovers, stop and report that closeout is incomplete by user choice.

## Feature Intent and Summary Source

Use artifacts as follows:

- Extract only the `## Overview` section from `overview.md` as the high-level feature intent.
- Use `execution.md` and `review.md` to summarize:
  - completed work
  - deviations
  - residual risk
  - final status

Do not duplicate reviewer findings verbatim. Synthesize them into final status.

## Remote and Provider Detection

Identify the remote provider from repository remotes.

Use this order:

1. the remote tracking the expected feature branch, if configured
2. otherwise `origin`
3. if neither yields a clear supported provider, stop and report ambiguity or unsupported provider

Determine:

- active remote name
- remote URL
- provider type
- current feature branch
- target branch, when it can be determined safely

Use the selected remote consistently for push and PR or MR creation. Do not detect one remote and execute against another.

If the target branch cannot be determined safely, stop and ask the user once.

If the provider is unsupported or unclear, say so explicitly and stop before PR or MR creation.

## Provider Matrix

Use only the exact provider flows below. Do not guess provider-specific commands.

- GitHub: first use `git push -u <remote> <branch>` when needed so the branch exists on the remote, then use `gh pr create --title <title> --body <body> --base <target> --head <branch>`.
- GitLab: use `git push -o merge_request.create -o merge_request.target=<target> <remote> <branch>`.
- Azure DevOps: first use `git push -u <remote> <branch>` when needed so the branch exists on the remote, then use `az repos pr create --title <title> --description <body> --source-branch <branch> --target-branch <target>`.
- Bitbucket Cloud / Bitbucket Data Center: no documented standard CLI flow is available here for automatic PR creation; treat as unsupported and do not guess.

## PR or MR Preparation

If the provider is supported:

1. Determine whether the current feature branch already exists on the chosen remote.
2. If needed, push the current branch to the chosen remote before attempting PR or MR creation.
3. If the push fails, stop and report the failure instead of attempting PR or MR creation.
4. Build the PR or MR title from the high-level feature name. Keep it concise and descriptive.
5. Build the PR or MR body from:
   - the `## Overview` section from `overview.md`
   - then `**Changes:**`
   - then bullet points derived from relevant non-merge commit messages for this loop only
6. Do not diff-analyze the codebase to build the PR or MR body.
7. Do not render the full PR or MR body in user-facing output unless the user asks for it.
8. Present a concise summary of:
   - provider
   - target branch
   - source branch
   - push status
   - prepared PR or MR title
9. Ask the user to confirm before creating the PR or MR.

## PR or MR Creation

After explicit user confirmation:

- GitHub:
  1. Ensure the branch push has already succeeded if required.
  2. Create the PR with:
     - `gh pr create --title <title> --body <body> --base <target> --head <branch>`

- GitLab:
  1. Use the documented push-based MR creation flow:
     - `git push -o merge_request.create -o merge_request.target=<target> <remote> <branch>`

- Azure DevOps:
  1. Ensure the branch push has already succeeded if required.
  2. Create the PR with:
     - `az repos pr create --title <title> --description <body> --source-branch <branch> --target-branch <target>`

If creation fails, report the failure clearly and stop.

## Shared Rules

- Do not reopen implementation unless the user explicitly asks for more changes.
- Do not reopen review unless chain artifacts show finalization is not actually allowed.
- Do not duplicate the reviewer’s findings; synthesize them into the final status.
- Do not guess about leftover files, worktrees, branches, or remote provider support.
- Do not guess about provider-specific PR or MR commands; use the matrix above.
- Do not attempt PR or MR creation before a required branch push succeeds.
- Do not create a PR or MR without user confirmation.
- Do not diff-analyze the codebase to build the PR or MR body; use commit messages only for the bullet list.
- Do not dump the full PR or MR title or body into user-facing output unless the user asks for it.
- Do not treat a missing or failing `review.md` as good enough to finalize.
- Do not deep-inspect leftover worktrees beyond branch and cleanliness state.
- Do not create new commits during finalization unless the user explicitly instructs the finaliser to commit leftover changes.
- Do not rebase, squash, rewrite history, or merge target-branch changes during finalization unless the user explicitly asks.
- Keep closeout brief, factual, and limited to repository state plus release actions.

## Loop Completion Rule

The coding loop is finished when final repository state has been inspected, any blockers have been resolved or explicitly left as user-owned decisions, and PR or MR creation has either:

- completed successfully
- been explicitly declined by the user
- been determined unsupported
- been skipped because the user chose not to proceed

Unsupported provider status does not invalidate the coding loop itself. It only prevents automatic PR or MR creation.

If the user chooses to keep unresolved leftovers and stop, the coding loop is not finalized for PR or MR purposes and closeout is incomplete by user choice.

## Output

Structure finalizer output in this order:

1. final readiness status
2. status synthesized from `execution.md` and `review.md`
3. remaining files, worktrees, branches, or other leftover state, if any
4. supported remote provider status or unsupported or unknown provider status
5. PR or MR action taken, pending, declined, unsupported, or blocked
6. loop finished message when applicable

When finalization is complete:

- tell the user the loop is finished
- tell the user that any new loop should start from a cleared context

For Claude Code and OpenCode, say exactly: `The coding loop is finished. If you start another loop, run /clear first and begin from an empty context.`

For Codex runtimes that use the same slash-command syntax, say exactly: `The coding loop is finished. If you start another loop, run /clear first and begin from an empty context.`

If a runtime uses a different syntax, define one exact sentence for that runtime and use it verbatim.

Do not offer to start another skill from the current context.