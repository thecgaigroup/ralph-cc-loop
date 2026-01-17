---
name: architecture-review
description: Comprehensive architecture review with recommendations for local, cloud, and service design. Use when asked to "review architecture", "architecture audit", "suggest improvements", "cloud architecture", or "system design review".
arguments: "<project_path> [--focus local|cloud|services|all] [--cloud aws|gcp|azure] | --help"
---

# Help Check

If the user passed `--help` as an argument, output the following and stop:

```
/architecture-review - Comprehensive architecture analysis and recommendations

Usage:
  claude /architecture-review <project_path> [options]
  claude /architecture-review --help

Arguments:
  project_path           Path to the project (required)

Options:
  --focus <area>         Focus area: local, cloud, services, all (default: all)
  --cloud <provider>     Cloud provider context: aws, gcp, azure (default: aws)
  --output <file>        Output file (default: ARCHITECTURE_REVIEW.md)
  --help                 Show this help message

Focus Areas:
  local      Code structure, patterns, modularity, dependencies
  cloud      Infrastructure, scaling, cost optimization, managed services
  services   API design, microservices, data flow, integrations
  all        Complete review of all areas

Examples:
  claude /architecture-review ~/Projects/my-app
  claude /architecture-review ~/Projects/my-app --focus cloud --cloud aws
  claude /architecture-review ~/Projects/my-app --focus services

What it analyzes:
  Local Architecture:
    - Project structure and organization
    - Design patterns and anti-patterns
    - Dependency management
    - Code modularity and coupling
    - Error handling patterns
    - Testing architecture

  Cloud Architecture:
    - Current infrastructure (IaC analysis)
    - Scaling strategy and bottlenecks
    - Cost optimization opportunities
    - Managed service recommendations
    - Security architecture
    - Disaster recovery

  Service Architecture:
    - API design and consistency
    - Data flow and state management
    - Service boundaries (if microservices)
    - Integration patterns
    - Event-driven opportunities
    - Caching strategy

Output:
  - ARCHITECTURE_REVIEW.md: Detailed analysis with diagrams
  - Prioritized recommendations
  - Migration roadmap (if applicable)
```

---

# Architecture Review

You are a senior solutions architect conducting a comprehensive architecture review. This skill:
1. Analyzes current project architecture
2. Identifies strengths and weaknesses
3. Recommends improvements with rationale
4. Provides migration paths and priorities

## Architecture Quality Dimensions

| Dimension | Description |
|-----------|-------------|
| **Scalability** | Can the system handle 10x load? |
| **Reliability** | What happens when components fail? |
| **Maintainability** | How easy is it to change? |
| **Security** | Defense in depth, least privilege |
| **Performance** | Response times, throughput |
| **Cost Efficiency** | Resource utilization, right-sizing |
| **Observability** | Monitoring, logging, tracing |
| **Developer Experience** | Onboarding, local dev, debugging |

## Phase 1: Discovery

### Step 1.1: Navigate and Inventory

```bash
cd [project_path] && pwd

# Get project structure
find . -type f -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" | head -100
find . -type d -not -path "*/node_modules/*" -not -path "*/.git/*" | head -50

# Check for infrastructure
ls -la terraform/ cdk/ cloudformation/ pulumi/ serverless.yml docker-compose.yml Dockerfile 2>/dev/null
```

### Step 1.2: Identify Tech Stack

```bash
# Languages and frameworks
cat package.json pyproject.toml go.mod Cargo.toml 2>/dev/null

# Databases
grep -r "mongoose\|prisma\|typeorm\|sequelize\|knex" package.json 2>/dev/null
grep -r "sqlalchemy\|django\|peewee" requirements.txt 2>/dev/null

# Message queues
grep -r "amqp\|bull\|kafka\|sqs\|pubsub\|redis" package.json 2>/dev/null

# Cloud services
cat serverless.yml cdk.json 2>/dev/null | head -50
```

### Step 1.3: Determine Architecture Style

Identify primary architecture:
- **Monolith**: Single deployable unit
- **Modular Monolith**: Monolith with clear module boundaries
- **Microservices**: Multiple independent services
- **Serverless**: Function-based (Lambda, Cloud Functions)
- **Hybrid**: Mix of the above

## Phase 2: Local Architecture Review (if focus includes local)

### Step 2.1: Project Structure Analysis

Evaluate against best practices:

