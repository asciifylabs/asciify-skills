---
name: security-principles
description: "Use when writing, reviewing, or modifying any code in any language"
---

# Security Principles

These are non-negotiable coding standards -- if you are about to write code that violates a principle, stop and fix it. When reviewing code, flag any violations.

# Never Hardcode Secrets

> Keep all secrets, credentials, API keys, and tokens out of source code — use environment variables, secret managers, or vault services instead.

## Rules

- Never commit passwords, API keys, tokens, private keys, or connection strings to version control
- Use environment variables or a dedicated secrets manager (HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, etc.) for all sensitive values
- Add `.env`, `*.pem`, `*.key`, `credentials.json`, and similar files to `.gitignore` before the first commit
- Use pre-commit hooks (e.g., `git-secrets`, `detect-secrets`, `gitleaks`) to block accidental secret commits
- Rotate any secret that has ever been committed to a repository — treat it as compromised
- Use distinct secrets per environment (development, staging, production) — never share secrets across environments
- Provide a `.env.example` or `.env.template` file with placeholder values (never real secrets) to document required variables
- Store secrets encrypted at rest — never in plain text config files, databases, or logs

## Example

```python
# Bad: hardcoded secret
DATABASE_URL = "postgresql://admin:s3cretP@ss@db.example.com/mydb"
API_KEY = "sk-live-abc123def456"

# Good: read from environment
import os

DATABASE_URL = os.environ["DATABASE_URL"]
API_KEY = os.environ["API_KEY"]
```

```javascript
// Bad: hardcoded token
const token = "ghp_xxxxxxxxxxxxxxxxxxxx";

// Good: read from environment
const token = process.env.GITHUB_TOKEN;
if (!token) throw new Error("GITHUB_TOKEN environment variable is required");
```

```gitignore
# .gitignore - always exclude secret files
.env
.env.local
.env.production
*.pem
*.key
credentials.json
service-account.json
```

---

# Validate and Sanitize All Inputs

> Treat all external input as untrusted — validate format, type, length, and range at system boundaries before processing.

## Rules

- Validate all inputs at the system boundary: HTTP request bodies, query parameters, headers, file uploads, CLI arguments, environment variables
- Use an allowlist approach (accept known-good) rather than a denylist approach (reject known-bad)
- Validate data type, length, range, and format before any processing
- Reject invalid input immediately with a clear error — do not attempt to "fix" malformed data silently
- Use schema validation libraries (Zod, Joi, Pydantic, JSON Schema) rather than hand-written validation
- Sanitize strings that will be rendered in HTML, SQL, shell commands, or other interpreted contexts
- Validate file uploads: check MIME type, file extension, file size, and content (not just the extension)
- Never trust client-side validation alone — always re-validate on the server
- Normalize unicode and encoding before validation to prevent bypass attacks
- Set maximum sizes for all inputs: request bodies, query strings, headers, uploaded files

## Example

```typescript
// Good: schema validation with Zod
import { z } from "zod";

const CreateUserSchema = z.object({
  email: z.string().email().max(254),
  name: z.string().min(1).max(100).trim(),
  age: z.number().int().min(13).max(150),
  role: z.enum(["user", "admin"]),
});

function createUser(input: unknown) {
  const validated = CreateUserSchema.parse(input); // throws on invalid
  return db.users.create(validated);
}
```

```python
# Good: Pydantic validation
from pydantic import BaseModel, EmailStr, Field

class CreateUser(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)
    age: int = Field(ge=13, le=150)
    role: Literal["user", "admin"]

@app.post("/users")
def create_user(user: CreateUser):
    # Input is already validated and typed
    return db.create_user(user)
```

---

# Use Parameterized Queries

> Prevent SQL and NoSQL injection by always using parameterized queries or prepared statements — never concatenate user input into query strings.

## Rules

- Always use parameterized queries (also called prepared statements or bound parameters) for all database queries
- Never concatenate or interpolate user input directly into SQL, NoSQL, or ORM query strings
- Use your language's database driver parameterization: `?` placeholders, `$1` positional params, or named params (`:name`)
- When using ORMs, use the ORM's built-in query builder methods — avoid raw query strings with interpolation
- For dynamic queries (e.g., variable column names or table names), use an allowlist of permitted values — never accept raw input
- Apply the same principle to NoSQL databases: use driver-provided query builders, not string-concatenated filters
- Review any raw SQL usage in code reviews — flag concatenation as a security defect

