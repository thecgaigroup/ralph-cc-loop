# /docs-gen

---
description: Generate and update project documentation including README, API docs, and architecture diagrams
arguments:
  - name: project_path
    description: Path to the project to document
    required: true
---

You are a technical documentation expert. Your task is to analyze a project and generate comprehensive, accurate documentation that stays in sync with the code.

## Phase 1: Project Analysis

### Step 1.1: Identify Documentation Needs

Scan the project structure:

```bash
# Check existing documentation
ls -la README.md CONTRIBUTING.md CHANGELOG.md docs/ 2>/dev/null

# Check for doc generation tools
cat package.json | jq '.devDependencies | keys[]' | grep -E 'typedoc|jsdoc|swagger|openapi'
ls docs/ .storybook/ 2>/dev/null

# Identify code structure
find src -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) | head -20
```

### Step 1.2: Analyze Existing Documentation

Assess current state:
- README.md completeness and accuracy
- API documentation coverage
- Inline code comments quality
- Architecture documentation
- Setup/installation guides

### Step 1.3: Extract Documentation Sources

Gather information from:
- package.json / pyproject.toml (name, description, scripts)
- Source code comments and JSDoc/docstrings
- Type definitions
- Config files
- Environment variables
- API routes and handlers
- Database schemas

## Phase 2: Generate PRD

```json
{
  "project": "{project_name}",
  "mode": "feature",
  "branchName": "ralph/documentation",
  "baseBranch": "main",
  "description": "Generate and update project documentation",
  "userStories": []
}
```

### Story Templates

#### Category 1: README (Priority 1)

```json
{
  "id": "DOCS-README-001",
  "title": "Create/update comprehensive README",
  "description": "Ensure README accurately represents the project",
  "acceptanceCriteria": [
    "IDENTIFY: Extract project name, description from package.json/config",
    "IDENTIFY: List all npm scripts and their purposes",
    "IDENTIFY: Map required environment variables from code",
    "IDENTIFY: Find prerequisites (Node version, dependencies)",
    "FIX: Write/update project title and description",
    "FIX: Add badges (build status, coverage, version, license)",
    "FIX: Write clear installation instructions",
    "FIX: Document all environment variables with descriptions",
    "FIX: Document available npm scripts",
    "FIX: Add usage examples with code snippets",
    "FIX: Add project structure overview",
    "FIX: Add contributing section or link",
    "FIX: Add license section",
    "VERIFY: All code examples are valid and tested",
    "VERIFY: Installation steps work on clean environment",
    "DOCUMENT: README follows standard template"
  ],
  "files": ["README.md", "package.json"],
  "dependsOn": [],
  "priority": 1,
  "passes": false,
  "category": "readme"
}
```

#### Category 2: API Documentation (Priority 2)

```json
{
  "id": "DOCS-API-001",
  "title": "Generate API documentation",
  "description": "Document all API endpoints with request/response schemas",
  "acceptanceCriteria": [
    "IDENTIFY: List all API routes from router files",
    "IDENTIFY: Extract request parameters, body schemas, response types",
    "IDENTIFY: Find authentication requirements per endpoint",
    "FIX: Create docs/api/ directory if needed",
    "FIX: Generate OpenAPI/Swagger spec if applicable",
    "FIX: Document each endpoint with: method, path, description",
    "FIX: Document request parameters and body format",
    "FIX: Document response format and status codes",
    "FIX: Add authentication requirements",
    "FIX: Include example requests/responses",
    "FIX: Add error response documentation",
    "VERIFY: API docs match actual implementation",
    "VERIFY: Examples are valid JSON/curl commands"
  ],
  "files": ["docs/api/", "openapi.yaml"],
  "dependsOn": ["DOCS-README-001"],
  "priority": 2,
  "passes": false,
  "category": "api-docs"
}
```

#### Category 3: Architecture Documentation (Priority 3)

