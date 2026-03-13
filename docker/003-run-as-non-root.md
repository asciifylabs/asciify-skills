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
