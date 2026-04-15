---
name: coding-loop-finaliser
description: Close out a completed coding loop by summarizing outcome, residual risk, and next steps. Use after review confirms the work is ready to finish.
---

# Coding Loop Finaliser

## Overview

Use this skill after review is complete and the work is ready to close. Capture the final outcome, any follow-up, and the remaining risk surface.

## Workflow

0. Require the planning folder path as input. If it is missing, stop and ask for it.
1. Read the plan, execution output, and review findings.
2. Confirm that the requested task is done or note what remains.
3. Summarize the result in direct, user-facing language.
4. Record any residual risk or future follow-up.
5. Keep the closeout brief and factual.

## Shared Rules

- Do not reopen implementation unless the user asks for more changes.
- Do not duplicate the reviewer’s findings; synthesize them into the final status.

## Output

- Final status.
- Short change summary.
- Remaining risk or follow-up, if any.
- When finalization is complete, tell the user the loop is finished and to clear context with `/clear` if they are starting a new loop.
