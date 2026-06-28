---
description: "Code review'i bilgi paylaşımı ve kalite aracına çeviren pratikler: review'ın 3 amacı, nit/blocker/question kategori sistemi, reviewer ve author rehberi."
tags:
  - Git
  - Culture
  - Soft Skills
  - Cheatsheet
---
# Code Review Checklist — İyi Review, İyi Reviewer

> *"PR'a 'LGTM' yazıp geçmek review değildir; **kontroldür**.
> Kontrol kaliteyi yakalamaz, **iyi review** yakalar."*

Bu rehber, code review'i mekanik bir onay-makinesi olmaktan çıkarıp,
**bilgi paylaşımı + kalite** aracına çeviren pratiklerin derlemesi.
Reviewer ve author için iki yönlü.

---

## 🎯 Review'ın 3 Amacı

1. **Bug yakalamak** (en az önemli — testlerin işi)
2. **Bilgi paylaşımı** — junior'a feedback, codebase'i ekibe yaymak
3. **Tasarım sürtünmesi** — "bunu böyle yapma, şuradaki pattern'i kullan"

> 🔑 Eğer review'larınızda sadece "typo" yorumu varsa, review değil
> **typoredaktörlüğü** yapıyorsunuz. Tasarım sürtünmesi olmuyorsa
> reviewer engaged değil demektir.

---

## 🚦 Yorum Kategori Sistemi

Yorumun **ne kadar bağlayıcı** olduğunu **prefix** ile bildir:

| Prefix | Anlam |
|---|---|
| **`nit:`** | Nitpick — opsiyonel iyileştirme. Author düzeltmese de OK. |
| **`question:`** | Anlamak için soru. Engelleyici değil. |
| **`suggestion:`** | Öneri. Düşün, yap veya gerekçesiyle reddet. |
| **`blocker:`** | Bunu düzeltmeden merge edemezsin. |
| **`praise:`** | "Bu güzel olmuş" — pozitif feedback de değerli. |

```
nit: variable adı `cnt` yerine `count` daha okunur

question: bu retry policy idempotent mi? POST için sorun çıkarmaz mı?

suggestion: burada `errors.Wrap` yerine `fmt.Errorf("%w", err)` standard
            kullanılabilir. Yeni Go 1.20+ idiom.

blocker: bu endpoint authentication olmadan internal data döndürüyor;
         gerçek prod'da bunu öyle bırakamayız.

praise: bu test setup süper temiz, helper fonksiyonu güzel olmuş.
```

> 🔑 **`praise`** unutulmamalı — yalnız hatayı yakalayan review zehirler.
> Pozitif örüntüleri **görünür** kılmak senior'ın işidir.

---

## 👤 Author için Checklist

PR açmadan önce **kendi kodunu review et:**

### Hazırlık
```
[ ] PR description doldurulmuş (template'den)
[ ] Linked issue/JIRA ticket
[ ] Test eklenmiş veya niye eklenmediği yazılmış
[ ] Screenshot / örnek output (UI/CLI değişikliği varsa)
[ ] Breaking change'ler "BREAKING CHANGE:" ile etiketlenmiş
[ ] CI yeşil
```

### Kod
```
[ ] Tek konsept, tek PR (3 farklı şey değil)
[ ] PR boyutu < 400 satır (büyükse split düşün)
[ ] Commits anlamlı (squash sonrası tek temiz commit zaten)
[ ] Yorum: WHAT yazma, WHY yaz (ya da yazma)
[ ] Magic number → constant, hardcode → config
[ ] Yeni dependency var mı? Niye? CVE durumu?
[ ] Print/console.log debug satırları temizlenmiş
[ ] Try/catch rastgele tepelenmemiş — gerçekten handle edilebilir mi?
[ ] Loglama: PII/secret yok, severity doğru
[ ] Error mesajları kullanıcıya yararlı (stack trace değil)
```

