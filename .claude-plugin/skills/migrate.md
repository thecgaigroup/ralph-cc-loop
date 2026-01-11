# /migrate

---
description: Assist with framework and version migrations (React, Node, TypeScript, etc.)
arguments:
  - name: project_path
    description: Path to the project to migrate
    required: true
  - name: migration_type
    description: "Type of migration (e.g., 'react-18-to-19', 'cjs-to-esm', 'node-18-to-20')"
    required: true
---

You are a migration expert. Your task is to safely migrate a project between framework versions or paradigms while maintaining functionality.

## Phase 1: Migration Analysis

### Step 1.1: Understand Current State

```bash
# Check current versions
cat package.json | jq '.dependencies, .devDependencies'
node --version
cat tsconfig.json 2>/dev/null

# Check for migration-specific files
ls .nvmrc .node-version .tool-versions 2>/dev/null
```

### Step 1.2: Identify Migration Scope

Based on `{migration_type}`, determine:
- Source version/paradigm
- Target version/paradigm
- Breaking changes to address
- Files that need modification

### Step 1.3: Assess Risk

Analyze:
- Test coverage (higher = safer migration)
- Dependency compatibility with target
- Custom implementations vs framework patterns
- Size of codebase affected

## Phase 2: Migration Types

### React Version Migration (e.g., 18 to 19)

```json
{
  "project": "{project_name}",
  "mode": "feature",
  "branchName": "ralph/migrate-react-19",
  "baseBranch": "main",
  "description": "Migrate from React 18 to React 19",
  "userStories": [
    {
      "id": "MIG-PREP-001",
      "title": "Pre-migration preparation",
      "description": "Prepare codebase for React 19 migration",
      "acceptanceCriteria": [
        "IDENTIFY: Current React version and all React-related packages",
        "IDENTIFY: Read React 19 upgrade guide for breaking changes",
        "IDENTIFY: Search codebase for deprecated patterns",
        "VERIFY: All tests pass on current version",
        "VERIFY: Git working tree is clean",
        "DOCUMENT: List all breaking changes that apply to this codebase"
      ],
      "files": ["package.json"],
      "priority": 1,
      "passes": false
    },
    {
      "id": "MIG-DEPS-001",
      "title": "Update React packages",
      "description": "Update React and related dependencies",
      "acceptanceCriteria": [
        "FIX: Update react and react-dom to ^19.0.0",
        "FIX: Update @types/react and @types/react-dom",
        "FIX: Update react-test-renderer if used",
        "FIX: Update React-dependent packages (react-router, etc)",
        "VERIFY: npm install completes without errors",
        "VERIFY: No peer dependency warnings for React version"
      ],
      "files": ["package.json", "package-lock.json"],
      "dependsOn": ["MIG-PREP-001"],
      "priority": 2,
      "passes": false
    },
    {
      "id": "MIG-CODE-001",
      "title": "Update deprecated patterns",
      "description": "Replace deprecated React patterns",
      "acceptanceCriteria": [
        "FIX: Replace deprecated lifecycle methods",
        "FIX: Update ref forwarding patterns if changed",
        "FIX: Update context API usage if needed",
        "FIX: Update concurrent features usage",
        "VERIFY: TypeScript compiles without errors",
        "VERIFY: No React deprecation warnings in console"
      ],
      "files": ["src/**/*.tsx", "src/**/*.jsx"],
      "dependsOn": ["MIG-DEPS-001"],
      "priority": 3,
      "passes": false
    },
    {
      "id": "MIG-TEST-001",
      "title": "Update and verify tests",
      "description": "Ensure tests work with React 19",
      "acceptanceCriteria": [
        "FIX: Update test utilities for React 19 compatibility",
        "FIX: Update snapshot tests if needed",
        "FIX: Address any act() warnings",
        "VERIFY: All unit tests pass",
        "VERIFY: All integration tests pass",
        "VERIFY: No test deprecation warnings"
      ],
      "files": ["tests/", "**/*.test.tsx"],
      "dependsOn": ["MIG-CODE-001"],
      "priority": 4,
      "passes": false
    },
    {
      "id": "MIG-VERIFY-001",
      "title": "Final migration verification",
      "description": "Comprehensive verification of migration",
      "acceptanceCriteria": [
        "VERIFY: App builds for production",
        "VERIFY: App runs without errors",
        "VERIFY: All major user flows work",
        "VERIFY: No console errors or warnings",
        "VERIFY: Performance is not degraded",
        "DOCUMENT: Update README with new React version",
        "DOCUMENT: Note any behavior changes in CHANGELOG"
      ],
      "files": ["README.md", "CHANGELOG.md"],
      "dependsOn": ["MIG-TEST-001"],
      "priority": 5,
      "passes": false
    }
  ]
}
```

### CommonJS to ESM Migration

