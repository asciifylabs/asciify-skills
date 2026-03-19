---
name: nodejs-principles
description: "Use when writing, reviewing, or modifying JavaScript or TypeScript code (.js, .ts, .tsx, package.json)"
globs: ["**/*.js", "**/*.ts", "**/*.tsx", "**/*.jsx", "**/package.json", "**/tsconfig.json"]
---

# Node.js Principles

These are non-negotiable coding standards -- if you are about to write code that violates a principle, stop and fix it. When reviewing code, flag any violations.

# Use Async/Await Over Callbacks

> Prefer async/await syntax over callbacks and raw promises for cleaner, more maintainable asynchronous code.

## Rules

- Always use async/await for asynchronous operations instead of callbacks
- Avoid callback hell by converting callback-based APIs to promises using `util.promisify()`
- Chain promises only when necessary; prefer async/await for sequential operations
- Use `Promise.all()` or `Promise.allSettled()` for concurrent operations
- Always handle promise rejections with try/catch blocks in async functions
- Never mix callback and promise patterns in the same codebase

## Example

```javascript
// Bad: callback hell
fs.readFile('file.txt', (err, data) => {
  if (err) return handleError(err);
  processData(data, (err, result) => {
    if (err) return handleError(err);
    saveResult(result, (err) => {
      if (err) return handleError(err);
    });
  });
});

// Good: async/await
async function processFile() {
  try {
    const data = await fs.promises.readFile('file.txt');
    const result = await processData(data);
    await saveResult(result);
  } catch (error) {
    handleError(error);
  }
}
```

---

# Use Environment Variables for Configuration

> Store all configuration, secrets, and environment-specific values in environment variables, never hardcode them.

## Rules

- Use environment variables for all configuration (ports, URLs, credentials, feature flags)
- Load environment variables using `dotenv` package in development
- Never commit `.env` files to version control -- add to `.gitignore`
- Provide a `.env.example` file documenting all required environment variables
- Validate required environment variables at application startup
- Use strict typing for environment variables with tools like `envalid` or Zod
- Fail fast if required environment variables are missing

## Example

```javascript
// Bad: hardcoded configuration
const config = {
  port: 3000,
  dbUrl: 'mongodb://localhost:27017/myapp',
  apiKey: 'sk-abc123xyz'
};

// Good: environment-based configuration
import dotenv from 'dotenv';
dotenv.config();

const config = {
  port: process.env.PORT || 3000,
  dbUrl: process.env.DATABASE_URL,
  apiKey: process.env.API_KEY
};

// Validate at startup
if (!config.dbUrl || !config.apiKey) {
  throw new Error('Missing required environment variables');
}
```

---

# Use Proper Error Handling

> Implement comprehensive error handling with meaningful error messages and proper error propagation.

## Rules

- Always wrap async operations in try/catch blocks
- Use custom error classes for domain-specific errors
- Include contextual information in error messages (what failed, why, where)
- Log errors with appropriate severity levels before re-throwing
- Never swallow errors silently with empty catch blocks
- Handle unhandled promise rejections and uncaught exceptions at process level
- Use error middleware in Express/HTTP frameworks
- Distinguish between operational errors (expected) and programmer errors (bugs)

## Example

```javascript
// Bad: swallowing errors
async function getUser(id) {
  try {
    return await db.users.findById(id);
  } catch (error) {
    return null; // Error lost!
  }
}

// Good: proper error handling
class UserNotFoundError extends Error {
  constructor(userId) {
    super(`User not found: ${userId}`);
    this.name = 'UserNotFoundError';
    this.userId = userId;
  }
}

async function getUser(id) {
  try {
    const user = await db.users.findById(id);
    if (!user) {
      throw new UserNotFoundError(id);
    }
    return user;
  } catch (error) {
    logger.error('Failed to get user', { userId: id, error });
    throw error;
  }
}

// Process-level handlers
process.on('unhandledRejection', (error) => {
  logger.fatal('Unhandled rejection', { error });
  process.exit(1);
});
```

---

# Use Package.json Scripts for Tasks

> Define all development, build, and deployment tasks as npm scripts in package.json.

## Rules

