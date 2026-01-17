---
name: changelog
description: Generate or update CHANGELOG.md from git history and pull requests. Use when asked to "generate changelog", "update changelog", "create release notes", or "document changes".
arguments: "<project_path> [--version <version>] [--since <tag|date>] [--format keep|conventional] | --help"
---

# Help Check

If the user passed `--help` as an argument, output the following and stop:

```
/changelog - Generate CHANGELOG from git history

Usage:
  claude /changelog <project_path> [options]
  claude /changelog --help

Arguments:
  project_path           Path to the project (required)

Options:
  --version <version>    Version for this release (e.g., 1.2.0)
  --since <ref>          Starting point: tag, commit, or date (default: last tag)
  --format <format>      Output format: keep (default), conventional
  --unreleased           Add to Unreleased section instead of version
  --help                 Show this help message

Formats:
  keep          Keep a Changelog format (keepachangelog.com)
  conventional  Conventional Changelog format

Examples:
  claude /changelog ~/Projects/my-app
  claude /changelog ~/Projects/my-app --version 2.0.0
  claude /changelog ~/Projects/my-app --since v1.5.0
  claude /changelog ~/Projects/my-app --since 2024-01-01
  claude /changelog ~/Projects/my-app --unreleased

What it does:
  - Parses git commits (conventional commits supported)
  - Fetches merged PR titles and descriptions
  - Groups changes by type (Added, Changed, Fixed, etc.)
  - Links to commits, PRs, and issues
  - Updates existing CHANGELOG.md or creates new one
  - Detects breaking changes

Output:
  - CHANGELOG.md (created or updated)
```

---

# Changelog Generator

You are a release manager generating changelogs. This skill:
1. Analyzes git history and pull requests
2. Groups changes by type using conventional commits
3. Creates human-readable changelog entries
4. Updates or creates CHANGELOG.md

## Change Categories (Keep a Changelog)

| Category | Conventional Commit | Description |
|----------|--------------------| ------------|
| Added | `feat:` | New features |
| Changed | `refactor:`, `perf:` | Changes in existing functionality |
| Deprecated | `deprecate:` | Soon-to-be removed features |
| Removed | `remove:` | Removed features |
| Fixed | `fix:` | Bug fixes |
| Security | `security:` | Security fixes |

## Phase 1: Project Setup

### Step 1.1: Navigate to Project

```bash
cd [project_path] && pwd
```

### Step 1.2: Get Repository Info

```bash
# Get repo name for links
git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]\(.*\)\.git/\1/' | sed 's/.*github.com[:/]\(.*\)/\1/'

# Check if CHANGELOG.md exists
ls CHANGELOG.md 2>/dev/null
```

### Step 1.3: Determine Starting Point

If `--since` provided, use that. Otherwise:

```bash
# Get the last tag
git describe --tags --abbrev=0 2>/dev/null || echo "none"

# If no tags, use first commit
git rev-list --max-parents=0 HEAD 2>/dev/null | head -1
```

### Step 1.4: Determine Version

If `--version` provided, use that. Otherwise:

```bash
# Try to get from package.json
cat package.json 2>/dev/null | jq -r '.version'

# Or pyproject.toml
grep "^version" pyproject.toml 2>/dev/null | cut -d'"' -f2

# Or Cargo.toml
grep "^version" Cargo.toml 2>/dev/null | head -1 | cut -d'"' -f2
```

If still unknown, use "Unreleased".

## Phase 2: Gather Changes

### Step 2.1: Get Commits Since Last Release

```bash
# Get commits with full message
git log [since]..HEAD --pretty=format:"%H|%s|%b|%an|%ad" --date=short

# Get merge commits (PRs)
git log [since]..HEAD --merges --pretty=format:"%H|%s|%b"
```

### Step 2.2: Parse Conventional Commits

For each commit, extract:
- **Type**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`
- **Scope**: Optional `(scope)` after type
- **Breaking**: `!` after type/scope or `BREAKING CHANGE:` in body
- **Description**: The commit message after `:`
- **Body**: Additional context
- **References**: `#123`, `closes #123`, `fixes #123`

Example parsing:
```
feat(auth): add OAuth2 support

Implements Google and GitHub OAuth providers.

Closes #45
```

→ Type: `feat`, Scope: `auth`, Description: `add OAuth2 support`, Refs: `#45`

### Step 2.3: Fetch PR Information (if GitHub)

```bash
# Get merged PRs
gh pr list --state merged --base main --json number,title,body,labels,mergedAt --limit 100
```

For each PR:
- Title (often cleaner than merge commit)
- Labels (can indicate type: `bug`, `enhancement`, `breaking`)
- Body (may have detailed description)
- Linked issues

### Step 2.4: Deduplicate and Enrich

