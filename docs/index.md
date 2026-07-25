---
hide:
  - toc
  - navigation
title: The DevSecOps Handbook — Halil İbrahim Dürmüş
description: >-
  Production'a yönelik modern DevOps · DevSecOps · SRE · Platform Engineering
  pratikleri — derin TR/EU regülasyon kapsamıyla. 21 konu, 125 deep-dive, 70K+
  satır Türkçe içerik. Yazan: Halil İbrahim Dürmüş, DevSecOps Engineer.
---

<div class="dn-hero" markdown>
<div class="dn-hero__inner" markdown>

<span class="dn-hero__eyebrow">DevOps · DevSecOps · SRE · Platform Engineering</span>

# The DevSecOps Handbook

<p class="dn-hero__lead">
Production'da işleyen, yargılı ve eylemsel bir başvuru kitabı — konferans slaytı değil,
on-call'da açıp uygulanan referans. Her bölüm <b>ne → nasıl → niye</b> sırasıyla ilerler;
anti-pattern tablosu ve production checklist ile biter. Türkçe yazıldı, derin TR/EU
regülasyon kapsamıyla.
</p>

<div class="dn-hero__cta" markdown>
[:material-school: Öğrenme Patikası](22-Learning-Path/){ .md-button .md-button--primary }
[:material-map: Yol Haritası 2026](RoadMap/Modern-DevOps-2026.md){ .md-button }
[:material-bookshelf: Tüm konular](#kategoriler){ .md-button }
</div>

<div class="dn-hero__byline">
  <img class="off-glb" src="https://github.com/halilibrahimd27.png" loading="lazy" alt="Halil İbrahim Dürmüş">
  <span><b>Halil İbrahim Dürmüş</b> — DevSecOps Engineer <span class="sep">·</span> <a href="https://github.com/halilibrahimd27">GitHub</a> <span class="sep">·</span> <a href="https://www.linkedin.com/in/halilibrahimd">LinkedIn</a></span>
</div>

</div>
</div>

<div class="dn-stats">
  <div class="stat"><b>21</b><span>ana konu</span></div>
  <div class="stat"><b>125</b><span>deep-dive</span></div>
  <div class="stat"><b>9</b><span>cheatsheet</span></div>
  <div class="stat"><b>19</b><span>template</span></div>
  <div class="stat"><b>70K+</b><span>satır</span></div>
</div>

---

<span class="section-eyebrow">Neden bu handbook</span>

## :material-star-four-points: Farkı ne { #neden }

<div class="grid cards" markdown>

-   :material-target:{ .lg .middle } __Eylemsel__

    ---

    Her bölüm "ne / nasıl / niye" sırasıyla. Buzzword listesi değil, *bugün* uygulanacak adımlar ve çalışan komutlar.

-   :material-shield-lock-outline:{ .lg .middle } __Placeholder güvenli__

    ---

    Gerçek IP/credential yok. `<TARGET_IP>`, `<NAMESPACE>` konvansiyonu — CI'da otomatik enforce edilir.

-   :material-flag-checkered:{ .lg .middle } __2026 stack__

    ---

    CloudNativePG, Karpenter, OpenTofu, Cilium ambient, Gateway API, vLLM. Eskimiş tavsiye yok.

-   :material-flag:{ .lg .middle } __TR-spesifik__

    ---

    KVKK, BDDK, Wazuh, Iyzico stack notları. Sadece İngilizce çeviri değil — yerel mühendislik.

</div>

<div class="dn-feature" markdown>
<div class="dn-feature__body" markdown>

### :material-school: Sıfırdan mı başlıyorsun?

Bir **okuma listesi** değil, **müfredat**: oku → inşa et → doğrula → geçemediysen dön → geçtiysen ilerle. 6 blok, 29 modül, lab + "kırık lab" + sertifika kapıları. Hiçbir adımda "şimdi ne yapayım?" bırakmaz.

[:material-arrow-right: Öğrenme Patikası'na gir](22-Learning-Path/){ .md-button .md-button--primary }
[Nasıl çalışılır](22-Learning-Path/STUDY-METHOD.md){ .md-button }

</div>
</div>

---

<span class="section-eyebrow">Kullanım senaryoları</span>

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

<span class="section-eyebrow">Bilgi tabanı · 21 konu · 125 deep-dive</span>

## :material-bookshelf: Kategoriler { #kategoriler }

<div class="dn-topics" markdown>

<div class="cluster" markdown>

### Kültür & İnsan

<p class="desc">Sürdürülebilir ekip, blameless kültür, on-call sağlığı.</p>

- [**00** Kültür `5`](00-Culture/)
- [**20** Soft Skills `8`](20-Soft-Skills/)

</div>

<div class="cluster" markdown>

### Build & Ship

<p class="desc">Kaynaktan üretime: sürüm, pipeline, altyapı, konteyner, orkestrasyon.</p>

- [**01** Git Workflow `5`](01-Git-Workflow/)
- [**02** CI/CD `7`](02-CI-CD/)
- [**03** IaC `6`](03-IaC/)
- [**04** Containers `6`](04-Containers/)
- [**05** Kubernetes `6`](05-Kubernetes/)
- [**06** GitOps `6`](06-GitOps/)

</div>

<div class="cluster" markdown>

### Run & Observe

<p class="desc">Çalıştır, gör, koru: gözlemlenebilirlik, güvenlik, ağ, veri, SRE.</p>

- [**07** Observability `8`](07-Observability/)
- [**08** Security `9`](08-Security/)
- [**09** Networking `7`](09-Networking/)
- [**10** Databases `8`](10-Databases-Production/)
- [**11** SRE `7`](11-SRE/)

</div>

<div class="cluster" markdown>

### Optimize & Evolve

<p class="desc">Maliyet, platform, sürdürülebilirlik ve AI/LLMOps.</p>

- [**12** FinOps `8`](12-FinOps/)
- [**13** Platform Engineering `5`](13-Platform-Engineering/)
- [**14** Sustainability `5`](14-Sustainability/)
- [**15** AI / LLMOps `7`](15-AI-LLMOps/)

</div>

<div class="cluster" markdown>

### Cebinde Hazır

<p class="desc">Hızlı referans: cheatsheet, kopyala-yapıştır şablon, kariyer.</p>

- [**16** Cheatsheets `9`](16-Cheatsheets/)
- [**17** Templates `19`](17-Templates/)
- [**18** Career `4`](18-Career/)

</div>

<div class="cluster" markdown>

### Hukuk & Saha

<p class="desc">Uyum kontrolleri ve gerçek kurulumlardan ham saha notları.</p>

- [**19** Compliance `8`](19-Compliance/)
- [**21** Field Notes `13`](21-Field-Notes/)

</div>

</div>

---

<span class="section-eyebrow">Yazar</span>

## :material-account: Hakkında

<div class="dn-author" markdown>

![Halil İbrahim Dürmüş](https://github.com/halilibrahimd27.png){ .off-glb loading=lazy }

<div class="dn-author__body" markdown>

### Halil İbrahim Dürmüş

<span class="dn-author__role">DevSecOps Engineer</span>

<p>Güvenliği en sona bırakan pipeline'lara güvenmem. Default config "çalışıyor" demek benim için "henüz kırılmadı" demek — Kubernetes'i de tedarik zincirini de baştan sıkı kurarım, sonradan yamamam. Bu handbook, sahada öğrendiklerimi eylemsel biçimde damıttığım amiral gemim.</p>

<div class="dn-author__links" markdown>
[:material-email: E-posta](mailto:s.ibrahimdrms@gmail.com){ .md-button .md-button--primary }
[:fontawesome-brands-github: GitHub](https://github.com/halilibrahimd27){ .md-button }
[:fontawesome-brands-linkedin: LinkedIn](https://www.linkedin.com/in/halilibrahimd){ .md-button }
[:material-account-details: Detaylı — Hakkımda](about.md){ .md-button }
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

<span class="section-eyebrow">Açık kaynak · GitHub</span>

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

<div class="contact-band" markdown>

## :material-email-fast: İletişim

Bir fikir, iş birliği ya da soru mu var? **Çekinme, yaz.**

[:material-email: s.ibrahimdrms@gmail.com](mailto:s.ibrahimdrms@gmail.com){ .md-button .md-button--primary }
[:fontawesome-brands-linkedin: LinkedIn](https://www.linkedin.com/in/halilibrahimd){ .md-button }
[:fontawesome-brands-github: GitHub](https://github.com/halilibrahimd27){ .md-button }

</div>

<p class="footer-quote" markdown>
*"Stil 'kişisel zevk' değil, hizmet. Tutarlı yazılan repo, 1000 sayfa olsa bile tek dosya gibi okunur."*

**:material-flag: Made with discipline in Türkiye · 2026**
</p>
