---
name: security-audit
description: Run a comprehensive security audit on any project. Scans for vulnerabilities, secrets, insecure patterns, and OWASP Top 10 issues. Use when asked to "security audit", "check security", "find vulnerabilities", or "security review".
arguments: "<project_path> [--level basic|standard|thorough] [--fix] | --help"
---

# Help Check

If the user passed `--help` as an argument, output the following and stop:

```
/security-audit - Comprehensive security audit and remediation

Usage:
  claude /security-audit <project_path> [options]
  claude /security-audit --help

Arguments:
  project_path           Path to the project to audit (required)

Options:
  --level <level>        Audit depth: basic, standard (default), thorough
  --fix                  Auto-fix issues where safe (default: report only)
  --help                 Show this help message

Levels:
  basic      Quick scan: secrets, dependencies, obvious issues (5-10 min)
  standard   Full scan: OWASP Top 10, auth, input validation (15-30 min)
  thorough   Deep scan: All standard + code flow analysis, threat modeling (30-60 min)

Examples:
  claude /security-audit ~/Projects/my-app
  claude /security-audit ~/Projects/my-app --level thorough
  claude /security-audit ~/Projects/my-app --fix
  claude /security-audit ~/Projects/api --level basic

What it audits:
  - Secrets & credentials (hardcoded keys, tokens, passwords)
  - Dependency vulnerabilities (npm audit, pip audit, etc.)
  - OWASP Top 10 (injection, XSS, broken auth, etc.)
  - Authentication & authorization patterns
  - Input validation & sanitization
  - Cryptographic practices
  - Security headers & CORS
  - Error handling & information disclosure
  - File upload security
  - API security

Remediation tiers:
  - Auto-fix: Safe changes (gitignore, env.example, simple sanitization)
  - Fix+confirm: Moderate changes (dependency updates, config changes)
  - Manual: Documents with clear instructions (credential rotation, architecture)

Output files:
  - SECURITY_AUDIT.md: Detailed findings with severity ratings
  - prd.json: Remediation stories for Ralph (if --fix used)
```

---

# Security Audit - Comprehensive Security Review

You are a security expert conducting a comprehensive security audit. This skill:
1. Takes a **local project path** (the codebase to audit)
2. Scans for security vulnerabilities and insecure patterns
3. Generates a detailed security report
4. Optionally creates remediation stories for Ralph

## Severity Definitions

| Severity | Definition | Response Time | Example |
|----------|-----------|---------------|---------|
| **CRITICAL** | Active exploitation risk, data breach imminent | Immediate | Hardcoded production credentials, SQL injection |
| **HIGH** | Significant security risk, likely exploitable | 24-48 hours | Missing auth on admin routes, XSS vulnerabilities |
| **MEDIUM** | Security weakness, requires specific conditions | 1-2 weeks | Outdated deps with known CVEs, weak crypto |
| **LOW** | Minor issue, defense in depth | Next sprint | Missing security headers, verbose errors |
| **INFO** | Best practice recommendation | Backlog | Code quality, documentation |

## Phase 1: Project Discovery

### Step 1.1: Locate Project

If `[project_path]` provided, use it. Otherwise, use current working directory.

Verify the path exists:
```bash
cd [project_path] && pwd
```

### Step 1.2: Detect Project Type & Stack

```bash
# Identify languages and frameworks
ls package.json pyproject.toml requirements.txt Cargo.toml go.mod pom.xml Gemfile composer.json 2>/dev/null

# Check for framework indicators
cat package.json 2>/dev/null | jq '.dependencies | keys[]' | grep -E 'express|fastify|next|react|vue|angular|nest|koa'
cat requirements.txt 2>/dev/null | grep -E 'django|flask|fastapi|tornado'
ls -la Dockerfile docker-compose.yml 2>/dev/null

# Check for security tools already in place
cat package.json 2>/dev/null | jq '.devDependencies | keys[]' | grep -E 'eslint-plugin-security|snyk|helmet|csurf'
```

### Step 1.3: Identify Audit Scope

Based on project type, determine which checks apply:

| Project Type | Key Security Concerns |
|-------------|----------------------|
| **Web App (Frontend)** | XSS, CSRF, sensitive data exposure, dependency vulns |
| **Web App (Backend)** | Injection, auth, access control, API security, secrets |
| **Full-Stack** | All of the above |
| **API Only** | Auth, rate limiting, input validation, data exposure |
| **CLI Tool** | Command injection, file handling, credential storage |
| **Library** | Dependency chain, input validation, safe defaults |

## Phase 2: Security Scans

### 2.1: Secrets & Credentials Scan (All Projects)

**CRITICAL priority - run first**

```bash
# Check for hardcoded secrets patterns
grep -rn --include="*.js" --include="*.ts" --include="*.py" --include="*.go" --include="*.java" --include="*.rb" \
  -E "(password|passwd|pwd|secret|api_key|apikey|api-key|token|auth|credential|private_key).*['\"][^'\"]{8,}['\"]" \
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor 2>/dev/null | head -50

# Check for AWS keys
grep -rn "AKIA[0-9A-Z]{16}" --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null

# Check for private keys
find . -name "*.pem" -o -name "*.key" -o -name "id_rsa" -o -name "id_ed25519" 2>/dev/null | grep -v node_modules

# Check .env files for committed secrets
git ls-files | grep -E "\.env$|\.env\." | head -10

# Check git history for secrets (basic)
git log --oneline --all -p 2>/dev/null | grep -E "(password|secret|api_key|token).*=" | head -20
```

**Findings to report:**
- Hardcoded credentials in source code
- API keys, tokens, or passwords in config files
- Private keys in repository
- .env files committed to git
- Secrets in git history

### 2.2: Dependency Vulnerability Scan (All Projects)

```bash
# Node.js
npm audit --json 2>/dev/null | jq '.vulnerabilities | to_entries | map({name: .key, severity: .value.severity, via: .value.via[0]}) | sort_by(.severity)'

# Python
pip audit 2>/dev/null || safety check 2>/dev/null

# Go
go list -m all 2>/dev/null && govulncheck ./... 2>/dev/null

# Ruby
bundle audit check 2>/dev/null

# PHP
composer audit 2>/dev/null
```

**Findings to report:**
- Critical/High severity vulnerabilities
- Number of total vulnerabilities by severity
- Outdated packages with known CVEs
- Unmaintained dependencies

### 2.3: OWASP Top 10 Scan (Web Apps)

#### A01: Broken Access Control
```bash
# Find routes/endpoints without auth middleware
grep -rn --include="*.js" --include="*.ts" --include="*.py" \
  -E "(app\.(get|post|put|delete|patch)|router\.(get|post|put|delete|patch)|@(Get|Post|Put|Delete))" \
  --exclude-dir=node_modules 2>/dev/null | head -30

# Check for direct object references
grep -rn --include="*.js" --include="*.ts" --include="*.py" \
  -E "params\.(id|userId|user_id)|req\.params\.[a-z]+[Ii]d" \
  --exclude-dir=node_modules 2>/dev/null | head -20
```

#### A02: Cryptographic Failures
```bash
# Check for weak crypto
grep -rn --include="*.js" --include="*.ts" --include="*.py" --include="*.go" \
  -E "(md5|sha1|DES|RC4|Math\.random)" \
  --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | head -20

# Check for hardcoded IVs/salts
grep -rn -E "(iv|IV|salt|SALT).*['\"][a-f0-9]{16,}['\"]" \
  --exclude-dir=node_modules 2>/dev/null | head -10
```

#### A03: Injection
```bash
# SQL injection patterns
grep -rn --include="*.js" --include="*.ts" --include="*.py" \
  -E "(query|execute|exec)\s*\(\s*[\"'\`].*\+|f[\"'].*SELECT|\.format\(.*SELECT" \
  --exclude-dir=node_modules 2>/dev/null | head -20

# Command injection patterns
grep -rn --include="*.js" --include="*.ts" --include="*.py" \
  -E "(exec|spawn|system|popen|subprocess)\s*\([^)]*\+" \
  --exclude-dir=node_modules 2>/dev/null | head -20

# NoSQL injection
grep -rn --include="*.js" --include="*.ts" \
  -E "\$where|\$regex.*\+" \
  --exclude-dir=node_modules 2>/dev/null | head -10
```

#### A04: Insecure Design
- Check for security controls in architecture
- Review authentication flow
- Check authorization model