**Good Structure Indicators:**
```
src/
├── modules/           # Feature-based organization
│   ├── users/
│   │   ├── users.controller.ts
│   │   ├── users.service.ts
│   │   ├── users.repository.ts
│   │   └── users.types.ts
│   └── orders/
├── shared/            # Cross-cutting concerns
│   ├── middleware/
│   ├── utils/
│   └── types/
├── infrastructure/    # External service adapters
│   ├── database/
│   ├── cache/
│   └── messaging/
└── config/           # Configuration management
```

**Anti-Pattern Indicators:**
- `utils/` with 50+ files (god folder)
- Circular dependencies between modules
- Business logic in controllers
- No clear separation of concerns
- Mixed infrastructure and domain code

### Step 2.2: Dependency Analysis

```bash
# Check for circular dependencies
npx madge --circular src/

# Analyze dependency graph
npx madge --image graph.svg src/

# Check coupling
npx dependency-cruiser --output-type err-long src/
```

Evaluate:
- Are dependencies flowing in the right direction?
- Is the domain layer independent of infrastructure?
- Are there hidden dependencies through globals?

### Step 2.3: Design Patterns Assessment

Look for appropriate use of:

| Pattern | When to Use | Signs of Misuse |
|---------|-------------|-----------------|
| Repository | Data access abstraction | Leaking ORM queries |
| Service Layer | Business logic | Anemic services, fat controllers |
| Factory | Complex object creation | Overused for simple objects |
| Strategy | Swappable algorithms | Used where if/else suffices |
| Observer/Event | Decoupling | Event spaghetti |
| Dependency Injection | Testability, flexibility | Over-abstraction |

### Step 2.4: Error Handling Review

Check for:
- Consistent error types/classes
- Proper error propagation
- Error boundaries at service edges
- Meaningful error messages
- No swallowed exceptions
- Retry logic where appropriate

### Step 2.5: Testing Architecture

Evaluate test structure:
- Unit tests for business logic
- Integration tests for services
- E2E tests for critical paths
- Test isolation (no shared state)
- Mock strategy (over-mocking vs under-mocking)
- Test coverage in critical paths

## Phase 3: Cloud Architecture Review (if focus includes cloud)

### Step 3.1: Infrastructure Analysis

If IaC exists, analyze:

```bash
# Terraform
cat terraform/*.tf | grep -E "resource|module"

# CDK
cat lib/*.ts | grep -E "new.*\(" | head -30

# Serverless
cat serverless.yml | grep -E "functions:|resources:"
```

### Step 3.2: Compute Architecture

Evaluate current compute:

| Type | Pros | Cons | Best For |
|------|------|------|----------|
| EC2/VMs | Full control | Ops overhead | Stateful, special requirements |
| Containers (ECS/EKS) | Portable, efficient | Complexity | Microservices, consistent workloads |
| Serverless (Lambda) | No ops, scales to zero | Cold starts, limits | Event-driven, variable load |
| App Runner/Fargate | Balanced | Less control | Web apps, APIs |

Recommendations based on:
- Traffic patterns (steady vs spiky)
- Execution time requirements
- State management needs
- Cost profile

### Step 3.3: Database Architecture

Evaluate data layer:

| Current | Consider | When |
|---------|----------|------|
| Self-managed DB | RDS/Cloud SQL | Ops burden, backups |
| RDS Single | RDS Multi-AZ | Production, HA required |
| SQL for everything | DynamoDB/Firestore | High scale, simple access patterns |
| No caching | ElastiCache/Redis | Repeated queries, sessions |
| Single region | Global Tables | Multi-region requirements |

### Step 3.4: Scaling Strategy

Analyze scaling approach:

**Vertical Scaling Issues:**
- Single point of failure
- Scaling limits
- Downtime during scaling

**Horizontal Scaling Requirements:**
- Stateless application design
- Session management (external store)
- Database connection pooling
- Load balancer configuration

**Auto-scaling Recommendations:**
- Target tracking policies
- Scheduled scaling for known patterns
- Queue-based scaling for async work

### Step 3.5: Cost Optimization

Identify opportunities:

| Area | Optimization |
|------|-------------|
| Compute | Right-sizing, Reserved/Spot instances |
| Database | Reserved capacity, storage tiering |
| Storage | Lifecycle policies, intelligent tiering |
| Transfer | VPC endpoints, CloudFront |
| Lambda | Memory optimization, provisioned concurrency |
| Idle Resources | Scheduled shutdown, cleanup |

### Step 3.6: Security Architecture

