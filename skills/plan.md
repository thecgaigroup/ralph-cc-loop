---
name: plan
description: Generate a prd.json from GitHub issues by scanning the codebase to understand what needs to change. Use when asked to "plan work", "create prd", "plan from issues", "build stories", or "import issues for ralph".
arguments: "[--repo owner/repo] [--label label] [--milestone milestone] [--issue 13,14,15] [--mode feature|backlog]"
---

# Plan

Generate `prd.json` files for Ralph by pulling GitHub issues and understanding the codebase.

## Your Task

1. **Parse arguments** to determine which issues to pull:
   - `--repo owner/repo` - Target repository (auto-detected if in a git repo)
   - `--label label` - Filter by label (can be repeated)
   - `--milestone milestone` - Filter by milestone
   - `--issue 13,14,15` - Pull specific issues (comma-separated)
   - `--mode feature|backlog` - PRD mode (default: feature)

2. **Detect the repository** if `--repo` not specified:
   ```bash
   # Auto-detect from git remote
   gh repo view --json nameWithOwner -q .nameWithOwner
   # Returns: owner/repo
   ```
   If auto-detection fails and no `--repo` specified, ask the user.

3. **Fetch issues** using the `gh` CLI:
   ```bash
   # Multiple specific issues:
   gh issue view 13 --repo owner/repo --json number,title,body,labels,state
   gh issue view 14 --repo owner/repo --json number,title,body,labels,state

   # By label:
   gh issue list --repo owner/repo --label "bug" --json number,title,body,labels,state --limit 50

   # By milestone:
   gh issue list --repo owner/repo --milestone "v2.0" --json number,title,body,labels,state --limit 50

   # All open issues:
   gh issue list --repo owner/repo --json number,title,body,labels,state --limit 50
   ```

3. **For each issue**, understand what it's asking:
   - Read the issue title and body carefully
   - Identify what feature/fix is being requested
   - Note any acceptance criteria or requirements mentioned

4. **Scan the codebase** to understand the context:
   - Use the Explore agent or search tools to find relevant code
   - Identify the files that would need to change
   - Understand existing patterns and architecture
   - Look for related components, APIs, utilities

5. **Generate right-sized stories**:
   - Break large issues into multiple stories if needed
   - Each story must be completable in one Claude context window
   - Include specific file references from your codebase scan
   - Write concrete acceptance criteria based on actual code

6. **Create the PRD** with:
   - `githubIssue` field linking each story to its source issue
   - `files` field listing relevant files discovered during scan
   - Proper dependencies between stories
   - Branch name based on issue(s)

## Story Sizing Guidelines

**Right-sized (one story):**
- Fix a specific bug in a known file
- Add a field to an existing form
- Update error handling in one component
- Add a new API endpoint

**Too large (split into multiple stories):**
- "Dashboard is slow" → separate stories for caching, lazy loading, query optimization
- "Add authentication" → separate stories for login UI, session management, protected routes
- "Music not playing" → separate stories for URL handling, error states, audio loading

## PRD Format

### Feature Mode (default)
For implementing a cohesive feature - single branch, one PR at end:

```json
{
  "project": "Audio playback and upload fixes",
  "mode": "feature",
  "branchName": "ralph/fix-audio-issues",
  "baseBranch": "main",
  "description": "Fix audio playback and file upload issues",
  "githubRepo": "owner/repo",
  "githubIssues": [13, 14],
  "userStories": [
    {
      "id": "GH-13-1",
      "githubIssue": 13,
      "title": "Handle S3 URLs in audio player",
      "files": ["apps/web/src/lib/url-utils.ts"],
      "priority": 1,
      "passes": false
    }
  ]
}
```

### Backlog Mode
For independent tasks - branch per story/issue, PR after each:

```json
{
  "project": "Bug Backlog",
  "mode": "backlog",
  "baseBranch": "main",
  "description": "Various bug fixes from GitHub issues",
  "githubRepo": "owner/repo",
  "githubIssues": [13, 14, 15],
  "userStories": [
    {
      "id": "GH-13-1",
      "githubIssue": 13,
      "title": "Fix audio playback",
      "files": ["apps/web/src/lib/url-utils.ts"],
      "priority": 1,
      "passes": false
    },
    {
      "id": "GH-14-1",
      "githubIssue": 14,
      "title": "Fix file upload validation",
      "files": ["apps/web/src/components/Upload.tsx"],
      "priority": 2,
      "passes": false
    }
  ]
}
```

**Key fields:**
- `mode`: `"feature"` (default) or `"backlog"`
- `baseBranch`: Branch to create feature branches from (default: `main`)
- `branchName`: Used in feature mode only
- `githubIssues`: Array of all issue numbers (for PR summary)
- `githubIssue` (per story): Which issue this story addresses

## Workflow

1. Fetch all requested issues
2. Read and understand each issue
3. Explore the codebase to find relevant files for ALL issues
4. Look for relationships between issues (shared files, dependencies)
5. **Determine mode** (if not specified):
   - **Feature mode**: Issues are related, share files, or build on each other
   - **Backlog mode**: Issues are independent, unrelated bugs/tasks
   - Ask user if unclear
6. Break down into properly-sized stories
7. Order stories considering cross-issue dependencies
8. Ask clarifying questions if requirements are ambiguous
9. Generate and save prd.json
10. Show summary to user

## Branch Naming for Multiple Issues

- Single issue: `ralph/fix-issue-13` or `ralph/audio-playback`
- Multiple related issues: `ralph/audio-fixes` or `ralph/v2-bugs`
- Milestone: `ralph/milestone-v2`

## PR Output

When Ralph completes all stories, it creates a PR like:

```markdown
## Summary
Fix audio playback and file upload issues

## Changes
- GH-13-1: Handle S3 URLs in audio player
- GH-13-2: Add error handling to AudioPlayer
- GH-14-1: Fix file upload validation

## GitHub Issues
Closes #13
Closes #14
```

## Important

- Always scan the codebase - don't guess at file locations
- Include file paths discovered during exploration
- Ask the user if an issue is too vague to implement
- Link stories back to their GitHub issues for traceability
- Group related issues into a single PRD when they touch similar code
- Keep unrelated issues in separate PRDs for cleaner PRs
