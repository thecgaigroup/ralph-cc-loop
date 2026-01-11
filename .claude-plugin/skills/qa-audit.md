---
name: qa-audit
description: Run a comprehensive QA audit on any project. Scans the codebase, detects project type, asks which environment to target, generates a QA PRD, then runs Ralph to execute the audit. Use when asked to "qa audit", "production readiness check", "security audit", or "test this project".
arguments: "<project_path> [--env local|dev|staging|prod] | --help"
---

# Help Check

If the user passed `--help` as an argument, output the following and stop:

```
/qa-audit - Production readiness audit with full remediation

Usage:
  claude /qa-audit <project_path> [options]
  claude /qa-audit --help

Arguments:
  project_path           Path to the project to audit (required)

Options:
  --env <environment>    Target environment: local, dev, staging, prod
  --help                 Show this help message

Examples:
  claude /qa-audit ~/Projects/my-app
  claude /qa-audit ~/Projects/my-app --env staging
  claude /qa-audit ~/Projects/my-app --env prod

What it audits & remediates:
  - Security: Secrets hygiene, vulnerable dependencies, auth, input validation
  - Testing: Unit tests, E2E smoke tests, API tests, critical paths
  - Performance: Load times, response times, bottlenecks
  - Documentation: README accuracy, API docs, deployment instructions
  - CI/CD: Pipeline validation, build artifacts

Remediation tiers:
  - Auto-fix: Safe changes (gitignore, env.example, lint fixes)
  - Fix+confirm: Moderate changes (dependency updates)
  - Follow-up: Creates new stories for complex remediation
  - Manual: Documents with clear instructions

Output files:
  - prd.json: QA stories for Ralph to execute
  - QA_PROGRESS.md: Findings with severity ratings
  - ENV_TEST_MATRIX.md: Environment configuration

Workflow:
  1. Scans codebase to detect tech stack
  2. Asks which environment to test (if not specified)
  3. Collects any needed credentials
  4. Generates QA PRD with remediation stories
  5. Runs Ralph to execute the audit
```

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

## Remediation Philosophy

This audit performs **full remediation** - not just reporting issues, but fixing them:

### Remediation Tiers

| Tier | Action | Examples |
|------|--------|----------|
| **Auto-fix** | Fix immediately, no user input needed | Add `.env.test` to `.gitignore`, create `.env.example`, fix lint errors |
| **Fix with confirmation** | Fix after brief user confirmation | Update vulnerable dependencies, add missing test files |
| **Document + Follow-up** | Document issue, create follow-up story | Refactor insecure auth pattern, major architectural changes |
| **Manual required** | Document with clear instructions | Rotate compromised credentials, configure external services |

### Story Behavior

Each QA story will:
1. **Identify** - Find all issues in its domain
2. **Triage** - Categorize by severity and remediation tier
3. **Fix** - Auto-fix what's safe, prompt for confirmation on others
4. **Document** - Log all findings and actions to `QA_PROGRESS.md`
5. **Follow-up** - Add new stories to `prd.json` for complex remediation

### Follow-up Story Generation

When a story finds issues that can't be auto-fixed, it creates follow-up stories:

```json
{
  "id": "QA-REM-001",
  "title": "Remediate: [specific issue]",
  "description": "Follow-up from QA-SEC-001: [details]",
  "acceptanceCriteria": ["[specific fix actions]"],
  "priority": [based on severity],
  "passes": false,
  "category": "remediation",
  "sourceStory": "QA-SEC-001",
  "severity": "HIGH"
}
```

Follow-up stories are appended to `prd.json` so Ralph continues processing them.

### Severity → Priority Mapping

| Severity | Priority | Action |
|----------|----------|--------|
| CRITICAL | 1 | Block audit, fix immediately |
| HIGH | 2-3 | Fix before audit completes |
| MEDIUM | 10-20 | Create follow-up story |
| LOW | 50+ | Document, optional follow-up |
| INFO | - | Document only, no follow-up |

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

### Step 2.5: Collect Authentication & Credentials

Ask about authentication requirements for the target environment:

