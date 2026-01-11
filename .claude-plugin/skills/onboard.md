# /onboard

---
description: Generate project overview, architecture docs, and getting-started guide for new developers
arguments:
  - name: project_path
    description: Path to the project to document
    required: true
---

You are a developer experience expert. Your task is to analyze a codebase and generate comprehensive onboarding documentation that helps new developers understand and contribute to the project quickly.

## Phase 1: Project Analysis

### Step 1.1: Gather Project Metadata

```bash
# Basic project info
cat package.json | jq '{name, description, version, scripts}'

# Tech stack from dependencies
cat package.json | jq '.dependencies | keys[]' | head -30

# Dev dependencies
cat package.json | jq '.devDependencies | keys[]' | head -20
```

### Step 1.2: Analyze Project Structure

```bash
# Directory structure
find . -type d -not -path '*/node_modules/*' -not -path '*/.git/*' | head -50

# Key file types
find src -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn

# Entry points
ls src/index.* src/main.* src/app.* 2>/dev/null
```

### Step 1.3: Identify Key Components

```bash
# Find main modules
ls -la src/*/

# Find API routes
find src -name "*.route*" -o -name "router*" -o -name "*Controller*" | head -20

# Find models/schemas
find src -name "*model*" -o -name "*schema*" -o -name "*entity*" | head -20

# Find services
find src -name "*service*" -o -name "*Service*" | head -20
```

### Step 1.4: Analyze Configuration

```bash
# Environment files
ls .env* *.env 2>/dev/null

# Config files
ls config/ src/config/ *.config.* 2>/dev/null

# CI/CD
ls .github/workflows/* .gitlab-ci.yml Jenkinsfile 2>/dev/null
```

### Step 1.5: Check Existing Documentation

```bash
# Documentation files
ls README.md CONTRIBUTING.md docs/ wiki/ 2>/dev/null

# Inline documentation
grep -r "@module\|@description\|@summary" src/ | head -10
```

## Phase 2: Generate PRD

```json
{
  "project": "{project_name}",
  "mode": "feature",
  "branchName": "ralph/onboarding-docs",
  "baseBranch": "main",
  "description": "Generate onboarding documentation for new developers",
  "userStories": []
}
```

### Story Templates

#### Category 1: Quick Start Guide (Priority 1)

```json
{
  "id": "ONBOARD-START-001",
  "title": "Create quick start guide",
  "description": "Generate a 5-minute getting started guide",
  "acceptanceCriteria": [
    "IDENTIFY: Prerequisites (Node version, required tools)",
    "IDENTIFY: Environment setup steps from .env.example",
    "IDENTIFY: Required services (database, redis, etc)",
    "IDENTIFY: Development scripts from package.json",
    "FIX: Create docs/QUICK_START.md",
    "FIX: Document prerequisites with installation commands",
    "FIX: Write step-by-step setup instructions",
    "FIX: Add troubleshooting for common setup issues",
    "FIX: Include 'verify it works' step",
    "VERIFY: A new dev can set up in < 15 minutes",
    "VERIFY: All commands are copy-pasteable",
    "VERIFY: No assumed knowledge"
  ],
  "files": ["docs/QUICK_START.md"],
  "dependsOn": [],
  "priority": 1,
  "passes": false,
  "category": "quickstart"
}
```

#### Category 2: Architecture Overview (Priority 2)

```json
{
  "id": "ONBOARD-ARCH-001",
  "title": "Create architecture overview",
  "description": "Document the high-level system architecture",
  "acceptanceCriteria": [
    "IDENTIFY: Main application layers (API, service, data)",
    "IDENTIFY: External service dependencies",
    "IDENTIFY: Data flow through the system",
    "IDENTIFY: Key design patterns used",
    "FIX: Create docs/ARCHITECTURE.md",
    "FIX: Draw ASCII/Mermaid system diagram",
    "FIX: Document each layer's responsibility",
    "FIX: Explain data flow with diagram",
    "FIX: List external integrations",
    "FIX: Document key design decisions",
    "VERIFY: Architecture is understandable without code",
    "VERIFY: Diagrams render correctly"
  ],
  "files": ["docs/ARCHITECTURE.md"],
  "dependsOn": ["ONBOARD-START-001"],
  "priority": 2,
  "passes": false,
  "category": "architecture"
}
```

#### Category 3: Directory Structure Guide (Priority 3)

