---
name: kubernetes-principles
description: "Use when writing, reviewing, or modifying Kubernetes manifests or Helm charts"
globs: ["**/k8s/**/*.yml", "**/k8s/**/*.yaml", "**/helm/**/*.yml", "**/helm/**/*.yaml", "**/Chart.yaml", "**/values.yaml"]
---

# Kubernetes Principles

These are non-negotiable coding standards -- if you are about to write code that violates a principle, stop and fix it. When reviewing code, flag any violations.

# Use Namespaces for Isolation

> Logically separate workloads using namespaces to enforce security boundaries, resource quotas, and RBAC.

## Rules

- Create dedicated namespaces for each application or team
- Use namespaces to separate environments (dev, staging, prod) when using a single cluster
- Apply resource quotas and limit ranges per namespace
- Use network policies scoped to namespaces
- Implement RBAC policies at the namespace level
- Reserve `kube-system` and `kube-public` for system components only
- Remember that some resources are cluster-scoped (CRDs, ClusterRoles) and cannot be namespaced

## Example

```yaml
# Create namespace with labels
apiVersion: v1
kind: Namespace
metadata:
  name: payments-service
  labels:
    team: platform
    environment: production
    cost-center: payments

---
# Apply resource quota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: payments-quota
  namespace: payments-service
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    pods: "50"
```

---

# Set Resource Requests and Limits

> Always define resource requests and limits for every container to ensure predictable scheduling and prevent resource starvation.

## Rules

- Set **requests** (minimum guaranteed resources) based on normal operating needs
- Set **limits** (maximum resources) to prevent runaway consumption
- For critical workloads, set requests equal to limits (Guaranteed QoS class)
- Use LimitRange to enforce defaults per namespace
- Monitor actual usage and adjust values based on metrics
- Do not over-provision (wastes resources) or under-provision (causes throttling/OOM kills)
- Understand QoS classes: Guaranteed (requests=limits), Burstable (requests<limits), BestEffort (no requests/limits)

## Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: api-server
spec:
  containers:
    - name: api
      image: api-server:v1.2.3
      resources:
        requests:
          cpu: 100m      # 0.1 CPU cores
          memory: 256Mi  # 256 MiB RAM
        limits:
          cpu: 500m      # 0.5 CPU cores
          memory: 512Mi  # 512 MiB RAM

---
# Namespace-level defaults
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: production
spec:
  limits:
    - default:
        cpu: 500m
        memory: 512Mi
      defaultRequest:
        cpu: 100m
        memory: 256Mi
      type: Container
```

---

# Use Liveness and Readiness Probes

> Configure appropriate health probes for all containers so Kubernetes can detect failures and manage traffic routing.

## Rules

- **Readiness probe**: Determines if a pod should receive traffic -- use for zero-downtime deployments
- **Liveness probe**: Determines if a container should be restarted -- keep these lightweight
- **Startup probe**: Use for slow-starting applications (Kubernetes 1.18+) to avoid premature liveness failures
- Choose appropriate probe type: HTTP, TCP, or exec
- Set sensible timeouts and thresholds
- Do not put expensive checks in liveness probes (they run frequently and can cause restart loops)
- Readiness probes can be more comprehensive than liveness probes

## Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-app
spec:
  containers:
    - name: app
      image: web-app:v1.0.0
      ports:
        - containerPort: 8080

      # Check if app is ready to serve traffic
      readinessProbe:
        httpGet:
          path: /health/ready
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 10
        successThreshold: 1
        failureThreshold: 3

      # Check if app is alive (restart if not)
      livenessProbe:
        httpGet:
          path: /health/live
          port: 8080
        initialDelaySeconds: 15
        periodSeconds: 20
        timeoutSeconds: 5
        failureThreshold: 3

      # For slow-starting apps
      startupProbe:
        httpGet:
          path: /health/live
          port: 8080
        failureThreshold: 30
        periodSeconds: 10
```

---

# Use ConfigMaps and Secrets Properly

> Externalize all configuration using ConfigMaps for non-sensitive data and Secrets for sensitive data -- never hardcode into images.

## Rules