```
question: "How does this environment handle authentication?"
header: "Auth Type"
options:
  - label: "None"
    description: "No authentication required (public app)"
  - label: "Username/Password"
    description: "Standard login form"
  - label: "SSO/OAuth"
    description: "Single sign-on or OAuth flow"
  - label: "API Key/Token"
    description: "API key or bearer token"
  - label: "AWS IAM"
    description: "AWS credentials/profile"
```

**Based on auth type, collect credentials:**

#### None (Public)
- No credentials needed
- Skip to Phase 3

#### Username/Password
Ask user to provide (or point to existing config):

```
question: "How should tests authenticate?"
header: "Credentials"
options:
  - label: "I'll provide test credentials"
    description: "Enter username/password for a test account"
  - label: "Use .env file"
    description: "Credentials in TEST_USER/TEST_PASSWORD env vars"
  - label: "Use Playwright auth state"
    description: "Existing storageState.json from prior login"
```

If providing credentials:
- Ask for test username (not in chat history - prompt user to enter in secure input)
- Ask for test password (not in chat history - prompt user to enter in secure input)
- Store in `.env.test` (gitignored) as `TEST_USER` and `TEST_PASSWORD`

**IMPORTANT:** Never log or display credentials. Never commit credentials to git.

#### SSO/OAuth
```
question: "How should tests handle SSO?"
header: "SSO Method"
options:
  - label: "Use existing session"
    description: "Tests will use storageState.json from manual login"
  - label: "Service account"
    description: "API-based auth bypass for testing"
  - label: "Manual login per run"
    description: "User logs in manually, tests capture session"
```

If using existing session:
- Check for `storageState.json` or `playwright/.auth/`
- If not present, instruct user to run `npx playwright codegen --save-storage=storageState.json [url]`

#### API Key/Token
```
question: "How should API tests authenticate?"
header: "API Auth"
options:
  - label: "I'll provide an API key"
    description: "Enter API key or token"
  - label: "Use .env file"
    description: "API key in TEST_API_KEY env var"
  - label: "Use AWS Secrets Manager"
    description: "Fetch from secrets manager"
```

If providing API key:
- Ask user to enter API key (secure input)
- Store in `.env.test` as `TEST_API_KEY`

#### AWS IAM
```
question: "Which AWS profile should tests use?"
header: "AWS Profile"
options:
  - label: "default"
    description: "Use default AWS profile"
  - label: "Other"
    description: "Specify a named profile"
```

Verify AWS credentials:
```bash
aws sts get-caller-identity --profile [profile_name]
```

If credentials invalid, prompt user to configure:
```bash
aws configure --profile [profile_name]
# Or for SSO:
aws sso login --profile [profile_name]
```

### Step 2.6: Create Credentials Config

Create `.env.test` in project root (if credentials were provided):

```bash
# QA Audit Test Credentials
# Generated by /qa-audit - DO NOT COMMIT

# Browser auth
TEST_USER=
TEST_PASSWORD=

# API auth
TEST_API_KEY=
TEST_API_BEARER_TOKEN=

# AWS
AWS_PROFILE=
```

Ensure `.env.test` is in `.gitignore`:
```bash
grep -q ".env.test" .gitignore || echo ".env.test" >> .gitignore
```

### Step 2.7: Store Auth Config in PRD

Add credentials reference to PRD metadata (not the actual credentials):