- Prefer PR title over merge commit message
- Link commits to their PRs
- Extract issue references
- Identify breaking changes from labels or commit messages

## Phase 3: Categorize Changes

### Step 3.1: Map to Categories

| Source | Category |
|--------|----------|
| `feat:` commits | Added |
| `fix:` commits | Fixed |
| `refactor:` commits | Changed |
| `perf:` commits | Changed |
| `security:` commits | Security |
| `BREAKING CHANGE` | ⚠️ flag in relevant category |
| PR label `bug` | Fixed |
| PR label `enhancement` | Added |
| PR label `breaking` | ⚠️ flag |

### Step 3.2: Filter Out Noise

Exclude from changelog:
- `chore:` commits (unless significant)
- `docs:` commits (unless user-facing)
- `test:` commits
- `style:` commits
- Merge commits (use PR info instead)
- Commits that are part of a PR (avoid duplicates)

### Step 3.3: Group by Category

```
Added:
- feat(auth): OAuth2 support (#45)
- feat(api): new /users endpoint (#52)

Fixed:
- fix(ui): button alignment on mobile (#48)
- fix: memory leak in worker (#51)

Changed:
- refactor(db): improve query performance (#50)

Security:
- security: patch XSS vulnerability (#53)
```

## Phase 4: Generate Changelog

### Step 4.1: Keep a Changelog Format (default)

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2024-01-15

### Added
- OAuth2 authentication with Google and GitHub providers ([#45](link))
- New `/users` API endpoint for user management ([#52](link))

### Fixed
- Button alignment issue on mobile devices ([#48](link))
- Memory leak in background worker process ([#51](link))

### Changed
- Improved database query performance by 40% ([#50](link))

### Security
- Patched XSS vulnerability in comment rendering ([#53](link))

## [1.1.0] - 2024-01-01
...
```

### Step 4.2: Conventional Changelog Format (if --format conventional)

```markdown
# Changelog

## [1.2.0](compare-link) (2024-01-15)

### Features

* **auth:** OAuth2 support ([#45](link)) ([commit](link))
* **api:** new /users endpoint ([#52](link)) ([commit](link))

### Bug Fixes

* **ui:** button alignment on mobile ([#48](link)) ([commit](link))
* memory leak in worker ([#51](link)) ([commit](link))

### Performance Improvements

* **db:** improve query performance ([#50](link)) ([commit](link))
```

### Step 4.3: Add Links

For GitHub repos, add links:
- `[#45](https://github.com/owner/repo/pull/45)` for PRs
- `[commit](https://github.com/owner/repo/commit/abc123)` for commits
- `[1.2.0](https://github.com/owner/repo/compare/v1.1.0...v1.2.0)` for version comparison

## Phase 5: Update CHANGELOG.md

### Step 5.1: If CHANGELOG.md Exists

1. Read existing content
2. Find insertion point (after header, before first version)
3. Insert new version section
4. Update `[Unreleased]` link if present

### Step 5.2: If No CHANGELOG.md

Create new file with:
1. Header and format description
2. Unreleased section (empty)
3. New version section
4. Link references at bottom

### Step 5.3: Validate

- No duplicate versions
- Dates are in order (newest first)
- Links are valid format
- Breaking changes are highlighted

## Phase 6: Output

### Step 6.1: Write CHANGELOG.md

Write the updated or new changelog file.

### Step 6.2: Show Summary

```
Changelog Generated
--------------------------------------------------

Project:     [name]
Version:     [version]
Since:       [tag/date]
Date:        [today]

Changes:
  Added:       X
  Changed:     X
  Fixed:       X
  Security:    X
  Breaking:    X ⚠️

Contributors: @user1, @user2, @user3

Output: CHANGELOG.md

Preview:
--------------------------------------------------
## [1.2.0] - 2024-01-15

### Added
- OAuth2 authentication with Google and GitHub providers (#45)
- New `/users` API endpoint for user management (#52)
...
```

### Step 6.3: Suggest Next Steps

```
Next steps:
  1. Review CHANGELOG.md for accuracy
  2. Add any manual notes or context
  3. Commit: git add CHANGELOG.md && git commit -m "docs: update changelog for v1.2.0"
  4. Tag release: git tag v1.2.0
  5. Push: git push && git push --tags
```

## Edge Cases

### No Conventional Commits

If commits don't follow conventional format:
1. Try to infer type from keywords (fix, add, update, remove)
2. Use PR labels if available
3. Group remaining as "Changed"
4. Note in output that conventional commits would improve changelog

### Monorepo

If multiple packages detected:
1. Group changes by package/workspace
2. Use scope to identify package
3. Consider separate changelogs per package

### Pre-1.0 Projects

For 0.x versions:
- Minor version = breaking changes allowed
- Note this in changelog header
- Still flag breaking changes for visibility