- Use ConfigMaps for non-sensitive configuration data
- Use Secrets for sensitive data (passwords, tokens, certificates)
- Mount as files or environment variables depending on use case
- Use immutable ConfigMaps/Secrets when possible for performance
- Never commit Secrets to version control
- Consider external secret management (Vault, External Secrets Operator)
- Use sealed-secrets or SOPS for GitOps workflows
- Base64 encoding in Secrets is NOT encryption -- anyone with RBAC access can read them
- ConfigMap/Secret size is limited to 1MB
- Changes require pod restart unless using a reloader

## Example

```yaml
# ConfigMap for application config
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
  config.yaml: |
    server:
      port: 8080
    cache:
      ttl: 300

---
# Secret for sensitive data
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: production
type: Opaque
stringData:  # Use stringData for clarity (auto base64 encoded)
  DATABASE_PASSWORD: "supersecret"
  API_KEY: "abc123"

---
# Pod using both
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
    - name: app
      image: myapp:v1
      envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: app-config
        items:
          - key: config.yaml
            path: config.yaml
```

---

# Use Labels and Annotations Consistently

> Establish and enforce labeling conventions using `app.kubernetes.io/*` recommended labels on all resources.

## Rules

- **Labels**: Use for selection, grouping, and filtering (used by selectors)
- **Annotations**: Use for non-identifying metadata (URLs, descriptions, tool config)
- Use recommended `app.kubernetes.io/*` labels on all resources
- Include labels for: app name, version, component, environment, team/owner
- Use annotations for ingress config, Prometheus scraping, etc.
- Do not change labels used in selectors (this is disruptive)
- Labels are limited to 63 characters

### Recommended Labels

| Label | Purpose |
|-------|---------|
| `app.kubernetes.io/name` | Application name |
| `app.kubernetes.io/instance` | Instance identifier |
| `app.kubernetes.io/version` | Application version |
| `app.kubernetes.io/component` | Component type (frontend, backend, database) |
| `app.kubernetes.io/part-of` | Higher-level application |
| `app.kubernetes.io/managed-by` | Tool managing resource (helm, argocd) |

## Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  labels:
    app.kubernetes.io/name: api-server
    app.kubernetes.io/instance: api-server-prod
    app.kubernetes.io/version: "1.2.3"
    app.kubernetes.io/component: backend
    app.kubernetes.io/part-of: payments-platform
    app.kubernetes.io/managed-by: argocd
    team: platform
    environment: production
    cost-center: payments
  annotations:
    description: "Main API server for payments platform"
    oncall: "platform-team@company.com"
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: api-server
      app.kubernetes.io/instance: api-server-prod
  template:
    metadata:
      labels:
        app.kubernetes.io/name: api-server
        app.kubernetes.io/instance: api-server-prod
        app.kubernetes.io/version: "1.2.3"
```

---

# Use PodDisruptionBudgets for High Availability

> Define PodDisruptionBudgets for all critical workloads to guarantee minimum availability during voluntary disruptions.

## Rules

- Specify `minAvailable` OR `maxUnavailable` (not both)
- Use percentages for workloads with variable replica counts (e.g., HPA)
- Always create PDBs for production deployments with replicas > 1
- Do not set PDBs that block all disruption (e.g., `minAvailable` = total replicas) -- this blocks node drains
- For stateful workloads, set `minAvailable` to maintain quorum
- PDBs only protect against voluntary disruptions (node drains, upgrades) -- not involuntary ones (node failure)
- Test PDB configuration during maintenance windows

## Example

```yaml
# Percentage-based (recommended for HPA workloads)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-server-pdb
  namespace: production
spec:
  minAvailable: 50%
  selector:
    matchLabels:
      app.kubernetes.io/name: api-server

---
# Absolute number-based
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: cache-pdb
  namespace: production
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: redis-cache

---
# For stateful workloads (e.g., etcd, databases)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: etcd-pdb
spec:
  minAvailable: 2  # Maintain quorum (for 3-node cluster)
  selector:
    matchLabels:
      app: etcd
```

---

# Use Network Policies for Zero-Trust Security

> Implement default-deny network policies per namespace, then explicitly allow only required traffic flows.

## Rules

- Start with a default-deny policy per namespace (both ingress and egress)
- Explicitly allow only required traffic flows
- Use pod selectors to target specific workloads
- Separate ingress (incoming) and egress (outgoing) rules
- Always allow DNS egress (UDP port 53) for service discovery
- Requires a CNI that supports network policies (Cilium, Calico)
- Document network policies alongside application deployments
- Test policies in non-production environments first

## Example

```yaml
# Default deny all traffic in namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress

