---
name: dead-code
description: Find and remove unused code, exports, dependencies, and orphan files. Use when asked to "find dead code", "clean up unused code", "find unused dependencies", or "remove cruft".
arguments: "<project_path> [--fix] [--scope all|deps|exports|files] | --help"
---

# Help Check

If the user passed `--help` as an argument, output the following and stop:

```
/dead-code - Find and remove unused code

Usage:
  claude /dead-code <project_path> [options]
  claude /dead-code --help

Arguments:
  project_path           Path to the project to analyze (required)

Options:
  --fix                  Remove dead code (default: report only)
  --scope <scope>        What to scan: all (default), deps, exports, files
  --help                 Show this help message

Scopes:
  all        Full scan: dependencies, exports, files (default)
  deps       Only unused dependencies in package.json/requirements.txt
  exports    Only unused exports and functions
  files      Only orphan files not imported anywhere

Examples:
  claude /dead-code ~/Projects/my-app
  claude /dead-code ~/Projects/my-app --fix
  claude /dead-code ~/Projects/my-app --scope deps
  claude /dead-code ~/Projects/my-app --scope exports --fix

What it finds:
  - Unused npm/pip/cargo dependencies
  - Exported functions/classes never imported
  - Files not imported by any other file
  - Unreachable code paths
  - Commented-out code blocks
  - Unused variables and imports within files
  - Dead feature flags
  - Orphan test files (tests for deleted code)

Output:
  - DEAD_CODE_REPORT.md: Detailed findings
  - Console summary with quick stats
```

---

# Dead Code Detection

You are a code analysis expert finding unused code. This skill:
1. Takes a **local project path** to analyze
2. Scans for various types of dead code
3. Generates a detailed report
4. Optionally removes dead code safely

## Phase 1: Project Discovery

### Step 1.1: Locate and Analyze Project

```bash
cd [project_path] && pwd
```

### Step 1.2: Detect Project Type

```bash
# Check for package managers and entry points
ls package.json pyproject.toml requirements.txt Cargo.toml go.mod pom.xml Gemfile composer.json 2>/dev/null

# Get project structure
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" \) | head -50
```

### Step 1.3: Identify Entry Points

Entry points are files that are NOT expected to be imported:
- `index.ts/js`, `main.ts/js`, `app.ts/js`
- `server.ts/js`, `cli.ts/js`
- Files in `bin/`, `scripts/`
- Test files (`*.test.ts`, `*.spec.ts`, `__tests__/`)
- Config files (`*.config.ts/js`)
- `__main__.py`, `manage.py`, `wsgi.py`

## Phase 2: Unused Dependencies (if scope includes deps)

### Step 2.1: Node.js Projects

```bash
# List all production dependencies
cat package.json | jq -r '.dependencies // {} | keys[]' 2>/dev/null

# For each dependency, check if it's imported
# Search for: import ... from 'package' or require('package')
```

For each dependency in `dependencies`:
1. Search for imports: `grep -r "from ['\"]<package>" src/` and `grep -r "require(['\"]<package>"`
2. Check if used in scripts (package.json scripts)
3. Check if it's a CLI tool used in npm scripts
4. Check if it's a type-only dependency (@types/*)

### Step 2.2: Python Projects

```bash
# List dependencies
cat requirements.txt 2>/dev/null | grep -v "^#" | grep -v "^$" | cut -d'=' -f1 | cut -d'>' -f1 | cut -d'<' -f1

# For each, check imports
grep -r "^import <package>" . --include="*.py"
grep -r "^from <package>" . --include="*.py"
```

### Step 2.3: Mark as Unused If

- No imports found in source code
- Not used in build scripts or config
- Not a peer dependency requirement
- Not a CLI tool used in scripts

## Phase 3: Unused Exports (if scope includes exports)

### Step 3.1: Find All Exports

```bash
# TypeScript/JavaScript exports
grep -rn "^export " --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" src/
grep -rn "export default" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" src/
grep -rn "module.exports" --include="*.js" src/

# Python exports (functions/classes at module level)
grep -rn "^def \|^class \|^async def " --include="*.py" .
```

### Step 3.2: For Each Export, Check Usage

For each exported function/class/constant:
1. Search for imports of that specific name
2. Check if it's re-exported from an index file
3. Check if it's used in tests (still flag but note it's test-only)
4. Check if it's part of public API (exported from package entry point)

### Step 3.3: Mark as Unused If

- Not imported anywhere except its own file
- Not part of public API
- Not used in tests (or only in tests - flag as "test-only")

## Phase 4: Orphan Files (if scope includes files)

### Step 4.1: Build Import Graph

