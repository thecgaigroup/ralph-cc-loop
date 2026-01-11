---
name: qa-audit
description: Run a comprehensive QA audit on any project. Scans the codebase, detects project type, asks which environment to target, generates a QA PRD, then runs Ralph to execute the audit. Use when asked to "qa audit", "production readiness check", "security audit", or "test this project".
arguments: "<project_path> [--env local|dev|staging|prod]"
---

# QA Audit - Production Readiness Check

You are running a comprehensive QA audit on a project. This skill:
1. Takes a **local project path** (the codebase to audit)
2. Asks which **target environment** to test against (local, dev, staging, prod)
3. Generates a QA PRD based on the project
4. Runs Ralph to execute the full audit

**Key distinction:**
- **Project path**: Where the code lives (local folder)
- **Target environment**: Where to run tests (localhost, dev URL, prod URL)

## Phase 1: Project Discovery

### Step 1.1: Locate Project

If `[project_path]` provided, use it. Otherwise, use current working directory.

Verify the path exists and is a git repository:
```bash
cd [project_path] && git status
```

### Step 1.2: Detect Project Type

Scan the project to understand its architecture:

```bash
# Check for project indicators
ls -la package.json pyproject.toml requirements.txt Cargo.toml go.mod pom.xml build.gradle 2>/dev/null
ls -la src/ app/ lib/ pages/ components/ api/ server/ 2>/dev/null
ls -la tests/ __tests__ spec/ test/ e2e/ 2>/dev/null
ls -la .env.example .env.local .env.development 2>/dev/null
ls -la Dockerfile docker-compose.yml 2>/dev/null
ls -la playwright.config.* cypress.config.* jest.config.* vitest.config.* pytest.ini 2>/dev/null
ls -la .github/workflows/ 2>/dev/null
```

Classify the project:

| Type | Indicators |
|------|-----------|
| **frontend** | React/Vue/Svelte/Next.js, no backend |
| **backend** | API/server code, no frontend framework |
| **full-stack** | Both frontend and backend |
| **monorepo** | Multiple packages/apps (turborepo, nx, lerna) |
| **cli** | Command-line tool (bin/, CLI entry point) |
| **library** | Published package, no app |

### Step 1.3: Assess Current State

Quickly evaluate what exists:

**Tests:**
- What test framework is configured?
- Are there existing tests? Roughly how many?
- Is there E2E testing set up?

**Security:**
- Does `.env.example` exist?
- Does `.gitignore` cover sensitive files?
- Quick grep for obvious secrets (API keys, passwords)

**CI/CD:**
- GitHub Actions or other CI present?
- What commands does CI run?

**Documentation:**
- README quality?
- API docs?

### Step 1.4: Detect Environments

Look for environment configurations:

```bash
# Check for environment files
ls -la .env* 2>/dev/null
grep -r "localhost\|127.0.0.1" --include="*.env*" --include="*.json" --include="*.ts" --include="*.js" 2>/dev/null | head -20
grep -r "dev\.\|staging\.\|prod\." --include="*.env*" --include="*.json" --include="*.ts" 2>/dev/null | head -20
```

Identify available environments (examples):
- `local` - localhost development
- `dev` / `development` - shared dev environment
- `staging` - pre-production
- `prod` / `production` - live environment

## Phase 2: Environment Selection

### Step 2.1: Check for --env Argument

If `--env` was provided in arguments, use that. Otherwise, ask the user.

### Step 2.2: Ask User (if not provided)

Use AskUserQuestion tool:

```
question: "Which environment should the QA audit test against?"
header: "Environment"
options:
  - label: "local"
    description: "Test against localhost dev server"
  - label: "dev"
    description: "Test against development/staging environment"
  - label: "prod"
    description: "Test against production (read-only tests only)"
```

### Step 2.3: Collect Environment Details

Based on selection, gather the required URLs:

**If `local`:**
- Determine dev server command from `package.json` scripts
- Default port (usually 3000, 5173, 8080)
- Base URL: `http://localhost:[port]`
- API URL: Often same, or `http://localhost:[api-port]`

```bash
cat package.json | jq '.scripts | to_entries[] | select(.key | test("dev|start|serve")) | "\(.key): \(.value)"' 2>/dev/null
```

**If `dev` or `prod`:**

Use AskUserQuestion to get URLs:

