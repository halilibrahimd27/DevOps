# STATE — Öğrenme Patikası İnşası

**Son güncelleme:** 2026-07-21 · **Son commit:** (bu commit) Faz 0'ı **tamamlar** — ⏸ ONAY KAPISI

## Faz durumu

| Faz | Ad | Durum | Not |
|---|---|---|---|
| -1 | Zemin: rebrand + i18n + P0 | ✅ | Tamamlandı: infra + rebrand(in-repo) + konumlandırma + i18n zemini + P0-1..7 |
| 0 | Keşif ve haritalama | ✅ | Tamamlandı: `GAP-MAP.md` + `MODULE-SPEC.md`. ⏸ **ONAY BEKLİYOR** |
| 1 | İskelet | ⬜ | Onay beklerken yapılabilir (ayrı tur) |
| 2 | Blok A + B | ⬜ | |
| 3 | Blok C + D | ⬜ | |
| 4 | Blok E | ⬜ | |
| 5 | Lab'ların tamamlanması | ⬜ | |
| 6 | Değerlendirme | ⬜ | |
| 6.5 | Sertifika katmanı | ⬜ | |
| 7 | Blok F + kariyer köprüsü | ⬜ | |
| 8 | Entegrasyon | ⬜ | |
| 9 | Düşmanca gözden geçirme | ⬜ | |

## Sıradaki adım

⏸ ONAY BEKLENIYOR — MODULE-SPEC.md incelenmeli

