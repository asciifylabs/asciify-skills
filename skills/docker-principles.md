---
name: docker-principles
description: "Use when writing, reviewing, or modifying Dockerfiles, docker-compose files, or container configurations"
---

# Docker Principles

These are non-negotiable coding standards -- if you are about to write code that violates a principle, stop and fix it. When reviewing code, flag any violations.

# Use Specific Image Tags

> Never use `latest` or untagged images. Always pin to a specific version tag or digest to ensure reproducible builds.

## Rules

- Always specify an explicit version tag for base images (e.g., `python:3.12-slim`, not `python` or `python:latest`)
- For maximum reproducibility, pin images by digest (e.g., `python@sha256:abc123...`)
- Use semantic version tags that match your stability requirements (e.g., `node:20-alpine` for minor updates, `node:20.11.0-alpine` for exact pinning)
- Never use `latest` — it is mutable and can change without warning, breaking builds
- Document why a specific version was chosen when it is not the current latest

## Example

```dockerfile
# Bad: mutable tags
FROM python
FROM node:latest
FROM ubuntu:rolling

# Good: pinned versions
FROM python:3.12-slim
FROM node:20.11.0-alpine
FROM ubuntu:24.04

# Best: pinned by digest for immutable builds
FROM python:3.12-slim@sha256:1a2b3c4d...
```

---

# Use Multi-Stage Builds

> Use multi-stage builds to separate build dependencies from the runtime image, producing smaller and more secure final images.

## Rules

- Use a builder stage for compilation, dependency installation, and asset generation
- Copy only the necessary artifacts into the final runtime stage
- Name stages explicitly with `AS` for clarity (e.g., `FROM golang:1.22 AS builder`)
- Use the smallest possible base image for the final stage (e.g., `distroless`, `alpine`, `slim`)
- Never ship build tools, compilers, or package managers in production images
- Use `--from=builder` to copy artifacts between stages

## Example

```dockerfile
# Bad: single stage with build tools in production
FROM golang:1.22
WORKDIR /app
COPY . .
RUN go build -o server .
CMD ["./server"]

# Good: multi-stage build
FROM golang:1.22 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o server .

FROM gcr.io/distroless/static:nonroot
COPY --from=builder /app/server /server
USER nonroot:nonroot
ENTRYPOINT ["/server"]
```

---

# Run as Non-Root User

> Never run containers as root. Create and switch to a non-root user to limit the blast radius of container escapes.

## Rules

- Always include a `USER` instruction in the Dockerfile to run as a non-privileged user
- Create a dedicated user and group for the application (e.g., `appuser`)
- Set `USER` after installing packages and before `CMD`/`ENTRYPOINT`
- Ensure application files are owned by root but readable by the app user — this prevents the running process from modifying its own binary
- Use numeric UIDs in the `USER` instruction for compatibility with security policies (e.g., `USER 1000:1000`)
- When using distroless images, use the built-in `nonroot` user

## Example

```dockerfile
# Bad: running as root (default)
FROM python:3.12-slim
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]

# Good: dedicated non-root user
FROM python:3.12-slim
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser
WORKDIR /app
COPY --chown=root:root requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY --chown=root:root . .
USER 1000:1000
CMD ["python", "app.py"]
```

---

# Use .dockerignore

> Always include a `.dockerignore` file to exclude unnecessary files from the build context, reducing image size and preventing secrets from leaking into images.

## Rules

- Create a `.dockerignore` file in every project that uses Docker
- Exclude version control directories (`.git/`), IDE configs, and OS files
- Exclude secrets, credentials, and environment files (`.env`, `*.pem`, `*.key`)
- Exclude test files, documentation, and CI/CD configs that are not needed at runtime
- Exclude `node_modules/`, `__pycache__/`, `target/`, and other dependency/build directories — these should be installed fresh inside the build
- Exclude the `Dockerfile` itself and `docker-compose*.yml`
- Review `.dockerignore` when adding new file types to the project

## Example

```
# Bad: no .dockerignore — everything gets sent to the build context

# Good: comprehensive .dockerignore
.git
.gitignore
.env
.env.*
*.md
LICENSE
Dockerfile
docker-compose*.yml
.dockerignore

# IDE and OS
.vscode/
.idea/
*.swp
.DS_Store

# Dependencies and build artifacts
node_modules/
__pycache__/
*.pyc
target/
dist/
coverage/

# Secrets and credentials
*.pem
*.key
*.crt
credentials/
```

---

# Minimize Layers and Image Size

> Combine related commands, clean up in the same layer, and remove unnecessary files to keep images small and reduce the attack surface.

