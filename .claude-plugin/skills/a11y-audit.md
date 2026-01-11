# /a11y-audit

---
description: Audit and remediate accessibility issues for WCAG compliance
arguments:
  - name: project_path
    description: Path to the project to audit
    required: true
  - name: level
    description: "WCAG compliance level: A, AA (default), or AAA"
    required: false
---

You are an accessibility expert. Your task is to audit a web application for WCAG compliance and remediate accessibility issues.

## Phase 1: Project Analysis

### Step 1.1: Detect Frontend Framework

```bash
# Check for UI frameworks
cat package.json | jq '.dependencies | keys[]' | grep -E 'react|vue|angular|svelte|next|nuxt'

# Check for component libraries
cat package.json | jq '.dependencies | keys[]' | grep -E 'chakra|material|antd|radix|headless'

# Find component files
find src -name "*.tsx" -o -name "*.jsx" -o -name "*.vue" -o -name "*.svelte" | head -10
```

### Step 1.2: Identify Testing Tools

```bash
# Check for a11y testing tools
cat package.json | jq '.devDependencies | keys[]' | grep -E 'axe|pa11y|lighthouse|jest-axe|cypress-axe'

# Check for existing a11y configs
ls .pa11yci* .lighthouserc* 2>/dev/null
```

### Step 1.3: Run Automated Audit

If tools available, run automated scans:
```bash
# axe-core via CLI
npx axe --dir src/

# pa11y
npx pa11y http://localhost:3000

# Lighthouse
npx lighthouse http://localhost:3000 --only-categories=accessibility --output=json
```

### Step 1.4: Manual Audit Checklist

Review codebase for:
- Images without alt text
- Form inputs without labels
- Missing ARIA attributes
- Color contrast issues
- Keyboard navigation
- Focus management
- Heading hierarchy
- Link text quality
- Skip navigation links

## Phase 2: Collect Environment Information

### Step 2.1: Ask for Target URL

Prompt user:
```
What URL should I audit for accessibility?

1. Local development (http://localhost:3000)
2. Staging environment
3. Production URL
4. I'll run the dev server manually
```

### Step 2.2: Ask for Compliance Level

```
What WCAG compliance level are you targeting?

1. WCAG 2.1 Level A (minimum)
2. WCAG 2.1 Level AA (recommended, required for many regulations)
3. WCAG 2.1 Level AAA (highest, often not fully achievable)
```

## Phase 3: Generate PRD

```json
{
  "project": "{project_name}",
  "mode": "feature",
  "branchName": "ralph/accessibility",
  "baseBranch": "main",
  "description": "WCAG {level} accessibility audit and remediation",
  "userStories": []
}
```

### Story Templates

#### Category 1: Setup & Tooling (Priority 1)

```json
{
  "id": "A11Y-SETUP-001",
  "title": "Set up accessibility testing infrastructure",
  "description": "Install and configure a11y testing tools",
  "acceptanceCriteria": [
    "IDENTIFY: Check for existing a11y testing setup",
    "FIX: Install axe-core or jest-axe for automated testing",
    "FIX: Add a11y test script to package.json",
    "FIX: Create a11y test configuration file",
    "FIX: Add sample a11y test for main components",
    "VERIFY: A11y tests can be run with npm run test:a11y",
    "DOCUMENT: Add a11y testing instructions to README"
  ],
  "files": ["package.json", "tests/a11y/"],
  "dependsOn": [],
  "priority": 1,
  "passes": false,
  "category": "setup"
}
```

#### Category 2: Semantic HTML (Priority 2)

```json
{
  "id": "A11Y-SEM-001",
  "title": "Fix semantic HTML structure",
  "description": "Ensure proper HTML semantics throughout the app",
  "acceptanceCriteria": [
    "IDENTIFY: Find divs that should be semantic elements (nav, main, section, article, aside, header, footer)",
    "IDENTIFY: Check for proper heading hierarchy (h1 -> h2 -> h3, no skipping)",
    "IDENTIFY: Find lists that aren't using ul/ol/li",
    "FIX: Replace div with appropriate semantic elements",
    "FIX: Fix heading hierarchy - ensure single h1 per page",
    "FIX: Convert list-like content to proper list elements",
    "FIX: Add landmark roles where semantic elements aren't possible",
    "VERIFY: Each page has proper landmark structure",
    "VERIFY: Heading hierarchy passes automated check"
  ],
  "files": ["src/**/*.tsx", "src/**/*.jsx"],
  "dependsOn": ["A11Y-SETUP-001"],
  "priority": 2,
  "passes": false,
  "category": "semantic-html"
}
```

#### Category 3: Images & Media (Priority 3)