## Example

```python
# Bad: string concatenation (SQL injection vulnerable)
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")

# Good: parameterized query
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
```

```javascript
// Bad: template literal in query (SQL injection vulnerable)
db.query(`SELECT * FROM users WHERE id = ${userId}`);

// Good: parameterized query
db.query("SELECT * FROM users WHERE id = $1", [userId]);
```

```go
// Bad: fmt.Sprintf in query
db.Query(fmt.Sprintf("SELECT * FROM users WHERE name = '%s'", name))

// Good: parameterized query
db.Query("SELECT * FROM users WHERE name = $1", name)
```

---

# Prevent Cross-Site Scripting (XSS)

> Encode all dynamic output and enforce Content Security Policy to prevent malicious script execution in browsers.

## Rules

- Always HTML-encode user-supplied data before rendering it in HTML context
- Use your framework's built-in auto-escaping (React JSX, Django templates, Go html/template) — do not bypass it
- Never use `innerHTML`, `dangerouslySetInnerHTML`, `document.write()`, or `v-html` with untrusted content
- Implement Content Security Policy (CSP) headers that restrict script sources — avoid `unsafe-inline` and `unsafe-eval`
- Use context-aware encoding: HTML-encode for HTML body, attribute-encode for HTML attributes, JS-encode for JavaScript contexts, URL-encode for URLs
- Sanitize rich-text input with a strict allowlist library (DOMPurify, bleach) — never with regex
- Set `HttpOnly` and `Secure` flags on cookies to prevent JavaScript access
- Validate URLs before rendering them as `href` or `src` — block `javascript:` and `data:` protocols
- Apply output encoding on the server side, not just the client side

## Example

```jsx
// React: safe by default (auto-escapes)
function UserGreeting({ name }) {
  return <h1>Hello, {name}</h1>; // Escaped automatically
}

// Bad: bypasses React's escaping
function UnsafeGreeting({ html }) {
  return <div dangerouslySetInnerHTML={{ __html: html }} />; // XSS risk
}

// Good: sanitize if you must render HTML
import DOMPurify from "dompurify";

function SafeHtmlRenderer({ html }) {
  const clean = DOMPurify.sanitize(html);
  return <div dangerouslySetInnerHTML={{ __html: clean }} />;
}
```

```http
# Good: Content Security Policy header
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; object-src 'none';
```

---

# Implement Authentication Properly

> Use established authentication libraries and proven patterns — never build custom password hashing, token generation, or session management from scratch.

## Rules

- Use established authentication libraries and frameworks (Passport.js, NextAuth, Django auth, Spring Security) — do not roll your own
- Hash passwords with bcrypt, argon2, or scrypt — never use MD5, SHA-1, SHA-256, or any unsalted hash for passwords
- Use a minimum cost factor of 10 for bcrypt (12+ recommended) and tune for ~250ms hash time
- Generate session tokens and API keys with cryptographically secure random generators (`crypto.randomBytes`, `secrets.token_urlsafe`, `crypto/rand`)
- Implement account lockout or exponential backoff after repeated failed login attempts
- Support multi-factor authentication (MFA/2FA) for sensitive operations and admin accounts
- Set session expiration and implement idle timeout — force re-authentication for sensitive actions
- Use secure, `HttpOnly`, `SameSite=Strict` cookies for session storage — avoid localStorage for auth tokens
- Invalidate all sessions on password change
- Never reveal whether a username or email exists in login error messages — use generic messages like "Invalid credentials"
- Log all authentication events (success, failure, lockout) for audit purposes

## Example

```python
# Good: bcrypt password hashing
import bcrypt

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12)).decode()

def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode(), hashed.encode())
```

```javascript
// Good: secure session configuration
app.use(
  session({
    secret: process.env.SESSION_SECRET,
    name: "__session", // non-default name
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: true, // HTTPS only
      httpOnly: true, // No JavaScript access
      sameSite: "strict", // CSRF protection
      maxAge: 3600000, // 1 hour
    },
  })
);
```

---

# Enforce Authorization and Least Privilege

> Verify permissions on every request, deny by default, and grant only the minimum access required for each operation.