#### A05: Security Misconfiguration
```bash
# Check for debug mode in production configs
grep -rn -E "(DEBUG|debug).*[Tt]rue" --include="*.json" --include="*.yml" --include="*.yaml" --include="*.env*" 2>/dev/null | head -10

# Check CORS configuration
grep -rn -E "cors|Access-Control-Allow-Origin" --include="*.js" --include="*.ts" --include="*.py" \
  --exclude-dir=node_modules 2>/dev/null | head -10

# Check for wildcard CORS
grep -rn "Access-Control-Allow-Origin.*\*" --exclude-dir=node_modules 2>/dev/null
```

#### A06: Vulnerable Components
(Covered in 2.2 Dependency Scan)

#### A07: Authentication Failures
```bash
# Check password handling
grep -rn --include="*.js" --include="*.ts" --include="*.py" \
  -E "(password|passwd).*=.*req\.|password.*plain|bcrypt\.compare|argon2|pbkdf2" \
  --exclude-dir=node_modules 2>/dev/null | head -20

# Check session configuration
grep -rn -E "(session|cookie).*secure|httpOnly|sameSite" \
  --include="*.js" --include="*.ts" --exclude-dir=node_modules 2>/dev/null | head -10

# Check for JWT issues
grep -rn -E "algorithm.*none|jwt\.decode\(|verify.*false" \
  --include="*.js" --include="*.ts" --exclude-dir=node_modules 2>/dev/null
```

#### A08: Software & Data Integrity
```bash
# Check for eval/exec of user input
grep -rn --include="*.js" --include="*.ts" --include="*.py" \
  -E "(eval|Function|exec)\s*\(" \
  --exclude-dir=node_modules 2>/dev/null | head -10

# Check deserialization
grep -rn -E "(pickle\.load|yaml\.load|unserialize|JSON\.parse.*req)" \
  --exclude-dir=node_modules 2>/dev/null | head -10
```

#### A09: Logging & Monitoring Failures
```bash
# Check for logging of sensitive data
grep -rn -E "console\.(log|info|debug).*password|logger\.(info|debug).*token" \
  --exclude-dir=node_modules 2>/dev/null | head -10

# Check for security event logging
grep -rn -E "login.*fail|auth.*error|unauthorized" \
  --exclude-dir=node_modules 2>/dev/null | head -10
```

#### A10: Server-Side Request Forgery (SSRF)
```bash
# Check for URL parameters used in requests
grep -rn --include="*.js" --include="*.ts" --include="*.py" \
  -E "(fetch|axios|request|http\.get|urllib).*req\.(body|query|params)" \
  --exclude-dir=node_modules 2>/dev/null | head -10
```

### 2.4: Input Validation (All Projects)

```bash
# Find form handlers without validation
grep -rn --include="*.js" --include="*.ts" \
  -E "req\.body\.[a-zA-Z]+" \
  --exclude-dir=node_modules 2>/dev/null | head -30

# Check for validation libraries
cat package.json 2>/dev/null | jq '.dependencies | keys[]' | grep -E 'joi|yup|zod|validator|express-validator'

# Check for sanitization
grep -rn "sanitize|escape|encode" --include="*.js" --include="*.ts" \
  --exclude-dir=node_modules 2>/dev/null | head -10
```

### 2.5: XSS Prevention (Frontend/Full-Stack)

```bash
# Check for innerHTML usage
grep -rn "innerHTML\s*=" --include="*.js" --include="*.ts" --include="*.tsx" --include="*.jsx" \
  --exclude-dir=node_modules 2>/dev/null | head -20

# Check for dangerouslySetInnerHTML
grep -rn "dangerouslySetInnerHTML" --include="*.tsx" --include="*.jsx" \
  --exclude-dir=node_modules 2>/dev/null | head -10

# Check for document.write
grep -rn "document\.write" --include="*.js" --include="*.ts" \
  --exclude-dir=node_modules 2>/dev/null

# Check for v-html (Vue)
grep -rn "v-html" --include="*.vue" 2>/dev/null | head -10
```

### 2.6: Security Headers (Web Apps)

