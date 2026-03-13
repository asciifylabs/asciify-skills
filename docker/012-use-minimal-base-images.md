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