```
question: "What is the base URL for the [environment] environment?"
header: "Base URL"
options:
  - label: "[detected URL if found]"
    description: "Detected from config"
  - label: "Other"
    description: "Enter custom URL"
```

Then ask for API URL if the project has a separate backend:

```
question: "What is the API URL? (skip if same as base URL)"
header: "API URL"
options:
  - label: "Same as base URL"
    description: "API is served from same origin"
  - label: "Other"
    description: "Enter separate API URL"
```

### Step 2.4: Production Safety Check

**If `prod` selected**, add this warning and constraint:

```
⚠️  PRODUCTION ENVIRONMENT SELECTED

Tests will be READ-ONLY:
- No data creation, modification, or deletion
- No form submissions that persist data
- No account creation or modifications
- Smoke tests and read operations only

Security and code analysis will still run against the local codebase.
```

Set a flag in the PRD:
```json
"qaMetadata": {
  "readOnlyMode": true
}
```

## Phase 3: Generate QA PRD

Create a comprehensive `prd.json` with all QA stories.

### PRD Structure

```json
{
  "project": "[Project Name] QA Audit",
  "mode": "feature",
  "branchName": "ralph/qa-audit-[YYYY-MM-DD]",
  "baseBranch": "main",
  "description": "Comprehensive QA audit for production readiness",
  "qaMetadata": {
    "projectType": "[detected type]",
    "targetEnvironment": "[selected environment]",
    "baseUrl": "[url or localhost:port]",
    "apiUrl": "[api url if different]",
    "generatedAt": "[timestamp]",
    "browserStrategy": "playwright-headless-first"
  },
  "plugins": {
    "recommended": ["security-guidance"],
    "optional": []
  },
  "userStories": []
}
```

### Story Templates

Generate stories based on project type. Include ALL applicable stories - this is a full audit.

---

#### QA-ENV-001: Environment Setup & Validation

```json
{
  "id": "QA-ENV-001",
  "title": "Environment setup and connectivity validation",
  "description": "Verify target environment is accessible and document test configuration",
  "acceptanceCriteria": [
    "QA_PROGRESS.md created with audit metadata",
    "Target environment URL is accessible (HTTP 200 or redirect)",
    "API endpoint responds (if applicable)",
    "Authentication method documented (if required)",
    "ENV_TEST_MATRIX.md created with environment details"
  ],
  "files": ["QA_PROGRESS.md", "ENV_TEST_MATRIX.md"],
  "dependsOn": [],
  "priority": 1,
  "passes": false,
  "category": "environment"
}
```

---

#### QA-SEC-001: Secrets Hygiene Audit

```json
{
  "id": "QA-SEC-001",
  "title": "Secrets and configuration hygiene audit",
  "description": "Verify no secrets committed, environment variables properly handled",
  "acceptanceCriteria": [
    "Grep codebase for hardcoded secrets (API keys, passwords, tokens)",
    "Verify .env.example exists with all required variables (no real values)",
    "Verify .gitignore includes: .env*, *.pem, *.key, credentials*, secrets*",
    "Check for secrets in config files, constants, or hardcoded strings",
    "All findings logged to QA_PROGRESS.md with severity"
  ],
  "files": [".env.example", ".gitignore", "QA_PROGRESS.md"],
  "dependsOn": [],
  "priority": 2,
  "passes": false,
  "category": "security"
}
```

---

#### QA-SEC-002: Dependency Vulnerability Scan

```json
{
  "id": "QA-SEC-002",
  "title": "Dependency vulnerability scan",
  "description": "Run dependency audit and address critical vulnerabilities",
  "acceptanceCriteria": [
    "Run appropriate audit command (npm audit / pip audit / cargo audit / etc.)",
    "Critical vulnerabilities: 0 remaining (fix or document exception)",
    "High vulnerabilities: addressed or documented with risk acceptance rationale",
    "Audit summary logged to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md", "package.json"],
  "dependsOn": [],
  "priority": 3,
  "passes": false,
  "category": "security"
}
```

---

#### QA-SEC-003: Authentication & Authorization Validation

**Include if project has auth (login, protected routes, API keys)**

