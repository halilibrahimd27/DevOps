# STATE — Öğrenme Patikası İnşası

**Son güncelleme:** 2026-07-22 · **Son commit:** (bu tur) Faz 8 TAMAM — entegrasyon: kök README + RoadMap redirect + build-docs nav + 43 deep-dive geri-link

## Faz durumu

| Faz | Ad | Durum | Not |
|---|---|---|---|
| -1 | Zemin: rebrand + i18n + P0 | ✅ | Tamamlandı: infra + rebrand(in-repo) + konumlandırma + i18n zemini + P0-1..7 |
| 0 | Keşif ve haritalama | ✅ | `GAP-MAP.md` + `MODULE-SPEC.md`. **ONAY ALINDI** — 9 revizyon uygulandı |
| 1 | İskelet | ✅ | 8 rehber + 29 modül iskeleti + 3 capstone. QA exit 0 |
| 2 | Blok A + B (içerik) | ✅ | **Tamam.** A1–A6 + B1–B3 (9 modül) TR içerik, hepsi >300s, QA exit 0 (0 uyarı) |
| 3 | Blok C + D | ✅ | **Tamam.** C0–C4 + D1–D5 (10 modül) içerik. C88·D84=172s (plan tutuyor). QA exit 0 (0 uyarı) |
| 4 | Blok E | ✅ | **Tamam.** E1–E5 (5 modül) içerik. E toplam=64s (revizyon4 planı tutuyor). QA exit 0 (0 uyarı). `INTERVIEW-COVERAGE.md` yazıldı: 15/15 mid-level soru A–E ile eşleşiyor |
| 5 | Lab'ların tamamlanması | ✅ | **Tamam.** L01–L20 (20 build) + K00–K09 (10 kırık) tam. 49 script `bash -n` temiz, kırık lab 4-dosya tam. Blok E lab'ları (L18–L20 + K07–K09) doğrulandı; 30 modül→lab pointer'ı canlı markdown link'e çevrildi. QA exit 0 (0 uyarı) |
| 6 | Değerlendirme | ✅ | **Tamam.** 5 STAGE-EXAM (A–E, blok klasörlerinde) + PLACEMENT 2 kontrol testi dolduruldu + 3 capstone (şartname/kabul/rubrik/portfolyo şablonu). Her sınav sorusu modül kabul kriterine izlenebilir (traceability sütunu). QA exit 0 (0 uyarı) |
| 6.5 | Sertifika katmanı | ✅ | **Tamam.** README + G1/G2/G3 + HOW-TO-CERTIFY (§8.2 9 bölüm/kapı, sürüm uyarısı, domain×modül boşluk sütunu). Redirect + RoadMap/CV-Tips entegrasyonu + DCA legacy notu + çelişki temizliği. G3'te F2→CKS ileri-link + sıra notu (revizyon 7). QA exit 0 (0 uyarı) |
| 7 | Blok F + kariyer köprüsü | ✅ | **Tamam.** F1–F5 içerik (üçüncü bakış çerçevesi) + F1/F2/F4/F5 teslim egzersizleri + PORTFOLIO.md + CV-Tips çift yönlü bağ. F toplam=48s (plan F48 tutuyor). QA exit 0 (0 uyarı) |
| 8 | Entegrasyon | ✅ | **Tamam.** Kök README (patika = Hızlı Başlangıç 1. satır + TOC) · RoadMap "A — Yeni Başlayan" redirect (eski liste `<details>` arşiv) · build-docs.sh: 22-LP `.pages` başlık+iç sıra, kök nav'da RoadMap'ten ÖNCE, `_planning` stage edilmiyor · mkdocs nav_translations EN başlık · **43 deep-dive'a "Önce oku" geri-linki** (kısıt #2 tek istisnası). QA exit 0, iki locale derlendi |
| 9 | Düşmanca gözden geçirme | ⬜ | TROUBLESHOOTING.md 40+ madde burada dolar |
| 9.5 | A0 + geri-dönük düzeltmeler | ⬜ | **ZORUNLU** — A0 modülü, L06 starter app, EN twin'ler, A1/A6 review maddeleri |

## Sıradaki adım

