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
- `overview.md` alone means the task is still in planning or discussion.
- The task is execution-ready only when both `overview.md` and `plan.yaml` exist.
- `execution.md` is the executor's handoff artifact for implementation status and verification.
- `review.md` is the reviewer's handoff artifact for findings, review-fix work, and final pass or fail status.

## Planner

- Gather the request.
- Ask for a high-level description if needed.
- Delay file creation until the feature is understood.
- Write `overview.md` first.
- Render the full `overview.md` contents in the assistant response itself, preserving its markdown structure as normal user-facing formatting for the current medium.
- Do not rely on shell output, tool transcripts, or summaries as a substitute for showing the document.
- Do not present the document as raw file text, a quoted blob, or a fenced code block unless the user explicitly asks for raw markdown.
- Do not write `plan.yaml` until the user has discussed the overview and explicitly asked to proceed.
- Hand off to executor only when both files exist.
- When planning is complete, give the user the planning folder path and the next skill to run. If the runtime supports slash commands, you may suggest `/clear` and `/coding-loop-executor .project_planning/FEATURE`.

## Executor

- Consume the approved plan.
- Require the planning folder path before doing anything.
- Require both `overview.md` and `plan.yaml`; otherwise stop and report that planning is incomplete.
- Create branch `cl/YYYY-MM-DD_FEATURE_NAME` before executing steps.
- Give each implementation step its own worktree and merge it back after the sub-agent finishes.
- Resolve merge conflicts as they happen.
- Ask sub-agents to keep commits minimal, with one descriptive commit preferred unless more are needed.
- Implement only the current stage or step.
- Prefer isolated, incremental changes.
- Write `execution.md` with completed steps, deviations, verification results, and branch state.
- Report blockers instead of guessing.
- When execution is complete, give the user the planning folder path and the next skill to run. If the runtime supports slash commands, you may suggest `/clear` and `/coding-loop-reviewer .project_planning/FEATURE`.

## Reviewer

- Review the implemented changes against the plan.
- Require the planning folder path before doing anything.
- Read `execution.md` before reviewing the current tree.
- Look for regressions, missing tests, or scope drift.
- Report findings before suggesting cleanup.
- If the user confirms fixes, generate a review-scoped fix plan, implement it sequentially, and commit each fix step separately.
- Write `review.md` with findings, fix-plan status, residual risk, and final pass or fail.
- When review is complete, give the user the planning folder path and the next skill to run. If the runtime supports slash commands, you may suggest `/clear` and `/coding-loop-finaliser .project_planning/FEATURE`.

## Finaliser

- Confirm the requested work is complete.
- Require the planning folder path in the form `.project_planning/YYYY-MM-DD_FEATURE_NAME/`.
- Read `overview.md`, `execution.md`, and `review.md` from that planning folder.
- Confirm that `review.md` records a passing review before offering release actions.
- Extract the `## Overview` section from `overview.md`.
- Check for uncommitted changes, untracked files, and leftover worktrees.
- Ask the user what to do with any leftover state instead of guessing.
- Detect the active remote provider and offer to create a PR or MR when supported.
- Use the provider's exact CLI flow, not a guessed one.
- GitHub: `gh pr create --title ... --body ... --base ... --head ...`.
- GitLab: `git push -o merge_request.create -o merge_request.target=<target> origin <branch>`.
- Azure DevOps: `az repos pr create --title ... --description ... --source-branch ... --target-branch ...`.
- Gitea-compatible AGit servers: `git push origin HEAD:refs/for/<target> -o topic=... -o title=... -o description=...`.
- Bitbucket Cloud / Data Center: unsupported for automatic PR creation in this loop.
- Build the PR/MR title from the high-level feature name.
- Build the PR/MR description from the `## Overview` in `overview.md` plus `**Changes:**` followed by bullet points derived from commit messages only.
- If the remote provider is unsupported or unclear, say so explicitly.
- When finalization is complete, tell the user that the loop is finished. If the runtime supports slash commands and they are starting a new loop, you may suggest `/clear`.