### Self-review akışı
```
1. PR'ı aç ama review atama
2. "Files changed" tab'ında kendi PR'ına bak
3. Açıklamak istediğin satırlara comment yaz
4. 3+ comment yazdığını fark ettiysen — kod yetmiyor demektir
5. Yorumla anlaşılmayan kod = okuyucu kaybedilmiş kod
6. Self-review temiz → reviewer'ları ata
```

> 🔑 Bir PR'a 5 explanation comment yazıyorsan, **kod yeniden yazılmalı.**

---

## 👀 Reviewer için Checklist

### Birinci geçiş: 2 dakika overview
```
[ ] PR description net mi? Niye yapılıyor anlıyor muyum?
[ ] Test kapsamı yeterli mi?
[ ] PR boyutu mantıklı mı? (yoksa "too big" diyebilirim)
[ ] Etkilenen dizinler beklenen mi yoksa scope creep mi?
[ ] Critical path'te bir yere dokunuyor mu? (auth, payment, data)
```

### İkinci geçiş: detaylı review

#### 🔧 Mantık
```
[ ] Edge case'ler düşünülmüş mü? (null, boş array, max int, negative)
[ ] Concurrency: race condition? lock? deadlock riski?
[ ] Error handling: catch'in içi gerçekten error'u handle ediyor mu?
[ ] Off-by-one: <= vs <, range edge'leri
[ ] Time zone: naive datetime mi, UTC mi?
[ ] Retry: exponential backoff? max attempts?
[ ] Idempotency: aynı request 2 kez = problem yaratır mı?
```

#### 📐 Tasarım
```
[ ] Bu fonksiyon zaten var (DRY ihlali)?
[ ] Tek sorumluluk (SRP) — fonksiyon 100+ satır mı?
[ ] Soyutlama doğru seviyede mi (premature abstraction değil)?
[ ] Mevcut pattern'lere uyuyor mu yoksa yeni bir akıma mı sürükleniyor?
[ ] API tasarımı: caller dostu mu, ad'lar açık mı?
[ ] Backward compat: API'yi kıran değişiklik versionsuz değil mi?
```

#### 🛡️ Güvenlik
```
[ ] Input validation (schema, max length, content-type)
[ ] SQL: parametreli mi, string concatenation yok mu?
[ ] XSS: output escape (template engine doğru kullanılıyor mu)?
[ ] AuthZ: yeni endpoint için RBAC tanımlı mı?
[ ] Sensitive data log'a düşmüyor (token, password, PII)?
[ ] Hardcoded secret/token/IP yok?
[ ] CORS: yeni route allow-listed mi?
[ ] Rate limit: brute-force vektörü yarattı mı?
[ ] Crypto: bcrypt/argon2 kullanılıyor (md5/sha1 değil)?
```

#### 🚀 Performans
```
[ ] N+1 query?
[ ] Hot path'te allocation?
[ ] Yeni external call → timeout + retry tanımlı mı?
[ ] Cache invalidation doğru mu?
[ ] Big-O makul mu?
[ ] Lazy load fırsatı?
```

#### 🧪 Test
```
[ ] Yeni davranış için test eklendi mi?
[ ] Regression için existing test bozulmadı mı?
[ ] Test happy path + edge + error?
[ ] Test isimleri okunduğunda davranış anlaşılıyor mu?
[ ] Mock/fake gerçeği temsil ediyor mu (over-mocking değil)?
[ ] Test deterministik mi (zaman/random freezing)?
```

#### 📜 Observability
```
[ ] Yeni feature için metric eklenmiş mi?
[ ] Log severity doğru (info/warn/error)?
[ ] Trace span'leri doğru noktada?
[ ] Alert lazım mı? Alert yok ama olmalı mı?
```

---

## 🎯 PR Boyutu — Niye Kritik?

| PR satırı | Bug yakalama oranı | Review süresi |
|---|---|---|
| < 100 | %85 | 5 dk |
| 100–400 | %70 | 15 dk |
| 400–1000 | %40 | 60+ dk |
| 1000+ | %15 | "LGTM" hızlı |