```json
"qaMetadata": {
  "auth": {
    "type": "username_password",
    "source": ".env.test",
    "browserAuth": "storageState.json",
    "awsProfile": "default"
  }
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
  "description": "Find and remediate secrets issues - auto-fix config, flag code changes",
  "acceptanceCriteria": [
    "IDENTIFY: Grep codebase for hardcoded secrets (API keys, passwords, tokens, connection strings)",
    "IDENTIFY: Check for secrets in config files, constants, or environment-specific code",
    "AUTO-FIX: Create .env.example if missing (extract var names from code, no values)",
    "AUTO-FIX: Update .gitignore to include: .env*, *.pem, *.key, credentials*, secrets*, .env.test",
    "AUTO-FIX: Add .env.local, .env.production to .gitignore if not present",
    "FIX+CONFIRM: If secrets found in committed files, remove and add to .env.example",
    "FOLLOW-UP: Create QA-REM story for each hardcoded secret that needs code refactor",
    "FOLLOW-UP: If secrets were ever committed, create story for credential rotation",
    "DOCUMENT: Log all findings and remediations to QA_PROGRESS.md"
  ],
  "files": [".env.example", ".gitignore", "QA_PROGRESS.md", "prd.json"],
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
  "title": "Dependency vulnerability scan and remediation",
  "description": "Find vulnerabilities and fix them - auto-update safe deps, flag breaking changes",
  "acceptanceCriteria": [
    "IDENTIFY: Run audit command (npm audit / pip audit / cargo audit / safety check)",
    "IDENTIFY: Categorize vulnerabilities by severity and fix availability",
    "AUTO-FIX: Run npm audit fix (or equivalent) for auto-fixable vulnerabilities",
    "AUTO-FIX: Update patch versions of vulnerable packages",
    "FIX+CONFIRM: For minor version updates, show changelog summary and confirm",
    "FOLLOW-UP: Create QA-REM story for each major version update needed",
    "FOLLOW-UP: Create QA-REM story for vulnerabilities with no fix available (document workaround)",
    "VERIFY: Re-run audit after fixes - critical count must be 0",
    "VERIFY: Run tests after dependency updates to catch breakage",
    "DOCUMENT: Log before/after vulnerability counts to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md", "package.json", "package-lock.json", "prd.json"],
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
    "Load credentials from qaMetadata.auth config (see .env.test or storageState.json)",
    "Protected routes return 401/403 when unauthenticated",
    "Valid authentication succeeds using configured credentials",
    "Role-based access enforced (if applicable)",
    "Session/token handling verified (cookies scoped, tokens expire)",
    "Logout invalidates session",
    "Test added or existing test verified for auth boundaries",
    "If credentials missing/invalid: document in QA_PROGRESS.md and prompt user",
    "Findings logged to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md", ".env.test"],
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
  "title": "Input validation and injection prevention - find and fix",
  "description": "Identify injection risks and remediate - auto-fix simple cases, refactor complex ones",
  "acceptanceCriteria": [
    "IDENTIFY: Scan for SQL string concatenation patterns (potential SQL injection)",
    "IDENTIFY: Scan for innerHTML/dangerouslySetInnerHTML without sanitization (XSS)",
    "IDENTIFY: Scan for unvalidated user input in shell commands (command injection)",
    "IDENTIFY: Check file upload handlers for type/size validation",
    "AUTO-FIX: Add input validation library if missing (zod, joi, etc.)",
    "AUTO-FIX: Replace innerHTML with textContent where possible",
    "AUTO-FIX: Add basic input sanitization helpers",
    "FIX+CONFIRM: Refactor simple SQL concatenation to parameterized queries",
    "FOLLOW-UP: Create QA-REM story for complex injection patterns needing refactor",
    "FOLLOW-UP: Create QA-REM story if file upload security needs overhaul",
    "VERIFY: Add/run tests for injection prevention",
    "DOCUMENT: Log all findings with code locations to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md", "prd.json"],
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
  "title": "Test suite assessment and gap remediation",
  "description": "Evaluate tests, fix failures, add missing critical tests",
  "acceptanceCriteria": [
    "IDENTIFY: Find test command and run full suite",
    "IDENTIFY: Measure coverage (add coverage tool if missing: nyc, c8, coverage.py)",
    "IDENTIFY: List critical code paths without test coverage",
    "AUTO-FIX: Fix simple test failures (outdated snapshots, minor assertion fixes)",
    "AUTO-FIX: Add test config if missing (jest.config.js, vitest.config.ts, pytest.ini)",
    "AUTO-FIX: Add at least 3 critical missing unit tests for core functionality",
    "FIX+CONFIRM: Fix complex test failures after showing root cause",
    "FOLLOW-UP: Create QA-REM story for each major untested module",
    "FOLLOW-UP: Create QA-REM story if test infrastructure needs setup",
    "VERIFY: All tests pass after fixes",
    "VERIFY: Coverage improved or baseline documented",
    "DOCUMENT: Log coverage %, test count, and gaps to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md", "prd.json"],
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
  "title": "E2E smoke test suite - create and verify",
  "description": "Set up Playwright, create smoke tests, fix any failures",
  "acceptanceCriteria": [
    "AUTO-FIX: Install Playwright if not present (npm init playwright@latest)",
    "AUTO-FIX: Create playwright.config.ts with headless default",
    "AUTO-FIX: Configure auth using storageState.json or .env.test credentials",
    "AUTO-FIX: Create smoke test file (e2e/smoke.spec.ts) if missing",
    "AUTO-FIX: Add smoke tests: app loads, no console errors, main nav works",
    "FIX+CONFIRM: If smoke tests fail, fix the issues (broken selectors, timing)",
    "FALLBACK: If Playwright unavailable, use Claude Chrome MCP for manual verification",
    "FALLBACK: If no browser tools, document manual test steps in QA_PROGRESS.md",
    "FOLLOW-UP: Create QA-REM story if app has critical bugs blocking smoke tests",
    "VERIFY: All smoke tests pass in headless mode",
    "DOCUMENT: Log test results, screenshots of failures to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md", "e2e/smoke.spec.ts", "playwright.config.ts", "prd.json"],
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
    "Load API credentials from qaMetadata.auth config (.env.test or secrets)",
    "Key API endpoints have integration tests",
    "Tests include proper Authorization headers (Bearer token, API key, etc.)",
    "Tests cover success and error responses",
    "Tests verify response schema/structure",
    "All API tests pass",
    "If no API tests exist: add tests for critical endpoints",
    "If credentials missing: prompt user or document as blocked",
    "Results logged to QA_PROGRESS.md"
  ],
  "files": ["QA_PROGRESS.md", ".env.test"],
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
  "title": "Documentation validation and fixes",
  "description": "Verify docs are accurate - fix inaccuracies, add missing sections",
  "acceptanceCriteria": [
    "IDENTIFY: Test README setup instructions by following them",
    "IDENTIFY: Check all documented commands actually work",
    "IDENTIFY: Verify environment variables are documented",
    "AUTO-FIX: Update README with correct setup steps if outdated",
    "AUTO-FIX: Add Environment Variables section if missing",
    "AUTO-FIX: Add or update test command documentation",
    "AUTO-FIX: Add basic API documentation if endpoints exist but undocumented",
    "FIX+CONFIRM: Update deployment instructions if outdated",
    "FOLLOW-UP: Create QA-REM story for major documentation overhaul",
    "VERIFY: New developer could set up project using only README",
    "DOCUMENT: Log documentation gaps and fixes to QA_PROGRESS.md"
  ],
  "files": ["README.md", "QA_PROGRESS.md", "prd.json"],
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
  "title": "Compile audit results and remaining remediation",
  "description": "Summarize what was fixed, what remains, production readiness assessment",
  "acceptanceCriteria": [
    "COMPILE: Count total issues found across all stories",
    "COMPILE: Count issues auto-fixed vs requiring follow-up",
    "COMPILE: List all QA-REM follow-up stories created",
    "VERIFY: All CRITICAL issues have been remediated (not just documented)",
    "VERIFY: All HIGH issues either fixed or have QA-REM follow-up story",
    "VERIFY: Tests pass, lint passes, typecheck passes",
    "ASSESS: Production readiness verdict with rationale:",
    "  - READY: All critical/high fixed, tests pass, no blocking issues",
    "  - READY WITH CAVEATS: Minor issues remain, documented",
    "  - NEEDS WORK: Follow-up stories must complete first",
    "  - NOT READY: Critical issues unresolved",
    "DOCUMENT: Final summary in QA_PROGRESS.md with:",
    "  - Issues found / fixed / remaining",
    "  - Follow-up stories pending",
    "  - Production readiness verdict",
    "  - Recommended next actions"
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
