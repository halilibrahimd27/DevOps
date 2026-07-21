# STATE — Öğrenme Patikası İnşası

**Son güncelleme:** 2026-07-22 · **Son commit:** (bu tur) Faz 4 tamam — Blok E içerik (E1–E5) + interview coverage

## Faz durumu

| Faz | Ad | Durum | Not |
|---|---|---|---|
| -1 | Zemin: rebrand + i18n + P0 | ✅ | Tamamlandı: infra + rebrand(in-repo) + konumlandırma + i18n zemini + P0-1..7 |
| 0 | Keşif ve haritalama | ✅ | `GAP-MAP.md` + `MODULE-SPEC.md`. **ONAY ALINDI** — 9 revizyon uygulandı |
| 1 | İskelet | ✅ | 8 rehber + 29 modül iskeleti + 3 capstone. QA exit 0 |
| 2 | Blok A + B (içerik) | ✅ | **Tamam.** A1–A6 + B1–B3 (9 modül) TR içerik, hepsi >300s, QA exit 0 (0 uyarı) |
| 3 | Blok C + D | ✅ | **Tamam.** C0–C4 + D1–D5 (10 modül) içerik. C88·D84=172s (plan tutuyor). QA exit 0 (0 uyarı) |
| 4 | Blok E | ✅ | **Tamam.** E1–E5 (5 modül) içerik. E toplam=64s (revizyon4 planı tutuyor). QA exit 0 (0 uyarı). `INTERVIEW-COVERAGE.md` yazıldı: 15/15 mid-level soru A–E ile eşleşiyor |
| 5 | Lab'ların tamamlanması | ⬜ | **SIRADA.** starter/solution/verify.sh/setup.sh/hints. L01–L20 + K00–K09. `bash -n` sözdizimi |
| 6 | Değerlendirme | ⬜ | STAGE-EXAM, PLACEMENT kontrol testleri, capstone rubrikleri |
| 6.5 | Sertifika katmanı | ⬜ | G3'te F2→CKS bağımlılığı burada çözülecek (revizyon 7) |
| 7 | Blok F + kariyer köprüsü | ⬜ | PORTFOLIO.md + F egzersizleri (revizyon 9) |
| 8 | Entegrasyon | ⬜ | 22 nav başlığı + geri-linkler. (Not: `2[0-9]-*` globu 22'yi zaten stage ediyor; `_planning` `exclude_docs`'ta) |
| 9 | Düşmanca gözden geçirme | ⬜ | TROUBLESHOOTING.md 40+ madde burada dolar |

## Sıradaki adım

**Faz 5'e başla — Lab'ların tamamlanması.** Faz 4 (E1–E5) bitti, QA exit 0.
Şu ana kadar **modüller lab'ları kod-span olarak referans veriyor** (markdown link değil);
`labs/build/L##/` ve `labs/broken/K##/` dizinleri **henüz yok** — Faz 5'te doğacaklar.

Yapılacak (BUILD-PROMPT §7 anatomisi):
- **İnşa lab'ları L01–L20:** `README.md` (görev+adım+kabul+ipucu) · `starter/` · `solution/`
  ("önce kendin dene" uyarısı) · `verify.sh` (mekanik doğrulama).
- **Kırık lab'lar K00–K09:** `README.md` (SADECE belirti) · `setup.sh` (bilerek bozuk kurar,
  kind/docker-compose) · `hints/` (hint-1/2/3 kademeli) · `solution.md` (kök sebep + **teşhis
  akışı** önce) · `verify.sh`. **qa.py kırık lab için 4 zorunlu dosya arar:** README+setup.sh+
  solution.md+verify.sh (`check_labs`, qa.py:251). Eksikse ERROR.
- **Tüm `.sh` dosyaları `bash -n` sözdizimi kontrolünden geçmeli** (qa.py:244). Bağımlılıklar
  README'de listeli.
- Modüllerdeki lab kod-span'lerini (`labs/build/L##/`) gerçek dizin oluşunca markdown link'e
  çevirmek OPSİYONEL — qa link denetimi yalnız markdown linkleri kontrol eder, kod-span'i değil.

