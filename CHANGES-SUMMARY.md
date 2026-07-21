# CHANGES-SUMMARY — Repo Cilası (chore/repo-polish)

> Bu belge, `chore/repo-polish` branch'indeki **tüm** değişiklikleri şeffaf
> biçimde listeler. Denetim raporu: [`AUDIT.md`](AUDIT.md).
>
> **İlke:** Hiçbir teknik içerik kaybedilmedi. Taşımalar `git mv` ile yapıldı
> (geçmiş korundu); bölme işlemleri byte-eksiksiz doğrulandı (assertion). Aşağıda
> "açıkça raporlanan silmeler" başlığı altında **yalnızca README pazarlama bloğu**
> kaldırıldı.

**Kapsam:** 8 commit · 200 dosya · +10.316 / −8.784 satır (çoğu taşıma/yeniden-yapı, içerik kaybı değil).

---

## 1. Taşınan / Yeniden Adlandırılan Dosyalar (içerik korundu)

Dağınık saha-notu klasörleri tek bir **`21-Field-Notes/`** bölümünde toplandı; tümü
kebab-case + `.md` uzantısı + geçerli markdown (uzantısız ham script'ler `bash`/`hcl`
code-fence içine alındı, H1 eklendi):

| Eski yol | Yeni yol |
|---|---|
| `Ansible/Ansible System Preperation` | `21-Field-Notes/ansible/system-preparation.md` |
| `Ansible/SSH CONNECTIVITY TEST` | `21-Field-Notes/ansible/ssh-connectivity-test.md` |
| `Network/Network Segmentation and Wazuh SIEM Integration Guide.md` | `21-Field-Notes/network/network-segmentation-wazuh-siem.md` |
| `System/Certified.md` | `21-Field-Notes/system/devops-certification-roadmap.md` |
| `System/EXTERNAL ACCESS PROBLEM` | `21-Field-Notes/system/external-access-solutions.md` |
| `System/Full Production-Ready Repo Layout.md` | `21-Field-Notes/system/production-ready-repo-layout.md` |
| `System/GitHub Actions Pipeline Setup Guide.md` | `21-Field-Notes/system/github-actions-pipeline-setup.md` |
| `System/Inventory Management Example.md` | `21-Field-Notes/system/inventory-management-example.md` |
| `System/Kubernetes Cluster Installation Guide.md` | `21-Field-Notes/system/kubernetes-cluster-installation.md` |
| `Terraform/COMPLETE TERRAFORM CONFIGURATION FOR PROXMOX` | `21-Field-Notes/terraform/proxmox-configuration.md` |
| `Terraform/Manuel Terraform Modules Create VM` | `21-Field-Notes/terraform/modules-create-vm.md` |
| `Kubectl/Logging/Apply.md` | `21-Field-Notes/kubectl/logging-elasticsearch.md` |
| `Kubectl/Password/Pass.md` | `21-Field-Notes/kubectl/cluster-passwords.md` |

**RoadMap** sitenin hero öğrenme-yolu olduğu için top-level bırakıldı:
- `RoadMap/Advanced RoadMap.md` → `RoadMap/advanced-roadmap.md` (index) + **`RoadMap/advanced/00…13-*.md`** (14 faz sayfası). 8568 satır byte-eksiksiz dağıtıldı.

---

## 2. Eklenen İçerik

- **SEO frontmatter** (`description`): 190 içerik dosyası.
- **Anti-pattern tabloları**: 7 dosya (Mobile-CICD-Flutter, Production-Checklist,
  OpenTelemetry-Adoption, Prometheus-Grafana-K8s-Setup, SLI-SLO-Error-Budget,
  Cloud-Cost-Allocation, SRE-Interview-Prep).
- **Production checklist'leri**: 12 dosya (00-Culture'da 4, Terraform-Best-Practices,
  DevSecOps-Pipeline, OpenTelemetry-Adoption, SLI-SLO, Cloud-Cost-Allocation, 18-Career'da 3).
- **Yeni template'ler** (README'nin vaat ettiği ama eksik olanlar):
  `17-Templates/terraform/` (README + main.tf + variables.tf + outputs.tf),
  `17-Templates/gitignore/` (stack başına .gitignore + anti-pattern).
- **Index**: `21-Field-Notes/README.md`.
- **Meta**: `AUDIT.md`, bu `CHANGES-SUMMARY.md`.

---

## 3. Değiştirilen İçerik

