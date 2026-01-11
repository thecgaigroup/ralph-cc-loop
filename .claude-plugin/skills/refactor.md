# /refactor

---
description: Detect code smells, apply design patterns, and reduce technical debt
arguments:
  - name: project_path
    description: Path to the project to refactor
    required: true
  - name: scope
    description: "Scope: file path, directory, or 'all' for full codebase"
    required: false
---

You are a software architecture expert. Your task is to identify code smells, apply appropriate design patterns, and reduce technical debt while maintaining functionality.

## Phase 1: Code Analysis

### Step 1.1: Gather Codebase Metrics

```bash
# Lines of code
find src -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" | xargs wc -l | tail -1

# File count by type
find src -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn

# Largest files
find src -name "*.ts" -o -name "*.tsx" | xargs wc -l | sort -rn | head -20

# Check for linting rules about complexity
cat .eslintrc* | grep -E 'complexity|max-lines|max-params'
```

### Step 1.2: Identify Code Smells

Run static analysis:
```bash
# ESLint complexity rules
npx eslint src --rule 'complexity: [warn, 10]' --rule 'max-lines-per-function: [warn, 50]'

# Find long files (>300 lines)
find src -name "*.ts" -o -name "*.tsx" | xargs wc -l | awk '$1 > 300 {print}'

# Find deeply nested code
grep -rn "if.*{" src | grep -E '^\s{16,}'
```

### Step 1.3: Analyze Dependencies

```bash
# Find circular dependencies (if tool available)
npx madge --circular src/

# Find files with many imports
grep -c "^import" src/**/*.ts | sort -t: -k2 -rn | head -20

# Find highly coupled files
npx madge --image graph.svg src/
```

### Step 1.4: Check for Common Anti-Patterns

Search for:
- God classes/files (>500 lines)
- Long functions (>50 lines)
- Deep nesting (>4 levels)
- Large parameter lists (>5 params)
- Duplicate code
- Magic numbers/strings
- Dead code
- Commented-out code

## Phase 2: Generate PRD

```json
{
  "project": "{project_name}",
  "mode": "feature",
  "branchName": "ralph/refactor",
  "baseBranch": "main",
  "description": "Code refactoring and technical debt reduction",
  "userStories": []
}
```

### Story Templates

#### Category 1: Critical Complexity (Priority 1)

```json
{
  "id": "REF-CRIT-001",
  "title": "Refactor {filename} - excessive complexity",
  "description": "Break down overly complex file/function",
  "acceptanceCriteria": [
    "IDENTIFY: Map all functions and their responsibilities",
    "IDENTIFY: Find violations: complexity > 10, lines > 50, params > 5",
    "IDENTIFY: Find mixed responsibilities (SRP violations)",
    "FIX: Extract pure helper functions",
    "FIX: Split into single-responsibility modules",
    "FIX: Reduce function complexity through early returns",
    "FIX: Extract complex conditions into named functions",
    "FIX: Replace magic numbers with named constants",
    "VERIFY: All functions complexity < 10",
    "VERIFY: All functions < 50 lines",
    "VERIFY: All tests still pass",
    "DOCUMENT: Update any affected documentation"
  ],
  "files": ["{filename}"],
  "dependsOn": [],
  "priority": 1,
  "passes": false,
  "category": "complexity"
}
```

#### Category 2: Duplicate Code (Priority 2)

```json
{
  "id": "REF-DUP-001",
  "title": "Remove duplicate code patterns",
  "description": "Extract common patterns into shared utilities",
  "acceptanceCriteria": [
    "IDENTIFY: Run duplicate detection (jscpd or similar)",
    "IDENTIFY: Find copy-pasted code blocks",
    "IDENTIFY: Find similar but slightly different implementations",
    "FIX: Extract exact duplicates into shared functions",
    "FIX: Parameterize similar code into generic functions",
    "FIX: Create shared utilities for common patterns",
    "FIX: Use composition for similar components",
    "VERIFY: No duplicate blocks > 10 lines",
    "VERIFY: All tests pass",
    "VERIFY: No functionality changed"
  ],
  "files": ["src/utils/", "src/"],
  "dependsOn": ["REF-CRIT-*"],
  "priority": 2,
  "passes": false,
  "category": "duplication"
}
```

#### Category 3: God Classes/Files (Priority 3)

```json
{
  "id": "REF-GOD-001",
  "title": "Split {filename} into focused modules",
  "description": "Break down large file with multiple responsibilities",
  "acceptanceCriteria": [
    "IDENTIFY: List all distinct responsibilities in the file",
    "IDENTIFY: Group related functions/classes",
    "IDENTIFY: Map dependencies between groups",
    "FIX: Create new module for each responsibility",
    "FIX: Move related code to appropriate module",
    "FIX: Update imports throughout codebase",
    "FIX: Create index file for backward compatibility if needed",
    "VERIFY: No file > 300 lines (or justified)",
    "VERIFY: Each module has single responsibility",
    "VERIFY: All tests pass",
    "VERIFY: No circular dependencies introduced"
  ],
  "files": ["{filename}"],
  "dependsOn": ["REF-DUP-*"],
  "priority": 3,
  "passes": false,
  "category": "god-class"
}
```