Review:
- Network isolation (VPC, subnets, security groups)
- Secrets management (Secrets Manager, Parameter Store)
- IAM policies (least privilege)
- Encryption (at rest, in transit)
- WAF and DDoS protection
- Audit logging (CloudTrail)

### Step 3.7: Disaster Recovery

Assess:
- Backup strategy and frequency
- RTO (Recovery Time Objective)
- RPO (Recovery Point Objective)
- Multi-region strategy
- Failover testing

## Phase 4: Service Architecture Review (if focus includes services)

### Step 4.1: API Design Analysis

Evaluate API consistency:

**REST Best Practices:**
- Resource-based URLs
- Proper HTTP methods
- Consistent response formats
- Pagination patterns
- Error response structure
- Versioning strategy

**Common Issues:**
- Verbs in URLs (`/getUsers` vs `/users`)
- Inconsistent naming (camelCase vs snake_case)
- Over-fetching / under-fetching
- No pagination on list endpoints
- Breaking changes without versioning

### Step 4.2: Service Boundaries

For microservices, evaluate:

**Good Boundaries:**
- Single responsibility
- Own their data
- Can be deployed independently
- Clear public interface
- Minimal synchronous dependencies

**Anti-Patterns:**
- Distributed monolith (tight coupling)
- Shared databases
- Synchronous chains
- Data duplication without sync strategy
- Chatty services (many calls for one operation)

### Step 4.3: Data Flow Analysis

Map data flow:
1. How does data enter the system?
2. How is it transformed and enriched?
3. Where is it stored?
4. How is it accessed/queried?
5. How does it leave the system?

Identify:
- Bottlenecks
- Single points of failure
- Data consistency challenges
- Caching opportunities

### Step 4.4: Integration Patterns

Evaluate integrations:

| Pattern | Use Case | Considerations |
|---------|----------|----------------|
| Sync REST | Simple CRUD, low latency needed | Coupling, failure handling |
| Async Events | Decoupling, eventual consistency OK | Debugging, ordering |
| Message Queue | Work distribution, buffering | Complexity, monitoring |
| GraphQL | Flexible client needs | Caching, N+1 queries |
| gRPC | Internal services, performance | Browser support, debugging |

### Step 4.5: Event-Driven Opportunities

Identify candidates for event-driven:
- Notifications (email, push, SMS)
- Analytics and tracking
- Audit logging
- Cache invalidation
- Cross-service updates
- Long-running processes

### Step 4.6: Caching Strategy

Review caching layers:

| Layer | Technology | Use Case |
|-------|------------|----------|
| CDN | CloudFront, Cloudflare | Static assets, API responses |
| Application | Redis, Memcached | Session, computed data |
| Database | Query cache, materialized views | Expensive queries |
| Client | Browser cache, service worker | Offline, reduce requests |

## Phase 5: Generate Report

Create `ARCHITECTURE_REVIEW.md`:

```markdown
# Architecture Review

**Project:** [name]
**Review Date:** [date]
**Reviewer:** Claude Architecture Review
**Focus:** [local|cloud|services|all]

---

## Executive Summary

### Overall Health Score: [A-F]

| Dimension | Score | Status |
|-----------|-------|--------|
| Scalability | B+ | Good, some bottlenecks |
| Reliability | B | Needs HA improvements |
| Maintainability | A- | Well-structured |
| Security | B | Missing some controls |
| Performance | B+ | Caching opportunities |
| Cost Efficiency | C+ | Over-provisioned |
| Observability | C | Minimal monitoring |
| Developer Experience | A | Excellent local dev |

### Top 3 Priorities
1. **[HIGH]** Implement database read replicas for scalability
2. **[HIGH]** Add application-level caching layer
3. **[MEDIUM]** Containerize for consistent deployments

---

## Current Architecture

### Architecture Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Client    │────▶│   API GW    │────▶│   Lambda    │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌──────────────────────────┼──────────────────────────┐
                    │                          ▼                          │
              ┌─────┴─────┐            ┌─────────────┐            ┌──────┴──────┐
              │   Redis   │            │   RDS       │            │   S3        │
              │  (Cache)  │            │  (Primary)  │            │  (Storage)  │
              └───────────┘            └─────────────┘            └─────────────┘
```

### Tech Stack
- **Runtime:** Node.js 18 (Lambda)
- **Framework:** Express.js
- **Database:** PostgreSQL (RDS)
- **Cache:** None currently
- **Queue:** None currently
- **Storage:** S3

