# REVIEW-FINDINGS — Faz 9 Düşmanca Gözden Geçirme ("yeni başlayan simülasyonu")

> BUILD-PROMPT §10 Faz 9. Rol: DevSecOps hakkında hiçbir şey bilmeyen biri, A1'den
> sırayla okur. Her modülde 8 kategori taranır: (a) tanımsız terim · (b) öğretilmemiş
> varsayım · (c) öznel kabul kriteri · (d) ölü link/doğrulanamayan lab · (e) gerçekçi
> olmayan süre · (f) açıklanmamış sıçrama · (g) dış kaynak §9 4-alan ihlali · (h) güvenlik
> ipliği kopuk (D/E).

**Yöntem:** her blok için ayrı bir "yeni başlayan" denetçisi, yalnız kendi bloğunu +
önceki blokların öğrenme hedeflerini bilerek okudu. Bulgular önem sırasına göre.

**Durum kodları:** `✅ düzeltildi` · `⬜ açık` · `➖ değişiklik yok (gerekçeli)`

**Bu tura kadar:** TROUBLESHOOTING.md 55 maddeye dolduruldu (§10 "40+ madde" kapısı geçti).

---

## Blok A (A1–A6) — düzeltildi bu tur

| ID | Kat | Yer | Bulgu | Karar | Durum |
|---|---|---|---|---|---|
| A-01 | b/d | A1:31 → COST-GUARDRAILS | A1 "Linux kurulum yolu COST-GUARDRAILS'de" der ama o dosyada gerçek kurulum adımı yoktu (tek tablo hücresi) — sıfır ön bilgili okuyucu ortamı kuramaz. | COST-GUARDRAILS'e WSL2/Multipass/VirtualBox somut kurulum bölümü eklendi. | ✅ |
| A-02 | b/d | A6:158-159 | §4 systemd unit'i `WorkingDirectory=/opt/app`+`ExecStart=/opt/app/app` kullanıyor; §3 uygulamayı `/opt/lab-app/app.py`'e koyup `python3 app.py` ile çalıştırıyor → birebir kopyalayan öğrencide `systemctl start` patlar. `ReadWritePaths=/opt/app/data` hiç yaratılmıyor. | Unit §3+L06 app.py ile hizalandı: `/opt/lab-app`, `python3 app.py`; app diske yazmadığı için `ReadWritePaths` yorumlandı; app.env `APP_PORT` de içeriyor. | ✅ |
| A-03 | a | A4:299 | Takıldıysan "yanlış branch'e commit" kurtarması `git cherry-pick` öneriyor ama cherry-pick modülde hiç öğretilmedi. | Kurtarma yalnız öğretilen komutlarla (`reset --soft`+`switch`) yeniden yazıldı. | ✅ |
| A-04 | a | A2:255 (Glossary) | `ICMP` ilk kez tanımsız kullanılıyor; Glossary'de yoktu. | A2'de tek cümle gloss + Glossary'ye `ICMP` satırı. | ✅ |
| A-05 | g | A5:261 | ShellCheck wiki dış linki §9 4 alanını doldurmuyor. | Modül §9 muafiyetini açıkça yazıyor ("dört-alanlı sözleşme yönlendirilmiş okuma içindir, tekil arama için değil"). §9 kapsam kararı: yönlendirilmiş okuma = 4 alan; ihtiyaç-anında tekil referans (man/wiki/release) muaf, in-module belgeli. | ➖ |

## Blok B (B1–B3) — düzeltildi bu tur