---
# Allow specific traffic for API server
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-server-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api-server
  policyTypes:
    - Ingress
    - Egress
  ingress:
    # Allow from ingress controller
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
          podSelector:
            matchLabels:
              app: ingress-nginx
      ports:
        - protocol: TCP
          port: 8080
  egress:
    # Allow DNS
    - to:
        - namespaceSelector: {}
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
    # Allow to database
    - to:
        - podSelector:
            matchLabels:
              app: postgres
      ports:
        - protocol: TCP
          port: 5432
```

---

# Use RBAC with Least Privilege

> Implement RBAC following least privilege -- never use cluster-admin for applications, create namespace-scoped Roles with specific permissions.

## Rules

- Never use `cluster-admin` for applications or regular users
- Prefer namespace-scoped Roles over cluster-wide ClusterRoles
- Define specific resource and verb permissions -- avoid wildcards (`*`)
- Create dedicated ServiceAccounts per application
- Use RoleBindings to assign Roles to ServiceAccounts
- Audit RBAC permissions regularly
- Use RBAC aggregation for composable roles
- Set `automountServiceAccountToken: true` only when the pod actually needs API access

## Example

```yaml
# Dedicated ServiceAccount for application
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-server
  namespace: production

---
# Namespace-scoped Role with specific permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: api-server-role
  namespace: production
rules:
  # Read ConfigMaps and Secrets
  - apiGroups: [""]
    resources: ["configmaps", "secrets"]
    verbs: ["get", "list", "watch"]
  # Manage own pods (for leader election, etc.)
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  # Create events
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "patch"]

---
# Bind role to ServiceAccount
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: api-server-binding
  namespace: production
subjects:
  - kind: ServiceAccount
    name: api-server
    namespace: production
roleRef:
  kind: Role
  name: api-server-role
  apiGroup: rbac.authorization.k8s.io

---
# Use ServiceAccount in Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: production
spec:
  template:
    spec:
      serviceAccountName: api-server
      automountServiceAccountToken: true  # Only if needed
      containers:
        - name: api
          image: api-server:v1
```

---

# Use Pod Security Standards

> Enforce Pod Security Standards at the namespace level -- use `restricted` for production, `baseline` for legacy apps during migration.

## Rules

- Apply Pod Security Admission (PSA) labels to namespaces to enforce standards
- **Privileged**: Unrestricted -- only for system workloads
- **Baseline**: Minimally restrictive -- prevents known privilege escalations
- **Restricted**: Heavily restricted -- use for production workloads
- Configure security contexts explicitly in pod specs
- Do not run containers as root
- Always set `allowPrivilegeEscalation: false`
- Use `readOnlyRootFilesystem: true` and mount writable paths as emptyDir
- Drop all capabilities with `capabilities.drop: [ALL]`
- Set `seccompProfile.type: RuntimeDefault`

## Example

```yaml
# Enable Pod Security Standards on namespace
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    # Enforce restricted standard
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    # Warn on violations (useful for migration)
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/audit: restricted

---
# Pod following restricted standard
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
  namespace: production
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: myapp:v1
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        capabilities:
          drop:
            - ALL
      volumeMounts:
        - name: tmp
          mountPath: /tmp
  volumes:
    - name: tmp
      emptyDir: {}
```

---

# Use PriorityClasses for Workload Prioritization

> Define PriorityClasses to ensure critical workloads are scheduled first and protected from eviction during resource pressure.

## Rules

- Use built-in `system-cluster-critical` and `system-node-critical` for system components
- Create custom PriorityClasses for application tiers (high, standard, low)
- Assign higher priority to production workloads
- Use lower priority for batch jobs and development workloads
- Set `preemptionPolicy: PreemptLowerPriority` for critical workloads
- Set `preemptionPolicy: Never` for batch/low-priority workloads to avoid evicting others
- Do not set all workloads to high priority -- this defeats the purpose
- Set one PriorityClass as `globalDefault: true` for standard workloads

## Example

```yaml
# High priority for production workloads
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: production-high
value: 1000000
globalDefault: false
preemptionPolicy: PreemptLowerPriority
description: "High priority for production-critical workloads"