> ⚠️ **Faz 5 kesinlikle tek tura sığmaz** (20 build + 10 kırık lab = 30 dizin, her biri
> 3–5 dosya). §14.1.3: nereye kadar geldiğini **lab no seviyesinde** buraya yaz
> (ör. "L01–L06 + K00 yazıldı, L07'den devam"), commit, dur. Blok sırasını takip et:
> önce A/B lab'ları (L01–L08 + K01), sonra C/D (L09–L17 + K02–K06), sonra E (L18–L20 + K07–K09).

> 🧵 **Güvenlik ipliği (lab'larda):** kırık lab bozukluk türleri gerçekçi olmalı —
> RBAC forbidden (K04), NetworkPolicy bağlantı kesme, image tarama fail (D4 hattı),
> secret sızma. K08 restore başarısız + backup erişim; K09 chaos blast-radius.

> 📌 **B2 notu hâlâ geçerli:** `Prometheus-Grafana-K8s-Setup.md` K8s tabanlı → B lab'ında
> (L08) kullanma; yerel docker-compose Prometheus yeter. Kaynak: `MODULE-SPEC.md`.

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

## Bu oturumda yapılanlar (Faz 4'ü TAMAMLADI — Blok E içerik)

Giriş durumu: Faz 3 kapalı, E iskeletleri hazır ama 5 modülde TODO. Bu tur **Faz 4'ü
kapattı** — 5 modül gövdesi dolduruldu (Kabul kriterleri doğrulanabilir + Kendini test et
Q&A + Takıldıysan tablosu). Hepsi 🟢 VAR (sıralayıcı) → Faz 3 deseni, kısa tutuldu:

- **E1 SLI/SLO/error-budget** (67s): SLI seçimi + SLO/error-budget hesabı kabul kriterine
  bağlandı (`%99.9→~43dk/ay`); 3 test Q&A (budget matematiği, health-check yerine kullanıcı
  isteği, budget tükenince yavaşla). "Önce oku" 11-SRE + 07-Observability (mevcut).
- **E2 alerting+on-call** (68s): SLO'ya bağlı alarm + gürültü örneği + page/ticket/log
  sınıflama + **eskalasyon** kabul kriteri. Güvenlik ipliği: eskalasyon zinciri + sessize
  alma denetim kaydı. cause-based↔symptom-based test.
- **E3 incident+postmortem** (70s): UTC timeline + blameless postmortem + izlenebilir eylem
  maddesi (sahip+tarih) + `K07 verify.sh`. "İnsan hatası kök sebep değil" + "niçin daha erken
  yakalanmadı" test. Kırık lab K07 kod-span.
- **E4 veritabanı-restore** (73s): temiz ortama restore + bütünlük sorgusu + RTO/RPO +
  **backup erişim/at-rest şifreleme** kabul kriteri + `K08 verify.sh`. Güvenlik ipliği açık
  (backup = tüm veri, en zayıf kopya). RPO↔RTO maliyet + açık bucket testi.
- **E5 chaos** (71s): sınırlı blast radius + hipotez→deney→sonuç raporu + zayıflık→eylem/alarm
  + `K09 verify.sh`. "Deneyden önce hipotez" + "blast radius" + "bozulmadan geçen game day
  başarısız mı" test. Kırık lab K09 kod-span.
- **`_planning/INTERVIEW-COVERAGE.md` yazıldı (Faz 4 çıktı kapısı):** `18-Career/DevOps-
  Interview-Questions.md` mid-level soruları (11–25) → A–E modül tablosu. **15/15 eşleşiyor,
  eşleşmeyen yok → F'ye taşınan soru yok, eklenen modül yok. Kapı geçildi.**
- **QA:** `python3 .local/qa.py` → **exit 0, 0 UYARI**. Kalan 5 TODO = F1–F5 (Faz 7).
- **Otonom denetimler (§14.3):** (1) tekrar: 3 özgün cümle (`test edilmemiş backup yalnızca
  bir umuttur`, `Hipotezsiz deney kurcalamadır`, `sistem X'e izin verdi`) LP dışında `grep` →
  **yok**; qa duplication temiz. (2) pazarlama regex → E modüllerinde **0 hit** (STATE ve D2
  "garanti ettiği" qa'nın `garanti ed` desenine takılmıyor, ayrıca _planning qa'dan hariç).
  (3) süre: Blok E=64 (12+12+14+14+12) — revizyon 4 planı (E64) birebir; E≥50 alarmı geçti.
  **Exit gate:** tüm E ön koşulları geriye işaret ediyor (döngü yok, qa doğruladı).