| ID | Kat | Yer | Bulgu | Karar | Durum |
|---|---|---|---|---|---|
| B-01 | b/f | B2:106-109 | Prometheus'un kendisi "aynı kalıpla kurulur" tek cümlesiyle geçiştiriliyor; oysa config dosyası + `--storage.tsdb.path` + 9090 + web UI node_exporter'dan farklı. Blok A dışında bilgisi olmayan biri Prometheus'u ayağa kaldıramaz. | B2 §3'e tam systemd Prometheus kurulum adımları eklendi (prometheus.yml + unit + servis kullanıcısı + config/storage bayrakları). | ✅ |
| B-02 | b | B2:108-109 → L08 | İşaret edilen L08 lab'ının ilk görev adımı `docker compose up -d` (henüz C1'de öğrenilmemiş araç). | L08 README zaten "asıl yol systemd / hızlı yol isteğe bağlı docker" olarak çerçevelenmiş (wip commit); Görev 1'e systemd kullanıcısı için atlama notu eklendi. | ✅ |
| B-03 | b | B2:84,86 | node_exporter indirme komutu `linux-amd64` sabit; Apple Silicon'da Multipass arm64 VM üretir → "exec format error". | `uname -m`'den ARCH türetilerek amd64/arm64 otomatik seçildi. | ✅ |
| B-04 | e | B3:5 | B3 `estimated_hours: 12`; denetçi ~4-5s tahmin etti (2-3x şişkin). B1/B2 de 12. | Değiştirilmedi: §3.5 "süreyi kısa göstermek güven kaybının en hızlı yolu" — asıl risk düşük tahmin; şişkin tahmin öğreneni erken bitirince olumlu. Blok toplamı (B36) onaylı plan. Süre = modül + lab + yazım + acemi tekrarı. | ➖ |
| B-05 | b | B2:144 | §5 "dene" sorgusu `rate(http_requests_total{status="500"}[5m])` app exporter'ı olmadan "no data" verir; açıklama bir bölüm sonra. | İnline not güçlendirildi: "şimdi 'no data' — uygulama exporter'ı E1'de". | ✅ |
| B-06 | a | B1:269 | `systemd-tmpfiles --create` ne yaptığı açıklanmadan reçete olarak veriliyor. | Tek cümle gloss eklendi. | ✅ |
| B-07 | b/d | B1:128-129 | "dolu disk ... K00/K01 kırık lab'larının klasik kök sebeplerinden" — K01 gerçekte port çakışması, K00 eksik EnvironmentFile; yanlış + spoiler + tanımsız ileri-referans. | Belirli lab kodu kaldırıldı, genel ifadeye çevrildi. | ✅ |
| B-08 | g | B2:81-84 | "resmi release'teki güncel sürümü yaz" — sürüm bulma çerçevesiz. | B-01/B-03 düzeltmesiyle sürüm+mimari bulma somutlaştı; §9 muafiyeti (A-05) tekil-referans için geçerli. | ✅ |

---

## Blok C (C0–C4) — düzeltildi bu tur

