# /test-coverage

---
description: Analyze test coverage, identify gaps, and generate tests for untested code
arguments:
  - name: project_path
    description: Path to the project to analyze
    required: true
  - name: --help
    description: Show help message
    required: false
---

# Help Check

If the user passed `--help` as an argument, output the following and stop:

```
/test-coverage - Analyze and improve test coverage

Usage:
  claude /test-coverage <project_path>
  claude /test-coverage --help

Arguments:
  project_path    Path to the project to analyze (required)

Options:
  --help          Show this help message

Examples:
  claude /test-coverage ~/Projects/my-app
  claude /test-coverage .

What it does:
  - Detects test framework (Jest, Vitest, pytest, etc.)
  - Runs coverage analysis
  - Identifies untested code paths
  - Generates PRD with test stories

Coverage targets:
  - Overall: > 80% line coverage, > 70% branch coverage
  - Critical paths (auth, payments): > 90% coverage

Story priority:
  1. Critical path tests (auth, payments, data mutations)
  2. Zero-coverage files
  3. Low-coverage files (< 80%)
  4. Integration tests
  5. API endpoint tests
  6. Test infrastructure improvements
  7. Final verification

Output:
  - prd.json: Test stories for Ralph to execute
  - tests/README.md: Test documentation

What it generates:
  - Unit tests for untested functions
  - Integration tests for component interactions
  - API tests for endpoints
  - Test utilities and factories
```

---

You are a test engineering expert. Your task is to analyze a project's test coverage, identify untested code paths, and generate comprehensive tests.

## Phase 1: Project Analysis

### Step 1.1: Detect Test Framework

Scan for test configuration:

```bash
# JavaScript/TypeScript
cat package.json | jq '.devDependencies | keys[]' | grep -E 'jest|vitest|mocha|ava|tap'
ls jest.config.* vitest.config.* .mocharc.* 2>/dev/null

# Python
ls pytest.ini pyproject.toml setup.cfg conftest.py 2>/dev/null
grep -l "pytest\|unittest" requirements*.txt 2>/dev/null

# Go (built-in testing)
find . -name "*_test.go" -type f | head -5

# Ruby
ls spec/ test/ .rspec Rakefile 2>/dev/null

# Rust
grep '\[dev-dependencies\]' Cargo.toml
```

### Step 1.2: Run Coverage Analysis

Execute coverage tools:

**JavaScript/TypeScript:**
```bash
# Jest
npx jest --coverage --coverageReporters=json-summary --coverageReporters=text

# Vitest
npx vitest run --coverage

# NYC/Istanbul
npx nyc --reporter=json-summary npm test
```

**Python:**
```bash
pytest --cov=. --cov-report=json --cov-report=term
```

**Go:**
```bash
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
```

**Ruby:**
```bash
# With SimpleCov configured
bundle exec rspec --format json
```

### Step 1.3: Identify Coverage Gaps

Parse coverage reports to find:
- Files with < 80% line coverage
- Files with < 70% branch coverage
- Functions/methods with 0% coverage
- Critical paths without tests (auth, payments, data mutations)

### Step 1.4: Analyze Code Complexity

Find high-complexity untested code:
```bash
# JavaScript - find complex functions
npx eslint --rule 'complexity: [error, 5]' src/ 2>&1 | grep -E 'complexity'

# Look for untested critical files
find src -name "*.ts" -o -name "*.js" | xargs grep -l "password\|auth\|payment\|delete\|admin"
```

## Phase 2: Collect Test Patterns

### Step 2.1: Analyze Existing Tests

Read existing tests to understand patterns:
- Test file naming convention
- Import patterns
- Mock/stub patterns
- Assertion style
- Setup/teardown patterns
- Test data patterns

### Step 2.2: Identify Test Types Needed

Categorize gaps by test type:
- **Unit tests**: Individual functions/methods
- **Integration tests**: Component interactions
- **API tests**: Endpoint testing
- **Component tests**: UI component testing
- **E2E tests**: Full flow testing

## Phase 3: Generate PRD

