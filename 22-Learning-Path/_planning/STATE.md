# STATE — Öğrenme Patikası İnşası

**Son güncelleme:** 2026-07-21 · **Son commit:** 145e2a8 (Faz -1 kısmi)

## Faz durumu

| Faz | Ad | Durum | Not |
|---|---|---|---|
| -1 | Zemin: rebrand + i18n + P0 | 🟡 | Kısmen: infra + rebrand(in-repo) + konumlandırma + i18n zemini + P0-2/4/6/7 yapıldı. Kalan: P0-1/3/5 |
| 0 | Keşif ve haritalama | ⬜ | |
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

Faz -1'i tamamla — kalan 3 P0 düzeltmesi (hepsi mevcut içerik dosyalarında,
"aynı ellemede" grubu):

- **P0-1:** `17-Templates/` altındaki 5 alt klasöre index `README.md` ekle
  (`dockerfiles/`, `github-actions/`, `kubernetes/`, `kyverno-policies/`,
  `prometheus-rules/`). Her README ilgili yaml'ları snippet olarak gömsün
  (MkDocs bu klasörleri md olmadığı için render etmiyor → 19 template sitede
  gezilemiyor). Not: `gitignore/`, `terraform/`, `runbooks/` zaten README/md içeriyor.
- **P0-3:** Diakritiksiz Türkçe frontmatter `description`'ları düzelt (~28 dosya).
  Tespit komutu:
  `grep -rn "^description:" --include="*.md" . | grep -v _planning | grep -iE "esasli|gecis|guvenlik|kullanim|olcum|teshis|adim adim|yonetim|gelistirme|ceviren|kucult|dogrulama"`
  Ayrıca `12-FinOps/Right-Sizing.md:2` → `kuculttme` yazım hatası (→ `küçültme`).
  Dikkat: sadece diakritik/typo düzelt, cümleyi yeniden yazma.