| ID | Kat | Yer | Bulgu | Karar | Durum |
|---|---|---|---|---|---|
| C-01 | b/f | C0:31-36,78-91 | C0 Bash-only öğrenciye Python sözdizimini (`with`, dict, f-string, argparse) öğretmeden "dışarı çıkmadan lab'ı yapabilirsin" diyor; tek gerçek kaynak (resmi tutorial) "isteğe bağlı". | C0 gövdesine **"🧩 Python sözdizimi — Bash'ten gelenler için"** köprü bölümü eklendi (6-satır Bash↔Python tablo + `with`/girinti). Repoda Python doküman yok → kısıt #1 case(a). İddia artık dürüst: köprü+örnek lab'a yeter. | ✅ |
| C-02 | a | C2:41,53 | `semver` tanımsız; Glossary'de yok. | C2 kabul kriterine inline gloss (`MAJOR.MINOR.PATCH`, ör. `1.4.2`) + Glossary `semver`. | ✅ |
| C-03 | g | C0:33-35 | `docs.python.org/3/tutorial` referansı 4 alanı inline doldurmuyor, sorumluluğu okuyucuya devrediyor; C-01 nedeniyle fiilen zorunlu kaynağa "isteğe bağlı" diyor. | Tutorial 4-sütun tablo satırına çevrildi (niye/ne/süre/dönüş doğrulaması); köprü eklendiği için statü artık gerçekten **opsiyonel** ve öyle etiketli. | ✅ |
| C-04 | a | C3:32 | `LocalStack` ilk geçişte tanımsız; Glossary'de yok. | C3 Lab satırına gloss ("AWS servislerini yerelde taklit eden öykünücü") + Glossary `LocalStack`. | ✅ |
| C-05 | b | C0:52,128 | Kendini-test Q3 "pipeline dostu" — CI/pipeline C2'de (C0'dan sonra) öğretiliyor. | Q3'e "(CI'ı C2'de göreceksin — şimdilik 'her commit'te otomatik çalışan komut dizisi' kadarını bil)" ileri-referans notu + C2 linki. | ✅ |
| C-06 | c | C4:52 | Son kabul kriteri "VPC/IAM/compute kavramlarını kendi cümlelerinle tanımlayabiliyorsun" — yazılı kanıt şartı yok (öznel); L12 lab bunu `report.txt`'e yazdırıyor, modül kriteri lab'dan gevşek. | Kriter "...kendi cümlelerinle **yazdın** (L12 `report.txt` — verify.sh üçünü de arar)" biçimine çevrildi; L12 verify.sh:27-30 ile hizalı. | ✅ |
| C-07 | a | C4:51,72 | `NAT`/`egress`/`free tier` tanımsız (Glossary'de NAT/egress yok). | free tier (kabul kriteri) + egress (Takıldıysan) inline gloss; Üç-bulut-temeli Glossary pointer'ına eklendi; Glossary `NAT`/`egress`/`Free tier`. | ✅ |

## Blok D (D1–D5) — düzeltildi bu tur — güvenlik ipliği kritik

| ID | Kat | Yer | Bulgu | Karar | Durum |
|---|---|---|---|---|---|
| D-01 | h/d | D1:54 + L13 networkpolicy.yaml + L13 verify.sh:33 | D1'in "ilk günden NetworkPolicy — yetkisiz erişimin kesildiğini göster" kabul kriteri fiilen doğrulanmıyor: L13 starter "kindnet NetworkPolicy uygular" diye koşulsuz iddia ediyor (sürüm-bağımlı; klasik kindnet zorlamaz, Calico gerekir), verify.sh yalnız report.txt'te "engellendi" kelimesi grep'liyor. Engelleme no-op olsa da lab geçer. | **L13 verify.sh'a guard'lı CANLI kontrol eklendi:** default-deny NP + hazır `lab-svc` endpoint varsa, izinsiz bir busybox probe'u `wget --timeout=3` ile servise erişmeyi dener; **ERİŞİRSE (`REACHED`) `verify.sh` hata verir** — no-op policy artık geçmez. starter/networkpolicy.yaml yorumu CNI sürüm-bağımlılığını + Görev 4 doğrulamasını + "bağlantı açıksa kind güncelle / Calico kur" yolunu anlatır. Cluster yoksa `⚠️` ile atlanır (`bash -n` temiz). | ✅ |
| D-02 | h/f | D4:16-17 vs :39; L16 | D4 🎯 "cluster yalnızca imzalı image kabul eder" der ama kabul kriteri yalnız "niçin reddetmeli — yazılı gerekçe"ye iniyor; L16 yalnız `cosign sign/verify` yapıp cluster tarafını atlıyor. Admission controller/Kyverno A–D'de hiç öğretilmiyor. | 🎯 kabul kriteriyle uyumlandı ("imzasız/taranmamış image'ı cluster'ın niçin ve **nerede — admission aşamasında** — reddetmesi gerektiğini açıklarsın"); **🚪 admission köprüsü** bloğu eklendi (imza pipeline'da üretilir, admission controller'da zorlanır; politikayı kurmak policy-as-code); "Önce oku"ya `Policy-as-Code-OPA-Kyverno.md`. Takıldıysan satırı zaten Kyverno/Gatekeeper diyor. Lab'a admission eklenmedi (§4.5 NOT-YET: politika-as-code ayrı derinlik) — kavram + gerekçe verildi. | ✅ |
| D-03 | h/a | D1:27-35 (🌉 Köprü) | Köprü Pod/Deployment/Service/Ingress'e kavram veriyor ama modülün kimliği olan RBAC ve NetworkPolicy'ye köprü yok — bu iki kavramın modül-içi tek varlığı bir okuma linki + kabul kriteri. | 🌉 Köprü başlığı "+ RBAC + NetworkPolicy" oldu; ikisine Pod/Service ile eşit ağırlıkta tanım: **RBAC** = "kim neyi yapabilir → Role (kaynak+fiil) + RoleBinding, en az yetki, `cluster-admin` dağıtma"; **NetworkPolicy** = "Pod-arası güvenlik duvarı; default-deny ile kes, sonra gerekeni açıkça aç". | ✅ |
| D-04 | a | D1:23,44,80; D5:32 (Glossary) | `kind` (ve `k3s`) açılımsız/tanımsız; Glossary'de yok; İngilizce "kind" ile karışıyor. | D1 "Niye bu" kısmına inline tanım: "kind = *Kubernetes-in-Docker*: Docker konteynerlerinin içinde çalışan yerel tek-makine cluster"; Glossary'ye `kind` + `k3s`. D5:32 "kind" D1 tanımından sonra geldiği için ek gloss gerekmez. | ✅ |
| D-05 | d/f | D2:42; L14 | D2 kabul kriteri "drain'de en az bir replica ayakta — kanıt" ister; L14 yalnız `kubectl get pdb` yaptırıyor (gerçek drain yok); tek-node kind'de gerçek drain sorunlu. | D2 PDB kriteri "yazılı açıkla"ya hizalandı: `get pdb` `ALLOWED DISRUPTIONS` gösteriyor + PDB'nin en az bir replica'yı niçin ayakta tuttuğunu `min-available`/`maxUnavailable` üzerinden **yazılı** anlat (tek-node kind'de gerçek drain yapılamaz notu açık). L14 çok-node'a zorlanmadı — kriter labla tutarlı. | ✅ |
| D-06 | f | D1:6,13,21 | D1 önkoşulu frontmatter'da `[C1,C2,C3]` ve anlatı C3/C4'e yaslanıyor; MODULE-SPEC+DAG `[C1,C2]` diyor ve D1 "bulut/para gerekmez". C3 gerekçesiz sert önkoşul, spec ile çelişki. | Önkoşul `[C1,C2,C3]` → **`[C1,C2]`** (frontmatter + "Blok/Süre/Ön koşul" satırı; MODULE-SPEC/DAG uyumu); "Niye bu" C1/C2'ye dayandırıldı, C3/C4 zorunluluğu kaldırıldı ("C3/C4'ün bulut/Terraform'u burada ön koşul değil; istersen sonra bağlarsın"). | ✅ |
| D-07 | b | D1:33,65,74 | Ingress'in çalışması için ingress controller gerektiği söylenmiyor; `taint/toleration` tanımsız. | Ingress tanımına not: "kural tek başına yetmez — trafiği fiilen karşılayan bir **ingress controller** (ör. ingress-nginx) kurulu olmalı; yoksa kural yazılıdır ama kimse uygulamaz". Pending satırına taint/toleration tek-cümle gloss + Glossary `Taint/Toleration`. | ✅ |
| D-08 | g | D1–D5 "Önce oku" | Dış link yok (ihlal yok); ama "Önce oku" tabloları 3 alanlı, §9'un "dönünce doğrulama" disiplini iç okumalara taşınmamış. | STUDY-METHOD §9'a **iki istisna açıkça yazıldı**: (1) ihtiyaç-anında tekil referans (man/wiki/release) muaf, (2) repo-içi "Önce oku" deep-dive linkleri 3 alanla yeter — "dönünce doğrulama"yı modülün **kabul kriterleri** yapar. A-05/C-03 kararı artık merkezi belgeli (yalnız A5 modülünde değil). | ✅ |

