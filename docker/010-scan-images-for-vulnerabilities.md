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
