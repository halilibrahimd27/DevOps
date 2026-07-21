# STATE — Öğrenme Patikası İnşası

**Son güncelleme:** 2026-07-21 · **Son commit:** (bu commit) Faz 1 — İskelet tamamlandı

## Faz durumu

| Faz | Ad | Durum | Not |
|---|---|---|---|
| -1 | Zemin: rebrand + i18n + P0 | ✅ | Tamamlandı: infra + rebrand(in-repo) + konumlandırma + i18n zemini + P0-1..7 |
| 0 | Keşif ve haritalama | ✅ | `GAP-MAP.md` + `MODULE-SPEC.md`. **ONAY ALINDI** — kullanıcı 9 revizyon ekledi (`MODULE-SPEC.md` → "ONAY REVİZYONLARI"), PAUSE silindi |
| 1 | İskelet | ✅ | 8 rehber + 29 modül iskeleti + 3 capstone. QA exit 0. 9 revizyon uygulandı |
| 2 | Blok A + B (içerik) | ⬜ | **Sıradaki.** Onay alındı → içerik yazımı başlayabilir |
| 3 | Blok C + D | ⬜ | |
| 4 | Blok E | ⬜ | |
| 5 | Lab'ların tamamlanması | ⬜ | |
| 6 | Değerlendirme | ⬜ | STAGE-EXAM, PLACEMENT kontrol testleri, capstone rubrikleri |
| 6.5 | Sertifika katmanı | ⬜ | G3'te F2→CKS bağımlılığı burada çözülecek (revizyon 7) |
| 7 | Blok F + kariyer köprüsü | ⬜ | PORTFOLIO.md + F egzersizleri (revizyon 9) |
| 8 | Entegrasyon | ⬜ | |
| 9 | Düşmanca gözden geçirme | ⬜ | TROUBLESHOOTING.md 40+ madde burada dolar |

## Sıradaki adım

**Faz 2 — Blok A + B içerik yazımı.** A1'den başla, sırayla A1→A2→A3→A4→A5→A6,
sonra B1→B2→B3 (+ kırık lab K01, K00). Modül iskeletleri hazır (`block-a-intuition/`,
`block-b-visibility/`); her modülün TODO bölümlerini doldur. 🔴 EKSİK modüller
öğretici gövde ister (**hedef 400–700 satır**, revizyon 1); §6 anatomisini izle.

> ⚠️ Faz 2 tek tura sığmaz (§14.1.3). Her tur nereye gelindiğini modül seviyesinde
> buraya yaz ("A1–A2 yazıldı, A3'ten devam"), commit at, dur.
>
> ⚠️ **İki dillilik:** Faz 2'de her modülün TR gövdesi yazılırken `.en.md` twin'i
> **birlikte** üretilir (§7 "sonradan çevirme"). İskelet fazında (Faz 1) EN
> üretilmedi — karar aşağıda.

## Açık kararlar

- **(Faz 1) i18n: İskelet TR-first; EN twin Faz 2+ içerikle birlikte.** Gerekçe:
  modül iskeletleri TODO-stub (yazılmış içerik değil); §7 "yeni yazılan içerik iki
  dilli" kuralı TODO→içerik dönüşünde (Faz 2+) bağlar, boş stub'da değil. Aşama A'da
  EN→TR fallback var → kırık/boş EN sayfa yok. Rehber dokümanlar (README/CURRICULUM…)
  da TR yazıldı; EN'leri patika omurgası içerik oturunca tek tutarlı geçişte gelir.
  Precedent: P0-1 template README'leri TR-only. `I18N-COVERAGE.md` P1 durumu güncellendi.
