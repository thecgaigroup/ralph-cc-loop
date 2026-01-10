# Ralph for Claude Code CLI

An autonomous AI agent loop that runs Claude Code CLI repeatedly until all PRD items are complete.

This is a fork of [Ralph](https://github.com/snarktank/ralph) adapted for **Claude Code CLI** instead of Amp.

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- `jq` installed (`brew install jq` on macOS)
- A git repository for your project
- Claude Code Max subscription ($200/month) recommended for heavy usage

## Setup

### Option 1: Keep Ralph in one place (recommended)

Keep ralph.sh and prompt.md in a dedicated folder. Only create `prd.json` in each project.

```bash
# Clone or keep Ralph somewhere permanent
git clone https://github.com/thecgaigroup/ralph-cc-loop ~/tools/ralph-cc-loop

# Optional: add alias to your shell config
alias ralph="~/tools/ralph-cc-loop/ralph.sh"
```

Then run against any project:
```bash
~/tools/ralph-cc-loop/ralph.sh ~/Projects/my-app
# or with alias:
ralph ~/Projects/my-app
```

### Option 2: Copy to your project

If you prefer self-contained projects:

```bash
cp ralph.sh prompt.md prd.json.example /path/to/your/project/
cd /path/to/your/project
./ralph.sh
```

## Workflow

### 1. Create a PRD

Create a `prd.json` file in your project root. See `prd.json.example` for the format:

```json
{
  "project": "My Project",
  "branchName": "ralph/feature-name",
  "description": "Description of what we're building",
  "userStories": [
    {
      "id": "US-001",
      "title": "First task",
      "description": "What to implement",
      "acceptanceCriteria": [
        "Criteria 1",
        "Criteria 2",
        "Tests pass"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-002",
      "title": "Second task (depends on first)",
      "description": "What to implement",
      "dependsOn": ["US-001"],
      "acceptanceCriteria": ["..."],
      "priority": 2,
      "passes": false,
      "notes": ""
    }
  ]
}
```

### Story Dependencies

Use the optional `dependsOn` field to ensure stories execute in the correct order:

```json
{
  "id": "US-003",
  "dependsOn": ["US-001", "US-002"],
  ...
}
```

- Stories with unmet dependencies are skipped until their dependencies pass
- Dependencies are specified as an array of story IDs
- Use dependencies when a story requires code/schema from another story

### 2. Run Ralph

```bash
# From Ralph's directory, targeting a project
./ralph.sh ~/Projects/my-app          # 10 iterations (default)
./ralph.sh ~/Projects/my-app 20       # 20 iterations

# Or from within your project (if ralph.sh is copied there)
./ralph.sh                            # Current directory, 10 iterations
./ralph.sh 20                         # Current directory, 20 iterations
```

Ralph will:
1. Create a feature branch (from PRD `branchName`)
2. Pick the next eligible story (highest priority where `passes: false` and all `dependsOn` stories have passed)
3. Implement that single story
4. Run quality checks (typecheck, tests)
5. Commit if checks pass
6. Update `prd.json` to mark story as `passes: true`
7. Append learnings to `progress.txt`
8. Repeat until all stories pass or max iterations reached

## Monitoring Progress

Ralph provides multiple ways to monitor long-running iterations:

### Real-time Output Log

Ralph streams all Claude output to `ralph-output.log` in your project directory. Monitor it in a separate terminal:

```bash
# Follow the full output stream in real-time
tail -f ~/Projects/my-app/ralph-output.log

# Or with colored output
tail -f ~/Projects/my-app/ralph-output.log | less -R +F
```

### Progress Summary

The `progress.txt` file contains high-level learnings and status from each iteration:

```bash
# Watch progress summary
tail -f ~/Projects/my-app/progress.txt

# Or use watch for periodic updates
watch -n 5 cat ~/Projects/my-app/progress.txt
```

### Terminal Controls

While Ralph is running in the foreground:

| Key | Action |
|-----|--------|
| `Ctrl+B` | Background the task and continue using Claude Code |
| `Ctrl+C` | Interrupt the current iteration |
| `Ctrl+O` | Toggle verbose output mode |
| Enter/Scroll | Expand collapsed output lines |

### Check PRD Status

```bash
# See which stories are complete
cat ~/Projects/my-app/prd.json | jq '.userStories[] | {id, title, passes}'
```

## Key Files

| File | Purpose |
|------|---------|
| `ralph.sh` | The bash loop that spawns fresh Claude Code instances |
| `prompt.md` | Instructions given to each Claude Code instance |
| `prd.json` | User stories with `passes` status (the task list) |
| `prd.json.example` | Example PRD format for reference |
| `progress.txt` | Append-only learnings for future iterations |
| `ralph-output.log` | Full Claude output from all iterations |

## Differences from Amp Version

| Feature | Amp Version | Claude Code Version |
|---------|-------------|---------------------|
| CLI command | `amp --dangerously-allow-all` | `claude --print --dangerously-skip-permissions` |
| Thread references | Uses `$AMP_CURRENT_THREAD_ID` | Not available |
| Browser tool | `dev-browser` skill | `mcp__puppeteer` or Browser tool |
| Config files | `AGENTS.md` | `CLAUDE.md` or `AGENTS.md` |

## Critical Concepts

### Each Iteration = Fresh Context

Each iteration spawns a **new Claude Code instance** with clean context. The only memory between iterations is:

- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)

### Small Tasks

Each PRD item should be small enough to complete in one context window. If a task is too big, Claude runs out of context before finishing.

**Right-sized stories:**
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic

**Too big (split these):**
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### CLAUDE.md Updates Are Critical

After each iteration, Ralph updates the relevant `CLAUDE.md` files with learnings. This is key because Claude Code automatically reads these files, so future iterations benefit from discovered patterns, gotchas, and conventions.

## Debugging

See [Monitoring Progress](#monitoring-progress) for real-time monitoring options.

```bash
# Check git history
git log --oneline -10

# See full Claude output from all iterations
less ralph-output.log

# Search for errors in output
grep -i "error\|failed\|exception" ralph-output.log
```

## Customizing prompt.md

Edit `prompt.md` to customize Ralph's behavior for your project:

- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

## Plugin Integration

Ralph can leverage official Claude Code plugins for enhanced capabilities. Add a `plugins` section to your `prd.json`:

```json
{
  "plugins": {
    "recommended": ["security-guidance", "commit-commands"],
    "optional": ["code-simplifier", "frontend-design", "pr-review-toolkit"]
  }
}
```

### Recommended Plugins

| Plugin | Purpose | Install |
|--------|---------|---------|
| `security-guidance` | Passive security warnings | Auto-installed |
| `commit-commands` | Better commit messages | Auto-installed |
| `code-simplifier` | Reduce code complexity | `claude plugins install code-simplifier` |
| `frontend-design` | Production-grade UI code | `claude plugins install frontend-design` |
| `pr-review-toolkit` | Multi-aspect code review | `claude plugins install pr-review-toolkit` |
| `typescript-lsp` | TypeScript intelligence | `claude plugins install typescript-lsp` |
| `pyright-lsp` | Python type checking | `claude plugins install pyright-lsp` |

### How Plugins Are Used

- **security-guidance**: Passively monitors edits for vulnerabilities
- **commit-commands**: `/commit` generates style-matching commit messages
- **code-simplifier**: `/code-simplifier:simplify` refactors complex files
- **pr-review-toolkit**: `/pr-review-toolkit:code-reviewer` validates before completion
- **frontend-design**: Automatically enhances UI/frontend code quality

If a plugin is listed but not installed, Ralph skips it gracefully.

## License

MIT
