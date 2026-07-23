# STATE — Öğrenme Patikası İnşası

**Son güncelleme:** 2026-07-23 · **Son commit:** (bu tur) Faz 9.5 — EN twin **P1b: Blok E+F modül twin'leri** (11 dosya: E1–E5 + Blok E STAGE-EXAM · F1–F5 — **Blok F'de STAGE-EXAM yok**). Bununla **P1b TAMAM** (A0…F5 + A–E STAGE-EXAM = 35 dosya). 11 paralel çeviri subagent (sonnet), dosya başına bir, sıkı ruleset. Başlık paritesi 11/11, link locale-eksiz (0 sızıntı), positioning/pazarlama (TR+EN) temiz, güvenlik ipliği korundu (E4 backup at-rest/erişim, F2 KVKK→GDPR→SOC 2), F-blok `## 🔨 Deliverable exercise` başlığı 5/5 tutarlı. QA exit 0 (1 uyarı: önceki turlardan kalan qa.py docs/index.en.md locale-twin false-positive; bu turdan yeni kırık link 0). EN kapsama %10.8 → %14.1. **Sıra: P2 (21 klasör README'si).**

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
| 9 | Düşmanca gözden geçirme | ✅ | **Tamam.** TROUBLESHOOTING 55 madde · REVIEW-FINDINGS 40 bulgu (6 blok) hepsi kapandı (A5·B8·C7·D8·E6·F6; `⬜` yok, `➖` gerekçeli: A-05/B-04/F-06) · GLOSSARY-COVERAGE.md çıkarıldı → açık terim boşluğu 0. Glossary'ye 6 terim (ack/ADR/Alertmanager/Cognitive load/Reserved Instance/Right-sizing). QA exit 0 |
| 9.5 | A0 + geri-dönük düzeltmeler + EN twin | 🟡 | **A0 TAMAM.** **EN twin: P0 ✅ · P1a ✅ · P1b TAMAM ✅ (A+B · C+D · E+F — bu tur)** — bu tur 11 twin: E1–E5 + Blok E STAGE-EXAM (6) · F1–F5 (5, Blok F STAGE-EXAM yok). P1b toplam 35 dosya (30 modül + 5 STAGE-EXAM). Kalan: **P2 (21 klasör README'si)** → P3 (15 deep-dive) → P4 (kalan). EN kapsama %10.8 → %14.1. QA exit 0 (1 uyarı: docs/index.en.md locale-twin false-positive, önceki turlardan; yeni kırık link 0). |

## Sıradaki adım

**Faz 9.5 · EN twin — P2: 21 klasör README'si (`NN-*/README.en.md`).** P0 + P1a (9 rehber)
+ **P1b TAMAM** (A+B 12 · C+D 12 · E+F 11 = 35 dosya) bitti. Sıra **21 konu klasörünün
README twin'leri** (`00-Culture` … `20-Soft-Skills`; bazı numara boş olabilir — `ls -d [0-2][0-9]-*/`
ile gerçek listeyi çıkar, her birinde `README.md` var mı `ls NN-*/README.md` ile doğrula):

1. **Hedef:** her `NN-*/README.md` → `NN-*/README.en.md`. Bu README'ler klasörün "İçindekiler"
   tablosu + kısa giriş; **modül değil** (frontmatter'sız ya da minimal) → qa `MOD_RE` eşleşmez,
   modül bütünlük denetimine girmez. Yine de yapı byte-korunur, yalnız prose + (varsa) frontmatter
   `description` çevrilir.
2. **İç link kuralı (değişmez):** README içindeki deep-dive linkleri locale eki ALMAZ
   (`[x](Kubernetes-Hardening.md)`, `.en.md` DEĞİL). Tablo satırlarındaki relative path'ler kaynakla birebir.
3. **Dilimleme (§14.1.3):** 21 README tek tura sığmayabilir → 2 dilime böl (örn. 00–10, sonra
   11–20). Blok deseni: paralel sonnet subagent, dosya başına bir. Nereye gelindiğini STATE'e
   **klasör-numarası seviyesinde** yaz.
4. **build-docs.sh'e dokunma:** `NN-*` klasörleri zaten `2[0-9]-*` DEĞİL ama `cp -r` ile
   staging'e giriyor mu doğrula (P0'da numaralı klasörler `cp -r` ile stage ediliyordu). Şüphede
   `site_src/NN-*/README.en.md` + `/en/NN-*/` render kontrolü yap; gerekiyorsa **yalnız** stage
   satırı ekle (izinli infra; qa.py/00-21 içeriği değil).
5. **P2 bitince → P3 (en güçlü 15 deep-dive) → P4 (kalan).** Aşama B eşiği (%60) hâlâ uzak.

**P1/P2 taktiği (P0…P1b'de 4 kez işe yaradı):** dosya başına bir çeviri subagent'ı (sonnet), sıkı
ruleset (yapıyı byte-koru, yalnız prose+frontmatter description çevir, hedef path'i locale-eksiz
koru, `{ #anchor }` sabit, positioning reframe, placeholder güvenliği, kod/komut verbatim),
sonra qa.py + iki-locale build + spot-read ile doğrula. Her tur bir dilim bitir,
STATE'e **dosya-seviyesinde** nereye gelindiğini yaz, commit, dur.

> NOT: **L06 starter app ARTIK VAR** (`labs/build/L06-elle-deploy/starter/app.py` +
> `KURULUM.template.md`) — 9.5 listesinden Faz 9'da düşmüştü, hâlâ mevcut.

> NOT: **`README.en.md` iki anlama gelir.** Kök `README.en.md` (bu tur, GitHub landing, P0) ≠
> `22-Learning-Path/README.en.md` (P1, henüz yok). Karıştırma.

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

> ✅ **ÇÖZÜLDÜ (önceki tur açık kararı) — kök `README.en.md` LinkedIn URL'i.** C+D turundaki
> atanmamış `README.en.md` farkı (`.../in/halilibrahimd` → `.../in/halil-ibrahim-durmus/`)
> kullanıcı tarafından commit'lendi: `3c10144 fix(README): update LinkedIn profile link`. Bilinçli
> kullanıcı düzeltmesiymiş → doğru bırakılmış (tahminle commit/geri-al yapmamıştım).
>
> ⚠️ **ATANMAMIŞ DEĞİŞİKLİK — kök `README.md` (TR) (bu turda BENİM işim DEĞİL).** Tur başında
> `git status --porcelain` yalnız ` M README.md` gösterdi: TR README'de aynı LinkedIn düzeltmesi
> (`.../in/halilibrahimd` → `.../in/halil-ibrahim-durmus/`) — yani kullanıcının `README.en.md`'de
> yaptığı düzeltmenin TR eşleniği. Bu değişikliği YAPMADIM (E+F çeviri kapsamı dışı; hiçbir
> subagent'a atanmadı). Kullanıcının kendi profil URL'i + `README.en.md` commit'iyle tutarlı
> olduğu için **tahminle commit ETMEDİM, geri de ALMADIM** — working-tree'de bırakıldı. Bu turun
> commit'i yalnız 13 kendi dosyamı içerir (11 twin + STATE + I18N-COVERAGE). **Sonraki tur
> uyarısı:** `git add -A` ile süpürme; kullanıcı kararı beklenir (bilinçli düzeltme gibi
> görünüyor → kullanıcı ayrı commit'ler, değilse `git checkout -- README.md`).

### Faz 9.5 · EN twin P1b (bu tur — Blok E+F: 11 modül/exam twin'i · P1b TAMAMLANDI)
- **Dilim = Blok E + Blok F (11 dosya) — P1b'nin son dilimi.** §14.1.3 dosya-seviyesi dilim:
  E1–E5 + Blok E STAGE-EXAM (6) · F1–F5 (5). **Blok F'de STAGE-EXAM YOK** (CURRICULUM: "Block F
  doesn't close with an exam") → P1b toplamı = 30 modül + 5 STAGE-EXAM (A–E) = 35 dosya, hepsi
  bitti. A+B (12) · C+D (12) · E+F (11) turlarının kadans deseni birebir. Sıradaki-adım kuralı 3:
  STAGE-EXAM (Blok E'de VAR) blok twin'iyle birlikte alındı.
- **11 paralel çeviri subagent (sonnet), dosya başına bir — A+B/C+D/P1a/P0 deseni tekrar.** Ruleset:
  yapı byte-korunur (başlık sayısı/sıra, tablo, kod bloğu, `<details>`, `---`, blockquote), yalnız
  prose + frontmatter `description` çevrilir; link hedefi locale-eksiz (`[E1](E1-....md)`, `.en.md`
  DEĞİL); modül→lab/modül→modül path'leri kaynakla birebir; komut/YAML/SQL/çıktı verbatim, yalnız
  kod-içi `#` yorum prose'u çevrildi; kanonik blok adları (E→Ownership, F→Judgment); `~N saat`→`~Nh`;
  placeholder EN-kanonik. 11/11 rapor + bağımsız orchestrator doğrulaması: başlık paritesi 11/11
  (10/10/10/11/10/6 · 10/10/10/10/10), link-leak 0, residual TR-başlık 0, pazarlama/positioning (TR+EN) 0.
- **F-blok ortak `## 🔨 Deliverable exercise` başlığı (5/5 tutarlı).** F1–F5'te `## 🔨 Lab` yerine
  `## 🔨 Teslim edilebilir egzersiz` var (F modülleri "sıralayıcı", lab yok — teslim egzersizi
  var). Kanonik H2 haritasında olmayan bu başlık **5 dosyada da** `## 🔨 Deliverable exercise`
  olarak çevrildi (grep 5/5). Teslim dosya adları (`finops-analiz.md`, `tehdit-modeli.md`,
  `golden-path-onerisi.md`, `karar-yazisi.md`) verbatim korundu — öğrencinin ürettiği çıktı, link değil.
- **Güvenlik ipliği korundu (§12.4).** E4 twin'inde "test edilmemiş backup, backup değildir" +
  backup at-rest şifreleme/erişim kontrolü/audit çerçevesi birebir; F2 twin'inde KVKK→GDPR→SOC 2
  regülasyon→kontrol→kanıt zinciri ve STRIDE korundu (KVKK 6 / GDPR 4 / SOC 2 4 geçiş sayısı).
  Blok E STAGE-EXAM'de güvenlik-iplik çerçevesi (Blok D deseni) taşındı.
- **Positioning reframe (EN tarafı):** F2 KVKK "AB-dışı veri koruma rejiminin mühendislik
  kontrolüne çevrilmesi" olarak global okur çerçevesiyle; hiçbir twin "Turkish resource/guide"
  demiyor (grep temiz). F5 vendor tartışması nötr buy-vs-build ödünleşimi (vendor-övgü tonu yok).
- **Modül twin'i qa `check_modules`'ten MUAF (`LOCALE_RE`, qa.py:156).** qa hâlâ "30 modül" sayar
  (twin'ler modül-bütünlük denetimine girmez) — beklenen davranış. build-docs.sh'e dokunulmadı;
  `block-{e,f}-*` twin'leri `2[0-9]-*` `cp -r` ile özyineli stage oluyor (doğrulandı: 11 staged;
  `/en/…/E1-sli-slo-error-budget/` "When you finish this module", `/en/…/F2-tehdit-uyum/`
  "F — Judgment" ile İngilizce render). EN kapsama %10.8 → %14.1 (47 site sayfası / 334).
- **QA'daki 1 UYARI = önceki turlardan kalan `docs/index.en.md` false-positive.** Bu turun 11 twin'i
  **yeni kırık link 0** ekledi; sayı değişmedi (29 kırık link / 1 dosya, birebir aynı).

### Faz 9.5 · EN twin P1b (önceki tur — Blok C+D: 12 modül/exam twin'i)
- **Dilim = Blok C + Blok D (12 dosya).** §14.1.3 dosya-seviyesi dilim: tüm P1b (30 modül +
  5 STAGE-EXAM = 35 dosya) bir tura sığmaz. A+B önceki tur (12); bu tur C+D (12) — önceki turun
  kadans deseniyle birebir. Kalan E+F (11 dosya) = sıradaki tur(lar). C STAGE-EXAM ve D
  STAGE-EXAM blok twin'iyle birlikte alındı (Sıradaki-adım kuralı 3).
- **12 paralel çeviri subagent (sonnet), dosya başına bir — A+B/P1a/P0 deseni tekrar.** Ruleset:
  yapı byte-korunur (başlık sayısı/sıra, tablo, kod bloğu, `<details>`, `---`), yalnız prose +
  frontmatter `description` çevrilir; link hedefi locale-eksiz (`[C1](C1-container.md)`, `.en.md`
  DEĞİL); modül→lab/modül→modül path'leri kaynakla birebir; komut/YAML/HCL/çıktı verbatim,
  yalnız kod-içi `#` yorum prose'u çevrildi; kanonik blok adları (C→Reproducibility,
  D→Orchestration); `~N saat`→`~Nh`; placeholder adları EN-kanonik (`<HEDEF_IP>`→`<TARGET_IP>`).
  12/12 rapor + bağımsız orchestrator doğrulaması: başlık paritesi 12/12 (16/11/10/11/11/6 ·
  12/11/10/10/11/6), link-leak 0, residual TR-başlık 0, pazarlama/positioning (TR+EN) 0.
- **Güvenlik ipliği korundu (§12.4).** D1 "RBAC + NetworkPolicy ilk günden" çerçevesi ve K04
  kırık-lab referansı, D4 "C2 pipeline'ının devamı (ayrı güvenlik dersi değil)" çerçevesi twin'de
  birebir; `/en/…/D1-k8s-temel/` "RBAC + NetworkPolicy" ile render. D2'deki "garanti" teknik
  anlamda ("guarantee" — K8s requests) çevrildi, pazarlama değil.
- **Modül twin'i qa `check_modules`'ten MUAF (`LOCALE_RE`, qa.py:156).** qa hâlâ "30 modül" sayar
  (twin'ler modül-bütünlük denetimine girmez) — beklenen davranış. İngilizce başlık serbest; yine
  de kaynak modülün bölüm iskeleti korundu (residual TR-başlık grep → 0).
- **build-docs.sh'e dokunulmadı** — `block-*` twin'leri `2[0-9]-*` `cp -r` globuyla özyineli stage
  oluyor (doğrulandı: `site_src/22-Learning-Path/block-{c,d}-*/*.en.md` = 12; `/en/…/C2-ci/`,
  `/en/…/D1-k8s-temel/`, `/en/…/STAGE-EXAM/` İngilizce render). A+B'deki gibi ek satır gerekmedi.
- **EN kapsama %7.2 → %10.8** (36 site sayfası / 334). Aşama B eşiği hâlâ %60.
- **QA'daki 1 UYARI = önceki turdan kalan `docs/index.en.md` false-positive.** Bu turun 12 twin'i
  **yeni kırık link 0** ekledi; sayı değişmedi.

### Faz 9.5 · EN twin P1b (önceki tur — Blok A+B: 12 modül/exam twin'i)
- **Dilim = Blok A + Blok B (12 dosya).** §14.1.3 dosya-seviyesi dilim: tüm P1b (30 modül +
  5 STAGE-EXAM = 35 dosya) bir tura sığmaz. A+B = ilk iki blok, birbirine kapalı set; STAGE-EXAM
  twin'leri blok twin'iyle birlikte alındı (Sıradaki-adım kuralı 3). Kalan C/D/E/F = sıradaki tur(lar).
- **12 paralel çeviri subagent (sonnet), dosya başına bir — P0/P1a deseni tekrar.** Ruleset:
  yapı byte-korunur (başlık sayısı/sıra, tablo, kod bloğu, `<details>`, `---`), yalnız prose +
  frontmatter `description` çevrilir; link hedefi locale-eksiz (`[A2](A2-ag-tcp-ip.md)`, `.en.md`
  DEĞİL); `{ #anchor }` sabit; modül→lab/modül→modül path'leri kaynakla birebir; kod/komut/çıktı
  verbatim; **kod-içi yorum prose'u çevrildi** (P1a COST-GUARDRAILS deseni: `# Open PowerShell…`),
  komut token'ı değil; kanonik blok adları (A→Intuition, B→Visibility); `~N saat`→`~Nh`;
  positioning reframe; placeholder güvenliği. 12/12 rapor: başlık paritesi eşit, link ek-siz.
- **Modül twin'i qa `check_modules`'ten MUAF (`LOCALE_RE`, qa.py:156).** Bu yüzden qa hâlâ
  "30 modül" sayar (twin'ler modül-bütünlük denetimine girmez) — beklenen davranış, eksik değil.
  İngilizce başlık serbest; yine de kaynak modülün bölüm iskeleti (🎯/Önce oku/Kabul/Kendini test/
  Takıldıysan/Sırada) korundu, salt prose çevrildi (residual TR-başlık grep → 0).
- **Blok F'de STAGE-EXAM YOK** (CURRICULUM: "Block F doesn't close with an exam"). P1b toplamı =
  30 modül + 5 STAGE-EXAM (A–E) = 35 dosya. Bu tur 12 bitti; kalan 23 (C/D/E/F).
- **build-docs.sh'e dokunulmadı** — `block-*` `2[0-9]-*` `cp -r` globuyla zaten özyineli stage
  oluyor (doğrulandı: `site_src/22-Learning-Path/block-{a,b}-*/*.en.md` = 12; `/en/…/A1-linux-
  temeli/` İngilizce render). P1a'daki gibi ek satır gerekmedi.
- **EN kapsama %3.6 → %7.2** (24 site sayfası / 334). Aşama B eşiği hâlâ %60.
- **QA'daki 1 UYARI = önceki turdan kalan `docs/index.en.md` false-positive** (P0 Açık
  kararlar'da kanıtla açıklandı). Bu turun 12 twin'i **yeni kırık link 0** ekledi; sayı değişmedi.

### Faz 9.5 · EN twin P1a (önceki tur — 9 rehber dosyası)
- **Dilim seçimi = 9 rehber dosyası (P1'in "P1a" alt-dilimi).** §14.1.3 dosya-seviyesi dilim:
  bir turda tüm P1 (9 rehber + 30 modül + 6 STAGE-EXAM) sığmaz. Rehber dosyaları düşük-riskli
  ve kendi içinde kapalı bir set (birbirine + modüllere link verir, modüller henüz twin'lenmedi
  ama link hedefleri locale-eksiz olduğu için plugin fallback ile çözülür) → temiz kesim. Modül
  twin'leri = P1b, sıradaki tur(lar).
- **9 paralel çeviri subagent (sonnet), dosya başına bir — P0 deseni tekrar.** Her subagent'a
  sıkı ruleset: yapıyı byte-koru, yalnız prose + frontmatter `description` çevir, link hedefi
  locale-eksiz kalır (`[x](PLACEMENT.md)`, `.en.md` DEĞİL), `{ #anchor }` sabit, mermaid node
  ID/edge sabit (yalnız subgraph etiketi çevrilir), kod/komut verbatim, positioning reframe,
  placeholder güvenliği. Hepsi rapor etti: link locale-eksiz, yapı korundu.
- **Kanonik EN blok adları (dizin slug'larından):** A Sezgi→**Intuition**, B Görebilmek→
  **Visibility**, C Tekrarlanabilirlik→**Reproducibility**, D Orkestrasyon→**Orchestration**,
  E Sahiplik→**Ownership**, F Karar→**Judgment**. P1b modül twin'lerinde de bunları kullan.
- **`~Ns` süre gösterimi → `~Nh`** (saat=hours). Twin'lerde tüm süre token'ları çevrildi.
- **PORTFOLIO.md frontmatter'sız** (H1 ile başlar) → twin de frontmatter'sız; "boş description"
  bir kusur değil, kaynakla birebir. Diğer 8 dosyanın `description`'ı İngilizce'ye çevrildi.
- **EN kapsama %0.9 → %3.6** (3 P0 + 9 P1a = 12 site sayfası / 334). Rehber twin'leri `2[0-9]-*`
  `cp -r` ile otomatik stage olur → build-docs.sh'e **ek satır gerekmedi** (P0'daki docs/Glossary
  elle-stage istisnasından farklı; onlar `2[0-9]-*` globu dışındaydı). Aşama B eşiği hâlâ %60.
- **QA'daki 1 UYARI = önceki turdan kalan `docs/index.en.md` false-positive** (P0 Açık
  kararlar'da kanıtla açıklandı). Bu turun 9 twin'i **yeni kırık link 0** ekledi; uyarı hâlâ
  tek dosya (`docs/index.en.md`), sayı değişmedi. İçerik kusuru değil.

### Faz 9.5 · EN twin P0 (önceki tur)
- **Blok kalktı — kullanıcı `qa.py`'yi genişletti (§15.4 sınırı korunarak).** `qa.py:156`
  `LOCALE_RE = \.[a-z]{2}\.md$`; `check_modules` (`qa.py:162`) ve `check_curriculum`
  (`qa.py:228`) artık `.en.md`/`.tr.md`'yi modül denetiminden ayırıyor. Ben `qa.py`'ye
  DOKUNMADIM (§15.4 yasak); kullanıcı yaptı + `.local/PAUSE`'u sildi = döngü devam sinyali
  (§14.2). Faz 2'den beri bekleyen EN twin tıkanması böyle çözüldü.
- **Kapsam = P0 (I18N-COVERAGE öncelik sırası).** Bir turda EN twin katmanının tamamı
  (P0…P4, 300+ sayfa) sığmaz → §14.1.3 dosya-seviyesi dilim. P0 = `README`/`docs-index`/
  `docs-about`/`Glossary` — dokümante edilmiş ilk adım. 4 `.en.md` üretildi.
- **`README.en.md` siteye stage EDİLMEZ (bilinçli).** Site homepage'i `docs/index.md`
  (build-docs.sh:7), README değil. `README.en.md` GitHub landing için — kökte, linkleri
  köke göre çözülür (qa temiz). Coverage oranı SİTE sayfası sayar → README dışı (3/334 ≈ %0.9).
- **build-docs.sh 3 satır eklendi (izinli — infra, qa.py değil, 00-21 değil):**
  `docs/index.en.md`→`index.en.md`, `docs/about.en.md`→`about.en.md`, `Glossary.en.md` stage.
  Numaralı klasörler (`cp -r`) zaten tüm `.en.md`'leri özyineli kopyalar → P1'de ek satır gerekmez.
- **QA'daki 1 UYARI = qa.py false-positive, içerik kusuru DEĞİL (§15.1 → buraya not).**
  `check_links` yalnız `docs/index.md`'yi pop eder (`qa.py:140`), locale twin'ini (`docs/index.en.md`)
  etmez. `docs/index.en.md` site-kökü göreli link kullanır (`00-Culture/` vb. — staged konumda
  `$STAGE/index.en.md` için DOĞRU); kaynak `docs/`'a göre çözülünce 29 "kırık" görünür → LP-dışı
  → UYARI (HATA değil, akış durmaz). **Kanıtlandı:** build sonrası `site/en/08-Security/
  DevSecOps-Pipeline/` vb. hedefler VAR; `/en/index.html` İngilizce intro ile render (TR fallback
  değil). Doğru düzeltme: kullanıcı `qa.py:140`'ı `docs/index.<locale>.md` da pop edecek şekilde
  genişletebilir (analog fix). Ben qa.py'ye dokunamam → not bırakıldı.
- **docs/about.en.md ve Glossary.en.md temiz (uyarı yok):** about yalnız `index.md`'ye linkler
  (`docs/index.md` var → çözülür); Glossary'de iç markdown link yok.
- **Positioning reframe uygulandı (Faz -1(b) kuralı EN tarafında):** hiçbir twin "Türkçe
  kaynak/rehber/yazılır" demiyor → "deep TR/EU regulatory coverage olan handbook". KVKK/BDDK
  içeriği kaldı, global okur çerçevesiyle. Grep doğrulaması temiz.
- **Çeviri subagent deseni (P1'de tekrar kullan):** 4 paralel sonnet subagent, dosya başına bir,
  sıkı ruleset (yapı byte-korunur, yalnız prose+frontmatter description çevrilir, link path'i
  ek-siz korunur, `{ #anchor }` id'leri sabit, placeholder güvenliği). README subagent'ı ToC +
  Quick-Start anchor'larını çevrilen başlık slug'ına göre güncelledi (proaktif, doğru).

### Faz 9.5 (önceki tur — A0 + entegrasyon)
- **A0'ın kapsamı = A1'in ÖNÜ, tekrarı değil (kısıt #1).** A1 process/izin/kullanıcı
  derinliğine iner; A0 ondan önceki katmandır: çalışan terminal + ortam + ergonomi +
  oryantasyon. Kurulum adımları tekrar edilmedi → `COST-GUARDRAILS.md`'ye devredildi.
  §14.3(1): 3 özgün A0 cümlesi repo-genelinde grep → yalnız A0. Gezinme bölümü (`pwd/ls/cd`)
  bilinçli **ergonomik** (dolaşmak), A1'in FHS/find/izin derinliğiyle örtüşmez.
- **A0 lab'sız (C0 deseni):** MODULE-SPEC A0'a L## atamaz; pratik = kabul kriterleri (ortamı
  kur + `uname/whoami/nano/man` ile kanıtla). Uydurma lab linki yok. Kabul kriterleri
  doğrulanabilir (komut çıktısı / yazılı cümle) — "anladım" yok (qa öznel-kriter deseni temiz).
- **Süre: A0 = 6s → Blok A 97 → 103, toplam 477 → 483.** §3.5 dürüst tavan: A0 gerçek iş
  (VM kurulumu + terminal alışkanlığı yeni başlayan için saatler alır), düşük gösterilmedi.
  CURRICULUM'daki stale "~453s modül" figürü de bu tur ~423'e düzeltildi (blok toplamı 417→423).
- **DAG: A0 → A1 geriye işaret ediyor** (rank ("A",0) < ("A",1)) → qa `check_modules` ön-koşul
  denetimi temiz. A0 yeni **tek giriş noktası**; CURRICULUM/PLACEMENT "A1 tek giriş" metinleri
  A0'a güncellendi. Developer/sysadmin rampaları A0'ı atlayabilir (ortam zaten var — PLACEMENT'ta yazılı).
- **MODULE-SPEC'e onay-sonrası ek yazıldı (şeffaflık):** STATE "A0 MODULE-SPEC'te işaretli"
  diyordu ama DEĞİLDİ — A0 Faz 9 review turlarında kararlaştırılan onay-sonrası eklemedir.
  Onaylı 28-modül tablosu **yeniden yazılmadı**; alta ayrı "ONAY SONRASI EK" bölümü eklendi
  (gerekçe + tek-satır tablo + süre etkisi). `_planning` dosyası → site/qa etkisi yok.
- **EN twin = §14.2-b tıkanma (kullanıcı-gated).** BUILD-PROMPT §10 program bitti; kalan tek
  iş EN twin ve o qa.py değişikliği olmadan üretilemez. Bu turda A0 (bloke-olmayan iş) bitirildi,
  sonra `.local/PAUSE` oluşturuldu. Loop kill-switch: kullanıcı qa.py'yi genişletip PAUSE'u silince devam.

### Faz 9 kapanışı (önceki tur — Blok E+F + çıktı kapısı)
- **Giriş durumu = limit-break kurtarma.** Önceki tur (`0de0c00 "wip: Faz 9 ara kayıt (limit
  molası)"`) Blok C+D bulgularını (14) düzeltip commit etmiş (REVIEW-FINDINGS C/D ✅) ama
  STATE Faz-durumu tablosunu güncellememişti; ayrıca Blok E+F için **inline düzeltmeleri
  yapıp commit etmeden** bırakmıştı (E1/E2/E4/E5/F1 working-tree'de M). Bu tur o iş
  doğrulandı, tamamlandı ve kapatıldı — yeniden yazılmadı.
- **E-03 prose köprüyle çözüldü (frontmatter değişmedi):** E2 önkoşulu `[E1,B1]` kaldı;
  E2→E1→B2 transitif (E1 prereq=`[B2,D2]`). E2 "Niye bu" bunu açıkça yazar. Frontmatter'a B2
  eklemek MODULE-SPEC/DAG ile ekstra tutarlılık yükü getirirdi; bağımlılık zaten sağlam →
  düşük-risk prose tercih edildi.
- **`bilişsel yük` Glossary'ye EN-anahtarlı girdi (`Cognitive load`, C bölümü):** Glossary
  EN|TR biçimli; kanonik terim Team Topologies'in "cognitive load"u. TR "bilişsel yük"
  açıklamada geçtiği için metin araması bulur; F3 zaten `Team-Topologies.md`'ye linkli.
- **6 yeni Glossary satırı = kısıt #1 ihlali değil:** hepsi tek-cümle tanım (deep-dive
  tekrarı değil); `Glossary.md` zaten 00-21 dışı kök referans dosyası (qa MOD_RE eşleşmez).
  §14.3(1): 3 yeni tanım cümlesi repo-genelinde grep → yalnız `Glossary.md`.
- **GLOSSARY-COVERAGE.md = çıktı kapısı artefaktı** (`_planning`, siteye stage edilmez):
  16 Faz-9 terimi + blok-içi çekirdek terim envanteri; açık boşluk 0. İki-kaynak kuralı
  (inline gloss ve/veya Glossary) belgeli.

### Faz 9 kararları (önceki tur — Blok A+B review)
- **§9 kapsam kararı (A-05/D-08/C-03'te tekrar eder):** Dört-alan dış-kaynak sözleşmesi
  **yönlendirilmiş dış okuma** linkleri içindir. İhtiyaç-anında tekil referans (man page,
  tool wiki, GitHub release sürüm bakışı) muaf — muafiyet A5 modülünde açıkça yazılı
  ("dört-alanlı sözleşme yönlendirilmiş okuma içindir, tekil arama için değil"). İç repo
  "Önce oku" deep-dive linkleri 3-alanlı hafif formatta kalır (§9 "dış link" der). **İstisna
  C-03:** C0'da Python tutorial'ı C-01 nedeniyle fiilen zorunlu → orada 4 alanla verilmeli.
- **B-04 süre — DEĞİŞMEDİ (gerekçeli ➖):** Denetçi B3=12s'i "şişkin" buldu. §3.5 "süreyi
  kısa göstermek güven kaybının en hızlı yolu" — asıl risk DÜŞÜK tahmin; şişkin tahmin
  öğreneni erken bitirince olumlu. Blok toplamı B36 onaylı plan. Süre = modül + lab + yazım
  + acemi tekrarı. Hours düşürülmedi.
- **A-05 ShellCheck linki — DEĞİŞMEDİ (➖):** §9 muafiyeti in-module belgeli (yukarı).
- **A-02 (A6 unit) L06 app.py ile hizalandı:** app `APP_HOST`/`APP_PORT` okur (`DB_URL`
  değil — `pg_isready` defaults kullanır); app.env'e `APP_PORT` eklendi, `DB_URL` "korunan
  sır örneği" olarak kaldı; `ReadWritePaths` yorumlandı (app diske yazmıyor). Unit artık
  birebir kopyalanınca çalışır.
- **B-01 Prometheus kurulumu B2 §3'e eklendi:** node_exporter reçetesinin yanına tam
  systemd Prometheus (config heredoc + `--config.file`/`--storage.tsdb.path`/9090 + servis
  kullanıcısı). "aynı kalıpla kurulur" tek-cümle geçiştirmesi kaldırıldı. Kısıt #1: temel
  kurulum adımları, `Prometheus-Best-Practices.md` deep-dive'ının (naming/retention/recording
  rules) tekrarı DEĞİL — §14.3(1) grep temiz.
- **REVIEW-FINDINGS.md `_planning`'de** (siteye stage edilmez) — 40 bulgu, blok blok, durum
  kolonlu. Faz 9'un canlı iş listesi burası; her tur güncellenir.

### Faz 8 kapanışı (önceki tur)
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

## Bu oturumda yapılanlar (Faz 9.5 — EN twin P1b: Blok E+F, 11 twin · P1b TAMAMLANDI)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, `.local/PAUSE` yok. Giriş HEAD
`3c10144`. Working-tree'de ` M README.md` (kullanıcının LinkedIn TR düzeltmesi — benim işim değil,
bkz. Açık kararlar). Faz -1…9 hepsi ✅; Faz 9.5 sürüyor (A0 ✅, EN twin P0 ✅, P1a ✅, P1b A+B ✅,
P1b C+D ✅); sıradaki iş EN twin P1b Blok E+F (P1b'nin son dilimi).

**Bu tur yapılan (Faz 9.5 · EN twin P1b · Blok E+F dilimi — §14.1.3 dosya-seviyesi · P1b tamam):**
1. **11 EN twin `.en.md` üretildi** (11 paralel sonnet subagent, dosya başına bir, sıkı ruleset):
   - **Blok E (6):** `block-e-ownership/` → `E1-sli-slo-error-budget.en.md` · `E2-alerting-oncall.en.md` ·
     `E3-incident-postmortem.en.md` · `E4-veritabani-restore.en.md` · `E5-chaos.en.md` · `STAGE-EXAM.en.md`.
   - **Blok F (5):** `block-f-judgment/` → `F1-maliyet-finops.en.md` · `F2-tehdit-uyum.en.md` ·
     `F3-platform-idp.en.md` · `F4-yazma-adr-rfc.en.md` · `F5-stakeholder-vendor.en.md` (**STAGE-EXAM yok**).
2. **`_planning/I18N-COVERAGE.md`:** P1b → ✅ TAMAM (A0…F5 + A–E STAGE-EXAM = 35); kapsama %10.8 → %14.1.
3. **build-docs.sh'e dokunulmadı** — `block-*` twin'leri `2[0-9]-*` `cp -r` ile özyineli stage
   oluyor (doğrulandı: `site_src/22-Learning-Path/block-{e,f}-*/*.en.md` = 11).

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0 (1 UYARI).** 30 modül (twin'ler `LOCALE_RE` ile muaf), 49 lab
  scripti, site iki locale hatasız derlendi, `_planning` sızmadı. Tek uyarı = önceki turların
  `docs/index.en.md` false-positive'i (29 kırık link / 1 dosya, birebir aynı); **bu turdan yeni kırık link 0**.
- **Yapısal parite (11/11 OK):** `grep -cE '^#{1,6} '` başlık sayısı kaynak=twin
  (E: 10/10/10/11/10/6 · F: 10/10/10/10/10); link locale-eki grep → 0; residual TR-başlık grep → 0;
  her twin frontmatter `description` var; F-blok `## 🔨 Deliverable exercise` 5/5; metadata blok adı
  E→Ownership / F→Judgment 11/11; positioning + pazarlama (TR+EN) → 0.
- **İki-locale build:** `build-docs.sh` + `mkdocs build --clean` exit 0; 11 twin staged;
  `site/en/…/block-e-ownership/E1-sli-slo-error-budget/` "When you finish this module" ile,
  `…/block-f-judgment/F2-tehdit-uyum/` "F — Judgment" ile İngilizce render; `…/block-e-ownership/
  STAGE-EXAM/` render; `_planning` YOK (0).
- **Spot-read:** `E4-veritabani-restore.en.md` + `F2-tehdit-uyum.en.md` akıcı/sadık — E4 güvenlik
  ipliği (backup at-rest/erişim/audit) + "untested backup is not a backup" korundu; F2 KVKK→GDPR→
  SOC 2 kontrol zinciri + üçüncü-bakış (risk/uyum) çerçevesi korundu; komut/YAML/SQL verbatim.
- **§14.3(1) tekrar:** çeviri (deep-dive rewrite değil); `check_duplication` exit-0'da geçti.
  **§14.3(2):** TR+EN pazarlama/ünvan → 0. **§14.3(3) süre:** yeni modül yok → kümülatif ~483s sabit.

**Değişen dosyalar (bu tur):** `22-Learning-Path/block-e-ownership/{E1-sli-slo-error-budget,
E2-alerting-oncall,E3-incident-postmortem,E4-veritabani-restore,E5-chaos,STAGE-EXAM}.en.md` (6 yeni) ·
`22-Learning-Path/block-f-judgment/{F1-maliyet-finops,F2-tehdit-uyum,F3-platform-idp,F4-yazma-adr-rfc,
F5-stakeholder-vendor}.en.md` (5 yeni) · `_planning/I18N-COVERAGE.md` · `_planning/STATE.md`.
Hepsi patika-içi `.en.md` twin + `_planning`; **hiçbir 00-21 içerik dosyası değişmedi**, `qa.py`'ye
dokunulmadı, `build-docs.sh` değişmedi. (` M README.md` commit'e DAHİL EDİLMEDİ — kullanıcı işi.)

---

## Önceki oturum (Faz 9.5 — EN twin P1b: Blok C+D, 12 twin)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, temiz tree, `.local/PAUSE` yok.
Giriş HEAD `275e2de`. Faz -1…9 hepsi ✅; Faz 9.5 sürüyor (A0 ✅, EN twin P0 ✅, P1a ✅, P1b A+B ✅);
sıradaki iş EN twin P1b Blok C+D.

**Bu tur yapılan (Faz 9.5 · EN twin P1b · Blok C+D dilimi — §14.1.3 dosya-seviyesi):**
1. **12 EN twin `.en.md` üretildi** (12 paralel sonnet subagent, dosya başına bir, sıkı ruleset):
   - **Blok C (6):** `block-c-reproducibility/` → `C0-ops-python.en.md` · `C1-container.en.md` ·
     `C2-ci.en.md` · `C3-terraform.en.md` · `C4-bulut-butce-alarmi.en.md` · `STAGE-EXAM.en.md`.
   - **Blok D (6):** `block-d-orchestration/` → `D1-k8s-temel.en.md` · `D2-k8s-production.en.md` ·
     `D3-secret-yonetimi.en.md` · `D4-supply-chain.en.md` · `D5-gitops-argocd.en.md` · `STAGE-EXAM.en.md`.
2. **`_planning/I18N-COVERAGE.md`:** P1b → 🟡 Blok A+B+C+D ✅ (24) / kalan E+F (11); kapsama %7.2 → %10.8.
3. **build-docs.sh'e dokunulmadı** — `block-*` twin'leri `2[0-9]-*` `cp -r` ile özyineli stage
   oluyor (doğrulandı: `site_src/22-Learning-Path/block-{c,d}-*/*.en.md` = 12).

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0 (1 UYARI).** 30 modül (twin'ler `LOCALE_RE` ile muaf), 49 lab
  scripti, site iki locale hatasız derlendi, `_planning` sızmadı. Tek uyarı = önceki turun
  `docs/index.en.md` false-positive'i; **bu turdan yeni kırık link 0**.
- **Yapısal parite (12/12 OK):** `grep -cE '^#{1,6} '` başlık sayısı kaynak=twin
  (16/11/10/11/11/6 · 12/11/10/10/11/6); link locale-eki grep → 0; residual TR-başlık grep → 0;
  her twin frontmatter `description` var; positioning + pazarlama (TR+EN) → 0.
- **İki-locale build:** `build-docs.sh` + `mkdocs build --clean` exit 0; `site/en/…/block-d-
  orchestration/D1-k8s-temel/` "RBAC + NetworkPolicy" ile, `…/C2-ci/` "When you finish this
  module" ile İngilizce render; `…/block-d-orchestration/STAGE-EXAM/` render; `_planning` YOK (0).
- **Spot-read:** `D1-k8s-temel.en.md` akıcı/sadık — metadata `**Block:** D — Orchestration ·
  **Duration:** ~28h · **Prerequisites:**`; güvenlik ipliği (RBAC/NetworkPolicy "from day one")
  korundu; kod-içi yorum çevrildi, komut/YAML verbatim.
- **§14.3(1) tekrar:** çeviri (deep-dive rewrite değil); `check_duplication` exit-0'da geçti.
  **§14.3(2):** TR+EN pazarlama/ünvan → 0. **§14.3(3) süre:** yeni modül yok → kümülatif ~483s sabit.

**Değişen dosyalar (bu tur):** `22-Learning-Path/block-c-reproducibility/{C0-ops-python,C1-
container,C2-ci,C3-terraform,C4-bulut-butce-alarmi,STAGE-EXAM}.en.md` (6 yeni) ·
`22-Learning-Path/block-d-orchestration/{D1-k8s-temel,D2-k8s-production,D3-secret-yonetimi,D4-
supply-chain,D5-gitops-argocd,STAGE-EXAM}.en.md` (6 yeni) · `_planning/I18N-COVERAGE.md` ·
`_planning/STATE.md`. Hepsi patika-içi `.en.md` twin + `_planning`; **hiçbir 00-21 içerik dosyası
değişmedi**, `qa.py`'ye dokunulmadı, `build-docs.sh` değişmedi.

---

## Önceki oturum (Faz 9.5 — EN twin P1b: Blok A+B, 12 twin)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, temiz tree, `.local/PAUSE` yok.
Giriş `qa.py` exit 0 (30 modül, 1 uyarı = önceki turun docs/index.en.md false-positive'i).
Faz -1…9 hepsi ✅; Faz 9.5 sürüyor (A0 ✅, EN twin P0 ✅, P1a ✅); sıradaki iş EN twin P1b.

**Bu tur yapılan (Faz 9.5 · EN twin P1b · Blok A+B dilimi — §14.1.3 dosya-seviyesi):**
1. **12 EN twin `.en.md` üretildi** (12 paralel sonnet subagent, dosya başına bir, sıkı ruleset):
   - **Blok A (8):** `block-a-intuition/` → `A0-baslamadan-once.en.md` · `A1-linux-temeli.en.md` ·
     `A2-ag-tcp-ip.en.md` · `A3-ag-dns-http-tls.en.md` · `A4-git-temeli.en.md` · `A5-bash.en.md` ·
     `A6-elle-deploy.en.md` · `STAGE-EXAM.en.md`.
   - **Blok B (4):** `block-b-visibility/` → `B1-log-okuma.en.md` · `B2-metrik-prometheus.en.md` ·
     `B3-ilk-kirik-lab.en.md` · `STAGE-EXAM.en.md`.
2. **`_planning/I18N-COVERAGE.md`:** P1b → 🟡 Blok A+B ✅ (12) / kalan C-F (23); kapsama %3.6 → %7.2.
3. **build-docs.sh'e dokunulmadı** — `block-*` twin'leri `2[0-9]-*` `cp -r` ile özyineli stage
   oluyor (doğrulandı: `site_src/22-Learning-Path/block-{a,b}-*/*.en.md` = 12).

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0 (1 UYARI).** 30 modül (twin'ler `LOCALE_RE` ile muaf), 49 lab
  scripti, site iki locale hatasız derlendi, `_planning` sızmadı. Tek uyarı = önceki turun
  `docs/index.en.md` false-positive'i; **bu turdan yeni kırık link 0**.
- **Yapısal parite (12/12 OK):** `grep -cE '^#{1,6} '` başlık sayısı kaynak=twin
  (25/35/35/37/28/26/27/6 · 38/32/24/6); link locale-eki grep → 0; `.tr.md)` grep → 0; residual
  TR-başlık grep → 0; her twin frontmatter `description` var; positioning + pazarlama (TR+EN) → 0.
- **İki-locale build:** `build-docs.sh` + `mkdocs build --clean` exit 0; `site/en/22-Learning-Path/
  block-a-intuition/A1-linux-temeli/` "When you finish this module" ile İngilizce render;
  `site/en/…/STAGE-EXAM/` + B1 render; `_planning` YOK.
- **Spot-read:** `A1-linux-temeli.en.md` akıcı/sadık — metadata `**Block:** A — Intuition ·
  **Duration:** ~16h`; kod-içi yorum çevrildi (`# See the process chain…`, `← your shell`),
  komut/çıktı verbatim (`ps -o pid,ppid,user,comm --forest`).
- **§14.3(1) tekrar:** 3 özgün EN cümle repo-genelinde grep → yalnız kendi twin'i (deep-dive
  rewrite değil; `check_duplication` exit-0'da geçti). **§14.3(2):** TR+EN pazarlama/ünvan → 0.
  **§14.3(3) süre:** yeni modül yok (çeviri) → kümülatif ~483s sabit.

**Değişen dosyalar (bu tur):** `22-Learning-Path/block-a-intuition/{A0-baslamadan-once,A1-linux-
temeli,A2-ag-tcp-ip,A3-ag-dns-http-tls,A4-git-temeli,A5-bash,A6-elle-deploy,STAGE-EXAM}.en.md`
(8 yeni) · `22-Learning-Path/block-b-visibility/{B1-log-okuma,B2-metrik-prometheus,B3-ilk-kirik-
lab,STAGE-EXAM}.en.md` (4 yeni) · `_planning/I18N-COVERAGE.md` · `_planning/STATE.md`. Hepsi
patika-içi `.en.md` twin + `_planning`; **hiçbir 00-21 içerik dosyası değişmedi**, `qa.py`'ye
dokunulmadı, `build-docs.sh` değişmedi.

---

## Önceki oturum (Faz 9.5 — EN twin P1a: 9 rehber dosyası)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, temiz tree, `.local/PAUSE` yok.
Giriş `qa.py` exit 0 (30 modül, 1 uyarı = önceki turun docs/index.en.md false-positive'i).
Faz -1…9 hepsi ✅; Faz 9.5 sürüyor (A0 ✅, EN twin P0 ✅); sıradaki iş EN twin P1.

**Bu tur yapılan (Faz 9.5 · EN twin P1a dilimi — §14.1.3 dosya-seviyesi):**
1. **9 EN twin `.en.md` üretildi** (9 paralel sonnet subagent, dosya başına bir, sıkı ruleset) —
   `22-Learning-Path/` kökündeki rehber dosyaları:
   `NOT-YET.en.md` · `PLACEMENT.en.md` · `PROGRESS-TEMPLATE.en.md` · `STUDY-METHOD.en.md` ·
   `README.en.md` (LP-klasörü README'si, kök README DEĞİL) · `COST-GUARDRAILS.en.md` ·
   `TROUBLESHOOTING.en.md` (57 belirti→sebep→çözüm girdisi korundu) · `PORTFOLIO.en.md` ·
   `CURRICULUM.en.md` (mermaid node/edge sabit, subgraph etiketleri EN, 30 modül satırı korundu).
2. **`_planning/I18N-COVERAGE.md`:** P1 → P1a ✅ (9 rehber) / P1b ⬜ (30 modül) ayrıldı; kapsama
   %0.9 → %3.6 güncellendi.
3. **build-docs.sh'e dokunulmadı** — rehber twin'leri `2[0-9]-*` `cp -r` ile zaten özyineli
   stage oluyor (doğrulandı: `site_src/22-Learning-Path/*.en.md` = 9 dosya).

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0 (1 UYARI).** 30 modül, 49 lab scripti, site iki locale
  hatasız derlendi, `_planning` sızmadı. Tek uyarı = önceki turun `docs/index.en.md` twin
  false-positive'i; **bu turdan yeni kırık link 0**.
- **Yapısal parite:** 9/9 dosyada H1-H3 başlık sayısı kaynak=twin; link locale-eki grep → 0;
  positioning (Turkish-resource) grep → 0; frontmatter `description` İngilizce (PORTFOLIO
  frontmatter'sız, kaynakla birebir); CURRICULUM mermaid 6 subgraph EN + 30 modül satırı.
- **İki-locale build:** `build-docs.sh` + `mkdocs build --clean` exit 0; `site/en/22-Learning-
  Path/CURRICULUM/` İngilizce render ("Block A — Intuition" HTML'de), `_planning` YOK.
- **Spot-read:** `README.en.md` + `STUDY-METHOD.en.md` (dış-kaynak 4-alan tablosu) akıcı,
  sadık, disclaimer/exception'lar korundu.
- **§14.3(1) tekrar:** twin'ler onaylı LP rehber dosyalarının 1:1 İngilizce çevirisi → deep-dive
  rewrite değil; qa `check_duplication` exit-0'da geçti (İngilizce twin TR deep-dive'la örtüşmez).
- **§14.3(2) pazarlama/ünvan:** TR regex + EN scan (`become senior|guaranteed|salary|most
  comprehensive`) twin'lerde → 0.
- **§14.3(3) süre:** yeni modül yok (çeviri) → kümülatif ~483s sabit.

**Değişen dosyalar (bu tur):** `22-Learning-Path/{NOT-YET,PLACEMENT,PROGRESS-TEMPLATE,STUDY-
METHOD,README,COST-GUARDRAILS,TROUBLESHOOTING,PORTFOLIO,CURRICULUM}.en.md` (9 yeni) ·
`_planning/I18N-COVERAGE.md` · `_planning/STATE.md`. Hepsi patika-içi `.en.md` twin +
`_planning`; **hiçbir 00-21 içerik dosyası değişmedi**, `qa.py`'ye dokunulmadı, `build-docs.sh`
değişmedi.

---

## Önceki oturum (Faz 9.5 — EN twin P0)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, temiz tree. **`.local/PAUSE`
SİLİNMİŞ** (kullanıcı = döngü devam sinyali, §14.2). **`qa.py` DEĞİŞMİŞ** — kullanıcı
`LOCALE_RE` (`qa.py:156`) ekleyip `check_modules`/`check_curriculum`'u locale-farkında yaptı →
Faz 2'den beri bekleyen EN twin bloğu kalktı. Giriş `qa.py` exit 0 (30 modül).

**Bu tur yapılan (Faz 9.5 · EN twin P0 dilimi — §14.1.3 dosya-seviyesi):**
1. **4 EN twin `.en.md` üretildi** (4 paralel sonnet subagent, dosya başına bir, sıkı ruleset):
   - `README.en.md` (210s) — kök GitHub landing; positioning reframe (tagline/felsefe bullet1/
     "66K satır Türkçe"→"66K lines"); ToC + Quick-Start anchor'ları çevrilen slug'a güncellendi.
   - `docs/index.en.md` (330s) — EN hero homepage; TR/EN content-tab tek İngilizce paragrafa
     indirildi, `<span class="en">` tagline promote+span silindi, `{ #flagship/#kategoriler/
     #hizli-basla }` id'leri sabit, TR-spesifik kart global çerçeveye alındı.
   - `docs/about.en.md` (151s) — EN about; mevcut İngilizce tab içeriği promote edildi.
   - `Glossary.en.md` (511s, 310 terim) — başlık/intro reframe (Türkçeleştirme felsefesi
     çıkarıldı), tablo başlığı `| Term | Definition |`, TR açıklamalar İngilizce'ye; TR karşılık
     yararlı yerde parantezde kaldı (KVKK/VERBİS TR-regülasyon bağlamı korundu).
2. **build-docs.sh:** `docs/index.en.md`→`index.en.md`, `docs/about.en.md`→`about.en.md`,
   `Glossary.en.md` stage satırları eklendi (izinli infra; qa.py/00-21 değil).
3. **I18N-COVERAGE.md:** P0 ✅ (2026-07-23), P1 "sıradaki/BLOKE değil", EN oran %0.9 notu.

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0 (1 UYARI).** 30 modül, 49 lab scripti, site iki locale
  hatasız derlendi, `_planning` sızmadı. Tek uyarı = `docs/index.en.md` locale-twin
  false-positive (yukarı Açık kararlar'da kanıtla açıklandı; içerik kusuru değil).
- **Site kanıtı:** `site/en/index.html` İngilizce intro ile render (TR fallback DEĞİL);
  `site/en/{about,Glossary}/` üretildi; EN homepage'in site-kökü göreli linkleri (`08-Security/
  DevSecOps-Pipeline/` vb.) `site/en/…`'de gerçek hedeflere çözülüyor.
- **§14.3(1) tekrar:** `.en.md` twin'ler İngilizce → TR deep-dive'larla `check_duplication`
  örtüşmesi yok (qa temiz). P0 dosyaları LP-dışı zaten duplication denetimine girmez.
- **§14.3(2) pazarlama/ünvan:** twin'lerde "Türkçe kaynak/written in turkish" grep → 0;
  `.en.md` link'lerinde locale eki grep → 0.
- **§14.3(3) süre:** yeni modül yok (çeviri) → kümülatif ~483s sabit.

**Değişen dosyalar (bu tur):** `README.en.md` (yeni) · `docs/index.en.md` (yeni) ·
`docs/about.en.md` (yeni) · `Glossary.en.md` (yeni) · `scripts/build-docs.sh` ·
`22-Learning-Path/_planning/I18N-COVERAGE.md` · `22-Learning-Path/_planning/STATE.md`.
Hepsi kök `.en.md` twin + docs + infra + `_planning`; **hiçbir 00-21 içerik dosyası değişmedi**,
`qa.py`'ye dokunulmadı.

---

## Önceki oturum (Faz 9.5 — A0, KISMEN → PAUSE)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, PAUSE yok, temiz tree,
`qa.py` exit 0 (29 modül). Faz -1…9 hepsi ✅; sıradaki iş Faz 9.5 (A0 + EN twin).

**Bu tur yapılan (§10 sonrası STATE-ek Faz 9.5 · A0 parçası):**
1. **A0 modülü yazıldı** — `block-a-intuition/A0-baslamadan-once.md` (330s, TR, öğretici).
   İçerik: DevSecOps'un şekli · ortam kur (4 parça, COST-GUARDRAILS'e devir) · terminal
   ergonomisi (prompt/`$`↔`#`/Ctrl-C/D/L/Tab/history/kopyala-yapıştır güvenliği) · gezinme
   minimumu (5 komut) · yardım (`--help`/`man`/hata okuma) · nano · patika kullanım kılavuzu.
   Anti-pattern tablosu (8 satır) + doğrulanabilir kabul kriterleri + 3 kendini-test + Takıldıysan.
2. **Entegrasyon (5 dosya):** A1 önkoşulu `[A0]` + "Ön koşul" satırı · CURRICULUM (tablo satırı
   + mermaid `A0-->A1` + toplam 30 modül/~483s + "A0 tek giriş" + description 30) · README
   (yeni-mezun rampası A0 + `A0…F5` + ~483s) · PLACEMENT (rampa tablosu + "emin değilsen A0") ·
   COST-GUARDRAILS başlık `A0/A1`.
3. **MODULE-SPEC onay-sonrası ek** (şeffaflık — A0 review eklemesidir, onaylı 28'in dışı).
4. **`.local/PAUSE` oluşturuldu** — EN twin qa.py-bloke; kullanıcı müdahalesi bekleniyor.

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0.** 30 modül (A0 eklendi), 49 lab scripti `bash -n`, kırık
  iç link yok (A0'ın 5 iç linki + A1↔A0 dahil), site iki locale derlendi, `_planning` sızmadı.
- **İki-locale build:** `build-docs.sh` + `mkdocs build --clean` exit 0; A0 TR'de render, EN
  fallback'te var, `site/`'te `_planning` YOK.
- **§14.3(1) tekrar:** 3 özgün A0 cümlesi grep → yalnız A0 (deep-dive tekrarı yok, kısıt #1).
- **§14.3(2) pazarlama/ünvan:** A0 grep → 0 hit.
- **§14.3(3) süre:** A0=6s; Blok A frontmatter toplamı = 103 (6+16+14+16+12+12+27), CURRICULUM
  ile tutuyor. Kümülatif 477 → 483.

**Değişen dosyalar (bu tur):** `block-a-intuition/A0-baslamadan-once.md` (yeni) ·
`block-a-intuition/A1-linux-temeli.md` (önkoşul) · `CURRICULUM.md` · `README.md` ·
`PLACEMENT.md` · `COST-GUARDRAILS.md` · `_planning/MODULE-SPEC.md` · `_planning/STATE.md` ·
`.local/PAUSE` (yeni). Hepsi patika içi (00-21 değil) + `_planning` + PAUSE.

---

## Önceki oturum (Faz 9 — Blok E+F + çıktı kapısı, KAPANDI)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, PAUSE yok. `qa-report.txt`
GEÇTİ ama bayat (son commit sonrası). Working tree'de 5 dosya `M` (E1/E2/E4/E5/F1) —
`0de0c00 "wip: Faz 9 ara kayıt (limit molası)"` turunun **commit edilmemiş** Blok E+F inline
düzeltmeleri. Diff okundu: E-01/E-02/E-04/E-05/E-06 + F-01/F-04 inline zaten uygulanmış; eksik =
Glossary satırları + GLOSSARY-COVERAGE.md + REVIEW-FINDINGS/STATE güncellemesi.

**Bu tur yapılan (§10 Faz 9 kapanışı):**
1. **Glossary'ye 6 terim** (eksik olanlar; grep'te `ack`→Backstage, `ADR`→CIDR/adres,
   `NAT`→alternatifi false-positive'leri elenerek doğrulandı): A bölümü `ack`/`ADR`/
   `Alertmanager`, C bölümü `Cognitive load` (bilişsel yük), R bölümü `Reserved Instance (RI)`/
   `Right-sizing`. `egress`/`NAT`/`burn rate` zaten vardı (C-07/prev), `semver`/`LocalStack`/
   `kind`/`k3s`/`Taint`/`Free tier`/`ICMP` de.
2. **E+F inline düzeltmeleri doğrulandı/kapatıldı:** E-01 (Alertmanager tanım), E-02 (E4 şema
   kabul kriteri), E-03 (E2 prose B2 köprü), E-04 (E1 burn-rate köprü), E-05 (ack gloss),
   E-06 (E5 kabul#3 yumuşatma), F-01 (F1 grep→yazılı "İş tarafı" paragrafı), F-04 (F1 Capstone
   linkleri). REVIEW-FINDINGS E/F blokları `✅`, gerekçeli `➖`: F-06.
3. **`_planning/GLOSSARY-COVERAGE.md` çıkarıldı** (Faz 9 çıktı kapısı) — 16 terim + blok-içi
   çekirdek envanteri, açık boşluk 0.
4. **REVIEW-FINDINGS.md kapanış özeti** (A5·B8·C7·D8·E6·F6, `⬜`=0) + GLOSSARY-COVERAGE gate ✅.

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0.** 29 modül, 49 lab scripti `bash -n`, kırık iç link yok,
  site iki locale derlendi, `_planning` sızmadı.
- **§14.3(1) tekrar:** yeni prose (E1/E2 köprü) + 6 Glossary tanımı → grep repo-genelinde
  yalnız kendi dosyasında; deep-dive tekrarı yok (kısıt #1).
- **§14.3(2) pazarlama/ünvan:** 22-LP grep → yalnız önceden-kabul teknik "garanti" (D2/L14/K05
  `requests`). Yeni pazarlama 0. Geniş tarama (`maaş|ROI|%..artış|en kapsamlı`) temiz.
- **§14.3(3) süre:** yeni modül yok (mevcut E/F modüllerine kısa ekleme + Glossary) →
  kümülatif ~477s sabit.

**Değişen dosyalar (bu tur):** `Glossary.md` · `block-e-ownership/E1,E2,E4,E5` ·
`block-f-judgment/F1` (limit-break'ten devralınan inline'lar + bu tur) · `_planning/REVIEW-
FINDINGS.md` · `_planning/GLOSSARY-COVERAGE.md` (yeni) · `_planning/STATE.md`. `Glossary.md` =
00-21 dışı kök referans (qa MOD_RE eşleşmez); `block-*` = patika içi (00-21 değil).

---

## Önceki oturum (Faz 9 — Blok A+B düşmanca review, KISMEN)

**Giriş durumu:** Faz 8 önceki tur kapanmıştı. `e47d703 "wip: ara kayıt"` commit'i Faz 9'u
başlatmış (TROUBLESHOOTING 55 madde + dağınık modül/verify.sh rötuşları) ama REVIEW-FINDINGS
oluşturmamış ve STATE'i güncellememişti. Bu tur giriş kontrolü: `qa.py` exit 0, PAUSE yok,
branch `feat/learning-path`, temiz tree. TROUBLESHOOTING dolu (55 madde > 40 kapısı) doğrulandı.

**Bu tur yapılan (§10 Faz 9 — yeni başlayan simülasyonu):**
1. **6 paralel "yeni başlayan" denetçisi** (blok başına biri) A1→F5 sırayla okudu; 40 bulgu
   çıktı → `_planning/REVIEW-FINDINGS.md` (8 kategori, önem sıralı, durum kolonlu).
2. **Blok A düzeltildi (5 bulgu):** A-01 COST-GUARDRAILS'e somut Linux kurulum bölümü
   (WSL2/Multipass/VirtualBox); A-02 A6 systemd unit L06 app.py ile hizalandı (kopyalayınca
   çalışır); A-03 A4 `cherry-pick` (öğretilmemiş) → `reset --soft`+`switch`; A-04 ICMP gloss
   + Glossary; A-05 ➖ (§9 muafiyeti belgeli).
3. **Blok B düzeltildi (8 bulgu):** B-01 B2 §3'e tam Prometheus systemd kurulumu; B-02 L08
   Görev 1'e systemd-atlama notu; B-03 node_exporter/Prometheus indirmesi `uname -m`→ARCH
   (arm64 tuzağı); B-05 §5 app-metrik sorgusuna "şimdi no-data" notu; B-06 systemd-tmpfiles
   gloss; B-07 B1 yanlış "K00/K01 disk-dolu" iddiası genelleştirildi; B-04/B-08 ➖ (gerekçe
   Açık kararlar'da).
4. **Glossary.md:** `ICMP` eklendi (A-04). (semver/LocalStack/kind/k3s/NAT/egress/Alertmanager/
   ack/ADR… ilgili blok turlarında eklenecek — REVIEW-FINDINGS'te izli.)

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0.** 29 modül, 49 lab scripti `bash -n`, kırık iç link yok
  (COST-GUARDRAILS→A1 yeni linki dahil), site iki locale derlendi, `_planning` sızmadı.
- **§14.3(1) tekrar:** yeni prose (Prometheus kurulum, Linux setup, glosslar) → 3 özgün cümle
  repo-genelinde grep, yalnız kendi hedef dosyasında. Deep-dive tekrarı yok (kısıt #1).
- **§14.3(2) pazarlama/ünvan:** 22-LP grep → yalnız önceden-kabul teknik "garanti" (K05/L14
  `requests`). Yeni pazarlama 0.
- **§14.3(3) süre:** yeni modül yok (mevcut A/B modüllerine ekleme) → kümülatif ~477s sabit.

**Değişen dosyalar (bu tur):** `_planning/REVIEW-FINDINGS.md` (yeni) · `COST-GUARDRAILS.md` ·
`Glossary.md` · `block-a-intuition/A2,A4,A6` · `block-b-visibility/B1,B2` ·
`labs/build/L08-metrik/README.md` · `_planning/STATE.md`. **`Glossary.md` = 00-21 dışı kök
dosya** (patika terimleri; qa MOD_RE eşleşmez). **`block-*`/`labs` = patika içi** (00-21 değil).

---

## Önceki oturum (Faz 8 — Entegrasyon, KAPANDI)

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
