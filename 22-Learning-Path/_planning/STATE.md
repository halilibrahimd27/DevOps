# STATE — Öğrenme Patikası İnşası

**Son güncelleme:** 2026-07-22 · **Son commit:** (bu commit) Faz 2 tamam — Blok A+B içerik (TR)

## Faz durumu

| Faz | Ad | Durum | Not |
|---|---|---|---|
| -1 | Zemin: rebrand + i18n + P0 | ✅ | Tamamlandı: infra + rebrand(in-repo) + konumlandırma + i18n zemini + P0-1..7 |
| 0 | Keşif ve haritalama | ✅ | `GAP-MAP.md` + `MODULE-SPEC.md`. **ONAY ALINDI** — 9 revizyon uygulandı |
| 1 | İskelet | ✅ | 8 rehber + 29 modül iskeleti + 3 capstone. QA exit 0 |
| 2 | Blok A + B (içerik) | ✅ | **Tamam.** A1–A6 + B1–B3 (9 modül) TR içerik, hepsi >300s, QA exit 0 (0 uyarı) |
| 3 | Blok C + D | ⬜ | **SIRADA.** C0(Python)·C1(container)·C2(CI)·C3(Terraform)·C4(bulut+bütçe) + D1–D5 |
| 4 | Blok E | ⬜ | |
| 5 | Lab'ların tamamlanması | ⬜ | |
| 6 | Değerlendirme | ⬜ | STAGE-EXAM, PLACEMENT kontrol testleri, capstone rubrikleri |
| 6.5 | Sertifika katmanı | ⬜ | G3'te F2→CKS bağımlılığı burada çözülecek (revizyon 7) |
| 7 | Blok F + kariyer köprüsü | ⬜ | PORTFOLIO.md + F egzersizleri (revizyon 9) |
| 8 | Entegrasyon | ⬜ | 22 nav başlığı + geri-linkler. (Not: `2[0-9]-*` globu 22'yi zaten stage ediyor; `_planning` `exclude_docs`'ta) |
| 9 | Düşmanca gözden geçirme | ⬜ | TROUBLESHOOTING.md 40+ madde burada dolar |

## Sıradaki adım

**Faz 3'e başla — Blok C + D içerik.** Faz 2 (A1–A6 + B1–B3) tamamen bitti, QA exit 0.
Faz 3 modül iskeletleri hazır (`block-c-reproducibility/`, `block-d-orchestration/`),
TODO gövdeleri dolacak. Yazım sırası (ön koşul zinciri):
**C0(ops-python) → C1(container) → C2(ci) → C3(terraform) → C4(bulut+bütçe alarmı) →
D1(k8s-temel) → D2(k8s-production) → D3(secret) → D4(supply-chain) → D5(gitops).**

> ⚠️ **Faz 3 ≠ Faz 2 deseni.** Blok C/D **sıralayıcı** modüllerdir (🟢), 🔴 EKSİK değil.
> Kısıt #1 gereği yeni açıklayıcı içerik **minimum**; gövde ağırlıkla **"Önce oku"** →
> mevcut deep-dive linki + 5–15 satırlık köprü. qa.py sıralayıcı modül >220 satırsa
> "deep-dive tekrarı olabilir" UYARISI verir → **kısa tut** (A/B'deki 300+ satır hedefi
> C/D için GEÇERLİ DEĞİL). Her modülün "Önce oku" tablosunda **en az bir mevcut repo
> dosyası** olmalı (Faz 3 çıktı kapısı). Kaynak eşlemesi: `_planning/MODULE-SPEC.md`.

> 🧵 **Güvenlik ipliği — Faz 3 çıktı kapısı:** **D1 RBAC + NetworkPolicy içerir** (ilk
> günden, ayrı ders değil). **D4 ayrı güvenlik dersi DEĞİL** — C2'de kurulan CI
> pipeline'ının devamı (image tarama + imzalama pipeline adımı olarak). D2/D3 güvenlik
> kontrolü içeride (probe/limit/PDB güvenlik değil ama secret D3 içeride).

> ⚠️ Faz 3 muhtemelen tek tura sığmaz (§14.1.3). Sığmazsa: nereye kadar geldiğini
> **modül adı seviyesinde** buraya yaz (ör. "C0–C2 yazıldı, C3'ten devam"), commit, dur.
> Lab/kırık-lab dizinleri (K02+ dahil) Faz 5'te doğar; modülde kod-span referans yeter.

