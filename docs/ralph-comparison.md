# Ralph Comparison: ralph-cc-loop vs ralph-wiggum

> **Ralph v2.1.0** includes 17 skills for comprehensive project automation.

This document compares the two Ralph systems available for iterative Claude Code execution.

## Overview

| | ralph-cc-loop | ralph-wiggum / ralph-loop |
|---|---|---|
| **Type** | Bash script orchestrator | Claude Code plugin |
| **Location** | This repo (`ralph.sh`) | `~/.claude/plugins/...` |
| **Approach** | PRD-driven story execution | Single-prompt iterative loops |
| **State** | Tracked in `prd.json` | Stateless (reads files each iteration) |

## Feature Comparison

| Feature | ralph-cc-loop | ralph-wiggum / ralph-loop |
|---------|:-------------:|:-------------------------:|
| **Architecture** | | |
| Bash script orchestrator | ✅ | ❌ |
| Claude Code plugin | ❌ | ✅ |
| Runs from any directory | ✅ | ✅ |
| **State Management** | | |
| PRD-driven (`prd.json`) | ✅ | ❌ |
| Discrete story tracking | ✅ | ❌ |
| `passes: true/false` per task | ✅ | ❌ |
| Story dependencies (`dependsOn`) | ✅ | ❌ |
| Priority ordering | ✅ | ❌ |
| Stateless between iterations | ❌ | ✅ |
| Must read files to know state | ❌ | ✅ |
| **Iteration Control** | | |
| Max iterations configurable | ✅ | ✅ |
| Completion promise detection | ✅ | ✅ |
| One task per iteration | ✅ | ❌ (open-ended) |
| Auto-stop when all tasks done | ✅ | ❌ |
| **Git Integration** | | |
| Auto-creates branches | ✅ | ❌ |
| Commits per story | ✅ | ❌ |
| PR creation (feature mode) | ✅ | ❌ |
| PR per story (backlog mode) | ✅ | ❌ |
| GitHub issue linking | ✅ | ❌ |
| **Modes** | | |
| Feature mode (single branch) | ✅ | ❌ |
| Backlog mode (branch per story) | ✅ | ❌ |
| **Progress Tracking** | | |
| `progress.txt` append log | ✅ | ❌ (manual) |
| `ralph-output.log` full output | ✅ | ❌ |
| Status command (`./ralph.sh status`) | ✅ | ❌ |
| Dry-run preview | ✅ | ❌ |
| **Flexibility** | | |
| Works with any prompt | ❌ (uses `prompt.md`) | ✅ |
| Self-directing exploration | ❌ | ✅ |
| Open-ended tasks | ❌ | ✅ |
| Custom completion conditions | ❌ | ✅ |
| **Setup Required** | | |
| Create `prd.json` first | ✅ | ❌ |
| Install plugin | ❌ | ✅ |
| **Best For** | | |
| Implementing features | ✅ | ⚠️ |
| Bug fixes / backlog | ✅ | ⚠️ |
| QA with discrete tasks | ✅ | ⚠️ |
| Research / exploration | ⚠️ | ✅ |
| Open-ended refactoring | ⚠️ | ✅ |
| "Keep going until done" | ⚠️ | ✅ |

**Legend:** ✅ = Yes / Built-in | ❌ = No | ⚠️ = Possible but not ideal

## Differences from Amp Version

This Claude Code version of Ralph has significant advantages over the original Amp-based Ralph:

### PRD Decomposition

**Big chunky requirements → Right-sized stories**

You can send Ralph a large, rough PRD and it will use `/prd` mode to intelligently break it down into properly-sized stories that fit within a single context window. The original Amp version required you to manually break down tasks.

```bash
# Give Ralph a high-level feature description
claude /prd "Add a complete user authentication system with OAuth,
email verification, password reset, and role-based permissions"

# Ralph breaks it into ~8-12 right-sized stories with dependencies
```

### 17 Automation Skills

The Claude Code version includes 17 skills that the Amp version doesn't have:

