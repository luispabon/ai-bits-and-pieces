# Language-Specific Notes: Test Coverage Audit

## Go

### Coverage commands
```bash
# Run tests with coverage profile
go test ./... -coverprofile=coverage.out

# Human-readable summary (per-function)
go tool cover -func=coverage.out

# HTML report (opens in browser)
go tool cover -html=coverage.out

# Coverage percentage only
go test ./... -cover

# Race detection (recommended for concurrent code)
go test ./... -race -coverprofile=coverage.out
```

### Identifying stubs
```bash
# Find test files with no actual assertions (no t.Error, t.Fatal, testify require/assert)
grep -rL 't\.Error\|t\.Fatal\|assert\.\|require\.' --include='*_test.go' .
```

### Mock libraries (in preference order)
- `github.com/stretchr/testify/mock` - standard, widely used
- `go.uber.org/mock` (mockgen) - interface mocks via code generation
- `github.com/vektra/mockery` - generates testify mocks from interfaces

### Test helpers
- `github.com/stretchr/testify/assert` + `require` - assertions
- `github.com/testcontainers/testcontainers-go` - Docker-based integration test deps
- Table-driven tests are idiomatic Go - recommend for any function with multiple input cases

### Coverage threshold in CI
```yaml
# GitHub Actions example
- run: go test ./... -coverprofile=coverage.out
- run: go tool cover -func=coverage.out | tail -1 | awk '{if ($3+0 < 70) exit 1}'
```

---

## TypeScript / JavaScript (Jest / Vitest)

### Coverage commands
```bash
# Jest
npx jest --coverage
npx jest --coverage --coverageReporters=text-summary
npx jest --coverage --collectCoverageFrom='src/**/*.{ts,tsx}'

# Vitest
npx vitest run --coverage
npx vitest run --coverage --reporter=verbose
```

### jest.config coverage threshold
```js
// jest.config.js
module.exports = {
  coverageThreshold: {
    global: { lines: 70, functions: 70, branches: 60 }
  }
}
```

### Identifying stubs
```bash
# Test files with no expect() calls
grep -rL 'expect(' --include='*.test.ts' --include='*.spec.ts' .
```

### Mock libraries
- `jest.fn()` / `jest.mock()` - built-in, prefer for unit tests
- `msw` (Mock Service Worker) - HTTP mocking for functional tests
- `@testing-library/react` - for React component tests
- `supertest` - for HTTP functional tests (Express/Fastify/etc.)

### Test types by file pattern
- `*.unit.test.ts` or `*.test.ts` in `src/` - unit tests
- `*.spec.ts` in `tests/` or `e2e/` - functional/integration
- `*.stories.tsx` - Storybook (not counted as test coverage)

---

## Python (pytest)

### Coverage commands
```bash
# Basic run
python -m pytest --cov=src --cov-report=term-missing

# With branch coverage (recommended)
python -m pytest --cov=src --cov-branch --cov-report=term-missing

# HTML report
python -m pytest --cov=src --cov-branch --cov-report=html
```

### .coveragerc or pyproject.toml threshold
```toml
# pyproject.toml
[tool.coverage.report]
fail_under = 70
```

### Identifying stubs
```bash
# Test files with no assert statements
grep -rL 'assert\b' --include='test_*.py' .
```

### Mock libraries
- `unittest.mock` (stdlib) - standard, always available
- `pytest-mock` (`mocker` fixture) - cleaner pytest integration
- `respx` or `responses` - HTTP mocking
- `factory_boy` - fixture factories for ORM models
- `pytest-django` / `pytest-fastapi` - framework-specific test helpers

### Test organisation
- Unit tests: `tests/unit/`
- Integration tests: `tests/integration/`
- Functional/e2e: `tests/functional/` or `tests/e2e/`

---

## Rust

### Coverage commands
```bash
# Using cargo-tarpaulin (install once: cargo install cargo-tarpaulin)
cargo tarpaulin --out Stdout

# With branch coverage
cargo tarpaulin --out Stdout --engine llvm

# Using llvm-cov (nightly)
cargo llvm-cov
```

### Test structure
```rust
// Unit tests: inline #[cfg(test)] module in same file
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn test_foo() { ... }
}

// Integration tests: tests/ directory at crate root
// Functional tests: examples/ or integration test crates in workspace
```

### Mock libraries
- `mockall` - attribute-based mock generation
- `wiremock` - HTTP mock server for integration tests
- `proptest` / `quickcheck` - property-based testing

---

## Java / Kotlin

### Coverage commands
```bash
# Maven + JaCoCo
mvn test jacoco:report
# Report at: target/site/jacoco/index.html

# Gradle + JaCoCo
./gradlew test jacocoTestReport
# Report at: build/reports/jacoco/test/html/index.html
```

### JaCoCo threshold (build.gradle)
```groovy
jacocoTestCoverageVerification {
    violationRules {
        rule { limit { minimum = 0.70 } }
    }
}
```

### Identifying stubs
```bash
# JUnit test methods with no assertions
grep -rL '@Test\|assertEquals\|assertThat\|assertTrue' --include='*Test.java' .
```

### Mock libraries
- `Mockito` - standard Java mock library
- `MockK` - idiomatic Kotlin mocks
- `WireMock` - HTTP mock server
- `Testcontainers` - Docker-based integration tests

---

## Ruby

### Coverage commands
```bash
# SimpleCov (add to spec_helper.rb or test_helper.rb)
# require 'simplecov'; SimpleCov.start
bundle exec rspec --format documentation
# Report at: coverage/index.html
```

### Identifying stubs
```bash
# RSpec files with no expectations
grep -rL 'expect\|should\b' --include='*_spec.rb' .
```

### Mock libraries
- `rspec-mocks` (built-in) - doubles, stubs, message expectations
- `webmock` - HTTP request stubbing
- `vcr` - record/replay HTTP interactions
- `factory_bot` - test data factories
