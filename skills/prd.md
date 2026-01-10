---
name: prd
description: Generate a prd.json file for Ralph by interactively breaking down a feature into right-sized user stories. Use when asked to "create a prd", "generate prd.json", "break down this feature", or "plan user stories for ralph".
arguments: "[feature description]"
---

# PRD Generator for Ralph

You are helping the user create a `prd.json` file for use with Ralph, an autonomous AI agent loop that implements user stories iteratively.

## Your Task

Guide the user through creating a well-structured PRD with right-sized user stories.

## Step 1: Gather Context

If the user provided a feature description in arguments, use that. Otherwise, ask:

1. **What feature or project are you building?** (brief description)
2. **What's the target project directory?** (to save prd.json there)

## Step 2: Understand the Scope

Ask clarifying questions to understand the full scope:

- What are the main components? (database, API, UI, etc.)
- Are there dependencies on existing code?
- Any specific tech stack considerations?

Read relevant files in the project if needed to understand existing patterns.

## Step 3: Break Down into Stories

Create user stories following these principles:

### Right-Sized Stories (Critical!)

Each story must be completable in ONE Claude context window. This means:

**Good story size:**
- Add a database column/table with migration
- Create a single UI component
- Add one API endpoint
- Update one form with new fields
- Add a filter or sort feature

**Too big (split these):**
- "Build the dashboard" → split into individual widgets/sections
- "Add authentication" → split into: schema, login UI, session handling, protected routes
- "Create admin panel" → split into: layout, user list, user edit, permissions

### Story Format

```json
{
  "id": "US-001",
  "title": "Short descriptive title",
  "description": "As a [user], I want [feature] so that [benefit]",
  "acceptanceCriteria": [
    "Specific testable criterion 1",
    "Specific testable criterion 2",
    "Typecheck/lint passes",
    "Tests pass (if applicable)"
  ],
  "priority": 1,
  "passes": false,
  "notes": ""
}
```

### Priority Order

Stories should be ordered by dependency:
1. Database/schema changes first
2. API/backend that uses the schema
3. UI that uses the API
4. Polish/enhancement features last

## Step 4: Generate the PRD

Create the complete prd.json:

```json
{
  "project": "Project Name",
  "branchName": "ralph/feature-name",
  "description": "Brief description of what this PRD accomplishes",
  "plugins": {
    "recommended": ["security-guidance", "commit-commands"],
    "optional": ["frontend-design", "typescript-lsp"]
  },
  "userStories": [
    // ... stories here
  ]
}
```

### Branch Naming

Use `ralph/` prefix followed by kebab-case feature name:
- `ralph/user-auth`
- `ralph/task-priorities`
- `ralph/dashboard-widgets`

## Step 5: Review with User

Before saving, show the user:
1. Total number of stories
2. The story breakdown (id, title, priority)
3. Ask if any stories need to be split further or combined

## Step 6: Save the File

Write the prd.json to the target project directory.

Confirm:
```
Created prd.json with X user stories.

To run Ralph:
  ./ralph.sh /path/to/project

Stories:
  1. US-001: [title]
  2. US-002: [title]
  ...
```

## Guidelines

- **Be conservative with scope** - it's better to have more small stories than fewer large ones
- **Include quality checks** in acceptance criteria (typecheck, lint, test)
- **Add browser verification** for any UI stories
- **Ask about existing patterns** - read CLAUDE.md or existing code to match conventions
- **Don't assume** - ask clarifying questions rather than guessing requirements
