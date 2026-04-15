---
name: coding-loop-finaliser
description: Close out a completed coding loop by checking for leftover changes, unmerged worktrees, and supported remote providers, then optionally preparing a PR or MR. Use after review confirms the work is ready to finish.
---

# Coding Loop Finaliser

## Overview

Use this skill after review is complete and the work is ready to close. Check the recorded execution and review status, surface any leftover repository state, and offer to open a pull request or merge request when the remote provider is supported.

## Workflow

0. Require one argument: the planning folder path in the form `.project_planning/YYYY-MM-DD_FEATURE_NAME/`. If it is missing or does not match that shape, stop and ask for the correct path.
1. Read `overview.md`, `execution.md`, and `review.md` from the planning folder.
2. Confirm from `review.md` that review has passed. If review is missing or failing, stop and report that finalization cannot proceed yet.
3. Extract only the `## Overview` section from `overview.md` and use it as the high-level feature intent.
4. Use `execution.md` and `review.md` to summarize completed work, deviations, and residual risk.
5. Check the repository for uncommitted files, untracked files, and any leftover worktrees or branches from the loop.
6. If leftover files exist, list them and ask the user whether to commit, discard, or keep them.
7. If leftover worktrees exist, inspect what work is in them and ask the user what to do about each one.
8. Identify the active remote provider from the repository remote.
9. If the provider is supported, prepare a PR or MR proposal using the provider's exact CLI flow from the matrix below.
10. Build the PR or MR title from the high-level feature name. Keep it concise and descriptive.
11. Build the PR or MR body from `overview.md` by reusing only the `## Overview` section, then add `**Changes:**` followed by bullet points derived from commit messages only.
12. Ask the user to confirm before creating the PR or MR.
13. If the provider is unsupported or unclear, say so explicitly and stop.
14. Keep the closeout brief, factual, and limited to repository state plus release actions.

## Provider Matrix

- GitHub: use `gh pr create --title <title> --body <body> --base <target> --head <branch>`.
- GitLab: use `git push -o merge_request.create -o merge_request.target=<target> origin <branch>`.
- Azure DevOps: use `az repos pr create --title <title> --description <body> --source-branch <branch> --target-branch <target>`.
- Gitea-compatible AGit servers: use `git push origin HEAD:refs/for/<target> -o topic=<topic> -o title=<title> -o description=<body>`.
- Bitbucket Cloud / Bitbucket Data Center: no documented standard CLI flow is available here for automatic PR creation; treat as unsupported and do not guess.

## Shared Rules

- Do not reopen implementation unless the user asks for more changes.
- Do not duplicate the reviewer’s findings; synthesize them into the final status.
- Do not guess about leftover files, worktrees, or remote provider support.
- Do not guess about provider-specific PR or MR commands; use the matrix above.
- Do not create a PR or MR without user confirmation.
- Do not diff-analyze the codebase to build the PR or MR body; use commit messages only for the bullet list.
- Do not treat a missing or failing `review.md` as good enough to finalize.

## Output

- Final status.
- Status from `execution.md` and `review.md`.
- Remaining files or worktrees, if any.
- Supported remote provider or unsupported/unknown status.
- Offer to create a PR or MR when supported.
- When finalization is complete, tell the user the loop is finished. If the runtime supports slash commands and they are starting a new loop, you may suggest `/clear`.
