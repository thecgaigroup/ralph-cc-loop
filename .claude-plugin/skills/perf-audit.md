# /perf-audit

---
description: Profile application performance, identify bottlenecks, and optimize
arguments:
  - name: project_path
    description: Path to the project to audit
    required: true
  - name: focus
    description: "Focus area: frontend, backend, database, or all (default)"
    required: false
---

You are a performance engineering expert. Your task is to profile an application, identify bottlenecks, and implement optimizations.

## Phase 1: Project Analysis

### Step 1.1: Identify Application Type

```bash
# Check for frontend frameworks
cat package.json | jq '.dependencies | keys[]' | grep -E 'react|vue|angular|next|nuxt|svelte'

# Check for backend frameworks
cat package.json | jq '.dependencies | keys[]' | grep -E 'express|fastify|koa|nest|hapi'

# Check for database
cat package.json | jq '.dependencies | keys[]' | grep -E 'prisma|sequelize|typeorm|mongoose|pg|mysql'

# Python
grep -E 'django|flask|fastapi|sqlalchemy' requirements*.txt pyproject.toml 2>/dev/null
```

### Step 1.2: Detect Performance Tools

```bash
# Check for existing performance tools
cat package.json | jq '.devDependencies | keys[]' | grep -E 'lighthouse|webpack-bundle-analyzer|source-map-explorer'

# Check for monitoring
cat package.json | jq '.dependencies | keys[]' | grep -E 'newrelic|datadog|sentry'
```

### Step 1.3: Gather Baseline Metrics

For frontend:
```bash
# Build size analysis
npm run build 2>&1 | tail -20
du -sh dist/ build/ .next/ 2>/dev/null

# Bundle analysis if available
npx source-map-explorer dist/**/*.js --json
```

For backend:
```bash
# Check for existing benchmarks
ls benchmarks/ perf/ 2>/dev/null
```

## Phase 2: Environment Setup

### Step 2.1: Ask for Performance Targets

```
What are your performance targets?

Frontend:
- Largest Contentful Paint (LCP): < 2.5s (good), < 4s (needs improvement)
- First Input Delay (FID): < 100ms (good), < 300ms (needs improvement)
- Cumulative Layout Shift (CLS): < 0.1 (good), < 0.25 (needs improvement)

Backend:
- API response time p50: ___ms
- API response time p99: ___ms
- Requests per second: ___

Database:
- Query time p50: ___ms
- Query time p99: ___ms
```

### Step 2.2: Ask for Environment

```
Which environment should I profile?

1. Local development
2. Staging (provide URL)
3. Production (read-only analysis)
```

## Phase 3: Generate PRD

```json
{
  "project": "{project_name}",
  "mode": "feature",
  "branchName": "ralph/performance",
  "baseBranch": "main",
  "description": "Performance audit and optimization",
  "userStories": []
}
```

### Frontend Performance Stories

#### Category 1: Bundle Analysis (Priority 1)

```json
{
  "id": "PERF-FE-BUNDLE-001",
  "title": "Analyze and optimize JavaScript bundles",
  "description": "Reduce bundle size and improve loading performance",
  "acceptanceCriteria": [
    "IDENTIFY: Run bundle analyzer to visualize dependencies",
    "IDENTIFY: Find largest dependencies by size",
    "IDENTIFY: Find duplicate dependencies",
    "IDENTIFY: Find unused exports (tree-shaking opportunities)",
    "FIX: Replace heavy dependencies with lighter alternatives",
    "FIX: Enable tree-shaking in build config",
    "FIX: Remove unused dependencies from package.json",
    "FIX: Split large dependencies into separate chunks",
    "VERIFY: Bundle size reduced by at least 20%",
    "VERIFY: No duplicate dependencies in bundle",
    "DOCUMENT: Log bundle size before/after in PERF_CHANGELOG.md"
  ],
  "files": ["package.json", "webpack.config.*", "vite.config.*", "next.config.*"],
  "dependsOn": [],
  "priority": 1,
  "passes": false,
  "category": "frontend-bundle"
}
```

#### Category 2: Code Splitting (Priority 2)

```json
{
  "id": "PERF-FE-SPLIT-001",
  "title": "Implement code splitting and lazy loading",
  "description": "Split code to reduce initial bundle size",
  "acceptanceCriteria": [
    "IDENTIFY: Find routes that can be lazy-loaded",
    "IDENTIFY: Find large components not needed on initial load",
    "IDENTIFY: Find conditional features (admin, premium)",
    "FIX: Implement route-based code splitting",
    "FIX: Add React.lazy/dynamic imports for large components",
    "FIX: Add loading states for lazy components",
    "FIX: Prefetch critical routes on hover/viewport",
    "VERIFY: Initial bundle reduced significantly",
    "VERIFY: Lazy chunks load correctly",
    "VERIFY: Loading states provide good UX"
  ],
  "files": ["src/routes/", "src/App.*"],
  "dependsOn": ["PERF-FE-BUNDLE-001"],
  "priority": 2,
  "passes": false,
  "category": "frontend-splitting"
}
```