- **README.md** — profesyonel/reklamsız tona çekildi (detay §5).
- **mkdocs.yml** — `site_description` sayıları gerçeğe eşlendi; `exclude_docs` bayat
  kayıtları temizlendi (LAUNCH-PLAN.md, taşınan Ansible girdisi, gitignore'lı MARKETING).
- **scripts/build-docs.sh** — 21-Field-Notes + RoadMap/advanced nav'a eklendi;
  kaldırılan eski klasörlerin kopyalama/başlık blokları temizlendi.
- **Placeholder hijyeni**: `cipassword "ubuntu"` → `<CI_PASSWORD>` (18 yer), zayıf
  parola örnekleri → `<...>` (7 yer), `osv-scanner-action@v1.7.0` → `@<VERSION>`.
  - **Düzeltme (denetim sonrası):** İlk geçişte `RoadMap/advanced/`'teki bölünmüş dosyalar
    atlanmıştı. İkinci geçişte 9 zayıf parola daha temizlendi (`AdminPassword123!`,
    `SuperSecurePassword123!`, `SuperSecretPassword123!`, `POSTGRES_PASSWORD=password`,
    `opensearch.password: admin`) → `<GRAFANA_ADMIN_PASSWORD>` / `<DB_PASSWORD>` /
    `<OPENSEARCH_PASSWORD>`. CI leak-scan regex'i de `!`/kısa-parola kaçağını kapatacak
    şekilde düzeltildi (`quality.yml`).
- **CHANGELOG.md** — [Unreleased] bölümü dolduruldu.

---

## 4. 🔴 Açıkça Raporlanan Silmeler

İçerik silme ilkesi gereği — **yalnız README pazarlama bloğu** kaldırıldı (teknik
içerik DEĞİL):

| Kaldırılan | Neden |
|---|---|
| Superlatif konumlandırma başlığı ("en kapsamlı …") | Doğrulanamaz pazarlama iddiası (CLAUDE.md ihlali) |
| "🆚 Diğer Türkçe DevOps Kaynakları ile" rakip-karşılaştırma tablosu | Satışçı ton |
| "⭐ Yıldız bırakırsan…" + "🌟 Repo'yu desteklemek istiyorsan" tablosu | Yıldız-dilenme |
| Star-history grafiği + Awesome rozeti + ~5 fazla shields badge | Badge yağmuru |
| `<details>` SEO keyword-stuffing bloğu (~90 terim) | README'nin kendi "buzzword listesi değil" felsefesiyle çelişiyordu |
| Bayat `exclude_docs: LAUNCH-PLAN.md` | Dosya zaten yoktu |

> Bu kaldırmalar **CLAUDE.md "Yapılması Yasak / Pazarlama Tonu"** kuralının uygulanmasıdır.
> Hiçbir teknik bilgi, kod veya rehber içeriği silinmedi.

---

## 5. README Yeniden Yazımı

- Badge: 8+ → 3 anlamlı (site, license, last-commit; geçersiz `deeppurple` rengi düzeltildi).
- Sayılar gerçeğe eşlendi: **125** deep-dive (125+ değil), **19** template (25+ değil), **~66K** satır.
- "production-tested" → "production senaryolarına göre yazılmış, 21-Field-Notes ile desteklenen" (dürüst çerçeve).
- **Yazar atfı eklendi** (Halil İbrahim Dürmüş).
- Korundu: görev-bazlı Hızlı Başlangıç tablosu, İçindekiler, mimari diyagram, repo felsefesi, yan-repolar.
- 3-mercek **adversarial review** (anayasa/doğruluk/kıdemli) ile denetlendi; bulgular uygulandı.

---

## 6. Doğrulama

| Kontrol | Sonuç |
|---|---|
| `bash scripts/build-docs.sh` (bash 5) | ✅ 193 dosya stage |
| `mkdocs build --strict` | ✅ EXIT 0 — 0 WARNING / 0 ERROR |
| Kırık iç-link taraması | ✅ 0 (docs/index staged false-pozitifleri hariç) |
| CI-parity leak guard (AWS key / public IPv4) | ✅ temiz (203.0.113.x = RFC 5737 doc-range, 8.8.4.4 = Google DNS) |
| Frontmatter bütünlüğü | ✅ 0 eksik / 0 bozuk |
| İçerik-koruma (RoadMap bölme) | ✅ assertion: 8568 satır byte-eksiksiz |

---

## 7. Bilinçli Kapsam-Dışı Bırakılanlar (gerekçeli)

- **Kütle kod-bloğu dil etiketi** (511 fence): markdownlint CI'da zorunlu değil
  (`MD040: false`, markdownlint zaten CI'dan çıkarılmış); çoğu ASCII diyagram/tree/çıktı.
- **Kütle mermaid + çapraz-link**: churn riski; mevcut ASCII diyagramlar + bölüm
  index'leri navigasyonu sağlıyor.
- **Network guide'da 85 RFC-1918 IP**: segmentasyon dersini bozmamak için mangle
  edilmedi; yerine "RFC 1918 örnek" disclaimer notu eklendi.
- **`tags` frontmatter**: tags plugin etkin değil → inert olurdu.