## Açık kararlar

### Faz 2'de alınanlar
- **⚠️ EN twin'ler ertelendi — `qa.py` çakışması, İLERİDE KULLANICI MÜDAHALESİ GEREKİR.**
  §7 "iki dil birlikte" kuralı + Faz 1 kararı EN twin öngörüyordu. ANCAK `qa.py`
  (değiştiremediğim dış denetçi) `^[A-F]\d+-` eşleşen **her** dosyada Türkçe bölüm
  başlıklarını (`🎯`, `Kabul kriterleri`, `Sırada`) zorunlu tutar (`qa.py:175`).
  `A1-…en.md` twin'i bu regex'e uyar → İngilizce başlıkla QA **kırılır**; Türkçe
  başlık koyup "İngilizce" demek **kandırma** olur (§15.4 yasak). Repoda 0 adet
  `.en.md` var (Faz -1'den beri). Karar: bu tur **TR içerik** yazıldı (asıl öğretici
  teslimat, QA exit 0); EN twin katmanı ayrı bir i18n turu (P1). Bunun için önce
  **kullanıcı `qa.py`'yi `.en.md` locale dosyalarını modül denetiminden ayırt edecek
  şekilde genişletmeli** (ben `qa.py`'ye dokunamam, §15.4). Sessiz kısıtlama değil,
  görünür eskalasyon. `I18N-COVERAGE.md` P1 durumu bunu yansıtacak.
- **build-docs.sh Bash 3.2 uyumlu yapıldı (taşınabilirlik).** Güncel `qa.py` mkdocs'u
  `python3 -m mkdocs` ile buluyor → `check_build` artık gerçekten çalışıyor. `build-docs.sh`
  `declare -A` (Bash 4+) yüzünden macOS varsayılan Bash 3.2'de patlıyordu (check_build
  ERROR). İki `declare -A` haritası (`TITLES`, `FN_TITLES`) `"anahtar|değer"` indeksli
  diziye çevrildi, Bash-4 guard'ı kaldırıldı. Davranış Bash 4+/CI'da aynı; yerelde artık
  **"Site hatasız derlendi"**. Gerçek build'i çalıştıran düzeltme, QA'yı kandırma değil.
- **A3 örnek IP'leri belge bloğuna çevrildi.** `example.com`'un gerçek IP'si sızmıştı
  → `192.0.2.10` (RFC 5737) + `2001:db8::10` (RFC 3849). `example.com` (RFC 2606 rezerve
  isim) kaldı — placeholder güvenliği korundu (qa leak guard temiz).
- **Modül derinliği revizyon 1 hedefine çekildi.** qa.py 🔴 EKSİK modüller için ~400–700
  satır derinlik denetliyor; ilk taslak (244–335) "ders yeterince derin mi?" uyarısı aldı →
  dördü de **gerçek beginner içerikle** derinleştirildi (A1: stdio/redirect/`PATH`;
  A2: subnet bit-math/NAT/DHCP/ARP + uçtan-uca teşhis; A3: çözümleme zinciri/HTTP
  metod+cookie/TLS el sıkışma; A4: restore/reset/revert/stash/reflog/`.gitignore`).
  **A1–A4: 379/314/316/314 satır** → QA **0 uyarı**.