```bash
# Check for helmet or security headers
grep -rn -E "helmet|X-Content-Type-Options|X-Frame-Options|Content-Security-Policy|Strict-Transport-Security" \
  --include="*.js" --include="*.ts" --include="*.py" \
  --exclude-dir=node_modules 2>/dev/null | head -20

# Check for HTTPS enforcement
grep -rn -E "https://|secure.*true|HSTS" \
  --include="*.js" --include="*.ts" --include="*.env*" \
  --exclude-dir=node_modules 2>/dev/null | head -10
```

### 2.7: File Upload Security (If Applicable)

```bash
# Find file upload handlers
grep -rn -E "multer|formidable|busboy|upload|multipart" \
  --include="*.js" --include="*.ts" --include="*.py" \
  --exclude-dir=node_modules 2>/dev/null | head -15

# Check for file type validation
grep -rn -E "mimetype|content-type|file\.type" \
  --include="*.js" --include="*.ts" \
  --exclude-dir=node_modules 2>/dev/null | head -10
```

### 2.8: API Security (APIs)

```bash
# Check for rate limiting
grep -rn -E "rate.*limit|throttle|express-rate-limit|slowDown" \
  --include="*.js" --include="*.ts" --include="*.py" \
  --exclude-dir=node_modules 2>/dev/null | head -10

# Check API versioning
grep -rn -E "/api/v[0-9]|/v[0-9]/" \
  --include="*.js" --include="*.ts" \
  --exclude-dir=node_modules 2>/dev/null | head -10

# Check for API key validation
grep -rn -E "x-api-key|apiKey|api_key.*header" \
  --include="*.js" --include="*.ts" \
  --exclude-dir=node_modules 2>/dev/null | head -10
```

### 2.9: Configuration Security

```bash
# Check .gitignore for sensitive files
cat .gitignore 2>/dev/null | grep -E "\.env|\.pem|\.key|credentials|secrets"

# Check for .env.example
ls .env.example .env.sample 2>/dev/null

# Check for production configs exposed
ls -la *.prod.* *.production.* 2>/dev/null
git ls-files | grep -E "prod|production" | head -10
```

## Phase 3: Generate Report

Create `SECURITY_AUDIT.md`:

```markdown
# Security Audit Report

**Project:** [name]
**Audit Date:** [date]
**Audit Level:** [basic|standard|thorough]
**Audited By:** Claude Security Audit

---

## Executive Summary

| Severity | Count | Status |
|----------|-------|--------|
| CRITICAL | X | [Needs immediate attention] |
| HIGH | X | [Action required] |
| MEDIUM | X | [Should fix] |
| LOW | X | [Consider fixing] |
| INFO | X | [Informational] |

**Overall Risk Level:** [CRITICAL/HIGH/MEDIUM/LOW]

---

## Critical Findings

### [CRIT-001] [Finding Title]

**Severity:** CRITICAL
**Category:** [Secrets/Injection/Auth/etc.]
**Location:** `file.ts:123`

**Description:**
[What the issue is]

**Evidence:**
```
[Code snippet or command output]
```

**Impact:**
[What could happen if exploited]

**Remediation:**
[How to fix it]

**References:**
- [Link to relevant documentation]

---

## High Findings

[Same format as Critical]

---

## Medium Findings

[Same format]

---

## Low Findings

[Same format]

---

## Informational

[Best practice recommendations]

---

## Remediation Priority

1. **Immediate (0-24h):** [List CRITICAL items]
2. **Short-term (1-7d):** [List HIGH items]
3. **Medium-term (1-4w):** [List MEDIUM items]
4. **Backlog:** [List LOW items]

---

## Appendix

### Tools Used
- [List of tools and versions]

### Scan Coverage
- [What was and wasn't scanned]

### False Positives
- [Any identified false positives]
```

## Phase 4: Generate Remediation PRD (If --fix)

If `--fix` flag provided, create `prd.json` with remediation stories:

```json
{
  "project": "[Project Name] Security Remediation",
  "mode": "feature",
  "branchName": "ralph/security-fixes-[YYYY-MM-DD]",
  "baseBranch": "main",
  "description": "Security remediation from audit on [date]",
  "userStories": []
}
```

### Story Templates by Finding Type