## Rules

- Check authorization on every request server-side — never rely on client-side checks or hidden UI elements for access control
- Deny by default: if no explicit permission grants access, the request must be rejected
- Implement role-based (RBAC) or attribute-based (ABAC) access control with clearly defined roles and permissions
- Verify resource ownership — ensure users can only access their own resources unless explicitly authorized for others
- Apply the principle of least privilege: grant the minimum permissions needed for each role, service, or process
- Use middleware or decorators to enforce authorization consistently across all routes — avoid per-endpoint ad-hoc checks
- Separate authentication (who are you?) from authorization (what can you do?) — do not conflate them
- Re-check permissions for state-changing operations, even if the user passed a read check
- API keys and service accounts must have scoped permissions — never use a "god" key with full access
- Log all authorization failures for security monitoring and audit

## Example

```python
# Good: decorator-based authorization
from functools import wraps

def require_role(*allowed_roles):
    def decorator(func):
        @wraps(func)
        def wrapper(request, *args, **kwargs):
            if request.user.role not in allowed_roles:
                raise PermissionDenied("Insufficient permissions")
            return func(request, *args, **kwargs)
        return wrapper
    return decorator

@require_role("admin", "manager")
def delete_user(request, user_id):
    # Only admins and managers reach this point
    ...
```

```typescript
// Good: resource ownership check
async function getDocument(userId: string, docId: string) {
  const doc = await db.documents.findById(docId);
  if (!doc) throw new NotFoundError("Document not found");
  if (doc.ownerId !== userId && !hasRole(userId, "admin")) {
    throw new ForbiddenError("Access denied");
  }
  return doc;
}
```

---

# Protect Against CSRF

> Use anti-CSRF tokens, SameSite cookies, and origin validation to prevent cross-site request forgery attacks on state-changing operations.

## Rules

- Include a unique, unpredictable CSRF token in every state-changing form and AJAX request
- Validate the CSRF token server-side on every POST, PUT, PATCH, and DELETE request
- Use your framework's built-in CSRF protection (Django CSRF middleware, Express csurf, Spring Security CSRF) — do not build your own
- Set `SameSite=Strict` or `SameSite=Lax` on all session cookies to prevent cross-origin cookie sending
- Verify the `Origin` and `Referer` headers on state-changing requests as a defense-in-depth measure
- Never use GET requests for state-changing operations — GET must be safe and idempotent
- For API-only applications using token-based auth (Bearer tokens), ensure tokens are sent via headers, not cookies
- Regenerate CSRF tokens after login to prevent token fixation

## Example

```html
<!-- Good: CSRF token in form (Django) -->
<form method="POST" action="/transfer">
  {% csrf_token %}
  <input name="amount" type="number" />
  <input name="recipient" type="text" />
  <button type="submit">Transfer</button>
</form>
```

```javascript
// Good: CSRF token in AJAX request
fetch("/api/transfer", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
  },
  body: JSON.stringify({ amount: 100, recipient: "user@example.com" }),
});
```

---

# Use HTTPS and Secure Communication

> Encrypt all data in transit with TLS — enforce HTTPS, validate certificates, and eliminate mixed content.

## Rules

- Use HTTPS for all traffic in production — never serve sensitive data over plain HTTP
- Enable HTTP Strict Transport Security (HSTS) with a minimum `max-age` of one year and `includeSubDomains`
- Redirect all HTTP requests to HTTPS at the server or load balancer level
- Use TLS 1.2 or higher — disable TLS 1.0, TLS 1.1, and all SSL versions
- Validate TLS certificates in all outbound requests — never disable certificate verification in production
- Eliminate mixed content: ensure all resources (scripts, styles, images, APIs) are loaded over HTTPS
- Use strong cipher suites and disable weak ones (RC4, DES, 3DES, export ciphers)
- Pin certificates or use Certificate Transparency for critical services
- Encrypt internal service-to-service communication — do not assume the internal network is trusted
- Use secure WebSocket connections (`wss://`) instead of unencrypted (`ws://`)

## Example

