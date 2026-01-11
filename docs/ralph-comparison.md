# Ralph Comparison: ralph-cc-loop vs ralph-wiggum

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