```json
{
  "id": "DOCS-ARCH-001",
  "title": "Create architecture documentation",
  "description": "Document system architecture and design decisions",
  "acceptanceCriteria": [
    "IDENTIFY: Map major components and their responsibilities",
    "IDENTIFY: Identify external service dependencies",
    "IDENTIFY: Map data flow between components",
    "FIX: Create docs/architecture/ directory",
    "FIX: Write high-level system overview",
    "FIX: Document component responsibilities",
    "FIX: Create ASCII/Mermaid diagrams for data flow",
    "FIX: Document database schema and relationships",
    "FIX: Document external integrations",
    "FIX: Add ADRs (Architecture Decision Records) for key decisions",
    "VERIFY: Diagrams accurately reflect code structure",
    "VERIFY: All major components are documented"
  ],
  "files": ["docs/architecture/"],
  "dependsOn": ["DOCS-API-001"],
  "priority": 3,
  "passes": false,
  "category": "architecture"
}
```

#### Category 4: Code Documentation (Priority 4)

```json
{
  "id": "DOCS-CODE-001",
  "title": "Add/improve inline code documentation",
  "description": "Add JSDoc/docstrings to public APIs",
  "acceptanceCriteria": [
    "IDENTIFY: Find exported functions/classes without documentation",
    "IDENTIFY: Find complex functions that need explanation",
    "FIX: Add JSDoc/docstring to all exported functions",
    "FIX: Document function parameters with types and descriptions",
    "FIX: Document return values",
    "FIX: Add @example tags for complex functions",
    "FIX: Add @throws documentation for functions that throw",
    "FIX: Document class properties and methods",
    "VERIFY: Documentation is accurate and helpful",
    "VERIFY: No documentation for trivial/obvious code"
  ],
  "files": ["src/"],
  "dependsOn": ["DOCS-ARCH-001"],
  "priority": 4,
  "passes": false,
  "category": "code-docs"
}
```

#### Category 5: Setup/Development Guide (Priority 5)

```json
{
  "id": "DOCS-DEV-001",
  "title": "Create development setup guide",
  "description": "Document how to set up and run the project locally",
  "acceptanceCriteria": [
    "IDENTIFY: List all development prerequisites",
    "IDENTIFY: Map local setup steps from codebase analysis",
    "IDENTIFY: Find required local services (database, redis, etc)",
    "FIX: Create docs/development.md or CONTRIBUTING.md",
    "FIX: Document prerequisites with version requirements",
    "FIX: Write step-by-step setup instructions",
    "FIX: Document how to run database migrations/seeds",
    "FIX: Document how to run tests locally",
    "FIX: Add troubleshooting section for common issues",
    "FIX: Document IDE setup recommendations",
    "VERIFY: Setup steps work from scratch",
    "VERIFY: All environment variables documented"
  ],
  "files": ["docs/development.md", "CONTRIBUTING.md"],
  "dependsOn": ["DOCS-CODE-001"],
  "priority": 5,
  "passes": false,
  "category": "dev-guide"
}
```

#### Category 6: Deployment Documentation (Priority 6)

```json
{
  "id": "DOCS-DEPLOY-001",
  "title": "Create deployment documentation",
  "description": "Document deployment process and configuration",
  "acceptanceCriteria": [
    "IDENTIFY: Analyze CI/CD configuration files",
    "IDENTIFY: Map production environment requirements",
    "IDENTIFY: Find deployment scripts and commands",
    "FIX: Create docs/deployment.md",
    "FIX: Document deployment environments (staging, prod)",
    "FIX: Document CI/CD pipeline stages",
    "FIX: Document required infrastructure/services",
    "FIX: Document environment variables for each environment",
    "FIX: Add deployment checklist",
    "FIX: Document rollback procedures",
    "VERIFY: Deployment docs match actual process"
  ],
  "files": ["docs/deployment.md"],
  "dependsOn": ["DOCS-DEV-001"],
  "priority": 6,
  "passes": false,
  "category": "deployment"
}
```

#### Category 7: Changelog (Priority 7)

