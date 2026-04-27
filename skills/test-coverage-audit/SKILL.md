---
name: test-coverage-audit
description: Analyse a codebase for test coverage gaps and generate a prioritised, actionable plan to plug those gaps with a well-balanced spread of unit and functional tests. Use this skill whenever the user asks to improve test coverage, find untested code, write a test plan, identify missing tests, audit test quality, or increase confidence in their test suite. Triggers include phrases like "what's not tested", "coverage gaps", "write tests for this", "where do we need tests", "test plan", "add unit tests", "add integration tests", "improve test coverage", "our tests are weak", or any request to systematically assess or improve the testing posture of a project. Use this even when the user phrases it casually ("we barely have any tests - help") or technically ("generate a test plan targeting lines with no coverage"). Do NOT use for reviewing a single specific test file or writing one-off tests for a single function the user has already identified.
---

# Test Coverage Audit & Plan Generator

This skill performs a systematic analysis of a codebase's test coverage and produces two deliverables:

1. **A test gap report** - a ranked inventory of untested or under-tested areas, classified by risk and test type.
2. **A test implementation plan** - an ordered sequence of discrete test-writing tasks that a coding agent can execute step by step, with a healthy balance of unit tests and functional/integration tests.

---

## Phase 1: Survey

Build a complete picture of the project before drawing any conclusions.

### 1.1 Read foundational files

Read these first if they exist:

