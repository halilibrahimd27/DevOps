# STATE — Öğrenme Patikası İnşası

**Son güncelleme:** 2026-07-22 · **Son commit:** (bu tur) Faz 5 kısmi — Blok C+D lab'ları (L09–L17 + K02–K06)

## Faz durumu

| Faz | Ad | Durum | Not |
|---|---|---|---|
| -1 | Zemin: rebrand + i18n + P0 | ✅ | Tamamlandı: infra + rebrand(in-repo) + konumlandırma + i18n zemini + P0-1..7 |
| 0 | Keşif ve haritalama | ✅ | `GAP-MAP.md` + `MODULE-SPEC.md`. **ONAY ALINDI** — 9 revizyon uygulandı |
| 1 | İskelet | ✅ | 8 rehber + 29 modül iskeleti + 3 capstone. QA exit 0 |
| 2 | Blok A + B (içerik) | ✅ | **Tamam.** A1–A6 + B1–B3 (9 modül) TR içerik, hepsi >300s, QA exit 0 (0 uyarı) |
| 3 | Blok C + D | ✅ | **Tamam.** C0–C4 + D1–D5 (10 modül) içerik. C88·D84=172s (plan tutuyor). QA exit 0 (0 uyarı) |
| 4 | Blok E | ✅ | **Tamam.** E1–E5 (5 modül) içerik. E toplam=64s (revizyon4 planı tutuyor). QA exit 0 (0 uyarı). `INTERVIEW-COVERAGE.md` yazıldı: 15/15 mid-level soru A–E ile eşleşiyor |
| 5 | Lab'ların tamamlanması | 🟡 | **DEVAM.** Blok A+B (L01–L08+K00–K01) **ve** Blok C+D (L09–L17+K02–K06) lab'ları yazıldı. 39 script `bash -n` temiz, kırık lab 4-dosya tam, QA exit 0 (0 uyarı). **Kalan (yalnız Blok E):** L18–L20 + K07–K09 |
| 6 | Değerlendirme | ⬜ | STAGE-EXAM, PLACEMENT kontrol testleri, capstone rubrikleri |
| 6.5 | Sertifika katmanı | ⬜ | G3'te F2→CKS bağımlılığı burada çözülecek (revizyon 7) |
| 7 | Blok F + kariyer köprüsü | ⬜ | PORTFOLIO.md + F egzersizleri (revizyon 9) |
| 8 | Entegrasyon | ⬜ | 22 nav başlığı + geri-linkler. (Not: `2[0-9]-*` globu 22'yi zaten stage ediyor; `_planning` `exclude_docs`'ta) |
| 9 | Düşmanca gözden geçirme | ⬜ | TROUBLESHOOTING.md 40+ madde burada dolar |

## Sıradaki adım

**Faz 5 DEVAM — `L18-sli-slo`'dan başla.** Blok C+D lab'ları bu tur bitti:
`labs/build/L09–L17` + `labs/broken/K02–K06`. QA exit 0. Blok A+B önceki turda bitmişti.

**Kalan iş (yalnız Blok E — sonra Faz 5 → ✅):**
- **Blok E build:** L18-sli-slo (SLI/SLO/error budget hesabı; yerel Prometheus L08
  desenini kullan) · L19-alerting (Alertmanager kuralı + on-call disiplini) ·
  L20-veritabani-restore (**restore** — test edilmemiş backup backup değildir; yerel
  postgres dump/restore).
- **Blok E kırık:** K07-incident-sim (**çok-arızalı** incident; K04/K05 deseninde birden
  fazla katman) · K08-restore-basarisiz (**backup erişim/bozuk dump** — restore fail) ·
  K09-chaos-gameday (blast radius sınırlı; tek namespace/tek servis, kind).
- Bittiğinde: `check_labs` + `bash -n` temizken ve modül→lab pointer'ları (aşağıya bak)
  güncellendiğinde **Faz 5 → ✅**.

