---
name: go-code-audit
description: Audit a Go codebase for code quality issues and generate an ordered, step-by-step refactoring plan that an AI coding agent can execute. Use this skill whenever the user asks to audit, review, clean up, refactor, or improve the structure of a Go project - including requests like "audit my Go code", "clean up this repo", "make this codebase DRY", "refactor plan", "code quality review", "improve my Go project structure", or any mention of consolidating, reorganising, or paying down tech debt in a Go application. Also triggers when the user asks to review or improve an AGENTS.md file for a Go project. Do NOT use for single-file code reviews, PR reviews, or writing new features.
---

# Go Code Audit & Refactoring Plan Generator

This skill performs a comprehensive audit of a Go codebase and produces two deliverables:

1. **A refactoring plan** - an ordered, dependency-safe sequence of discrete steps that an AI coding agent (Claude Code, Codex, etc.) can execute one at a time to bring the codebase to a clean, well-structured state.
2. **An AGENTS.md update** - additions or revisions to the project's AGENTS.md that encode the quality standards and architectural patterns established during the audit, preventing future regression.

The plan targets codebases that have grown organically - "vibe-coded" projects where files have ballooned, logic has been duplicated, conventions have drifted, and no systematic quality pass has been done.

---

## Phase 1: Survey

Before analysing anything, build a complete picture of the project.

### 1.1 Read foundational files

Read these files first if they exist, as they contain project intent and constraints:

- `AGENTS.md` - existing agent instructions, conventions, architectural decisions
- `README.md` - project purpose, architecture overview
- `go.mod` - module name, Go version, dependencies
- `Makefile` or `Taskfile` or build scripts - build/test/lint commands

Take note of any stated conventions, architectural decisions, or constraints. These are guardrails - the audit must respect them unless they are themselves the problem.

### 1.2 Structural inventory

Run the following to build the structural map:

```bash
# File inventory with line counts, sorted largest first
find . -name '*.go' -not -path './vendor/*' | xargs wc -l | sort -rn

# Package structure
find . -name '*.go' -not -path './vendor/*' -exec dirname {} \; | sort -u

# Test file inventory
find . -name '*_test.go' -not -path './vendor/*' | xargs wc -l 2>/dev/null | sort -rn

# Check for available Go tooling
which staticcheck gocyclo dupl 2>/dev/null
```

Record:
- Total line count and file count
- Each file's path and line count
- Which packages exist and their apparent purpose
- Which packages have tests and which do not
- The main entry point (`main.go` or `cmd/` structure)

### 1.3 Dependency graph

Trace internal package imports to understand coupling:

```bash
# Internal import map
grep -rn '"<module-name>/' --include='*.go' | grep -v vendor | grep -v _test.go
```

Identify:
- Which packages import which other packages
- Circular or near-circular dependency chains
- Packages that are imported by everything (these are candidates for a `types` or `internal` package)
- Packages that import everything (these are likely doing too much)

### 1.4 Go tooling pass (if available)

If `go vet`, `staticcheck`, `gocyclo`, or `dupl` are available, run them. These provide hard data that supplements the LLM analysis. Do not hard-depend on them - if they are not installed, proceed with LLM-only analysis. Do not install them unless the user explicitly asks.

```bash
# Always available
go vet ./...

# If installed
staticcheck ./... 2>/dev/null
gocyclo -over 15 . 2>/dev/null
dupl -t 50 . 2>/dev/null
```

Record any findings. These feed into Phase 2.

---

## Phase 2: Analysis

Work through each analysis dimension. For each issue found, record:
- **Location**: file(s) and line range(s)
- **Category**: which dimension it falls under
- **Severity**: critical / high / medium / low
- **Description**: what the problem is, concretely
- **Action**: the specific refactoring move needed
- **Dependencies**: which other issues must be resolved first

### 2.1 Oversized files

**Threshold**: 300 lines is a warning, 500 lines needs splitting.

For each oversized file, determine *why* it is large:
- Multiple unrelated types or functions colocated - split by domain concept
- A single type with many methods - may be fine if cohesive, flag if methods serve different concerns
- Mixed model/view/update logic (common in TUI apps) - split by layer
- Long procedural functions padded with boilerplate - extract and simplify

Produce a specific split recommendation: which types/functions move where, what the new file names should be, what stays. Do not recommend splitting if the file is large but genuinely cohesive.

### 2.2 Duplication

Look for:
- Copy-pasted functions with minor parameter differences - consolidate with parameters or generics
- Repeated error handling boilerplate - extract helper functions
- Similar struct definitions across packages - extract shared types
- Repeated patterns in TUI rendering (common in Bubble Tea / Charm apps) - extract reusable components
- Repeated patterns in command/tool definitions - extract a registry or builder pattern

For each duplication cluster, identify the canonical location and the copies to eliminate.

### 2.3 Function complexity

Flag functions that are:
- Over 50 lines
- Nested more than 3 levels deep (if/for/switch)
- Doing multiple unrelated things (setup + execution + cleanup + logging)
- Using named returns with bare returns (hard to follow in long functions)

For each, recommend specific extract-function operations with proposed names and signatures.

### 2.4 Error handling

Check for consistency in:
- Wrapping style: does the project use `fmt.Errorf("context: %w", err)` consistently?
- Sentinel errors vs string matching
- Swallowed errors (`_ = someFunc()` where the error matters)
- `log.Fatal` or `os.Exit` in non-main packages (these prevent graceful shutdown and break testability)
- Inconsistent error types (sometimes custom error types, sometimes bare strings)

Recommend a single consistent pattern and list each deviation.

### 2.5 Go conventions

