---
name: api-docs
description: Generate OpenAPI/Swagger specifications from code by analyzing route handlers. Use when asked to "generate API docs", "create OpenAPI spec", "document API", or "swagger docs".
arguments: "<project_path> [--output <file>] [--format yaml|json] [--include-examples] | --help"
---

# Help Check

If the user passed `--help` as an argument, output the following and stop:

```
/api-docs - Generate OpenAPI specification from code

Usage:
  claude /api-docs <project_path> [options]
  claude /api-docs --help

Arguments:
  project_path           Path to the project (required)

Options:
  --output <file>        Output file (default: openapi.yaml or openapi.json)
  --format <format>      Output format: yaml (default), json
  --include-examples     Generate example request/response bodies
  --serve                Start local Swagger UI server after generation
  --help                 Show this help message

Supported Frameworks:
  Node.js:    Express, Fastify, NestJS, Koa, Hono
  Python:     FastAPI, Flask, Django REST, Starlette
  Go:         Gin, Echo, Chi, Fiber
  Ruby:       Rails API, Sinatra, Grape

Examples:
  claude /api-docs ~/Projects/my-api
  claude /api-docs ~/Projects/my-api --format json
  claude /api-docs ~/Projects/my-api --include-examples
  claude /api-docs ~/Projects/my-api --output docs/api.yaml

What it generates:
  - Complete OpenAPI 3.0 specification
  - Path definitions with methods, parameters, responses
  - Request/response schemas from TypeScript types or validation
  - Authentication requirements
  - Example values (with --include-examples)

Output:
  - openapi.yaml (or .json): OpenAPI specification
  - Optional: Swagger UI preview
```

---

# API Documentation Generator

You are an API documentation expert. This skill:
1. Analyzes route handlers and controllers
2. Extracts request/response schemas
3. Generates OpenAPI 3.0 specification
4. Creates comprehensive API documentation

## Phase 1: Project Discovery

### Step 1.1: Navigate to Project

```bash
cd [project_path] && pwd
```

### Step 1.2: Detect Framework

```bash
# Node.js
cat package.json 2>/dev/null | jq -r '.dependencies | keys[]' | grep -E 'express|fastify|@nestjs|koa|hono'

# Python
cat requirements.txt pyproject.toml 2>/dev/null | grep -iE 'fastapi|flask|django|starlette'

# Go
cat go.mod 2>/dev/null | grep -E 'gin|echo|chi|fiber'

# Ruby
cat Gemfile 2>/dev/null | grep -E 'rails|sinatra|grape'
```

### Step 1.3: Find Route Files

Based on framework, locate route definitions:

| Framework | Typical Locations |
|-----------|------------------|
| Express | `routes/`, `app.js`, `server.js`, `*.routes.ts` |
| Fastify | `routes/`, `plugins/`, `app.ts` |
| NestJS | `*.controller.ts`, `*.module.ts` |
| FastAPI | `main.py`, `routers/`, `api/` |
| Flask | `app.py`, `views/`, `routes/` |
| Django REST | `views.py`, `viewsets.py`, `urls.py` |

```bash
# Find route files
find . -type f \( -name "*.routes.ts" -o -name "*.controller.ts" -o -name "*router*.py" -o -name "views.py" \) -not -path "*/node_modules/*"
```

## Phase 2: Extract Routes

### Step 2.1: Express/Fastify Routes

Look for patterns:
```typescript
// Express
router.get('/users', handler)
router.post('/users', handler)
app.use('/api', router)

// Fastify
fastify.get('/users', handler)
fastify.route({ method: 'GET', url: '/users', handler })
```

Extract:
- HTTP method
- Path (including parameters like `:id`)
- Middleware (for auth requirements)
- Handler function

### Step 2.2: NestJS Controllers

Look for decorators:
```typescript
@Controller('users')
export class UsersController {
  @Get()
  findAll() {}

  @Get(':id')
  findOne(@Param('id') id: string) {}

  @Post()
  @UseGuards(AuthGuard)
  create(@Body() dto: CreateUserDto) {}
}
```

Extract:
- Controller path prefix
- Method decorators (@Get, @Post, etc.)
- Parameter decorators (@Param, @Query, @Body)
- Guard decorators (for auth)
- DTO types

### Step 2.3: FastAPI Routes

Look for decorators:
```python
@app.get("/users", response_model=List[User])
async def get_users(skip: int = 0, limit: int = 100):
    pass

@app.post("/users", response_model=User, status_code=201)
async def create_user(user: UserCreate):
    pass
```

Extract:
- Path and method from decorator
- Response model
- Status code
- Function parameters (become query/path params)
- Pydantic models for body

### Step 2.4: Flask/Django Routes

```python
# Flask
@app.route('/users', methods=['GET', 'POST'])
def users():
    pass

# Django REST
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
```

## Phase 3: Extract Schemas

### Step 3.1: TypeScript Types/Interfaces

Find types used in routes:
```typescript
interface User {
  id: string;
  email: string;
  name: string;
  createdAt: Date;
}

interface CreateUserDto {
  email: string;
  password: string;
  name?: string;
}
```

Convert to OpenAPI schema:
```yaml
User:
  type: object
  required: [id, email, name, createdAt]
  properties:
    id:
      type: string
    email:
      type: string
      format: email
    name:
      type: string
    createdAt:
      type: string
      format: date-time
```

### Step 3.2: Zod/Yup Validation Schemas

```typescript
const createUserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().optional(),
});
```

Extract validation rules for:
- Required vs optional
- String formats (email, uuid, url)
- Number constraints (min, max)
- Array items
- Enums

### Step 3.3: Pydantic Models (Python)

```python
class User(BaseModel):
    id: UUID
    email: EmailStr
    name: str
    created_at: datetime

class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8)
    name: Optional[str] = None
```

