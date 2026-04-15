---
name: coding-loop-reviewer
description: Review coding changes against the approved plan, identify bugs and regressions, and report concrete findings. Use after execution and before finalization.
---

# Coding Loop Reviewer

## Overview

Use this skill after implementation to compare the changes against the plan and surface concrete issues before the work is finalized.

## Input Contract

- Require one argument: the path to the feature planning folder.
- Fail immediately if the path is missing, does not exist, or does not contain the expected planning artifacts.
- Treat the planning folder as the authoritative source of truth for the task.
- Read the planning files in this order for context and intent:
  - `overview.md` for the original request, the high-level overview, and the decision log
  - `plan.yaml` for the staged implementation contract, step order, and parallelism
  - any `research.md` or `research_*.md` files for background assumptions and technical findings
- Use the planning files as the reference point for scope, intent, and acceptance expectations.

## Workflow

0. Require the planning folder path as input. If it is missing or invalid, stop and ask for the correct path.
1. Scan the current context for coding standards, formatting rules, linting rules, and test-running preferences.
2. Prefer preferences from the latest planner output and repo docs when they exist.
3. If the preferences are missing or ambiguous, ask once before proceeding.
4. Read the current plan and the implemented changes.
5. Compare the implementation against `overview.md`, `plan.yaml`, and any research files for plan and intent adherence.
6. Check code quality, conciseness, repetition, correctness, tests, and obvious regressions.
7. Classify findings by severity and impact.
8. Prefer evidence over speculation.
9. Keep the review focused on the current chain step.
10. If there are no issues, say so and note residual risks or missing validation.
11. If issues exist, generate a concrete fix plan before making changes.
12. Ask the user to confirm the fix plan before implementing it.
13. After fixes are implemented, restart the review from the top against the updated tree.

## Shared Rules

- Review the execution output, not the planner intent alone.
- Own the fix loop once the user confirms the fix plan.
- Do not advance to finalization until review is complete.

## Output

- Findings first, ordered by severity.
- Short summary second.
- Mention any verification gaps or follow-up checks.
- If fixes are needed, include the proposed fix plan and request confirmation before editing files.
- When review is complete, tell the user to clear context with `/clear` and then run `/coding-loop-finaliser .project_planning/FEATURE`.
- The next step of the chain is finaliser.