## Rules

- Chain related `RUN` commands with `&&` to reduce the number of layers
- Remove package manager caches in the same `RUN` layer that installs packages (e.g., `rm -rf /var/lib/apt/lists/*`)
- Use `--no-cache-dir` for pip, `--no-cache` for apk
- Do not install recommended or suggested packages (`apt-get install --no-install-recommends`)
- Remove temporary files, documentation, and man pages in the same layer they are created
- Order Dockerfile instructions from least-frequently changing to most-frequently changing to maximize cache hits
- Place `COPY` for dependency manifests (e.g., `requirements.txt`, `package.json`) before copying the full source

## Example

```dockerfile
# Bad: multiple layers, cache not cleaned
FROM ubuntu:24.04
RUN apt-get update
RUN apt-get install -y python3 python3-pip curl wget vim
RUN rm -rf /var/lib/apt/lists/*

# Good: single layer, minimal install, cache cleaned
FROM ubuntu:24.04
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-pip curl && \
    rm -rf /var/lib/apt/lists/*
```

---

# Use COPY Instead of ADD

> Prefer `COPY` over `ADD` unless you specifically need `ADD`'s extra features. `COPY` is explicit and predictable.

## Rules

- Use `COPY` for copying local files and directories into the image
- Only use `ADD` when you need automatic tar extraction or fetching remote URLs (and prefer `curl`/`wget` + `RUN` over `ADD` for remote URLs)
- `ADD` has implicit behavior (auto-extraction, remote fetch) that can introduce unexpected files or security risks
- Never use `ADD` with remote URLs to untrusted sources — use `curl` or `wget` in a `RUN` step so you can verify checksums
- Use `COPY --chown` to set file ownership in the same layer

## Example

```dockerfile
# Bad: ADD when COPY would suffice
ADD . /app
ADD config.json /etc/app/config.json

# Bad: ADD for remote files (no checksum verification)
ADD https://example.com/binary /usr/local/bin/binary

# Good: explicit COPY
COPY . /app
COPY config.json /etc/app/config.json

# Good: download with verification
RUN curl -fsSL https://example.com/binary -o /usr/local/bin/binary && \
    echo "expected_sha256  /usr/local/bin/binary" | sha256sum -c - && \
    chmod +x /usr/local/bin/binary
```

---

# Set Health Checks

> Define `HEALTHCHECK` instructions so Docker can detect when a container is unhealthy and orchestrators can respond appropriately.

## Rules

- Include a `HEALTHCHECK` in every Dockerfile for long-running services
- Use lightweight health check commands that verify the application is actually serving (e.g., an HTTP endpoint), not just that the process is running
- Set appropriate `--interval`, `--timeout`, `--start-period`, and `--retries` values
- Use `--start-period` to allow time for application startup before health checks begin
- Avoid health checks that are expensive or cause side effects
- For non-HTTP services, check the relevant protocol (TCP connect, database ping, etc.)

## Example

```dockerfile
# Bad: no health check — Docker assumes the container is always healthy

# Good: HTTP health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Good: for images without curl, use a minimal binary
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["/app/healthcheck"]

# Good: TCP check for non-HTTP services
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD pg_isready -U postgres || exit 1
```

---

# Never Store Secrets in Images

> Never bake secrets, credentials, API keys, or tokens into Docker images. They persist in image layers and can be extracted.

## Rules

- Never use `ENV` for secrets — environment variables in Dockerfiles are baked into the image metadata and visible via `docker inspect`
- Never `COPY` secret files (`.env`, certificates, private keys) into the image
- Use BuildKit secrets (`--mount=type=secret`) for build-time secrets (e.g., private package registry tokens)
- Pass runtime secrets via environment variables at `docker run` time, mounted secret files, or a secrets manager
- Use `.dockerignore` to prevent accidental inclusion of secret files in the build context
- If a secret was ever baked into an image layer, consider that secret compromised and rotate it

## Example

```dockerfile
# Bad: secret baked into image layer
ENV API_KEY=sk-1234567890abcdef
COPY .env /app/.env
RUN curl -H "Authorization: Bearer $API_KEY" https://registry.example.com/package.tar.gz

# Good: BuildKit secret mount (never persisted in layers)
# syntax=docker/dockerfile:1
RUN --mount=type=secret,id=registry_token \
    REGISTRY_TOKEN=$(cat /run/secrets/registry_token) && \
    curl -H "Authorization: Bearer $REGISTRY_TOKEN" https://registry.example.com/package.tar.gz

# Good: runtime secrets via docker run
# docker run -e API_KEY="$API_KEY" myapp
# docker run -v /run/secrets:/run/secrets:ro myapp
```