### Step 3.4: Database Models (if no DTOs)

Fall back to ORM models:
- Prisma schema
- TypeORM entities
- SQLAlchemy models
- Django models

## Phase 4: Extract Authentication

### Step 4.1: Identify Auth Middleware

Look for:
```typescript
// Express
app.use('/api', authMiddleware)
router.get('/users', requireAuth, handler)

// NestJS
@UseGuards(JwtAuthGuard)

// FastAPI
@app.get('/users', dependencies=[Depends(get_current_user)])
```

### Step 4.2: Determine Auth Type

| Pattern | OpenAPI Security Scheme |
|---------|------------------------|
| Bearer token | `bearerAuth` (http, bearer) |
| API key header | `apiKey` (apiKey, header) |
| Basic auth | `basicAuth` (http, basic) |
| OAuth2 | `oauth2` (oauth2, flows) |
| Cookie/Session | `cookieAuth` (apiKey, cookie) |

### Step 4.3: Map to Endpoints

Track which endpoints require auth:
- Public (no security)
- Authenticated (requires valid token)
- Role-based (requires specific role)

## Phase 5: Generate OpenAPI Spec

### Step 5.1: Base Structure

```yaml
openapi: 3.0.3
info:
  title: [Project Name] API
  description: |
    API documentation generated from source code.

    Generated by /api-docs skill.
  version: [from package.json]
  contact:
    name: API Support
  license:
    name: MIT

servers:
  - url: http://localhost:3000
    description: Development server
  - url: https://api.example.com
    description: Production server

tags:
  - name: Users
    description: User management endpoints
  - name: Auth
    description: Authentication endpoints
```

### Step 5.2: Security Schemes

```yaml
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT token from /auth/login

    apiKey:
      type: apiKey
      in: header
      name: X-API-Key
```

### Step 5.3: Path Definitions

```yaml
paths:
  /users:
    get:
      tags: [Users]
      summary: List all users
      description: Returns a paginated list of users
      operationId: getUsers
      security:
        - bearerAuth: []
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
            maximum: 100
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
                  pagination:
                    $ref: '#/components/schemas/Pagination'
        '401':
          $ref: '#/components/responses/Unauthorized'

    post:
      tags: [Users]
      summary: Create a new user
      operationId: createUser
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUser'
      responses:
        '201':
          description: User created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          $ref: '#/components/responses/BadRequest'
        '409':
          description: Email already exists
```

### Step 5.4: Schema Components

```yaml
components:
  schemas:
    User:
      type: object
      required: [id, email, name, createdAt]
      properties:
        id:
          type: string
          format: uuid
          example: "123e4567-e89b-12d3-a456-426614174000"
        email:
          type: string
          format: email
          example: "user@example.com"
        name:
          type: string
          example: "John Doe"
        createdAt:
          type: string
          format: date-time

    CreateUser:
      type: object
      required: [email, password]
      properties:
        email:
          type: string
          format: email
        password:
          type: string
          format: password
          minLength: 8
        name:
          type: string

    Error:
      type: object
      properties:
        code:
          type: string
        message:
          type: string

  responses:
    Unauthorized:
      description: Authentication required
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'

    BadRequest:
      description: Invalid request body
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
```

### Step 5.5: Add Examples (if --include-examples)

```yaml
components:
  examples:
    UserExample:
      value:
        id: "123e4567-e89b-12d3-a456-426614174000"
        email: "john@example.com"
        name: "John Doe"
        createdAt: "2024-01-15T10:30:00Z"

    UserListExample:
      value:
        data:
          - id: "123e4567-e89b-12d3-a456-426614174000"
            email: "john@example.com"
            name: "John Doe"
        pagination:
          page: 1
          limit: 20
          total: 1
```

## Phase 6: Output

### Step 6.1: Write Specification

Write to `openapi.yaml` (or `openapi.json` if `--format json`).

### Step 6.2: Validate Specification

```bash
# If npx available
npx @redocly/cli lint openapi.yaml
```

### Step 6.3: Summary

```
API Documentation Generated
--------------------------------------------------

Project:     [name]
Framework:   [Express/FastAPI/etc]
Output:      openapi.yaml

Endpoints:   X total
  GET:       X
  POST:      X
  PUT:       X
  PATCH:     X
  DELETE:    X

Schemas:     X
Auth:        [Bearer JWT / API Key / None]

Tags:
  - Users (X endpoints)
  - Auth (X endpoints)
  - Products (X endpoints)

Output: openapi.yaml

View documentation:
  npx @redocly/cli preview-docs openapi.yaml
  # or
  npx swagger-ui-watcher openapi.yaml
```

### Step 6.4: Suggest Improvements

If gaps detected:
```
Recommendations:
  - Add JSDoc comments to handlers for better descriptions
  - Define response types for error cases
  - Add validation schemas for request bodies
  - Document rate limiting headers
  - Add webhook documentation if applicable
```

## Framework-Specific Notes

### NestJS

NestJS has built-in Swagger support. Check if `@nestjs/swagger` is installed:
```bash
cat package.json | jq '.dependencies["@nestjs/swagger"]'
```

If installed, may already have decorators - incorporate them:
```typescript
@ApiTags('users')
@ApiOperation({ summary: 'Get all users' })
@ApiResponse({ status: 200, type: [User] })
```

### FastAPI

FastAPI auto-generates OpenAPI. Check `/docs` or `/openapi.json`:
```bash
# If server running
curl http://localhost:8000/openapi.json
```

May want to enhance rather than replace.

### Express with existing swagger-jsdoc

Check for JSDoc comments:
```javascript
/**
 * @swagger
 * /users:
 *   get:
 *     summary: Get users
 */
```

Merge with code analysis.
