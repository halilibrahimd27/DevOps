---
description: "50 maddelik Kubernetes prod-readiness checklist: workload tasarimi, resource, security, reliability/HA, observability ve operations/GitOps eksenleri."
---
# Kubernetes Production Checklist

> *"`kubectl apply -f` çalıştı diye production'da çalışıyor demek değil."*
>
> Bu checklist, prod'a çıkacak her workload için **resource → security →
> reliability → observability → ops** beş ekseninde doğrulanması
> gerekenleri gruplar. Tek satırlık tablo değil — her madde **niye** ve
> **nasıl** açıklamalı.

---

## 📊 Hızlı bakış (50 madde)

| # | Eksen | Madde sayısı |
|---|---|---|
| A | Workload Tasarımı | 12 |
| B | Resource & Performance | 7 |
| C | Security | 11 |
| D | Reliability & HA | 8 |
| E | Observability | 6 |
| F | Operations & GitOps | 6 |

---

## A. Workload Tasarımı

### A1 — Deployment vs StatefulSet doğru seçildi
- ✅ Stateless workload → `Deployment`
- ✅ Stable identity (Postgres, Kafka, ZK) → `StatefulSet` + headless `Service`
- ✅ Tek-instance task → `Job` veya `CronJob`
- ✅ Node-level daemon → `DaemonSet`

### A2 — Image tag'i immutable
```yaml
image: <REGISTRY>/<APP>:v1.2.3            # ✅ semantic versioned
image: <REGISTRY>/<APP>@sha256:abc...     # ✅✅ SHA pinned (en güvenli)
image: <REGISTRY>/<APP>:latest            # ❌ rollback imkansız
```

