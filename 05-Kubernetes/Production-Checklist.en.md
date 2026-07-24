---
description: "50-item Kubernetes prod-readiness checklist: workload design, resource, security, reliability/HA, observability, and operations/GitOps axes."
tags:
  - Kubernetes
  - Security
  - SRE
  - Observability
  - GitOps
  - Cheatsheet
---
# Kubernetes Production Checklist

> *"`kubectl apply -f` succeeded doesn't mean it's running in production."*
>
> This checklist groups what must be verified for every workload heading
> to prod across five axes: **resource → security → reliability →
> observability → ops**. Not a one-line table — every item explains the
> **why** and the **how**.

---

## 📊 Quick view (50 items)

| # | Axis | Item count |
|---|---|---|
| A | Workload Design | 12 |
| B | Resource & Performance | 7 |
| C | Security | 11 |
| D | Reliability & HA | 8 |
| E | Observability | 6 |
| F | Operations & GitOps | 6 |

---

## A. Workload Design

### A1 — Deployment vs StatefulSet chosen correctly
- ✅ Stateless workload → `Deployment`
- ✅ Stable identity (Postgres, Kafka, ZK) → `StatefulSet` + headless `Service`
- ✅ Single-instance task → `Job` or `CronJob`
- ✅ Node-level daemon → `DaemonSet`

### A2 — Image tag is immutable
```yaml
image: <REGISTRY>/<APP>:v1.2.3            # ✅ semantic versioned
image: <REGISTRY>/<APP>@sha256:abc...     # ✅✅ SHA pinned (safest)
image: <REGISTRY>/<APP>:latest            # ❌ rollback impossible
```

### A3 — `imagePullPolicy` correct
- `IfNotPresent` (default) — don't pull if present on the node
- `Always` — dev only (needless registry load in production)
- If you use a SHA-pinned image, `Always` isn't needed anyway

### A4 — Replica count at least 2
- Minimum 2 for HA; ideally 3 (one per zone)
- Single replica = single point of failure
- Even a singleton workload: leader-election + 2 replicas + PDB

### A5 — `revisionHistoryLimit` reasonable
```yaml
spec:
  revisionHistoryLimit: 10     # default 10, OK; prevents uncontrolled growth
```

### A6 — Rolling update strategy defined
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 25%               # temporary extra pods
    maxUnavailable: 0           # ❗ MUST be 0 for zero-downtime
```

### A7 — `terminationGracePeriodSeconds` sufficient
- Default 30 seconds
- Time to hold long-running requests + buffer
- `preStop` hook + graceful shutdown flow total < this value

### A8 — Graceful shutdown via `preStop` hook
```yaml
lifecycle:
  preStop:
    exec:
      command: ["sh", "-c", "sleep 15"]   # for the LB to remove the pod from the list
```
Without this: pod kill → existing connections return 503.

### A9 — Container `command/args` clear
- If you override the image's default `CMD`, make the reason clear
- The runtime profile should be changeable via `args`

### A10 — Is the multi-container pattern appropriate?
- Sidecar (istio-proxy, log forwarder): OK
- Init container (DB migration, secret fetch): OK
- Pod with 3+ containers: probably should be split into separate workloads

### A11 — Is there a headless service? (for StatefulSet)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: <NAME>
spec:
  clusterIP: None       # ← headless
  selector: ...
```

### A12 — Pod DNS subdomain check (for StatefulSet)
```yaml
spec:
  serviceName: <NAME>   # pod DNS: <pod>.<svc>.<ns>.svc.cluster.local
```

---

## B. Resource & Performance

### B1 — `resources.requests` on every container
```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
```
Otherwise: since the scheduler can't know, you get BestEffort QoS, and you'll be the first pod to be evicted.

### B2 — `resources.limits` used correctly
- ❗ **Memory limit:** always define (prevent OOM)
- ⚠️ **CPU limit:** controversial. Adds throttling. Generally:
  - Request = guaranteed minimum
  - Limit = burstable cap only (or none at all)

