.PHONY: install-skills

SKILL_FILES := $(shell find skills -name SKILL.md -type f | sort)
GLOBAL_SKILL_DIRS := \
	$$HOME/.agents/skills \
	$$HOME/.claude/skills \
	$$HOME/.junie/skills \
	$$HOME/.cursor/skills \
	$$HOME/.config/opencode/skills

install-skills:
	@set -eu; \
	for skill_file in $(SKILL_FILES); do \
		skill_dir="$$(dirname "$$skill_file")"; \
		skill_name="$$(awk -F': *' '/^name:/ { print $$2; exit }' "$$skill_file")"; \
		if [ -z "$$skill_name" ]; then \
			echo "Missing frontmatter name in $$skill_file" >&2; \
			exit 1; \
		fi; \
		for dest_root in $(GLOBAL_SKILL_DIRS); do \
			mkdir -p "$$dest_root"; \
			rm -rf "$$dest_root/$$skill_name"; \
			cp -R "$$skill_dir" "$$dest_root/$$skill_name"; \
		done; \
	done