- **P0-5:** tfsec → `trivy config` geçişi. Kesin değişecek dosya:
  `17-Templates/github-actions/terraform-plan.yml` (`aquasecurity/tfsec-action@v1`
  → `trivy config`). Doküman mention'ları (`03-IaC/Terraform-Best-Practices.md`,
  `03-IaC/Terraform-Module-Layout.md`, `16-Cheatsheets/terraform.md`,
  `08-Security/DevSecOps-Pipeline.md`, `RoadMap/Modern-DevOps-2026.md`): tfsec'in
  CANLI tavsiye olarak geçtiği yerlere tek satır geçiş notu ekle ("tfsec Trivy'ye
  konsolide edildi (2023); `trivy config` kullan"), prose'u yeniden yazma.

Bunlar bitince Faz -1 çıktı kapısı: `bash scripts/build-docs.sh && python3 -m mkdocs
build --clean` iki locale için hatasız (bu turda i18n eklendikten sonra doğrulandı),
konumlandırma grep'i boş, iç linklerde locale eki yok, `_planning` sitede yok.
Sonra STATE'i güncelle, commit at, **Faz 0'a geçme** (bu tur değil).

## Açık kararlar

- **GitHub-side rebrand elle yapılacak (gh CLI bu ortamda yok).** Kullanıcı şunları
  manuel yapmalı: ① GitHub repo rename `DevOps` → `devsecops-handbook`,
  ② repo `description` + `topics` (`turkish` çıkar; `devsecops`, `security`,
  `handbook`, `learning-path` ekle), ③ (varsa) Cloudflare `CNAME` (proxy KAPALI).
  ⚠️ **Repo rename bu branch main'e merge edilMEDEN önce yapılmalı** — aksi halde
  in-repo URL'ler `devsecops-handbook`'a döndüğü için canlı Pages sitesi 404 verir.
  Bu branch (`feat/learning-path`) main'e otomatik deploy tetiklemez, o yüzden şu an
  canlı site etkilenmiyor.
- **Custom domain verilmedi** → `site_url` fallback: `https://halilibrahimd27.github.io/devsecops-handbook/`
  (prompt §a ⚠️ notu). `build-docs.sh`'e CNAME kopyalama adımı eklendi ama CNAME
  dosyası yok; alan adı gelince kökte `CNAME` oluşturmak yeterli.
- **i18n Aşama A:** TR varsayılan (kök), EN `/en/` altında (suffix `.<locale>.md`).
  Şu an 0 EN çeviri var → EN sayfalar TR'ye fallback ediyor; iki-locale build
  fallback ile geçiyor. **Aşama B** (EN varsayılan olur): EN kapsama ≥ %60 olunca.
  Şimdi yapma. Çeviri önceliği ve durum: `_planning/I18N-COVERAGE.md`.
- **i18n uyarısı (non-fatal):** `mkdocs-static-i18n` dil değiştirici "contextual link"i
  `navigation.instant` ile uyumlu değil → switcher aynı sayfa yerine locale ana sayfasına
  gider. Build'i kırmıyor (strict:false). Aşama A'da EN çoğunlukla fallback olduğu için
  önemsiz; ileride gerekirse `navigation.instant` tradeoff'u yeniden değerlendirilir.
- **build-docs.sh doğrulaması:** Bu makinede Bash ≥4 yok (`declare -A` gerekiyor),
  script doğrudan koşmadı. Portable staging ile `python3 -m mkdocs build --clean`
  iki locale için **hatasız** doğrulandı (tr → `site/`, en → `site/en/`). CI'da Bash 4+
  olduğundan `build-docs.sh` orada normal koşar.
- **AUDIT.md / CHANGES-SUMMARY.md** eski pazarlama ifadesini *kaldırıldı kaydı* olarak
  tutuyordu; grep temiz kalsın diye literal superlatif ifade parafraz edildi (anlam korundu).
  Bu dosyalar zaten `exclude_docs` ile siteden hariç.

## Bu oturumda yapılanlar (Faz -1, kısmi)

- `_planning/` + `STATE.md` oluşturuldu (bu dosya).
- **Rebrand (in-repo):** `mkdocs.yml` `site_name` → "The DevSecOps Handbook",
  `site_url`/`repo_url`/`repo_name` → `devsecops-handbook`, `site_description`
  konumlandırması sadeleştirildi. `README.md`, `SECURITY.md`, `CONTRIBUTING.md`,
  `CHANGELOG.md`, `.github/DISCUSSION_TEMPLATE/q-and-a.yml`,
  `.github/ISSUE_TEMPLATE/config.yml` içindeki eski repo URL'leri güncellendi.
  `build-docs.sh`'e CNAME kopyalama adımı eklendi.
- **Konumlandırma (b):** "Türkçe DevSecOps rehberi/başucu kitabı" gibi
  konumlandırma tagline'ları "derin TR/EU regülasyon kapsamı olan handbook"
  çerçevesine çekildi (`README.md`, `docs/index.md`, `docs/about.md`); brand
  "DevOps Notebook" → "The DevSecOps Handbook". TR içeriği silinmedi.
- **i18n zemini (c):** `requirements-docs.txt`'e `mkdocs-static-i18n`;
  `mkdocs.yml`'e `i18n` plugin'i (`awesome-pages`'ten SONRA, `docs_structure: suffix`,
  tr default + en); `exclude_docs`'a `_planning/`; `I18N-COVERAGE.md` oluşturuldu.
- **P0-2:** `docs/index.md` `3. parti` → `Üçüncü parti` (ordered-list parse hatası).
- **P0-4:** `17-Templates/github-actions/docker-build-push.yml` `trivy-action@master`
  → sürüm-pinli placeholder (mutable ref anti-pattern giderildi).
- **P0-6:** `.github/workflows/quality.yml` lychee tek job'dan → iç linkler ayrı
  job'da `--offline` + `fail: true` (kırmızı olabilir); dış linkler rapor-only.
- **P0-7:** `mkdocs.yml` çerez onay banner'ı kaldırıldı (analytics/gtag yok,
  kullanılmayan çerez için izin isteniyordu); `copyright`'taki "Çerez ayarları" linki çıkarıldı.

### Süre denetimi (14.3)
Bu faz içerik modülü yazmadı (infra/rebrand) → `estimated_hours` toplamı yok.

### Otonom denetimler (14.3)
- Tekrar denetimi: içerik modülü yazılmadı → uygulanmadı.
- Ünvan/pazarlama taraması (14.3.2 regex'i): 22-Learning-Path/ → temiz.
- Konumlandırma + eski repo URL grep'leri → temiz. Locale-ekli iç link → 0.
- İki-locale build → hatasız (0 error, 2 non-fatal warning).
