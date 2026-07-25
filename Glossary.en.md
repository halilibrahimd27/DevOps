---
title: 📖 Glossary
description: "Turkish ↔ English DevOps/DevSecOps glossary — consistent equivalents for tool names, acronyms and jargon."
---
# Glossary — DevOps / DevSecOps Terms

> *A quick reference for the DevOps / DevSecOps terms used across this
> handbook. Definitions are in English; a Turkish equivalent is kept
> where it helps Turkish-speaking readers or where TR/EU regulatory
> context matters.*

---

## A

| Term | Definition |
|---|---|
| **ack** | Acknowledgment — confirming you've seen an alert and are taking ownership of it; if many alerts get ack'ed and closed but few turn into action, the alerting is just noise. |
| **Admission Controller** | Admission controller in the K8s API server; validates and/or mutates requests before they're persisted. |
| **ADR** | Architecture Decision Record — a short document recording an architectural decision along with its context and the alternatives that were rejected. |
| **Agent (LLM)** | LLM-based automation; operates via tool calls plus reasoning. |
| **Alertmanager** | Prometheus's component for grouping, routing, and silencing alerts; the rule fires in Prometheus, but Alertmanager sends the notification. |
| **AppArmor** | Linux Mandatory Access Control; profile-based application isolation. |
| **API** | API — kept as-is; industry standard. |
| **Artifact** | Image/package/binary; the output of a CI run. |
| **Attestation** | A signed metadata claim (SLSA, in-toto). |
| **Atlantis** | Terraform PR-driven workflow tool. |
| **Autoscaler** | Scales workloads automatically (HPA, VPA, CA). |
| **AuthN / AuthZ** | Authentication (verifying identity) / Authorization (granting permissions). |

## B

| Term | Definition |
|---|---|
| **Backstage** | Spotify's open-source IDP framework. |
| **Baseline** | A baseline/starting measurement used for comparison. |
| **Blast radius** | The scope affected by a change or failure. |
| **Blameless** | Blame-free (in postmortems) — focus on the process/system failure, not on who to blame. |
| **Blue/Green** | Blue/green deploy — two versions run in parallel, traffic is switched between them. |
| **BuildKit** | Docker's next-generation image builder. |
| **Burnout** | Burnout — physical and emotional exhaustion from sustained work stress. |
| **Burn rate** | How many times faster than normal you're consuming the SLO error budget. |

## C

| Term | Definition |
|---|---|
| **Canary** | Canary — testing a new version with a small percentage of traffic. |
| **Capsule** | K8s multi-tenancy operator. |
| **Cardinality** | The number of unique label-value combinations for a metric (Prometheus). |
| **Carbon-aware** | Running workloads at times/locations with lower carbon intensity. |
| **Chainguard Images** | A distroless alternative aimed at zero CVEs, rebuilt daily. |
| **Chaos engineering** | The practice of deliberately breaking a system in a controlled way to prove its resilience (game day). |
| **Cognitive load** | The mental load a team carries at any given time; Team Topologies and platform engineering aim to reduce it. |
| **Compute** | Compute resource — the CPU/memory that runs a workload (VM, container, server). |
| **CD** | Continuous Delivery / Deployment. |
| **CI** | Continuous Integration. |
| **CIDR** | IP address block notation. |
| **CISA** | US Cybersecurity & Infrastructure Security Agency. |
| **CIS Benchmark** | Center for Internet Security's security hardening standard. |
| **Cilium** | eBPF-based CNI plus service mesh. |
| **CNCF** | Cloud Native Computing Foundation. |
| **CNI** | Container Network Interface (pod networking). |
| **CloudNativePG (CNPG)** | K8s-native Postgres operator (CNCF Sandbox). |
| **Composition (Crossplane)** | Self-service abstraction built from an XRD plus a template. |
| **Compliance** | Compliance — meeting regulatory/legal requirements. |
| **Conformance test** | Conformance test (Gateway API, K8s). |
| **conntrack** | Linux netfilter's connection-tracking/NAT table. |
| **CRD** | Custom Resource Definition (K8s). |
| **Crossplane** | Cloud-native control plane / IaC alternative. |
| **CSI** | Container Storage Interface (volumes). |
| **CSRD** | EU Corporate Sustainability Reporting Directive. |
| **CTO** | Chief Technology Officer. |
| **CUDs** | GCP Committed Use Discounts. |
| **CVE** | Common Vulnerabilities and Exposures (a public vulnerability record). |