```json
{
  "id": "ONBOARD-DIR-001",
  "title": "Document directory structure",
  "description": "Explain what each directory contains and why",
  "acceptanceCriteria": [
    "IDENTIFY: List all top-level directories",
    "IDENTIFY: Purpose of each directory",
    "IDENTIFY: File naming conventions",
    "FIX: Create docs/DIRECTORY_STRUCTURE.md",
    "FIX: Document each directory with purpose",
    "FIX: Explain file organization within directories",
    "FIX: Document naming conventions",
    "FIX: Provide examples of where to add new files",
    "VERIFY: Developer knows where to find things",
    "VERIFY: Developer knows where to add new code"
  ],
  "files": ["docs/DIRECTORY_STRUCTURE.md"],
  "dependsOn": ["ONBOARD-ARCH-001"],
  "priority": 3,
  "passes": false,
  "category": "structure"
}
```

#### Category 4: Development Workflow (Priority 4)

```json
{
  "id": "ONBOARD-WORKFLOW-001",
  "title": "Document development workflow",
  "description": "Explain how to develop, test, and submit changes",
  "acceptanceCriteria": [
    "IDENTIFY: Git branching strategy",
    "IDENTIFY: Testing requirements",
    "IDENTIFY: Code review process",
    "IDENTIFY: CI/CD pipeline stages",
    "FIX: Create docs/DEVELOPMENT_WORKFLOW.md",
    "FIX: Document branching strategy with examples",
    "FIX: Explain how to run tests locally",
    "FIX: Document PR template and requirements",
    "FIX: Explain CI/CD pipeline",
    "FIX: Add common workflow examples",
    "VERIFY: Developer can confidently submit a PR"
  ],
  "files": ["docs/DEVELOPMENT_WORKFLOW.md"],
  "dependsOn": ["ONBOARD-DIR-001"],
  "priority": 4,
  "passes": false,
  "category": "workflow"
}
```

#### Category 5: Key Concepts Glossary (Priority 5)

```json
{
  "id": "ONBOARD-GLOSSARY-001",
  "title": "Create domain glossary",
  "description": "Define domain terms and concepts used in code",
  "acceptanceCriteria": [
    "IDENTIFY: Domain-specific terms in code",
    "IDENTIFY: Abbreviations and acronyms",
    "IDENTIFY: Key business concepts",
    "IDENTIFY: Technical terms specific to project",
    "FIX: Create docs/GLOSSARY.md",
    "FIX: Define each term clearly",
    "FIX: Include code examples where helpful",
    "FIX: Link terms to relevant code/docs",
    "VERIFY: No jargon left unexplained",
    "VERIFY: New developer understands domain language"
  ],
  "files": ["docs/GLOSSARY.md"],
  "dependsOn": ["ONBOARD-WORKFLOW-001"],
  "priority": 5,
  "passes": false,
  "category": "glossary"
}
```

#### Category 6: Code Patterns Guide (Priority 6)

```json
{
  "id": "ONBOARD-PATTERNS-001",
  "title": "Document code patterns and conventions",
  "description": "Explain how to write code that fits the codebase",
  "acceptanceCriteria": [
    "IDENTIFY: Common patterns used in codebase",
    "IDENTIFY: Error handling conventions",
    "IDENTIFY: Testing patterns",
    "IDENTIFY: Naming conventions",
    "FIX: Create docs/CODE_PATTERNS.md",
    "FIX: Document each pattern with example",
    "FIX: Explain when to use each pattern",
    "FIX: Show anti-patterns to avoid",
    "FIX: Include snippets that can be copied",
    "VERIFY: New code will be consistent"
  ],
  "files": ["docs/CODE_PATTERNS.md"],
  "dependsOn": ["ONBOARD-GLOSSARY-001"],
  "priority": 6,
  "passes": false,
  "category": "patterns"
}
```

#### Category 7: Common Tasks Guide (Priority 7)

```json
{
  "id": "ONBOARD-TASKS-001",
  "title": "Create common tasks guide",
  "description": "Document how to do frequent development tasks",
  "acceptanceCriteria": [
    "IDENTIFY: Most common development tasks",
    "IDENTIFY: Database operations (migrations, seeds)",
    "IDENTIFY: Testing workflows",
    "IDENTIFY: Debugging approaches",
    "FIX: Create docs/COMMON_TASKS.md",
    "FIX: Document: 'How to add a new API endpoint'",
    "FIX: Document: 'How to add a new database table'",
    "FIX: Document: 'How to add a new feature flag'",
    "FIX: Document: 'How to debug common issues'",
    "FIX: Document: 'How to run specific tests'",
    "VERIFY: Tasks are step-by-step",
    "VERIFY: Commands are copy-pasteable"
  ],
  "files": ["docs/COMMON_TASKS.md"],
  "dependsOn": ["ONBOARD-PATTERNS-001"],
  "priority": 7,
  "passes": false,
  "category": "tasks"
}
```

#### Category 8: Environment Guide (Priority 8)