```json
{
  "id": "DOCS-CHANGE-001",
  "title": "Create/update CHANGELOG",
  "description": "Document version history and changes",
  "acceptanceCriteria": [
    "IDENTIFY: Check if CHANGELOG.md exists",
    "IDENTIFY: Get version from package.json",
    "IDENTIFY: Review recent git commits for changes",
    "FIX: Create CHANGELOG.md following Keep a Changelog format",
    "FIX: Document unreleased changes",
    "FIX: Categorize changes (Added, Changed, Fixed, Removed)",
    "FIX: Link to compare views between versions",
    "VERIFY: Changelog format is consistent",
    "VERIFY: Version numbers match package.json"
  ],
  "files": ["CHANGELOG.md"],
  "dependsOn": ["DOCS-DEPLOY-001"],
  "priority": 7,
  "passes": false,
  "category": "changelog"
}
```

#### Category 8: Final Verification (Priority 8)

```json
{
  "id": "DOCS-FIN-001",
  "title": "Final documentation verification",
  "description": "Verify all documentation is complete and accurate",
  "acceptanceCriteria": [
    "VERIFY: README has all required sections",
    "VERIFY: All API endpoints documented",
    "VERIFY: Architecture docs exist and are accurate",
    "VERIFY: Development setup guide works",
    "VERIFY: No broken links in documentation",
    "VERIFY: Code examples are valid and runnable",
    "VERIFY: Environment variables documented consistently",
    "DOCUMENT: Create docs/index.md with links to all docs",
    "DOCUMENT: Add documentation status to README"
  ],
  "files": ["docs/index.md", "README.md"],
  "dependsOn": ["DOCS-CHANGE-001"],
  "priority": 8,
  "passes": false,
  "category": "verification"
}
```

## Phase 3: Documentation Standards

### README Template
```markdown
# Project Name

Brief description of what this project does.

[![Build Status](badge-url)](ci-url)
[![Coverage](badge-url)](coverage-url)
[![License](badge-url)](license-url)

## Features

- Feature 1
- Feature 2

## Prerequisites

- Node.js >= 18
- PostgreSQL >= 14

## Installation

```bash
npm install
cp .env.example .env
npm run db:migrate
```

## Usage

```bash
npm run dev
```

## Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `DATABASE_URL` | PostgreSQL connection string | Yes | - |
| `PORT` | Server port | No | 3000 |

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server |
| `npm run build` | Build for production |
| `npm test` | Run tests |

## Project Structure

```
src/
├── api/          # API routes
├── services/     # Business logic
├── models/       # Database models
└── utils/        # Utilities
```

## Documentation

- [API Documentation](docs/api/)
- [Architecture](docs/architecture/)
- [Development Guide](docs/development.md)
- [Deployment](docs/deployment.md)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

[MIT](LICENSE)
```

### API Documentation Format
```markdown
## POST /api/users

Create a new user.

**Authentication:** Required (Bearer token)

**Request Body:**
```json
{
  "email": "user@example.com",
  "name": "John Doe"
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "John Doe",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

**Errors:**
- `400` - Invalid request body
- `401` - Unauthorized
- `409` - Email already exists
```

### JSDoc Template
```javascript
/**
 * Brief description of function.
 *
 * @param {string} param1 - Description of param1
 * @param {Object} options - Configuration options
 * @param {boolean} [options.optional] - Optional parameter
 * @returns {Promise<Result>} Description of return value
 * @throws {ValidationError} When validation fails
 * @example
 * const result = await myFunction('value', { optional: true });
 */
```

## Phase 4: Output

Generate `prd.json` ordered by documentation importance:
1. README (first thing people see)
2. API docs (most used reference)
3. Architecture (understanding the system)
4. Code docs (inline reference)
5. Development guide (onboarding)
6. Deployment docs (operations)
7. Changelog (version history)
8. Final verification

Documentation philosophy:
- Write for the reader, not the writer
- Keep it DRY - don't duplicate information
- Use examples liberally
- Keep it up to date (or don't write it)
- Test all code examples