- Use npm scripts instead of shell scripts or Makefiles for project tasks
- Define scripts for common tasks: `start`, `dev`, `build`, `test`, `lint`, `format`
- Use `pre` and `post` hooks for setup and cleanup tasks
- Use tools like `npm-run-all` or `concurrently` for running multiple scripts
- Document all scripts in README.md
- Avoid complex logic in scripts -- extract to separate files if needed
- Use cross-platform commands or packages like `cross-env` for compatibility

## Example

```json
{
  "scripts": {
    "start": "node dist/index.js",
    "dev": "nodemon src/index.js",
    "build": "tsc",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint src",
    "lint:fix": "eslint src --fix",
    "format": "prettier --write \"src/**/*.{js,ts}\"",
    "precommit": "npm run lint && npm run test",
    "prebuild": "npm run lint",
    "typecheck": "tsc --noEmit",
    "clean": "rm -rf dist",
    "prepublishOnly": "npm run build"
  }
}
```

---

# Use ESLint and Prettier

> Enforce code quality and consistent formatting with ESLint and Prettier configured for your project.

## Rules

- Always configure ESLint for linting and Prettier for formatting
- Use established style guides (Airbnb, Standard, or create your own)
- Configure ESLint and Prettier to work together (use `eslint-config-prettier`)
- Run linting and formatting in pre-commit hooks using `husky` and `lint-staged`
- Fix auto-fixable issues automatically, fail CI on unfixable issues
- Enable TypeScript-aware ESLint rules if using TypeScript
- Configure editor integration for immediate feedback
- Never disable rules without good reason and documentation

## Example

```json
// .eslintrc.json
{
  "extends": [
    "eslint:recommended",
    "plugin:node/recommended",
    "prettier"
  ],
  "plugins": ["node"],
  "env": {
    "node": true,
    "es2022": true
  },
  "parserOptions": {
    "ecmaVersion": 2022
  },
  "rules": {
    "no-console": "warn",
    "no-unused-vars": ["error", { "argsIgnorePattern": "^_" }]
  }
}

// .prettierrc.json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5"
}

// package.json
{
  "lint-staged": {
    "*.js": ["eslint --fix", "prettier --write"]
  }
}
```

---

# Use ESM Modules Consistently

> Use ECMAScript Modules (ESM) with import/export syntax consistently throughout your project.

## Rules

- Use ESM (import/export) for new projects unless you have a specific reason to use CommonJS
- Add `"type": "module"` to package.json for ESM
- Use `.mjs` extension for ESM files if not setting type in package.json
- Never mix ESM and CommonJS in the same project
- Use named exports for multiple exports, default export for single primary export
- Import packages using their documented module format
- Use `import.meta.url` instead of `__dirname` in ESM modules
- Use dynamic `import()` for conditional or lazy loading

## Example

```json
// package.json
{
  "type": "module"
}
```

```javascript
// Bad: mixing CommonJS and ESM
const express = require('express');
import { readFile } from 'fs/promises';

// Good: consistent ESM
import express from 'express';
import { readFile } from 'fs/promises';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// ESM equivalent of __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Named exports
export const helper = () => {};
export const config = {};

// Default export for main export
export default function main() {}
```

---

# Lock Dependencies with Lock Files

> Always commit lock files (package-lock.json or yarn.lock) to ensure reproducible builds across environments.

## Rules

- Commit `package-lock.json` (npm) or `yarn.lock` (yarn) or `pnpm-lock.yaml` (pnpm) to version control
- Use exact versions for production dependencies in package.json when stability is critical
- Use `npm ci` or `yarn install --frozen-lockfile` in CI/CD pipelines
- Never manually edit lock files
- Update dependencies regularly but deliberately using `npm update` or `yarn upgrade`
- Use `npm audit` or `yarn audit` to check for security vulnerabilities
- Document the package manager being used in README.md
- Include `.npmrc` if using specific npm configurations

## Example

```json
// package.json - use semantic versioning appropriately
{
  "dependencies": {
    "express": "^4.18.2",        // Minor and patch updates allowed
    "lodash": "~4.17.21",         // Only patch updates allowed
    "critical-lib": "1.2.3"       // Exact version for critical dependencies
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "eslint": "^8.0.0"
  }
}

// CI/CD script
{
  "scripts": {
    "ci:install": "npm ci",       // Use ci for reproducible installs
    "audit": "npm audit --audit-level=moderate"
  }
}
```

```bash
# .gitignore - never ignore lock files
node_modules/
# package-lock.json  <- NEVER ignore this!
```

---

# Use Structured Logging

