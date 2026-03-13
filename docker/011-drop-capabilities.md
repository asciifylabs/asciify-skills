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