**Faz 9 — Düşmanca gözden geçirme ("yeni başlayan simülasyonu").** Faz 8 bu tur kapandı.
Faz 9'da yapılacaklar (BUILD-PROMPT §10 Faz 9):
- **Rolü değiştir:** DevSecOps hakkında hiçbir şey bilmeyen biri ol, **A1'den sırayla** oku.
  Her modülde ara ve `_planning/REVIEW-FINDINGS.md`'ye yaz: (a) o ana kadar tanımlanmamış
  terim, (b) henüz öğrenilmemiş bir şeyi varsayan adım, (c) öznel kabul kriteri, (d)
  doğrulanamayan lab / ölü link, (e) gerçekçi olmayan süre, (f) iki modül arası açıklanmamış
  sıçrama, (g) dış kaynak sözleşmesine (§9: 4 alan) uymayan link, (h) güvenlik ipliği kopmuş
  D-modülü.
- **`TROUBLESHOOTING.md` 40+ madde burada dolar** (§5 dizin yapısı; hata → sebep → çözüm).
  Şu an dosya iskelet/az dolu olabilir — **kontrol et**, `ImagePullBackOff`/RBAC forbidden/
  terraform state lock/DNS/PVC binding/OOMKilled gibi kesin takılma noktalarını doldur.
  Kırık lab solution.md'lerindeki teşhis akışlarıyla çapraz bağla.
- Her bulguyu düzelt, düzeltmeleri de gözden geçir, **liste boşalana kadar tekrarla.**
- **Çıktı kapısı:** açık bulgu yok · terim envanteri (`_planning/GLOSSARY-COVERAGE.md`)
  çıkarıldı, her teknik terim ya bir modülde tanımlı ya `Glossary.md`'de var.
- Faz 9 muhtemelen tek tura sığmaz → §14.1(3): nereye kadar gelindiğini modül adı seviyesinde
  `Sıradaki adım`'a yaz, commit at, dur.
- Bittiğinde: QA exit 0, §14.3 self-check, STATE güncelle, commit, **Faz 9 → ✅**, dur.
- **Faz 9.5 (ZORUNLU, en son):** A0 modülü + L06 starter app + EN twin'ler + A1/A6 review
  maddeleri. EN twin katmanı hâlâ `qa.py` `.en.md` çakışmasına takılı (bkz. Faz 2 kararı) —
  kullanıcı `qa.py`'yi genişletmeden EN twin yazılamaz. Bu turda GİRME; Faz 9'u bitir.

**Yerleşik desenler (sonraki fazlarda referans al):**
- **STAGE-EXAM deseni (Faz 6'da kondu):** frontmatter (`description/level/tags`, `module`
  YOK → qa MOD_RE eşleşmez, modül denetimine girmez) + traceability tablosu (`| # | Soru |
  İzlenebilirlik (modül → kabul kriteri) |`) + uygulamalı görev (kırık lab verify.sh'e
  bağlı) + anti-pattern tablosu + "Geçtin mi?" checklist. **Konum: her blok klasörü içinde
  `STAGE-EXAM.md`.** CURRICULUM geçiş-sinyalleri tablosundan + README adım 6'dan linkli.