### B3 — Request/limit ratio determines the QoS class
```
requests == limits         → Guaranteed (highest priority)
requests < limits          → Burstable
nothing                    → BestEffort (evicted first)
```
In production: **Guaranteed** or **Burstable**. BestEffort forbidden.

### B4 — VPA recommendation reviewed
```bash
kubectl get vpa <APP> -o yaml | grep -A 10 'recommendation'
# Compare current requests with actual usage
```
Optimal request = p95 actual + 20% headroom.

### B5 — HPA min/max replicas
```yaml
spec:
  minReplicas: 3       # for HA
  maxReplicas: 30      # cost guardrail
```

### B6 — Pod priority class
- System-critical: `system-cluster-critical`
- Production app: custom `priorityClass: production-high`
- Best-effort batch: `priorityClass: low`

### B7 — Pod density (pods per node) reasonable
- Is node max-pods (default 110) enough?
- Is the IP pool (CNI) enough? (`kubectl get node -o yaml | grep podCIDR`)

---

## C. Security

### C1 — `runAsNonRoot: true`
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65532
  runAsGroup: 65532
```

### C2 — `readOnlyRootFilesystem: true`
```yaml
securityContext:
  readOnlyRootFilesystem: true
```
Directories that need to be written mount via `emptyDir`.

### C3 — Capabilities dropped
```yaml
securityContext:
  capabilities:
    drop: ["ALL"]
    # add: ["NET_BIND_SERVICE"]   # only if binding :80/:443 is needed
```

### C4 — `allowPrivilegeEscalation: false`
```yaml
securityContext:
  allowPrivilegeEscalation: false
```

### C5 — Seccomp profile
```yaml
securityContext:
  seccompProfile:
    type: RuntimeDefault
```

### C6 — ServiceAccount least privilege
- Default SA token not mounted: `automountServiceAccountToken: false`
- Own SA + Role + RoleBinding (only the necessary verbs)
- `cluster-admin` is never granted to a pod

### C7 — NetworkPolicy default-deny + explicit allow
```yaml
# Default-deny per namespace, then an allow rule per app
```
Clusters that skip this are open to lateral movement attacks.

### C8 — Secrets via `Secret` resource or External Secrets
- Passwords in plain `env` are **forbidden**
- Vault / AWS Secrets Manager + ESO
- Or SOPS-encrypted YAML + in git

### C9 — Pod Security Standards: `restricted`
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: <NS>
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
```

### C10 — Image signed + Kyverno verifyImages
- `cosign sign` after every CI/CD build
- Cluster rejects unsigned via `Kyverno ClusterPolicy: verifyImages`

### C11 — All images from a trusted registry
```yaml
# Enforce with a Kyverno policy:
# image: ghcr.io/<ORG>/* or <COMPANY_REGISTRY>/*
# don't use docker.io/library/* directly — go through a proxy registry
```

---

## D. Reliability & HA

### D1 — `livenessProbe` defined correctly
```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 0       # if a startupProbe exists
  periodSeconds: 10
  failureThreshold: 3
```
Wrong: a `/health` endpoint with a heavy DB query → cascade kill.

### D2 — `readinessProbe` defined correctly
```yaml
readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  periodSeconds: 5
  failureThreshold: 3
```
Should check DB connection and downstream warm-up; 503 → removed from service.

### D3 — `startupProbe` (for slow startup)
```yaml
startupProbe:
  httpGet:
    path: /health/live
    port: 8080
  failureThreshold: 30          # tolerate up to 30 * 5s = 150 seconds
  periodSeconds: 5
```
Prevents liveness from killing during startup.

### D4 — `PodDisruptionBudget` present
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
spec:
  minAvailable: 2     # guaranteed during voluntary disruption
  selector: ...
```

### D5 — `topologySpreadConstraints` present
```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        app: <APP>
```
Doesn't go down on a single zone failure.

### D6 — Pod anti-affinity (prevent piling onto the same node)
```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app: <APP>
          topologyKey: kubernetes.io/hostname
```

### D7 — Persistent storage: StorageClass + retain policy
```yaml
volumeClaimTemplates:                    # in StatefulSet
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: <CLASS>          # gp3, ssd, etc.
      resources:
        requests:
          storage: 10Gi