```bash
# Find all source files
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) -not -path "*/node_modules/*" -not -path "*/.git/*"

# For each file, find what it imports and what imports it
```

### Step 4.2: Identify Orphans

A file is orphan if:
- It's not an entry point
- It's not imported by any other file
- It's not a config file
- It's not a type declaration file used by TypeScript

### Step 4.3: Check for Indirect Usage

Before flagging, verify:
- Dynamic imports: `import()`, `require.resolve()`
- Glob imports: `require.context`, webpack magic comments
- Auto-loaded files (Next.js pages, Nuxt pages, etc.)
- Framework conventions (middleware, hooks, plugins directories)

## Phase 5: Additional Checks

### Step 5.1: Commented-Out Code

```bash
# Find large commented blocks (3+ lines)
# Look for patterns like:
# // function oldFunction() {
# /*
#    old code
# */
```

Flag blocks that look like commented-out code vs documentation comments.

### Step 5.2: Unused Variables/Imports in Files

For TypeScript/JavaScript projects with ESLint:
```bash
npx eslint . --rule 'no-unused-vars: error' --rule '@typescript-eslint/no-unused-vars: error' 2>/dev/null
```

### Step 5.3: Dead Feature Flags

Search for feature flags that are always true/false:
```bash
grep -rn "featureFlag\|FEATURE_\|isEnabled\|FF_" --include="*.ts" --include="*.js" .
```

## Phase 6: Generate Report

Create `DEAD_CODE_REPORT.md` with:

```markdown
# Dead Code Report

**Project:** [name]
**Analyzed:** [date]
**Scope:** [all|deps|exports|files]

## Summary

| Category | Found | Safe to Remove | Review Needed |
|----------|-------|----------------|---------------|
| Unused Dependencies | X | X | X |
| Unused Exports | X | X | X |
| Orphan Files | X | X | X |
| Commented Code | X | X | X |

**Estimated Cleanup:** ~X lines, X files, X dependencies

---

## Unused Dependencies

### Safe to Remove
| Package | Last Used | Size Impact | Reason |
|---------|-----------|-------------|--------|
| lodash | Never imported | ~500KB | No imports found |

### Review Needed
| Package | Concern | Action |
|---------|---------|--------|
| @types/node | May be peer dep | Check tsconfig |

**Quick Fix:**
```bash
npm uninstall lodash leftpad moment
```

---

## Unused Exports

### [filename.ts]

| Export | Line | Type | Status |
|--------|------|------|--------|
| `oldHelper` | 45 | function | Never imported |
| `DeprecatedClass` | 102 | class | Only in tests |

---

## Orphan Files

| File | Size | Last Modified | Likely Reason |
|------|------|---------------|---------------|
| src/utils/old-helper.ts | 2.1KB | 6 months ago | Refactored out |
| src/components/Unused.tsx | 500B | 1 year ago | Feature removed |

---

## Commented-Out Code

| File | Lines | Preview |
|------|-------|---------|
| src/api.ts | 45-67 | `// async function oldEndpoint...` |

---

## Recommended Actions

### Immediate (Safe)
```bash
# Remove unused dependencies
npm uninstall [packages]

# Delete orphan files
rm src/utils/old-helper.ts
rm src/components/Unused.tsx
```

### Review First
- [ ] Verify `@types/node` is not needed
- [ ] Check if `oldHelper` is used via dynamic import
- [ ] Confirm feature X is fully removed before deleting flag
```

## Phase 7: Auto-Fix (if --fix)

### Step 7.1: Safe Removals Only

Only auto-remove if:
- Unused dependency with zero imports
- Orphan file with no dynamic import patterns
- Export that's clearly dead (not in index, not tested)

### Step 7.2: Create Backup Branch

```bash
git checkout -b cleanup/dead-code-removal
```

### Step 7.3: Remove Dead Code

```bash
# Dependencies
npm uninstall [safe-packages]

# Files
rm [orphan-files]

# Exports - edit files to remove unused exports
```

### Step 7.4: Verify Build

```bash
npm run build && npm test
```

If build fails, revert and flag the item as "review needed".

### Step 7.5: Commit Changes

```bash
git add -A
git commit -m "chore: remove dead code

Removed:
- X unused dependencies
- X orphan files
- X unused exports

Generated by /dead-code skill"
```

## Output

Always end with a summary:

```
Dead Code Analysis Complete
--------------------------------------------------

Project:     [name]
Scope:       [all|deps|exports|files]

Findings:
  Unused Dependencies:  X (Xkb savings)
  Unused Exports:       X
  Orphan Files:         X (X lines)
  Commented Code:       X blocks

Actions Taken:        [Report only | X items removed]

Output: DEAD_CODE_REPORT.md
```