- **B1–B3 derinlik uyarısı kapatıldı (bu tur), içerik özgün.** Önceki "ara kayıt"
  commit'i (c87c867) A5–B3 gövdelerini yazmış ama STATE'i güncellememişti; B1/B2/B3
  (281/240/231s) qa.py'nin `<300s` "ders yeterince derin mi?" UYARISI'nı tetikliyordu.
  Bu tur üçü de **kısıt #1'i ihlal etmeden** derinleştirildi (357/303/306s, QA 0 uyarı):
  B1'e journalctl derinliği (çıktı biçimi/alan süzgeci/`-b -1`/kalıcı journal/rate-limit) —
  `Logs-Loki-vs-ELK.md`'de yok; B3'e uçtan-uca **DNS** teşhis yürüyüşü (K01 gizli
  sebep setiyle *kasıtlı* örtüşmez) + zaman kutusu/eskalasyon disiplini. **B2 kasıtlı
  kısa/devir:** eklenen içerik `Prometheus-Best-Practices.md`'nin varsaydığı ama
  öğretmediği beginner iskelesi (anlık↔aralık vektör, scrape yaşam döngüsü + meta-metrik,
  `scrape_interval` ödünleşimi) — deep-dive tekrarı DEĞİL (naming/cardinality/histogram/
  recording-rules deep-dive'da kaldı). Üç özgün cümle repoda `grep` ile aranıp
  **bulunmadı**.

### Önceki fazlardan taşınanlar (hâlâ geçerli)
- **i18n Aşama A:** TR varsayılan (kök), EN `/en/` fallback ile kısmi → boş/kırık EN
  sayfa yok. **Aşama B** (EN varsayılan): EN kapsama ≥ %60 olunca; şimdi değil.
- **9 onay revizyonu (Faz 0/1):** 200-satır tavanı yalnız 🟢; C0 (Python) A5'ten ayrı;
  A4/D1 🔴; süreler A97·B36·C88·D84·E64·F48+capstone60=~477s; K00 (A6) + K02 zorunlu;
  G3 CKS↔F2 Faz 6.5'e ertelendi; CAP1–3 eklendi; F1/F4 teslim egzersizleri işaretli.
- **Lab'lar kod-span olarak referanslı** (markdown link değil) — dizinler Faz 5'te doğar;
  "Önce oku"da yalnız **var olan** deep-dive'lara link.
- **GitHub-side rebrand elle yapılacak (gh CLI yok):** repo rename `DevOps`→`devsecops-handbook`,
  `description`+`topics`. **Custom domain verilmedi** → `site_url` fallback
  `https://halilibrahimd27.github.io/devsecops-handbook/`. Repo rename main'e merge ÖNCE.

## Bu oturumda yapılanlar (Faz 2'yi TAMAMLADI — Blok B derinleştirme)

Bu tur girişte durum: A5–B3 gövdeleri önceki "ara kayıt" (c87c867) ile yazılmış ama
Faz 2 kapatılmamış, B1/B2/B3 qa.py derinlik UYARISI veriyordu. Bu tur **Faz 2'yi kapattı**:

- **B1 log-okuma** 281→**357s**: `## 🔟 journalctl derinliği` (çıktı biçimi `-o json/cat`,
  alan süzgeci `_PID=`/`_UID=`/`PRIORITY=`, `-b`/`-b -1`/`-k` önyükleme+çekirdek) +
  `## 1️⃣1️⃣ kalıcı vs geçici journal` (`/var/log/journal`, `--list-boots`, rate-limit
  `Suppressed N messages`). +2 anti-pattern satırı. `Logs-Loki-vs-ELK.md` bunu içermez.
- **B2 metrik** 240→**303s** (kasıtlı kısa/devir): `## 8️⃣ anlık↔aralık vektör` (`[5m]`
  ne demek, counter→`rate()`), `## 9️⃣ scrape yaşam döngüsü + meta-metrik` (`up`/
  `scrape_duration_seconds`/`scrape_samples_scraped`, disk% worked query, staleness,
  `scrape_interval` ödünleşimi). Derinlik `Prometheus-Best-Practices.md`'de KALDI. +2 AP.
- **B3 kırık-lab** 231→**306s**: `## 9️⃣ uçtan-uca teşhis` — **DNS** senaryosu (K01 gizli
  sebep setiyle *kasıtlı* örtüşmez), belirti→katman böl→kök sebep→düzelt+DOĞRULA;
  `## 🔟 zaman kutusu / yan etki / eskalasyon` ("neyi kanıtladım" ile eskale et). +3 AP.
- **Güvenlik ipliği (§4.2) korundu:** B1 log'da sır/PII kırmızı çizgi + KVKK; B2 `/metrics`
  sızıntısı + sır/PII etikete koyma; B3 `chmod 777`/`root` "hızlı düzeltme" = açık açar.
- **QA:** `python3 .local/qa.py` → **exit 0, 0 UYARI** (önceki 3 derinlik uyarısı temizlendi).
- **Otonom denetimler (§14.3):** (1) tekrar: B1/B2/B3 özgün cümleleri (`list-boots`,
  `aralık vektörü`, `zaman kutusu`) block-b dışında `grep` → **yok**. (2) pazarlama grep
  temiz. (3) süre: Blok B `estimated_hours`=36 (12×3, değişmedi); Blok A+B toplam **133s**
  (A97·B36, plan tutuyor). **Exit gate:** tüm A/B ön koşulları geriye işaret ediyor (döngü yok).