- **Capstone deseni (Faz 6'da dolduruldu):** Şartname (teslim edilecek repo içeriği) +
  doğrulanabilir Kabul kriterleri + 0–2 puanlı Rubrik tablosu (geçme eşiği + zorunlu eksen) +
  Portfolyo README şablonu (```markdown code-block, placeholder-güvenli). **`PORTFOLIO.md`
  code-span olarak anılır, LINK DEĞİL** (dosya Faz 7'de doğar; link olsaydı qa kırık-link verirdi).
- Build lab = `README.md` + `starter/` + `solution/` + `verify.sh`. Kırık lab =
  `README.md` (belirti) + `setup.sh` + `hints/hint-1..3.md` + `solution.md` + `verify.sh`.
  Modül→lab: `../labs/build/L##-.../`; lab→modül: `../../../block-x/<ID>-...md`.

> 📌 **Yerel-önce (değişmez):** hiçbir lab gerçek para/bulut şart koşmaz (C4 bütçe alarmı
> `validate/plan` ile yerelde doğrulanır). Sertifika pratik ortamı da yerel-önce (kind/k3s/
> LocalStack) — G# dosyalarında bunu vurgula.

## Açık kararlar

### Faz 8 kapanışı (bu tur)
- **Geri-link kapsamı = yalnız "Önce oku" tablosunda anılan deep-dive'lar (43 dosya).** §8/§10
  Faz 8 "Hangi deep-dive'lar hangi modülde 'Önce oku'da anılıyorsa onlara. Kapsamı dar tut,
  her dosyaya değil" der. Modüllerin **yalnız `## 📖 Önce oku` bölümünü** ayrıştıran script
  ile 43 hedef bulundu (Kendini-test/Takıldıysan linkleri hariç → daha dar, daha savunulabilir).
  125 deep-dive'ın ~1/3'ü; "her dosyaya değil" kuralına uyar. Çok-modüllü dosyalar (ör.
  Blameless-Postmortem → E3+F4) tüm modülleri linkli listeler.
- **Geri-link = §3 kısıt #2'nin ADLI istisnası.** "00-21 değiştirme, tek istisna Faz 8 dosya
  sonuna tek satır geri-link." 43 dosyaya `---` + tek blockquote (`🎓 Öğrenme Patikası: Bu
  doküman [`X`](...) modülünde "Önce oku" kaynağı...`). İçerik yeniden yazılmadı, salt footer.
  Idempotent script (marker varsa atlar). 46 hedef link (`os.path.exists`) doğrulandı, kırık 0.
- **22-Learning-Path zaten `2[0-9]-*` globuna dahil** (build-docs.sh:58) — doğrulandı, glob
  değişmedi. Eklenen: (a) `_planning` staging'den `rm -rf` (çift emniyet; `exclude_docs`'ta
  da var), (b) özel `.pages` (başlık `🎓 Öğrenme Patikası` + iç sıra: README→rehberler→
  bloklar→capstone/sertifika/lab), (c) 9 alt-klasör başlığı (Blok A..F, Capstone, Sertifika,
  Lab), (d) kök nav'da `22-Learning-Path` **RoadMap'ten önce**.
- **`.pages` başlığı TR, EN nav_translations'ta** (§8 "nav_translations ile EN başlık"):
  `"🎓 Öğrenme Patikası": "🎓 Learning Path"` — mevcut Roadmap/About/Sözlük/Etiketler
  deseniyle birebir. BUILD-PROMPT'taki `🎓 Öğrenme Patikası / Learning Path` ifadesi bu
  iki-dilli çift olarak yorumlandı (RoadMap deseni), tek string değil.
- **RoadMap "A — Yeni Başlayan" eski liste `<details>` arşivinde korundu** (§10 "eski liste
  özet olarak kalır" — silme). Üstüne redirect kutusu: gap #1'i (linux-troubleshooting =
  ileri SRE materyali) açıkça anlatıp patikaya yönlendirir. `🆕 0'dan başlıyorum` kartı da
  patikaya bağlandı. Ünvan/süre iddiası ("90 günde junior") kaldırıldı → patika bunu vaat etmez.
- **`site_src/` + `site/` gitignore'da** — commit'e girmiyor (doğrulandı, git status'ta yok).

### Faz 7 kapanışı (önceki tur)
- **`18-Career/CV-Tips.md` düzenlendi — §10 Faz 7'nin ADLI istisnası.** §3 kısıt #2 "00-21
  değiştirme, tek istisna Faz 8 geri-link" der; ANCAK §10 Faz 7 açıkça "`18-Career/CV-Tips.md`
  ile çift yönlü bağla" diyerek bu dosyayı isimle çağırır (Faz 6.5 de aynı gerekçeyle
  düzenlemişti). Değişiklik minimal: Referanslar listesine **tek satır** PORTFOLIO.md link'i.
  İçerik yeniden yazılmadı.
- **Kısıt #1 (kopyalama değil, LINK) korundu.** F1–F5 "sıralayıcı" modüller: her biri 75–79
  satır (qa `≤220` sıralayıcı eşiğinin çok altında), "Önce oku" tabloları `12-FinOps`/
  `13-Platform-Engineering`/`19-Compliance`/`20-Soft-Skills`/`08-Security` deep-dive'larına
  link veriyor, açıklayıcı içerik tekrar edilmedi. §14.3(1) 4 özgün cümle grep → LP dışı 0.
- **"senior olur" substring tuzağı (qa marketing regex):** PORTFOLIO.md'de ünvan iddiasını
  **reddeden** cümle ilk taslakta "mid/senior olursun demez" yazıyordu; `senior olur`
  substring'i qa.py `check_marketing`'e takılırdı (regex bağlam/negasyon anlamaz). Cümle
  "şu ünvana geçersin gibi bir cümle burada geçmez" olarak yeniden yazıldı. Kandırma değil —
  anlam aynı (ünvan reddi), yalnız yasak substring kaldırıldı.
- **F teslim egzersizleri "yazılı çıktı" ile doğrulanabilir yapıldı (revizyon 9 + §12.3).**
  F1 `finops-analiz.md`, F2 `tehdit-modeli.md`, F3 `golden-path-onerisi.md`, F4 ADR+postmortem,
  F5 `karar-yazisi.md`. Kabul kriterleri dosya varlığı/içerik üzerinden ölçülür, "anladım" yok
  (qa öznel-kriter deseni temiz). §4.5 NOT-YET ilkesi F3'te ("ne zaman erken") pekiştirildi.
- **PORTFOLIO.md CV bulle şablonlarında metrik `<...>` placeholder.** §1 "kaynaksız istatistik
  yok" + CLAUDE.md placeholder güvenliği: uydurma sayı yerine öğrencinin kendi ölçtüğü değeri
  yazacağı `<önce>`/`<sonra>` placeholder'ı. `%X artış` kalıbından kaçınıldı (qa marketing).

### Faz 5 kapanışı (önceki tur)
- **Blok E lab'ları giriş anında zaten commit'liydi (elle/karışık geçmiş) — bu tur
  doğrulandı, yeniden yazılmadı.** `a0994d3` ("ara kayıt (elle)") L18–L20 + K07–K09'u
  ekledi ama K09'un `solution.md`+`verify.sh`'i eksikti; onları **yanlış mesajlı**
  `a6b75ef` commit'i ("Faz 9.5 …") tamamladı — o commit gerçekte Faz 9.5 işi YAPMADI,
  yalnız K09'un 2 dosyasını + STATE'e 9.5 satırını ekledi. **Faz 9.5 hâlâ ⬜** (A0/EN
  twin yapılmadı). Bu tur altı Blok E lab'ı tek tek okundu: anatomi tam, CLAUDE.md tonu,
  güvenlik ipliği (K08 backup erişim/at-rest, K09 blast-radius sınırlı), `bash -n` temiz,
  pazarlama/placeholder sızıntısı yok, özgün (3 cümle repo-genelinde grep → LP dışı 0).
- **30 modül→lab pointer'ı canlı markdown link'e çevrildi (Faz 5 kapanış işi).** Tüm
  L01–L20 + K00–K09 dizinleri artık var; `👉 \`labs/…/\` — Faz 5'te oluşturulacak.`
  code-span'leri `👉 [\`labs/…/\`](../labs/…/)` link'ine dönüştü, "Faz 5'te" ibaresi
  kaldırıldı. A/B görev-taslağı açıklamaları korundu. qa.py link denetimi dizin link'ini
  (`os.path.exists`) kabul ediyor → QA exit 0. Kapsam: yalnız `block-*/` pointer satırları
  (24 dosya, +33/−31), `00-21` ve lab içeriği değişmedi.
- **C0 (ops-python) ayrı lab dizini yok — dürüstçe yeniden çerçevelendi.** MODULE-SPEC C0'a
  L## atamıyor. Pointer, olmayan bir lab'a link vermek yerine "ayrı lab yok; pratik =
  kabul kriterleri; yazdığın aracı C2/L10 pipeline'ında kullanırsın" oldu. Uydurma link yok.
- **D2:52 "garanti ettiği" — teknik (K8s requests), dokunulmadı.** §14.3(2) taraması bunu
  yakalar ama pazarlama değil; bu tur değişmedi (yalnız D2 pointer satırları). Önceden
  kabul edilmiş karar.

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

## Bu oturumda yapılanlar (Faz 8 — Entegrasyon, KAPANDI)

**Giriş durumu:** Faz 7 önceki tur kapanmıştı (STATE ✅). Bu tur `STATE.md` okundu, QA giriş
kontrolü (`qa.py` exit 0, PAUSE yok, branch `feat/learning-path`, temiz working tree) yapıldı,
Faz 8'e geçildi.

**Bu tur yapılan (§10 Faz 8):**
1. **Kök `README.md`** — patika **Hızlı Başlangıç'ın 1. satırı**: yeni `🎓 Sıfırdan
   başlıyorum` satırı → `22-Learning-Path/README.md`. Eski `🆕 "DevOps nedir?"` satırı
   Modern-DevOps-2026'yı "alanın kuşbakışı" olarak yeniden çerçeveledi (kırık ön-koşul
   zinciri artık beginner'ı yanlış yere yollamıyor). TOC "Yol Haritası & Felsefe"ye de
   patika satırı eklendi (RoadMap'ten önce).
2. **`RoadMap/README.md`** — "A — Yeni Başlayan" patikaya yönlendirildi: intro'ya + section A
   başına redirect kutusu (gap #1'i açıkça anlatır), `🆕 0'dan başlıyorum` kartı patikaya
   bağlandı, **eski 90 günlük haftalık liste `<details>` arşivinde korundu** (silinmedi,
   özetlendi). "90 günde junior" ünvan/süre iddiası kaldırıldı.
3. **`scripts/build-docs.sh`** — (a) `_planning` staging'den `rm -rf` (stage EDİLMEZ); (b)
   `22-Learning-Path/.pages` özel blok: başlık `🎓 Öğrenme Patikası` + iç sıra (README önce);
   (c) 9 alt-klasör başlığı (Blok A..F + Capstone/Sertifika/Lab); (d) kök nav'da
   `22-Learning-Path` **RoadMap'ten ÖNCE**. `2[0-9]-*` globu 22'yi zaten stage ediyor (doğrulandı).
4. **`mkdocs.yml`** — `nav_translations`'a `"🎓 Öğrenme Patikası": "🎓 Learning Path"`.
   `exclude_docs`'ta `_planning` zaten vardı (doğrulandı, dokunulmadı).
5. **43 deep-dive'a geri-link** (§3 kısıt #2 tek istisnası) — yalnız "Önce oku"da anılan
   dosyalara, idempotent script ile dosya sonuna `---` + tek blockquote. Çok-modüllü dosyalar
   tüm modülleri linkler.

**Doğrulama:**
- **`bash scripts/build-docs.sh` + `python3 -m mkdocs build --clean` → exit 0**, iki locale
  (TR kök + EN `/en/`) derlendi. `site/`'te `_planning` YOK; `22-Learning-Path` TR+EN'de var.
  (INFO anchor uyarıları dokunmadığım 3 dosyada — Mobile-CICD/Prometheus-Grafana/Modern-DevOps —
  önceden vardı, error değil.)
- **`python3 .local/qa.py` → exit 0, 0 UYARI.** 29 modül, 49 lab scripti, kırık iç link yok
  (46 geri-link hedefi + README/RoadMap redirect linkleri `os.path.exists` ile doğrulandı).
- **§14.3(1) tekrar:** bu faz yeni modül prose'u yazmadı (salt geri-link footer + nav/README
  config) → deep-dive tekrarı yok; qa `check_duplication` temiz.
- **§14.3(2) pazarlama/ünvan:** düzenlenen dosyalar (README/RoadMap/geri-linkler) grep → 0 hit.
  LP'deki 3 "garanti" = önceden kabul edilmiş teknik K8s usage (D2/L14/K05).
- **§14.3(3) süre:** yeni modül yok → kümülatif değişmedi (~477s).

**Değişen dosyalar (bu tur):** kök `README.md` · `RoadMap/README.md` · `scripts/build-docs.sh` ·
`mkdocs.yml` · **43 deep-dive** (`00-Culture`…`20-Soft-Skills` + `16-Cheatsheets` + `19`/`20`)
geri-link footer'ı · `_planning/STATE.md`. `00-21` edit'leri = §3 kısıt #2'nin **Faz 8 adlı
istisnası** (dosya sonuna tek satır geri-link).

---

## Önceki oturum (Faz 7 — Blok F + kariyer köprüsü, KAPANDI)

**Giriş durumu:** Faz 6.5 önceki tur kapanmıştı (STATE ✅). Bu tur `STATE.md` okundu,
QA giriş kontrolü (`qa.py` exit 0, PAUSE yok) yapıldı, Faz 7'ye geçildi.

**Bu tur yapılan (§10 Faz 7 + §4.2 Blok F + §4.6):**
1. **F1–F5 içeriği yazıldı** (`block-f-judgment/`) — iskeletlerdeki tüm `TODO`'lar dolduruldu.
   Her modül **üçüncü bakış çerçevesiyle** (§4.2 sonu): aynı sistemlere para/organizasyon/risk
   gözüyle dönüş. **F1** maliyet ayrımı + trade-off · **F2** STRIDE tehdit modeli + KVKK/SOC2
   kontrol/kanıt eşleme · **F3** platform/golden-path/Team Topologies (NOT-YET "ne zaman erken"
   pekiştirildi) · **F4** ADR + rubrikli postmortem (yazma egzersizi) · **F5** gerekçeli "hayır"
   + vendor/kilitlenme. Her modül: "Önce oku" (2–3 mevcut deep-dive link), teslim egzersizi,
   **yazılı çıktıyla doğrulanabilir** kabul kriterleri, 3 kendini-test (cevaplar repo linkli),
   4-satır "Takıldıysan" tablosu.
2. **`PORTFOLIO.md` oluşturuldu** (§5 kök dosya) — modül/capstone → CV satırı eşlemesi.
   Kanıt→etki ilkesi, 3 eşleme tablosu (capstone / F eseri / blok→yetenek), 4-adım
   eser→bulle akışı, 8-satır anti-pattern tablosu, checklist, referanslar. Ünvan iddiası
   açıkça reddedildi; CV metrikleri `<...>` placeholder (uydurma sayı yok).
3. **CV-Tips çift yönlü bağ** — `18-Career/CV-Tips.md` Referanslar'a tek satır PORTFOLIO.md
   link'i (PORTFOLIO zaten CV-Tips'e "Deneyim/Yetenekler" bölümlerine link veriyor).