```javascript
// Good: enforce HTTPS in Express
import helmet from "helmet";

app.use(
  helmet.hsts({
    maxAge: 31536000, // 1 year in seconds
    includeSubDomains: true,
    preload: true,
  })
);

// Redirect HTTP to HTTPS
app.use((req, res, next) => {
  if (req.header("x-forwarded-proto") !== "https") {
    return res.redirect(301, `https://${req.hostname}${req.url}`);
  }
  next();
});
```

```python
# Bad: disabling certificate verification
requests.get("https://api.example.com", verify=False)  # NEVER do this

# Good: proper TLS verification (default behavior)
requests.get("https://api.example.com")  # verify=True by default
```

---

# Handle Errors Without Leaking Information

> Return generic error messages to clients and log detailed diagnostics server-side — never expose stack traces, internal paths, or system details in responses.

## Rules

- Return generic, user-friendly error messages to clients (e.g., "Something went wrong") — never include stack traces, SQL errors, or internal paths
- Log full error details (stack trace, context, request ID) server-side for debugging
- Use a unique request/correlation ID in both the client response and server logs to enable tracing without exposing details
- Never reveal whether a specific record exists in error messages (e.g., "User not found" vs "Invalid credentials")
- Disable debug mode, verbose errors, and stack trace display in production environments
- Configure custom error pages for HTTP 4xx and 5xx responses — never use framework defaults in production
- Catch all unhandled exceptions with a global error handler that sanitizes output
- Never include database connection details, file system paths, or internal IP addresses in error responses
- Different error codes should not leak timing information — use constant-time comparison for sensitive checks

## Example

```typescript
// Good: global error handler that separates client vs server details
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  const requestId = crypto.randomUUID();

  // Log full details server-side
  logger.error({
    requestId,
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
    userId: req.user?.id,
  });

  // Return safe response to client
  res.status(err instanceof AppError ? err.statusCode : 500).json({
    error: err instanceof AppError ? err.message : "Internal server error",
    requestId, // enables support lookup without exposing details
  });
});
```

```python
# Bad: leaking stack trace to client
@app.errorhandler(500)
def handle_error(error):
    return str(error), 500  # Exposes internal details

# Good: generic message with server-side logging
@app.errorhandler(500)
def handle_error(error):
    request_id = uuid.uuid4().hex
    logger.error("Unhandled error", request_id=request_id, exc_info=error)
    return jsonify({"error": "Internal server error", "request_id": request_id}), 500
```

---

# Log Security Events

> Record all authentication, authorization, and security-relevant events with structured logging — enable detection, investigation, and compliance auditing.

## Rules

- Log all authentication events: successful logins, failed logins, logouts, password changes, MFA enrollment/usage
- Log all authorization failures: access denied events with the user, resource, and attempted action
- Log account lifecycle events: creation, deletion, role changes, permission grants/revokes
- Log security-sensitive operations: data exports, bulk deletions, configuration changes, API key creation
- Never log secrets, passwords, tokens, API keys, credit card numbers, or other sensitive values
- Mask or truncate personally identifiable information (PII) in logs — log only what is necessary for investigation
- Use structured logging (JSON) with consistent fields: timestamp, event type, user ID, IP address, request ID, outcome
- Include sufficient context for investigation: what happened, who did it, when, from where, and the outcome
- Forward security logs to a centralized logging system (SIEM) with tamper-proof storage
- Set appropriate log retention periods for compliance requirements (typically 90 days to 7 years)
- Alert on anomalous patterns: brute force attempts, privilege escalation, unusual access patterns

## Example

```python
# Good: structured security event logging
import structlog

security_logger = structlog.get_logger("security")

def login(request):
    user = authenticate(request.email, request.password)
    if user:
        security_logger.info(
            "authentication.success",
            user_id=user.id,
            ip_address=request.remote_addr,
            user_agent=request.user_agent,
        )
    else:
        security_logger.warning(
            "authentication.failure",
            email=request.email,  # OK to log email, NOT the password
            ip_address=request.remote_addr,
            reason="invalid_credentials",
        )
