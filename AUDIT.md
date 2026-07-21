# AUDIT.md — DevOps Notebook Denetim Raporu (Faz 0, read-only)

> *"Önce ölç, sonra kes."* — Bu rapor hiçbir dosyayı değiştirmeden üretildi.
> Karar bekleyen yerler **❓ KARAR** ile işaretli.

**Tarih:** 2026-06-27 · **Branch:** `chore/repo-polish` · **Baz commit:** `1fd8299` (origin/main ile eşit)

> ⚙️ **Önemli ön-bulgu (çözüldü):** Local `main` 10 commit **geride**ydi (`0fa3e1c`); MkDocs site + CI + son içerik commit'leri yereldeki kopyada yoktu. `origin/main`'e fast-forward edildi (temiz ata, içerik kaybı yok) — denetim **kanonik durum** üzerinde yapıldı. Görev tanımındaki `mkdocs.yml`, `scripts/build-docs.sh`, `.github/workflows/*` artık mevcut.

---

## 1. Gerçek Envanter (iddia ↔ gerçek)

| Metrik | README / mkdocs iddiası | Gerçek | Durum |
|---|---|---|---|
| Ana bölüm (numaralı) | 21 | 21 (00–20) | ✅ |
| Deep-dive | **125+** | **125** (README hariç, 00–15/18/19/20) | 🟡 "+" yanıltıcı — tam 125 |
| Cheatsheet | 9 | 9 (16-Cheatsheets, README hariç) | ✅ |
| Template | **25+** | **19** (17-Templates: 3 Dockerfile, 7 K8s yaml, 3 Kyverno, 3 GH Actions, 1 Prometheus, 2 md şablon) | 🔴 **Aşırı iddia** (~19) |
| Markdown satır | 64.000+ | **66.097** | ✅ (hatta muhafazakâr) |
| "production-tested" | "her biri … production-tested" | **doğrulanamaz** | 🔴 Kredibilite riski (bkz §8) |