- **(Faz 1) 9 onay revizyonu uygulandı:**
  1. 200-satır tavanı yalnız 🟢 için; 🔴 = 400–700, 🟡 = 200–400 → Faz 2+ gövde hedefleri.
  2. A5 = Bash (12s); yeni **C0 — Ops için Python** (30s, ön koşul A5, C2'nin ön koşulu).
     A6 ön koşulu A1,A2,A3,A4,A5 (Python değil). → 28 modül **29 oldu**.
  3. A4 12s, D1 28s (temel içerik yükü).
  4. Süre revize: A97·B36·C88·D84·E64·F48 = **417 modül** + 60 capstone = **~477s (≈40-48 hafta)**.
     Doğrulandı (grep estimated_hours = 417; capstone gövdede ~20s×3).
  5. A6 → kırık lab **K00** (systemd ayağa kalkmıyor). Kırık lab: K00, K01, K02, K03, K04, K05, K06, K07, K08, K09.
  6. **K02 zorunlu** (C1).
  7. G3'te CKS↔F2 ileri-bağımlılığı → **Faz 6.5'e ertelendi** (yukarıdaki tabloda not).
  8. **Capstone'lar eklendi:** CAP1 (Blok C sonu), CAP2 (Blok D sonu), CAP3 (Blok E sonu).
     Dosya adı `CAP#-` → `[A-F]\d+` modül regex'iyle çakışmaz (QA temiz).
  9. F1 (maliyet hesaplama) + F4 (ADR+postmortem yaz) teslim egzersizleri iskelette işaretlendi (Faz 7'de dolar).
- **(Faz 1) Lab'lar kod-span olarak referanslandı, markdown link DEĞİL** — lab dizinleri
  Faz 5'te doğar; şimdi link olsa QA kırık-link hatası verirdi. "Önce oku" tablolarında
  yalnızca **var olan** deep-dive'lara link verildi (22 kaynak dosya varlığı doğrulandı).
- **(Faz 1) TROUBLESHOOTING.md iskeleti eklendi** (README/STUDY-METHOD ona link veriyor;
  kırık link olmasın diye). 40+ madde Faz 9'da dolar. PORTFOLIO.md Faz 7 (henüz link yok).
- **GitHub-side rebrand elle yapılacak (gh CLI yok).** Repo rename `DevOps`→`devsecops-handbook`,
  `description`+`topics`, (varsa) Cloudflare CNAME. **Repo rename main'e merge ÖNCE yapılmalı.**
- **Custom domain verilmedi** → `site_url` fallback `https://halilibrahimd27.github.io/devsecops-handbook/`.
- **i18n Aşama B** (EN varsayılan): EN kapsama ≥ %60 olunca. Şimdi değil.

## Bu oturumda yapılanlar (Faz 1 — İskelet)

- **8 rehber dokümanı yazıldı** (TR): `README`, `CURRICULUM` (modül tablosu + mermaid
  DAG + geçiş sinyalleri + dürüst tavan), `NOT-YET`, `PLACEMENT` (3 rampa + kontrol testi
  iskeleti), `STUDY-METHOD` (dış kaynak sözleşmesi — 4 alanlı link kuralı),
  `PROGRESS-TEMPLATE`, `COST-GUARDRAILS` (yerel-önce + bütçe alarmı), `TROUBLESHOOTING` (iskelet).
- **29 modül iskeleti** (`block-a…f/`): frontmatter (description/level/module/estimated_hours/
  prerequisites/tags) + §6 anatomisi başlıkları + TODO gövde. Ön koşullar geriye işaret
  ediyor (döngü yok). "Önce oku"da var olan deep-dive linkleri; güvenlik ipliği D1
  (Kubernetes-Hardening) ve D4 (Container-Image-Scanning = C2 devamı) içinde.
- **3 capstone iskeleti** (`capstones/CAP1..3`): şartname + kabul kriteri + rubrik + portfolyo
  şablonu (TODO Faz 6).
- **QA:** `python3 .local/qa.py` → **exit 0** (2 non-fatal uyarı: `.local/BUILD-PROMPT.md`
  patika-dışı link; mkdocs PATH'te yok → derleme atlandı, modül olarak importable).

### Faz 1 çıktı kapısı (§Faz 1) — geçildi
- ✅ Bağımlılık grafiğinde döngü yok (QA "ön koşul ileriye işaret ediyor" hatası yok).
- ✅ Her modülün ön koşulu kendisinden önce (rank: harf+sayı).
- ✅ Blok sınırları korunuyor; hiçbir modül sonraki bloğu ön koşul saymıyor.
- ✅ CURRICULUM ↔ dosya tutarlı (29 modül, QA check_curriculum temiz).

### Otonom denetimler (§14.3)
- **Tekrar denetimi:** 3 özgün cümle (C3/B1/E4) `grep -ri` ile mevcut deep-dive'larda
  **yok**. QA check_duplication da temiz. İskeletler sıralayıcı, deep-dive tekrarı değil.
- **Ünvan/pazarlama:** grep temiz (tek false-positive README'de "senior olur…" ünvan
  **karşıtı** cümlede çıktı → reword edildi; §15.4'e uygun, kriter silinmedi).
- **Süre gerçekçiliği:** 417 modül + 60 capstone = 477s; Blok D 84 ≥ 60 (§14.3 alarmı geçildi).