```

```json
// Example structured security log entry
{
  "timestamp": "2024-01-15T14:30:00Z",
  "level": "warning",
  "event": "authorization.denied",
  "user_id": "usr_abc123",
  "resource": "/api/admin/users",
  "action": "DELETE",
  "ip_address": "192.168.1.100",
  "request_id": "req_xyz789",
  "reason": "insufficient_permissions"
}
```

---

# Keep Dependencies Secure

> Audit dependencies regularly, pin versions, monitor for CVEs, and remove unused packages to minimize supply chain risk.

## Rules

- Run dependency vulnerability scans regularly: `npm audit`, `pip-audit`, `cargo audit`, `go vuln check`, `bundler-audit`
- Integrate dependency scanning into CI/CD pipelines — fail builds on critical or high severity vulnerabilities
- Pin dependency versions in lock files (`package-lock.json`, `poetry.lock`, `go.sum`, `Cargo.lock`) and commit them
- Review dependency updates before applying — use tools like Dependabot, Renovate, or Snyk for automated PRs
- Remove unused dependencies — every dependency is an attack surface
- Prefer well-maintained dependencies with active communities, frequent releases, and security policies
- Verify package integrity: use checksum verification and package signing where available
- Limit the number of transitive dependencies — prefer packages with fewer sub-dependencies
- Never install packages from untrusted sources or registries
- Establish a process for emergency patching when critical CVEs are disclosed in your dependencies
- Use software composition analysis (SCA) tools to maintain a software bill of materials (SBOM)

## Example

```yaml
# Good: CI pipeline with dependency scanning
# GitHub Actions example
name: Security Scan
on: [push, pull_request]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm audit --audit-level=high
        # Fails on high or critical vulnerabilities

  snyk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

```bash
# Regular audit commands by ecosystem
npm audit                    # Node.js
pip-audit                    # Python
cargo audit                  # Rust
govulncheck ./...            # Go
bundler-audit check          # Ruby
```

---

# Use Secure Defaults

> Configure applications to be secure out of the box — disable debug features in production, restrict CORS, minimize exposed surface area, and require explicit opt-in for risky settings.

## Rules