Onay gelince (kullanıcı `.local/PAUSE`'u siler) sıra: **Faz 1 — İskelet**
(`README`, `CURRICULUM` + mermaid DAG, `NOT-YET`, `PLACEMENT`, `PROGRESS-TEMPLATE`,
`STUDY-METHOD`, `COST-GUARDRAILS` + 28 modülün boş iskeleti). Faz 1, `MODULE-SPEC.md`'yi
girdi alır; onay beklerken de yapılabilir ama Faz 2 (içerik) **onaysız başlamaz**.

**İnceleme için özet:** 28 modül (A:6 B:3 C:4 D:5 E:5 F:5), 20 build + 9 kırık lab,
~300 saat (~25–30 hafta @10–12s/hafta). Blok A+B çekirdeği sıfırdan yazılacak (temeller
repoda yok); Blok C–F mevcut deep-dive'ları sarar. Detay: [`MODULE-SPEC.md`](MODULE-SPEC.md).

> Not (§14.1): bir turda en fazla bir faz. Faz 0 tek tura sığdı (analiz).

## Açık kararlar

- **(Faz 0) Modül sayısı 28**, BUILD-PROMPT §4.2'nin 28 ID'siyle birebir. Blok içi bölme
  (`D1a`/`D1b`) yapılmadı — gerekirse Faz 2/3'te bölünür (§4.2 izinli).
- **(Faz 0) Kırık lab: Blok A ve F hariç.** B/C/D/E her birinde ≥1 (D,E'de birden fazla).
  Gerekçe: A inşa-öncesi sezgi (bozulacak bir şey yok), F karar/yazım bloğu. §7.2'nin katı
  okunuşu istenirse eklenebilir; detay `MODULE-SPEC.md` → "Kırık lab dağılımı".
- **(Faz 0) Süre tahminleri taslak** (~300s toplam), cömert tutuldu; Faz 2+ netleşir.
- **GitHub-side rebrand elle yapılacak (gh CLI bu ortamda yok).** Kullanıcı manuel:
  ① repo rename `DevOps` → `devsecops-handbook`, ② repo `description` + `topics`
  (`turkish` çıkar; `devsecops`, `security`, `handbook`, `learning-path` ekle),
  ③ (varsa) Cloudflare `CNAME` (proxy KAPALI).
  ⚠️ **Repo rename bu branch main'e merge edilMEDEN önce yapılmalı** — aksi halde
  in-repo URL'ler `devsecops-handbook`'a döndüğü için canlı Pages sitesi 404 verir.
  Bu branch (`feat/learning-path`) main'e otomatik deploy tetiklemez.
- **Custom domain verilmedi** → `site_url` fallback:
  `https://halilibrahimd27.github.io/devsecops-handbook/`. `build-docs.sh`'e CNAME
  kopyalama adımı eklendi; alan adı gelince kökte `CNAME` oluşturmak yeterli.
- **i18n Aşama A:** TR varsayılan (kök), EN `/en/` altında; şu an 0 EN çeviri →
  EN sayfalar TR'ye fallback. **Aşama B** (EN varsayılan): EN kapsama ≥ %60 olunca.
  Öncelik/durum: `_planning/I18N-COVERAGE.md`.
- **i18n uyarısı (non-fatal, 2 adet):** `mkdocs-static-i18n` dil değiştirici
  "contextual link"i `navigation.instant` ile uyumsuz → build'i kırmıyor
  (strict:false). Aşama A'da EN çoğunlukla fallback → önemsiz.
- **P0-1 template README'leri TR-only yazıldı (`.md`, EN fallback).** Gerekçe:
  reponun tümünde 0 EN çeviri var; bu 5 dosya patika modülü değil, mevcut template
  klasörlerini gezilebilir kılan indekstir → mevcut TR-only içerik konvansiyonuyla
  tutarlı. EN çevirileri i18n öncelik listesinde (P4) sonraya kalır.
- **P0-1 embed tradeoff:** 5 README ilgili yaml'ları kod bloğu olarak **gömer**
  (`pymdownx.snippets` etkin değil; MkDocs .yaml/.yml/.Dockerfile'ı sayfa olarak
  render etmez). Gömülü kopya kaynaktan zamanla sapabilir; her README başına
  "kaynak dosyalar aynı klasörde" notu düşüldü. Template'ler stabil → risk düşük.
- **build-docs.sh doğrulaması:** Bu makinede Bash 3.2 (script `declare -A` ile
  Bash ≥4 ister). Portable Python staging + `python3 -m mkdocs build --clean` ile
  iki locale **hatasız** doğrulandı (exit 0). CI'da Bash 4+ olduğundan orada normal koşar.

## Bu oturumda yapılanlar (Faz 0 — Keşif ve haritalama)

- **Tam envanter tarandı:** 168 içerik dosyası (`00-*`…`21-*`), her birinin H1 +
  frontmatter `description`'ı çıkarıldı → konu/seviye çıkarımı. Ayrıca
  `RoadMap/README.md` (kırık başlangıç patikası), `21-Field-Notes/` (lab kıvamı),
  `17-Templates/` alt ağacı incelendi.
- **`_planning/GAP-MAP.md` oluşturuldu:** 28 müfredat konusunun her biri →
  mevcut dosya(lar) VEYA "🔴 EKSİK — yazılacak". Kaynak durum kodları (🟢/🟡/🔴).
  Sertifika kapıları + çözülecek 3 repo çelişkisi de haritalandı.
- **`_planning/MODULE-SPEC.md` oluşturuldu (ONAY KAPISI):** A1…F5 tam liste — ID,
  ad, blok/seviye, saat, ön koşul, kaynak durumu, build lab (L01–L20), kırık lab
  (K01–K09). + bağımlılık DAG'ı (döngü yok, ön koşullar önde) + süre denetimi +
  kırık lab dağılımı + sertifika eşlemesi + açık kararlar.

### Süre denetimi (§14.3)
MODULE-SPEC toplamı ~**300 saat** (A:68 B:26 C:48 D:66 E:50 F:42). Blok D ≥60 ✓
(§14.3 alarmı geçildi). Bunlar tahmin; içerik yazılırken (Faz 2+) netleşir.

### Otonom denetimler (§14.3)
- **Tekrar denetimi:** Bu turda patika **modülü** yazılmadı (sadece _planning analizi).
  GAP-MAP/MODULE-SPEC deep-dive tekrarı değil, sıralayıcı iskelet. Tekrar riski yok.
- **Ünvan/pazarlama taraması:** `grep -rniE "mid olur|senior olur|maaş|ROI|%N artış|en
  kapsamlı|garanti" 22-Learning-Path/` → **temiz** (tek meta-hit `_planning/`de reword edildi).
- **Faz 0 çıktı kapısı:** **kaynaksız modül yok** — 28 modülün her birinin kaynağı ya
  mevcut dosya (🟢/🟡) ya "Blok A/B'de yazılacak" (🔴). GAP-MAP "Kaynak yeterlilik özeti"
  tablosu bunu doğruluyor. `mkdocs.yml:28` `_planning/`'i exclude ediyor → sitede yok.
