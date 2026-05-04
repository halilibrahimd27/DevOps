# Sözlük — Türkçe ↔ İngilizce DevOps Terim Rehberi

> *Bu repo Türkçe yazılır, ama tool isimleri/akronimler/jargon
> İngilizcedir. Bu sözlük "neyi nasıl Türkçeleştirelim, neyi
> bırakalım" sorusunun cevabıdır.*

> 🔑 **Çeviri felsefesi:** Akronim/protokol/tool ismi **çevirme**.
> Kavram/eylem **doğal Türkçe** kullan. "Production" değil "üretim/prod"
> ama "Continuous Integration" değil "CI"; "Service Mesh" diye bırak,
> "servis ağı" sun'i durur.

---

## A

| EN | TR / Açıklama |
|---|---|
| **Admission Controller** | K8s API server'da kabul kontrolcüsü; istek validate/mutate eder |
| **AppArmor** | Linux Mandatory Access Control; profil bazlı uygulama izolasyonu |
| **API** | API (çevirme — endüstri standardı) |
| **Artifact** | İmaj/paket/binary; CI çıktısı (kelime kalır) |
| **Attestation** | İmzalı metadata claim (SLSA, in-toto) |
| **Autoscaler** | Otomatik ölçekleyici (HPA, VPA, CA) |
| **AuthN / AuthZ** | Authentication (kimlik doğrulama) / Authorization (yetkilendirme) |

## B

