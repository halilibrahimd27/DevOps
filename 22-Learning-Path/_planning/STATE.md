# STATE — Öğrenme Patikası İnşası

**Son güncelleme:** 2026-07-21 · **Son commit:** 843d924 (Faz -1 kısmi) → bu commit Faz -1'i **tamamlar**

## Faz durumu

| Faz | Ad | Durum | Not |
|---|---|---|---|
| -1 | Zemin: rebrand + i18n + P0 | ✅ | Tamamlandı: infra + rebrand(in-repo) + konumlandırma + i18n zemini + P0-1..7 |
| 0 | Keşif ve haritalama | ⬜ | **Sırada** |
| 1 | İskelet | ⬜ | |
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

**Faz 0 — Keşif ve haritalama** (kod yok, analiz). Bir sonraki turda başla:

1. Tüm `00-*`…`21-*` dosyalarını tara: konu, varsaydığı ön bilgi seviyesi,
   hangi bloğa/modüle (A1…F5) ait olabileceği.
2. `_planning/GAP-MAP.md` oluştur: her müfredat konusu → karşılayan mevcut
   dosya(lar) VEYA "EKSİK — yazılacak".
3. `_planning/MODULE-SPEC.md` oluştur: A1…F5 tam liste (ID, ad, blok, süre,
   ön koşul, okunacak mevcut dosyalar, lab no, kırık lab no).
4. Çıktı kapısı: kaynaksız modül yok (her modülün kaynağı ya mevcut dosya ya
   "Blok A/B'de yazılacak").
5. ⏸️ **Faz 0 SONUNDA DUR — onay kapısı.** `MODULE-SPEC.md` hazır olunca
   `Sıradaki adım`a birebir `⏸ ONAY BEKLENIYOR — MODULE-SPEC.md incelenmeli`
   yaz, `.local/PAUSE` oluştur, commit at, dur (§14.2-a). Faz 2'ye onaysız geçme.
   (Onay beklerken Faz 1 iskeleti yapılabilir — ama bu ayrı tur.)

> Not (§14.1): bir turda en fazla bir faz. Faz 0 tek tura sığar (analiz).

## Açık kararlar

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

## Bu oturumda yapılanlar (Faz -1 kapanışı — kalan 3 P0)

- **P0-1:** `17-Templates/` altındaki 5 alt klasöre index `README.md` eklendi
  (`dockerfiles/`, `github-actions/`, `kubernetes/`, `kyverno-policies/`,
  `prometheus-rules/`). Her biri ilgili yaml/Dockerfile'ları gömer + kısa
  "niye" + anti-pattern tablosu. MkDocs artık 19 template'i (5 klasör) iki
  locale'de de render ediyor (TR: `site/17-Templates/<f>/`, EN: `site/en/...`).
- **P0-3:** 23 diakritiksiz frontmatter `description` düzeltildi (sadece
  diakritik/typo; cümle korundu). `Right-Sizing.md` `kuculttme` → `küçültme`.
  Tespit grep'i artık boş; `kucult` typo grep'i boş.
- **P0-5:** tfsec → `trivy config` geçişi.
  - `17-Templates/github-actions/terraform-plan.yml`: `aquasecurity/tfsec-action@v1`
    → `trivy config` (`scan-type: config`), mutable ref yerine `@<VERSION>` placeholder.
  - Doküman geçiş notları (canlı tavsiye yerleri): `03-IaC/Terraform-Best-Practices.md`,
    `03-IaC/Terraform-Module-Layout.md`, `16-Cheatsheets/terraform.md`,
    `08-Security/DevSecOps-Pipeline.md`, `RoadMap/Modern-DevOps-2026.md`.
    Prose yeniden yazılmadı; tek satır not / tek kelime swap.

### Süre denetimi (14.3)
Bu turda içerik modülü (estimated_hours'lu) yazılmadı → toplam yok. Faz -1 baştan
sona infra/rebrand/P0 fix'ti.

### Otonom denetimler (14.3)
- **Tekrar denetimi:** Bu turda patika modülü yazılmadı. 5 template README'si
  deep-dive tekrarı değil; mevcut yaml'ları (P0-1 gereği) gezilebilir kılmak için
  gömüyor + ince template-spesifik prose. Kasıtlı, tekrar sayılmaz.
- **Ünvan/pazarlama taraması:** `22-Learning-Path/` → temiz.
- **Faz -1 çıktı kapısı:** iki-locale build exit 0 (2 bilinen non-fatal warning);
  konumlandırma grep boş; locale-ekli iç link 0; `_planning` sitede yok; yeni
  template .md'lerinde public IP leak yok (RFC1918/`0.0.0.0` dışı IP yok).