**Veri:** SmartBear araştırması (2008, hâlâ geçerli) — büyük PR'lar
nominally review edilir, gerçekten edilmez.

### Büyük PR'ı bölme stratejileri
1. **Vertical slice** — feature'ı küçük UI + backend + test ünitelerine böl
2. **Stacked diffs** — Graphite ile birbirine bağlı küçük PR'lar
3. **Refactor önce, feature sonra** — ayrı PR'da
4. **Feature flag** — yarım kod merge edilebilir

---

## 🤖 Otomasyona Devredilebilenler

Bunları reviewer'ın yapması zaman israfı:

| İş | Tool |
|---|---|
| Format / lint | Prettier, ESLint, gofmt, ruff, black |
| Type check | TypeScript, mypy, sorbet |
| SAST | Semgrep, CodeQL |
| SCA | Trivy, OSV-Scanner |
| Secret scan | gitleaks, trufflehog |
| PR title format | semantic-pr-action |
| PR template doldurma | `.github/PULL_REQUEST_TEMPLATE.md` |
| Coverage threshold | Codecov, custom CI step |
| Bundle size | size-limit, bundlewatch |

> 🔑 İnsan reviewer **mantık + tasarım + bilgi paylaşımı**'na zaman ayırır.
> Format düzeltmek için review = mühendis maaşının israfı.

---

## ⏱️ Response Time Hedefleri

| PR durumu | Hedef |
|---|---|
| PR açıldı → ilk review | **< 4 saat** (work hours) |
| Review verildi → author yanıt | < 1 iş günü |
| Yanıt verildi → re-review | < 4 saat |
| Toplam PR → merge | P50 < 1 gün, P95 < 3 gün |

Trunk-based ile uyumlu. Yavaş review = yavaş geliştirme.

> ⚠️ "Review queue" 10+ PR olduğunda ekip akışı tıkanır. Standup'ta kontrol et.

---

## 🧠 İletişim Tonu

### ✅ İyi
- "Burada kafam karıştı, niye böyle yapıyoruz?"
- "Bu yaklaşım iyi gözüküyor — alternatif olarak X de düşündün mü?"
- "Bu test çok güzel ne oldu burada teşekkürler 👏"
- "Burada potansiyel bir race condition görüyorum: A, B... düşünür müsün?"

### ❌ Kötü
- "Bu yanlış." (gerekçe yok)
- "Bunu hep böyle yapardım." (otorite argument)
- "Niye böyle yazdın??" (saldırgan)
- "..." (sessiz red)

### Reviewer'ın kuralları
1. **Kodu eleştir, kişiyi değil.**
2. **"You" yerine "the code"**: "you're not handling X" → "X is not handled here"
3. **"Niye"yi gerekçele:** "Bu yapılmamalı çünkü <X scenario>"
4. **Soru sormayı tercih et:** "Bu kasıtlı mı?" > "Bu yanlış"
5. **Junior'da öğretici, senior'da partner ol.**

### Author'ın kuralları
1. **Defansif olma.** Reviewer "kötü dedektif" değil, partner.
2. **Direkt sor:** "Anlamadığımı yeniden açıklar mısın?"
3. **Reddedebilirsin** ama gerekçele: "Bu suggestion'ı X sebepten almıyorum."
4. **Tartışma uzarsa video chat:** 3+ yorum = 5 dk konuş.

---

## 🛠️ CODEOWNERS — Doğru Reviewer Otomatik

```
# .github/CODEOWNERS

# Default
*                       @platform-team

# Specific paths
/api/                   @backend-team
/web/                   @frontend-team
/infra/                 @platform-team
/docs/                  @docs-team

# Critical = ek reviewer
/api/auth/              @backend-team @security-team
/api/payments/          @backend-team @payments-team @security-team

# Specific files
*.tf                    @platform-team
Dockerfile              @platform-team @security-team
.github/workflows/      @platform-team
```

Branch protection'da **`Require code owner reviews`** açık olunca:
- Path'e dokunan PR otomatik o team'e atanır
- Spot critical area'da extra göz garantilenir