#### Category 3: Image Optimization (Priority 3)

```json
{
  "id": "PERF-FE-IMG-001",
  "title": "Optimize images and media",
  "description": "Reduce image sizes and implement lazy loading",
  "acceptanceCriteria": [
    "IDENTIFY: Find all images and their sizes",
    "IDENTIFY: Check for unoptimized images (>100KB)",
    "IDENTIFY: Check for missing responsive images",
    "FIX: Convert images to WebP/AVIF format",
    "FIX: Add srcset for responsive images",
    "FIX: Implement lazy loading for below-fold images",
    "FIX: Add width/height attributes to prevent CLS",
    "FIX: Use next/image or equivalent for optimization",
    "VERIFY: No images over 100KB without justification",
    "VERIFY: LCP image is prioritized (no lazy load)",
    "VERIFY: CLS score improved"
  ],
  "files": ["src/**/*.tsx", "public/images/"],
  "dependsOn": ["PERF-FE-SPLIT-001"],
  "priority": 3,
  "passes": false,
  "category": "frontend-images"
}
```

#### Category 4: Core Web Vitals (Priority 4)

```json
{
  "id": "PERF-FE-CWV-001",
  "title": "Optimize Core Web Vitals",
  "description": "Improve LCP, FID, and CLS metrics",
  "acceptanceCriteria": [
    "IDENTIFY: Run Lighthouse and identify CWV issues",
    "IDENTIFY: Find render-blocking resources",
    "IDENTIFY: Find layout shifts",
    "FIX: Inline critical CSS",
    "FIX: Defer non-critical CSS",
    "FIX: Add font-display: swap for web fonts",
    "FIX: Preload LCP image/resource",
    "FIX: Reserve space for dynamic content (ads, embeds)",
    "FIX: Optimize JavaScript execution (defer, async)",
    "VERIFY: LCP < 2.5s on mobile 3G",
    "VERIFY: FID < 100ms",
    "VERIFY: CLS < 0.1"
  ],
  "files": ["src/", "public/index.html"],
  "dependsOn": ["PERF-FE-IMG-001"],
  "priority": 4,
  "passes": false,
  "category": "frontend-cwv"
}
```

### Backend Performance Stories

#### Category 5: API Performance (Priority 5)

```json
{
  "id": "PERF-BE-API-001",
  "title": "Optimize API response times",
  "description": "Profile and optimize slow API endpoints",
  "acceptanceCriteria": [
    "IDENTIFY: Find slowest API endpoints from logs/monitoring",
    "IDENTIFY: Profile each slow endpoint to find bottleneck",
    "IDENTIFY: Check for N+1 query patterns",
    "FIX: Add database indexes for slow queries",
    "FIX: Implement query batching to fix N+1",
    "FIX: Add response caching where appropriate",
    "FIX: Optimize serialization (select only needed fields)",
    "FIX: Add pagination for large result sets",
    "VERIFY: p50 response time < target",
    "VERIFY: p99 response time < target",
    "DOCUMENT: Log improvements in PERF_CHANGELOG.md"
  ],
  "files": ["src/api/", "src/routes/"],
  "dependsOn": [],
  "priority": 5,
  "passes": false,
  "category": "backend-api"
}
```

#### Category 6: Database Optimization (Priority 6)

```json
{
  "id": "PERF-BE-DB-001",
  "title": "Optimize database queries",
  "description": "Profile and optimize slow database queries",
  "acceptanceCriteria": [
    "IDENTIFY: Enable query logging to find slow queries",
    "IDENTIFY: Run EXPLAIN on slow queries",
    "IDENTIFY: Check for missing indexes",
    "IDENTIFY: Find full table scans",
    "FIX: Add indexes for frequent WHERE/JOIN columns",
    "FIX: Add composite indexes for multi-column queries",
    "FIX: Optimize query structure (avoid SELECT *)",
    "FIX: Add query result caching for expensive queries",
    "FIX: Consider denormalization for read-heavy data",
    "VERIFY: Slow query log shows improvement",
    "VERIFY: No full table scans on large tables",
    "DOCUMENT: Document added indexes"
  ],
  "files": ["prisma/schema.prisma", "src/models/", "migrations/"],
  "dependsOn": ["PERF-BE-API-001"],
  "priority": 6,
  "passes": false,
  "category": "backend-database"
}
```

#### Category 7: Caching Strategy (Priority 7)

```json
{
  "id": "PERF-BE-CACHE-001",
  "title": "Implement caching strategy",
  "description": "Add caching layers to reduce load and latency",
  "acceptanceCriteria": [
    "IDENTIFY: Find cacheable data (static, infrequently changing)",
    "IDENTIFY: Find expensive computations that can be cached",
    "IDENTIFY: Analyze cache hit/miss opportunities",
    "FIX: Add HTTP caching headers (ETag, Cache-Control)",
    "FIX: Implement in-memory caching for hot data",
    "FIX: Add Redis/Memcached for distributed caching",
    "FIX: Implement cache invalidation strategy",
    "FIX: Add cache warming for critical data",
    "VERIFY: Cache hit rate > 80% for cacheable endpoints",
    "VERIFY: Response times improved",
    "DOCUMENT: Document caching strategy"
  ],
  "files": ["src/cache/", "src/middleware/"],
  "dependsOn": ["PERF-BE-DB-001"],
  "priority": 7,
  "passes": false,
  "category": "backend-caching"
}
```

