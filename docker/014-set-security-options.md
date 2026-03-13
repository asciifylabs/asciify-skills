# Set Security Options

> Apply security hardening options to prevent privilege escalation, restrict system calls, and limit container capabilities at runtime.

## Rules

- Set `no-new-privileges` to prevent processes from gaining additional privileges via setuid/setgid binaries
- Use seccomp profiles to restrict which system calls a container can make — at minimum, use Docker's default profile
- Use AppArmor or SELinux profiles for mandatory access control
- Disable privilege escalation with `allowPrivilegeEscalation: false` in Kubernetes
- Set `runAsNonRoot: true` in Kubernetes pod security context as a safety net
- Use `securityContext.seccompProfile.type: RuntimeDefault` in Kubernetes for the default seccomp profile

## Example

```bash
# Good: runtime hardening flags
docker run \
  --security-opt no-new-privileges \
  --security-opt seccomp=default.json \
  --cap-drop=ALL \
  --read-only \
  myapp
```

```yaml
# Kubernetes: comprehensive security context
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: myapp:1.0.0
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
```