---

## 📝 PR Description Şablonu

```markdown
## Niye?
<problem ne, niye çözüyoruz, hangi metric/feedback'le geldi>

## Ne?
<özet: ne yapıldı, hangi yaklaşım seçildi>

## Alternatif yaklaşımlar (düşünüldüyse)
- A: <kısa>
- B: <kısa>
- Seçilen: <gerekçe>

## Test
- [ ] Unit test eklendi
- [ ] Integration test güncellendi
- [ ] Manuel test: <adımlar>

## Risk
<deploy edildiğinde ne kırabilir, rollback nasıl>

## Screenshots (UI ise)
<…>

## Linked issues
Closes #123
```

> 🔑 "Niye?" sorusunun cevabı PR'a yazılmazsa, 6 ay sonra `git blame`
> yapan biri için "neden böyle" cevabı kayıp.

---

## 🧪 Pair / Mob Programming Alternatifi

Code review = asenkron pair programming. Bazen real-time daha iyi:

| Senaryo | Tercih |
|---|---|
| Junior öğreniyor | Pair (sync) |
| Karmaşık tasarım kararı | Mob (3-4 kişi, sync) |
| Bug fix, küçük | PR (async) |
| Refactor, geniş | PR + tech design doc önce |
| Time-sensitive prod fix | Pair → 1 reviewer onay |

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "LGTM" sadece | Review yapılmadı, etiketlendi | Substantif yorum, en az 1 |
| Senior her zaman 4 saat sonra review | Bottleneck | Round-robin, CODEOWNERS |
| 1500-satır PR | Gerçekten okunmuyor | < 400 satır, böl |
| Reviewer formatla uğraşıyor | Insan zamanı israfı | Pre-commit + CI lint |
| "Niye böyle?" sorusu yok, hep "LGTM" | Bilgi paylaşımı yok | Soru sorma kültürü |
| Yorum saldırgan | Toxic culture, herkes savunmacı | "Code, not person" |
| Author'a 4 reviewer atanmış | Diffusion of responsibility | 1 + CODEOWNERS spot |
| `nit:` prefix yok | Author her şeyi blocker sanır | Prefix sistem |
| Re-review 2 gün sonra | Trunk-based imkansız | < 4 saat hedef |
| Author değişikliği reviewer'a duyurmuyor | Reviewer eski state'i okur | "Re-review please, comments addressed" |

---

## 📋 Review Kültürü Sağlık Çek

```
[ ] PR ortalaması < 400 satır
[ ] PR → first review P50 < 4 saat
[ ] PR → merge P50 < 1 gün
[ ] Review yorumları: %30+ "question/suggestion" (sadece "blocker" değil)
[ ] Praise / pozitif yorum görünür
[ ] CODEOWNERS güncel + critical path'te ekstra reviewer
[ ] Reviewer rotation (tek kişi bottleneck değil)
[ ] Otomasyon: lint, format, SAST, SCA — insan yorumlamıyor
[ ] PR template kullanılıyor, "Niye?" doldurulmuş
[ ] Linked issue/ticket
[ ] Quarterly: review metrik review (lead time, comment volume)
[ ] Junior'a öğretici review veriliyor (link, dokuman, örnek)
```

---

## 📚 Referanslar

- **Google Engineering Practices** — google.github.io/eng-practices/review
- **Conventional Comments** — conventionalcomments.org
- **What to look for in a code review** — Trisha Gee
- **The Pull Request Review Process** — Jessica Joy Kerr
- [`Trunk-Based-Development.md`](Trunk-Based-Development.md)
- [`Conventional-Commits.md`](Conventional-Commits.md)
- [`PR-Templates-and-Automation.md`](PR-Templates-and-Automation.md)

---

> *"Review'ın kalitesi, ekip kültürünün barometresi. PR'ların 'LGTM
> stamping'le geçtiği ekip, 6 ay sonra postmortem'de 'kimse bunu fark etmedi'
> diyen ekibin **6 ay öncesi**dir."*