```
The StorageClass should have `reclaimPolicy: Retain` (protection against accidental deletion).

### D8 — Backup tested
- Velero or snapshot-based
- Test restore at least once a month — a backup never restored doesn't exist

---

## E. Observability

### E1 — Metrics endpoint exposed (Prometheus format)
```yaml
ports:
  - name: metrics
    containerPort: 9090
```
ServiceMonitor / PodMonitor (if kube-prometheus-stack is present).

### E2 — Structured logging (JSON)
```python
# write JSON to stdout; the log forwarder (Loki/ELK) parses it
{"level":"error","ts":"2026-04-30T14:05:32Z","msg":"DB timeout","trace_id":"..."}
```

### E3 — Trace context propagation (W3C `traceparent`)
- OpenTelemetry SDK integrated
- HTTP clients forward the `traceparent` header
- Logger adds trace_id to logs (auto-correlation)

### E4 — SLO + alert defined
- At least 3 SLIs: availability, latency p99, error rate
- SLO target (e.g. 99.9%, p99 < 500ms, error < 0.1%)
- Multi-burn-rate alert (fast + slow burn)

### E5 — Dashboard present
- Golden 4 signals (latency, traffic, errors, saturation)
- Per-deployment annotation (deploy times marked)

### E6 — Alert routing structured
- Sev-1 → PagerDuty
- Sev-2 → Slack #alerts
- Sev-3 → Ticket queue
- Alert fatigue guard: SLO-based, symptom-based

---

## F. Operations & GitOps

### F1 — Manifests in a GitOps repo
- Manual `kubectl apply` is **not done**
- ArgoCD/Flux watch Git
- Drift is continuously corrected

### F2 — Multi-env layout (Kustomize/Helm)
```
apps/<APP>/
  base/
    deployment.yaml
    service.yaml
  overlays/
    dev/
    staging/
    prod/
```

### F3 — Secret management GitOps-compatible
- ESO + Vault/AWS SM
- Sealed Secrets (Bitnami)
- SOPS-encrypted (age/PGP)

### F4 — Image update automation
- Image bump PR in the k8s-config repo via Argo Image Updater or Renovate

### F5 — Migration jobs controlled
- Hook: `helm.sh/hook: post-install,pre-upgrade`
- Idempotent
- Timeout + retry policy

### F6 — Cost labels mandatory
```yaml
metadata:
  labels:
    team: <TEAM>
    cost-center: <CC>
    environment: prod
```
Enforce with Kyverno.

---

## ✅ Pre-deploy Sanity (scriptable)

```bash
# 1. YAML valid
kubeconform -strict -summary deployment.yaml

# 2. Best practices linter
kube-linter lint deployment.yaml

# 3. Security scan
trivy config deployment.yaml
checkov -f deployment.yaml --framework kubernetes

# 4. Server-side dry-run (including admission policies)
kubectl apply -f deployment.yaml --dry-run=server