```json
{
  "id": "ONBOARD-ENV-001",
  "title": "Document environment configuration",
  "description": "Explain all environment variables and config",
  "acceptanceCriteria": [
    "IDENTIFY: All environment variables from code",
    "IDENTIFY: Required vs optional variables",
    "IDENTIFY: Different environments (dev, staging, prod)",
    "FIX: Create docs/ENVIRONMENT.md",
    "FIX: Document each env var with description",
    "FIX: Mark required variables clearly",
    "FIX: Provide example values (not secrets)",
    "FIX: Explain how to get credentials for services",
    "FIX: Document environment differences",
    "VERIFY: Developer can configure all environments"
  ],
  "files": ["docs/ENVIRONMENT.md", ".env.example"],
  "dependsOn": ["ONBOARD-TASKS-001"],
  "priority": 8,
  "passes": false,
  "category": "environment"
}
```

#### Category 9: Troubleshooting Guide (Priority 9)

```json
{
  "id": "ONBOARD-TROUBLE-001",
  "title": "Create troubleshooting guide",
  "description": "Document common problems and solutions",
  "acceptanceCriteria": [
    "IDENTIFY: Common setup issues",
    "IDENTIFY: Common runtime errors",
    "IDENTIFY: Common debugging scenarios",
    "FIX: Create docs/TROUBLESHOOTING.md",
    "FIX: Document: 'Installation problems'",
    "FIX: Document: 'Database connection issues'",
    "FIX: Document: 'Test failures'",
    "FIX: Document: 'Build errors'",
    "FIX: Add solutions for each problem",
    "VERIFY: Common problems have solutions"
  ],
  "files": ["docs/TROUBLESHOOTING.md"],
  "dependsOn": ["ONBOARD-ENV-001"],
  "priority": 9,
  "passes": false,
  "category": "troubleshooting"
}
```

#### Category 10: Documentation Index (Priority 10)

```json
{
  "id": "ONBOARD-INDEX-001",
  "title": "Create documentation index",
  "description": "Create navigation for all documentation",
  "acceptanceCriteria": [
    "FIX: Create docs/README.md as index",
    "FIX: Link all documentation files",
    "FIX: Organize by audience (new dev, contributor, maintainer)",
    "FIX: Add suggested reading order",
    "FIX: Update main README to link to docs/",
    "VERIFY: All docs are discoverable",
    "VERIFY: No broken links",
    "VERIFY: Clear navigation structure"
  ],
  "files": ["docs/README.md", "README.md"],
  "dependsOn": ["ONBOARD-TROUBLE-001"],
  "priority": 10,
  "passes": false,
  "category": "index"
}
```

## Phase 3: Documentation Templates

### Quick Start Template
```markdown
# Quick Start Guide

Get up and running in 5 minutes.

## Prerequisites

- Node.js >= 18 (`node --version`)
- PostgreSQL >= 14 (`psql --version`)
- Git (`git --version`)

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/org/repo.git
   cd repo
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your values
   ```

4. **Set up database**
   ```bash
   npm run db:create
   npm run db:migrate
   npm run db:seed  # Optional: add sample data
   ```

5. **Start development server**
   ```bash
   npm run dev
   ```

6. **Verify it works**
   - Open http://localhost:3000
   - You should see [expected result]

## Common Issues

### Port already in use
```bash
lsof -i :3000  # Find process
kill -9 <PID>  # Kill it
```

### Database connection failed
- Ensure PostgreSQL is running
- Check DATABASE_URL in .env

## Next Steps

- Read [Architecture Overview](./ARCHITECTURE.md)
- Review [Development Workflow](./DEVELOPMENT_WORKFLOW.md)
```

### Architecture Template
```markdown
# Architecture Overview

## System Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Client    │────▶│   API       │────▶│  Database   │
│  (React)    │     │  (Express)  │     │ (PostgreSQL)│
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Redis     │
                    │  (Cache)    │
                    └─────────────┘
```

## Layers

### API Layer (`/src/api`)
Handles HTTP requests, validation, authentication.

### Service Layer (`/src/services`)
Contains business logic, orchestrates data access.

### Data Layer (`/src/models`)
Database models and queries.

## Key Design Decisions

### Why Express over Fastify?
[Explanation]

### Why PostgreSQL?
[Explanation]

## External Services

| Service | Purpose | Environment Variable |
|---------|---------|---------------------|
| Stripe | Payments | `STRIPE_API_KEY` |
| SendGrid | Email | `SENDGRID_API_KEY` |
```

## Phase 4: Output

Generate `prd.json` with stories ordered by:
1. Quick start (first thing new devs need)
2. Architecture (understand the system)
3. Directory structure (navigate the code)
4. Development workflow (contribute code)
5. Glossary (understand the domain)
6. Code patterns (write consistent code)
7. Common tasks (do frequent things)
8. Environment (configure correctly)
9. Troubleshooting (solve problems)
10. Index (find everything)

The goal is to reduce time-to-first-PR for new developers from days to hours.
