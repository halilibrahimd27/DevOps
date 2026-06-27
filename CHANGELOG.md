# Changelog

Bu repo'daki tüm önemli değişiklikler bu dosyada tutulur.

Format [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) standardına,
sürümleme [Semantic Versioning](https://semver.org/spec/v2.0.0.html) kuralına dayanır.

---

## [Unreleased]

### Repo Cilası (chore/repo-polish) — 2026-06

Tam denetim + kalite pası (repo kökünde `AUDIT.md`). İçerik silinmedi; tüm
değişiklikler repo kökündeki `CHANGES-SUMMARY.md`'de.

#### Eklendi
- **21-Field-Notes/** bölümü: dağınık saha-notu klasörleri (System/Network/Ansible/
  Terraform/kubectl) tek bölümde toplandı; her dosya kebab-case + geçerli markdown
- **RoadMap/advanced/**: 8568 satırlık tek dosya 14 faz sayfası + index'e bölündü
- **SEO frontmatter**: 190 içerik dosyasına `description` meta açıklaması
- **17-Templates/terraform/** + **17-Templates/gitignore/**: README'nin vaat ettiği
  ama eksik olan template'ler eklendi
- 7 dosyaya anti-pattern tablosu, 12 dosyaya production checklist (CLAUDE.md anatomi)

#### Değiştirildi
- **README** profesyonel/reklamsız tona çekildi: badge yağmuru → 3 anlamlı badge,
  pazarlama klişeleri + yıldız-dilenme + rakip-tablosu kaldırıldı, yazar atfı eklendi
- Sayılar gerçeğe eşlendi: deep-dive **125** (125+ değil), template **19** (25+ değil),
  satır **~66K**; `mkdocs.yml` site_description da güncellendi

#### Düzeltildi
- Placeholder hijyeni: hardcoded zayıf parolalar (`cipassword "ubuntu"` vb.) →
  `<PLACEHOLDER>`; GitHub Action full-semver pin → `@<VERSION>`
- Kırık iç linkler (Faz 2 bölme artefaktları + pre-existing) düzeltildi
- Yazım hataları: "Preperation" → preparation, "Manuel" → modules
- Bayat `exclude_docs` kayıtları (LAUNCH-PLAN.md) temizlendi

Doğrulama: `mkdocs build --strict` 0 uyarı/hata; kırık-link tarama 0; leak-guard temiz.

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
- **MkDocs Material site**: <https://halilibrahimd27.github.io/DevOps/>
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

[unreleased]: https://github.com/halilibrahimd27/DevOps/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/halilibrahimd27/DevOps/releases/tag/v1.0.0