> 📌 **Modül→lab pointer'ları henüz güncellenmedi (bilinçli).** C/D modüllerindeki
> `## 🔨 Lab` satırları hâlâ "👉 `labs/build/L09-...` — Faz 5'te oluşturulacak." diyor;
> dizinler artık **var**. Faz 5 kapanışında (E lab'ları bitince) bu 14 pointer'ı canlı
> markdown link'e çevir ve "Faz 5'te oluşturulacak" ibaresini kaldır. Alternatif: Faz 8
> entegrasyonunda. QA'yı kırmıyor (code-span), o yüzden acil değil.

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

> ⚠️ Faz 5'in son chunk'ı kaldı: **Blok E lab'ları (L18–L20 + K07–K09)**. Sonraki tur
> bunları yaz, modül→lab pointer'larını güncelle, STATE'i güncelle, commit, **Faz 5 → ✅**,
> dur. (Blok E tek chunk'a sığar: 3 build + 3 kırık.)

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

### Faz 5'te alınanlar (bu tur — Blok C+D lab'ları)
- **Yerel-önce her lab'da korundu.** C1/C2 docker + yerel `registry:2`; C3/C4 **LocalStack**
  (bulutsuz, `test`/`test` sahte kimlik — leak guard'ın `{12,}` uzunluk eşiğinin altında,
  gerçek credential değil); D1–D5 **kind** + guard'lı `kubectl`. Hiçbir lab gerçek para/bulut
  şart koşmaz (C4 bütçe alarmı hariç, o da `validate/plan` ile yerelde doğrulanır).
- **verify.sh iki mod (A/B deseni sürdü):** mekanik artefakt denetimi (report.txt/manifest
  grep) **+** guard'lı canlı kontrol (docker/kubectl/terraform varsa çalışır, yoksa `⚠️` ile
  atlanır). Böylece hepsi CI'da `bash -n` ve öğrenci makinesinde anlamlı.
- **Lab image sürümleri pinli (placeholder değil):** `postgres:16-alpine`,
  `nginxinc/nginx-unprivileged:1.27-alpine`, `python:3.12-slim`, `registry:2`,
  `busybox:1.36`. Çalışması gereken lab artefaktı reprodüksiyon için gerçek tag ister
  (`:latest` yasak — P0 #4 deseni). GitHub Actions örneklerinde (`ci.yml`) sürümler
  `@<VERSION>` placeholder (CLAUDE.md kuralı; gerçek repoda SHA-pin notu düşüldü).
- **Kırık lab kök sebepleri ayrıştırıldı (çakışma yok):** K02=port eşleme (host:container
  sağ taraf yanlış) · K03=**bayat state lock** (`.terraform.tfstate.lock.info` → force-unlock;
  gap #8) · K04=**çok-arızalı: ImagePullBackOff + izinsiz default-deny NetworkPolicy**
  (güvenlik ipliği) · K05=**çok-arızalı: OOMKilled (32Mi limit) + yanlış probe portu (9999)** ·
  K06=**drift + auto-sync kapalı** (L17 önkoşullu; `syncPolicy.automated` geri açılır).
  K04/K05 D-bloğu için bilerek çok-arızalı (BUILD-PROMPT §7.2 "D ve E'de birden fazla").
- **K06 L17 önkoşullu:** ArgoCD+Git gerçek runtime gerektirdiği için K06 setup, L17'nin
  `argocd/lab-app` Application'ını arar; yoksa "L17'yi tamamla" der (guard). Mekanik QA
  (4 dosya + bash -n) bundan bağımsız geçer. Makul varsayım; dependency zinciri D5-içi.
- **"garanti ed" qa marketing regex çakışması düzeltildi:** L10 README "neyi garanti eder"
  → "neyi kanıtlar". qa.py'nin `garanti ed` deseni bunu yakalıyordu; teknik "garanti"
  (K8s requests, L14) noun kullanımı desende yok, dokunulmadı. §14.3(2) LP `.md` taramasında
  0 hit.
- **Modül→lab pointer'ları bu tur GÜNCELLENMEDİ (bilinçli):** bkz. Sıradaki adım notu.

### Faz 5'te alınanlar (önceki tur — Blok A+B lab'ları)
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

## Bu oturumda yapılanlar (Faz 5 KISMİ — Blok C+D lab'ları)

Giriş durumu: Faz 5'in A+B chunk'ı (L01–L08 + K00–K01) önceki turda bitmişti. Bu tur
**Blok C ve D'nin tüm lab'ları** yazıldı (BUILD-PROMPT §7 anatomisi). Otonom sözleşme
§14.1.3: Faz 5 tek tura sığmadığı için C+D chunk yazıldı, kalan (yalnız Blok E) lab no
seviyesinde `Sıradaki adım`a not düşüldü.

**İnşa lab'ları (9) — L09…L17:**
- **L09-container** (C1): naive tek-stage Dockerfile (build-essential şişkin, "önce") →
  multi-stage non-root (`--prefix=/install`, "sonra"); `docker compose` app+postgres;
  katman cache gözlemi. verify: `>=2 FROM + COPY --from=` + `:latest yok` + report boyutları.
- **L10-ci** (C2): yerel `registry:2`; `pytest → docker build → SHA-tag → push` pipeline
  (`set -euo pipefail`); GH Actions `ci.yml` ikizi (`@<VERSION>`). verify: test/build/push +
  `:latest` yasağı + "yeşil neyi kanıtlar".
- **L11-terraform** (C3): **LocalStack** (`test`/`test`, 4566); `aws_s3_bucket`+`aws_ssm_parameter`;
  apply→destroy→apply idempotency; state açıklaması.
- **L12-bulut-butce-alarmi** (C4): **ADIM 1 = bütçe alarmı** (`aws_budgets_budget`+2 bildirim,
  `<YOUR_EMAIL>`); ADIM 2 = LocalStack S3 aç/kapa; free-tier listesi + VPC/IAM/compute tanımı.
- **L13-k8s-temel** (D1): kind; Deployment+Service+Ingress **+ en-az-yetki RBAC (delete yok)
  + default-deny NetworkPolicy + izin kuralı** (güvenlik ipliği ilk gün). verify: 6 kind +
  Role'de delete olmaması + `auth can-i` kanıtı.
- **L14-k8s-production** (D2): request/limit + readiness/liveness probe + PDB(minAvailable:1) +
  HPA(CPU %50, metrics-server). verify: request/limit+2 probe+HPA+PDB.
- **L15-secret-yonetimi** (D3): `kubectl create secret` (kabuktan) → `secretKeyRef`;
  base64≠şifreleme kanıtı; gitleaks/`trivy fs` taraması; SealedSecrets/SOPS/ESO yazılı.
- **L16-supply-chain** (D4): L10 pipeline üstüne **trivy tarama KAPISI** (`--exit-code 1
  --severity HIGH,CRITICAL`) + SBOM (cyclonedx) + `cosign sign/verify`; `ci.yml` trivy-action
  `@<VERSION>`. verify: tarama kapısı + cosign + report gerekçe/SBOM.
- **L17-gitops-argocd** (D5): kind+ArgoCD; `argoproj.io/Application` (repoURL+path+syncPolicy
  automated/selfHeal); drift→OutOfSync→self-heal geri çekme. NOT-YET'e link (App-of-Apps hayır).

**Kırık lab'lar (5) — K02…K06 (hepsi 4 zorunlu dosya + 3 kademe hint):**
- **K02-container-hatasi** (C1): kök sebep = port eşleme `"8080:80"` ama app 5000 dinliyor
  (`HOST:CONTAINER` sağ taraf yanlış). `ps→logs→eşleme` teşhis üçlüsü.
- **K03-terraform-state** (C3): kök sebep = **bayat state kilidi** (yarıda kalan apply
  `.terraform.tfstate.lock.info` bıraktı) → `force-unlock`. (gap #8 kesin takılma noktası.)
- **K04-imagepullbackoff-rbac** (D1): **çok-arızalı** — (1) yok-olan image tag → ImagePullBackOff,
  (2) izinsiz default-deny NetworkPolicy → Running olsa da erişilemez. Güvenlik ipliği.
- **K05-oomkilled-probe** (D2): **çok-arızalı** — (1) `limits.memory:32Mi` + ~40MB app →
  OOMKilled(137), (2) readinessProbe port 9999 → hiç Ready olmaz. `Last State` teşhisi.
- **K06-argocd-out-of-sync** (D5): kök sebep = `syncPolicy.automated` kaldırılmış + drift →
  OutOfSync kendiliğinden düzelmiyor. **L17 önkoşullu** (setup `argocd/lab-app` arar, guard'lı).

**Doğrulama:**
- `bash -n`: **tüm yeni C/D script'leri temiz** (qa toplamı **39/39** lab scripti).
- Kırık lab 4 zorunlu dosya: **K02–K06 tam** (qa `check_labs` geçti).
- **`python3 .local/qa.py` → exit 0, 0 UYARI** (mkdocs derlendi, `_planning` sızmadı,
  kırık link yok, leak yok, duplication yok).
- **§14.3 otonom denetimler:** (1) tekrar: 3 özgün lab cümlesi (`Container "Up" ≠`,
  `koruma, koruyacağı şeyden önce`, `RESTARTS bir sayaç`) LP-dışı repoda `grep` → **0 dosya**.
  (2) pazarlama: LP `.md` içinde qa `garanti ed` deseni → düzeltildi (L10), şimdi **0 hit**.
  (3) süre: lab'lar estimated_hours taşımaz (modül değil) → N/A; lab sayısı plana birebir
  (C/D: 9 build + 5 kırık = L09–L17 + K02–K06).
