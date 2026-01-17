# Contributing to Ralph

Thanks for your interest in contributing to Ralph! This document provides guidelines for contributing to the project.

## Ways to Contribute

- **Bug Reports**: Open an issue describing the bug, steps to reproduce, and expected behavior
- **Feature Requests**: Open an issue describing the feature and its use case
- **Documentation**: Improve README, CLAUDE.md, or add examples
- **Code**: Fix bugs or implement new features

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