| Skill | What It Does | Amp Equivalent |
|-------|--------------|----------------|
| `/prd` | Breaks down features into right-sized stories | ❌ Manual |
| `/review-issues` | Generates PRD from GitHub issues | ❌ Manual |
| `/review-prs` | Reviews, approves, merges PRs | ❌ Manual |
| `/qa-audit` | Full QA audit with remediation | ❌ None |
| `/test-coverage` | Finds gaps, generates tests | ❌ None |
| `/a11y-audit` | WCAG accessibility audit | ❌ None |
| `/perf-audit` | Performance profiling | ❌ None |
| `/security-audit` | Security vulnerabilities & OWASP | ❌ None |
| `/dead-code` | Find unused deps, exports, files | ❌ None |
| `/architecture-review` | Architecture analysis & recommendations | ❌ None |
| `/deps-update` | Dependency updates + security fixes | ❌ Manual |
| `/refactor` | Code smell detection + fixes | ❌ None |
| `/migrate` | Framework/version migrations | ❌ None |
| `/docs-gen` | Auto-generate documentation | ❌ None |
| `/api-docs` | Generate OpenAPI/Swagger specs | ❌ None |
| `/onboard` | Create onboarding docs | ❌ None |
| `/changelog` | Generate CHANGELOG from git history | ❌ None |

### End-to-End Automation

With skills, you can automate entire workflows:

```bash
# Morning routine - takes ~5 minutes of human time
claude /review-issues --label bug           # Generate PRD from bugs
./ralph.sh ~/Projects/my-app 20             # Ralph fixes them
claude /review-prs --auto-merge             # Merge safe PRs
claude /deps-update ~/Projects/my-app       # Update dependencies
```

### Technical Differences

| Feature | Amp Version | Claude Code Version |
|---------|-------------|---------------------|
| CLI command | `amp --dangerously-allow-all` | `claude --print --dangerously-skip-permissions` |
| Thread references | Uses `$AMP_CURRENT_THREAD_ID` | Not available |
| Browser tool | `dev-browser` skill | MCP browser tools |
| Config files | `AGENTS.md` | `CLAUDE.md` |
| Skills/Plugins | Limited | 13 built-in skills |
| PRD decomposition | Manual | Automatic via `/prd` |

## When to Use Each

### Use ralph-cc-loop when:

- You can define discrete tasks upfront
- You want git integration (branches, commits, PRs)
- You need progress tracking and status visibility
- Tasks have dependencies on each other
- You want to review a PRD before execution
- You're implementing features or working through a backlog

### Use ralph-wiggum when:

- You want Claude to self-direct the work
- Tasks are exploratory or open-ended
- You have a single goal but unclear steps
- You want maximum flexibility in approach
- You're doing research or investigation
- You want "keep going until you figure it out"

## Example Workflows

### ralph-cc-loop workflow

```bash
# 1. Generate PRD (or create manually)
claude /review-issues --issue 42

# 2. Review the PRD
cat ~/Projects/my-app/prd.json

# 3. Run Ralph
./ralph.sh ~/Projects/my-app 20

# 4. Check status
./ralph.sh status ~/Projects/my-app

# 5. Review and merge PRs
claude /review-prs --auto-merge
```

### Skills Available (v2.1.0)

**Core:** `/prd`, `/review-issues`, `/review-prs`
**Quality:** `/qa-audit`, `/test-coverage`, `/a11y-audit`, `/perf-audit`
**Security:** `/security-audit`
**Maintenance:** `/deps-update`, `/refactor`, `/migrate`
**Docs:** `/docs-gen`, `/onboard`

### ralph-wiggum workflow

```bash
# 1. Start loop with prompt and completion condition
claude /ralph-wiggum:ralph-loop "
  Refactor the authentication module to use JWT.
  Update all tests. Keep going until everything passes.
" --max-iterations 30 --completion-promise "REFACTOR_COMPLETE"

# 2. Wait for completion or max iterations

# 3. Review changes manually
git diff
```

## Combining Both

You can use both systems together:

1. **ralph-wiggum for discovery** → Explore codebase, identify what needs to change
2. **ralph-cc-loop for implementation** → Execute discrete stories with tracking

Or:

1. **ralph-cc-loop for main work** → Implement features with PRD
2. **ralph-wiggum for cleanup** → "Polish everything until it's perfect"