## D

| Term | Definition |
|---|---|
| **DAG** | Directed Acyclic Graph; the structure behind most pipelines. |
| **Daemon** | A service process that runs continuously in the background (e.g. nginx, sshd). |
| **dmesg** | Kernel ring-buffer messages (hardware/driver/OOM); the equivalent of `journalctl -k`. |
| **DDoS** | Distributed Denial of Service. |
| **DCS** | Distributed Configuration Store (etcd / Consul; used by Patroni). |
| **DeepSeek** | Open-source LLM (671B param MoE, ~37B active). |
| **Direct Connect** | AWS dedicated fiber on-prem ↔ cloud link. |
| **driftctl** | Terraform unmanaged resource detection. |
| **Deployment** | Deploy — releasing a new version to an environment. |
| **DevSecOps** | Development + Security + Operations. |
| **DFD** | Data Flow Diagram. |
| **Distroless** | A minimal base image (just the app plus a minimal runtime). |
| **DLQ** | Dead Letter Queue — a queue for messages that failed processing. |
| **DNS** | DNS. |
| **DORA** | DevOps Research and Assessment — the team behind the DORA metrics. |
| **DPA** | Data Processing Agreement. |
| **DPIA** | Data Protection Impact Assessment. |
| **DPO** | Data Protection Officer. |
| **Drift** | Drift — the gap between what's declared in Git and what's actually running in the cluster. |
| **DSL** | Domain Specific Language. |

## E

| Term | Definition |
|---|---|
| **eBPF** | Extended Berkeley Packet Filter — a framework for programming the kernel. |
| **EBS** | AWS Elastic Block Store. |
| **egress** | Outbound network traffic; cloud providers usually charge for data transfer out. |
| **EKS** | AWS Elastic Kubernetes Service. |
| **Encryption-at-rest / -in-transit** | Encryption while stored / encryption while in transit. |
| **Endpoint** | Endpoint — a reachable address for a service or API. |
| **Envoy** | Service mesh proxy (Istio, AWS App Mesh). |
| **Error budget** | Error budget — the allowed amount of unreliability before the SLO is breached. |
| **ESO** | External Secrets Operator. |
| **etcd** | K8s key-value store. |
| **EU AI Act** | The European Union's Artificial Intelligence Act. |

## F

| Term | Definition |
|---|---|
| **Falco** | Runtime security detector (CNCF). |
| **Feature flag** | Feature flag — a toggle that turns functionality on/off without a new deploy. |
| **FIDO2** | A phishing-resistant authentication standard. |
| **FinOps** | Finance + Operations — cloud cost management. |
| **Flame Graph** | A profiling visualization (CPU time per function). |
| **Flux** | GitOps tool (CNCF). |
| **Free tier** | A cloud provider's free usage tier; charges kick in once a limit (hours/GB/requests) is exceeded. |
| **Fulcio** | Sigstore short-lived cert authority. |

## G

| Term | Definition |
|---|---|
| **Gateway API** | Kubernetes's next-generation ingress standard. |
| **GDPR** | EU General Data Protection Regulation. |
| **gh-ost** | GitHub Online Schema Transmogrifier (MySQL). |
| **gitleaks** | Secret detection in Git. |
| **GitOps** | A deployment philosophy that treats Git as the single source of truth. |
| **Goldilocks** | Fairwinds VPA recommendation tool. |
| **Golden Path** | An opinionated, paved path in an IDP — e.g. "spin up a new service in 5 minutes." |
| **GPAI** | General Purpose AI (foundation model). |
| **Graphite** | Stacked diff CLI tool. |
| **Graviton** | AWS's ARM-based CPUs. |
| **GSF** | Green Software Foundation. |

## H