> Implement structured logging with log levels and context instead of console.log statements.

## Rules

- Use a logging library like `pino`, `winston`, or `bunyan` instead of `console.log`
- Include log levels (debug, info, warn, error, fatal) and use them appropriately
- Log structured data (JSON) for easy parsing and searching
- Include contextual information (request ID, user ID, timestamp, etc.)
- Configure different log levels for different environments (verbose in dev, concise in prod)
- Never log sensitive information (passwords, tokens, PII)
- Use log aggregation tools in production (CloudWatch, DataDog, ELK stack)
- Remove or disable debug logs in production

## Example

```javascript
// Bad: unstructured console logging
console.log('User logged in');
console.log('Error:', error);

// Good: structured logging with pino
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: process.env.NODE_ENV === 'development'
    ? { target: 'pino-pretty' }
    : undefined
});

// Log with context
logger.info({ userId: user.id, email: user.email }, 'User logged in');

// Log errors with full context
logger.error(
  {
    err: error,
    userId: user.id,
    operation: 'fetchUserData',
    requestId: req.id
  },
  'Failed to fetch user data'
);

// Child loggers for request context
app.use((req, res, next) => {
  req.log = logger.child({ requestId: req.id });
  next();
});
```

---

# Validate All Inputs

> Validate and sanitize all external inputs (API requests, user input, environment variables) at system boundaries.

## Rules

- Validate all incoming data at API boundaries using schema validation libraries
- Use tools like `joi`, `zod`, `yup`, or `ajv` for validation
- Validate types, formats, ranges, and required fields
- Return clear validation error messages to clients
- Never trust client-side validation alone
- Validate environment variables at application startup
- Sanitize inputs to prevent injection attacks (SQL, NoSQL, XSS)
- Use TypeScript for compile-time type checking in addition to runtime validation

## Example

```javascript
// Bad: no validation
app.post('/users', async (req, res) => {
  const user = await db.users.create(req.body); // Dangerous!
  res.json(user);
});

// Good: schema validation with zod
import { z } from 'zod';

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().min(18).max(120),
  role: z.enum(['user', 'admin']).default('user')
});

app.post('/users', async (req, res) => {
  try {
    const validatedData = createUserSchema.parse(req.body);
    const user = await db.users.create(validatedData);
    res.json(user);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        error: 'Validation failed',
        details: error.errors
      });
    }
    throw error;
  }
});
```

---

# Use Dependency Injection for Testability

> Pass dependencies as parameters instead of hardcoding them to improve testability and maintainability.

## Rules

- Inject dependencies through function parameters or constructors
- Avoid direct imports of modules that have side effects or external dependencies
- Use dependency injection for database connections, external services, and configuration
- Create factory functions or use DI containers for complex dependency graphs
- Make dependencies explicit in function signatures
- Use interfaces or types to define contracts between modules
- Inject mocks and stubs in tests instead of using complex mocking libraries

## Example

```javascript
// Bad: hardcoded dependencies
import { db } from './database.js';
import { emailService } from './email.js';

export async function createUser(userData) {
  const user = await db.users.create(userData);
  await emailService.sendWelcome(user.email);
  return user;
}

// Good: dependency injection
export function createUserService(db, emailService) {
  return {
    async createUser(userData) {
      const user = await db.users.create(userData);
      await emailService.sendWelcome(user.email);
      return user;
    }
  };
}

// Usage in application
import { db } from './database.js';
import { emailService } from './email.js';

const userService = createUserService(db, emailService);
await userService.createUser(userData);

// Easy to test with mocks
const mockDb = { users: { create: jest.fn() } };
const mockEmail = { sendWelcome: jest.fn() };
const testService = createUserService(mockDb, mockEmail);
```

---

# Handle Promises Properly

> Always handle promise rejections and avoid creating unhandled promise rejections.

## Rules

- Every promise must have a `.catch()` handler or be in a try/catch block
- Never create floating promises -- always await or explicitly handle them
- Use `Promise.allSettled()` when you need results from all promises regardless of failures
- Use `Promise.race()` for timeout patterns with `AbortController`
- Avoid creating promises unnecessarily with `new Promise()` when async/await suffices
- Handle errors in promise chains before they bubble up
- Use ESLint rule `no-floating-promises` to catch unhandled promises
- Be careful with `forEach` and other array methods -- they don't await promises

