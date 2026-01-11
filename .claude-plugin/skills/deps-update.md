# /deps-update

---
description: Audit and update outdated dependencies with automated testing and PR creation
arguments:
  - name: project_path
    description: Path to the project to audit
    required: true
  - name: --help
    description: Show help message
    required: false
---

# Help Check

If the user passed `--help` as an argument, output the following and stop:

```
/deps-update - Audit and update outdated dependencies

Usage:
  claude /deps-update <project_path>
  claude /deps-update --help

Arguments:
  project_path    Path to the project to audit (required)

Options:
  --help          Show this help message

Examples:
  claude /deps-update ~/Projects/my-app
  claude /deps-update .

What it does:
  - Detects package managers (npm, yarn, pnpm, pip, gem, go, cargo)
  - Runs security audits (npm audit, pip-audit, etc.)
  - Identifies outdated dependencies
  - Generates PRD with prioritized update stories

Update priority:
  1. Security vulnerabilities (critical/high)
  2. Major version updates (with breaking change analysis)
  3. Minor/patch updates (batched)
  4. Dev dependencies
  5. Cleanup (remove unused)
  6. Final verification

Output:
  - prd.json: Update stories for Ralph to execute
  - DEPS_CHANGELOG.md: Log of all changes made

Remediation:
  - Auto-fixes security vulnerabilities
  - Reviews breaking changes before major updates
  - Runs tests after each update batch
  - Creates separate commits for easy rollback
```

---

You are a dependency management expert. Your task is to audit a project's dependencies, identify outdated packages, update them safely, and ensure everything still works.

## Phase 1: Project Analysis

### Step 1.1: Detect Package Managers and Lock Files

Scan the project for package managers:

```bash
# Check for package managers
ls -la package.json pnpm-lock.yaml yarn.lock package-lock.json 2>/dev/null
ls -la requirements.txt Pipfile pyproject.toml poetry.lock 2>/dev/null
ls -la Gemfile Gemfile.lock 2>/dev/null
ls -la go.mod go.sum 2>/dev/null
ls -la Cargo.toml Cargo.lock 2>/dev/null
ls -la composer.json composer.lock 2>/dev/null
```

### Step 1.2: Identify Current Dependency State

For each detected package manager, list current dependencies and their versions:

**Node.js (npm/yarn/pnpm):**
```bash
npm outdated --json 2>/dev/null || yarn outdated --json 2>/dev/null || pnpm outdated --json 2>/dev/null
```

**Python:**
```bash
pip list --outdated --format=json 2>/dev/null
```

**Ruby:**
```bash
bundle outdated --parseable 2>/dev/null
```

**Go:**
```bash
go list -u -m all 2>/dev/null
```

**Rust:**
```bash
cargo outdated 2>/dev/null
```

### Step 1.3: Check for Security Vulnerabilities

Run security audits:

```bash
# Node.js
npm audit --json 2>/dev/null || yarn audit --json 2>/dev/null || pnpm audit --json 2>/dev/null

# Python
pip-audit --format=json 2>/dev/null || safety check --json 2>/dev/null

# Ruby
bundle audit check 2>/dev/null

# Go
govulncheck ./... 2>/dev/null
```

## Phase 2: Generate PRD

Based on analysis, generate a `prd.json` with this structure:

```json
{
  "project": "{project_name}",
  "mode": "backlog",
  "baseBranch": "main",
  "description": "Dependency updates and security patches",
  "userStories": []
}
```

### Story Categories

#### Category 1: Security Vulnerabilities (Priority 1)
Critical and high severity vulnerabilities get individual stories:

```json
{
  "id": "DEP-SEC-001",
  "title": "Fix critical vulnerability in {package}",
  "description": "Update {package} to fix {CVE-ID}: {description}",
  "acceptanceCriteria": [
    "IDENTIFY: Current version {current} has {severity} vulnerability {CVE-ID}",
    "FIX: Update {package} from {current} to {fixed_version}",
    "VERIFY: Run `npm audit` / `pip-audit` - no {severity} vulnerabilities for this package",
    "VERIFY: All tests pass after update",
    "VERIFY: App starts and basic functionality works",
    "DOCUMENT: Log update in DEPS_CHANGELOG.md"
  ],
  "files": ["package.json", "package-lock.json", "DEPS_CHANGELOG.md"],
  "dependsOn": [],
  "priority": 1,
  "passes": false,
  "category": "security"
}
```

#### Category 2: Major Version Updates (Priority 2)
Major versions may have breaking changes - one story per package:

```json
{
  "id": "DEP-MAJ-001",
  "title": "Update {package} to v{major}",
  "description": "Major version update for {package} - review breaking changes",
  "acceptanceCriteria": [
    "IDENTIFY: Read CHANGELOG/release notes for breaking changes between v{current} and v{target}",
    "IDENTIFY: Search codebase for usage of deprecated/changed APIs",
    "FIX: Update package version in package.json",
    "FIX: Update any code affected by breaking changes",
    "FIX: Update any types/imports that changed",
    "VERIFY: TypeScript compiles without errors",
    "VERIFY: All tests pass",
    "VERIFY: App starts and affected features work",
    "FOLLOW-UP: Create DEP-TEST story if new features need test coverage",
    "DOCUMENT: Log breaking changes addressed in DEPS_CHANGELOG.md"
  ],
  "files": ["package.json", "package-lock.json", "DEPS_CHANGELOG.md"],
  "dependsOn": ["DEP-SEC-*"],
  "priority": 2,
  "passes": false,
  "category": "major-update"
}
```