---
# Medium priority for standard production
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: production-standard
value: 100000
globalDefault: true  # Default for all pods
preemptionPolicy: PreemptLowerPriority
description: "Standard priority for production workloads"

---
# Low priority for batch/dev workloads
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: batch-low
value: 1000
globalDefault: false
preemptionPolicy: Never  # Don't evict other pods
description: "Low priority for batch jobs and dev workloads"

---
# Use in deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-processor
spec:
  template:
    spec:
      priorityClassName: production-high
      containers:
        - name: processor
          image: payment-processor:v1
```

---

# Cilium - Choose the Right Routing Mode

> Select native routing for maximum performance when the network supports it, or tunnel mode (VXLAN/Geneve) for universal compatibility.

## Rules

- **Native routing** (`routingMode: native`): Best performance, no encapsulation overhead, requires network support (BGP, cloud CNI integration), pod IPs must be routable
- **Tunnel/VXLAN** (`routingMode: tunnel`, `tunnelProtocol: vxlan`): Widely compatible, works over any IP network, ~50 bytes overhead
- **Tunnel/Geneve** (`routingMode: tunnel`, `tunnelProtocol: geneve`): More flexible, supports metadata, preferred for new tunnel deployments
- Use `autoDirectNodeRoutes: true` with native routing on flat networks
- Cloud providers: use native routing with cloud integration
- On-premises with BGP: use native routing
- VPN/overlay networks: use tunnel mode (VXLAN)
- Unknown/mixed environments: default to tunnel mode for compatibility

## Example

```yaml
# Tunnel mode for overlay networks (e.g., WireGuard)
routingMode: tunnel
tunnelProtocol: vxlan
tunnelPort: 8472
autoDirectNodeRoutes: false

# Calculate MTU: underlying_mtu - vxlan_overhead - safety_margin
# WireGuard (1280) - VXLAN (50) - safety (30) = 1200
MTU: 1200

---
# Native routing for cloud/BGP environments
routingMode: native
autoDirectNodeRoutes: true
ipam:
  mode: cluster-pool  # or kubernetes

# Use BGP for route advertisement
bgpControlPlane:
  enabled: true
```

---

# Cilium - Configure MTU Properly

> Calculate and set MTU accounting for all encapsulation layers to prevent packet fragmentation and connectivity failures.

## Rules

- Formula: `Final MTU = Physical MTU - Overlay Overhead - Cilium Overhead - Safety Margin`
- Enable path MTU discovery when possible
- Enable `enableIPv4FragmentsTracking: true` for overlay networks
- Test MTU with actual traffic patterns
- Monitor for ICMP "fragmentation needed" messages
- Do not include overlay interfaces (wt0, wg0, vxlan.cilium) in the `devices` list
- Set `bpf.hostLegacyRouting: false` for performance

### Common Overhead Values

| Layer | Overhead |
|-------|----------|
| VXLAN | 50 bytes |
| Geneve | 50 bytes |
| WireGuard | 60-80 bytes |
| IPsec | 50-70 bytes |
| IPv6 | 20 bytes (vs IPv4) |

### Example Calculations

- Standard network (1500 MTU) with VXLAN: `1500 - 50 = 1450`
- WireGuard (1280 MTU) with VXLAN: `1280 - 50 - 30 = 1200`
- Cloud (jumbo frames 9000) with VXLAN: `9000 - 50 = 8950`

## Example

```yaml
# Cilium configuration for WireGuard + VXLAN
# Physical interface: WireGuard with MTU 1280
# Cilium tunnel: VXLAN (50 bytes overhead)
# Safety margin: 30 bytes
MTU: 1200

# Enable fragment tracking for overlay networks
# Required when packets may be fragmented before reaching Cilium
enableIPv4FragmentsTracking: true

# BPF settings for proper packet handling
bpf:
  masquerade: true
  # Disable host legacy routing for performance
  hostLegacyRouting: false

# Specify devices to attach BPF programs
# Don't include overlay interfaces (wt0, wg0) to avoid interference
devices:
  - eth0