---

# Use Read-Only Filesystem

> Run containers with a read-only root filesystem to prevent runtime tampering, malware persistence, and unauthorized modifications.

## Rules

- Design containers so the root filesystem can be mounted read-only (`--read-only` flag or `readOnlyRootFilesystem: true` in Kubernetes)
- Use `tmpfs` mounts for directories that need write access (e.g., `/tmp`, `/var/run`)
- Use named volumes for application data that must persist
- Ensure application logs write to stdout/stderr (not files) so the filesystem stays read-only
- Test the image with `docker run --read-only` during development to catch write dependencies early
- Document any directories that require write access

## Example

```dockerfile
# Good: designed for read-only filesystem
FROM python:3.12-slim
RUN groupadd -r appuser && useradd -r -g appuser appuser
WORKDIR /app
COPY --chown=root:root . .
RUN pip install --no-cache-dir -r requirements.txt
USER appuser
# Application writes only to stdout/stderr
CMD ["python", "app.py"]

# Run with read-only filesystem:
# docker run --read-only --tmpfs /tmp:rw,noexec,nosuid myapp
```

```yaml
# Kubernetes: read-only root filesystem
securityContext:
  readOnlyRootFilesystem: true
volumeMounts:
  - name: tmp
    mountPath: /tmp
volumes:
  - name: tmp
    emptyDir:
      medium: Memory
      sizeLimit: 64Mi
```

---

# Scan Images for Vulnerabilities

> Scan every Docker image for known vulnerabilities before pushing to a registry or deploying to production.

## Rules

- Integrate image scanning into the CI/CD pipeline — fail builds on critical or high vulnerabilities
- Use tools like `trivy`, `grype`, or `docker scout` for scanning
- Scan both the base image and the final built image
- Rebuild images regularly to pick up patched base image versions
- Monitor running images for newly disclosed vulnerabilities
- Fix vulnerabilities by updating base images, packages, or dependencies — do not ignore them
- Use `trivy image --severity HIGH,CRITICAL` to focus on actionable findings

## Example

```bash
# Scan with trivy
trivy image --severity HIGH,CRITICAL myapp:latest

# Scan during build in CI
docker build -t myapp:latest .
trivy image --exit-code 1 --severity CRITICAL myapp:latest

# Scan with grype
grype myapp:latest

# Scan with docker scout
docker scout cves myapp:latest
```

```yaml
# CI pipeline example (GitHub Actions)
- name: Build image
  run: docker build -t myapp:${{ github.sha }} .

- name: Scan for vulnerabilities
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:${{ github.sha }}
    exit-code: 1
    severity: CRITICAL,HIGH
```

---

# Drop All Capabilities

> Drop all Linux capabilities and add back only the specific ones your application needs. This limits what a compromised container can do.

## Rules

- Drop all capabilities with `--cap-drop=ALL` and add back only what is required
- Most applications need zero additional capabilities — start with none and add only if the application fails
- Never use `--privileged` — it grants full host access and disables all security protections
- Never add `SYS_ADMIN` — it is nearly equivalent to `--privileged`
- Common legitimate capabilities: `NET_BIND_SERVICE` (bind to ports below 1024), `CHOWN`, `SETUID`/`SETGID` (for init processes)
- Document why each added capability is required
- In Kubernetes, set capabilities in the `securityContext`

## Example

```bash
# Bad: privileged container
docker run --privileged myapp

# Bad: default capabilities (too permissive)
docker run myapp

# Good: drop all, add only what is needed
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE myapp
```

```yaml
# Kubernetes: drop all capabilities
securityContext:
  capabilities:
    drop:
      - ALL
    add:
      - NET_BIND_SERVICE
  allowPrivilegeEscalation: false
```

---

# Use Minimal Base Images

> Use the smallest base image that meets your application's requirements to minimize the attack surface and image size.

## Rules

- Prefer `distroless` images for compiled languages (Go, Rust, Java) — they contain only the application and its runtime dependencies
- Use `alpine` variants when you need a shell and package manager but want a small footprint
- Use `slim` variants (e.g., `python:3.12-slim`) over full images when alpine is not compatible
- Never use full OS images (e.g., `ubuntu`, `debian`) as base images for production unless absolutely necessary
- Fewer packages installed means fewer CVEs to patch and a smaller attack surface
- Evaluate the trade-off: `distroless` (smallest, no shell for debugging) vs. `alpine` (small, has shell) vs. `slim` (medium, better compatibility)