4. **Entegrasyon köprüleri:** `README.md` "Bu klasörde ne var" tablosuna PORTFOLIO.md satırı;
   F5 "Sırada" → PORTFOLIO.md canlı link; CAP1–3 "Faz 7'de eklenecek `PORTFOLIO.md`"
   code-span'leri → canlı link + present tense (dosya artık var).

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0, 0 UYARI.** "5 modülde TODO" notu kayboldu (F1–F5 doldu),
  29 modül bütünlük geçti, 49 lab scripti `bash -n` temiz, site derlendi, `_planning` sızmadı.
- **§14.3(1) tekrar:** F modüllerinden 4 özgün cümle repo-genelinde grep → LP dışında 0 hit.
  qa `check_duplication` (2-ardışık-satır örtüşme) temiz. Kısıt #1 uyumlu (linkler, kopya değil).
- **§14.3(2) pazarlama:** qa `check_marketing` deseni LP'de (`_planning` hariç) → 0 hit.
  PORTFOLIO'daki "senior olur" substring tuzağı önden yakalanıp reddedici cümle yeniden yazıldı.
- **§14.3(3) süre:** F toplam = 10+12+10+10+6 = **48s** — revizyon 4 planı (F48) birebir tutuyor.
  Kümülatif: A97·B36·C88·D84·E64·F48 + capstone60 ≈ 477s (plan sabit).