- Disable debug mode, verbose logging, and developer tools in production environments
- Use restrictive CORS policies — never use `Access-Control-Allow-Origin: *` in production with credentials
- Disable directory listing on web servers
- Remove default accounts, passwords, and sample data before deployment
- Set restrictive file permissions — follow the principle of least privilege for file system access
- Disable unnecessary HTTP methods (TRACE, OPTIONS where not needed)
- Configure security headers by default: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`
- Use parameterized configuration with environment-specific overrides — never embed production settings in code
- Disable unnecessary features and services — every enabled feature is an attack surface
- Default to denying access and requiring explicit grants rather than defaulting to open access
- Ensure error pages do not reveal framework or server version information

## Example

```python
# Good: Django production settings
DEBUG = False
ALLOWED_HOSTS = ["myapp.example.com"]
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
X_FRAME_OPTIONS = "DENY"
```

```javascript
// Good: restrictive CORS configuration
app.use(
  cors({
    origin: ["https://myapp.example.com"],
    methods: ["GET", "POST", "PUT", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"],
    credentials: true,
    maxAge: 86400,
  })
);
```

---

# Protect Sensitive Data

> Encrypt sensitive data at rest and in transit, mask PII in logs and outputs, classify data by sensitivity, and enforce retention policies.

## Rules

- Encrypt sensitive data at rest using strong algorithms (AES-256, ChaCha20) with proper key management
- Never store sensitive data in plain text: passwords, tokens, personal data, financial records, health records
- Classify data by sensitivity level (public, internal, confidential, restricted) and apply appropriate protections
- Mask or redact PII (emails, phone numbers, addresses, SSNs) in logs, error messages, and non-essential displays
- Use field-level encryption for highly sensitive database columns (credit cards, SSNs, health data)
- Implement data retention policies — automatically purge data that is no longer needed
- Minimize data collection — only collect and store what is strictly necessary for the business function
- Scrub sensitive data from development and staging environments — use anonymized or synthetic test data
- Implement secure deletion — overwrite or crypto-shred data rather than just marking it as deleted
- Comply with applicable data protection regulations (GDPR, CCPA, HIPAA, PCI-DSS) for data handling, storage, and transfer
- Never return more data than the client needs — use projection and field filtering in API responses

## Example

```python
# Good: mask PII in logs
def mask_email(email: str) -> str:
    local, domain = email.split("@")
    return f"{local[0]}{'*' * (len(local) - 1)}@{domain}"

def mask_card(card_number: str) -> str:
    return f"****-****-****-{card_number[-4:]}"

logger.info("Processing payment", email=mask_email(user.email), card=mask_card(card))
```

```typescript
// Good: selective API response fields
function toPublicUser(user: User): PublicUser {
  return {
    id: user.id,
    name: user.name,
    avatar: user.avatarUrl,
    // Excluded: email, phone, address, passwordHash, ssn
  };
}
```

---

# Prevent Injection Attacks

> Use safe APIs, parameterized inputs, and allowlists to prevent OS command injection, LDAP injection, template injection, and other injection vectors beyond SQL.

## Rules

- Never pass user input directly to OS commands, shell interpreters, or `eval()`-like functions
- Use language-native APIs instead of shell commands: use `fs.readdir()` instead of `exec("ls")`, use `subprocess.run([...])` with list arguments instead of shell strings
- When shell execution is unavoidable, use allowlists for permitted values — never interpolate raw user input
- Use `subprocess.run(["cmd", "arg"], shell=False)` (Python), `execFile` (Node.js), or `exec.Command` (Go) with argument arrays — never `shell=True` with user input
- Prevent template injection: never pass user input as template source — only use it as template data/context
- Prevent LDAP injection: escape special characters or use parameterized LDAP queries
- Prevent XML injection (XXE): disable external entity processing in XML parsers
- Prevent header injection: validate and sanitize values before setting HTTP headers
- Prevent log injection: sanitize log inputs to prevent log forging (strip newlines, control characters)
- Apply the principle of least authority: run processes with minimal OS permissions

## Example

```python
# Bad: OS command injection
import os
os.system(f"convert {user_filename} output.png")  # Shell injection

# Good: safe subprocess with argument list
import subprocess
subprocess.run(["convert", user_filename, "output.png"], check=True, shell=False)
```

```javascript
// Bad: eval with user input
const result = eval(userExpression); // Code injection

// Bad: shell command with interpolation
exec(`grep ${userInput} /var/log/app.log`); // Command injection

// Good: safe child process with argument array
execFile("grep", [userInput, "/var/log/app.log"], (err, stdout) => {
  // userInput is passed as an argument, not interpolated into shell
});
```

```python
# Bad: template injection
from jinja2 import Template
Template(user_input).render()  # User controls the template itself

# Good: user input as template data only
from jinja2 import Template
Template("Hello, {{ name }}!").render(name=user_input)
```

---

# Implement Rate Limiting

> Apply rate limiting on authentication endpoints, APIs, and resource-intensive operations to prevent brute force attacks, abuse, and denial of service.

## Rules

- Rate-limit all authentication endpoints (login, registration, password reset, MFA verification) aggressively
- Implement API rate limiting per client (by API key, user ID, or IP address) with appropriate windows and limits
- Use HTTP 429 (Too Many Requests) responses with a `Retry-After` header to inform clients when they are throttled
- Apply progressive penalties: increase lockout duration after repeated violations (exponential backoff)
- Implement account lockout after a configurable number of failed login attempts (e.g., 5-10 attempts)
- Rate-limit resource-intensive operations: file uploads, report generation, bulk exports, search queries
- Use distributed rate limiting (Redis, memcached) in multi-instance deployments to prevent per-instance bypass
- Apply different rate limits for different tiers: stricter for anonymous users, more generous for authenticated users
- Rate-limit by multiple dimensions when appropriate: per IP, per user, per endpoint
- Monitor and alert on rate limit violations — they may indicate attack attempts
- Never rely solely on client-side throttling — always enforce server-side

## Example

```javascript
// Good: rate limiting with express-rate-limit
import rateLimit from "express-rate-limit";

// Strict limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // 10 attempts per window
  message: { error: "Too many attempts, please try again later" },
  standardHeaders: true, // Return rate limit info in headers
});
app.use("/api/auth/", authLimiter);

// General API limit
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100,
  standardHeaders: true,
});
app.use("/api/", apiLimiter);
```

```python
# Good: rate limiting with Flask-Limiter
from flask_limiter import Limiter

limiter = Limiter(app, key_func=get_remote_address)

@app.route("/api/login", methods=["POST"])
@limiter.limit("10 per 15 minutes")
def login():
    ...

@app.route("/api/data")
@limiter.limit("100 per minute")
def get_data():
    ...