## Example

```javascript
// Bad: floating promise (unhandled)
async function bad() {
  saveToDatabase(data); // Promise not awaited or handled!
  return 'done';
}

// Bad: forEach doesn't await
users.forEach(async (user) => {
  await sendEmail(user); // Doesn't wait!
});

// Good: properly handled promises
async function good() {
  try {
    await saveToDatabase(data);
    return 'done';
  } catch (error) {
    logger.error({ error }, 'Failed to save to database');
    throw error;
  }
}

// Good: parallel processing with error handling
await Promise.allSettled(
  users.map(user => sendEmail(user))
);

// Good: for...of for sequential async operations
for (const user of users) {
  await sendEmail(user);
}

// Good: timeout pattern
const timeout = new Promise((_, reject) =>
  setTimeout(() => reject(new Error('Timeout')), 5000)
);
const result = await Promise.race([fetchData(), timeout]);
```

---

# Use TypeScript for Type Safety

> Prefer TypeScript over JavaScript for improved type safety, better tooling, and fewer runtime errors.

## Rules

- Use TypeScript for all new Node.js projects of significant size
- Enable strict mode in tsconfig.json (`"strict": true`)
- Define interfaces and types for all data structures
- Avoid using `any` type -- use `unknown` if type is truly unknown
- Use type guards and discriminated unions for runtime type checking
- Generate types from schemas using tools like `zod` or `ts-json-schema-generator`
- Use type inference where possible, but add explicit types for public APIs
- Configure path aliases in tsconfig.json for cleaner imports
- Use TypeScript's utility types (Partial, Pick, Omit, etc.)

## Example

```typescript
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "node",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "outDir": "./dist",
    "rootDir": "./src"
  }
}
```

```typescript
// Good: strong typing
interface User {
  id: string;
  email: string;
  name: string;
  role: 'user' | 'admin';
  createdAt: Date;
}

interface CreateUserInput {
  email: string;
  name: string;
  role?: User['role'];
}

async function createUser(
  input: CreateUserInput
): Promise<User> {
  // TypeScript ensures we handle all fields correctly
  return await db.users.create({
    ...input,
    id: generateId(),
    role: input.role ?? 'user',
    createdAt: new Date()
  });
}
```

---

# Use Security Best Practices

> Implement security measures to protect against common vulnerabilities and attacks.

## Rules

- Use helmet.js middleware to set security HTTP headers in Express apps
- Implement rate limiting to prevent brute force and DoS attacks
- Validate and sanitize all inputs to prevent injection attacks
- Use parameterized queries or ORMs to prevent SQL injection
- Enable CORS with strict origin policies, not wildcard `*` in production
- Never expose sensitive data in error messages or stack traces to clients
- Use HTTPS in production (enforce with `express-force-ssl`)
- Implement authentication and authorization properly (use established libraries)
- Scan dependencies regularly with `npm audit` or `snyk`
- Use Content Security Policy (CSP) headers for web applications
- Hash and salt passwords with bcrypt or argon2, never store plain text
- Implement proper session management with secure, httpOnly cookies

## Example

```javascript
// Good: security middleware in Express
import express from 'express';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import cors from 'cors';

const app = express();

// Security headers
app.use(helmet());

// CORS with strict origin
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || 'https://example.com',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
});
app.use('/api/', limiter);

// Hide Express
app.disable('x-powered-by');

// Error handling - don't leak details
app.use((err, req, res, next) => {
  logger.error({ err, requestId: req.id });
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production'
      ? 'Internal server error'
      : err.message
  });
});
```

---

# Organize Project Structure

> Use a clear, consistent directory structure that separates concerns and scales with project growth.

## Rules

- Organize code by feature or domain, not by file type
- Keep related files together (routes, controllers, services, tests in same feature folder)
- Use an `src/` directory for source code and `dist/` or `build/` for compiled output
- Place tests alongside the code they test or in a parallel `__tests__/` directory
- Use `index.js` or `index.ts` as the main entry point for each module
- Separate configuration, utilities, and shared code into dedicated directories
- Keep the root directory clean -- only essential files (package.json, README.md, etc.)
- Use path aliases to avoid deep relative imports (`../../../utils`)
- Document the structure in README.md

## Example

