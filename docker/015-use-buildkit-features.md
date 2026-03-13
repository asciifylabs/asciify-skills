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