Check against idiomatic Go:
- **Naming**: exported names should be meaningful without package qualifier (`config.Config` is fine, `config.ConfigStruct` is not). Receiver names should be 1-2 letters, consistent across methods.
- **Package naming**: lowercase, single-word where possible, no underscores, no `util`/`helper`/`common` grab-bags.
- **Interface design**: interfaces should be small (1-3 methods), defined by the consumer not the implementor. Check for "header interfaces" (large interfaces defined next to their only implementation).
- **Struct organisation**: exported fields first, then unexported. Group logically.
- **Comment quality**: exported symbols should have doc comments. `// Foo does X` not `// This function does X`.

### 2.6 Dead code and unnecessary exports

Identify:
- Exported functions/types/constants only used within their own package - unexport them
- Completely unused functions (not called anywhere, not implementing an interface)
- Unused struct fields
- Commented-out code blocks (remove or explain)
- TODO/FIXME/HACK comments - catalogue these as they often indicate known debt

### 2.7 Package architecture

Evaluate the overall package layout:
- Is there a clear separation of concerns? For a TUI agent, typical layers are: `cmd/` (entry), `tui/` (terminal UI), `agent/` (core loop), `tools/` (tool implementations), `config/`, `types/` or `model/`.
- Are there packages that have become dumping grounds?
- Could internal packages benefit from `internal/` to prevent accidental external use?
- Is the dependency direction clean (UI depends on core, not core on UI)?

### 2.8 Test gaps

Map test coverage:
- Which packages have zero test files?
- Which critical paths (agent loop, tool execution, config parsing) lack tests?
- Are there tests that are actually just `func TestFoo(t *testing.T) {}` stubs?

Do not generate a full test plan - just flag the gaps as input for prioritisation.

---

## Phase 3: AGENTS.md Audit

Read the existing AGENTS.md (from Phase 1) and evaluate it against what a good AGENTS.md for this project should contain. See `references/agents-md-standards.md` for the template.

Produce a diff-style set of recommended additions/changes:
- Missing sections that should exist
- Existing rules that are too vague to be actionable
- Conventions that should be added based on Phase 2 findings (the standards you are about to enforce)
- Rules that contradict each other

The updated AGENTS.md should encode the patterns the refactoring plan establishes, so that future agent work maintains the improved codebase quality.

---

## Phase 4: Plan Generation

This is the primary deliverable. Synthesise all Phase 2 findings into an ordered execution plan.

### Ordering principles

Steps must be ordered so that each step can be executed in isolation without breaking the build. The dependency-safe order is:

1. **Shared types extraction** - move types that are used across packages into their canonical home first. Everything else depends on this.
2. **Interface definitions** - define or refine interfaces before splitting implementations across files.
3. **File splits** - break up oversized files. This is safer after types are settled.
4. **Duplication removal** - replace copies with calls to canonical implementations. Easier after files are cleanly split.
5. **Function extraction** - break down complex functions within now-cleanly-scoped files.
6. **Error handling normalisation** - apply consistent patterns. This touches many files so it goes late.
7. **Convention cleanup** - naming, exports, comments. Cosmetic, so it goes last.
8. **AGENTS.md update** - apply the changes from Phase 3. This goes last because it documents the now-established patterns.

Within each group, order by severity (critical first) then by dependency (upstream packages before downstream).

### Step format

Each step in the plan must contain exactly these fields:

```markdown
### Step N: [Short descriptive title]

**Category**: [types-extraction | interface-definition | file-split | deduplication | function-extraction | error-handling | convention-cleanup | agents-md-update]
**Severity**: [critical | high | medium | low]
**Files**: [list of files touched]
**Depends on**: [step numbers this depends on, or "none"]

**Problem**:
[2-3 sentences describing the concrete problem. Reference specific symbols, line ranges, patterns.]

**Action**:
[Precise instructions for what to do. Name the functions/types to move, the new file to create, the pattern to apply. Be specific enough that an agent can execute without ambiguity.]

**Verification**:
[How to confirm the step was done correctly. Usually: `go build ./...` passes, `go vet ./...` clean, specific tests pass, or a manual check like "function X no longer exists in file Y".]
```

### Plan document structure

The final output is a single markdown document:

```markdown
# Code Audit & Refactoring Plan: [Project Name]

## Audit Summary
[3-5 sentence summary: total files, total lines, number of issues found by severity, biggest problem areas]

## Architecture Overview
[Brief description of the current package layout and what the target layout should look like after refactoring]

## Refactoring Steps

### Step 1: ...
### Step 2: ...
...

## AGENTS.md Recommendations
[The diff-style recommendations from Phase 3]

## Notes
[Any caveats, risks, or decisions the user should weigh before executing]
```

---

## Important guidelines

- **Never recommend rewriting from scratch.** The plan must be incremental. Each step is a small, verifiable change.
- **Preserve behaviour.** This is a structural refactoring, not a feature change. If a function works, it should still work identically after being moved or renamed. Call this out explicitly in each step.
- **Respect existing conventions.** If the project consistently does something a certain way (even if it is not "textbook Go"), flag it but do not silently change it. The plan should note "this deviates from convention but is consistent internally - recommend aligning, user should confirm".
- **Be concrete.** "Consider refactoring this" is useless. "Move `ParseConfig` and `ValidateConfig` from `agent.go` to a new file `config.go` in the same package" is actionable.
- **Keep steps atomic.** Each step should result in a compilable, working codebase. If a rename touches 15 files, that is one step, not fifteen. But if a file split and a function extraction are independent, they are separate steps even if they touch the same file.
- **Calibrate severity honestly.** Critical means "this will cause bugs or makes the codebase unworkable". High means "significant maintenance burden". Medium means "should fix but won't block progress". Low means "polish".
