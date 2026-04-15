# Repository Instructions

Read this file before changing anything in this repository.

## Purpose

This repository stores reusable coding-agent prompts, skills, and prompt fragments.

## Conventions

- Keep skill directories in `skills/<category>/<skill_name>/`.
- Use underscore-separated directory names in the repository path, not hyphens.
- Keep each skill structurally consistent with the others.
- Keep `SKILL.md` as the primary skill entry point.
- Keep skill metadata minimal: `name` and `description` only in YAML frontmatter.
- Use optional companion files only when they materially help the skill:
  - `agents/openai.yaml`
  - `references/`
  - `scripts/`
  - `assets/`
- For chained skills, keep the sequence explicit and shared through a common reference file.

## Skill Format

- `description` must explain what the skill does and when to use it.
- The body of `SKILL.md` must define the workflow, output artifacts, and guardrails.
- If a skill supports multiple stages or modes, describe the core workflow first and keep variants compact.
- If a skill changes its format or conventions, update `README.md` in the same change.

## Working Rules

- Do not change files outside the requested scope.
- Preserve existing skill conventions when adding new skills.
- For planning-oriented skills, keep any generated planning artifacts under `.project_planning/` only.
- For chained skills, document the handoff boundary clearly so a later skill can continue without guessing.
- The `coding_loop` family should stay ordered as `planner` -> `executor` -> `reviewer` -> `finaliser`.
