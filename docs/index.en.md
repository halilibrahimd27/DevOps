---
hide:
  - toc
  - navigation
title: The DevSecOps Handbook — Halil İbrahim Dürmüş
description: >-
  Production-focused modern DevOps · DevSecOps · SRE · Platform Engineering
  practices — with deep TR/EU regulatory coverage. 21 topics, 125 deep-dives,
  70K+ lines. By Halil İbrahim Dürmüş, DevSecOps Engineer.
---

<div class="dn-hero" markdown>
<div class="dn-hero__inner" markdown>

<span class="dn-hero__eyebrow">DevOps · DevSecOps · SRE · Platform Engineering</span>

# The DevSecOps Handbook

<p class="dn-hero__lead">
An opinionated, actionable reference that works in production — not a conference slide
deck, but a reference that earns its keep on-call. Every section runs
<b>what → how → why</b>, and ends with an anti-pattern table and a production checklist.
Written in Turkish, with deep TR/EU regulatory coverage.
</p>

<div class="dn-hero__cta" markdown>
[:material-school: Learning Path](22-Learning-Path/){ .md-button .md-button--primary }
[:material-map: Roadmap 2026](RoadMap/Modern-DevOps-2026.md){ .md-button }
[:material-bookshelf: All topics](#kategoriler){ .md-button }
</div>

<div class="dn-hero__byline">
  <img class="off-glb" src="https://github.com/halilibrahimd27.png" loading="lazy" alt="Halil İbrahim Dürmüş">
  <span><b>Halil İbrahim Dürmüş</b> — DevSecOps Engineer <span class="sep">·</span> <a href="https://github.com/halilibrahimd27">GitHub</a> <span class="sep">·</span> <a href="https://www.linkedin.com/in/halilibrahimd">LinkedIn</a></span>
</div>

</div>
</div>

<div class="dn-stats">
  <div class="stat"><b>21</b><span>topics</span></div>
  <div class="stat"><b>125</b><span>deep-dives</span></div>
  <div class="stat"><b>9</b><span>cheatsheets</span></div>
  <div class="stat"><b>19</b><span>templates</span></div>
  <div class="stat"><b>70K+</b><span>lines</span></div>
</div>

---

<span class="section-eyebrow">Why this handbook</span>

## :material-star-four-points: What makes it different { #neden }

<div class="grid cards" markdown>

-   :material-target:{ .lg .middle } __Actionable__

    ---

    Every section follows "what / how / why". Not a buzzword list — steps you can apply *today* and commands that run.

-   :material-shield-lock-outline:{ .lg .middle } __Placeholder-safe__

    ---

    No real IPs/credentials. The `<TARGET_IP>`, `<NAMESPACE>` convention — enforced automatically in CI.

-   :material-flag-checkered:{ .lg .middle } __2026 stack__

    ---

    CloudNativePG, Karpenter, OpenTofu, Cilium ambient, Gateway API, vLLM. No stale advice.

-   :material-flag:{ .lg .middle } __TR-specific__

    ---

    KVKK, BDDK, Wazuh, Iyzico stack notes. Not just an English translation — local engineering.

</div>

<div class="dn-feature" markdown>
<div class="dn-feature__body" markdown>

### :material-school: Starting from scratch?

Not a **reading list** but a **curriculum**: read → build → verify → go back if you fail → move on if you pass. 6 blocks, 29 modules, labs + "broken labs" + certification gates. It never leaves you asking "what now?".

[:material-arrow-right: Enter the Learning Path](22-Learning-Path/){ .md-button .md-button--primary }
[Study method](22-Learning-Path/STUDY-METHOD.md){ .md-button }

</div>
</div>

---

<span class="section-eyebrow">Use cases</span>

## :material-rocket: What brought you here? { #hizli-basla }

<div class="grid cards" markdown>

-   :material-fire:{ .lg .middle } __Firefighting__

    ---

    Something blew up in production.

    [:octicons-arrow-right-24: Incident Response](11-SRE/Incident-Response.md) · [Cheatsheets](16-Cheatsheets/)

-   :material-package-variant:{ .lg .middle } __Standing up a new service__

    ---

    Containers + K8s + CI/CD.

    [:octicons-arrow-right-24: K8s Production Checklist](05-Kubernetes/Production-Checklist.md)

-   :material-shield-lock:{ .lg .middle } __Security review incoming__

    ---

    DevSecOps, hardening, SLSA/SBOM.

    [:octicons-arrow-right-24: DevSecOps Pipeline](08-Security/DevSecOps-Pipeline.md)

-   :material-cash-multiple:{ .lg .middle } __Cloud bill exploded__

    ---

    Cost allocation, right-sizing, spot.

    [:octicons-arrow-right-24: FinOps starter](12-FinOps/Cloud-Cost-Allocation.md)

-   :material-scale-balance:{ .lg .middle } __KVKK / GDPR / SOC2__

    ---

    Compliance via engineering controls.

    [:octicons-arrow-right-24: KVKK Practical](19-Compliance/KVKK-Practical.md)

-   :material-database:{ .lg .middle } __Taking Postgres to prod__

    ---

    Patroni HA, zero-downtime migration.

    [:octicons-arrow-right-24: Postgres Guide](10-Databases-Production/Postgres-Production-Guide.md)

</div>

---

<span class="section-eyebrow">Knowledge base · 21 topics · 125 deep-dives</span>

## :material-bookshelf: Categories { #kategoriler }

<div class="dn-topics" markdown>

<div class="cluster" markdown>

### Culture & People

<p class="desc">Sustainable teams, blameless culture, on-call health.</p>

- [**00** Culture `5`](00-Culture/)
- [**20** Soft Skills `8`](20-Soft-Skills/)

</div>

<div class="cluster" markdown>

### Build & Ship

<p class="desc">From source to production: version, pipeline, infra, containers, orchestration.</p>

- [**01** Git Workflow `5`](01-Git-Workflow/)
- [**02** CI/CD `7`](02-CI-CD/)
- [**03** IaC `6`](03-IaC/)
- [**04** Containers `6`](04-Containers/)
- [**05** Kubernetes `6`](05-Kubernetes/)
- [**06** GitOps `6`](06-GitOps/)

</div>

<div class="cluster" markdown>

### Run & Observe

<p class="desc">Run, see, protect: observability, security, networking, data, SRE.</p>

- [**07** Observability `8`](07-Observability/)
- [**08** Security `9`](08-Security/)
- [**09** Networking `7`](09-Networking/)
- [**10** Databases `8`](10-Databases-Production/)
- [**11** SRE `7`](11-SRE/)

</div>

<div class="cluster" markdown>

### Optimize & Evolve

<p class="desc">Cost, platform, sustainability and AI/LLMOps.</p>

- [**12** FinOps `8`](12-FinOps/)
- [**13** Platform Engineering `5`](13-Platform-Engineering/)
- [**14** Sustainability `5`](14-Sustainability/)
- [**15** AI / LLMOps `7`](15-AI-LLMOps/)

</div>

<div class="cluster" markdown>

### In Your Back Pocket

<p class="desc">Quick reference: cheatsheets, copy-paste templates, career.</p>

- [**16** Cheatsheets `9`](16-Cheatsheets/)
- [**17** Templates `19`](17-Templates/)
- [**18** Career `4`](18-Career/)

</div>

<div class="cluster" markdown>

### Legal & Field

<p class="desc">Compliance controls and raw field notes from real deployments.</p>

- [**19** Compliance `8`](19-Compliance/)
- [**21** Field Notes `13`](21-Field-Notes/)

</div>

</div>

---

<span class="section-eyebrow">Author</span>

## :material-account: About

<div class="dn-author" markdown>

![Halil İbrahim Dürmüş](https://github.com/halilibrahimd27.png){ .off-glb loading=lazy }

<div class="dn-author__body" markdown>

### Halil İbrahim Dürmüş

<span class="dn-author__role">DevSecOps Engineer</span>

<p>I don't trust pipelines that leave security for last. A default config that "works" means "not broken yet" to me — I build both Kubernetes and the supply chain tight from day one, I don't patch them later. This handbook is my flagship, distilling what I've learned in production into something actionable.</p>

<div class="dn-author__links" markdown>
[:material-email: Email](mailto:s.ibrahimdrms@gmail.com){ .md-button .md-button--primary }
[:fontawesome-brands-github: GitHub](https://github.com/halilibrahimd27){ .md-button }
[:fontawesome-brands-linkedin: LinkedIn](https://www.linkedin.com/in/halilibrahimd){ .md-button }
[:material-account-details: More — About](about.md){ .md-button }
</div>

</div>
</div>

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

---

<span class="section-eyebrow">Open source · GitHub</span>

## :material-rocket-launch-outline: Projects

Alongside the knowledge base, open-source tools I've written for production:

<div class="grid cards projects" markdown>

-   :material-database-cog:{ .lg .middle } __databases-stack__

    ---

    A self-hosted **MariaDB + PostgreSQL + MongoDB + Redis** stack with a single `docker compose up`: admin panels, Prometheus exporters, 15-minute backup automation, Google Drive sync.

    [:fontawesome-brands-github: Repo](https://github.com/halilibrahimd27/databases-stack)

-   :material-lock-outline:{ .lg .middle } __file-crypter__

    ---

    File/folder encryption with **AES-256-CBC + PBKDF2** — a single command from the terminal. Lightweight, no dependencies.

    [:fontawesome-brands-github: Repo](https://github.com/halilibrahimd27/file-crypter)

-   :material-chart-timeline-variant:{ .lg .middle } __wakapi-admin__

    ---

    Self-hosted **Wakapi** stack + custom admin panel: real-time active users, domain tag system, AI editor detection.

    [:fontawesome-brands-github: Repo](https://github.com/halilibrahimd27/wakapi-admin)

-   :material-api:{ .lg .middle } __api-sentinel__

    ---

    **Schema-change detection** for third-party APIs — plugin-based, severity-aware monitoring. It catches breaking changes before you do.

    [:fontawesome-brands-github: Repo](https://github.com/halilibrahimd27/api-sentinel)

-   :material-shield-search:{ .lg .middle } __cheat-sheet__

    ---

    Offensive security command reference — **2000+ pentest commands**, OSCP/OSWE/OSEP prep.

    [:fontawesome-brands-github: Repo](https://github.com/halilibrahimd27/cheat-sheet)

-   :material-github:{ .lg .middle } __More__

    ---

    All my open-source work lives on my GitHub profile.

    [:octicons-arrow-right-24: github.com/halilibrahimd27](https://github.com/halilibrahimd27)

</div>

---

<div class="contact-band" markdown>

## :material-email-fast: Get in touch

Got an idea, a collaboration, or a question? **Don't be shy — reach out.**

[:material-email: s.ibrahimdrms@gmail.com](mailto:s.ibrahimdrms@gmail.com){ .md-button .md-button--primary }
[:fontawesome-brands-linkedin: LinkedIn](https://www.linkedin.com/in/halilibrahimd){ .md-button }
[:fontawesome-brands-github: GitHub](https://github.com/halilibrahimd27){ .md-button }

</div>

<p class="footer-quote" markdown>
*"Style is not personal taste — it's a service. A consistently written repo reads like a single file even at 1,000 pages."*

**:material-flag: Made with discipline in Türkiye · 2026**
</p>