### A3 — `imagePullPolicy` doğru
- `IfNotPresent` (default) — node'da varsa çekme
- `Always` — sadece dev için (production'da gereksiz registry yükü)
- SHA-pinned image kullanırsanız `Always` zaten gerekmiyor

### A4 — Replica sayısı en az 2
- HA için minimum 2; ideali 3 (zone başına 1)
- Tek replica = single point of failure
- Singleton workload bile leader-election + 2 replica + PDB

### A5 — `revisionHistoryLimit` makul
```yaml
spec:
  revisionHistoryLimit: 10     # default 10, OK; kontrolsüz büyüme engelleyici
```

### A6 — Rolling update stratejisi tanımlı
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 25%               # geçici fazla pod
    maxUnavailable: 0           # ❗ zero-downtime için MUTLAKA 0
```

### A7 — `terminationGracePeriodSeconds` yeterli
- Default 30 saniye
- Uzun-süren request'leri bekletme süresi + buffer
- `preStop` hook + graceful shutdown akışı toplam < bu değer

### A8 — `preStop` hook ile graceful shutdown
```yaml
lifecycle:
  preStop:
    exec:
      command: ["sh", "-c", "sleep 15"]   # LB'in pod'u listeden çıkarması için
```
Bu olmadan: pod kill → mevcut bağlantılar 503 döndürür.

### A9 — Container `command/args` net
- Image'ın default `CMD`'si üzerine yazıyorsanız neden net olsun
- `args` üzerinden çalışma profili değiştirilebiliyor olsun

### A10 — Multi-container pattern uygun mu?
- Sidecar (istio-proxy, log forwarder): OK
- Init container (DB migration, secret fetch): OK
- 3+ container'lı pod: muhtemelen ayrı workload'lara bölünmeli

### A11 — Headless service var mı? (StatefulSet için)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: <NAME>
spec:
  clusterIP: None       # ← headless
  selector: ...
```

### A12 — Pod DNS subdomain kontrolü (StatefulSet için)
```yaml
spec:
  serviceName: <NAME>   # pod DNS: <pod>.<svc>.<ns>.svc.cluster.local
```

---

## B. Resource & Performance

### B1 — `resources.requests` her container'da var
```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
```
Yoksa: scheduler bilemediği için BestEffort QoS, evict edilen ilk pod siz olursunuz.

### B2 — `resources.limits` doğru kullanılıyor
- ❗ **Memory limit:** mutlaka tanımla (OOM önle)
- ⚠️ **CPU limit:** controversial. Throttling ekler. Genellikle:
  - Request = guaranteed minimum
  - Limit = sadece burstable cap (ya da hiç koyma)

### B3 — Request/limit oranı QoS sınıfını belirler
```
requests == limits         → Guaranteed (en yüksek priority)
requests < limits          → Burstable
hiçbir şey                 → BestEffort (en önce evict)
```
Production'da: **Guaranteed** veya **Burstable**. BestEffort yasak.

### B4 — VPA recommendation görüldü
```bash
kubectl get vpa <APP> -o yaml | grep -A 10 'recommendation'
# Mevcut request'leri actual usage ile karşılaştır
```
Optimum request = p95 actual + %20 headroom.

### B5 — HPA min/max replica
```yaml
spec:
  minReplicas: 3       # HA için
  maxReplicas: 30      # cost guardrail
```

### B6 — Pod priority class
- Sistem-kritik: `system-cluster-critical`
- Production app: custom `priorityClass: production-high`
- Best-effort batch: `priorityClass: low`

### B7 — Pod density (node başına pod) makul
- Node max-pods (default 110) yetiyor mu?
- IP havuzu (CNI) yetiyor mu? (`kubectl get node -o yaml | grep podCIDR`)

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
Yazılması gereken dizinler `emptyDir` ile mount.

### C3 — Capabilities düşürülmüş
```yaml
securityContext:
  capabilities:
    drop: ["ALL"]
    # add: ["NET_BIND_SERVICE"]   # sadece :80/:443 bind için gerekirse
```

### C4 — `allowPrivilegeEscalation: false`
```yaml
securityContext:
  allowPrivilegeEscalation: false
```

### C5 — Seccomp profili
```yaml
securityContext:
  seccompProfile:
    type: RuntimeDefault
```

### C6 — ServiceAccount least privilege
- Default SA token mount edilmiyor: `automountServiceAccountToken: false`
- Kendi SA + Role + RoleBinding (sadece gerekli verb'ler)
- `cluster-admin` asla pod'a verilmez

### C7 — NetworkPolicy default-deny + explicit allow
```yaml
# Namespace başına default-deny, sonra app başına allow rule
```
Bunu skip eden cluster'lar lateral movement saldırısına açıktır.

### C8 — Secrets `Secret` resource veya External Secrets
- Plain `env` ile şifre **yasak**
- Vault / AWS Secrets Manager + ESO
- Ya da SOPS-encrypted YAML + git'te

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

### C10 — Image imzalı + Kyverno verifyImages
- `cosign sign` her CI/CD build sonrası
- Cluster `Kyverno ClusterPolicy: verifyImages` ile imzasızı reject

### C11 — Tüm imajlar trusted registry'den
```yaml
# Kyverno policy'le enforce:
# image: ghcr.io/<ORG>/* veya <COMPANY_REGISTRY>/*
# docker.io/library/* doğrudan kullanma — proxy registry'den geç
```

---

## D. Reliability & HA

### D1 — `livenessProbe` doğru tanımlı
```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 0       # startupProbe varsa
  periodSeconds: 10
  failureThreshold: 3
```
Yanlış: heavy DB query'li `/health` endpoint → cascade kill.

### D2 — `readinessProbe` doğru tanımlı
```yaml
readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  periodSeconds: 5
  failureThreshold: 3
```
DB bağlantısı, downstream warm-up okumalı; 503 → service'ten çıkar.

### D3 — `startupProbe` (yavaş başlangıç için)
```yaml
startupProbe:
  httpGet:
    path: /health/live
    port: 8080
  failureThreshold: 30          # 30 * 5s = 150 saniye'ye kadar tolerate
  periodSeconds: 5
```
Liveness'in startup sırasında öldürmesini engeller.

### D4 — `PodDisruptionBudget` var
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
spec:
  minAvailable: 2     # voluntary disruption sırasında garanti
  selector: ...
```

### D5 — `topologySpreadConstraints` var
```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        app: <APP>
```
Tek zone arızasında düşmez.

### D6 — Pod anti-affinity (aynı node'a yığılma engel)
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
volumeClaimTemplates:                    # StatefulSet'te
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: <CLASS>          # gp3, ssd, vs
      resources:
        requests:
          storage: 10Gi
```
StorageClass'ın `reclaimPolicy: Retain` (kazara silmede koruma).

### D8 — Backup test edilmiş
- Velero veya snapshot tabanlı
- Restore'u en az ayda bir test et — hiç restore edilmemiş backup yoktur

---

## E. Observability

### E1 — Metrics endpoint expose (Prometheus formatı)
```yaml
ports:
  - name: metrics
    containerPort: 9090
```
ServiceMonitor / PodMonitor (kube-prometheus-stack varsa).

### E2 — Structured logging (JSON)
```python
# stdout'a JSON yaz; log forwarder (Loki/ELK) parse eder
{"level":"error","ts":"2026-04-30T14:05:32Z","msg":"DB timeout","trace_id":"..."}
```

### E3 — Trace context propagation (W3C `traceparent`)
- OpenTelemetry SDK ekli
- HTTP client'lar `traceparent` header'ını forward eder
- Logger trace_id'yi log'a ekler (auto-correlation)

### E4 — SLO + alert tanımlı
- En az 3 SLI: availability, latency p99, error rate
- SLO target (örn: %99.9, p99 < 500ms, error < %0.1)
- Multi-burn-rate alert (fast + slow burn)

### E5 — Dashboard var
- Golden 4 sinyal (latency, traffic, errors, saturation)
- Per-deployment annotation (deploy zamanları işaretli)

### E6 — Alert routing yapılı
- Sev-1 → PagerDuty
- Sev-2 → Slack #alerts
- Sev-3 → Ticket queue
- Alert fatigue önlemi: SLO-based, symptom-based

---

## F. Operations & GitOps

### F1 — Manifest GitOps repo'da
- Kubectl `apply` manuel **yapılmaz**
- ArgoCD/Flux Git'i izler
- Drift sürekli düzeltilir

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

### F3 — Secret yönetimi GitOps-uyumlu
- ESO + Vault/AWS SM
- Sealed Secrets (Bitnami)
- SOPS-encrypted (age/PGP)

### F4 — Image update otomasyonu
- Argo Image Updater veya Renovate ile k8s-config repo'sunda image bump PR

### F5 — Migration job'ları kontrollü
- Hook: `helm.sh/hook: post-install,pre-upgrade`
- Idempotent
- Timeout + retry policy

### F6 — Cost label'ları zorunlu
```yaml
metadata:
  labels:
    team: <TEAM>
    cost-center: <CC>
    environment: prod
```
Kyverno ile enforce.

---

## ✅ Pre-deploy Sanity (script'lenebilir)

```bash
# 1. YAML valid
kubeconform -strict -summary deployment.yaml

# 2. Best practices linter
kube-linter lint deployment.yaml

# 3. Security scan
trivy config deployment.yaml
checkov -f deployment.yaml --framework kubernetes

# 4. Dry-run sunucu tarafı (admission policies dahil)
kubectl apply -f deployment.yaml --dry-run=server

# 5. Diff (canlı vs yeni)
kubectl diff -f deployment.yaml
```

---

## 🚫 Anti-Pattern

Red flag'ler "neyi yapma"yı söyler; bu tablo "onun yerine ne yap"ı da verir.

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| `image: <APP>:latest` | Tag mutable; aynı tag farklı içerik çeker, rollback imkansız | SHA-pinned (`@sha256:...`) veya semantic version |
| `imagePullPolicy: Always` prod'da | Her pod start'ında registry'ye gider; rate-limit + yavaş başlangıç | SHA-pinned image + `IfNotPresent` |
| `resources` tanımsız | BestEffort QoS; node baskısında ilk evict edilen pod olursun | Her container'a `requests`, memory `limits` zorunlu |
| Memory `limit` yok | Sızıntı node'u OOM'a sürükler, komşu pod'ları öldürür | Memory limit mutlaka; CPU limit opsiyonel |
| CPU `limit == request` her yerde | Gereksiz CFS throttling, p99 latency artar | CPU'da burst bırak (limit yok ya da request'ten yüksek) |
| `livenessProbe` ağır `/health`'e bağlı | DB yavaşlayınca probe fail → cascade restart fırtınası | Liveness hafif `/health/live`; bağımlılık kontrolü readiness'te |
| `readinessProbe` yok | Henüz warm-up bitmemiş pod'a trafik gider, 503 | `/health/ready` ile downstream + warm-up kontrolü |
| `preStop` + grace period yok | Pod kill anında in-flight bağlantılar 503 alır | `preStop: sleep`, `terminationGracePeriodSeconds` yeterli |
| `replicas: 1` (leader-election'sız) | Tek node/zone arızası = tam kesinti (SPOF) | min 2-3 replica + PDB + topology spread |
| PDB yok | Node drain/upgrade tüm replica'ları aynı anda kaldırabilir | `PodDisruptionBudget: minAvailable` |
| Secret `env` içinde plain | Log, `env` dump ve `kubectl describe`'da sızar | `Secret` resource / ESO / Sealed Secrets / SOPS |
| `runAsRoot` (securityContext yok) | Container escape ayrıcalıklı; node compromise yolu | `runAsNonRoot`, `drop: ["ALL"]`, `readOnlyRootFilesystem` |
| Default ServiceAccount + cluster-admin | Tek pod compromise = cluster pwn | Kendi SA + dar Role; `automountServiceAccountToken: false` |
| NetworkPolicy yok | Düz ağ; bir pod'dan tüm namespace'lere lateral movement | Namespace başına default-deny + explicit allow |
| `kubectl apply` manuel | Drift, audit-trail yok, "kim ne deploy etti" belirsiz | GitOps (ArgoCD/Flux) Git'i izlesin, drift'i düzeltsin |

---

## 🚦 "Bu prod'a çıkamaz" red flag'ler

| 🚩 | Açıklama |
|---|---|
| `:latest` tag | Rollback yok, immutability yok |
| `replicas: 1` (singleton non-leader-elected) | SPOF |
| `resources` null | BestEffort QoS, evict riski |
| `runAsRoot` | Container escape risk |
| Namespace == `default` | Multi-tenant boundary yok |
| `livenessProbe` HTTP `/` | DB query'li endpoint cascade kill |
| Secret env'de plain | Logger'da, env dump'ta sızıyor |
| NetworkPolicy yok | Lateral movement açık |
| `cluster-admin` SA | Tek pod compromise = cluster pwn |

> Bu 9 maddeden 1'i bile geçerse: PR red, canlıya çıkmaz.
