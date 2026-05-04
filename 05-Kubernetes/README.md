# 05 · Kubernetes

> *"`kubectl apply -f` çalıştı diye production'da işliyor demek
> değildir; dashboard yeşil yandı diye SLO tutmuyor demek değildir."*

Production'da Kubernetes'i yöneten ekibe gerçek işine yarayan referanslar.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`Production-Checklist.md`](Production-Checklist.md) | 50 maddelik prod-readiness checklist (resource, probe, security, observability) |
| _`Resource-Limits-Guide.md`_ *(yakında)* | Request vs limit, OOMKilled debug, VPA recommendations |
| _`HPA-VPA-KEDA.md`_ *(yakında)* | Otomatik ölçekleme: CPU/RAM/custom metric/event-driven |
| _`Ingress-and-Gateway-API.md`_ *(yakında)* | Ingress'ten Gateway API'ye geçiş, niçin ve nasıl |
| _`Multi-Tenancy-Patterns.md`_ *(yakında)* | Soft/hard multi-tenancy, namespace izolasyonu, vCluster |
| _`StatefulSet-vs-Operator.md`_ *(yakında)* | Stateful workload'larını yönetmek; ne zaman operator gerekir |
| _`Upgrade-Strategy.md`_ *(yakında)* | Cluster upgrade'i sıfır-downtime ile yapma; deprecated API geçişi |
| _`Debugging-Pods.md`_ *(yakında)* | CrashLoopBackOff, ImagePullBackOff, Pending: triage flowchart'ı |

## Production checklist (özet)

```
Workload
[ ] requests/limits her container'da tanımlı
[ ] liveness + readiness + startup probe
[ ] terminationGracePeriodSeconds = SIGTERM süresi + buffer
[ ] PodDisruptionBudget (en az minAvailable: 1)
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
[ ] CNI: Cilium (eBPF) veya Calico
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

## Anti-pattern'ler

- ❌ `latest` tag deploy (rollback imkansız)
- ❌ `resources` boş (noisy neighbor, evicted random)
- ❌ Tek replica deployment ("HA varsayılır" demeden HA olmaz)
- ❌ Default namespace'de `prod` çalıştırmak
- ❌ `kubectl edit` ile production değişiklik (drift, GitOps yok)
- ❌ `cluster-admin` her servis account'a (least privilege ihlali)
- ❌ Monitoring olmadan canlı çıkmak
