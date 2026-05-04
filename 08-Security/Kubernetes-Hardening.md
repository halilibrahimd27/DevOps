# Kubernetes Hardening — 2026 Production Rehberi

> *"Default Kubernetes config'i 'çalışıyor' demek, banka kasasının kapısını
> 'kapatmadan zarif kapatmak' demektir. Kapatmayı bilmek değil, **doğru
> kapatmak** önemli."*

Bu rehber bir Kubernetes cluster'ını **prod-grade** seviyesine çıkarmak için
adım adım gider. CIS Benchmark esas alır ama "şu satıra dokun" demek yerine
**niye dokunduğunu** açıklar.

---

## 🎯 Hedef Tehdit Modeli

| Saldırgan profili | Vektör | Kontrol |
|---|---|---|
| **Compromised pod** | RCE → cluster içi lateral movement | NetworkPolicy, RBAC, PSS |
| **Compromised node** | kubelet credential → pod hijack | Node-level seccomp, AppArmor |
| **Compromised supply chain** | Kötü amaçlı image | cosign verify, image scan, admission |
| **Insider threat** | Geniş RBAC → veri exfiltration | Least-privilege, audit log |
| **Internet-facing API** | Kubernetes API'ye direkt saldırı | Private API, OIDC, network ACL |
| **Misconfigured ingress** | Public expose edilmiş dashboard | Policy-as-code, default-deny |

---

## 1️⃣ Cluster API Server Hardening

### Anonymous auth kapalı
```bash
# kube-apiserver flag
--anonymous-auth=false
```
Default `true` — kapatılmalı. Aksi halde `system:anonymous` pek çok endpoint'e read erişim alabilir.

### Kullanıcı authentication: OIDC
- Statik token (`--token-auth-file`) **YASAK**.
- ServiceAccount token + OIDC kullan.
- Kurumsal IdP entegrasyonu (Keycloak, Auth0, Azure AD, Google Workspace).

```yaml
# kube-apiserver
--oidc-issuer-url=https://<IDP_URL>
--oidc-client-id=<CLIENT_ID>
--oidc-username-claim=email
--oidc-groups-claim=groups
```

### Audit logging
Default audit yok — **mutlaka** aç.

```yaml
# audit-policy.yaml (örnek)
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - RequestReceived
rules:
  # Secret işlemleri tam log
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["secrets", "configmaps"]
  # exec/portforward kritik
  - level: Request
    resources:
      - group: ""
        resources: ["pods/exec", "pods/portforward", "pods/proxy"]
  # Geri kalan write metadata yeterli
  - level: Metadata
    verbs: ["create", "update", "patch", "delete"]
  # Read az gürültülü
  - level: None
    verbs: ["get", "list", "watch"]
```

```bash
--audit-log-path=/var/log/kube-audit.log
--audit-log-maxage=30
--audit-log-maxbackup=10
--audit-log-maxsize=100
--audit-policy-file=/etc/kubernetes/audit-policy.yaml
```

> 🔑 **Audit log → SIEM.** Wazuh / Splunk / Loki'ye ship et. Sadece dosyada kalırsa kimse bakmaz.

### API server: public mi private mi?
- ✅ **Private** + bastion / VPN + cloud-native auth proxy (örn: AWS EKS Private endpoint + Tailscale).
- ⚠️ Public ise: IP allow-list, `--enable-admission-plugins=NodeRestriction`, MFA-bağlı OIDC.
- ❌ Public + token-only auth: **devam etme, ihlal an meselesi.**

---

## 2️⃣ Pod Security Standards (PSS)

PSP (Pod Security Policy) **kaldırıldı** (k8s 1.25+). Yerine **PSS + admission**.

| Profil | Kullanım |
|---|---|
| **privileged** | Sistem komponentleri (CNI, CSI). Sadece `kube-system`. |
| **baseline** | Geleneksel yük; root engellenmiş ama bazı şeyler izinli. |
| **restricted** | **2026 hedefi.** Tüm app namespace'leri. |

