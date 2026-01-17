# Contributing to Ralph

Thanks for your interest in contributing to Ralph! This document provides guidelines for contributing to the project.

## Ways to Contribute

- **Bug Reports**: Open an issue describing the bug, steps to reproduce, and expected behavior
- **Feature Requests**: Open an issue describing the feature and its use case
- **Documentation**: Improve README, CLAUDE.md, or add examples
- **Code**: Fix bugs or implement new features

## Development Environment

Ralph uses a three-folder structure for development:

```
~/tools/ralph-cc-loop/        # Main working copy (optional)
~/Projects/cgai/
├── dev-ralph-cc-loop/        # Development - push DISABLED
└── prod-ralph-cc-loop/       # Production - push ENABLED
```

| Folder | Purpose | Git Push |
|--------|---------|----------|
| `dev-*` | Testing, running Ralph, making changes | Disabled |
| `prod-*` | Pushing to GitHub, creating PRs | Enabled |

### Why This Setup?

- **Safe testing**: Can't accidentally push incomplete work from dev
- **Clean separation**: Dev can have PRD files, logs, experiments
- **Controlled releases**: Only intentional changes go through prod

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Ensure you have the prerequisites:
   - `jq` - JSON parsing
   - `claude` - Claude Code CLI
   - `gh` - GitHub CLI (authenticated)

## Development Guidelines

### Code Style

- **Shell scripts**: Follow [Google's Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use meaningful variable names
- Add comments for non-obvious logic
- Keep functions focused and small

### Testing Changes

Before submitting:

1. Test `ralph.sh` against a sample project with a `prd.json`
2. Verify all modes work (`feature` and `backlog`)
3. Test the status command: `./ralph.sh status <project>`
4. Ensure skills work: `/prd`, `/review-issues`, `/review-prs`

### Commit Messages

Use conventional commit format:

```
type: short description

Longer explanation if needed.
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

Examples:
- `feat: add support for custom iteration count`
- `fix: handle missing prd.json gracefully`
- `docs: clarify backlog mode in README`

## Pull Request Process

1. Create a branch from `main` with a descriptive name
2. Make your changes with clear, focused commits
3. Update documentation if needed (README.md, CLAUDE.md)
4. Open a PR with:
   - Clear description of what changed and why
   - Link to related issue (if applicable)
   - Any testing you performed

## Development Workflow

### Making Changes (Dev → Prod → GitHub)

**1. Work in dev folder:**
```bash
cd ~/Projects/cgai/dev-ralph-cc-loop

# Make changes, run Ralph, test, etc.
./ralph.sh .                    # Run Ralph on a PRD
./ralph.sh --check-deps         # Test installation verification
```

**2. When ready to push, sync to prod:**
```bash
# Sync files from dev to prod (excludes .git, prd.json, logs)
rsync -av \
  --exclude='.git' \
  --exclude='prd.json' \
  --exclude='progress.txt' \
  --exclude='ralph-output.log' \
  --exclude='.last-branch' \
  --exclude='archive' \
  ~/Projects/cgai/dev-ralph-cc-loop/ \
  ~/Projects/cgai/prod-ralph-cc-loop/
```

**3. Commit and push from prod:**
```bash
cd ~/Projects/cgai/prod-ralph-cc-loop

# Create branch, commit, push
git checkout -b feature/my-changes
git add -A
git commit -m "feat: description of changes"
git push -u origin feature/my-changes

# Create PR
gh pr create --title "feat: My Changes" --body "Description..."
```

**4. After PR is merged, clean up:**
```bash
# Clean up prod
cd ~/Projects/cgai/prod-ralph-cc-loop
git checkout main && git pull origin main

# Clean up dev
cd ~/Projects/cgai/dev-ralph-cc-loop
git checkout main && git pull origin main
git branch -D feature/my-changes 2>/dev/null || true

# Remove Ralph-generated files from dev
rm -f prd.json progress.txt ralph-output.log .last-branch
rm -rf archive
```

### Helper Script (Recommended)

A `dev-workflow.sh` script automates the entire workflow:

```bash
# Show available commands
./dev-workflow.sh

# Sync dev → prod (no commit)
./dev-workflow.sh sync

# Full workflow: sync, commit, push, create PR
./dev-workflow.sh push "feat: my new feature"

# Merge PR and clean up everything
./dev-workflow.sh merge 8

# Just clean Ralph files from dev
./dev-workflow.sh clean

# Show status of both folders
./dev-workflow.sh status
```

To set up the helper script, copy from the gist or create it locally (it's in .gitignore).

### Manual Commands Reference

| Action | Command |
|--------|---------|
| Sync dev → prod | `rsync -av --exclude='.git' --exclude='prd.json' --exclude='progress.txt' --exclude='ralph-output.log' --exclude='.last-branch' --exclude='archive' ~/Projects/cgai/dev-ralph-cc-loop/ ~/Projects/cgai/prod-ralph-cc-loop/` |
| Merge PR (admin) | `gh pr merge <number> --squash --delete-branch --admin` |
| Clean dev files | `rm -f prd.json progress.txt ralph-output.log .last-branch` |
| Update both folders | `git checkout main && git pull origin main` |

## Project Structure

```
ralph-cc-loop/
├── ralph.sh              # Main loop script - core logic lives here
├── prompt.md             # Instructions sent to each Claude instance
├── .claude-plugin/       # Claude Code plugin
│   ├── plugin.json       # Plugin manifest with version
│   └── skills/           # 13 Claude Code skills
│       ├── prd.md            # /prd - PRD generation
│       ├── review-issues.md  # /review-issues - GitHub issue review
│       ├── review-prs.md     # /review-prs - PR review
│       ├── qa-audit.md       # /qa-audit - Production readiness audit
│       ├── test-coverage.md  # /test-coverage - Test coverage analysis
│       ├── a11y-audit.md     # /a11y-audit - Accessibility audit
│       ├── perf-audit.md     # /perf-audit - Performance audit
│       ├── deps-update.md    # /deps-update - Dependency updates
│       ├── refactor.md       # /refactor - Code refactoring
│       ├── migrate.md        # /migrate - Framework migrations
│       ├── docs-gen.md       # /docs-gen - Documentation generation
│       ├── onboard.md        # /onboard - Onboarding docs
│       └── security-audit.md # /security-audit - Security audit
├── docs/                 # Additional documentation
│   ├── ralph-comparison.md   # Comparison with ralph-wiggum
│   └── images/               # Documentation images
├── README.md             # User documentation
├── CLAUDE.md             # Developer/AI guidance
├── CONTRIBUTING.md       # This file
└── prd.json.example      # Example PRD template
```

## Questions?

Open an issue with the `question` label if you need help or clarification.
