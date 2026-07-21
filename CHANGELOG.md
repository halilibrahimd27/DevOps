# Changelog

Bu repo'daki tüm önemli değişiklikler bu dosyada tutulur.

Format [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) standardına,
sürümleme [Semantic Versioning](https://semver.org/spec/v2.0.0.html) kuralına dayanır.

---

## [Unreleased]

---

## [1.2.1] — 2026-06-28

Portfolyo cilası — site sunumu rafine edildi.

### Değiştirildi
- **Hero tagline'ları** insan sesine çekildi (AI-kokan "X gömen, Y kuran mühendis" +
  buzzword listesi + TR↔EN birebir ayna kaldırıldı); görüşlü/somut bir ifadeyle değiştirildi
- Hero başlığındaki permalink `#` çıpası gizlendi
- Sayfa üstündeki **"Görüntüle" / "Düzenle"** (view source / edit this page) action
  butonları kaldırıldı — tek-yazarlı portfolyo sitesinde gereksiz/dağıtıcı
  (`content.action.view` + `content.action.edit` özellikleri çıkarıldı)
- **CHANGELOG** yayınlanan siteden çıkarıldı (portfolyo nav'ında yersiz); dosya repo'da kalır
- X/Twitter profil linki kaldırıldı (v1.2.0'da başlandı; GitHub · LinkedIn · e-posta kaldı)

---

## [1.2.0] — 2026-06-28

Portfolyo + denetim sürümü. Site kişisel **DevSecOps portfolyosuna** dönüştü;
kapsamlı bir kalite denetimi (P0/P1/P2) uygulandı; editorial anatomi tamamlandı.
Repo cilası (chore/repo-polish) detayları: `AUDIT.md` + `CHANGES-SUMMARY.md`.

### Eklendi
- **Kişisel portfolyo sitesi**: kişi-öncelikli ana sayfa (avatar, "DevSecOps Engineer",
  TR/EN hero, açık kaynak **proje vitrini**, skill chip'leri, iletişim bandı) + çift dil
  (TR/EN) **Hakkımda** sayfası. (`docs/index.md`, `docs/about.md`, `assets/extra.css`)
- **Konu etiketleri** (Material `tags` plugin) + etiket indeks sayfası (`docs/tags.md`)
- **21-Field-Notes/**: dağınık saha-notu klasörleri (System/Network/Ansible/Terraform/
  kubectl) tek bölümde toplandı; kebab-case + geçerli markdown
- **RoadMap/advanced/**: 8568 satırlık tek dosya 14 faz sayfası + index'e bölündü
- **SEO frontmatter**: ~190 içerik dosyasına `description`
- **17-Templates/terraform/** + **17-Templates/gitignore/** template'leri
- Eksik **epigraph / anti-pattern / checklist / referans / kapanış** öğeleri tamamlandı
  → numaralı (non-FieldNotes) deep-dive'larda CLAUDE.md anatomisi ~%100

### Değiştirildi
- **README** profesyonel/reklamsız tona çekildi; sayılar gerçeğe eşlendi
  (deep-dive **125**, template **19**); yazar atfı eklendi
- Profil sosyal linkleri sadeleştirildi: **X/Twitter kaldırıldı** (GitHub · LinkedIn · e-posta kaldı)
- **RoadMap GitOps** bölümü push-based (Jenkins+kubectl) → pull-based (ArgoCD/Flux)
- **15-AI-LLMOps**: model fiyatlarına tarih+kaynak; Claude Opus 4.7 → **4.8**; embedding fiyatı düzeltildi
- **K8s 1.28 → 1.30** sürüm hizalama (Terraform/EKS/CI) + GPG key uyumu + `registry.k8s.io`
- `mkdocs.yml strict`: link bütünlüğü ayrı **lychee** CI job'ında (Pages deploy stabilitesi)

### Düzeltildi
- **Güvenlik/placeholder**: kalan zayıf örnek parolalar → `<PLACEHOLDER>`
  (RoadMap/advanced, Grafana `adminPassword`, proxmox, ingress-nginx secret ref)
- **CI leak-scan** regex'i özel karakter + kısa parola kaçağını kapatacak şekilde sertleştirildi
- **Teknik hatalar**: sahte `ClusterAutoscaler` CRD → gerçek Helm kurulumu; ters Sloth latency
  SLI matematiği; `work_mem` formül/değer uyumu; VPA YAML indent + `spec/targetRef`;
  malformed path; Incident-Response tablo hücresi; kyverno `v2beta1` → `v1`
- **build-docs.sh** Bash 4+ guard; GDPR "Madde" → "Article"; PCI DSS v4.0 deadline güncellendi; Glossary `LLMOps`
- **CI yeşillendirme**: Pages deploy (`strict` ↔ git-revision-date çakışması) + Quality Gate (leak-guard)

Doğrulama: CI **Pages deploy + Quality Gate yeşil**; canlı site `200`; leak-guard 0 hit;
`CI=true mkdocs build` EXIT 0.

---

## [1.1.0] — 2026-05-06

### Düzeltildi
- **CI paths filter**: `pages.yml`'a `assets/**` + `scripts/build-docs.sh` eklendi;
  `quality.yml` paths filtresi kaldırıldı (her push/PR'da çalışır) — site canlıya yansımama sorunu giderildi

---

## [1.0.0] — 2026-05-06

İlk kararlı sürüm. Repo bir yıllık damıtmadan sonra "production-ready"
olarak işaretlendi: 21 ana bölüm, 125+ deep-dive, 65K+ satır Türkçe içerik.

### Eklendi
- **00-Culture** → **20-Soft-Skills** arası 21 numaralı ana bölüm
- 125+ deep-dive doküman (her biri 250-600 satır, anti-pattern + checklist + referanslar)
- **9 cheatsheet**: kubectl · docker · git · helm · terraform · aws-cli · linux-troubleshooting · networking-tools · vim-survival
- **25+ production-ready template**: GitHub Actions, K8s manifest, Dockerfile, Kyverno policy, runbook
- **Compliance kapsamı**: KVKK · GDPR · ISO 27001 · SOC 2 Type II · EU AI Act · NIS2 · PCI DSS v4
- **TR-spesifik içerik**: KVKK pratikleri, BDDK uyumu, Wazuh SIEM entegrasyonu, Iyzico ödeme yığını notları
- **Soft skills**: oncall sürdürülebilirliği, mentoring, stakeholder yönetimi, "hayır" demek, RFC yazımı
- **Modern stack 2026**: CloudNativePG, Karpenter, OpenTofu, Cilium ambient mode, Gateway API, vLLM
- **Glossary**: TR↔EN DevOps terim sözlüğü (300+ giriş)
- **CLAUDE.md**: katkıcılar (insan ve AI) için yazım stili rehberi
- **CI quality gate** (`.github/workflows/quality.yml`):
  - markdownlint (CLAUDE.md stiline esnetilmiş config)
  - lychee link checker
  - placeholder/credential leak guard (AWS, Google, Slack token, private key, public IP)
  - PR'da repo istatistik özeti
- **MkDocs Material site**: <https://halilibrahimd27.github.io/devsecops-handbook/>
  - Tam metin arama (TR + EN)
  - Karanlık/aydınlık tema
  - Mermaid diyagram desteği
  - Mobil uyumlu, SEO meta description'lı

### Repo metadata
- 20 GitHub topic: `devops`, `devsecops`, `sre`, `kubernetes`, `terraform`, `gitops`,
  `cloud-native`, `observability`, `platform-engineering`, `finops`, `helm`, `docker`,
  `ci-cd`, `infrastructure-as-code`, `awesome`, `cheatsheet`, `learning-resources`,
  `site-reliability-engineering`, `turkish`, `handbook`
- MIT lisans
- GitHub Discussions açık
- Issue + PR template'leri (kategori-spesifik)

---

[unreleased]: https://github.com/halilibrahimd27/devsecops-handbook/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/halilibrahimd27/devsecops-handbook/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/halilibrahimd27/devsecops-handbook/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/halilibrahimd27/devsecops-handbook/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/halilibrahimd27/devsecops-handbook/releases/tag/v1.0.0
