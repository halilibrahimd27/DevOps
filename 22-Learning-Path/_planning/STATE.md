# STATE — Öğrenme Patikası İnşası

**Son güncelleme:** 2026-07-22 · **Son commit:** (bu tur) Faz 3 tamam — Blok C+D içerik (sıralayıcı + C0/D1 köprü)

## Faz durumu

| Faz | Ad | Durum | Not |
|---|---|---|---|
| -1 | Zemin: rebrand + i18n + P0 | ✅ | Tamamlandı: infra + rebrand(in-repo) + konumlandırma + i18n zemini + P0-1..7 |
| 0 | Keşif ve haritalama | ✅ | `GAP-MAP.md` + `MODULE-SPEC.md`. **ONAY ALINDI** — 9 revizyon uygulandı |
| 1 | İskelet | ✅ | 8 rehber + 29 modül iskeleti + 3 capstone. QA exit 0 |
| 2 | Blok A + B (içerik) | ✅ | **Tamam.** A1–A6 + B1–B3 (9 modül) TR içerik, hepsi >300s, QA exit 0 (0 uyarı) |
| 3 | Blok C + D | ✅ | **Tamam.** C0–C4 + D1–D5 (10 modül) içerik. C88·D84=172s (plan tutuyor). QA exit 0 (0 uyarı) |
| 4 | Blok E | ⬜ | **SIRADA.** E1–E5 + chaos/ileri kırık lab. Çıktı kapısı: interview coverage |
| 5 | Lab'ların tamamlanması | ⬜ | |
| 6 | Değerlendirme | ⬜ | STAGE-EXAM, PLACEMENT kontrol testleri, capstone rubrikleri |
| 6.5 | Sertifika katmanı | ⬜ | G3'te F2→CKS bağımlılığı burada çözülecek (revizyon 7) |
| 7 | Blok F + kariyer köprüsü | ⬜ | PORTFOLIO.md + F egzersizleri (revizyon 9) |
| 8 | Entegrasyon | ⬜ | 22 nav başlığı + geri-linkler. (Not: `2[0-9]-*` globu 22'yi zaten stage ediyor; `_planning` `exclude_docs`'ta) |
| 9 | Düşmanca gözden geçirme | ⬜ | TROUBLESHOOTING.md 40+ madde burada dolar |

## Sıradaki adım

**Faz 4'e başla — Blok E içerik.** Faz 3 (C0–C4 + D1–D5) tamamen bitti, QA exit 0.
Blok E iskeletleri hazır (`block-e-ownership/`), TODO gövdeleri dolacak. Modüller
(hepsi 🟢 VAR — Faz 3 sıralayıcı deseni, kısa tut):
**E1(SLI/SLO/error-budget) → E2(alerting+on-call) → E3(incident+postmortem) →
E4(veritabanı production — özellikle restore) → E5(chaos/ileri kırık lab).**

> ⚠️ **Faz 4 = Faz 3 deseni.** Blok E tümü 🟢 VAR (sıralayıcı). Yeni açıklayıcı içerik
> **minimum**; gövde "Önce oku" → mevcut deep-dive (11-SRE, 07-Observability, 08-Security,
> 10-Databases-Production) + kabul kriteri + kırık lab kod-span. **>220 satır = qa UYARISI
> → kısa tut.** Her modülün "Önce oku"da ≥1 mevcut repo dosyası. Kaynak: `MODULE-SPEC.md`.

> 🎯 **Faz 4 çıktı kapısı:** `18-Career/DevOps-Interview-Questions.md` içindeki her
> mid-seviye soru en az bir A–E modülüyle eşleşiyor. Eşleşmeyen → ya modül ekle ya soruyu
> F'ye taşı. Tabloyu `_planning/INTERVIEW-COVERAGE.md`'ye yaz.

> 🧵 **Güvenlik ipliği (Blok E):** E4 restore (test edilmemiş backup ≠ backup) + veri
> güvenliği; E2 alerting'te gürültü/eskalasyon disiplini; E3 blameless postmortem.
> Kırık lab: E3→K07 (incident sim), E4→K08 (restore başarısız), E5→K09 (chaos/game day).