### Restricted profile'i namespace düzeyinde uygula
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: <NAMESPACE>
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### `restricted` ne dayatır?
- `runAsNonRoot: true`
- `allowPrivilegeEscalation: false`
- `readOnlyRootFilesystem: true` *(önerilen, restricted'da zorunlu değil)*
- `seccompProfile.type: RuntimeDefault`
- Capabilities: `drop: [ALL]`, ekleme: sadece `NET_BIND_SERVICE`
- Volume tipleri kısıtlı (hostPath yok, emptyDir/configMap/secret/projected/pvc/csi var)

### Pod manifest örneği (restricted-uyumlu)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  template:
    spec:
      automountServiceAccountToken: false
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        fsGroup: 10001
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: app
          image: <REGISTRY>/<APP>:<DIGEST>
          imagePullPolicy: IfNotPresent
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: [ALL]
          resources:
            requests: {cpu: 100m, memory: 128Mi}
            limits: {cpu: 500m, memory: 512Mi}
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir: {}
```

> ⚠️ `automountServiceAccountToken: false` — pod ServiceAccount token'a
> ihtiyaç duymuyorsa **kapat**. Compromised container içinden API'ye erişimi
> engeller.

---

## 3️⃣ NetworkPolicy: Default-Deny

Default Kubernetes networking: **her şey her şeye konuşabilir.** Bu en
büyük lateral-movement vektörü.

### Default-deny her namespace'de
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: <NAMESPACE>
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
```

Bu uygulandığı an **hiçbir trafik geçmez** — DNS dahil. Sonra **whitelist** ekle:

### DNS izni (her zaman lazım)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: <NAMESPACE>
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

### Servis-servis whitelist
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-to-postgres
  namespace: <NAMESPACE>
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes: [Ingress]
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api
      ports:
        - protocol: TCP
          port: 5432
```

### Cilium / Calico ile L7 NetworkPolicy
Standart NetworkPolicy L4 (port). Cilium L7 verir:

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: api-to-payment-service
spec:
  endpointSelector:
    matchLabels: {app: api}
  egress:
    - toEndpoints:
        - matchLabels: {app: payment}
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
          rules:
            http:
              - method: "POST"
                path: "/charge"
              - method: "GET"
                path: "/health"
```

> 🔑 **Production'a girişte:** her namespace `default-deny` + `allow-dns` ile
> başlasın. Ardından servis sahibi gerekli kuralları PR ile ekler.

---

## 4️⃣ RBAC — Least Privilege

### Anti-pattern: cluster-admin paylaşımı
```bash
# ❌ ASLA YAPMA
kubectl create clusterrolebinding dev-admin \
  --clusterrole=cluster-admin --user=dev@example.com
```

### Doğru: namespace-bound role + grup
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: app-team-a
  name: developer
rules:
  - apiGroups: ["", "apps"]
    resources: ["pods", "deployments", "services", "configmaps"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["pods/log", "pods/exec"]
    verbs: ["get", "list", "create"]
  # Secret read'i KASITLI olarak yok
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-a-developers
  namespace: app-team-a
subjects:
  - kind: Group
    name: team-a-devs    # OIDC group claim
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

### RBAC denetim sorgusu
```bash
# Cluster-admin'i kim alıyor?
kubectl get clusterrolebindings -o json | \
  jq '.items[] | select(.roleRef.name=="cluster-admin") |
      {name: .metadata.name, subjects: .subjects}'

# kim hangi resource'a yazabilir
kubectl auth can-i --list --as=<USER>

# wildcard kullanan tehlikeli rolleri bul
kubectl get clusterroles -o json | \
  jq '.items[] | select(.rules[]?.verbs[]? == "*" or .rules[]?.resources[]? == "*") |
      .metadata.name'
```

### ServiceAccount token: kullanmıyorsan token oluşturma
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: <APP>
automountServiceAccountToken: false
```

K8s 1.24+ artık SA için otomatik secret oluşturmuyor. Bu iyi — explicit token gerektirir.

---

## 5️⃣ Secret Management

> Ayrıntı: [`Secrets-Management.md`](Secrets-Management.md). Burada özet kurallar.

| Yapma | Yap |
|---|---|
| Secret'ları Git'te tutmak | SOPS / sealed-secrets ile şifreli commit |
| Cluster `Secret` (base64) yetiyor sanmak | Vault + External Secrets Operator |
| `env` üzerinden secret enjekte etmek (`ps`'te görünür) | File mount + tmpfs |
| Single secret tüm uygulamalarda ortak | Service başına ayrı secret |
| Secret rotation manuel | ESO + secret rotator → otomatik |

### etcd encryption-at-rest
```yaml
# /etc/kubernetes/encryption.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources: ["secrets"]
    providers:
      - kms:
          name: <KMS_NAME>
          endpoint: unix:///var/run/kmsplugin/socket.sock
          cachesize: 1000
      - identity: {}    # fallback (read existing unencrypted)
```

> ⚠️ Default'ta etcd'de secret'lar **plaintext base64**. KMS provider olmadan
> etcd snapshot çalan herkes secret'ları okur.

---

## 6️⃣ Image Security

### Admission'da imza zorunluluğu (Kyverno)
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signatures
spec:
  validationFailureAction: Enforce
  rules:
    - name: verify-signature
      match:
        any:
          - resources:
              kinds: [Pod]
      verifyImages:
        - imageReferences:
            - "<REGISTRY>/*"
          attestors:
            - entries:
                - keyless:
                    subject: "https://github.com/<ORG>/*"
                    issuer: "https://token.actions.githubusercontent.com"
```

### Image policy katalog
```yaml
# Yasaklı: latest tag
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  validationFailureAction: Enforce
  rules:
    - name: validate-image-tag
      match:
        any:
          - resources:
              kinds: [Pod]
      validate:
        message: "':latest' tag yasak; sürüm/digest kullan."
        pattern:
          spec:
            containers:
              - image: "!*:latest"
```

Hazır şablonlar: [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/).

### Image scan gate (Trivy)
```yaml
# .github/workflows/scan.yml
- uses: aquasecurity/trivy-action@<VERSION>
  with:
    image-ref: <REGISTRY>/<APP>:${{ github.sha }}
    format: sarif
    output: trivy.sarif
    severity: CRITICAL,HIGH
    exit-code: 1   # CRITICAL/HIGH → fail
    ignore-unfixed: true   # fix yoksa boş gürültü yapma
```

---

## 7️⃣ Node Hardening

### Kubelet
```yaml
# /var/lib/kubelet/config.yaml
authentication:
  anonymous: {enabled: false}
  webhook: {enabled: true}
authorization:
  mode: Webhook
readOnlyPort: 0           # 10255 kapalı
protectKernelDefaults: true
streamingConnectionIdleTimeout: 5m
makeIPTablesUtilChains: true
eventRecordQPS: 0         # event spam DDoS önler
```

### Container runtime: containerd
- Docker shim → containerd (k8s 1.24+ default)
- gVisor (`--runtime=runsc`) untrusted workload için sandbox
- Kata Containers VM-level isolation gereken durumlarda

### seccomp default
Cluster-wide default seccomp profil:
```yaml
# kubelet config
seccompDefault: true   # k8s 1.27+ stable
```

### AppArmor / SELinux
- Ubuntu/Debian → AppArmor profil per pod:
  ```yaml
  metadata:
    annotations:
      container.apparmor.security.beta.kubernetes.io/<CONTAINER>: runtime/default
  ```
- RHEL/CentOS → SELinux Enforcing.

---

## 8️⃣ Runtime Security (Falco / Tetragon)

Sadece "build-time" güvenlik yetmiyor. Çalışan pod'larda anomali:

```yaml
# Falco rule örneği
- rule: Shell in container
  desc: Container içinde shell başlatıldı (debugging dışında olmamalı)
  condition: >
    container and proc.name in (bash, sh, zsh)
    and not container.image.repository in (allowed_debug_images)
  output: >
    Shell in container (user=%user.name container=%container.name
    cmd=%proc.cmdline)
  priority: WARNING
  tags: [container, shell]
```

Tetragon (eBPF) Falco'dan daha düşük overhead'li, Cilium ekosistemiyle bütünleşik.

> Detay: [`Runtime-Security.md`](Runtime-Security.md) (Faz 2).

---

## 9️⃣ CIS Benchmark Otomasyonu

```bash
# kube-bench: CIS Benchmark check
docker run --rm --pid=host \
  -v /etc:/etc:ro -v /var:/var:ro \
  aquasec/kube-bench:latest run --targets node,policies

# Cluster-wide kube-hunter (penetration test perspektifi)
docker run --rm aquasec/kube-hunter:latest --remote <CLUSTER_API>
```

CI'da haftada bir çalıştır → Slack/PagerDuty'e raporla.

---

## 🔟 Multi-Tenancy (Soft Multi-Tenancy)

Aynı cluster'da farklı ekipler:

| Kontrol | Amaç |
|---|---|
| **Namespace per team** | Logical separation |
| **ResourceQuota** | Bir tenant cluster'ı tüketmesin |
| **LimitRange** | Default request/limit |
| **NetworkPolicy** | Cross-tenant trafik yok |
| **PSS restricted** | Privilege escalation yok |
| **PriorityClass** | Sistem pod'ları > tenant pod'ları |
| **NodeSelector / Taint** | Tenant izolasyonu node bazında (hard tenancy yaklaşımı) |

**Hard multi-tenancy** (örn: SaaS müşteri başına izole kümeler) için:
- vCluster, Capsule veya cluster-per-tenant.
- Aynı cluster'da hard tenancy = saldırgan eninde sonunda çıkar (kernel exploit ile).

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| `kubectl create clusterrolebinding ...cluster-admin` | Tüm cluster sahibi olur | Namespace-bound Role + grup |
| `image: nginx` (tag yok) | `latest` çekiyor | Digest pin: `nginx@sha256:...` |
| `runAsUser: 0` | Container = root | `runAsNonRoot: true`, UID 10000+ |
| `hostNetwork: true` (gereksiz) | Pod node IP'sinde | Service ile expose et |
| `hostPath: /` | Node FS pod'a açık | PV/PVC, CSI |
| `privileged: true` | Tüm capability açık | Sadece DaemonSet'ler için, restricted'a sokma |
| Default ServiceAccount + token mount | API'ye explicit erişim | `automountServiceAccountToken: false` |
| `NetworkPolicy yok` | Her pod her pod'a | Default-deny + whitelist |
| `Secret` env var olarak | Process listesinde görünür | File mount tmpfs |
| Audit log yok | Forensic imkansız | Audit + SIEM |
| Public API server + token | İhlal an meselesi | Private API + OIDC + MFA |

---

## 📋 Hardening Checklist (sprint zero için)

```
[ ] Audit log açık + SIEM'e ship ediliyor
[ ] OIDC entegre, statik token yok
[ ] API server private veya IP allow-list + MFA
[ ] etcd encryption-at-rest (KMS provider)
[ ] PSS: restricted enforce non-system namespace'lerde
[ ] NetworkPolicy: default-deny + DNS whitelist tüm namespace'lerde
[ ] RBAC: cluster-admin <= 2 kişi, geri kalan namespace-bound
[ ] ServiceAccount: kullanılmayan token mount kapalı
[ ] Image: digest pinning, signed images, Kyverno verifyImages
[ ] Image scan: CI'da Trivy, CRITICAL/HIGH = fail
[ ] Secrets: Vault + ESO veya equivalent, etcd plaintext yok
[ ] kube-bench: haftada bir, raporla
[ ] Falco/Tetragon: en azından "shell in container" + "writes to /etc" alarmı
[ ] LimitRange + ResourceQuota her namespace'de
[ ] Container: runAsNonRoot, readOnlyRootFilesystem, drop ALL caps
[ ] seccompDefault=true (k8s ≥1.27)
[ ] Backup: etcd + PV snapshot + restore tatbikatı
```

---

## 📚 Referanslar

- **CIS Kubernetes Benchmark v1.10** (2025) — `kube-bench` ile otomatize
- **NSA/CISA Kubernetes Hardening Guide** v1.2
- **Kubernetes Pod Security Standards** — kubernetes.io/docs/concepts/security/pod-security-standards/
- **Falco Rules** — falco.org/docs/rules/
- [`DevSecOps-Pipeline.md`](DevSecOps-Pipeline.md) — pipeline tarafı
- [`Policy-as-Code-OPA-Kyverno.md`](Policy-as-Code-OPA-Kyverno.md) (Faz 2)
- [`Secrets-Management.md`](Secrets-Management.md) (Faz 2)
- [`05-Kubernetes/Production-Checklist.md`](../05-Kubernetes/Production-Checklist.md) — operasyonel checklist
- [`17-Templates/kyverno-policies/`](../17-Templates/kyverno-policies/) — hazır policy örnekleri

---

> *"Hardening 'bir sefer yapılır' değil — **continuous compliance**.
> Cluster bir hafta sonra checklist'in dışına kayar; otomasyon yoksa
> drift fark edilmez."*
