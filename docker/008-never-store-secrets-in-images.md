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