| Term | Definition |
|---|---|
| **Hallucination** | An LLM stating something it doesn't actually know as if it were certain. |
| **Helm** | Kubernetes's package manager. |
| **HITL / HOTL** | Human-in-the-loop / Human-on-the-loop (human approval/oversight). |
| **HPA** | Horizontal Pod Autoscaler. |
| **HSM** | Hardware Security Module. |
| **HTTPS** | HTTPS. |
| **Hubble** | Cilium's observability UI. |

## I

| Term | Definition |
|---|---|
| **IaaS / PaaS / SaaS** | Infrastructure / Platform / Software as a Service. |
| **IaC** | Infrastructure as Code. |
| **IAM** | Identity and Access Management. |
| **IC** | Incident Commander. |
| **ICMP** | Internet Control Message Protocol — the portless reachability protocol used by `ping`/`traceroute`. |
| **IDP** | Internal Developer Platform. |
| **IdP** | Identity Provider. |
| **Idempotent** | Idempotent — running the same operation N times has the same effect as running it once. |
| **Ingress** | The entry point for external traffic into a Kubernetes cluster. |
| **in-toto** | Supply chain attestation framework. |
| **IRSA** | IAM Roles for Service Accounts (AWS). |
| **Istio** | Service mesh. |
| **ISO 27001** | An information security management standard. |

## J

| Term | Definition |
|---|---|
| **JSON** | JSON. |
| **JWT** | JSON Web Token. |

## K

| Term | Definition |
|---|---|
| **Karpenter** | AWS K8s node autoscaler (consolidation + spot). |
| **KEDA** | Kubernetes Event-Driven Autoscaler. |
| **Kepler** | eBPF-based pod-level energy measurement. |
| **Keyless signing** | Signing without a long-lived private key (cosign + OIDC). |
| **kind** | Kubernetes-in-Docker — a local, single-machine cluster running inside Docker containers (for testing/learning). |
| **k3s** | A lightweight, single-binary Kubernetes distribution (for edge/local/small environments). |
| **KMS** | Key Management Service. |
| **Kubecost** | K8s per-namespace cost dashboard. |
| **kube-proxy** | Kubernetes's service networking component. |
| **kubectl** | Kubernetes's CLI. |
| **Kubernetes / k8s** | Kubernetes / k8s. |
| **kubent** | K8s deprecated API detection tool. |
| **Kustomize** | K8s manifest customizer. |
| **KVKK** | Turkey's Personal Data Protection Law — the Turkish equivalent of GDPR. |
| **Kyverno** | K8s policy engine. |

## L

| Term | Definition |
|---|---|
| **L4 / L7** | Layer 4 (transport) / Layer 7 (application). |
| **LangChain** | LLM agent framework. |
| **Linkerd** | Lightweight service mesh. |
| **LINDDUN** | Privacy threat modeling framework. |
| **Linting** | Lint — static code analysis. |
| **Llama** | Meta's family of open-source LLMs. |
| **LLMOps** | The discipline of taking LLMs to production and operating them — prompt versioning, evals, guardrails, token cost, and observability. |
| **LocalStack** | An emulator that mimics AWS services locally — lets you practice Terraform/CLI without a real cloud account or cost. |
| **Loki** | Grafana log aggregation. |
| **LRT** | Long-running task. |

## M

| Term | Definition |
|---|---|
| **Manifest** | A Kubernetes YAML file. |
| **Mesh** | Service mesh. |
| **MFA** | Multi-Factor Authentication. |
| **Migration** | Migration — a database schema change. |
| **MITRE ATT&CK** | Adversary tactics & techniques framework. |
| **MTBF** | Mean Time Between Failures. |
| **MTTD** | Mean Time To Detect. |
| **MTTR** | Mean Time To Recover/Resolve. |
| **mTLS** | Mutual TLS — both client and server authenticate each other. |
| **Mutating** | Mutating admission — modifies a manifest at admission time. |

## N