- `AGENTS.md` / `CLAUDE.md` / `CURSOR.md` - agent conventions, test commands
- `README.md` - project purpose and architecture overview
- Build manifest (`package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `pom.xml`, etc.) - language, framework, test runner
- CI config (`.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`) - what the pipeline currently runs
- Existing test config (`jest.config.*`, `pytest.ini`, `vitest.config.*`, `go test` flags, etc.)

Note the test runner, any coverage tooling already configured, and any existing coverage thresholds or exclusions.

### 1.2 Structural inventory

```bash
# Language-agnostic: map all source files and test files
find . -type f \( -name '*.go' -o -name '*.ts' -o -name '*.tsx' -o -name '*.js' \
  -o -name '*.jsx' -o -name '*.py' -o -name '*.rs' -o -name '*.java' \
  -o -name '*.kt' -o -name '*.rb' -o -name '*.cs' \) \
  -not -path '*/node_modules/*' -not -path '*/vendor/*' \
  -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/build/*' \
  | sort

# Identify test files by convention (adapt pattern to language)
find . -type f \( \
  -name '*_test.go' -o -name '*.test.ts' -o -name '*.spec.ts' \
  -o -name '*.test.js' -o -name '*.spec.js' -o -name 'test_*.py' \
  -o -name '*_test.py' -o -name '*_test.rs' -o -name '*Test.java' \
  -o -name '*_spec.rb' \
) \
  -not -path '*/node_modules/*' -not -path '*/vendor/*' \
  | sort
```

Record:
- Total source file count and test file count
- Ratio of test files to source files
- Which directories/packages have zero test files
- Test files that exist but are suspiciously small (stubs, empty `describe` blocks)

### 1.3 Run coverage tooling (if available and safe)

Only run coverage if a test command is already configured and the project has existing tests. Do not install new tooling unless the user explicitly asks.

```bash
# Go
go test ./... -coverprofile=coverage.out 2>/dev/null && go tool cover -func=coverage.out

# Node/TypeScript (if jest configured)
npx jest --coverage --coverageReporters=text 2>/dev/null

# Python (if pytest + pytest-cov configured)
python -m pytest --cov --cov-report=term-missing 2>/dev/null

# Rust
cargo tarpaulin --out Stdout 2>/dev/null
```

If coverage tooling produces output, parse it for:
- Files with 0% coverage
- Files with < 50% coverage
- Files with > 80% coverage (already well-tested - lower priority)
- Specific uncovered lines or branches

If tooling is not available or produces errors, proceed with static analysis only. Note this limitation in the report.

### 1.4 Read key source files

For each package/module identified as having low or no coverage, read the source file(s). Focus on:
- Exported/public functions and methods
- Core domain logic
- Error paths and edge cases
- State transitions
- External integrations (HTTP clients, DB access, queues, file I/O)

---

## Phase 2: Gap Analysis

For each source file or module, classify its test coverage status and risk level.

### 2.1 Coverage classification

Assign each file/module one of:

| Status | Meaning |
|---|---|
| `untested` | No test file exists, or test file exists but has no assertions targeting this file |
| `partial` | Tests exist but significant paths are uncovered (< 60% or key branches missing) |
| `stub-only` | Test file exists but contains only empty test functions or placeholder comments |
| `well-tested` | > 80% coverage with meaningful assertions (not just happy-path smoke tests) |

### 2.2 Risk scoring

Score each gap by risk using these factors:

**Code risk factors (raise risk):**
- Contains business logic or domain rules
- Handles money, authentication, authorisation, or security checks
- Parses, transforms, or validates user input
- Manages state that persists across requests/sessions
- Is called from many places (high fan-in)
- Has complex branching logic (multiple if/switch arms, error paths)
- Wraps an external dependency (DB, HTTP, file system, queue)

**Code risk factors (lower risk):**
- Pure glue code / dependency wiring
- Simple CRUD with no logic beyond pass-through
- UI rendering only (no logic)
- Configuration loading (tested implicitly by integration tests)
- Auto-generated code

Score: `critical` / `high` / `medium` / `low`

### 2.3 Test type classification

For each gap, determine the most appropriate test type(s):

| Type | When to use |
|---|---|
| `unit` | Pure logic, no I/O, easily isolated. Test the function directly with mocked dependencies. |
| `unit-with-mock` | Logic that calls external dependencies. Mock the dependency boundary; test the logic. |
| `functional` | End-to-end behaviour of a feature or user-facing flow. Drives the system through its public interface. |
| `integration` | Tests that wire real components together (real DB, real HTTP calls). Higher cost but higher confidence for integration points. |
| `property` | Suitable for parsing, serialisation, encoding, or logic with large input spaces. Use a property/fuzz library. |
| `contract` | For API boundaries or shared interfaces between services. |

Most coverage gaps should be addressed primarily with `unit` and `unit-with-mock` tests, supplemented by `functional` tests for key user-facing flows. Integration tests are high-value but high-cost - recommend them sparingly for critical integration points only.

**Target mix guidance:**
- 60-70% unit / unit-with-mock
- 20-30% functional
- 5-15% integration

---

## Phase 3: Plan Generation

### Ordering principles

Order test tasks so that:
1. `critical` gaps are addressed first, regardless of test type.
2. Within the same severity, `unit` tests come before `functional` - they are faster to write and provide the feedback loop needed to validate assumptions before writing functional tests.
3. Functional tests that cut across multiple modules come after the unit tests for those modules.
4. Integration tests come last - they are the most expensive and fragile.
5. Within a severity tier, prefer modules that are imported by many others (testing them first gives broader coverage lift).

### Task format

Each task in the plan must contain exactly these fields:

```markdown
### Task N: [Short descriptive title]

**Test type**: [unit | unit-with-mock | functional | integration | property | contract]
**Risk**: [critical | high | medium | low]
**Target**: [file(s) or module(s) being tested]
**New test file**: [path where the new test file should be created]
**Depends on**: [task numbers this depends on, or "none"]

**What is untested**:
[2-3 sentences describing the specific gap. Reference concrete function names, branches, or behaviours that are currently not covered. Be precise.]

**What to test**:
[Bulleted list of specific test cases to write. Each bullet should be a concrete scenario: inputs, expected outputs or side effects, and any important edge cases. Include at least one unhappy-path/error case per task.]

**Mocking / test infrastructure needed**:
[Any new mocks, fakes, fixtures, test helpers, or test data that need to be created first. "None" if no new infrastructure is needed. If this is a new mock, describe its interface.]

**Verification**:
[The command to run to confirm the tests pass and coverage improves. Include coverage flag if available.]
```

### Plan document structure

Write the plan to disk at:

```
.project_planning/test-coverage-plan.md
```

Create the `.project_planning/` directory if it does not exist. Use the `create_file` tool. After writing, tell the user the file path and summarise the task count and severity breakdown in one sentence.

The document content:

```markdown
# Test Coverage Audit & Plan: [Project Name]

## Executive Summary
[4-6 sentences: language/framework, total files analysed, current coverage level (if measurable), number of gaps found by severity, recommended test mix, estimated effort tier (small/medium/large).]

## Coverage Baseline
[Table: file or module | current status | risk | recommended test type(s)]
Omit well-tested files from the table unless they have notable quality issues.

## Key Findings
[3-5 bullet points calling out the most important structural observations: e.g. "All database access code is untested", "Happy-path unit tests exist but no error paths are covered", "No functional tests exist for the authentication flow".]

## Test Infrastructure Assessment
[What mocking/fixture/factory infrastructure already exists and what needs to be created before the plan tasks can be executed. Include any test helper libraries that should be added.]

## Implementation Plan

### Task 1: ...
### Task 2: ...
...

## Coverage Target
[Recommended coverage % target by file type or package, and why. Don't over-specify: "90% line coverage on all business logic packages; 70% on integration wrappers; no target for generated code" is more useful than a single project-wide number.]

## Notes
[Caveats, risks, or decisions for the user. E.g. "The database layer would benefit from integration tests but this requires a test database - suggest using testcontainers or a local Docker Compose fixture."]
```

---

## Important guidelines

- **Never write the actual tests in the plan.** The plan describes what to test and how. A coding agent executes the tasks. Keep the plan document as instructions, not implementation.
- **Be specific about function names.** "Test the auth module" is useless. "Test `validateToken` in `auth/jwt.go`: valid token, expired token, malformed token, missing claims" is actionable.
- **Balance is mandatory.** Do not produce a plan that is 100% unit tests. Every plan must include at least 2-3 functional tests that exercise user-facing flows end-to-end. Call out explicitly where functional tests are most valuable.
- **Respect existing patterns.** If the project already uses a specific mock library or test helper pattern, the plan should use the same. Do not introduce new testing paradigms without flagging it as a deliberate suggestion.
- **Do not target generated code.** If files are auto-generated (proto, GraphQL codegen, ORM migrations), exclude them from coverage targets.
- **Flag test quality issues.** If test files exist but contain only happy-path assertions, flag this as a gap even if line coverage looks good. Branch coverage and error-path coverage matter.
- **Size the effort honestly.** Estimate task effort as `S` (< 30 min), `M` (30-90 min), or `L` (> 90 min). Include these in the task header. A plan with 20 `L` tasks is not useful without that context.
- **Recommend coverage thresholds.** The plan should end with a concrete recommendation for what coverage gates to add to CI, not just "add more tests".

---

## Language-specific notes

See `references/language-notes.md` for test runner commands, mock library recommendations, and coverage flag syntax for Go, TypeScript/JavaScript, Python, Rust, Java, and Ruby.

Read the relevant section when you need the exact CLI invocations or library recommendations for the project's language.