**Değişen dosyalar (bu tur):** `block-f-judgment/F1..F5.md` (içerik) · `PORTFOLIO.md` (yeni) ·
`README.md` · `capstones/CAP1..CAP3.md` (PORTFOLIO link) · `18-Career/CV-Tips.md` (tek satır) ·
`_planning/STATE.md`. `00-21` edit'i yalnız CV-Tips (§10 Faz 7 adlı istisna) — tek satır geri-link.

---

## Daha önceki oturum (Faz 6.5 — Sertifika katmanı, KAPANDI)

**Giriş durumu — önemli:** Önceki tur kapı dosyalarını (G1/G2/G3 + HOW-TO-CERTIFY +
README) yazmış ve `d18804f` commit'iyle işlemiş ama **STATE'i güncellememişti** (Faz 6.5
hâlâ ⬜). O commit `21-Field-Notes/system/devops-certification-roadmap.md`'yi **sildi**
(221 satır) — §8.1'in istediği gibi *taşımadı*, geriye **yönlendirme bırakmadı** →
`21-Field-Notes/README.md:47` kırık link (qa UYARI). `LANDSCAPE.md` ara dosyası (pazarlama
dolu) commit edilmeden silinmişti. Bu tur önce **gerçek durum doğrulandı** (5 kapı dosyası
okundu: hepsi §8.2 9-bölüm tam, sürüm uyarılı, domain×modül boşluk sütunlu, ton temiz),
sonra **eksik §8 teslimatları tamamlandı**.