```json
{
  "id": "A11Y-IMG-001",
  "title": "Fix image accessibility",
  "description": "Ensure all images have appropriate alt text",
  "acceptanceCriteria": [
    "IDENTIFY: Find all img tags and Image components",
    "IDENTIFY: Categorize as informative, decorative, or functional",
    "FIX: Add descriptive alt text to informative images",
    "FIX: Add alt=\"\" or role=\"presentation\" to decorative images",
    "FIX: Ensure functional images (buttons/links) have descriptive alt",
    "FIX: Add aria-label to icon-only buttons",
    "FIX: Ensure SVGs have title or aria-label",
    "VERIFY: No images missing alt attribute",
    "VERIFY: Alt text is descriptive, not \"image of...\""
  ],
  "files": ["src/**/*.tsx", "src/**/*.jsx"],
  "dependsOn": ["A11Y-SEM-001"],
  "priority": 3,
  "passes": false,
  "category": "images"
}
```

#### Category 4: Forms (Priority 4)

```json
{
  "id": "A11Y-FORM-001",
  "title": "Fix form accessibility",
  "description": "Ensure all form elements are accessible",
  "acceptanceCriteria": [
    "IDENTIFY: Find all form inputs, selects, textareas",
    "IDENTIFY: Check for associated labels",
    "IDENTIFY: Find error messages and their associations",
    "FIX: Add label elements associated via htmlFor/id",
    "FIX: Add aria-label for inputs without visible labels",
    "FIX: Add aria-describedby for helper text",
    "FIX: Add aria-invalid for error states",
    "FIX: Associate error messages with aria-errormessage or aria-describedby",
    "FIX: Add required attribute or aria-required",
    "FIX: Ensure proper fieldset/legend for radio/checkbox groups",
    "VERIFY: All inputs announce their label in screen reader",
    "VERIFY: Error messages are announced"
  ],
  "files": ["src/**/*.tsx", "src/**/*.jsx"],
  "dependsOn": ["A11Y-IMG-001"],
  "priority": 4,
  "passes": false,
  "category": "forms"
}
```

#### Category 5: Keyboard Navigation (Priority 5)

```json
{
  "id": "A11Y-KB-001",
  "title": "Fix keyboard navigation",
  "description": "Ensure full keyboard accessibility",
  "acceptanceCriteria": [
    "IDENTIFY: Find interactive elements (buttons, links, inputs)",
    "IDENTIFY: Find custom interactive components (dropdowns, modals, tabs)",
    "IDENTIFY: Check tab order logic",
    "FIX: Ensure all interactive elements are focusable",
    "FIX: Add tabindex=\"0\" to custom interactive elements",
    "FIX: Remove tabindex > 0 (anti-pattern)",
    "FIX: Add visible focus indicators (outline, ring)",
    "FIX: Implement skip navigation link",
    "FIX: Ensure modals trap focus properly",
    "FIX: Add keyboard handlers (Enter/Space for buttons, Escape for modals)",
    "VERIFY: Can navigate entire app with keyboard only",
    "VERIFY: Focus is always visible",
    "VERIFY: Tab order is logical"
  ],
  "files": ["src/**/*.tsx", "src/**/*.jsx", "src/**/*.css"],
  "dependsOn": ["A11Y-FORM-001"],
  "priority": 5,
  "passes": false,
  "category": "keyboard"
}
```

#### Category 6: Color & Contrast (Priority 6)

```json
{
  "id": "A11Y-COLOR-001",
  "title": "Fix color contrast issues",
  "description": "Ensure sufficient color contrast throughout the app",
  "acceptanceCriteria": [
    "IDENTIFY: Run contrast checker on all text/background combinations",
    "IDENTIFY: Find color-only indicators (error states, required fields)",
    "FIX: Adjust text colors to meet 4.5:1 ratio (normal text)",
    "FIX: Adjust large text to meet 3:1 ratio",
    "FIX: Adjust UI component contrast to meet 3:1 ratio",
    "FIX: Add non-color indicators (icons, underlines, patterns)",
    "FIX: Ensure links are distinguishable from text",
    "FIX: Check contrast in all color themes (light/dark)",
    "VERIFY: All text passes WCAG AA contrast requirements",
    "VERIFY: Information not conveyed by color alone"
  ],
  "files": ["src/**/*.css", "src/**/*.scss", "tailwind.config.*"],
  "dependsOn": ["A11Y-KB-001"],
  "priority": 6,
  "passes": false,
  "category": "color"
}
```

#### Category 7: ARIA & Live Regions (Priority 7)