```json
{
  "project": "{project_name}",
  "mode": "feature",
  "branchName": "ralph/test-coverage",
  "baseBranch": "main",
  "description": "Improve test coverage across the codebase",
  "userStories": []
}
```

### Story Templates

#### Category 1: Critical Path Tests (Priority 1)

```json
{
  "id": "TEST-CRIT-001",
  "title": "Add tests for authentication flows",
  "description": "Ensure all auth code paths have test coverage",
  "acceptanceCriteria": [
    "IDENTIFY: Map all auth-related functions and their current coverage",
    "IDENTIFY: List edge cases: invalid credentials, expired tokens, rate limiting",
    "FIX: Write unit tests for login function - happy path",
    "FIX: Write unit tests for login function - invalid credentials",
    "FIX: Write unit tests for token refresh logic",
    "FIX: Write unit tests for logout and session cleanup",
    "FIX: Write integration test for full auth flow",
    "VERIFY: Auth code coverage > 90%",
    "VERIFY: All tests pass",
    "DOCUMENT: Add test documentation in tests/README.md"
  ],
  "files": ["src/auth/", "tests/auth/", "tests/README.md"],
  "dependsOn": [],
  "priority": 1,
  "passes": false,
  "category": "critical-tests"
}
```

#### Category 2: Zero-Coverage Files (Priority 2)

```json
{
  "id": "TEST-ZERO-001",
  "title": "Add tests for {filename} (0% coverage)",
  "description": "Create test suite for completely untested file",
  "acceptanceCriteria": [
    "IDENTIFY: Analyze {filename} exports and public interface",
    "IDENTIFY: Map dependencies that need mocking",
    "FIX: Create test file following project conventions",
    "FIX: Write tests for each exported function/class",
    "FIX: Include happy path and error cases",
    "FIX: Add edge case tests for boundary conditions",
    "VERIFY: File coverage > 80%",
    "VERIFY: Branch coverage > 70%",
    "VERIFY: All tests pass"
  ],
  "files": ["{filename}", "tests/{testfile}"],
  "dependsOn": ["TEST-CRIT-*"],
  "priority": 2,
  "passes": false,
  "category": "zero-coverage"
}
```

#### Category 3: Low Coverage Files (Priority 3)

```json
{
  "id": "TEST-LOW-001",
  "title": "Improve coverage for {filename} ({current}% -> 80%)",
  "description": "Add missing tests to reach coverage threshold",
  "acceptanceCriteria": [
    "IDENTIFY: Run coverage on file to find uncovered lines",
    "IDENTIFY: Map uncovered branches and conditions",
    "FIX: Add tests for uncovered code paths",
    "FIX: Add tests for uncovered branches",
    "FIX: Add edge case tests",
    "VERIFY: File coverage > 80%",
    "VERIFY: Branch coverage > 70%",
    "VERIFY: No regression in existing tests"
  ],
  "files": ["{filename}", "tests/{testfile}"],
  "dependsOn": ["TEST-ZERO-*"],
  "priority": 3,
  "passes": false,
  "category": "low-coverage"
}
```

#### Category 4: Integration Tests (Priority 4)

```json
{
  "id": "TEST-INT-001",
  "title": "Add integration tests for {feature}",
  "description": "Test component interactions for {feature}",
  "acceptanceCriteria": [
    "IDENTIFY: Map component boundaries and interactions",
    "IDENTIFY: Identify external dependencies to mock",
    "FIX: Create integration test file",
    "FIX: Write tests for happy path flows",
    "FIX: Write tests for error handling between components",
    "FIX: Add tests for data flow validation",
    "VERIFY: Integration tests pass",
    "VERIFY: Tests are isolated (no external calls)",
    "DOCUMENT: Document test setup requirements"
  ],
  "files": ["tests/integration/"],
  "dependsOn": ["TEST-LOW-*"],
  "priority": 4,
  "passes": false,
  "category": "integration"
}
```

#### Category 5: API Tests (Priority 5)

