# QA Loop Proposal for Ralph

> **Status: Implemented** ✅
>
> This proposal has been implemented as the `/qa-audit` skill in v2.1.0.
> See `.claude-plugin/skills/qa-audit.md` for the full implementation.

## Executive Summary

This document proposes a structured approach to running QA audits via Ralph. Instead of a monolithic prompt, we break the QA process into discrete, trackable stories that Ralph can execute iteratively.

## Architecture Decision

**Approach: PRD-Driven QA (using main Ralph)**

Why not Ralph Wiggum?
- Ralph Wiggum is stateless between iterations (same prompt fed each time)
- QA requires tracking progress across many discrete tasks
- Main Ralph has built-in story tracking, dependency management, and PR creation

## Proposed Components

### 1. QA PRD Generator Skill: `/qa-audit`

A new skill that scans a project and generates a `prd.json` with QA stories.

**Usage:**
```bash
claude /qa-audit ~/Projects/my-app --scope full
claude /qa-audit ~/Projects/my-app --scope security
claude /qa-audit ~/Projects/my-app --scope e2e
```

**What it does:**
1. Scans project structure (detects frontend/backend/full-stack)
2. Identifies existing test coverage
3. Detects environments (local, dev, prod configs)
4. Generates appropriate QA stories based on project type

### 2. QA Story Templates

Pre-defined story templates that the skill uses:

#### Environment Stories
- `QA-ENV-001`: Create environment matrix documentation
- `QA-ENV-002`: Validate local environment connectivity
- `QA-ENV-003`: Validate dev environment connectivity
- `QA-ENV-004`: Validate prod environment connectivity (read-only)

#### Security Stories
- `QA-SEC-001`: Secrets hygiene audit
- `QA-SEC-002`: Authentication flow validation
- `QA-SEC-003`: Authorization boundary testing
- `QA-SEC-004`: Dependency vulnerability scan
- `QA-SEC-005`: API security validation

#### Testing Stories
- `QA-TEST-001`: Unit test coverage assessment
- `QA-TEST-002`: Integration test validation
- `QA-TEST-003`: E2E smoke test suite
- `QA-TEST-004`: E2E critical path tests
- `QA-TEST-005`: Performance baseline

#### Documentation Stories
- `QA-DOC-001`: README validation
- `QA-DOC-002`: API documentation verification
- `QA-DOC-003`: Deployment runbook review

### 3. Story Dependencies

```
QA-ENV-001 (matrix)
    └── QA-ENV-002 (local)
    └── QA-ENV-003 (dev)
            └── QA-SEC-002 (auth)
            └── QA-TEST-003 (e2e smoke)
                    └── QA-TEST-004 (e2e critical)
```

### 4. Example Generated prd.json

```json
{
  "project": "My App QA Audit",
  "mode": "feature",
  "branchName": "ralph/qa-audit-2026-01-11",
  "baseBranch": "main",
  "description": "Comprehensive QA audit for production readiness",
  "qaScope": "full",
  "projectType": "full-stack",
  "plugins": {
    "recommended": ["security-guidance"],
    "optional": ["frontend-design"]
  },
  "environments": {
    "local": { "url": "http://localhost:3000", "apiUrl": "http://localhost:3001" },
    "dev": { "url": "https://dev.myapp.com", "apiUrl": "https://api.dev.myapp.com" }
  },
  "userStories": [
    {
      "id": "QA-ENV-001",
      "title": "Create environment test matrix",
      "description": "Document all environments, their URLs, auth methods, and test strategies",
      "acceptanceCriteria": [
        "ENV_TEST_MATRIX.md exists with all environments documented",
        "Each environment has: base URL, API URL, auth method, access requirements",
        "Test data strategy documented per environment"
      ],
      "files": ["ENV_TEST_MATRIX.md"],
      "dependsOn": [],
      "priority": 1,
      "passes": false,
      "category": "environment"
    },
    {
      "id": "QA-SEC-001",
      "title": "Secrets hygiene audit",
      "description": "Verify no secrets in codebase, .env.example exists, .gitignore configured",
      "acceptanceCriteria": [
        "No hardcoded secrets found in codebase",
        ".env.example exists with all required variables (no values)",
        ".gitignore includes .env*, credentials, keys",
        "Secrets loaded via env vars or secret manager"
      ],
      "files": [".env.example", ".gitignore"],
      "dependsOn": [],
      "priority": 2,
      "passes": false,
      "category": "security"
    }
  ]
}
```

## Execution Flow