```json
{
  "id": "QA-SEC-003",
  "title": "Authentication and authorization validation",
  "description": "Verify auth flows work correctly and access boundaries are enforced",
  "acceptanceCriteria": [
    "Protected routes return 401/403 when unauthenticated",
    "Valid authentication succeeds and grants appropriate access",
    "Role-based access enforced (if applicable)",
    "Session/token handling verified (cookies scoped, tokens expire)",
    "Logout invalidates session",
    "Test added or existing test verified for auth boundaries",
    "Findings logged to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md"],
  "dependsOn": ["QA-ENV-001"],
  "priority": 4,
  "passes": false,
  "category": "security"
}
```

---

#### QA-SEC-004: Input Validation & Injection Prevention

```json
{
  "id": "QA-SEC-004",
  "title": "Input validation and injection prevention check",
  "description": "Verify user inputs are validated and injection attacks prevented",
  "acceptanceCriteria": [
    "Form inputs have appropriate validation (client and server)",
    "SQL queries use parameterized statements or ORM (no string concatenation)",
    "User content is escaped/sanitized before rendering (XSS prevention)",
    "File uploads validate type and size (if applicable)",
    "Error responses don't leak stack traces or internal details",
    "Findings logged to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md"],
  "dependsOn": ["QA-ENV-001"],
  "priority": 5,
  "passes": false,
  "category": "security"
}
```

---

#### QA-SEC-005: API Security Review

**Include if project has API endpoints**

```json
{
  "id": "QA-SEC-005",
  "title": "API security review",
  "description": "Verify API endpoints are properly secured",
  "acceptanceCriteria": [
    "API endpoints require authentication where appropriate",
    "Rate limiting present or documented as out-of-scope",
    "CORS configured appropriately (not wildcard * in production)",
    "Sensitive endpoints don't appear in public API docs",
    "API error responses don't leak internal details",
    "Findings logged to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md"],
  "dependsOn": ["QA-ENV-001"],
  "priority": 6,
  "passes": false,
  "category": "security"
}
```

---

#### QA-TEST-001: Test Suite Assessment

```json
{
  "id": "QA-TEST-001",
  "title": "Test suite assessment and validation",
  "description": "Evaluate existing tests, run them, identify critical gaps",
  "acceptanceCriteria": [
    "Test command identified and documented",
    "All existing tests pass (or failures documented)",
    "Test coverage measured (if coverage tool available)",
    "Critical untested code paths identified",
    "At least 1 critical missing test added (if gaps found)",
    "Test summary logged to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md"],
  "dependsOn": [],
  "priority": 7,
  "passes": false,
  "category": "testing"
}
```

---

#### QA-TEST-002: E2E Smoke Tests

**Include if project has UI**

```json
{
  "id": "QA-TEST-002",
  "title": "E2E smoke test suite",
  "description": "Create or verify basic E2E smoke tests using Playwright (headless)",
  "acceptanceCriteria": [
    "Playwright configured (or install if not present)",
    "Smoke test covers: app loads successfully, no console errors",
    "Basic navigation works (click through main routes)",
    "Tests run in headless mode by default",
    "If Playwright unavailable: use Claude Chrome MCP as fallback",
    "If no browser tools: document manual test steps",
    "Results logged to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md", "e2e/", "playwright.config.ts"],
  "dependsOn": ["QA-ENV-001"],
  "priority": 8,
  "passes": false,
  "category": "testing",
  "browserStrategy": "playwright-headless > claude-chrome-mcp > manual"
}
```

---

#### QA-TEST-003: E2E Critical Path Tests

**Include if project has UI**

```json
{
  "id": "QA-TEST-003",
  "title": "E2E critical user journey tests",
  "description": "Test the most important user journeys end-to-end",
  "acceptanceCriteria": [
    "Critical user journey identified (e.g., signup, login, main action)",
    "E2E test covers happy path completely",
    "E2E test covers at least 1 error/edge case",
    "Tests pass in headless mode",
    "If browser tools unavailable: manual test steps documented",
    "Results logged to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md", "e2e/"],
  "dependsOn": ["QA-TEST-002"],
  "priority": 9,
  "passes": false,
  "category": "testing",
  "browserStrategy": "playwright-headless > claude-chrome-mcp > manual"
}
```

---

#### QA-TEST-004: API Integration Tests

**Include if project has API**