```json
{
  "id": "TEST-API-001",
  "title": "Add API endpoint tests",
  "description": "Ensure all API endpoints have test coverage",
  "acceptanceCriteria": [
    "IDENTIFY: List all API routes and their current test coverage",
    "IDENTIFY: Map request/response schemas for each endpoint",
    "FIX: Write tests for each endpoint - success cases",
    "FIX: Write tests for validation errors (400)",
    "FIX: Write tests for auth errors (401/403)",
    "FIX: Write tests for not found errors (404)",
    "FIX: Write tests for server errors (500)",
    "VERIFY: All endpoints have at least happy path + error tests",
    "VERIFY: API tests pass against test server"
  ],
  "files": ["tests/api/"],
  "dependsOn": ["TEST-INT-*"],
  "priority": 5,
  "passes": false,
  "category": "api-tests"
}
```

#### Category 6: Test Infrastructure (Priority 6)

```json
{
  "id": "TEST-INF-001",
  "title": "Improve test infrastructure and utilities",
  "description": "Add test helpers, factories, and documentation",
  "acceptanceCriteria": [
    "IDENTIFY: Common patterns across test files that could be extracted",
    "FIX: Create test utility functions for repeated operations",
    "FIX: Create test data factories for common entities",
    "FIX: Add custom matchers if framework supports",
    "FIX: Update test setup/teardown for consistency",
    "VERIFY: Existing tests still pass",
    "VERIFY: New utilities reduce test code duplication",
    "DOCUMENT: Document test utilities in tests/README.md"
  ],
  "files": ["tests/utils/", "tests/factories/", "tests/README.md"],
  "dependsOn": ["TEST-API-*"],
  "priority": 6,
  "passes": false,
  "category": "infrastructure"
}
```

#### Category 7: Final Verification (Priority 7)

```json
{
  "id": "TEST-FIN-001",
  "title": "Final coverage verification and report",
  "description": "Verify overall coverage meets targets",
  "acceptanceCriteria": [
    "VERIFY: Overall line coverage > 80%",
    "VERIFY: Overall branch coverage > 70%",
    "VERIFY: Critical paths (auth, payments, data) > 90%",
    "VERIFY: All tests pass",
    "VERIFY: No flaky tests (run suite 3 times)",
    "DOCUMENT: Generate coverage report",
    "DOCUMENT: List any intentionally untested code with justification",
    "DOCUMENT: Update README with coverage badge/status"
  ],
  "files": ["README.md", "coverage/"],
  "dependsOn": ["TEST-INF-*"],
  "priority": 7,
  "passes": false,
  "category": "verification"
}
```

## Phase 4: Test Generation Guidelines

### Test Structure
Follow AAA pattern:
```javascript
describe('functionName', () => {
  it('should do X when Y', () => {
    // Arrange - set up test data
    // Act - call the function
    // Assert - verify results
  });
});
```

### What to Test
- **Happy paths**: Normal expected behavior
- **Edge cases**: Boundary values, empty inputs, max values
- **Error cases**: Invalid inputs, failures, exceptions
- **Async behavior**: Promises, callbacks, timeouts
- **State changes**: Before/after mutations

### What NOT to Test
- Private/internal functions (test through public API)
- Framework code (React, Express internals)
- Third-party libraries (mock them)
- Trivial getters/setters

### Mocking Strategy
- Mock external services (APIs, databases)
- Mock time-dependent code
- Don't mock what you're testing
- Use realistic mock data

## Phase 5: Output

Generate `prd.json` with:
1. Critical path tests first (auth, payments, data mutations)
2. Zero-coverage files
3. Low-coverage files
4. Integration tests
5. API tests
6. Infrastructure improvements
7. Final verification

Create `tests/README.md` if missing:
```markdown
# Test Documentation

## Running Tests
```bash
npm test           # Run all tests
npm test -- --coverage  # With coverage
```

## Test Structure
- `tests/unit/` - Unit tests
- `tests/integration/` - Integration tests
- `tests/api/` - API endpoint tests
- `tests/e2e/` - End-to-end tests

## Test Utilities
- `tests/utils/` - Helper functions
- `tests/factories/` - Test data factories
- `tests/fixtures/` - Static test data

## Coverage Targets
- Overall: > 80% lines, > 70% branches
- Critical paths: > 90%

## Writing Tests
[Document patterns and conventions here]
```
