# Katkı Rehberi

Önce sağol — bu repo'yu zenginleştirmek istemen değerli. Aşağıdaki kurallar
"sıkı bürokrasi" değil, içeriğin tutarlı ve **public-safe** kalması için.

## 🎯 Katkı türleri

- ✅ Yeni bir cheatsheet ekleme ([`16-Cheatsheets/`](16-Cheatsheets/))
- ✅ Mevcut bir konuya derinlik ekleme (örnek, post-mortem, anti-pattern)
- ✅ Şablon ekleme ([`17-Templates/`](17-Templates/))
- ✅ Yazım/dilbilgisi düzeltmesi
- ✅ Linklerin bozuk olduğunu bildirme
- ✅ Eksik konu önerisi (issue olarak)

## 🚫 Kabul edilmeyenler

- ❌ Gerçek IP, domain, credential, e-mail adresi içeren içerik
- ❌ Pazarlama/SEO yazısı, bir ürünün sponsorlu reklamı
- ❌ Çeviri tabanlı içerik (orijinal kaynağa link verin yeter)
- ❌ Dökümantasyon-bot çıktısı (kalitesi düşük, ham AI çıktıları)
- ❌ Tekil komutu olan PR'lar (cheatsheet'e ekleyin yeter, yeni dosya açmayın)

## 📝 Stil kuralları

### Markdown
- **Türkçe yaz.** İngilizce terim kullan ama açıkla.
- Başlıklar: `#` H1 (dosya başına 1 tane), `##` H2 ana bölüm, `###` H3 alt bölüm.
- Komut blokları için `bash`, YAML için `yaml`, JSON için `json` dil kodu.
- Dosya yolları, komutlar, env var'lar `code` içine alınır.
- Link metni anlamlı olsun — "[buraya tıkla]" değil "[Postgres production guide]".
- Emoji ölçülü — başlıkta 0-1 tane, vurgu için bölüm girişinde 1-2 tane.

### Placeholder konvansiyonu
| Placeholder | Anlam |
|---|---|
| `<TARGET_IP>` | Hedef makine IP'si |
| `<DOMAIN>` | Domain adı |
| `<NAMESPACE>` | K8s namespace |
| `<REGISTRY>` | Container registry hostname |
| `<USERNAME>` | Kullanıcı adı |
| `<PASSWORD>` | Şifre (asla gerçek değer) |
| `<TOKEN>` | API token |
| `<CLUSTER_NAME>` | Cluster adı |
| `<REGION>` | Cloud region |
| `<ACCOUNT_ID>` | Cloud account ID |

**Asla** `123.45.67.89` gibi spesifik IP, `mysite.com` gibi gerçek domain,
`admin/admin` ötesinde inanılır şifreler kullanmayın.

### Komut bloklarında
- `$` prompt'u **kullanmayın** — copy-paste'i bozar
- Çıktı göstermek için yorum satırı: `# Output:`
- Uzun komutları `\` ile satıra böl
- `sudo` gerekiyorsa belirt — gereksiz `sudo` kullanma

## 🔒 Public-Safe Audit (PR açmadan önce)

Aşağıdakileri kontrol et:

```bash
# Repo'da gerçek IP arıyor (sınıf A/B/C, lokal hariç)
grep -rEn '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b' --include='*.md' \
  | grep -vE '127\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|0\.0\.0\.0'

# E-mail
grep -rEn '\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b' --include='*.md' \
  | grep -vE 'example\.com|noreply|noreply@|@example|placeholder|<.*>'

# Olası secret
grep -rEnI 'password\s*[:=]|api[_-]?key\s*[:=]|secret\s*[:=]|token\s*[:=]' \
  --include='*.md' --include='*.yaml' --include='*.yml'
```

Bir tane bile gerçek değer çıkarsa **placeholder'a çevir** ve commit et.

## 📂 Yeni klasör eklerken

1. Numaralı bir önek seç (mevcut sırayla mantıklı)
2. İçinde `README.md` mutlaka olsun
3. Top-level `README.md`'deki içindekiler tablosuna ekle
4. En az 1 deep-dive markdown + 1 cheatsheet/template

## 📂 Dosya isimlendirme

- `Title-Case-With-Dashes.md` — başlık tarzı
- Sığamayan açıklayıcı isimler kabul: `Zero-Downtime-Postgres-Migrations.md`
- Türkçe karakter kullanma (`ş`, `ğ`, vb.) — link'leri kırar
- Boşluk yerine `-` kullan

## 🔄 PR süreci

1. Fork → branch (`feature/<konu>` veya `fix/<konu>`)
2. Conventional commit:
   - `docs: add Kubernetes Gateway API guide`
   - `fix(cheatsheet): correct kubectl describe flag`
   - `chore: update broken link in README`
3. PR açıklamasında: ne ekledin, niye ekledin
4. Reviewer atama gerekmez, ben gözden geçiririm

## 💡 İçerik fikrin var ama yazacak vaktin yok mu?

[Issue aç](https://github.com/halilibrahimd27/DevOps/issues) ve `good first issue`
etiketi iste. Belki başka biri yazar.

---

> Tekrar teşekkürler 🙏 — ortak değer üretiyoruz.