```json
{
  "project": "{project_name}",
  "mode": "feature",
  "branchName": "ralph/migrate-esm",
  "baseBranch": "main",
  "description": "Migrate from CommonJS to ES Modules",
  "userStories": [
    {
      "id": "MIG-ESM-PREP-001",
      "title": "Analyze CJS usage",
      "description": "Identify all CommonJS patterns in codebase",
      "acceptanceCriteria": [
        "IDENTIFY: Find all require() statements",
        "IDENTIFY: Find all module.exports and exports.* patterns",
        "IDENTIFY: Find __dirname and __filename usage",
        "IDENTIFY: Check for dynamic requires",
        "IDENTIFY: List dependencies that may not support ESM",
        "DOCUMENT: Create migration checklist"
      ],
      "files": ["src/"],
      "priority": 1,
      "passes": false
    },
    {
      "id": "MIG-ESM-CONFIG-001",
      "title": "Update package configuration",
      "description": "Configure package.json for ESM",
      "acceptanceCriteria": [
        "FIX: Add \"type\": \"module\" to package.json",
        "FIX: Update exports field if publishing",
        "FIX: Update main/module fields",
        "FIX: Rename .js to .mjs if needed OR update config",
        "FIX: Update tsconfig for ESM output if TypeScript",
        "VERIFY: Package config is valid"
      ],
      "files": ["package.json", "tsconfig.json"],
      "dependsOn": ["MIG-ESM-PREP-001"],
      "priority": 2,
      "passes": false
    },
    {
      "id": "MIG-ESM-IMPORTS-001",
      "title": "Convert require to import",
      "description": "Replace all require() with import statements",
      "acceptanceCriteria": [
        "FIX: Convert require('module') to import module from 'module'",
        "FIX: Convert require('./local') to import local from './local.js'",
        "FIX: Add .js extensions to relative imports",
        "FIX: Convert dynamic requires to dynamic imports",
        "FIX: Handle JSON imports with assert syntax",
        "VERIFY: No require() statements remain (except in CJS dependencies)"
      ],
      "files": ["src/**/*.js", "src/**/*.ts"],
      "dependsOn": ["MIG-ESM-CONFIG-001"],
      "priority": 3,
      "passes": false
    },
    {
      "id": "MIG-ESM-EXPORTS-001",
      "title": "Convert exports syntax",
      "description": "Replace module.exports with export statements",
      "acceptanceCriteria": [
        "FIX: Convert module.exports = X to export default X",
        "FIX: Convert exports.name = X to export const name = X",
        "FIX: Convert module.exports = { a, b } to named exports",
        "VERIFY: All exports are valid ESM syntax"
      ],
      "files": ["src/**/*.js", "src/**/*.ts"],
      "dependsOn": ["MIG-ESM-IMPORTS-001"],
      "priority": 4,
      "passes": false
    },
    {
      "id": "MIG-ESM-COMPAT-001",
      "title": "Handle __dirname/__filename",
      "description": "Replace CJS globals with ESM equivalents",
      "acceptanceCriteria": [
        "IDENTIFY: Find all __dirname and __filename usage",
        "FIX: Import fileURLToPath from 'url'",
        "FIX: Import dirname from 'path'",
        "FIX: Replace __filename with fileURLToPath(import.meta.url)",
        "FIX: Replace __dirname with dirname(fileURLToPath(import.meta.url))",
        "VERIFY: File path operations work correctly"
      ],
      "files": ["src/**/*.js", "src/**/*.ts"],
      "dependsOn": ["MIG-ESM-EXPORTS-001"],
      "priority": 5,
      "passes": false
    },
    {
      "id": "MIG-ESM-TEST-001",
      "title": "Update test configuration",
      "description": "Configure test framework for ESM",
      "acceptanceCriteria": [
        "FIX: Update Jest/Vitest config for ESM",
        "FIX: Update test file imports",
        "FIX: Update mocking patterns for ESM",
        "VERIFY: All tests pass",
        "VERIFY: Test coverage maintained"
      ],
      "files": ["jest.config.*", "vitest.config.*", "tests/"],
      "dependsOn": ["MIG-ESM-COMPAT-001"],
      "priority": 6,
      "passes": false
    },
    {
      "id": "MIG-ESM-VERIFY-001",
      "title": "Final ESM migration verification",
      "description": "Verify complete ESM migration",
      "acceptanceCriteria": [
        "VERIFY: No CJS syntax remains in src/",
        "VERIFY: All imports have proper extensions",
        "VERIFY: App builds successfully",
        "VERIFY: App runs in Node.js ESM mode",
        "VERIFY: All tests pass",
        "DOCUMENT: Update README with ESM requirements"
      ],
      "files": ["README.md"],
      "dependsOn": ["MIG-ESM-TEST-001"],
      "priority": 7,
      "passes": false
    }
  ]
}
```

### Node.js Version Migration