```
project/
├── src/
│   ├── index.ts                 # Application entry point
│   ├── config/                  # Configuration files
│   │   ├── database.ts
│   │   └── env.ts
│   ├── features/                # Feature-based organization
│   │   ├── users/
│   │   │   ├── user.routes.ts
│   │   │   ├── user.controller.ts
│   │   │   ├── user.service.ts
│   │   │   ├── user.model.ts
│   │   │   ├── user.schema.ts
│   │   │   └── user.test.ts
│   │   └── auth/
│   │       ├── auth.routes.ts
│   │       ├── auth.service.ts
│   │       └── auth.middleware.ts
│   ├── lib/                     # Shared utilities and helpers
│   │   ├── logger.ts
│   │   ├── errors.ts
│   │   └── validation.ts
│   └── types/                   # Shared TypeScript types
│       └── index.ts
├── tests/                       # Integration/E2E tests
│   └── integration/
├── dist/                        # Compiled output (gitignored)
├── package.json
├── tsconfig.json
└── README.md
```

---

# Use Graceful Shutdown

> Implement graceful shutdown to properly close connections and finish processing before terminating the application.

## Rules

- Listen for `SIGTERM` and `SIGINT` signals to initiate shutdown
- Stop accepting new requests when shutdown is initiated
- Allow in-flight requests to complete within a timeout period
- Close database connections, message queues, and other resources properly
- Use a shutdown timeout to force exit if graceful shutdown takes too long
- Log shutdown events for observability
- Respond with `503 Service Unavailable` to health checks during shutdown
- Use packages like `terminus` for Express or implement manually

## Example

```javascript
// Good: graceful shutdown implementation
import express from 'express';
import { createTerminus } from '@godaddy/terminus';

const app = express();
const server = app.listen(3000);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Cleanup function
async function onShutdown() {
  logger.info('Starting graceful shutdown');

  // Close database connections
  await db.close();

  // Close message queue connections
  await messageQueue.disconnect();

  // Any other cleanup
  logger.info('Graceful shutdown completed');
}

// Setup graceful shutdown
createTerminus(server, {
  timeout: 10000, // 10 seconds
  signals: ['SIGTERM', 'SIGINT'],
  beforeShutdown: async () => {
    // Give load balancer time to deregister
    await new Promise(resolve => setTimeout(resolve, 5000));
  },
  onShutdown,
  logger: (msg, err) => logger.error({ err }, msg)
});

// Manual implementation alternative
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received');
  server.close(async () => {
    await onShutdown();
    process.exit(0);
  });

  // Force shutdown after timeout
  setTimeout(() => {
    logger.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
});
```

---

# Write Comprehensive Tests

> Use a layered testing strategy with unit, integration, and end-to-end tests to ensure correctness and prevent regressions.

## Rules

- Use a modern test runner (Vitest, Jest, or Node.js built-in test runner)
- Write unit tests for business logic, pure functions, and utilities
- Write integration tests for API endpoints, database queries, and external service interactions
- Use test fixtures and factories instead of hardcoded test data
- Mock external dependencies at service boundaries, not internal modules
- Aim for meaningful coverage of critical paths, not arbitrary coverage percentages
- Run tests in CI on every PR; block merges on test failure

## Example

```typescript
// Bad: no tests, or testing implementation details
test("calls database", () => {
  const spy = jest.spyOn(db, "query");
  getUser(1);
  expect(spy).toHaveBeenCalledWith("SELECT * FROM users WHERE id = $1", [1]);
});

// Good: test behavior, not implementation
import { describe, it, expect, beforeEach } from "vitest";
import { createApp } from "../src/app.js";
import { createTestDatabase } from "./helpers/db.js";

describe("GET /users/:id", () => {
  let app: Express;
  let db: TestDatabase;

  beforeEach(async () => {
    db = await createTestDatabase();
    app = createApp({ db });
  });

  it("returns the user when found", async () => {
    await db.seed({ users: [{ id: 1, name: "Alice" }] });

    const response = await request(app).get("/users/1");

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ id: 1, name: "Alice" });
  });

  it("returns 404 for unknown user", async () => {
    const response = await request(app).get("/users/999");
    expect(response.status).toBe(404);
  });
});
```

```bash
# Run tests with coverage
npx vitest run --coverage

# Run tests in watch mode during development
npx vitest
```

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **eslint** — lint JavaScript and TypeScript files: `npx eslint --fix .`
- **prettier** — format code consistently: `npx prettier --write .`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
