# AGENTS.md Standards for Go Projects

This reference defines what a well-structured AGENTS.md should contain for a Go codebase. Use it to audit existing AGENTS.md files and recommend additions.

## Required sections

### 1. Project overview

A 2-3 sentence description of what the project is, its primary architecture pattern, and the Go version it targets. An agent reading this should immediately understand the domain and scope.

**What to check for:**
- Is the project's purpose stated clearly?
- Is the architecture named (CLI, TUI, API server, library, agent)?
- Is the Go version specified?

### 2. Build and test commands

Exact commands to build, test, lint, and run the project. No ambiguity - copy-pasteable.

**Must include:**
- `go build` target (or `make` equivalent)
- `go test` invocation (with any flags like `-race`, `-count=1`)
- Lint command if applicable (`go vet`, `staticcheck`, `golangci-lint`)
- How to run the application locally

**What to check for:**
- Are the commands actually correct and up to date?
- Are there prerequisite steps (env vars, config files)?

### 3. Package layout

A map of the package structure with a one-line description of each package's purpose. This is the single most important section for preventing architectural drift.

**Format:**
```
project/
  cmd/           - entry points
  internal/      - private packages
  agent/         - core agent loop, conversation management
  tui/           - terminal UI components (Bubble Tea)
  tools/         - tool implementations (filesystem, shell, etc.)
  config/        - configuration loading and validation
  types/         - shared type definitions
```

**What to check for:**
- Does every package have a stated purpose?
- Are the boundaries clear (what goes where)?
- Is there guidance on when to create a new package vs extend an existing one?

### 4. Code style and conventions

Concrete rules that go beyond `gofmt`. These are the project-specific decisions that an agent must follow.

**Should cover:**
- Error handling pattern: wrapping style, sentinel errors, when to use custom error types
- Naming conventions beyond Go defaults (e.g., receiver naming, acronym casing)
- Logging approach (structured? which library? when to log vs return error?)
- Comment requirements (doc comments on all exports? internal TODOs format?)
- Import grouping order (stdlib, external, internal)

**What to check for:**
- Are the rules specific enough to be unambiguous? "Use good error handling" is useless. "Wrap errors with `fmt.Errorf('doing X: %w', err)` using a lowercase verb phrase describing the action" is actionable.
- Do the rules match what the code actually does? If the rules say one thing and the code does another, the rules need updating or the code needs fixing - but they must agree.

### 5. File organisation rules

When to create new files, how to name them, maximum file size guidance.

**Should cover:**
- Maximum recommended file size (e.g., "keep files under 300 lines; split at 500")
- File naming conventions (e.g., `foo_bar.go` not `fooBar.go`)
- One type per file vs grouping: what is the project's preference?
- Test file placement (`foo_test.go` alongside `foo.go`)

### 6. Architecture boundaries

Rules about what can depend on what. This prevents the dependency graph from degrading.

**Should cover:**
- Dependency direction: which packages may import which
- What must NOT be imported by core logic (e.g., TUI packages, specific frameworks)
- Where shared types live and how to avoid circular imports
- Interface ownership: who defines the interface, who implements it

### 7. Testing expectations

What level of testing is expected and how tests should be structured.

**Should cover:**
- Which packages require tests
- Test naming conventions
- Table-driven test preference
- Mock/stub approach
- Integration vs unit test distinction

### 8. Change workflow

How changes should be made - particularly important for agent consumers.

**Should cover:**
- One concern per commit
- Build must pass after every change (`go build ./...`, `go vet ./...`)
- Test must pass after every change
- How to handle changes that touch many files (rename, refactor)

---

## Quality checklist for auditing an existing AGENTS.md

When evaluating an existing AGENTS.md, check each point:

- [ ] Every instruction is concrete and actionable (no "write clean code")
- [ ] Rules do not contradict each other
- [ ] Rules match the actual codebase (or the plan explicitly addresses the gap)
- [ ] Package purposes are documented
- [ ] Dependency direction is stated
- [ ] Error handling pattern is specified
- [ ] File size guidance exists
- [ ] Build/test/lint commands are present and correct
- [ ] The document is concise enough that an agent will actually read and follow it (under 200 lines is ideal; over 400 lines risks being ignored)
- [ ] No sections are aspirational-only ("we should eventually...") - every rule should apply now
