# STATE — Öğrenme Patikası İnşası

**Son güncelleme:** 2026-07-22 · **Son commit:** (bu tur) Faz 5 kısmi — Blok A+B lab'ları (L01–L08 + K00–K01)

## Faz durumu

| Faz | Ad | Durum | Not |
|---|---|---|---|
| -1 | Zemin: rebrand + i18n + P0 | ✅ | Tamamlandı: infra + rebrand(in-repo) + konumlandırma + i18n zemini + P0-1..7 |
| 0 | Keşif ve haritalama | ✅ | `GAP-MAP.md` + `MODULE-SPEC.md`. **ONAY ALINDI** — 9 revizyon uygulandı |
| 1 | İskelet | ✅ | 8 rehber + 29 modül iskeleti + 3 capstone. QA exit 0 |
| 2 | Blok A + B (içerik) | ✅ | **Tamam.** A1–A6 + B1–B3 (9 modül) TR içerik, hepsi >300s, QA exit 0 (0 uyarı) |
| 3 | Blok C + D | ✅ | **Tamam.** C0–C4 + D1–D5 (10 modül) içerik. C88·D84=172s (plan tutuyor). QA exit 0 (0 uyarı) |
| 4 | Blok E | ✅ | **Tamam.** E1–E5 (5 modül) içerik. E toplam=64s (revizyon4 planı tutuyor). QA exit 0 (0 uyarı). `INTERVIEW-COVERAGE.md` yazıldı: 15/15 mid-level soru A–E ile eşleşiyor |
| 5 | Lab'ların tamamlanması | 🟡 | **DEVAM.** Blok A+B lab'ları yazıldı: L01–L08 (build) + K00, K01 (kırık). 18 script `bash -n` temiz, QA exit 0. **Kalan:** L09–L20 + K02–K09 |
| 6 | Değerlendirme | ⬜ | STAGE-EXAM, PLACEMENT kontrol testleri, capstone rubrikleri |
| 6.5 | Sertifika katmanı | ⬜ | G3'te F2→CKS bağımlılığı burada çözülecek (revizyon 7) |
| 7 | Blok F + kariyer köprüsü | ⬜ | PORTFOLIO.md + F egzersizleri (revizyon 9) |
| 8 | Entegrasyon | ⬜ | 22 nav başlığı + geri-linkler. (Not: `2[0-9]-*` globu 22'yi zaten stage ediyor; `_planning` `exclude_docs`'ta) |
| 9 | Düşmanca gözden geçirme | ⬜ | TROUBLESHOOTING.md 40+ madde burada dolar |

## Sıradaki adım

**Faz 5 DEVAM — `L09-container`'dan başla.** Blok A+B lab'ları bu tur bitti:
`labs/build/L01–L08` + `labs/broken/K00, K01` + `labs/README.md`. QA exit 0.

**Kalan iş (blok sırasıyla):**
- **Blok C/D build:** L09-container · L10-ci · L11-terraform (yerel: LocalStack) ·
  L12-bulut-butce-alarmi (**ilk adım bütçe alarmı**) · L13-k8s-temel (kind/k3s) ·
  L14-k8s-production · L15-secret-yonetimi · L16-supply-chain (C2 pipeline üstüne) ·
  L17-gitops-argocd (kind+ArgoCD).
- **Blok C/D kırık:** K02-container-hatasi (image tag/port/env) · K03-terraform-state
  (state lock/drift) · K04-imagepullbackoff-rbac (**RBAC forbidden / NetworkPolicy** güvenlik
  ipliği) · K05-oomkilled-probe · K06-argocd-out-of-sync.
- **Blok E build:** L18-sli-slo · L19-alerting · L20-veritabani-restore.
- **Blok E kırık:** K07-incident-sim (çok-arızalı) · K08-restore-basarisiz (**backup erişim**) ·
  K09-chaos-gameday (blast radius sınırlı).