```bash
# Step 1: Generate QA PRD for project
claude /qa-audit ~/Projects/my-app --scope full

# Step 2: Review generated prd.json (human checkpoint)
cat ~/Projects/my-app/prd.json

# Step 3: Run Ralph with reasonable iteration limit
./ralph.sh ~/Projects/my-app 30

# Step 4: Review results
./ralph.sh status ~/Projects/my-app
```

## Key Differences from Original Proposal

| Original | Proposed |
|----------|----------|
| Ralph Wiggum single prompt | Main Ralph with PRD stories |
| 80 iterations blind | Trackable stories with status |
| Creates PRD during execution | PRD generated before execution |
| Everything in one loop | Modular stories with dependencies |
| No human checkpoints | Review PRD before running |
| Plugin confusion | Clear tool/skill references |
| Assumes all features present | Adapts to project type |

## QA Prompt.md Modifications

The existing `prompt.md` can be used as-is, but QA stories should include:

### QA-Specific Acceptance Criteria Patterns

```json
"acceptanceCriteria": [
  "QA_PROGRESS.md updated with findings",
  "No regressions in existing tests",
  "Findings logged with severity: CRITICAL/HIGH/MEDIUM/LOW/INFO"
]
```

### QA Progress File Format

```markdown
# QA Progress Log
# Project: My App
# Scope: full
# Started: 2026-01-11

## Findings Summary
| ID | Severity | Category | Status | Description |
|----|----------|----------|--------|-------------|
| F-001 | HIGH | security | FIXED | Exposed API key in config.js |
| F-002 | MEDIUM | testing | OPEN | No tests for auth flow |

## Story Progress
- [x] QA-ENV-001: Environment matrix
- [x] QA-SEC-001: Secrets hygiene
- [ ] QA-SEC-002: Auth validation (in progress)
```

## Iteration Limits by Scope

| Scope | Stories | Recommended Iterations |
|-------|---------|------------------------|
| `security` | ~5-8 | 15 |
| `testing` | ~5-10 | 20 |
| `e2e` | ~3-5 | 10 |
| `full` | ~15-25 | 40 |

## Stop Conditions

1. **All stories pass**: Normal completion (`<promise>COMPLETE</promise>`)
2. **Critical blocker found**: Story notes include `BLOCKER: ...`, human review needed
3. **Max iterations reached**: Continue later with `./ralph.sh` again
4. **Environment inaccessible**: Story blocked, documented in progress.txt

## Browser Testing Strategy

### When Playwright/Browser Tools Available
- Use headless Playwright for E2E stories
- Screenshots on failure stored in `qa-screenshots/`
- Trace files for debugging complex failures

### When Unavailable
- Skip E2E stories with note in progress.txt
- Provide manual test instructions in QA_PROGRESS.md
- Story marked as `passes: true` with caveat

### Tool Detection
```markdown
# In QA story acceptance criteria:
"acceptanceCriteria": [
  "If browser tools available: E2E test passes",
  "If browser tools unavailable: Manual test documented in QA_PROGRESS.md"
]
```

## Security Baseline (Simplified)

Instead of the exhaustive list, focus on **actionable, automatable checks**:

### Tier 1: Automated (Every Project)
1. **Secrets scan**: grep for API keys, passwords, tokens
2. **Dependency audit**: npm audit / pip audit
3. **.gitignore check**: Sensitive patterns included
4. **HTTPS enforcement**: No hardcoded http:// URLs in prod config

### Tier 2: Semi-Automated (With Test Suite)
1. **Auth boundary tests**: 401/403 for protected routes
2. **Input validation tests**: XSS/injection patterns rejected
3. **Error response tests**: No stack traces in prod errors

### Tier 3: Manual Review (Documented)
1. **Session handling**: Cookies scoped correctly
2. **Rate limiting**: Present or documented as out-of-scope
3. **Logging practices**: No secrets in logs

## Implementation Status

All features from this proposal have been implemented:

- ✅ `/qa-audit` skill created in `.claude-plugin/skills/qa-audit.md`
- ✅ Story templates for Environment, Security, Testing, Documentation
- ✅ Story dependencies and priority ordering
- ✅ Browser testing with graceful fallback
- ✅ Full remediation mode (not just audit)
- ✅ Credentials collection for browser/API/AWS auth

### Usage

```bash
# Run a full QA audit with remediation
claude /qa-audit ~/Projects/my-app --env local

# Just run security checks
claude /qa-audit ~/Projects/my-app --scope security
```

See the skill documentation for complete usage details.