**Bu tur yapılan (Faz 6.5 eksiklerini kapatma):**
1. **§8.1 redirect** — `21-Field-Notes/system/devops-certification-roadmap.md` yeniden
   yazıldı: kısa yönlendirme sayfası (frontmatter + tablo → `certifications/` 5 dosyası).
   Eski "48 ayda 10 sertifika" planının kaldırıldığını açıkça söyler. **qa UYARI kayboldu.**
2. **`21-Field-Notes/README.md:47`** — "Senior seviye sertifika kariyer rehberi" →
   "3 sertifika kapısına yönlendirir (3 kapı, 10 değil)". Yanlış çerçeve düzeltildi.
3. **§8.2 entegrasyon — `RoadMap/README.md:179`** anti-pattern satırı: "Bir tane al" →
   "Blok başına 1 kapı — 3 kapı, 10 değil" + `certifications/` linki. Çelişki kalktı.
4. **§8.2 entegrasyon — `18-Career/CV-Tips.md`** §📜 Sertifikalar: 9-sertifika tablosunun
   altına "bu patikanın duruşu koleksiyon değil 3 kapı" kutusu + `certifications/` linki;
   "fark yaratır" pazarlama tonu yumuşatıldı. Tablo "piyasa haritası, yapılacaklar değil".