```json
{
  "id": "QA-TEST-004",
  "title": "API integration test validation",
  "description": "Verify API endpoints work correctly with integration tests",
  "acceptanceCriteria": [
    "Key API endpoints have integration tests",
    "Tests cover success and error responses",
    "Tests verify response schema/structure",
    "All API tests pass",
    "If no API tests exist: add tests for critical endpoints",
    "Results logged to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md"],
  "dependsOn": ["QA-ENV-001"],
  "priority": 10,
  "passes": false,
  "category": "testing"
}
```

---

#### QA-TEST-005: CLI Tests

**Include if project is CLI tool**

```json
{
  "id": "QA-TEST-005",
  "title": "CLI command validation",
  "description": "Verify CLI commands work correctly with expected inputs",
  "acceptanceCriteria": [
    "All documented commands execute without error",
    "Help output is accurate and complete",
    "Invalid inputs produce helpful error messages",
    "Exit codes are correct (0 for success, non-zero for errors)",
    "Results logged to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md"],
  "dependsOn": [],
  "priority": 10,
  "passes": false,
  "category": "testing"
}
```

---

#### QA-PERF-001: Performance Baseline

```json
{
  "id": "QA-PERF-001",
  "title": "Performance baseline assessment",
  "description": "Establish performance baseline and identify obvious bottlenecks",
  "acceptanceCriteria": [
    "Page load time measured (for web apps)",
    "API response times sampled for key endpoints",
    "No obvious N+1 queries or performance anti-patterns",
    "Large assets optimized (images, bundles)",
    "Performance baseline documented in QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md"],
  "dependsOn": ["QA-ENV-001"],
  "priority": 11,
  "passes": false,
  "category": "performance"
}
```

---

#### QA-DOC-001: Documentation Validation

```json
{
  "id": "QA-DOC-001",
  "title": "Documentation validation",
  "description": "Verify documentation is accurate and complete",
  "acceptanceCriteria": [
    "README has accurate setup instructions",
    "Environment variables documented",
    "Test commands documented and work",
    "API documentation accurate (if applicable)",
    "Deployment instructions present or linked",
    "Documentation tested by following instructions",
    "Gaps logged to QA_PROGRESS.md"
  ],
  "files": ["README.md", "QA_PROGRESS.md"],
  "dependsOn": ["QA-ENV-001"],
  "priority": 12,
  "passes": false,
  "category": "documentation"
}
```

---

#### QA-CI-001: CI/CD Validation

**Include if CI is present**

```json
{
  "id": "QA-CI-001",
  "title": "CI/CD pipeline validation",
  "description": "Verify CI pipeline is comprehensive and working",
  "acceptanceCriteria": [
    "CI runs on PRs (or document why not)",
    "CI includes: lint, typecheck, tests",
    "CI includes security checks (dependency audit)",
    "CI status is currently green (or failures documented)",
    "Build artifacts don't include source maps or secrets in prod",
    "CI configuration logged to QA_PROGRESS.md"
  ],
  "files": [".github/workflows/", "QA_PROGRESS.md"],
  "dependsOn": [],
  "priority": 13,
  "passes": false,
  "category": "ci"
}
```

---

#### QA-FINAL-001: Audit Summary & Recommendations

```json
{
  "id": "QA-FINAL-001",
  "title": "Generate audit summary and recommendations",
  "description": "Compile all findings into final audit report",
  "acceptanceCriteria": [
    "QA_PROGRESS.md has complete findings summary table",
    "All CRITICAL findings addressed or have action items",
    "All HIGH findings documented with remediation plan",
    "Recommendations section added with prioritized next steps",
    "Overall production readiness assessment: READY / NEEDS WORK / NOT READY"
  ],
  "files": ["QA_PROGRESS.md"],
  "dependsOn": ["QA-ENV-001", "QA-SEC-001", "QA-SEC-002", "QA-TEST-001", "QA-DOC-001"],
  "priority": 99,
  "passes": false,
  "category": "summary"
}
```

---

### Adapt Stories to Project Type

**Remove stories that don't apply:**

| Project Type | Remove |
|-------------|--------|
| **frontend** | QA-TEST-004 (API tests), QA-TEST-005 (CLI) |
| **backend** | QA-TEST-002, QA-TEST-003 (E2E browser tests) |
| **cli** | QA-TEST-002, QA-TEST-003 (E2E browser), QA-SEC-003 (auth UI) |
| **library** | QA-TEST-002, QA-TEST-003, QA-PERF-001 |