## Example

```dockerfile
# Bad: full OS image (900MB+, hundreds of unnecessary packages)
FROM ubuntu:24.04

# Better: slim variant (~150MB)
FROM python:3.12-slim

# Good: alpine variant (~50MB)
FROM python:3.12-alpine

# Best for compiled languages: distroless (~20MB)
FROM gcr.io/distroless/static:nonroot

# Best for Java: distroless Java image
FROM gcr.io/distroless/java21-debian12:nonroot
```

---

# Use Exec Form for CMD and ENTRYPOINT

> Always use the exec form (JSON array) for `CMD` and `ENTRYPOINT` so the application runs as PID 1 and receives signals correctly.

## Rules

- Use exec form `["executable", "arg1", "arg2"]` instead of shell form `executable arg1 arg2`
- Shell form wraps the command in `/bin/sh -c`, which means the application is not PID 1 and does not receive `SIGTERM` for graceful shutdown
- Use `ENTRYPOINT` for the main executable and `CMD` for default arguments that can be overridden
- If you need shell features (variable expansion, pipes), use an explicit shell: `["/bin/sh", "-c", "command"]`
- Never combine `ENTRYPOINT` shell form with `CMD` — the behavior is unpredictable
- Ensure the application handles `SIGTERM` for clean shutdown in container orchestrators

## Example

```dockerfile
# Bad: shell form — app runs under /bin/sh, does not receive signals
ENTRYPOINT python app.py
CMD python app.py --port 8080

# Good: exec form — app is PID 1, receives SIGTERM
ENTRYPOINT ["python", "app.py"]
CMD ["--port", "8080"]

# Good: explicit shell when needed
CMD ["/bin/sh", "-c", "envsubst < config.tmpl > config.json && exec python app.py"]
```

---

# Set Security Options

> Apply security hardening options to prevent privilege escalation, restrict system calls, and limit container capabilities at runtime.

## Rules

- Set `no-new-privileges` to prevent processes from gaining additional privileges via setuid/setgid binaries
- Use seccomp profiles to restrict which system calls a container can make — at minimum, use Docker's default profile
- Use AppArmor or SELinux profiles for mandatory access control
- Disable privilege escalation with `allowPrivilegeEscalation: false` in Kubernetes
- Set `runAsNonRoot: true` in Kubernetes pod security context as a safety net
- Use `securityContext.seccompProfile.type: RuntimeDefault` in Kubernetes for the default seccomp profile

## Example

```bash
# Good: runtime hardening flags
docker run \
  --security-opt no-new-privileges \
  --security-opt seccomp=default.json \
  --cap-drop=ALL \
  --read-only \
  myapp
```

```yaml
# Kubernetes: comprehensive security context
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: myapp:1.0.0
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
```

---

# Use BuildKit Features

> Use Docker BuildKit for faster builds, better caching, secret handling, and advanced Dockerfile features.

## Rules

- Enable BuildKit with `DOCKER_BUILDKIT=1` or configure it as the default builder
- Use `# syntax=docker/dockerfile:1` at the top of Dockerfiles to access the latest Dockerfile syntax features
- Use `--mount=type=cache` to cache package manager directories across builds (e.g., `/root/.cache/pip`, `/var/cache/apt`)
- Use `--mount=type=secret` for build-time secrets that must not persist in image layers
- Use `--mount=type=ssh` for SSH agent forwarding during builds (e.g., accessing private git repos)
- Use `.dockerignore` effectively — BuildKit only sends files not excluded by `.dockerignore` to the build context

## Example

```dockerfile
# syntax=docker/dockerfile:1

FROM python:3.12-slim AS builder

# Good: cache pip downloads across builds
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# Good: use build secret without baking into layers
RUN --mount=type=secret,id=github_token \
    GITHUB_TOKEN=$(cat /run/secrets/github_token) && \
    pip install git+https://${GITHUB_TOKEN}@github.com/org/private-pkg.git

# Good: cache apt packages
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends build-essential
```

```bash
# Build with BuildKit and secrets
DOCKER_BUILDKIT=1 docker build \
  --secret id=github_token,src=$HOME/.github_token \
  -t myapp:latest .
```

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **hadolint** — Dockerfile linter following best practices: `hadolint Dockerfile`
  Install: `brew install hadolint` or `docker run --rm -i hadolint/hadolint < Dockerfile`
- **docker scout** — scan images for vulnerabilities: `docker scout cves myimage:tag`
- **trivy** — scan images and config files: `trivy config Dockerfile`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