5. **§8.1 DCA + `certifications/README.md`** — LANDSCAPE'ten kalan çift/kırık-niyet satırı
   (68) kaldırıldı; yeni "🚪 Bu patikanın parçası olmayan sertifikalar" bölümü: CKAD/AWS
   DevOps Pro/GCP/Vault/PCA neden dışarıda + **Docker DCA legacy/tartışmalı statü notu**
   (öneri listesinde yok, kenarda not) + `../NOT-YET.md` linki.

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0, 0 UYARI** (önceki tek UYARI = field-notes kırık link
  artık yok; mkdocs derlendi, `_planning` sızmadı, kırık iç link yok, leak yok).
- **§8.1 no-contradiction sweep:** repoda kalan tüm "10 sertifika / 48 ay / koleksiyon"
  mentionları **anti-pattern çerçevesinde** (NOT-YET satırı, G3 "eleştirdiği koleksiyon",
  README anti-pattern tablosu, redirect açıklaması). Çelişen iki cümle yok.
- **§14.3 otonom denetimler:** (1) tekrar: kapı dosyaları mevcut deep-dive'lara link veriyor,
  yeni açıklayıcı içerik yok (kısıt #1 uyumlu). (2) pazarlama: `grep -iE "maaş|ROI|%..artış|
  en kapsamlı|garanti"` LP'de → yalnız önceden-kabul teknik "garanti" (K8s requests: D2/L14/
  K05) + STATE meta; bu turdan **0 yeni pazarlama**. (3) süre: kapı dosyaları modül değil
  (estimated_hours yok) → N/A. 5 kapı dosyası zaten plana birebir (G1/G2/G3 + HOW-TO + README).

**Değişen dosyalar (bu tur):** `21-Field-Notes/system/devops-certification-roadmap.md` (yeni
redirect) · `21-Field-Notes/README.md` · `RoadMap/README.md` · `18-Career/CV-Tips.md` ·
`22-Learning-Path/certifications/README.md` · `_planning/STATE.md`. **Kapı içeriği (G1/G2/G3/
HOW-TO) `d18804f`'te zaten doğruydu — dokunulmadı.** `00-21` dosya edit'leri §8'in açık
istisnası (§8.1/§8.2 bu dosyaları isimle sayar).