**Add auth stories only if:**
- Project has login/signup flows
- Project has protected routes
- Project uses API keys or tokens

## Phase 4: Create Supporting Files

### QA_PROGRESS.md (initial template)

Write this to the project:

```markdown
# QA Audit Progress

**Project:** [name]
**Target Environment:** [environment]
**Base URL:** [url]
**Project Type:** [type]
**Started:** [timestamp]
**Generated by:** Ralph QA Audit

---

## Findings Summary

| ID | Severity | Category | Status | Description |
|----|----------|----------|--------|-------------|

**Severity Levels:** CRITICAL > HIGH > MEDIUM > LOW > INFO

---

## Story Progress

| Story | Title | Status |
|-------|-------|--------|
| QA-ENV-001 | Environment setup | Pending |
| QA-SEC-001 | Secrets hygiene | Pending |
| ... | ... | ... |

---

## Environment Details

**Target:** [environment]
**URL:** [url]
**API:** [api url]
**Auth Method:** [TBD during QA-ENV-001]

---

## Notes

<!-- Learnings and context added during audit -->
```

### ENV_TEST_MATRIX.md (template)

```markdown
# Environment Test Matrix

## Target Environment: [selected]

| Property | Value |
|----------|-------|
| Environment | [name] |
| Base URL | [url] |
| API URL | [url] |
| Auth Method | [TBD] |
| Test Data Strategy | [TBD] |

## Access Requirements

| Requirement | Status | Notes |
|-------------|--------|-------|
| URL accessible | TBD | |
| Auth configured | TBD | |
| Test data available | TBD | |

## Commands

| Action | Command |
|--------|---------|
| Start dev server | [if local] |
| Run tests | |
| Run lint | |
| Run typecheck | |
```

## Phase 5: Execute

### Step 5.1: Write PRD

Save the generated `prd.json` to the project directory.

### Step 5.2: Write Supporting Files

Save `QA_PROGRESS.md` and `ENV_TEST_MATRIX.md` templates.

### Step 5.3: Confirm and Launch

Output:
```
QA Audit PRD Generated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project:     [name]
Type:        [detected type]
Environment: [selected]
URL:         [url]
Stories:     [count]

Stories:
  1. QA-ENV-001: Environment setup and connectivity
  2. QA-SEC-001: Secrets hygiene audit
  3. QA-SEC-002: Dependency vulnerability scan
  ...

Launching Ralph...
```

### Step 5.4: Run Ralph

Execute Ralph to run the audit:

```bash
~/tools/ralph-cc-loop/ralph.sh [project_path] 40
```

The iteration count of 40 should be sufficient for a full audit (~15 stories).

---

## Browser Testing Strategy

Stories that require browser testing should follow this priority:

1. **Playwright (headless)** - Primary choice
   - Check if Playwright is configured: `ls playwright.config.*`
   - Install if needed: `npm init playwright@latest`
   - Run headless: `npx playwright test --headed=false`

2. **Claude Chrome MCP** - Fallback for debugging
   - Use if Playwright fails to reproduce an issue
   - Use for visual inspection of complex UI
   - Use `mcp__claude-in-chrome__*` tools

3. **Manual documentation** - Last resort
   - If no browser tools available
   - Document manual test steps in QA_PROGRESS.md
   - Mark story complete with caveat

**In acceptance criteria**, use this pattern:
```
"Run E2E test with Playwright headless",
"If Playwright unavailable: use Claude Chrome MCP",
"If no browser tools: document manual test steps in QA_PROGRESS.md"
```

---

## Severity Definitions

| Severity | Definition | Example |
|----------|-----------|---------|
| **CRITICAL** | Security vulnerability, data exposure, system down | Hardcoded API keys, SQL injection |
| **HIGH** | Significant risk, needs fix before production | Missing auth on admin routes |
| **MEDIUM** | Should fix, but not blocking | Outdated dependencies (non-critical) |
| **LOW** | Minor issue, fix when convenient | Missing input validation on optional field |
| **INFO** | Observation, no action required | Suggestion for improvement |

---

## Stop Condition

Ralph will output `<promise>COMPLETE</promise>` when all QA stories pass.

If QA-FINAL-001 completes with assessment of "NOT READY", the audit still completes - findings are documented for remediation.