| Term | Definition |
|---|---|
| **Namespace** | Namespace. |
| **NAT** | Network Address Translation — maps private IPs to a single external IP; in the cloud, a NAT Gateway charges for egress. |
| **NetworkPolicy** | A Kubernetes network rule. |
| **NIST** | US National Institute of Standards and Technology. |
| **NIS2** | EU Network and Information Security Directive 2. |
| **Node** | Node — a VM/server in a Kubernetes cluster. |
| **NodePort** | A Kubernetes Service type (port-based). |
| **NodeLocal DNSCache** | A node-level DNS cache that reduces load on CoreDNS. |
| **NPS** | Net Promoter Score — a customer/developer satisfaction measure. |
| **NTP** | Network Time Protocol — keeps machine clocks in sync; drift causes log and certificate errors. |

## O

| Term | Definition |
|---|---|
| **Observability** | Observability (four pillars: metrics, logs, traces, profiles). |
| **OIDC** | OpenID Connect — an authentication standard. |
| **Ollama** | Local LLM serving CLI. |
| **OOM** | Out Of Memory. |
| **OPA** | Open Policy Agent (Rego policy engine). |
| **OpenCost** | CNCF cost allocation engine. |
| **OpenSearch** | AWS fork of Elasticsearch (Apache 2 license). |
| **OpenTelemetry / OTel** | An observability instrumentation standard. |
| **OpenTofu** | Terraform open-source fork. |
| **Operator** | Domain-specific K8s controller (CRD-based). |
| **Orchestration** | Orchestration — coordinating multiple components/services as a system. |
| **OWASP** | Open Web Application Security Project. |

## P

| Term | Definition |
|---|---|
| **PagerDuty** | On-call alerting platform. |
| **Patroni** | Postgres HA tool. |
| **PCI DSS** | Payment Card Industry Data Security Standard. |
| **PDB** | PodDisruptionBudget (K8s). |
| **Percentile (p95)** | A distribution percentile; p95 latency = the duration under which 95% of requests complete. |
| **PITR** | Point-In-Time Recovery — restoring a database to a specific moment using WAL. |
| **PgBouncer** | Postgres connection pooler. |
| **pgcat** | Modern Rust-based Postgres pooler. |
| **PII** | Personally Identifiable Information. |
| **PIM** | Privileged Identity Management (just-in-time access). |
| **Playbook** | Playbook — synonymous with runbook. |
| **pluto** | K8s deprecated API detection. |
| **Postgres / PostgreSQL** | Postgres/PostgreSQL. |
| **Postmortem** | Postmortem — a post-incident report. |
| **PR** | Pull Request. |
| **Profile (continuous)** | Continuous profiling (Pyroscope) — the 4th observability pillar. |
| **Prometheus** | Metrics monitoring system. |
| **Promtail** | Loki log shipper. |
| **Provenance** | Provenance — origin/lineage information (an SLSA term). |
| **PSP** | Pod Security Policy (deprecated, replaced by PSS). |
| **PSS** | Pod Security Standards. |
| **Pulumi** | An IaC alternative that uses general-purpose programming languages. |
| **PV / PVC** | Persistent Volume / Persistent Volume Claim. |
| **Pyroscope** | Grafana continuous profiling. |

## Q

| Term | Definition |
|---|---|
| **Quarantine** | Quarantine — isolating a compromised pod. |
| **Quorum** | The minimum majority needed to reach agreement (Raft, etcd). |

## R

| Term | Definition |
|---|---|
| **RAG** | Retrieval-Augmented Generation — an LLM combined with an external knowledge source. |
| **RBAC** | Role-Based Access Control. |
| **Reconciliation** | Reconciliation — continuously syncing state, e.g. ArgoCD/Flux keeping the cluster aligned with Git. |
| **Registry** | Image registry — where you publish and store versioned container images (e.g. GHCR, ECR). |
| **Rego** | OPA's policy DSL. |
| **Rekor** | Sigstore transparent log. |
| **Renovate** | Dependency update bot. |
| **Reranker** | A second pass in RAG that improves retrieval quality. |
| **Replication lag** | Replication lag — the delay between a write on the primary and its appearance on a replica. |
| **Reproducible build** | A build that produces identical output every time it's run from the same source. |
| **Reserved Instance (RI)** | Reserved capacity — discounted cloud compute in exchange for a 1-3 year commitment; cheaper than on-demand for predictable, steady workloads. |
| **RFC** | Request For Comments — a design document. |
| **Right-sizing** | Sizing resources to actual usage — cutting waste by scaling down over-provisioned CPU/memory/instance types to match real demand. |
| **Rollback** | Rollback — reverting to a previous version. |
| **Rollout** | Rollout — a gradual/staged deploy. |
| **RPO / RTO** | Recovery Point Objective (tolerable data loss) / Recovery Time Objective (target recovery time). |
| **Runbook** | Runbook — a step-by-step guide for resolving an alert/issue. |
| **Runtime** | Runtime — the environment in which code executes. |