## Blok E (E1–E5) — düzeltildi bu tur

| ID | Kat | Yer | Bulgu | Karar | Durum |
|---|---|---|---|---|---|
| E-01 | b | E2:35,18 | `Alertmanager` kabul kriterinde kanıt aracı olarak isteniyor ama A–D'de öğretilmemiş, Glossary'de yok, modülde tanımsız (ilk tanım L19'da). | E2 kabul kriterine inline tanım eklendi ("Prometheus'un alarmları gruplayan/yönlendiren/susturan bileşeni; L19'da kurarsın") + `Glossary.md` A bölümüne `Alertmanager`. | ✅ |
| E-02 | f | E4:18 | Hedef #3 "sıfır kesintili şema değişikliği" ilan edilip okuma veriliyor ama hiçbir kabul kriteri/test/lab sınamıyor (öksüz çıktı). | E4 kabul kriterlerine yazılı kriter eklendi: sıfır-kesintili şema değişiminin niçin çok-adımlı/sıralı yapıldığını (ekle→çift-yaz→doldur→at) bir cümleyle yazılı açıkla. Hedef artık öksüz değil. | ✅ |
| E-03 | b | E2:6,13 | Önkoşul `[E1,B1]`; E2 baştan sona PromQL üstüne kurulu, gerçek metrik önkoşulu B2 yalnız dolaylı. | Prose köprü: E2 "Niye bu" bölümü alarm kurallarının **B2'de kurulan Prometheus/PromQL üstüne** yazıldığını ve E1'in zaten B2'yi ön koşul saydığını (`E1 prereq = [B2,D2]` → E2→E1→B2 transitif) açıkça yazar. Frontmatter değişmedi (MODULE-SPEC/DAG uyumu korunur); bağımlılık zinciri zaten sağlam. | ✅ |
| E-04 | f | E2:41 | Kendini-test #1 "burn rate" muhakemesi ister ama E1 yalnız statik aylık bütçe öğretti; burn rate metinde tanımsız (yalnız Glossary'de). | E1 "Niye bu" bölümüne tek-cümle burn-rate köprüsü ("bütçe ne kadar hızlı tükeniyor = yakma hızı, normal hızın kaç katı"); E2 zaten burn rate'e dayanıyor. `Glossary.md` Burn rate vardı. | ✅ |
| E-05 | a | E2:48,58 | `ack`/`ack'lenmezse` tanımsız; Glossary'de yok. | E2 Cevaplar bölümüne inline gloss ("ack = alarmı gördüm/üstleniyorum onayı") + `Glossary.md` A bölümüne `ack`. | ✅ |
| E-06 | c/f | E5:39 vs 45-51 | Kabul #3 "en az bir zayıflık eylem maddesine çevrildi" zorunlu; modülün kendi ilkesi (K09: "hiçbir şey bozulmayan game day başarısız değildir") tersini öğretiyor — çelişki. | Kriter yumuşatıldı: "bir zayıflık eylem maddesine/alarma çevrildi **ya da** (zayıflık çıkmadıysa) doğrulanan dayanıklılığın hangi kanıtla izlendiği yazıldı". Çelişki kalktı; her iki game day sonucu da geçerli çıktı üretir. | ✅ |

## Blok F (F1–F5) — düzeltildi bu tur

| ID | Kat | Yer | Bulgu | Karar | Durum |
|---|---|---|---|---|---|
| F-01 | c/d | F1:45 | Kabul #4 (iş dilinde savunma) `grep -c "" finops-analiz.md` "boş değil" ile doğrulanıyor — alakasız tek satır bile geçer (öznel kriter objektif kılıfında). | `grep -c` kaldırıldı; kriter yazılı-artefakt kontrolüne çevrildi: `finops-analiz.md` içinde **ayrı bir "İş tarafı" paragrafı** (aylık maliyet + kesinti/risk sonucu, yalnız teknik terim değil). Objektif kılıf düştü, gerçek yazılı çıktı kaldı. | ✅ |
| F-02 | a | F1:16,35 (Glossary) | `egress` F1 maliyet ekseni + kabul kriteri kalemi ama Glossary'de yok, ana metinde glose edilmiyor. | `Glossary.md` E bölümünde `egress` (C-07 turunda eklendi). | ✅ |
| F-03 | a | F4 (Glossary) | Modül ekseni `ADR` Glossary'de yok; kardeş `RFC` ekli — tutarsızlık. | `Glossary.md` A bölümüne `ADR — Architecture Decision Record`. F4 zaten inline açıyor. | ✅ |
| F-04 | b/d | F1:34, F2:34 | "Capstone 1/2" linksiz anılıyor; dosyalar `CAP1-*/CAP2-*`. Eşleme okuyucuya bırakılmış. | F1 teslim egzersizinde Capstone 1/2 canlı relative link'e çevrildi (`../capstones/CAP1-blok-c-sonu.md` / `CAP2-blok-d-sonu.md`). | ✅ |
| F-05 | a | F1:17; F3:17,30 (Glossary) | `right-sizing`/`reserved`/`bilişsel yük` Glossary'de yok (deep-dive'da tanımlı, hafif). | `Glossary.md`: `Right-sizing` + `Reserved Instance (RI)` (R bölümü), `Cognitive load` (bilişsel yük; C bölümü). | ✅ |
| F-06 | kısıt#1 | F4:36,40-41 | F4 ADR yapısını + rubriği inline gömüyor (sıralayıcıya en yakın "yeniden yazma"); egzersiz iskelesi olarak kabul edilebilir, ihlal değil. | İsteğe bağlı: rubriği bir şablona bağla. | ➖ (sınırda) |