```

---

# Cilium - Enable Hubble for Network Observability

> Enable Hubble with relay for cluster-wide network visibility, flow inspection, and Prometheus metrics integration.

## Rules

- Enable Hubble with relay for cluster-wide visibility
- Configure relevant metrics: `dns:query`, `drop`, `tcp`, `flow`, `port-distribution`, `icmp`
- Enable `httpV2` metrics with context labels for L7 visibility (adds overhead)
- Use Hubble CLI for real-time flow inspection (`hubble observe`)
- Enable Hubble UI for visual flow analysis (optional, adds resource cost)
- Export metrics to Prometheus/Grafana via serviceMonitor
- Set resource requests/limits on relay pods

## Example

```yaml
# Hubble configuration
hubble:
  enabled: true

  # Relay for cluster-wide observability
  relay:
    enabled: true
    replicas: 1
    resources:
      requests:
        cpu: 100m
        memory: 128Mi

  # UI for visual analysis (optional)
  ui:
    enabled: true
    replicas: 1

  # Metrics for Prometheus integration
  metrics:
    enabled:
      - dns:query
      - drop
      - tcp
      - flow
      - port-distribution
      - icmp
      # L7 HTTP metrics with context labels
      - httpV2:exemplars=true;labelsContext=source_ip,source_namespace,source_workload,destination_ip,destination_namespace,destination_workload,traffic_direction

    serviceMonitor:
      enabled: true  # If using Prometheus Operator

# Usage examples:
# hubble observe --namespace production
# hubble observe --verdict DROPPED
# hubble observe --from-pod frontend --to-pod backend
# hubble observe --protocol TCP --port 443
```

---

# Cilium - Use Kube-Proxy Replacement

> Enable Cilium's eBPF-based kube-proxy replacement for better service routing performance and scalability over iptables.

## Rules

- Set `kubeProxyReplacement: true` for full replacement
- Disable kube-proxy during cluster installation (cannot run alongside)
- Configure `k8sServiceHost` and `k8sServicePort` to point to the control plane
- Use SNAT load balancer mode for overlay/tunnel networks
- Use DSR (Direct Server Return) for native routing with network support
- Enable socket-level load balancing for local traffic optimization
- Requires kernel 5.x+ for full eBPF feature support
- For RKE2: configure Cilium before cluster init
- Set health check endpoint: `kubeProxyReplacementHealthzBindAddr: "0.0.0.0:10256"`

## Example

```yaml
# Full kube-proxy replacement
kubeProxyReplacement: true
kubeProxyReplacementHealthzBindAddr: "0.0.0.0:10256"

# Kubernetes API server endpoint
k8sServiceHost: "10.0.0.1"  # Or control plane VIP
k8sServicePort: 6443

# Load balancer configuration
loadBalancer:
  mode: snat  # Use SNAT for overlay/tunnel networks
  # mode: dsr  # Use DSR for native routing with network support

# NodePort support
nodePort:
  enabled: true
  # bindProtection: true  # Prevent binding to NodePort range

# Socket-level load balancing
socketLB:
  enabled: true
  hostNamespaceOnly: true  # Only for host-network pods

# External IPs
externalIPs:
  enabled: true

# HostPort support
hostPort:
  enabled: true

# Local redirect policy for node-local services
localRedirectPolicy: true
```

---

# Cilium - Configure Masquerading Correctly

> Enable eBPF masquerading for external traffic and define non-masquerade CIDRs to preserve pod IPs for internal communication.

## Rules

- Enable `bpf.masquerade: true` for eBPF-based masquerading (faster than iptables)
- Enable `enableIPv4Masquerade: true` for external traffic
- Use IP Masquerade Agent for fine-grained control over which CIDRs are masqueraded
- Define non-masquerade CIDRs for all internal networks (pod CIDR, service CIDR, VPN/overlay CIDR)
- Traffic to non-masquerade CIDRs keeps original pod IP (important for network policies and logging)
- Traffic to all other destinations (internet) is masqueraded to node IP
- Set `masqLinkLocal: false` to skip link-local addresses
- For tunnel mode, use SNAT load balancer mode for symmetric routing
- Update non-masquerade CIDRs when adding new internal networks

## Example

```yaml
# Enable eBPF masquerading
bpf:
  masquerade: true

# Enable IPv4 masquerade for external traffic
enableIPv4Masquerade: true
enableIPv6Masquerade: false  # Disable if not using IPv6

