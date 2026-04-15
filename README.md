# ai-bits-and-pieces

This repository collects reusable coding-agent prompts, skills, and supporting prompt fragments.

## Layout

- `skills/` contains reusable skills.
- `skills/<category>/<skill_name>/SKILL.md` is the main skill file.
- `skills/<category>/<skill_name>/agents/openai.yaml` holds UI metadata when needed.
- `skills/<category>/<skill_name>/references/` holds longer reference material.
- `skills/<category>/<skill_name>/scripts/` holds deterministic helper scripts.
- `skills/<category>/<skill_name>/assets/` holds output templates or other bundled files.
- `system_prompts/` holds local system prompt variants.

## Skill Format

All skills in this repository should follow the same structure:

1. `SKILL.md` with YAML frontmatter containing only:
   - `name`
   - `description`
2. A short Markdown body that defines the skill workflow and guardrails.
3. Optional resource folders only when they are actually needed.

Recommended `SKILL.md` sections:

- `Overview`
- `Workflow`
- `Artifacts`
- `Research Rule`
- `Plan Structure`
- `Interaction Policy`

Keep the skill body concise. Put long reference material in `references/` instead of expanding `SKILL.md`.

## Naming

- Repository paths use underscores, for example `skills/coding_loop/planner/`.
- Skill names inside frontmatter use the canonical trigger name for the skill.
- Keep directory names short and filesystem-safe.

## Planning Skills

The `skills/coding_loop/planner/` skill is the canonical example for planning workflows.

Its key rules are:

- Ask for a high-level description if the user only invokes the skill by name.
- Do not write planning files until the feature is well understood.
- Create `.project_planning/YYYY-MM-DD_FEATURE_NAME/` before generating planning artifacts.
- Write the initial request, high-level overview, and decision log in one `overview.md` file.
- Offer optional research every time.
- If research is used, run it in a sub-agent with the smallest useful context and a restricted write scope.
- Keep all planning writes inside the planning directory.
- Treat the loop as a chain: `planner` -> `executor` -> `reviewer` -> `finaliser`.
- Keep the chain rules in `skills/coding_loop/README.md` so sibling skills stay aligned.
- After the planner finishes, suggest `/clear` and hand off to `executor` with the planning folder path.
- Require the planning folder path for `executor`, `reviewer`, and `finaliser`; if it is missing, they must stop and ask for it.

## Coding Loop Skills

The `coding_loop` family currently includes:

- `planner`
- `executor`
- `reviewer`
- `finaliser`

Each one should stay narrow and should reference the shared chain contract instead of duplicating logic.

## Adding a New Skill

1. Create `skills/<category>/<skill_name>/`.
2. Add `SKILL.md` with the required frontmatter and workflow.
3. Add `agents/openai.yaml` if the skill should appear in a skill list UI.
4. Add `references/`, `scripts/`, or `assets/` only when needed.
5. Keep the new skill aligned with the structure used by the existing skills.

## Installing Skills

Use `make install-skills` to copy every skill in this repository into the global skill locations for Codex, Claude, Junie, Cursor, and OpenCode.