#### Category 4: Deep Nesting (Priority 4)

```json
{
  "id": "REF-NEST-001",
  "title": "Reduce nesting depth in {filename}",
  "description": "Flatten deeply nested code structures",
  "acceptanceCriteria": [
    "IDENTIFY: Find functions with nesting > 3 levels",
    "IDENTIFY: Analyze conditional logic structure",
    "FIX: Apply early return pattern for guard clauses",
    "FIX: Extract nested blocks into separate functions",
    "FIX: Use flat map/filter/reduce instead of nested loops",
    "FIX: Consider strategy pattern for complex conditionals",
    "FIX: Use lookup objects instead of switch/if chains",
    "VERIFY: No nesting deeper than 3 levels",
    "VERIFY: Code is more readable",
    "VERIFY: All tests pass"
  ],
  "files": ["{filename}"],
  "dependsOn": ["REF-GOD-*"],
  "priority": 4,
  "passes": false,
  "category": "nesting"
}
```

#### Category 5: Parameter Lists (Priority 5)

```json
{
  "id": "REF-PARAM-001",
  "title": "Simplify function signatures",
  "description": "Reduce parameter counts and improve APIs",
  "acceptanceCriteria": [
    "IDENTIFY: Find functions with > 3 parameters",
    "IDENTIFY: Find boolean flag parameters",
    "IDENTIFY: Find optional parameter chains",
    "FIX: Group related parameters into options objects",
    "FIX: Replace boolean flags with explicit function variants",
    "FIX: Use builder pattern for complex construction",
    "FIX: Consider introducing parameter objects",
    "VERIFY: No function has > 3 positional parameters",
    "VERIFY: API is more intuitive",
    "VERIFY: All tests pass"
  ],
  "files": ["src/"],
  "dependsOn": ["REF-NEST-*"],
  "priority": 5,
  "passes": false,
  "category": "parameters"
}
```

#### Category 6: Dead Code (Priority 6)

```json
{
  "id": "REF-DEAD-001",
  "title": "Remove dead code and unused exports",
  "description": "Clean up unreachable and unused code",
  "acceptanceCriteria": [
    "IDENTIFY: Find unused exports (ts-prune or similar)",
    "IDENTIFY: Find commented-out code blocks",
    "IDENTIFY: Find unreachable code paths",
    "IDENTIFY: Find unused variables and imports",
    "FIX: Remove confirmed unused exports",
    "FIX: Remove commented-out code (it's in git)",
    "FIX: Remove unreachable code",
    "FIX: Remove unused imports and variables",
    "VERIFY: No TypeScript/ESLint unused warnings",
    "VERIFY: All tests pass",
    "VERIFY: Build succeeds"
  ],
  "files": ["src/"],
  "dependsOn": ["REF-PARAM-*"],
  "priority": 6,
  "passes": false,
  "category": "dead-code"
}
```

#### Category 7: Naming (Priority 7)

```json
{
  "id": "REF-NAME-001",
  "title": "Improve naming consistency",
  "description": "Rename unclear or inconsistent identifiers",
  "acceptanceCriteria": [
    "IDENTIFY: Find single-letter variables (except i, j in loops)",
    "IDENTIFY: Find generic names (data, info, item, thing)",
    "IDENTIFY: Find inconsistent naming patterns",
    "IDENTIFY: Find misleading names",
    "FIX: Rename to reveal intent",
    "FIX: Apply consistent naming conventions",
    "FIX: Use domain terminology consistently",
    "FIX: Make boolean names questions (isActive, hasPermission)",
    "VERIFY: Names are self-documenting",
    "VERIFY: All tests pass",
    "VERIFY: No linting errors"
  ],
  "files": ["src/"],
  "dependsOn": ["REF-DEAD-*"],
  "priority": 7,
  "passes": false,
  "category": "naming"
}
```

#### Category 8: Error Handling (Priority 8)

```json
{
  "id": "REF-ERR-001",
  "title": "Improve error handling patterns",
  "description": "Standardize and improve error handling",
  "acceptanceCriteria": [
    "IDENTIFY: Find empty catch blocks",
    "IDENTIFY: Find generic error throws",
    "IDENTIFY: Find inconsistent error handling",
    "IDENTIFY: Find swallowed errors (catch without rethrow/log)",
    "FIX: Add proper error handling to empty catches",
    "FIX: Create typed error classes for domain errors",
    "FIX: Standardize error response format",
    "FIX: Add error boundaries for UI (if React)",
    "FIX: Ensure errors are logged appropriately",
    "VERIFY: No empty catch blocks",
    "VERIFY: Errors have useful messages",
    "VERIFY: All tests pass"
  ],
  "files": ["src/"],
  "dependsOn": ["REF-NAME-*"],
  "priority": 8,
  "passes": false,
  "category": "error-handling"
}
```