#### Secrets Remediation
```json
{
  "id": "SEC-REM-001",
  "title": "Remove hardcoded secrets and rotate credentials",
  "description": "Remediate secrets exposure found in security audit",
  "acceptanceCriteria": [
    "Remove all hardcoded secrets from source code",
    "Move secrets to environment variables",
    "Create .env.example with placeholder values",
    "Update .gitignore to exclude .env files",
    "Rotate any credentials that were exposed",
    "Verify no secrets remain in git history (consider git-filter-repo)",
    "Document secret management in README"
  ],
  "priority": 1,
  "passes": false,
  "category": "secrets"
}
```

#### Dependency Vulnerabilities
```json
{
  "id": "SEC-REM-002",
  "title": "Fix dependency vulnerabilities",
  "description": "Update vulnerable dependencies identified in audit",
  "acceptanceCriteria": [
    "Run npm audit fix (or equivalent)",
    "Manually update packages with breaking changes",
    "Test application after updates",
    "Document any packages that cannot be updated",
    "Add npm audit to CI pipeline"
  ],
  "priority": 2,
  "passes": false,
  "category": "dependencies"
}
```

#### Injection Prevention
```json
{
  "id": "SEC-REM-003",
  "title": "Fix injection vulnerabilities",
  "description": "Remediate SQL/command/NoSQL injection risks",
  "acceptanceCriteria": [
    "Replace string concatenation with parameterized queries",
    "Add input validation for all user inputs",
    "Sanitize inputs before use in commands",
    "Add integration tests for injection prevention",
    "Review and fix all identified injection points"
  ],
  "priority": 1,
  "passes": false,
  "category": "injection"
}
```

#### XSS Prevention
```json
{
  "id": "SEC-REM-004",
  "title": "Fix XSS vulnerabilities",
  "description": "Remediate cross-site scripting risks",
  "acceptanceCriteria": [
    "Replace innerHTML with textContent where possible",
    "Add DOMPurify for necessary HTML rendering",
    "Review all dangerouslySetInnerHTML usage",
    "Add Content-Security-Policy header",
    "Add XSS tests to test suite"
  ],
  "priority": 2,
  "passes": false,
  "category": "xss"
}
```

#### Authentication Hardening
```json
{
  "id": "SEC-REM-005",
  "title": "Harden authentication",
  "description": "Improve authentication security",
  "acceptanceCriteria": [
    "Implement secure password hashing (bcrypt/argon2)",
    "Add rate limiting to auth endpoints",
    "Configure secure session cookies (httpOnly, secure, sameSite)",
    "Implement account lockout after failed attempts",
    "Add MFA support or document as future work"
  ],
  "priority": 2,
  "passes": false,
  "category": "authentication"
}
```

#### Security Headers
```json
{
  "id": "SEC-REM-006",
  "title": "Implement security headers",
  "description": "Add recommended security headers",
  "acceptanceCriteria": [
    "Install and configure helmet (Node.js) or equivalent",
    "Add Content-Security-Policy",
    "Add X-Content-Type-Options",
    "Add X-Frame-Options",
    "Add Strict-Transport-Security",
    "Verify headers with securityheaders.com"
  ],
  "priority": 3,
  "passes": false,
  "category": "headers"
}
```

## Phase 5: Output Summary

After completing the audit, output:

```
Security Audit Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project:     [name]
Audit Level: [level]
Duration:    [time]

Findings:
  CRITICAL:  [count]
  HIGH:      [count]
  MEDIUM:    [count]
  LOW:       [count]
  INFO:      [count]

Overall Risk: [CRITICAL/HIGH/MEDIUM/LOW]

Output Files:
  - SECURITY_AUDIT.md (detailed report)
  [- prd.json (remediation stories) - if --fix used]

Top Priority Actions:
  1. [Most critical finding]
  2. [Second most critical]
  3. [Third most critical]

[If --fix was used:]
To run remediation:
  ~/tools/ralph-cc-loop/ralph.sh [project_path]
```

## Audit Level Details

### Basic (Quick Scan)
- Secrets scan
- Dependency vulnerabilities
- .gitignore check
- Basic config review

### Standard (Default)
All of Basic, plus:
- Full OWASP Top 10 scan
- Input validation review
- Authentication analysis
- XSS/CSRF checks
- Security headers review

### Thorough (Deep Scan)
All of Standard, plus:
- Code flow analysis for data handling
- Threat modeling documentation
- Third-party integration review
- Infrastructure security (if Dockerfile/k8s present)
- Compliance check (GDPR, HIPAA indicators)
- Security architecture recommendations