| EN | TR / Açıklama |
|---|---|
| **Backstage** | Spotify'ın açık kaynak IDP framework'ü |
| **Baseline** | Temel/başlangıç ölçümü (baseline kalır, "temel ölçü" alternatifi) |
| **Blast radius** | Bir değişikliğin/hatanın etkilediği alan |
| **Blameless** | Suçlamasız (postmortem'de) |
| **Blue/Green** | Mavi/yeşil deploy — iki sürüm paralel, traffic switch |
| **BuildKit** | Docker yeni nesil image builder |
| **Burnout** | Tükenmişlik |

## C

| EN | TR / Açıklama |
|---|---|
| **Canary** | Kanarya — ufak yüzdelik traffic'le yeni sürüm test |
| **CD** | Continuous Delivery / Deployment (sürekli teslim) — CD kalır |
| **CI** | Continuous Integration (sürekli entegrasyon) — CI kalır |
| **CIDR** | IP adres bloğu notasyonu |
| **CISA** | US Cybersecurity & Infrastructure Security Agency |
| **CIS Benchmark** | Center for Internet Security güvenlik standardı |
| **Cilium** | eBPF-tabanlı CNI + service mesh |
| **CNCF** | Cloud Native Computing Foundation |
| **CNI** | Container Network Interface (pod network) |
| **Compliance** | Uyum / mevzuata uyum |
| **Conformance test** | Uyumluluk testi (Gateway API, K8s) |
| **CRD** | Custom Resource Definition (K8s) |
| **Crossplane** | Cloud-native control plane / IaC alternatifi |
| **CSI** | Container Storage Interface (volume) |
| **CSRD** | EU Corporate Sustainability Reporting Directive |
| **CTO** | Chief Technology Officer |
| **CVE** | Common Vulnerabilities and Exposures (güvenlik açığı kayıt) |

## D

| EN | TR / Açıklama |
|---|---|
| **DAG** | Directed Acyclic Graph (yönlü döngüsüz çizge); pipeline yapısı |
| **DDoS** | Distributed Denial of Service (dağıtık hizmet engelleme) |
| **Deployment** | Deploy / dağıtım (kelime kalır) |
| **DevSecOps** | Development + Security + Operations |
| **DFD** | Data Flow Diagram (veri akış diyagramı) |
| **Distroless** | Minimal base image (sadece app + minimum runtime) |
| **DLQ** | Dead Letter Queue (başarısız mesaj kuyruğu) |
| **DNS** | DNS (kalır) |
| **DORA** | DevOps Research and Assessment metrik takımı |
| **DPA** | Data Processing Agreement (veri işleme sözleşmesi) |
| **DPIA** | Data Protection Impact Assessment (veri koruma etki değerlendirmesi) |
| **DPO** | Data Protection Officer |
| **Drift** | Sapma — Git'teki niyet ile cluster'daki gerçek arasındaki fark |
| **DSL** | Domain Specific Language |

## E

| EN | TR / Açıklama |
|---|---|
| **eBPF** | Extended Berkeley Packet Filter (kernel programlama framework'ü) |
| **EBS** | AWS Elastic Block Store |
| **EKS** | AWS Elastic Kubernetes Service |
| **Encryption-at-rest / -in-transit** | Depodayken / iletim sırasında şifreleme |
| **Endpoint** | Endpoint (kalır), bazen "uç nokta" |
| **Envoy** | Service mesh proxy (Istio, AWS App Mesh) |
| **Error budget** | Hata bütçesi |
| **ESO** | External Secrets Operator |
| **etcd** | K8s key-value store |
| **EU AI Act** | Avrupa Birliği Yapay Zeka Yasası |

## F

| EN | TR / Açıklama |
|---|---|
| **Falco** | Runtime security detector (CNCF) |
| **Feature flag** | Özellik bayrağı |
| **FIDO2** | Phishing-resistant authentication standardı |
| **FinOps** | Finance + Operations — bulut maliyet yönetimi |
| **Flux** | GitOps tool (CNCF) |

## G

| EN | TR / Açıklama |
|---|---|
| **Gateway API** | K8s yeni nesil ingress standardı |
| **GDPR** | EU General Data Protection Regulation |
| **gh-ost** | GitHub Online Schema Transmogrifier (MySQL) |
| **gitleaks** | Secret detection in Git |
| **GitOps** | Git'i tek doğruluk kaynağı yapan deploy felsefesi |
| **GPAI** | General Purpose AI (foundation model) |
| **Graviton** | AWS ARM CPU'lar |
| **GSF** | Green Software Foundation |

## H

| EN | TR / Açıklama |
|---|---|
| **Helm** | K8s paket yöneticisi |
| **HITL / HOTL** | Human-in-the-loop / Human-on-the-loop (insan onay/gözlem) |
| **HPA** | Horizontal Pod Autoscaler |
| **HSM** | Hardware Security Module |
| **HTTPS** | HTTPS (kalır) |
| **Hubble** | Cilium gözlem UI'ı |

## I

| EN | TR / Açıklama |
|---|---|
| **IaaS / PaaS / SaaS** | Infrastructure / Platform / Software as a Service |
| **IaC** | Infrastructure as Code (kod olarak altyapı) |
| **IAM** | Identity and Access Management (kimlik ve erişim yönetimi) |
| **IC** | Incident Commander (incident komutanı) |
| **IDP** | Internal Developer Platform |
| **IdP** | Identity Provider (kimlik sağlayıcı) |
| **Idempotent** | İdempotent — aynı işlem N kez = 1 kez |
| **Ingress** | K8s'de external traffic giriş kaynağı |
| **in-toto** | Supply chain attestation framework |
| **IRSA** | IAM Roles for Service Accounts (AWS) |
| **Istio** | Service mesh |
| **ISO 27001** | Information Security Management standardı |

## J

| EN | TR / Açıklama |
|---|---|
| **JSON** | JSON (kalır) |
| **JWT** | JSON Web Token |

## K

| EN | TR / Açıklama |
|---|---|
| **KEDA** | Kubernetes Event-Driven Autoscaler |
| **Kepler** | eBPF-tabanlı pod-level energy ölçümü |
| **Keyless signing** | Anahtar-siz imzalama (cosign + OIDC) |
| **KMS** | Key Management Service |
| **kube-proxy** | K8s service network bileşeni |
| **kubectl** | K8s CLI (kalır) |
| **Kubernetes / k8s** | Kubernetes / k8s (kalır) |
| **Kustomize** | K8s manifest customizer |
| **KVKK** | Kişisel Verilerin Korunması Kanunu (TR) |
| **Kyverno** | K8s policy engine |

## L

| EN | TR / Açıklama |
|---|---|
| **L4 / L7** | Layer 4 (transport) / Layer 7 (application) |
| **Linkerd** | Lightweight service mesh |
| **LINDDUN** | Privacy threat modeling framework |
| **Linting** | Lint — statik kod kontrolü (kelime kalır) |
| **Loki** | Grafana log aggregation |
| **LRT** | Long-running task (uzun-süreli iş) |

## M

| EN | TR / Açıklama |
|---|---|
| **Manifest** | K8s yaml dosyası (kelime kalır) |
| **Mesh** | Service mesh (kelime kalır) |
| **MFA** | Multi-Factor Authentication (çok faktörlü kimlik doğrulama) |
| **Migration** | Migration / migrasyon — DB schema değişikliği |
| **MITRE ATT&CK** | Adversary tactics & techniques framework |
| **MTBF** | Mean Time Between Failures (arıza arası ortalama süre) |
| **MTTD** | Mean Time To Detect (tespit süresi) |
| **MTTR** | Mean Time To Recover/Resolve (kurtarma süresi) |
| **mTLS** | mutual TLS (karşılıklı TLS) |
| **Mutating** | Mutating — kabul anında manifest değiştiren admission |

## N

| EN | TR / Açıklama |
|---|---|
| **Namespace** | İsim alanı / namespace (kelime kalır) |
| **NetworkPolicy** | K8s ağ kuralı (kelime kalır) |
| **NIST** | US National Institute of Standards and Technology |
| **NIS2** | EU Network and Information Security Directive 2 |
| **Node** | Düğüm / node — K8s VM/server (kelime kalır) |
| **NodePort** | K8s service tip (port-bazlı) |
| **NPS** | Net Promoter Score (müşteri/dev memnuniyet ölçümü) |

## O

| EN | TR / Açıklama |
|---|---|
| **Observability** | Gözlemlenebilirlik (3 pillar: metrics, logs, traces) |
| **OIDC** | OpenID Connect (auth standardı) |
| **OOM** | Out Of Memory (bellek tükendi) |
| **OPA** | Open Policy Agent (Rego policy engine) |
| **OpenTelemetry / OTel** | Observability instrumentation standardı |
| **OpenTofu** | Terraform open-source fork |
| **Orchestration** | Orkestrasyon |
| **OWASP** | Open Web Application Security Project |

## P

| EN | TR / Açıklama |
|---|---|
| **PagerDuty** | On-call alerting platform |
| **Patroni** | Postgres HA tool |
| **PCI DSS** | Payment Card Industry Data Security Standard |
| **PDB** | PodDisruptionBudget (K8s) |
| **PgBouncer** | Postgres connection pooler |
| **PII** | Personally Identifiable Information (kişisel veri) |
| **PIM** | Privileged Identity Management (just-in-time access) |
| **Playbook** | Playbook (kalır), runbook ile aynı anlamda |
| **Postgres / PostgreSQL** | Postgres (kalır) |
| **Postmortem** | Postmortem — incident sonrası rapor (kelime kalır) |
| **PR** | Pull Request |
| **Prometheus** | Metrics monitoring system |
| **Provenance** | Köken bilgisi (SLSA terim) |
| **PSP** | Pod Security Policy (deprecated, PSS yerine) |
| **PSS** | Pod Security Standards |
| **PV / PVC** | Persistent Volume / Persistent Volume Claim |

## Q

| EN | TR / Açıklama |
|---|---|
| **Quarantine** | Karantina (compromised pod izolasyonu) |
| **Quorum** | Yeterli çoğunluk (Raft, etcd) |

## R

| EN | TR / Açıklama |
|---|---|
| **RBAC** | Role-Based Access Control |
| **Reconciliation** | Uzlaşma / sürekli senkron — ArgoCD/Flux Git ↔ cluster |
| **Rego** | OPA'nın policy DSL'i |
| **Renovate** | Dependency update bot |
| **Replication lag** | Replikasyon gecikmesi |
| **Reproducible build** | Tekrar üretilebilir build |
| **RFC** | Request For Comments (tasarım dokümanı) |
| **Rollback** | Geri alma / rollback |
| **Rollout** | Aşamalı deploy |
| **RPO / RTO** | Recovery Point Objective (veri kaybı toleransı) / Recovery Time Objective (kurtarma süresi) |
| **Runbook** | Runbook — alarm/sorun çözüm rehberi (kelime kalır) |
| **Runtime** | Runtime / çalışma zamanı |

## S

| EN | TR / Açıklama |
|---|---|
| **SaaS** | Software as a Service |
| **SAML** | Security Assertion Markup Language (auth) |
| **SAST** | Static Application Security Testing |
| **SBOM** | Software Bill of Materials (yazılım malzeme listesi) |
| **SCA** | Software Composition Analysis (dependency security) |
| **Scaffold** | İskelet — yeni proje template'i |
| **SCC** | Standard Contractual Clauses (EU veri ihracı) |
| **SCI** | Software Carbon Intensity |
| **SCRAM-SHA-256** | Salted Challenge Response Auth Mechanism |
| **Secret** | Sır — credential, key (kelime kalır) |
| **seccomp** | Linux secure computing mode (syscall filter) |
| **SELinux** | Security-Enhanced Linux MAC |
| **Self-heal** | Otomatik düzelme (ArgoCD selfHeal) |
| **Service Account / SA** | K8s servis hesabı |
| **Service Mesh** | Service mesh (kalır) |
| **SEV1 / SEV2** | Severity 1 / 2 — incident etki seviyesi |
| **Sharding** | Sharding — veri/yük bölme |
| **Shift-left** | Sola kaydırma — kontrolleri sürecin başına çekmek |
| **Sidecar** | Yan-kova / sidecar container |
| **Sigstore** | Software signing infrastructure (cosign, Rekor, Fulcio) |
| **SIEM** | Security Information and Event Management |
| **SLA** | Service Level Agreement (müşteriye söz) |
| **SLI** | Service Level Indicator (ölçülen) |
| **SLO** | Service Level Objective (iç hedef) |
| **SLSA** | Supply-chain Levels for Software Artifacts |
| **SME** | Subject Matter Expert (konu uzmanı) |
| **SMI** | Service Mesh Interface |
| **SOC2** | Service Organization Control 2 (audit standardı) |
| **SOPS** | Secrets OPerationS (Mozilla file encryption) |
| **SPIFFE / SPIRE** | Secure Production Identity Framework + reference impl |
| **SQLi** | SQL Injection |
| **SRE** | Site Reliability Engineering |
| **SSO** | Single Sign-On |
| **StatefulSet** | K8s ordered + persistent workload |
| **STRIDE** | Threat modeling framework |
| **Sustainability** | Sürdürülebilirlik (yeşil yazılım) |

## T

| EN | TR / Açıklama |
|---|---|
| **Tag** | Tag — image versiyonu (kelime kalır) |
| **TDE** | Transparent Data Encryption (DB) |
| **Telemetry** | Telemetri |
| **Terraform** | Terraform (kalır) |
| **Tetragon** | Cilium runtime security |
| **Threat model** | Tehdit modeli |
| **TLS** | Transport Layer Security |
| **Toil** | Toil — tekrarlayan, manuel, value-yaratmayan iş (kelime kalır) |
| **Trivy** | Aqua Security scanner |
| **Trunk-Based Development / TBD** | Trunk-based — tek ana branch geliştirme |

## U

| EN | TR / Açıklama |
|---|---|
| **Upstream / Downstream** | Yukarı akış / aşağı akış |
| **UTC** | Coordinated Universal Time |

## V

| EN | TR / Açıklama |
|---|---|
| **Validating** | Validating admission — kabul kontrolü (red/onay) |
| **Vault** | HashiCorp secret manager |
| **Velocity** | Velocity / hız |
| **VERBİS** | Veri Sorumluları Sicil Bilgi Sistemi (KVK) |
| **Versioning** | Versiyonlama |
| **VirtualService** | Istio L7 routing CRD |
| **VPA** | Vertical Pod Autoscaler |
| **VPC** | Virtual Private Cloud |
| **VPN** | Virtual Private Network |
| **Vulnerability** | Açık / zayıflık (vulnerability kalır) |

## W

| EN | TR / Açıklama |
|---|---|
| **WAF** | Web Application Firewall |
| **WAL** | Write-Ahead Log (Postgres) |
| **WAL-G** | WAL archiving tool |
| **Watcher** | İzleyici — controller pattern |
| **Webhook** | Webhook (kalır) |
| **Workload** | İş yükü / workload |

## X

| EN | TR / Açıklama |
|---|---|
| **XSS** | Cross-Site Scripting |

## Y

| EN | TR / Açıklama |
|---|---|
| **YAML** | YAML (kalır) |

## Z

| EN | TR / Açıklama |
|---|---|
| **Zero downtime** | Sıfır kesinti |
| **Zero Trust** | Sıfır güven (network/security paradigma) |

---

## 🇹🇷 Türkçe → İngilizce Hızlı Bakış

| TR | EN |
|---|---|
| altyapı | infrastructure |
| arıza | failure / outage |
| ayrıcalık | privilege |
| bağımlılık | dependency |
| bütçe | budget (error budget) |
| dağıtım | deployment |
| denetim kaydı | audit log |
| destek | support |
| dosya yapısı | repo structure |
| etiket | label / tag |
| gözlem(lenebilirlik) | observability |
| güvenlik açığı | vulnerability / CVE |
| hata bütçesi | error budget |
| imzalama | signing |
| izolasyon | isolation |
| kabul kontrolü | admission control |
| kanı durdur | mitigate (incident'ta) |
| kararlılık | stability / reliability |
| karşılıklı TLS | mutual TLS / mTLS |
| kuyruk | queue |
| metrik | metric |
| ölçeklendirme | scaling |
| onay | approval |
| oturum | session |
| paylaşım | sharing (file vs lock) |
| performans iyileştirmesi | optimization |
| sürdürülebilirlik | sustainability |
| sürdürülebilir | sustainable |
| sızıntı | leak |
| sürekli entegrasyon | continuous integration / CI |
| şifreleme | encryption |
| tedarik zinciri | supply chain |
| tehdit modeli | threat model |
| tekrar üretilebilir | reproducible |
| üretim | production / prod |
| yol haritası | roadmap |
| yük dengeleyici | load balancer |
| zaman aşımı | timeout |

---

## 📚 Stil Tercihleri (Bu Repo İçin)

1. **Akronim/protokol/tool ismi**: Bırak. Hiç çevirme. (`Kubernetes`, `TLS`, `OIDC`)
2. **Kavram/eylem**: Doğal Türkçe varsa kullan. ("kabul kontrolü" yerine "admission" yine olur, ama "vulnerability" → "açık" eski kalır)
3. **İlk kullanım**: İngilizce + parantez içinde Türkçe. *"Service Level Indicator (SLI)"*
4. **Tekrar**: Akronim yeter. *"SLI'lar müşteri perspektifinden..."*
5. **Yeni terimler (2024-2026)**: Henüz Türkçe karşılığı oturmamış olabilir — İngilizce bırak. ("eBPF", "SLSA", "GPAI")

---

> *"Türkçeleştirmek niyet değil, **hizmet**. Okuyucuya kolaylık sağlamıyorsa
> sun'i çeviri zarar verir. Tool adını çeviren değil, **kavramı çeviren**
> repo iyi okunur."*