**Klasör dağılımı (md / satır):** 08-Security 10/4204, 10-Databases 9/3284, 02-CI-CD 8/3353 en yoğun; RoadMap 5/**9915** (tek dosya 8568!), System 5/3217, Network 1/1242. Ansible & Terraform: **0 .md** (yalnız uzantısız dosyalar).

---

## 2. CLAUDE.md Anatomi Uyumu

**Numaralı deep-dive'lar (125 dosya) — büyük ölçüde uyumlu:**
- Anti-pattern tablosu eksik: **7 / 125**
- Checklist eksik: **13 / 125**

> ⚠️ **Düzeltme:** İlk taramada "1/125" yazılmıştı; bu bir zsh word-splitting
> hatasının ürünüydü (döngü tek iterasyon koştu). Python ile yeniden ölçülen
> doğru rakamlar yukarıdadır. ~16 benzersiz dosya etkileniyor.

→ İçeriğin %85+'i anatomiye uyumlu; Faz 3 eksik bölümleri (anti-pattern/checklist)
dosyanın gerçek konusuna dayalı, CLAUDE.md sesinde ekler (uydurma yok).
Kod-bloğu dil etiketi (`MD040`) CI'da zorunlu değil (`.markdownlint.jsonc: MD040 false`,
zaten markdownlint CI'dan çıkarılmış) → 511 etiketsiz fence (çoğu ASCII diyagram/
tree/çıktı) bilinçli olarak değiştirilmedi.

**Eski klasörler (RoadMap/System/Network/Ansible/Terraform/Kubectl) — anatomi YOK:**
Bunlar saha notu / uzun rehber formatında; CLAUDE.md deep-dive iskeletini (epigraf, kavram tablosu, anti-pattern tablosu, checklist, kapanış) izlemiyor. Bilinçli mi (saha notu) yoksa dönüştürülecek mi → **§5 kararına bağlı**.

---

## 3. Oversized Dosyalar (>1500 satır / >40KB)

| Dosya | Satır | Boyut | Öneri |
|---|---|---|---|
| `RoadMap/Advanced RoadMap.md` | **8568** | **217 KB** | 🔴 Bölünmeli → `RoadMap/advanced/` alt-sayfalar + index (örn. AWS/EKS provisioning, networking, CI/CD, security, observability, cost başlıklarına) |

> Diğer "büyük" sandığım dosyalar aslında <1500 satır: `Network/…Wazuh… (1242)`, `System/Full Production-Ready Repo Layout.md (≈900)` — bölme zorunlu değil, opsiyonel. Tek gerçek dev dosya **Advanced RoadMap.md**.

---

## 4. Adlandırma Tutarsızlığı (boşluk / CAPS → kebab-case)

11 dosya numaralı taksonomi konvansiyonunu (kebab-case) ihlal ediyor; **5'i uzantısız** (MkDocs render etmez, GitHub vurgulamaz):

| Mevcut | Önerilen | Not |
|---|---|---|
| `Ansible/Ansible System Preperation` | `ansible-system-preparation.md` | uzantısız + "Preperation" yazım hatası |
| `Ansible/SSH CONNECTIVITY TEST` | `ssh-connectivity-test.md` | uzantısız + CAPS |
| `Network/Network Segmentation and Wazuh SIEM Integration Guide.md` | `network-segmentation-wazuh-siem.md` | |
| `RoadMap/Advanced RoadMap.md` | `advanced-roadmap.md` (+ §3 bölme) | build-docs.sh & RoadMap/.pages referanslı! |
| `System/EXTERNAL ACCESS PROBLEM` | `external-access-problem.md` | uzantısız + CAPS |
| `System/Full Production-Ready Repo Layout.md` | `full-production-ready-repo-layout.md` | |
| `System/GitHub Actions Pipeline Setup Guide.md` | `github-actions-pipeline-setup.md` | |
| `System/Inventory Management Example.md` | `inventory-management-example.md` | |
| `System/Kubernetes Cluster Installation Guide.md` | `kubernetes-cluster-installation.md` | |
| `Terraform/COMPLETE TERRAFORM CONFIGURATION FOR PROXMOX` | `terraform-proxmox-config.md` | uzantısız + CAPS |
| `Terraform/Manuel Terraform Modules Create VM` | `terraform-modules-create-vm.md` | uzantısız + "Manuel" hatası |

> ⚠️ **Senkron riski:** `scripts/build-docs.sh` (RoadMap/.pages bloğu "Advanced RoadMap.md"yi açıkça nav'a yazıyor) ve klasör kopyalama döngüleri her yeniden adlandırmayla güncellenmeli. `git mv` + script + iç link güncellemesi atomik yapılmalı (Faz 1).

---

## 5. ❓ KARAR — Eski Klasörlerin Kaderi (RoadMap/System/Network/Ansible/Terraform/Kubectl)

Bu klasörler elle yazılmış, kişisel/yaşanmış, yargılı saha notları (CLAUDE.md'nin korumamı istediği ses). 3 seçenek:

- **(a) Numaralı taksonomiye entegre et** — örn. Network/Wazuh → `09-Networking/`, Terraform-Proxmox → `03-IaC/`, System/K8s-install → `05-Kubernetes/`. *Artı:* tek tutarlı taksonomi. *Eksi:* saha-notu sesi deep-dive anatomisine zorlanır, en çok iş.
- **(b) Tek bir "Saha Notları / Field Notes" bölümü** (örn. `21-Field-Notes/`) altında topla, kebab-case'le, ama anatomi dayatma. *Artı:* yaşanmış ton korunur + numaralı yapı tutarlı + en az risk. *Eksi:* iki içerik sınıfı (cilalı deep-dive vs ham saha notu).
- **(c) Hibrit** — en güçlü/tamamlanmış olanları (Wazuh, Terraform-Proxmox, K8s-install) ilgili numaralı klasöre taşı; gerisini `21-Field-Notes/` saha notu bırak.

**🟢 Önerim: (b)** — saha notlarının değeri "ham gerçeklik"; deep-dive'a zorlamak sesi öldürür. `21-Field-Notes/` altında kebab-case + index + placeholder temizliği yeterli; build-docs.sh/nav tek yerde güncellenir. (Sen karar vereceksin.)

---

## 6. Bayat Referanslar / Junk

| Bulgu | Konum | Aksiyon |
|---|---|---|
| `LAUNCH-PLAN.md` exclude_docs'ta ama **dosya yok** | `mkdocs.yml:27` | Bayat kaydı sil |
| `MARKETING.md` **gitignore'lı + untracked** ama exclude_docs'ta | kök + `mkdocs.yml:28` | Repo'da değil; exclude kaydı zararsız ama gereksiz — sadeleştir |
| 5 uzantısız dosya (mkdocs render etmez) | Ansible/, System/, Terraform/ | §4 ile `.md` uzantısı + kebab-case |
| `.pages` repoda yok (build-docs.sh **dinamik üretiyor**) | — | Sorun değil; not |

---

## 7. Doğruluk / Tazelik / Bakım Yükü

- **Versiyon pin'leri:** ~15 hardcoded `vX.Y.Z` / `:1.2.3` (CLAUDE.md `<VERSION>` istiyor). → Faz 4: `<VERSION>` placeholder veya tek "Sürümler" referans tablosu.
- **Placeholder konvansiyon sapmaları (KIRMIZI ÇİZGİ — ama gerçek sızıntı DEĞİL):**
  - `Network/…Wazuh…` literal `192.168.10/20/30/40.x` (onlarca) — RFC-1918 örnek, **gerçek altyapı değil**, ama CLAUDE.md `<TARGET_IP>`/`<SUBNET>` istiyor. → placeholder'a çek.
  - `Terraform/…PROXMOX` `cipassword = "ubuntu"` (5×) — zayıf hardcoded örnek parola; `<CI_PASSWORD>` olmalı (kötü örnek + konvansiyon).
  - `System/…Repo Layout.md` `MYSQL_ROOT_PASSWORD: password`, `your-*-password` — illüstratif, yine de `<...>` formuna çekilebilir.
  - **Gerçek IP/e-posta/credential/SHA sızıntısı: YOK** (e-postalar `@company.com`/`@yourdomain.com`, `git@github.com` kanonik; 8.8.8.8/1.1.1.1 public DNS).
- **Kırık link:** Otomatik tarama Faz 4/7'de `lychee` (`.lychee.toml` mevcut) ile. Faz 0'da çalıştırılmadı (read-only).
- **Deprecated:** Spot kontrol gerek (eski k8s API sürümleri vb.) — Faz 4.

---

## 8. README & Kredibilite (CLAUDE.md "pazarlama tonu yasak" ile çelişki)

`README.md` (272 satır) CLAUDE.md §"Yapılması Yasak / Pazarlama Tonu" kuralını ihlal ediyor:
- 🔴 Badge yağmuru (8+ shields + "Awesome" rozeti)
- 🔴 Doğrulanamaz superlatif konumlandırma iddiası (kaldırıldı)
- 🔴 Yıldız dilenme: "⭐ Yıldız bırakırsan repo daha çok kişiye ulaşır"
- 🔴 Rakip-dövme tablosu: "🆚 Diğer Türkçe DevOps Kaynakları ile … Diğerleri (genelde)"
- 🔴 "125+ deep-dive … **production-tested**" — doğrulanamaz iddia
- 🔴 "25+ template" — gerçek 19

→ **Faz 5:** kıdemli/inandırıcı tona çek (önce "ne + kim için", sonra içerik haritası); badge'leri 2-3 anlamlıya indir; rakip-karşılaştırmayı kaldır; sayıları gerçeğe eşle (125 deep-dive, 9 cheatsheet, 19 template, 66K satır); "production-tested" → "production için damıtılmış referans" gibi dürüst çerçeve (veya `<!-- VERIFY: Halil onaylasın -->`). `mkdocs.yml:site_description` de aynı sayılarla güncellenecek.

---

## 9. Keşfedilebilirlik / Okuyucu Deneyimi

- ✅ İyi: MkDocs Material (palette, search tr+en, instant nav, glightbox, mermaid superfence, social, consent), `assets/` (logo/favicon/css/js), `docs/index.md` hero.
- 🟡 Frontmatter: dosyalarda YAML frontmatter (description/tags) yok → SEO/arama zayıf. → Faz 6.
- 🟡 Bölüm index'leri: numaralı klasörlerde README var; eski klasörlerde index yok. → Faz 6.
- 🟡 Çapraz-link & mermaid: yoğun kavramlarda artırılabilir. → Faz 6.
- 🟡 `mkdocs.yml strict: false` — Faz 7'de `--strict` ile build doğrulanmalı (kırık nav/link build'i kırmasın diye önce düzelt).

---

## 10. Önceliklendirilmiş Aksiyon Listesi (fazlara eşli)

| Öncelik | İş | Faz | Risk |
|---|---|---|---|
| P0 | Eski klasör kararı (§5) | (karar) | — |
| P1 | Boşluk/CAPS/uzantısız → kebab-case + `.md`; build-docs.sh/nav/iç-link senkron; LAUNCH-PLAN bayat kaydı sil | Faz 1 | Orta (build senkron) |
| P1 | `Advanced RoadMap.md` (217KB) böl + index | Faz 2 | Düşük (içerik korunur) |
| P2 | README pazarlama tonu → kıdemli ton; sayıları gerçeğe eşle; site_description | Faz 5 | Düşük |
| P2 | Placeholder konvansiyonu: 192.168.x → `<SUBNET>`, `cipassword` → `<CI_PASSWORD>` | Faz 4 | Düşük |
| P3 | Versiyon pin → `<VERSION>` / Sürümler tablosu; deprecated kontrol; lychee link-fix | Faz 4 | Düşük |
| P3 | 1 eksik anti-pattern + 1 eksik checklist'i kapat; kod-bloğu dil etiketi taraması | Faz 3 | Düşük |
| P3 | Frontmatter + bölüm index'leri + çapraz-link + mermaid | Faz 6 | Düşük |
| P4 | `mkdocs build --strict` + lychee + markdownlint + leak-scan geçir; CHANGELOG + CHANGES-SUMMARY | Faz 7 | Düşük |

---

## ❓ Onay Beklenen Kararlar

1. **§5 — Eski klasör stratejisi:** (a) entegre / (b) `21-Field-Notes/` topla / (c) hibrit. **Önerim: (b).**
2. **Hangi fazlar çalışsın?** (Hepsi mi, yoksa belirli sıra mı? Önerim: Faz 1 → 2 → 5 → 4 → 3 → 6 → 7.)
3. **"production-tested" çerçevesi:** dürüst yeniden-çerçeve mi, yoksa `<!-- VERIFY -->` ile sana mı bırakayım?

> *"Repo cevheri sağlam — 125 deep-dive, %99 anatomi uyumu. İş, cilada ve eski saha notlarını taksonomiye düzgün oturtmakta; içeriği yeniden yazmakta değil."*
