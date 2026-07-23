---
description: "Production Kubernetes reference set contents: prod-readiness checklist, resource limits, HPA/VPA/KEDA, multi-tenancy, upgrade strategy, and pod debugging."
tags:
  - Kubernetes
  - Platform Engineering
  - SRE
  - Roadmap
---
# 05 · Kubernetes

> *"`kubectl apply -f` running doesn't mean it's working in
> production; a green dashboard doesn't mean the SLO is holding."*

References that actually help the team running Kubernetes in production.

## Contents

| File | Topic |
|---|---|
| [`Production-Checklist.md`](Production-Checklist.md) | 50-item prod-readiness checklist (resource, probe, security, observability) |
| [`Resource-Limits-Guide.md`](Resource-Limits-Guide.md) | Request vs limit, OOMKilled debugging, VPA recommendations |
| [`HPA-VPA-KEDA.md`](HPA-VPA-KEDA.md) | Autoscaling: CPU/RAM/custom metric/event-driven |
| _`Ingress-and-Gateway-API.md`_ *(coming soon)* | Migrating from Ingress to Gateway API, why and how |
| [`Multi-Tenancy-Patterns.md`](Multi-Tenancy-Patterns.md) | Soft/hard multi-tenancy, namespace isolation, vCluster |
| _`StatefulSet-vs-Operator.md`_ *(coming soon)* | Managing stateful workloads; when you need an operator |
| [`Upgrade-Strategy.md`](Upgrade-Strategy.md) | Zero-downtime cluster upgrades; deprecated API migration |
| [`Debugging-Pods.md`](Debugging-Pods.md) | CrashLoopBackOff, ImagePullBackOff, Pending: triage flowchart |

## Production checklist (summary)

```
Workload
[ ] requests/limits defined on every container
[ ] liveness + readiness + startup probe
[ ] terminationGracePeriodSeconds = SIGTERM duration + buffer
[ ] PodDisruptionBudget (at least minAvailable: 1)
[ ] topologySpreadConstraints (HA)
[ ] preStop hook (graceful shutdown)

Security
[ ] runAsNonRoot: true
[ ] readOnlyRootFilesystem: true
[ ] allowPrivilegeEscalation: false
[ ] capabilities drop: ALL
[ ] seccompProfile: RuntimeDefault
[ ] NetworkPolicy (default-deny + explicit allow)

Cluster
[ ] CNI: Cilium (eBPF) or Calico
[ ] Ingress: NGINX / Gateway API
[ ] cert-manager + Let's Encrypt
[ ] kube-prometheus-stack
[ ] kube-state-metrics + node-exporter
[ ] OpenTelemetry Collector
[ ] Velero (backup)
[ ] external-secrets-operator + Vault
[ ] kyverno / gatekeeper

Observability
[ ] Container logs → Loki/ELK
[ ] Metrics → Prometheus
[ ] Traces → Tempo/Jaeger
[ ] SLO + error budget alert
[ ] PagerDuty / Opsgenie integration
```

## Anti-patterns

- ❌ Deploying the `latest` tag (rollback impossible)
- ❌ Empty `resources` (noisy neighbor, random evictions)
- ❌ Single-replica deployment (HA doesn't happen just by "assuming HA")
- ❌ Running `prod` in the default namespace
- ❌ Production changes via `kubectl edit` (drift, no GitOps)
- ❌ `cluster-admin` on every service account (violates least privilege)
- ❌ Going live without monitoring