# 5. Diff (live vs new)
kubectl diff -f deployment.yaml
```

---

## 🚫 Anti-Pattern

Red flags tell you "what not to do"; this table also gives "what to do instead".

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| `image: <APP>:latest` | Tag is mutable; the same tag pulls different content, rollback impossible | SHA-pinned (`@sha256:...`) or semantic version |
| `imagePullPolicy: Always` in prod | Hits the registry on every pod start; rate-limit + slow startup | SHA-pinned image + `IfNotPresent` |
| `resources` undefined | BestEffort QoS; you're the first pod evicted under node pressure | `requests` on every container, memory `limits` mandatory |
| No memory `limit` | A leak drives the node to OOM, kills neighbor pods | Memory limit mandatory; CPU limit optional |
| CPU `limit == request` everywhere | Needless CFS throttling, p99 latency rises | Leave burst on CPU (no limit or higher than request) |
| `livenessProbe` tied to a heavy `/health` | When the DB slows, probe fails → cascade restart storm | Liveness on a light `/health/live`; dependency check in readiness |
| No `readinessProbe` | Traffic goes to a pod not yet warmed up, 503 | Downstream + warm-up check via `/health/ready` |
| No `preStop` + grace period | In-flight connections get 503 at pod kill | `preStop: sleep`, sufficient `terminationGracePeriodSeconds` |
| `replicas: 1` (without leader-election) | Single node/zone failure = full outage (SPOF) | min 2-3 replicas + PDB + topology spread |
| No PDB | Node drain/upgrade can remove all replicas at once | `PodDisruptionBudget: minAvailable` |
| Secret in `env` as plain | Leaks in logs, `env` dump, and `kubectl describe` | `Secret` resource / ESO / Sealed Secrets / SOPS |
| `runAsRoot` (no securityContext) | Container escape is privileged; a path to node compromise | `runAsNonRoot`, `drop: ["ALL"]`, `readOnlyRootFilesystem` |
| Default ServiceAccount + cluster-admin | One pod compromise = cluster pwn | Own SA + narrow Role; `automountServiceAccountToken: false` |
| No NetworkPolicy | Flat network; lateral movement from one pod to all namespaces | Default-deny per namespace + explicit allow |
| Manual `kubectl apply` | Drift, no audit trail, "who deployed what" unclear | GitOps (ArgoCD/Flux) watches Git, corrects drift |

---

## 🚦 "This can't go to prod" red flags

| 🚩 | Description |
|---|---|
| `:latest` tag | No rollback, no immutability |
| `replicas: 1` (singleton non-leader-elected) | SPOF |
| `resources` null | BestEffort QoS, eviction risk |
| `runAsRoot` | Container escape risk |
| Namespace == `default` | No multi-tenant boundary |
| `livenessProbe` HTTP `/` | Endpoint with a DB query cascade kills |
| Secret plain in env | Leaks in the logger, in env dump |
| No NetworkPolicy | Lateral movement open |
| `cluster-admin` SA | One pod compromise = cluster pwn |

> If even 1 of these 9 items applies: PR rejected, doesn't go live.

---

## 📋 Checklist

```
[ ] Image SHA-pinned or semantic versioned — no `:latest` (A2)
[ ] Replica >= 2 + PDB + topologySpreadConstraints (A4, D4, D5)
[ ] `requests` on every container, memory `limit` mandatory; no BestEffort QoS (B1, B3)
[ ] securityContext strict: runAsNonRoot, readOnlyRootFilesystem, drop ALL, seccomp (C1-C5)
[ ] ServiceAccount least-privilege + NetworkPolicy default-deny (C6, C7)
[ ] Secret not plain in env — Secret/ESO/Sealed Secrets/SOPS (C8)
[ ] liveness/readiness/startup probe properly separated; not tied to a heavy endpoint (D1-D3)
[ ] preStop hook + sufficient terminationGracePeriodSeconds (A8, A7)
[ ] Metrics + structured logging + trace context + SLO/alert defined (E1-E6)
[ ] Manifests in a GitOps repo (ArgoCD/Flux), no manual `kubectl apply` (F1)
[ ] Pre-deploy sanity script run (kubeconform, kube-linter, trivy, dry-run)
```

---

## 📚 References

- [Kubernetes Hardening](../08-Security/Kubernetes-Hardening.md) — securityContext, PSS, RBAC depth
- [Secrets Management](../08-Security/Secrets-Management.md) — ESO, Sealed Secrets, SOPS details
- [Resource Limits Guide](Resource-Limits-Guide.md) — request/limit and QoS classes
- [SLI-SLO-Error-Budget](../11-SRE/SLI-SLO-Error-Budget.md) — the SLO items on the observability axis
- [Kubernetes Documentation](https://kubernetes.io/docs/) — official concept and API reference

---

> *"Prod-readiness isn't a feeling, it's a filled-out checklist; if any one of the resource, security, or reliability items is empty, that manifest belongs to a PR, not yet to prod."*

---

> 🎓 **Learning Path:** This document is used as a "Read first" resource in the [`D2`](../22-Learning-Path/block-d-orchestration/D2-k8s-production.md) module.