```json
{
  "id": "A11Y-ARIA-001",
  "title": "Implement proper ARIA attributes",
  "description": "Add and fix ARIA attributes for dynamic content",
  "acceptanceCriteria": [
    "IDENTIFY: Find dynamic content areas (notifications, loading states)",
    "IDENTIFY: Find custom widgets (tabs, accordions, carousels)",
    "IDENTIFY: Check for ARIA misuse",
    "FIX: Add aria-live regions for dynamic content",
    "FIX: Add aria-busy for loading states",
    "FIX: Implement proper ARIA patterns for custom widgets",
    "FIX: Remove redundant ARIA (role=\"button\" on button)",
    "FIX: Add aria-expanded, aria-controls, aria-selected where needed",
    "FIX: Ensure aria-hidden is used correctly",
    "VERIFY: Screen reader announces dynamic updates",
    "VERIFY: Custom widgets follow ARIA authoring practices"
  ],
  "files": ["src/**/*.tsx", "src/**/*.jsx"],
  "dependsOn": ["A11Y-COLOR-001"],
  "priority": 7,
  "passes": false,
  "category": "aria"
}
```

#### Category 8: Automated Tests (Priority 8)

```json
{
  "id": "A11Y-TEST-001",
  "title": "Add automated accessibility tests",
  "description": "Create comprehensive a11y test suite",
  "acceptanceCriteria": [
    "IDENTIFY: List all pages and key components",
    "FIX: Add axe-core tests for each page",
    "FIX: Add component-level a11y tests",
    "FIX: Add keyboard navigation tests",
    "FIX: Add screen reader announcement tests if possible",
    "FIX: Configure CI to run a11y tests",
    "FIX: Set up a11y test failure thresholds",
    "VERIFY: All a11y tests pass",
    "VERIFY: CI blocks on a11y failures"
  ],
  "files": ["tests/a11y/", ".github/workflows/"],
  "dependsOn": ["A11Y-ARIA-001"],
  "priority": 8,
  "passes": false,
  "category": "testing"
}
```

#### Category 9: Final Verification (Priority 9)

```json
{
  "id": "A11Y-FIN-001",
  "title": "Final accessibility verification",
  "description": "Comprehensive a11y audit and documentation",
  "acceptanceCriteria": [
    "VERIFY: Run full automated a11y scan - no critical/serious issues",
    "VERIFY: Manual keyboard navigation test passes",
    "VERIFY: Screen reader testing (if available) passes",
    "VERIFY: Color contrast checker passes",
    "VERIFY: Heading hierarchy is correct",
    "VERIFY: All forms are accessible",
    "DOCUMENT: Create ACCESSIBILITY.md with compliance statement",
    "DOCUMENT: List known limitations or exceptions",
    "DOCUMENT: Add a11y testing instructions",
    "FOLLOW-UP: Create issues for any AAA-level improvements"
  ],
  "files": ["ACCESSIBILITY.md", "README.md"],
  "dependsOn": ["A11Y-TEST-001"],
  "priority": 9,
  "passes": false,
  "category": "verification"
}
```

## Phase 4: WCAG Quick Reference

### Level A (Minimum)
- All images have alt text
- Form inputs have labels
- No keyboard traps
- Page has title
- Link purpose is clear
- No auto-playing media

### Level AA (Standard)
- 4.5:1 contrast for normal text
- 3:1 contrast for large text
- Text can resize to 200%
- Multiple ways to find pages
- Consistent navigation
- Error identification and suggestions

### Level AAA (Enhanced)
- 7:1 contrast for normal text
- Sign language for video
- Extended audio descriptions
- No timing limits
- No interruptions

## Phase 5: Testing Tools

### Automated
- **axe-core**: Most comprehensive, integrates with browsers and test frameworks
- **pa11y**: CLI and CI-friendly
- **Lighthouse**: Built into Chrome DevTools
- **WAVE**: Browser extension for visual feedback

### Manual Testing
- **Keyboard**: Tab through entire app
- **Screen Reader**: VoiceOver (Mac), NVDA (Windows), Orca (Linux)
- **Zoom**: Test at 200% zoom
- **Color**: Test with color blindness simulators

### Browser Extensions
- axe DevTools
- WAVE
- Accessibility Insights
- HeadingsMap

## Phase 6: Output

Generate `prd.json` with stories ordered by impact:
1. Setup and tooling
2. Semantic HTML (foundation)
3. Images (common issue)
4. Forms (critical for interaction)
5. Keyboard (essential for many users)
6. Color contrast (common failure)
7. ARIA (for dynamic content)
8. Automated tests (prevent regression)
9. Final verification

Create `ACCESSIBILITY.md`:
```markdown
# Accessibility Statement

## Compliance Status
This application aims to conform to WCAG 2.1 Level {level}.

## Testing
- Automated testing with axe-core
- Manual keyboard testing
- Screen reader testing with {screen_reader}

## Known Limitations
- [List any known issues]

## Feedback
Report accessibility issues to: [contact]

## Assessment Date
Last assessed: {date}
```