```json
{
  "id": "MIG-NODE-001",
  "title": "Migrate to Node.js {target_version}",
  "acceptanceCriteria": [
    "IDENTIFY: Current Node version requirements",
    "IDENTIFY: Features deprecated between versions",
    "IDENTIFY: New features available in target version",
    "FIX: Update .nvmrc / .node-version to {target_version}",
    "FIX: Update engines field in package.json",
    "FIX: Update CI configuration for new Node version",
    "FIX: Update Dockerfile if present",
    "FIX: Replace deprecated APIs",
    "VERIFY: All tests pass on new Node version",
    "VERIFY: No deprecation warnings",
    "DOCUMENT: Update README with new Node requirement"
  ]
}
```

### TypeScript Version Migration

```json
{
  "id": "MIG-TS-001",
  "title": "Migrate to TypeScript {target_version}",
  "acceptanceCriteria": [
    "IDENTIFY: Current TypeScript version",
    "IDENTIFY: Breaking changes in target version",
    "FIX: Update typescript dependency",
    "FIX: Update tsconfig.json for new options",
    "FIX: Fix any new type errors introduced",
    "FIX: Update @types packages to compatible versions",
    "VERIFY: tsc compiles without errors",
    "VERIFY: All tests pass",
    "DOCUMENT: Note any type changes in CHANGELOG"
  ]
}
```

### Database ORM Migration (e.g., Sequelize to Prisma)

```json
{
  "project": "{project_name}",
  "mode": "feature",
  "branchName": "ralph/migrate-prisma",
  "baseBranch": "main",
  "description": "Migrate from Sequelize to Prisma",
  "userStories": [
    {
      "id": "MIG-ORM-PREP-001",
      "title": "Analyze current Sequelize usage",
      "description": "Map all Sequelize models and queries",
      "acceptanceCriteria": [
        "IDENTIFY: List all Sequelize models and relationships",
        "IDENTIFY: Map all query patterns used",
        "IDENTIFY: Find migrations and seeders",
        "IDENTIFY: Document custom hooks and scopes",
        "DOCUMENT: Create schema mapping document"
      ],
      "priority": 1
    },
    {
      "id": "MIG-ORM-SCHEMA-001",
      "title": "Create Prisma schema",
      "description": "Translate Sequelize models to Prisma schema",
      "acceptanceCriteria": [
        "FIX: Create prisma/schema.prisma",
        "FIX: Define all models with fields",
        "FIX: Add relationships (1:1, 1:N, N:N)",
        "FIX: Add indexes and constraints",
        "FIX: Configure database connection",
        "VERIFY: prisma validate passes",
        "VERIFY: Schema matches existing database"
      ],
      "dependsOn": ["MIG-ORM-PREP-001"],
      "priority": 2
    },
    {
      "id": "MIG-ORM-CLIENT-001",
      "title": "Replace Sequelize queries with Prisma",
      "description": "Convert all database queries",
      "acceptanceCriteria": [
        "FIX: Replace Model.findAll with prisma.model.findMany",
        "FIX: Replace Model.findOne with prisma.model.findFirst/findUnique",
        "FIX: Replace Model.create with prisma.model.create",
        "FIX: Replace Model.update with prisma.model.update",
        "FIX: Replace Model.destroy with prisma.model.delete",
        "FIX: Convert complex queries and raw SQL",
        "VERIFY: All CRUD operations work"
      ],
      "dependsOn": ["MIG-ORM-SCHEMA-001"],
      "priority": 3
    },
    {
      "id": "MIG-ORM-VERIFY-001",
      "title": "Verify ORM migration",
      "description": "Comprehensive testing of migrated data layer",
      "acceptanceCriteria": [
        "VERIFY: All database operations work correctly",
        "VERIFY: All tests pass",
        "VERIFY: Transactions work properly",
        "VERIFY: No N+1 query issues introduced",
        "FIX: Remove Sequelize dependencies",
        "DOCUMENT: Update README with Prisma setup"
      ],
      "dependsOn": ["MIG-ORM-CLIENT-001"],
      "priority": 4
    }
  ]
}
```

## Phase 3: Migration Principles

### Safety First
1. **Always have tests** - Don't migrate without test coverage
2. **Incremental changes** - Small commits, easy rollback
3. **Feature flags** - Toggle between old/new if possible
4. **Parallel running** - Run both versions in tests if feasible

### Common Pitfalls
- Assuming "it compiles = it works"
- Not reading migration guides thoroughly
- Batch updating dependencies (update incrementally)
- Ignoring deprecation warnings before migration
- Not testing on production-like data

### Rollback Plan
Every migration story should support rollback:
- Each change in separate commit
- Document how to revert
- Keep old code commented (temporarily) for complex changes
- Test rollback procedure

## Phase 4: Output

Generate `prd.json` based on the specific migration type requested:
1. Preparation and analysis
2. Configuration changes
3. Code changes (incremental by module)
4. Test updates
5. Final verification

The key is breaking the migration into atomic, testable steps where each story can be verified independently before proceeding.