### Strengths
- ✅ Clean modular code structure
- ✅ Good separation of concerns
- ✅ Comprehensive test coverage
- ✅ Infrastructure as Code (CDK)

### Weaknesses
- ❌ No caching layer
- ❌ Single database instance
- ❌ Limited monitoring
- ❌ No async processing

---

## Detailed Findings

### Local Architecture

#### [STRENGTH] Modular Code Structure
The codebase follows a clean modular architecture with clear boundaries...

#### [ISSUE] Circular Dependencies
Found 3 circular dependency chains...

**Current:**
```
modules/orders → modules/users → modules/orders
```

**Recommendation:**
Extract shared types to a common module...

---

### Cloud Architecture

#### [ISSUE] Database Scalability
Single RDS instance without read replicas...

**Current State:**
- Single db.t3.medium instance
- No read replicas
- No connection pooling

**Recommendation:**
```
                    ┌─────────────────┐
                    │   Application   │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │  RDS Proxy      │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌─────────┐   ┌─────────┐   ┌─────────┐
        │ Primary │   │ Replica │   │ Replica │
        └─────────┘   └─────────┘   └─────────┘
```

**Migration Steps:**
1. Enable Multi-AZ on existing RDS
2. Add RDS Proxy for connection pooling
3. Create read replica
4. Update application to use replica for reads

**Estimated Cost Impact:** +$150/month

---

### Service Architecture

#### [OPPORTUNITY] Event-Driven Processing
Current synchronous notification sending could be async...

---

## Recommendations

### Immediate (1-2 weeks)
| # | Recommendation | Effort | Impact |
|---|---------------|--------|--------|
| 1 | Add Redis caching layer | Medium | High |
| 2 | Implement health checks | Low | Medium |
| 3 | Add structured logging | Low | Medium |

### Short-term (1-2 months)
| # | Recommendation | Effort | Impact |
|---|---------------|--------|--------|
| 4 | Database read replicas | Medium | High |
| 5 | Async notification queue | Medium | Medium |
| 6 | Container migration | High | Medium |

### Long-term (3-6 months)
| # | Recommendation | Effort | Impact |
|---|---------------|--------|--------|
| 7 | Service mesh evaluation | High | Medium |
| 8 | Multi-region deployment | High | High |

---

## Proposed Architecture

```
                              ┌─────────────┐
                              │ CloudFront  │
                              └──────┬──────┘
                                     │
┌─────────────┐              ┌──────┴──────┐              ┌─────────────┐
│   Route53   │─────────────▶│    ALB      │─────────────▶│    ECS      │
└─────────────┘              └─────────────┘              └──────┬──────┘
                                                                 │
       ┌─────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┐
       │                                                         │                                                         │
       ▼                                                         ▼                                                         ▼
┌─────────────┐                                          ┌─────────────┐                                          ┌─────────────┐
│ ElastiCache │                                          │ RDS Proxy   │                                          │    SQS      │
│   (Redis)   │                                          └──────┬──────┘                                          └──────┬──────┘
└─────────────┘                                                 │                                                         │
                                                    ┌───────────┼───────────┐                                            │
                                                    ▼           ▼           ▼                                            ▼
                                              ┌─────────┐ ┌─────────┐ ┌─────────┐                                 ┌─────────────┐
                                              │ Primary │ │ Replica │ │ Replica │                                 │   Lambda    │
                                              └─────────┘ └─────────┘ └─────────┘                                 │  (Workers)  │
                                                                                                                   └─────────────┘
```

---

## Appendix

### Cost Comparison

| Item | Current | Proposed | Change |
|------|---------|----------|--------|
| Compute | $200 | $250 | +$50 |
| Database | $150 | $350 | +$200 |
| Cache | $0 | $50 | +$50 |
| **Total** | **$350** | **$650** | **+$300** |

*Note: Proposed architecture handles 5x current load*

### Reference Architectures
- [AWS Well-Architected](https://aws.amazon.com/architecture/well-architected/)
- [12-Factor App](https://12factor.net/)
```

## Phase 6: Output

### Summary

```
Architecture Review Complete
--------------------------------------------------

Project:     [name]
Focus:       [local|cloud|services|all]
Cloud:       [aws|gcp|azure]

Health Score: B+

Findings:
  Strengths:    X
  Issues:       X
  Opportunities: X

Top Recommendations:
  1. [HIGH] Add caching layer
  2. [HIGH] Database scaling
  3. [MEDIUM] Async processing

Output: ARCHITECTURE_REVIEW.md
```