```

---

# Use Static Analysis and Linting

> Integrate SAST tools and security-focused linters into CI pipelines to catch vulnerabilities, code quality issues, and anti-patterns before code reaches production.

## Rules

- Integrate static application security testing (SAST) tools into the CI/CD pipeline and run them on every pull request
- Use security-focused linters alongside general linters: `eslint-plugin-security` (JS), `bandit` (Python), `gosec` (Go), `cargo-audit` (Rust), `brakeman` (Ruby)
- Use multi-language SAST scanners (Semgrep, SonarQube, CodeQL) for broad coverage and custom rules
- Treat high and critical SAST findings as build blockers — do not allow merging until resolved
- Configure tools with rules appropriate to your stack — disable irrelevant rules to reduce false positives
- Run secret detection tools (`gitleaks`, `detect-secrets`, `trufflehog`) in CI to catch committed secrets
- Use type checking (`mypy`, `TypeScript`, `go vet`) to catch type-related bugs before runtime
- Review and triage findings regularly — do not let a backlog of ignored warnings accumulate
- Document any suppressed warnings with a justification comment explaining why the finding is a false positive
- Keep SAST tools and rulesets up to date to catch newly discovered vulnerability patterns
- Combine static analysis with code review — tools catch patterns, humans catch logic flaws

## Example

```yaml
# Good: CI pipeline with security scanning
name: Security Analysis
on: [pull_request]

jobs:
  semgrep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/security-audit
            p/owasp-top-ten
            p/secrets

  codeql:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript, python
      - uses: github/codeql-action/analyze@v3

  secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
```

```python
# When suppressing a finding, always document why
password_hash = get_hash(input)  # nosec B105 - not a hardcoded password, variable name is misleading
```

---

# Write Security-Focused Tests

> Test authentication boundaries, input rejection, error responses, and authorization rules explicitly — do not assume security works because the happy path passes.

## Rules

- Write tests that verify authentication is required: unauthenticated requests to protected endpoints must return 401
- Write tests that verify authorization: users must not access resources or actions beyond their role
- Test input validation: verify that malformed, oversized, and malicious inputs are rejected with appropriate error codes
- Test error responses: verify that error messages do not leak stack traces, internal paths, or system details
- Test rate limiting: verify that excessive requests are throttled and return 429
- Test CSRF protection: verify that state-changing requests without valid CSRF tokens are rejected
- Test authentication edge cases: expired tokens, revoked sessions, concurrent sessions, password changes invalidating sessions
- Include negative test cases for every security control — test that the control rejects what it should
- Use fuzz testing to discover unexpected input handling bugs in parsers and validators
- Test that sensitive data is not exposed in API responses, logs, or error messages
- Run security tests in CI — they must pass before merging

## Example

```python
# Good: security-focused test cases
class TestAuthSecurity:
    def test_unauthenticated_access_returns_401(self, client):
        response = client.get("/api/admin/users")
        assert response.status_code == 401

    def test_unauthorized_role_returns_403(self, client, user_token):
        response = client.delete(
            "/api/admin/users/123",
            headers={"Authorization": f"Bearer {user_token}"},
        )
        assert response.status_code == 403

    def test_expired_token_returns_401(self, client, expired_token):
        response = client.get(
            "/api/profile",
            headers={"Authorization": f"Bearer {expired_token}"},
        )
        assert response.status_code == 401

    def test_sql_injection_in_search_is_rejected(self, client, auth_headers):
        response = client.get(
            "/api/users?q=' OR 1=1 --",
            headers=auth_headers,
        )
        assert response.status_code == 400

    def test_error_response_does_not_leak_stack_trace(self, client, auth_headers):
        response = client.get("/api/trigger-error", headers=auth_headers)
        body = response.json()
        assert "traceback" not in str(body).lower()
        assert "stack" not in str(body).lower()
        assert "/home/" not in str(body)
        assert "/usr/" not in str(body)