**Yerleşik desen (A+B lab'larında kanıtlandı, aynen sürdür):**
- Build lab = `README.md` (görev/adım/kabul/ipucu) + `starter/<dosya>` + `solution/<dosya>` +
  `verify.sh`. verify.sh çoğunlukla öğrencinin `report.txt`/artefakt'ını grep'ler + varsa
  canlı `curl`/`ss` kontrolü; her verify.sh içinde `ok()/no()` PASS/FAIL çerçevesi.
- Kırık lab = `README.md` (SADECE belirti) + `setup.sh` (sudo/systemd guard'lı, heredoc'la app
  yazar, bilerek bozar) + `hints/hint-1..3.md` (yön→daralt→neredeyse cevap) + `solution.md`
  (önce **teşhis akışı**, sonra kök sebep) + `verify.sh`. **qa.py `check_labs` 4 zorunlu dosyayı
  arar:** README+setup.sh+solution.md+verify.sh.
- Modül→lab linkleri: `../../../block-x/<ID>-...md` (labs/build/L##/'den 3 seviye yukarı).
  Lab→kırık lab linki: `../../broken/K##-.../`.

> ⚠️ Faz 5 hâlâ tek tura sığmaz. Sonraki tur bir sonraki blok chunk'ını yaz
> (öneri: C/D build+kırık = L09–L17 + K02–K06), STATE'i güncelle, commit, dur.
> Tüm build+kırık bitince `check_labs` + `bash -n` temizken Faz 5 → ✅.

> 📌 **B2/L08 kararı uygulandı:** L08 yerel **docker-compose** Prometheus + node-exporter
> kullandı (K8s Prometheus-Grafana-K8s-Setup.md'ye dokunulmadı). C/D lab'larında da yerel-önce:
> C1/C2 docker, D1+ kind/k3s.

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

### Faz 5'te alınanlar (bu tur)
- **Lab image sürümleri pinlendi (placeholder değil).** L08 compose'da `prom/prometheus:v2.53.0`
  ve `prom/node-exporter:v1.8.2` **gerçek sürümle** pinlendi. CLAUDE.md'nin `<VERSION>` kuralı
  *dokümantasyon snippet'leri* içindir; **çalışması gereken lab artefaktı** reprodüksiyon için
  gerçek tag ister (`:latest` yasak — P0 fix #4 deseni). Placeholder güvenliği (IP/credential)
  korundu; sürüm pin bir ihlal değil.
- **verify.sh iki mod:** (a) mekanik artefakt denetimi — öğrencinin `report.txt`/dosya izinleri/
  git durumu grep'lenir; (b) canlı kontrol — `curl`/`ss`/`systemctl` varsa çalışır, yoksa
  `⚠️` ile **atlanır** (hata değil). Böylece verify.sh hem CI'da (`bash -n`) hem öğrencinin
  makinesinde anlamlı. Öznel "anladım" kriteri yok → qa `check_modules` deseniyle uyumlu.
- **Kırık lab kök sebepleri ayrıştırıldı (çakışma yok):** K00 = eksik `EnvironmentFile`
  (systemd ön-hazırlık hatası); K01 = **port çakışması** (decoy servis 8080'i tutar).
  İkisi de B3 modülünün DNS teşhis yürüyüşünden **kasıtlı farklı** (STATE B3 notu korundu).
- **Lab placeholder güvenliği:** tüm .sh/.yaml/.env örneklerinde yalnız `127.0.0.1`/`10.x`/
  `lab.example` (RFC 2606) + `<DB_PASSWORD>` placeholder. `app.env.example` `.env` uzantısı
  taşımaz (leak guard'ın taradığı uzantı listesinde yok) ama yine de placeholder yazıldı.
  qa leak guard temiz.
- **labs/README.md eklendi** (modül değil → frontmatter gerekmez; MOD_RE eşleşmez). İki lab
  türünün anatomisi + "önce kendin dene" kuralı + bağımlılık notu.

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

## Bu oturumda yapılanlar (Faz 5 KISMİ — Blok A+B lab'ları)

Giriş durumu: Faz 4 kapalı, `labs/` dizini **yoktu**; modüller lab'ları kod-span olarak
referans veriyordu. Bu tur **Blok A ve B'nin tüm lab'ları** sıfırdan yazıldı (BUILD-PROMPT
§7 anatomisi). Otonom sözleşme §14.1.2: bir turda en fazla bir faz; Faz 5 tek tura sığmadığı
için A+B chunk yazıldı, kalan lab no seviyesinde `Sıradaki adım`a not düşüldü.

**İnşa lab'ları (8):**
- **L01-linux-temeli** (A1): process bul/incele + 750/640 izin + servis kullanıcısı.
  starter playground'u bilerek dağınık kurar; verify izinleri + report.txt'i denetler.
- **L02-ag-tcp-ip** (A2): 127.0.0.1:8080 dinlet + `ss` kanıtı + **refused↔timeout** ayrımı.
- **L03-dns-http-tls** (A3): openssl kendinden-imzalı yerel HTTPS; DNS/HTTP/TLS katmanlarını
  tek tek yürü, DNS ve TLS'i **ayrı** boz. `lab.example` (RFC 2606).
- **L04-git** (A4): sıfırdan repo, bilerek conflict + çöz, merge↔rebase grafik farkı.
- **L05-bash** (A5): `set -euo pipefail` + 2 argüman doğrulama + log özetleyip rapor yazan
  + shellcheck-temiz script. verify script'i çalıştırıp çıktısını denetler.
- **L06-elle-deploy** (A6): **container YOK** elle deploy — app.py (stdlib) + systemd unit +
  nginx ters vekil + ufw + PostgreSQL + reboot testi + KURULUM.md. En büyük lab; solution/
  tam referans (unit+nginx.conf+env.example+KURULUM.md).
- **L07-log-okuma** (B1): app'i 3 şekilde boz, her birini `journalctl` süzgeciyle bul;
  `leaky.py` sır sızdırır → güvenli hâle getir.
- **L08-metrik** (B2): yerel docker-compose Prometheus+node-exporter; 2 altın sinyal PromQL;
  `high_cardinality.py` ile seri patlaması gözlemi (CARD 10→100000).

**Kırık lab'lar (2):**
- **K00-systemd-ayaga-kalkmiyor** (A6): kök sebep = eksik `EnvironmentFile` (systemd
  ön-hazırlık hatası, app'e hiç ulaşmaz). hints 3 kademe + solution teşhis akışı önce.
- **K01-kirik-vm** (B3): kök sebep = **port çakışması** (decoy servis 8080'i tutar,
  `EADDRINUSE`). B3'ün DNS yürüyüşünden kasıtlı farklı. `status→journalctl→ss` teşhis üçlüsü.

**+ `labs/README.md`** (iki lab türü anatomisi + "önce kendin dene" kuralı).

**Doğrulama:**
- `bash -n`: **18/18 lab script'i temiz.**
- Kırık lab 4 zorunlu dosya (README+setup.sh+solution.md+verify.sh): **K00, K01 tam.**
- **`python3 .local/qa.py` → exit 0, 0 UYARI** (mkdocs derlendi, `_planning` sızmadı,
  kırık link yok, leak yok).
- **§14.3 otonom denetimler:** (1) pazarlama regex `22-Learning-Path/labs/` → **0 hit**.
  (2) tekrar: 3 özgün lab cümlesi (`sonraki her soyutlamanın`, `Reddedilmek iyi haberdir`,
  `Cardinality, Prometheus'u öldüren`) LP-dışı repoda `grep` → **0 dosya**; qa duplication
  temiz. (3) süre: lab'ların estimated_hours frontmatter'ı yok (modül değil) → süre denetimi
  N/A; lab sayısı hedefe uygun (A+B: 8 build + 2 kırık, plan L01–L08+K00–K01 birebir).
