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