# IP Masquerade Agent for fine-grained control
ipMasqAgent:
  enabled: true
  config:
    # Traffic to these CIDRs keeps original pod IP
    nonMasqueradeCIDRs:
      - 10.42.0.0/16    # Pod CIDR
      - 10.43.0.0/16    # Service CIDR
      - 100.64.0.0/10   # WireGuard/VPN overlay (if applicable)
      - 172.16.0.0/12   # Private network (if applicable)
    # Don't masquerade link-local traffic
    masqLinkLocal: false

# For tunnel mode, ensure symmetric routing
# with SNAT load balancer mode
loadBalancer:
  mode: snat

# Devices for BPF attachment (source of masqueraded traffic)
devices:
  - eth0  # Primary interface for external traffic
```

---

# Cilium - Use CiliumNetworkPolicies for Advanced Security

> Use CiliumNetworkPolicy for L7 filtering, DNS-based egress rules, and identity-based security beyond what standard NetworkPolicy supports.

## Rules

- Use standard Kubernetes NetworkPolicy for basic L3/L4 rules (portable across CNIs)
- Use CiliumNetworkPolicy (CNP) for L7 HTTP/gRPC filtering, DNS-based policies, and advanced features
- Use CiliumClusterwideNetworkPolicy (CCNP) for cluster-wide rules
- Implement default-deny with explicit allow rules
- L7 policies add latency (proxy required) -- only use when needed
- Available Cilium-specific features:
  - L7 HTTP/gRPC filtering (methods, paths, headers)
  - DNS-based egress policies (`toFQDNs`) -- no hardcoded IPs
  - Entity-based rules (`world`, `cluster`, `host`)
  - CIDR-based rules for external services
  - Port ranges and named ports

## Example

```yaml
# Default deny with DNS and health check exceptions
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: default-deny
  namespace: production
spec:
  endpointSelector: {}
  egress:
    # Allow DNS
    - toEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-system
            k8s-app: kube-dns
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP

---
# L7 HTTP policy
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: api-http-policy
  namespace: production
spec:
  endpointSelector:
    matchLabels:
      app: api-server
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: frontend
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
          rules:
            http:
              - method: GET
                path: "/api/v1/.*"
              - method: POST
                path: "/api/v1/orders"

---
# DNS-based egress policy (FQDN)
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: external-api-egress
  namespace: production
spec:
  endpointSelector:
    matchLabels:
      app: payment-service
  egress:
    - toFQDNs:
        - matchName: "api.stripe.com"
        - matchPattern: "*.amazonaws.com"
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP

---
# Cluster-wide policy
apiVersion: cilium.io/v2
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: deny-external-except-allowed
spec:
  endpointSelector:
    matchLabels:
      allow-external: "true"
  egress:
    - toEntities:
        - world
```

---

# Cilium - Configure eBPF for Optimal Performance

> Enable eBPF masquerading, disable host legacy routing, and properly configure BPF devices and cgroups for high-performance packet processing.

## Rules

- Enable `bpf.masquerade: true` (faster than iptables)
- Set `bpf.hostLegacyRouting: false` for eBPF datapath performance
- Set `bpf.tproxy: true` for transparent proxying (required for L7 policies)
- Configure `bpf.mapDynamicSizeRatio` for dynamic BPF map sizing (0.0025 = 0.25% of system memory)
- Enable `bpf.autoMount.enabled: true` for BPF filesystem
- Only list physical/bridge interfaces in `devices` -- never overlay interfaces
- Do not include in `devices`: wt0, wg0, vxlan.cilium, cilium_* interfaces
- Enable cgroup auto-mount with cgroup v2 path (`/sys/fs/cgroup`)
- Minimum kernel: 4.19, recommended: 5.4+
- Enable `wellKnownIdentities.enabled: true` for system services

## Example

```yaml
# eBPF core configuration
bpf:
  # Use eBPF for masquerading (faster than iptables)
  masquerade: true

  # Disable legacy host routing for eBPF datapath
  hostLegacyRouting: false

  # Dynamic BPF map sizing
  # Ratio of memory to allocate for BPF maps
  # 0.0025 = 0.25% of system memory
  mapDynamicSizeRatio: 0.0025

  # Enable transparent proxy for L7 policies
  tproxy: true

  # Auto-mount BPF filesystem
  autoMount:
    enabled: true