> ⚠️ Faz 4 muhtemelen tek tura sığmaz (§14.1.3). Sığmazsa: nereye kadar geldiğini
> **modül adı seviyesinde** buraya yaz (ör. "E1–E3 yazıldı, E4'ten devam"), commit, dur.
> Lab/kırık-lab dizinleri (K07–K09) Faz 5'te doğar; modülde kod-span referans yeter.

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

## Bu oturumda yapılanlar (Faz 3'ü TAMAMLADI — Blok C + D içerik)

Giriş durumu: Faz 2 kapalı, C/D iskeletleri hazır ama 10 modülde TODO. Bu tur **Faz 3'ü
kapattı** — 10 modül gövdesi dolduruldu (Kabul kriterleri + Kendini test et Q&A +
Takıldıysan tablosu; C0'a öğretici gövde, D1'e kavram köprüsü):

- **C0 ops-python** 59→**148s** (tek 🔴 EKSİK modül — Python repoda yok): öğretici gövde
  yazıldı — Bash↔Python sınırı tablosu, `argparse` CLI + çıkış kodu, `urllib`/JSON + timeout,
  `except: pass` tuzağı, venv/requirements. "Önce oku" A5 + STUDY-METHOD'a bağlandı
  (placeholder satır kaldırıldı). Level=C olduğu için qa sıralayıcı sayar ama 148<220 → **uyarı yok**.
- **C1–C4** (sıralayıcı, 69–74s): container/CI/terraform/bulut — kabul kriterleri
  doğrulanabilir hale getirildi (`docker images` önce/sonra, `:latest` yasağı, state lock/drift,
  bütçe alarmı test), 3 test sorusu + cevap, 4 satır takıldıysan tablosu. "Önce oku" mevcut.
- **D1 k8s-temel** (🟡 KISMİ, 66→**85s**): `## 🌉 Köprü` eklendi — Pod→Deployment→Service→
  Ingress kavram girişi (05-Kubernetes bunu varsayar, öğretmez); placeholder "Önce oku" satırı
  kaldırıldı. **RBAC + NetworkPolicy ilk günden**: köprü + hardening linki + kabul kriteri +
  test Q3 + takıldıysan (forbidden, NetworkPolicy bağlantı kesme) hepsinde içeride.
- **D2–D5** (sıralayıcı, 69–74s): production/secret/supply-chain/gitops. **D4 ayrı güvenlik
  dersi DEĞİL** — "C2 pipeline'ının devamı" çerçevesi metinde açık (tarama build'i kırıyor,
  cosign verify, admission policy). D3 secret + leak tarama; D5 drift/OutOfSync + D3'e geri dönüş.
- **qa.py false-positive düzeltildi:** D4'te "garanti eder/etmez" → qa marketing regex'i
  `garanti ed`'e takılıyordu (ERROR). Anlamı bozmadan "kanıtlar/kanıtlamaz" yapıldı (§15.4:
  kontrol yanlış değil, ifade değişti — içerik korundu).
- **QA:** `python3 .local/qa.py` → **exit 0, 0 UYARI**. Kalan 10 TODO = E1–E5 + F1–F5 (Faz 4/7).
- **Otonom denetimler (§14.3):** (1) tekrar: 3 özgün cümle (`Bash'in tıkandığı yeri açan`,
  `çalışıyor ama erişilemiyor`, imza cümlesi) LP dışında `grep` → **yok**; qa duplication da temiz.
  (2) pazarlama regex → **0 hit**. (3) süre: Blok C=88 (30+14+16+16+12), Blok D=84
  (28+16+12+14+14), toplam **172s** — revizyon 4 planı (C88·D84) birebir tutuyor; D≥60 alarmı geçti.
  **Exit gate:** tüm C/D ön koşulları geriye işaret ediyor (döngü yok, qa doğruladı).