#### Category 8: Memory & CPU (Priority 8)

```json
{
  "id": "PERF-BE-MEM-001",
  "title": "Optimize memory and CPU usage",
  "description": "Profile and reduce resource consumption",
  "acceptanceCriteria": [
    "IDENTIFY: Profile memory usage under load",
    "IDENTIFY: Find memory leaks",
    "IDENTIFY: Find CPU-intensive operations",
    "FIX: Fix memory leaks (event listeners, closures)",
    "FIX: Implement streaming for large data sets",
    "FIX: Move CPU-intensive work to background jobs",
    "FIX: Add connection pooling for external services",
    "FIX: Optimize garbage collection (if applicable)",
    "VERIFY: Memory usage stable under load",
    "VERIFY: No memory leaks in 24hr test",
    "VERIFY: CPU usage within acceptable range"
  ],
  "files": ["src/"],
  "dependsOn": ["PERF-BE-CACHE-001"],
  "priority": 8,
  "passes": false,
  "category": "backend-resources"
}
```

### Final Verification

#### Category 9: Performance Testing (Priority 9)

```json
{
  "id": "PERF-TEST-001",
  "title": "Implement performance testing",
  "description": "Add automated performance tests and monitoring",
  "acceptanceCriteria": [
    "FIX: Add Lighthouse CI to build pipeline",
    "FIX: Set performance budgets (bundle size, CWV)",
    "FIX: Add load testing scripts (k6, artillery)",
    "FIX: Configure performance monitoring (if not present)",
    "FIX: Add performance regression tests",
    "VERIFY: CI fails on performance budget violations",
    "VERIFY: Load tests pass target RPS",
    "DOCUMENT: Document performance testing in README"
  ],
  "files": [".github/workflows/", "tests/performance/"],
  "dependsOn": ["PERF-BE-MEM-001"],
  "priority": 9,
  "passes": false,
  "category": "testing"
}
```

#### Category 10: Final Verification (Priority 10)

```json
{
  "id": "PERF-FIN-001",
  "title": "Final performance verification",
  "description": "Comprehensive performance validation",
  "acceptanceCriteria": [
    "VERIFY: Lighthouse performance score > 90",
    "VERIFY: Core Web Vitals all green",
    "VERIFY: Bundle size within budget",
    "VERIFY: API p50 < target",
    "VERIFY: API p99 < target",
    "VERIFY: Load test passes",
    "VERIFY: No memory leaks",
    "DOCUMENT: Create PERF_CHANGELOG.md with all improvements",
    "DOCUMENT: Update README with performance characteristics",
    "DOCUMENT: Add performance monitoring dashboard link"
  ],
  "files": ["PERF_CHANGELOG.md", "README.md"],
  "dependsOn": ["PERF-TEST-001"],
  "priority": 10,
  "passes": false,
  "category": "verification"
}
```

## Phase 4: Performance Optimization Checklist

### Frontend
- [ ] Bundle size < 200KB gzipped (initial)
- [ ] Code splitting for routes
- [ ] Lazy loading for images
- [ ] Optimized images (WebP, srcset)
- [ ] Critical CSS inlined
- [ ] Fonts optimized (preload, font-display)
- [ ] No render-blocking resources
- [ ] Service worker for caching

### Backend
- [ ] Database indexes optimized
- [ ] No N+1 queries
- [ ] Response caching
- [ ] Connection pooling
- [ ] Async operations for I/O
- [ ] Pagination for large sets
- [ ] Compression enabled (gzip/brotli)

### Database
- [ ] Indexes on frequent queries
- [ ] Query optimization (no SELECT *)
- [ ] Connection pooling
- [ ] Read replicas for heavy reads
- [ ] Query caching

## Phase 5: Output

Generate `prd.json` based on focus area:
- `frontend`: Bundle, splitting, images, CWV
- `backend`: API, database, caching, memory
- `database`: Query optimization, indexing, caching
- `all`: All of the above

Create `PERF_CHANGELOG.md`:
```markdown
# Performance Changelog

## Optimizations Applied

### Bundle Size
| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Initial JS | X KB | Y KB | -Z% |
| Total JS | X KB | Y KB | -Z% |

### Core Web Vitals
| Metric | Before | After | Target |
|--------|--------|-------|--------|
| LCP | Xs | Ys | <2.5s |
| FID | Xms | Yms | <100ms |
| CLS | X | Y | <0.1 |

### API Performance
| Endpoint | p50 Before | p50 After | p99 Before | p99 After |
|----------|------------|-----------|------------|-----------|
| GET /api/x | Xms | Yms | Xms | Yms |

### Database
| Query | Before | After | Index Added |
|-------|--------|-------|-------------|
| X | Xms | Yms | idx_name |

## Recommendations Not Implemented
- [List any recommendations that were deferred]
```