#### Category 3: Minor/Patch Updates (Priority 3)
Batch compatible updates together:

```json
{
  "id": "DEP-MIN-001",
  "title": "Batch minor/patch dependency updates",
  "description": "Update all compatible minor and patch versions",
  "acceptanceCriteria": [
    "IDENTIFY: List all packages with minor/patch updates available",
    "FIX: Update all minor versions: {list}",
    "FIX: Update all patch versions: {list}",
    "VERIFY: Lock file regenerated cleanly",
    "VERIFY: All tests pass",
    "VERIFY: App starts successfully",
    "DOCUMENT: Log all updates in DEPS_CHANGELOG.md"
  ],
  "files": ["package.json", "package-lock.json", "DEPS_CHANGELOG.md"],
  "dependsOn": ["DEP-MAJ-*"],
  "priority": 3,
  "passes": false,
  "category": "minor-update"
}
```

#### Category 4: Dev Dependencies (Priority 4)
Update development dependencies separately:

```json
{
  "id": "DEP-DEV-001",
  "title": "Update dev dependencies",
  "description": "Update linters, test frameworks, build tools",
  "acceptanceCriteria": [
    "IDENTIFY: List outdated devDependencies",
    "FIX: Update ESLint and plugins to latest compatible versions",
    "FIX: Update Prettier to latest",
    "FIX: Update TypeScript to latest minor version",
    "FIX: Update test framework (Jest/Vitest/etc) to latest",
    "FIX: Update build tools (Vite/Webpack/etc) to latest minor",
    "VERIFY: Linting passes (fix any new rule violations)",
    "VERIFY: All tests pass",
    "VERIFY: Build completes successfully",
    "DOCUMENT: Log updates in DEPS_CHANGELOG.md"
  ],
  "files": ["package.json", "package-lock.json", "DEPS_CHANGELOG.md"],
  "dependsOn": ["DEP-MIN-*"],
  "priority": 4,
  "passes": false,
  "category": "dev-deps"
}
```

#### Category 5: Cleanup (Priority 5)
Remove unused dependencies:

```json
{
  "id": "DEP-CLN-001",
  "title": "Remove unused dependencies",
  "description": "Identify and remove packages that are no longer used",
  "acceptanceCriteria": [
    "IDENTIFY: Run depcheck/npm-check to find unused dependencies",
    "IDENTIFY: Manually verify each flagged package is truly unused",
    "FIX: Remove confirmed unused packages from package.json",
    "FIX: Remove any orphaned @types packages",
    "VERIFY: App builds successfully",
    "VERIFY: All tests pass",
    "VERIFY: No import errors at runtime",
    "DOCUMENT: Log removed packages in DEPS_CHANGELOG.md"
  ],
  "files": ["package.json", "package-lock.json", "DEPS_CHANGELOG.md"],
  "dependsOn": ["DEP-DEV-*"],
  "priority": 5,
  "passes": false,
  "category": "cleanup"
}
```

#### Category 6: Final Verification (Priority 6)

```json
{
  "id": "DEP-FIN-001",
  "title": "Final dependency update verification",
  "description": "Comprehensive verification of all dependency changes",
  "acceptanceCriteria": [
    "VERIFY: `npm audit` shows no high/critical vulnerabilities",
    "VERIFY: `npm outdated` shows no security-critical updates pending",
    "VERIFY: All tests pass",
    "VERIFY: App builds for production",
    "VERIFY: App starts and core flows work",
    "DOCUMENT: Create summary in DEPS_CHANGELOG.md with all changes",
    "DOCUMENT: Note any packages intentionally kept at older versions and why"
  ],
  "files": ["DEPS_CHANGELOG.md"],
  "dependsOn": ["DEP-CLN-*"],
  "priority": 6,
  "passes": false,
  "category": "verification"
}
```

## Phase 3: Pre-flight Checks

Before generating the PRD, verify:

1. **Git state is clean**: No uncommitted changes
2. **Tests pass**: Current test suite passes before updates
3. **Lock file exists**: Don't update without a lock file
4. **CI config exists**: Understand what CI runs

## Phase 4: Output

Generate `prd.json` in the project directory with:
- Security updates first (priority 1)
- Major updates individually (priority 2)
- Minor/patch batched (priority 3)
- Dev deps separate (priority 4)
- Cleanup last (priority 5)
- Final verification (priority 6)

Create `DEPS_CHANGELOG.md` if it doesn't exist:

```markdown
# Dependency Changelog

## [Unreleased]

### Security Fixes
-

### Major Updates
-

### Minor/Patch Updates
-

### Dev Dependencies
-

### Removed
-

### Notes
-
```

## Update Strategies by Ecosystem

### Node.js
- Use `npm update` for minor/patch
- Edit package.json directly for major
- Always regenerate lock file
- Run `npm ci` to verify clean install

### Python
- Use `pip install --upgrade` for updates
- Update requirements.txt or pyproject.toml
- Regenerate with `pip freeze` or `poetry lock`

### Ruby
- Use `bundle update {gem}` for specific updates
- `bundle update` for all (careful with major versions)

### Go
- Use `go get -u` for updates
- Run `go mod tidy` after updates

### Rust
- Use `cargo update` for compatible updates
- Edit Cargo.toml for major versions

## Risk Mitigation

1. **Always have passing tests first** - Don't update if tests already fail
2. **Security first** - Fix vulnerabilities before feature updates
3. **One major at a time** - Don't batch breaking changes
4. **Lock file hygiene** - Always commit lock files
5. **Rollback plan** - Each story is a separate commit for easy revert
