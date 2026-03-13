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
