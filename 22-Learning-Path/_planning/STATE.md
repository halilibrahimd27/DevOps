# STATE — Öğrenme Patikası İnşası

**Son güncelleme:** 2026-07-21 · **Son commit:** (bu commit) Faz 2 kısmen — A1–A4 içerik (TR)

## Faz durumu

| Faz | Ad | Durum | Not |
|---|---|---|---|
| -1 | Zemin: rebrand + i18n + P0 | ✅ | Tamamlandı: infra + rebrand(in-repo) + konumlandırma + i18n zemini + P0-1..7 |
| 0 | Keşif ve haritalama | ✅ | `GAP-MAP.md` + `MODULE-SPEC.md`. **ONAY ALINDI** — 9 revizyon uygulandı |
| 1 | İskelet | ✅ | 8 rehber + 29 modül iskeleti + 3 capstone. QA exit 0 |
| 2 | Blok A + B (içerik) | 🟡 | **Devam ediyor.** A1–A4 (Linux+ağ+Git) TR yazıldı, QA exit 0. **A5'ten devam** |
| 3 | Blok C + D | ⬜ | |
| 4 | Blok E | ⬜ | |
| 5 | Lab'ların tamamlanması | ⬜ | |
| 6 | Değerlendirme | ⬜ | STAGE-EXAM, PLACEMENT kontrol testleri, capstone rubrikleri |
| 6.5 | Sertifika katmanı | ⬜ | G3'te F2→CKS bağımlılığı burada çözülecek (revizyon 7) |
| 7 | Blok F + kariyer köprüsü | ⬜ | PORTFOLIO.md + F egzersizleri (revizyon 9) |
| 8 | Entegrasyon | ⬜ | 22 nav başlığı + geri-linkler. (Not: `2[0-9]-*` globu 22'yi zaten stage ediyor; `_planning` `exclude_docs`'ta) |
| 9 | Düşmanca gözden geçirme | ⬜ | TROUBLESHOOTING.md 40+ madde burada dolar |

## Sıradaki adım

**Faz 2 devam — A5'ten başla.** A1–A4 (TR) tamamlandı (`block-a-intuition/`), TODO
gövdeleri öğretici içerikle dolduruldu. Kalan sıra:
**A5 (Bash, 🔴 EKSİK) → A6 (elle deploy, 🔴 EKSİK, patikanın çıpası) → B1 (log, 🔴) →
B2 (metrik, 🟡 KISMİ → `Prometheus-Best-Practices.md`'e devret) → B3 (kırık lab, 🔴).**

Her modülün TODO bölümleri §6 anatomisiyle doldurulur: öğretici numaralı gövde +
🚫 anti-pattern tablosu + ✅ kabul kriteri (komut+çıktı, öznel DEĞİL) + 🧪 kendini test
(cevaplı `<details>`) + 🆘 takıldıysan tablosu. Yazım deseni için tamamlanmış **A1–A4**
birebir örnek. Güvenlik ipliğini her modülde içeride tut (A2 en-az-açıklık, A3 TLS
doğrulama gibi).

> ⚠️ Faz 2 tek tura sığmıyor (§14.1.3). Bu tur: A1–A4. Kalan: A5, A6, B1, B2, B3
> (+ kırık lab çıpaları K00/K01 iskelette işaretli; lab dizinleri Faz 5'te doğar).

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

## Bu oturumda yapılanlar (Faz 2 — Blok A içerik, kısmen: A1–A4)

- **A1–A4 modül gövdeleri sıfırdan yazıldı (TR)**; iskelet TODO'ları öğretici
  içerikle dolduruldu (§6 anatomisi tam):
  - **A1 Linux temeli** (379s): process/`/proc`/sinyaller, filesystem/inode/`df -i`,
    izin modeli (rwx/octal/umask), kullanıcı/grup/`sudo` **güvenlik sınırı** → D1 RBAC'e
    köprü, stdio/yönlendirme/`PATH`.
  - **A2 Ağ I** (314s): 4-katman teşhis modeli, `ip`/`ss`, subnet bit-math, NAT/DHCP/ARP,
    port/soket, routing, TCP/UDP, **"connection refused vs timed out"** ayrımı (teşhisin kalbi).
  - **A3 Ağ II** (316s): DNS çözümleme zinciri→HTTP(metod/idempotency/cookie)→TLS el sıkışma;
    `dig`/`curl`/`openssl`; "site açılmıyor"u 4 komuta bölme; sertifika = **zaman/isim/zincir**.
  - **A4 Git** (314s): DAG zihinsel modeli, commit/branch/merge, **conflict elle çözme**,
    merge vs rebase + **altın kural**, restore/reset/revert/stash/reflog, remote köprüsü (C2/D5).
- **Güvenlik ipliği (§4.2):** least-privilege (A1), en-az-açıklık güvenlik duvarı (A2),
  TLS doğrulama + `--insecure` anti-pattern (A3), sır commit'leme anti-pattern (A4).
- **Altyapı:** `build-docs.sh` Bash 3.2 uyumlu → site yerelde hatasız derleniyor.
- **QA:** `python3 .local/qa.py` → **exit 0, 0 uyarı** ("Site hatasız derlendi").
- **Otonom denetimler (§14.3):** pazarlama grep temiz (tek eşleşme `_planning/STATE.md`
  meta-notu — shipped değil, qa `_planning`'i atlar); 3 özgün cümle mevcut deep-dive'da
  **yok**; A1–A4 `estimated_hours`=58 (Blok A toplam 97'nin parçası, değişmedi).