## S

| Term | Definition |
|---|---|
| **SaaS** | Software as a Service. |
| **SAML** | Security Assertion Markup Language (auth). |
| **Sapling** | Meta's stacked-diff Git replacement. |
| **SAST** | Static Application Security Testing. |
| **Savings Plans (SP)** | AWS commitment-based discount. |
| **SBOM** | Software Bill of Materials — an inventory of everything that goes into a piece of software. |
| **SCA** | Software Composition Analysis — scanning dependencies for security issues. |
| **Sloth** | SLO YAML → Prometheus rule generator. |
| **Scaffold** | Scaffold — a template for a new project. |
| **SCC** | Standard Contractual Clauses — for EU data transfers/exports. |
| **SCI** | Software Carbon Intensity. |
| **SCRAM-SHA-256** | Salted Challenge Response Auth Mechanism. |
| **Secret** | Secret — a credential or key. |
| **seccomp** | Linux secure computing mode (syscall filter). |
| **SELinux** | Security-Enhanced Linux MAC. |
| **Self-heal** | Automatic remediation (ArgoCD's selfHeal). |
| **semver** | Semantic Versioning — the `MAJOR.MINOR.PATCH` version scheme (e.g. `1.4.2`); an immutable version tag. |
| **Service Account / SA** | A Kubernetes service account. |
| **Service Mesh** | Service mesh. |
| **SEV1 / SEV2** | Severity 1 / 2 — the impact level of an incident. |
| **Sharding** | Sharding — splitting data/load across multiple partitions. |
| **Shift-left** | Shift-left — moving checks earlier in the process. |
| **Sidecar** | Sidecar container — an auxiliary container that runs alongside the main one in a pod. |
| **Sigstore** | Software signing infrastructure (cosign, Rekor, Fulcio). |
| **SIEM** | Security Information and Event Management. |
| **Spacelift** | Terraform/OpenTofu PR-driven workflow + drift detection. |
| **Spot Instance** | Idle cloud capacity sold at a discount (~70% cheaper), with a risk of interruption. |
| **Stacked Diffs** | Splitting a large feature into a chain of small, stacked PRs. |
| **SLA** | Service Level Agreement — a commitment made to the customer. |
| **SLI** | Service Level Indicator — what's actually measured. |
| **SLO** | Service Level Objective — the internal target. |
| **SLSA** | Supply-chain Levels for Software Artifacts. |
| **SME** | Subject Matter Expert. |
| **SMI** | Service Mesh Interface. |
| **SOC2** | Service Organization Control 2 — an audit standard. |
| **SOPS** | Secrets OPerationS (Mozilla file encryption). |
| **SPIFFE / SPIRE** | Secure Production Identity Framework For Everyone, plus its reference implementation. |
| **SQLi** | SQL Injection. |
| **SRE** | Site Reliability Engineering. |
| **SSO** | Single Sign-On. |
| **StatefulSet** | A Kubernetes workload type with ordered, persistent identity. |
| **STRIDE** | Threat modeling framework. |
| **Sustainability** | Sustainability — green software practices. |

## T

| Term | Definition |
|---|---|
| **Tag** | Tag — an image version label. |
| **Tail Sampling** | Deciding whether to sample a trace after it's completed (OTel). |
| **Taint / Toleration** | A node's "don't schedule me" marker (taint) matched against a pod's "I can tolerate this anyway" permission (toleration) — controls scheduling. |
| **TDE** | Transparent Data Encryption (DB). |
| **Team Topologies** | A team interaction model: stream-aligned, platform, enabling, complicated-subsystem. |
| **Telemetry** | Telemetry — data collected about system behavior (metrics, logs, traces). |
| **Tempo** | Grafana distributed tracing backend. |
| **Terraform** | Terraform. |
| **Tetragon** | Cilium runtime security. |
| **Thanos** | Prometheus long-term storage. |
| **Threat model** | Threat model — a structured analysis of what could go wrong and how. |
| **TLS** | Transport Layer Security. |
| **Toil** | Toil — repetitive, manual work that doesn't create lasting value. |
| **Tokenization** | Replacing a PAN with a token (reduces PCI scope). |
| **Trivy** | Aqua Security scanner. |
| **Trunk-Based Development / TBD** | Trunk-based development — everyone develops against a single main branch. |
| **Twelve-Factor App (12-Factor)** | A set of modern application principles; e.g. write logs to stdout, not to a file. |

## U

| Term | Definition |
|---|---|
| **Upstream / Downstream** | Upstream / downstream — where data/changes come from vs. where they flow to. |
| **UTC** | Coordinated Universal Time. |

## V

| Term | Definition |
|---|---|
| **vCluster** | Virtual K8s cluster (multi-tenant API isolation). |
| **Validating** | Validating admission — accepts or rejects a request at admission time. |
| **Vault** | HashiCorp secret manager. |
| **Velocity** | Velocity — the rate at which a team ships work. |
| **Vendor lock-in** | Vendor lock-in — being dependent on a provider to the point where switching away becomes costly. |
| **VERBİS** | Turkey's Data Controllers' Registry Information System (under KVKK). |
| **Versioning** | Versioning — assigning identifiers to track changes over time. |
| **VirtualService** | Istio L7 routing CRD. |
| **vLLM** | Production-grade LLM serving (multi-user, GPU). |
| **VPA** | Vertical Pod Autoscaler. |
| **VPC** | Virtual Private Cloud. |
| **VPC Endpoint** | NAT bypass for AWS services. |
| **VPN** | Virtual Private Network. |
| **Vulnerability** | Vulnerability — a weakness that can be exploited. |

## W

| Term | Definition |
|---|---|
| **WAF** | Web Application Firewall. |
| **WAL** | Write-Ahead Log (Postgres). |
| **WAL-G** | WAL archiving tool. |
| **WASM** | WebAssembly — an alternative server-side runtime. |
| **WSL2** | Windows Subsystem for Linux 2 — a real Linux kernel running on top of Windows. |
| **Watcher** | Watcher — the controller pattern of observing and reacting to state changes. |
| **Webhook** | Webhook — an HTTP callback triggered by an event. |
| **Wolfi** | Chainguard's minimal Linux distro. |
| **Workload** | Workload — the unit of work running on infrastructure. |

## X

| Term | Definition |
|---|---|
| **XSS** | Cross-Site Scripting. |

## Y

| Term | Definition |
|---|---|
| **YAML** | YAML. |

## Z

| Term | Definition |
|---|---|
| **Zero downtime** | Zero downtime — no service interruption during a change. |
| **Zero Trust** | Zero Trust — a security paradigm of "never trust, always verify." |

---

## 🇹🇷 Turkish → English Quick Reference

Useful when a Turkish term surfaces elsewhere in the handbook (regulatory names, code comments, or cross-references that haven't been translated yet):

| Turkish | English |
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
| kanı durdur | mitigate (in an incident) |
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

## 📚 Style Conventions (Used in This Handbook)

1. **Acronym/protocol/tool name**: Keep as-is. Never translate. (`Kubernetes`, `TLS`, `OIDC`)
2. **Concept/action**: Use the natural equivalent in the target language where one exists.
3. **First use**: Full term + acronym in parentheses. *"Service Level Indicator (SLI)"*
4. **Repeat**: The acronym alone is enough afterward. *"SLIs measured from the customer's perspective..."*
5. **New terms (2024-2026)**: May not have a settled equivalent yet in every language — leave in English. ("eBPF", "SLSA", "GPAI")

---

> *"Translation is a service, not an intention. If it doesn't make things
> easier for the reader, forced translation does harm. A handbook that
> translates the concept — not the tool's name — reads well."*