```

```javascript
// Good: testing authorization boundaries
describe("Authorization", () => {
  it("prevents regular users from accessing admin endpoints", async () => {
    const res = await request(app)
      .delete("/api/admin/users/123")
      .set("Authorization", `Bearer ${userToken}`);
    expect(res.status).toBe(403);
  });

  it("prevents users from accessing other users' data", async () => {
    const res = await request(app)
      .get("/api/users/other-user-id/private")
      .set("Authorization", `Bearer ${userToken}`);
    expect(res.status).toBe(403);
  });
});
```

---

# Follow Secure Code Review Practices

> Review all code changes against a security checklist — flag authentication gaps, input validation issues, hardcoded secrets, and insecure patterns before merging.

## Rules

- Use a security review checklist for every pull request covering: authentication, authorization, input validation, output encoding, secrets, error handling, logging, and dependency changes
- Require at least one reviewer with security awareness for changes touching authentication, authorization, cryptography, or data handling
- Flag any hardcoded credentials, API keys, tokens, or secrets — treat as a blocking finding
- Verify that all user inputs are validated and sanitized before use in queries, commands, templates, or output
- Check that error handling does not leak sensitive information in responses
- Review dependency additions and updates: check for known vulnerabilities, assess the package's maintenance status and trust level
- Verify that new API endpoints have proper authentication and authorization checks
- Look for common anti-patterns: `eval()`, `exec()`, raw SQL concatenation, disabled security features, wildcard CORS
- Check that security-sensitive logic has corresponding test coverage
- Review infrastructure and configuration changes (Dockerfiles, CI/CD, Terraform) for security implications
- Document security decisions and trade-offs in review comments for future reference
- Never approve code that introduces a known vulnerability, even under deadline pressure

## Security Review Checklist

```markdown
## Security Review

- [ ] No hardcoded secrets, API keys, or credentials
- [ ] All inputs validated and sanitized at system boundaries
- [ ] Parameterized queries used (no SQL string concatenation)
- [ ] Output properly encoded for context (HTML, JS, URL)
- [ ] Authentication required on all protected endpoints
- [ ] Authorization checks verify resource ownership and role
- [ ] Error responses do not leak internal details
- [ ] Security events are logged (auth, access denied, etc.)
- [ ] New dependencies audited for vulnerabilities
- [ ] Security-sensitive changes have test coverage
```

## Example

```markdown
# Pull Request Review Comment Examples

## Blocking: Hardcoded secret
> Line 42: `const API_KEY = "sk-live-..."` — this must be moved to an
> environment variable. Secrets must never be committed to source code.

## Blocking: Missing authorization
> `DELETE /api/users/:id` has authentication but no authorization check.
> Any authenticated user can delete any other user. Add an ownership or
> role check before proceeding with deletion.

## Non-blocking: Improvement suggestion
> Consider adding rate limiting to this registration endpoint to prevent
> automated abuse. Not blocking, but should be addressed before GA.
```

---

# Vulnerability Scanning

Before considering security-sensitive code complete, run these scanning tools. If a tool is not installed, skip it and suggest the install command to the user.

- **trivy** — filesystem and dependency vulnerability scanning: `trivy fs .`
  Install: `brew install trivy` or see https://aquasecurity.github.io/trivy
- **semgrep** — OWASP top 10 pattern detection: `semgrep --config auto`
  Install: `pip install semgrep` or see https://semgrep.dev
- **gitleaks** — secret detection in git repositories: `gitleaks detect --source .`
  Install: `brew install gitleaks` or see https://github.com/gitleaks/gitleaks

Run all three tools and address findings before merging.

---

# Unsafe Code Detection

When reviewing code, flag the following dangerous patterns:

- **SQL injection** — raw SQL queries built with string concatenation or interpolation. Always use parameterized queries or prepared statements.
- **Command injection** — unsanitized user input passed to shell execution functions (e.g., `os.system()`, `exec()`, `child_process.exec()`). Use allow-lists and avoid shell invocation.
- **XSS (Cross-Site Scripting)** — unescaped user input rendered in HTML output. Always escape or sanitize output contextually.
- **Path traversal** — unsanitized file paths that could resolve outside intended directories (e.g., `../../etc/passwd`). Canonicalize and validate paths against a base directory.
- **Deserialization attacks** — untrusted data passed to deserialization functions (e.g., `pickle.loads()`, `yaml.load()`, `JSON.parse()` with reviver abuse). Use safe loaders and validate schemas.
- **SSRF (Server-Side Request Forgery)** — user-controlled URLs used in server-side HTTP requests. Validate and restrict URLs to allowed hosts and schemes.