#### Category 9: Type Safety (Priority 9)

```json
{
  "id": "REF-TYPE-001",
  "title": "Improve type safety",
  "description": "Reduce any types and improve type coverage",
  "acceptanceCriteria": [
    "IDENTIFY: Find all 'any' type usages",
    "IDENTIFY: Find type assertions (as X)",
    "IDENTIFY: Find ! non-null assertions",
    "IDENTIFY: Find implicit any in function parameters",
    "FIX: Replace any with proper types",
    "FIX: Add type guards instead of assertions",
    "FIX: Use strict null checks properly",
    "FIX: Add return type annotations",
    "VERIFY: No explicit 'any' types (or justified)",
    "VERIFY: TypeScript strict mode passes",
    "VERIFY: All tests pass"
  ],
  "files": ["src/", "tsconfig.json"],
  "dependsOn": ["REF-ERR-*"],
  "priority": 9,
  "passes": false,
  "category": "type-safety"
}
```

#### Category 10: Final Verification (Priority 10)

```json
{
  "id": "REF-FIN-001",
  "title": "Final refactoring verification",
  "description": "Verify refactoring improved code quality",
  "acceptanceCriteria": [
    "VERIFY: All complexity warnings resolved",
    "VERIFY: No duplicate code > 10 lines",
    "VERIFY: No files > 300 lines (without justification)",
    "VERIFY: No functions > 50 lines",
    "VERIFY: All tests pass",
    "VERIFY: Code coverage maintained or improved",
    "VERIFY: No new linting errors",
    "DOCUMENT: Update architecture docs if structure changed",
    "DOCUMENT: Create REFACTOR_LOG.md with changes made"
  ],
  "files": ["REFACTOR_LOG.md"],
  "dependsOn": ["REF-TYPE-*"],
  "priority": 10,
  "passes": false,
  "category": "verification"
}
```

## Phase 3: Refactoring Patterns

### Extract Function
```javascript
// Before
function processOrder(order) {
  // 20 lines of validation
  // 30 lines of calculation
  // 15 lines of notification
}

// After
function processOrder(order) {
  validateOrder(order);
  const total = calculateTotal(order);
  notifyCustomer(order, total);
}
```

### Replace Conditional with Polymorphism
```javascript
// Before
function getArea(shape) {
  if (shape.type === 'circle') return Math.PI * shape.radius ** 2;
  if (shape.type === 'rectangle') return shape.width * shape.height;
}

// After
const areaCalculators = {
  circle: (s) => Math.PI * s.radius ** 2,
  rectangle: (s) => s.width * s.height,
};
function getArea(shape) {
  return areaCalculators[shape.type](shape);
}
```

### Early Return
```javascript
// Before
function process(data) {
  if (data) {
    if (data.isValid) {
      if (data.hasPermission) {
        // actual logic
      }
    }
  }
}

// After
function process(data) {
  if (!data) return;
  if (!data.isValid) return;
  if (!data.hasPermission) return;
  // actual logic
}
```

### Parameter Object
```javascript
// Before
function createUser(name, email, age, role, department, manager) {}

// After
function createUser({ name, email, age, role, department, manager }) {}
```

## Phase 4: Code Quality Thresholds

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| Cyclomatic Complexity | < 10 | 10-15 | > 15 |
| Function Length | < 30 lines | 30-50 | > 50 |
| File Length | < 200 lines | 200-400 | > 400 |
| Parameters | < 3 | 3-5 | > 5 |
| Nesting Depth | < 3 | 3-4 | > 4 |
| Duplicate Blocks | 0 | 1-3 | > 3 |

## Phase 5: Output

Generate `prd.json` prioritizing:
1. Critical complexity (highest risk)
2. Duplication (maintenance burden)
3. God classes (architectural issue)
4. Deep nesting (readability)
5. Parameter lists (API quality)
6. Dead code (cruft)
7. Naming (clarity)
8. Error handling (reliability)
9. Type safety (correctness)
10. Final verification

Create `REFACTOR_LOG.md`:
```markdown
# Refactoring Log

## Summary
- Files refactored: X
- Functions extracted: Y
- Lines removed: Z

## Changes by Category

### Complexity Reduction
- {file}: Split into X modules
- {function}: Reduced complexity from X to Y

### Duplication Removed
- Extracted {pattern} to utils/{file}

### Architecture Changes
- Created new module: {module}
- Moved {components} from {old} to {new}

## Metrics Before/After
| Metric | Before | After |
|--------|--------|-------|
| Avg complexity | X | Y |
| Max file length | X | Y |
| Duplicate blocks | X | Y |

## Deferred Items
- [List any technical debt not addressed]
```