---

## GLOSSARY-COVERAGE.md (çıktı kapısı) — ✅ ÇIKARILDI

Faz 9 çıktı kapısı: her teknik terim ya bir modülde tanımlı ya `Glossary.md`'de.
`_planning/GLOSSARY-COVERAGE.md` envanteri çıkarıldı: Faz 9'da tespit edilen 16 terim
(ICMP, semver, LocalStack, Free tier, NAT, egress, kind, k3s, Taint/Toleration, burn rate,
Alertmanager, ack, ADR, Right-sizing, Reserved Instance, Cognitive load) hepsi inline gloss
ve/veya Glossary ile kapatıldı — **açık terim boşluğu 0**. Bu turda Glossary'ye eklenen 6
satır: `ack`, `ADR`, `Alertmanager`, `Cognitive load`, `Reserved Instance (RI)`, `Right-sizing`.

## Faz 9 kapanış özeti

Tüm blok bulguları kapandı: A (5) ✅ · B (8) ✅ · C (7) ✅ · D (8) ✅ · E (6) ✅ · F (6) ✅.
`⬜` açık bulgu kalmadı. `➖` gerekçeli-değişmez: A-05, B-04, F-06. Çıktı kapısı
(GLOSSARY-COVERAGE.md) çıkarıldı. **Faz 9 → ✅.**

## §9 kapsam kararı (tekrar eden — A-05/D-08/C-03)

§9 dört-alan sözleşmesi **yönlendirilmiş dış okuma** linkleri içindir. İhtiyaç-anında tekil
referans (man page, tool wiki, GitHub release sürüm bakışı) bu sözleşmeden muaftır; muafiyet
A5 modülünde açıkça yazılı. İç repo "Önce oku" linkleri (deep-dive) 3-alanlı hafif formatta
kalır — §9 "dış link" der. C-03 istisnası: C0'da tutorial C-01 nedeniyle fiilen zorunlu
olduğu için orada 4 alanla verilmeli (tekil-referans muafiyeti orada geçmez).
