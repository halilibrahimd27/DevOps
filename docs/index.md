---
hide:
  - toc
  - navigation
title: Halil İbrahim Dürmüş — DevSecOps Engineer
description: >-
  Halil İbrahim Dürmüş — DevSecOps Engineer. Kubernetes, GitOps, IaC, observability,
  supply-chain security ve SRE üzerine üretim-odaklı çalışmalar. Derin TR/EU regülasyon
  kapsamı olan bir DevSecOps handbook (21 konu, 125 deep-dive) ve açık kaynak projeler.
---

<div class="profile-hero" markdown>

![Halil İbrahim Dürmüş](https://github.com/halilibrahimd27.png){ .profile-hero__avatar .off-glb loading=lazy }

<div class="profile-hero__text" markdown>

# Halil İbrahim Dürmüş

<span class="role">DevSecOps Engineer</span>

<p class="tagline" markdown>
Güvenliği en sona bırakan pipeline'lara güvenmem. Default config "çalışıyor" demek benim için "henüz kırılmadı" demek — Kubernetes'i de tedarik zincirini de baştan sıkı kurarım, sonradan yamamam.
<span class="en">I'd rather argue about a threat model on day one than patch a breach on day ninety.</span>
</p>

<div class="profile-links" markdown>
[:material-email: E-posta](mailto:s.ibrahimdrms@gmail.com){ .md-button .md-button--primary }
[:fontawesome-brands-github: GitHub](https://github.com/halilibrahimd27){ .md-button }
[:fontawesome-brands-linkedin: LinkedIn](https://www.linkedin.com/in/halilibrahimd){ .md-button }
[:material-book-open-variant: Knowledge Base](#flagship){ .md-button }
</div>

</div>
</div>

=== "🇹🇷 Türkçe"

    Merhaba 👋 Ben Halil. **DevSecOps** odaklı çalışıyorum: CI/CD pipeline'larına güvenlik kapıları
    gömmek, Kubernetes üzerinde güvenilir platformlar kurmak, IaC ile altyapıyı kod gibi yönetmek ve
    her şeyi observability ile görünür kılmak. Aşağıdaki **The DevSecOps Handbook**, sahada öğrendiklerimi
    eylemsel biçimde damıttığım amiral gemim — yanında açık kaynak projelerim.

=== "🇬🇧 English"

    Hi 👋 I'm Halil, a **DevSecOps** engineer. I bake security gates into CI/CD pipelines, build reliable
    platforms on Kubernetes, manage infrastructure as code, and make everything observable. **The
    DevSecOps Handbook** below is my flagship — a distilled, opinionated handbook of what I've learned
    in production, with deep TR/EU regulatory coverage — alongside my open-source projects.

---

<span class="section-eyebrow">Flagship</span>

## :material-book-open-page-variant: The DevSecOps Handbook { #flagship }

Production'da işleyen modern **DevOps · DevSecOps · SRE · Platform Engineering** pratikleri — derin TR/EU regülasyon kapsamıyla. Konferans slaytı değil — **oncall'da işine yarayan referans**.

<div class="hero-stats" markdown>

| | | | | |
|---|---|---|---|---|
| **21** | **125** | **9** | **19** | **70K+** |
| ana bölüm | deep-dive | cheatsheet | template | satır |

</div>

<div class="grid cards" markdown>

-   :material-target:{ .lg .middle } __Eylemsel / Actionable__

    ---

    Her bölüm "ne / nasıl / niye" sırasıyla. Buzzword değil, *bugün* uygulanacak adımlar.

-   :material-shield-lock-outline:{ .lg .middle } __Placeholder güvenli__

    ---

    Gerçek IP/credential yok. `<TARGET_IP>`, `<NAMESPACE>` konvansiyonu — CI'da otomatik enforce.

-   :material-flag-checkered:{ .lg .middle } __2026 stack__

    ---

    CloudNativePG, Karpenter, OpenTofu, Cilium ambient, Gateway API, vLLM. Eskimiş tavsiye yok.

-   :material-flag:{ .lg .middle } __TR-spesifik__

    ---

    KVKK, BDDK, Wazuh, Iyzico stack notları. Sadece İngilizce çeviri değil — yerel mühendislik.

</div>

[:material-rocket-launch: Yol haritasıyla başla](RoadMap/Modern-DevOps-2026.md){ .md-button .md-button--primary }
[:material-bookshelf: Tüm bölümler](#kategoriler){ .md-button }

---

<span class="section-eyebrow">Use cases</span>

## :material-rocket: Hangi sorunla geldin? { #hizli-basla }

<div class="grid cards" markdown>

-   :material-fire:{ .lg .middle } __Yangın söndürüyorum__

    ---

    Production'da bir şey patladı.

    [:octicons-arrow-right-24: Incident Response](11-SRE/Incident-Response.md) · [Cheatsheets](16-Cheatsheets/)

-   :material-package-variant:{ .lg .middle } __Yeni servis kuracağım__

    ---

    Konteyner + K8s + CI/CD.

    [:octicons-arrow-right-24: K8s Production Checklist](05-Kubernetes/Production-Checklist.md)

-   :material-shield-lock:{ .lg .middle } __Güvenlik review geliyor__

    ---

    DevSecOps, hardening, SLSA/SBOM.

    [:octicons-arrow-right-24: DevSecOps Pipeline](08-Security/DevSecOps-Pipeline.md)

-   :material-cash-multiple:{ .lg .middle } __Cloud faturası patladı__

    ---

    Cost allocation, right-sizing, spot.

    [:octicons-arrow-right-24: FinOps başlangıç](12-FinOps/Cloud-Cost-Allocation.md)

-   :material-scale-balance:{ .lg .middle } __KVKK / GDPR / SOC2__

    ---

    Compliance mühendislik kontrolüyle.

    [:octicons-arrow-right-24: KVKK Practical](19-Compliance/KVKK-Practical.md)

-   :material-database:{ .lg .middle } __Postgres prod'a alıyorum__

    ---

    Patroni HA, zero-downtime migration.

    [:octicons-arrow-right-24: Postgres Guide](10-Databases-Production/Postgres-Production-Guide.md)

</div>

---

<span class="section-eyebrow">Knowledge base</span>

## :material-bookshelf: Kategoriler { #kategoriler }

<div class="grid cards" markdown>

-   :material-account-group: __Kültür & İnsan__

    ---

    DORA/SPACE, Team Topologies, blameless postmortem, on-call kültürü.

    [:octicons-arrow-right-24: 00 — Kültür](00-Culture/)

-   :material-source-branch: __Build & Ship__

    ---

    Git/Trunk-based, CI/CD, IaC, Containers, Kubernetes, GitOps.

    [01 — Git](01-Git-Workflow/) · [02 — CI/CD](02-CI-CD/) · [03 — IaC](03-IaC/)

    [04 — Containers](04-Containers/) · [05 — K8s](05-Kubernetes/) · [06 — GitOps](06-GitOps/)

-   :material-eye-outline: __Run & Observe__

    ---

    Observability, Security, Networking, Databases, SRE.

    [07 — Observability](07-Observability/) · [08 — Security](08-Security/) · [09 — Networking](09-Networking/)

    [10 — Databases](10-Databases-Production/) · [11 — SRE](11-SRE/)

-   :material-trending-up: __Modern Trendler__

    ---

    FinOps, Platform Engineering, Sustainability, AI/LLMOps.

    [12 — FinOps](12-FinOps/) · [13 — Platform](13-Platform-Engineering/)

    [14 — Sustainability](14-Sustainability/) · [15 — AI/LLMOps](15-AI-LLMOps/)

-   :material-toolbox: __Hazır Cebinde__

    ---

    9 cheatsheet, 19 production-ready template, kariyer hazırlığı.

    [16 — Cheatsheets](16-Cheatsheets/) · [17 — Templates](17-Templates/) · [18 — Career](18-Career/)

-   :material-scale-balance: __Hukuki & Soft Skills__

    ---

    KVKK · GDPR · ISO 27001 · SOC 2 · oncall sustainability · stakeholder.

    [19 — Compliance](19-Compliance/) · [20 — Soft Skills](20-Soft-Skills/)

</div>

---

<span class="section-eyebrow">Open source · GitHub</span>

## :material-rocket-launch-outline: Projeler

Knowledge base'in yanında, üretim için yazdığım açık kaynak araçlar:

<div class="grid cards projects" markdown>

-   :material-database-cog:{ .lg .middle } __databases-stack__

    ---

    Tek `docker compose up` ile **MariaDB + PostgreSQL + MongoDB + Redis** self-hosted stack: admin paneller, Prometheus exporter'lar, 15 dakikalık backup automation, Google Drive sync.

    [:fontawesome-brands-github: Repo](https://github.com/halilibrahimd27/databases-stack)

-   :material-lock-outline:{ .lg .middle } __file-crypter__

    ---

    **AES-256-CBC + PBKDF2** ile dosya/klasör şifreleme — terminalden tek komut. Hafif, bağımlılıksız.

    [:fontawesome-brands-github: Repo](https://github.com/halilibrahimd27/file-crypter)

-   :material-chart-timeline-variant:{ .lg .middle } __wakapi-admin__

    ---

    Self-hosted **Wakapi** stack + custom admin panel: realtime aktif kullanıcılar, domain tag sistemi, AI editor tespiti.

    [:fontawesome-brands-github: Repo](https://github.com/halilibrahimd27/wakapi-admin)

-   :material-api:{ .lg .middle } __api-sentinel__

    ---

    Üçüncü parti API **schema değişikliği tespiti** — plugin tabanlı, severity-aware monitoring. Breaking change'i sen değil o yakalar.

    [:fontawesome-brands-github: Repo](https://github.com/halilibrahimd27/api-sentinel)

-   :material-shield-search:{ .lg .middle } __cheat-sheet__

    ---

    Offensive security komut referansı — **2000+ pentest komutu**, OSCP/OSWE/OSEP hazırlığı.

    [:fontawesome-brands-github: Repo](https://github.com/halilibrahimd27/cheat-sheet)

-   :material-github:{ .lg .middle } __Daha fazlası__

    ---

    Tüm açık kaynak çalışmalarım GitHub profilimde.

    [:octicons-arrow-right-24: github.com/halilibrahimd27](https://github.com/halilibrahimd27)

</div>

---

<span class="section-eyebrow">Toolbox</span>

## :material-toolbox-outline: Stack & Yetkinlikler

<div class="skill-chips">
<span class="chip">Kubernetes</span>
<span class="chip">Docker</span>
<span class="chip">Helm</span>
<span class="chip">Kustomize</span>
<span class="chip">Terraform</span>
<span class="chip">OpenTofu</span>
<span class="chip">ArgoCD</span>
<span class="chip">Flux</span>
<span class="chip">GitHub Actions</span>
<span class="chip">GitLab CI</span>
<span class="chip">AWS</span>
<span class="chip">Cilium / eBPF</span>
<span class="chip">Gateway API</span>
<span class="chip">Prometheus</span>
<span class="chip">Grafana</span>
<span class="chip">OpenTelemetry</span>
<span class="chip">Loki / Tempo</span>
<span class="chip">PostgreSQL</span>
<span class="chip">Patroni</span>
<span class="chip">Vault / ESO</span>
<span class="chip">Trivy</span>
<span class="chip">Cosign / SLSA</span>
<span class="chip">Kyverno / OPA</span>
<span class="chip">Falco</span>
<span class="chip">Wazuh SIEM</span>
<span class="chip">Ansible</span>
<span class="chip">Python</span>
<span class="chip">Bash</span>
<span class="chip">KVKK / GDPR</span>
<span class="chip">vLLM / RAG</span>
</div>

[:material-account-details: Detaylı bilgi — Hakkımda / About](about.md){ .md-button }

---

<div class="contact-band" markdown>

## :material-email-fast: İletişim · Get in touch

Bir fikir, iş birliği ya da soru mu var? **Çekinme, yaz.** / Got an idea or opportunity? Reach out.

[:material-email: s.ibrahimdrms@gmail.com](mailto:s.ibrahimdrms@gmail.com){ .md-button .md-button--primary }
[:fontawesome-brands-linkedin: LinkedIn](https://www.linkedin.com/in/halilibrahimd){ .md-button }
[:fontawesome-brands-github: GitHub](https://github.com/halilibrahimd27){ .md-button }

</div>

<p class="footer-quote" markdown>
*"Stil 'kişisel zevk' değil, hizmet. Tutarlı yazılan repo, 1000 sayfa olsa bile tek dosya gibi okunur."*

**:material-flag: Made with discipline in Türkiye · 2026**
</p>
