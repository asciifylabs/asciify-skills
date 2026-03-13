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