# Cgroup configuration
cgroup:
  autoMount:
    enabled: true
  # Cgroup v2 path (modern systems)
  hostRoot: /sys/fs/cgroup

# Devices to attach BPF programs
# Only physical/bridge interfaces, NOT overlay interfaces
devices:
  - eth0
  # - bond0  # If using bonding
  # - br0    # If using bridge

# Do NOT include:
# - wt0 (WireGuard)
# - wg0 (WireGuard)
# - vxlan.cilium (Cilium VXLAN - managed internally)
# - cilium_* interfaces

# L7 proxy configuration
l7Proxy: true

# Well-known identities for system services
wellKnownIdentities:
  enabled: true

# Kernel requirements check
# Cilium will validate kernel capabilities at startup
# Minimum: 4.19, Recommended: 5.4+
```

---

# Cilium - Enable Bandwidth Manager for QoS

> Enable Cilium's eBPF bandwidth manager with BBR congestion control to enforce per-pod bandwidth limits and prevent noisy neighbors.

## Rules

- Enable `bandwidthManager.enabled: true` for pod bandwidth limits
- Enable `bandwidthManager.bbr: true` for improved throughput (especially over high-latency/lossy links)
- Use standard Kubernetes annotations to set per-pod bandwidth limits:
  - `kubernetes.io/ingress-bandwidth: "10M"` (download limit)
  - `kubernetes.io/egress-bandwidth: "50M"` (upload limit)
- Requires kernel 5.1+ for bandwidth manager
- Requires kernel 5.18+ for BBR with EDT (Earliest Departure Time)
- Limits are per-pod, not per-container
- Ensure proper `devices` configuration

## Example

```yaml
# Cilium bandwidth manager configuration
bandwidthManager:
  enabled: true
  # Enable BBR congestion control
  # Improves throughput, especially over high-latency/lossy links
  bbr: true

# Pod with bandwidth limits
apiVersion: v1
kind: Pod
metadata:
  name: bandwidth-limited-app
  annotations:
    # Limit ingress (download) to 100 Mbps
    kubernetes.io/ingress-bandwidth: "100M"
    # Limit egress (upload) to 50 Mbps
    kubernetes.io/egress-bandwidth: "50M"
spec:
  containers:
    - name: app
      image: myapp:v1
      resources:
        requests:
          cpu: 100m
          memory: 128Mi

---
# Deployment with bandwidth limits
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rate-limited-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rate-limited
  template:
    metadata:
      labels:
        app: rate-limited
      annotations:
        kubernetes.io/ingress-bandwidth: "50M"
        kubernetes.io/egress-bandwidth: "25M"
    spec:
      containers:
        - name: service
          image: service:v1
```

---

# Test Manifests and Charts

> Validate Kubernetes manifests and Helm charts before deploying to catch misconfigurations, policy violations, and regressions.

## Rules

- Validate manifests against Kubernetes schemas using kubeconform or kubeval
- Use Helm unit tests (helm-unittest) to verify template rendering
- Run policy checks with OPA/Gatekeeper, Kyverno, or Datree in CI
- Test Helm values across environments (dev, staging, prod) to catch drift
- Use `helm template` to render and inspect output before installing
- Test deployments in ephemeral namespaces or Kind/k3d clusters in CI
- Validate CRDs and custom resources against their schemas

## Example

```bash
# Validate manifests against schemas
kubeconform -strict -kubernetes-version 1.29.0 k8s/

# Render and validate Helm chart
helm template my-release ./chart -f values-prod.yaml | kubeconform -strict

# Lint Helm chart
helm lint ./chart -f values.yaml

# Run Helm unit tests
helm unittest ./chart
```

```yaml
# tests/deployment_test.yaml (helm-unittest)
suite: deployment tests
templates:
  - deployment.yaml
tests:
  - it: should set resource limits
    asserts:
      - isNotNull:
          path: spec.template.spec.containers[0].resources.limits.memory
      - isNotNull:
          path: spec.template.spec.containers[0].resources.limits.cpu

  - it: should run as non-root
    asserts:
      - equal:
          path: spec.template.spec.containers[0].securityContext.runAsNonRoot
          value: true
```

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **kubeval/kubeconform** — validate Kubernetes manifests against schemas: `kubeconform -strict .`
- **helm lint** — lint Helm charts for issues: `helm lint ./chart`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
