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
