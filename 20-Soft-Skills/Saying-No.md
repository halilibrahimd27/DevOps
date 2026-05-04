# "Hayır" Demek — Soft Skill'in Özü

> *"Üstüne aldığın işi yapamadığında verdiğin zarar, **baştan
> 'hayır' demenin** maliyetinden kat kat fazladır. 'Hayır' demek
> kabalık değil, **dürüstlüktür**."*

DevOps/SRE'de "hayır" demek günde 3 kez gerekir: scope creep, premature
commitment, gerçekçi olmayan deadline, alaka dışı talep. Bu rehber
"hayır"ı kişisel rahatsızlık olmaktan çıkarıp **profesyonel iletişim
aracına** çevirir.

---

## 🎯 Niye "Hayır" Demek Zor?

### Türk iş kültüründe bağlam
- **Hiyerarşik beklenti**: "Müdür istedi, yapılır."
- **Yüz kaybı korkusu**: "Hayır" → "yetersiz"
- **İlişki önceliği**: "Hayır" → ilişki bozulur sanılır
- **Belirsizlik toleransı**: "Belki yaparım" tercih edilir

### Sonuç (kötü olan)
- Üstlenilen işler tamamlanmaz → **güvensizlik**
- Tükenmişlik → **istifa**
- Önemli iş ertelenir → **opportunity cost**
- "Hayır" demeyen kişi **kötü kararların taşıyıcısı** olur

> 🔑 **Çözüm:** "Hayır" demek **profesyonel araç**. Doğru söylenen
> "hayır" güveni artırır, ilişkiyi bozmaz.

---

## 🪜 "Hayır" Demenin 5 Yolu

### 1. **"Yes-If"** — Şartlı evet
> "Yapabilirim **eğer** X bırakırsak."

```
Talep:  "Bu sprint'e 5 feature daha sığdırın."
Yes-If: "5'i sığdırırız ama:
         - Test süremiz sıkışır → P95 bug riski %20
         - Tech debt 2 sprint daha gecikir
         Hangisini kabul edelim?"
```

> 🔑 **Trade-off açıkla, kararı yöneticiye bırak.** Bu hem profesyonel
> hem güçlüdür — sen sadece "yapamam" demiyorsun, **maliyet** gösteriyorsun.

### 2. **"Not-Now"** — Zaman shift
> "Bu çeyrek değil, **Q3'te**."

```
Talep:  "Postgres'i Aurora'ya migrate edelim — bu ay."
Not-Now: "Migration 6 hafta + 2 mühendis. Bu ay capacity yok.
          Q3'te slot var. Bu sürede mevcut Postgres'in performansı 
          kritik olmayacak (kontrol ettim). Q3'e koyabilir miyiz?"
```

### 3. **"Not-By-Me"** — Yetki/uzmanlık devri
> "Bu **benim alanım değil**; X ekibi daha uygun."

```
Talep:  "Frontend'de bu modal'ı niye 3 saniyede açılıyor?"
Not-By-Me: "Bu UI rendering tarafı — frontend ekibinden @alice
            daha uygun. Slack'te tag'liyorum."
```

> 🔑 Yönlendirme aktif olmalı (sadece "ben değil" değil, **kim olduğu**).

### 4. **"Not-Worth-It"** — ROI argümanı
> "Maliyet/fayda **yatmıyor** — şu sayılar..."

```
Talep:  "ML modelimizi K8s'ye container'la migrate et."
Not-Worth-It: "Migration 4 hafta. Mevcut SageMaker setup'tan
               kazanç: ~%5 maliyet azalma ($2K/ay).
               4 hafta mühendis maliyeti = $40K. ROI 17 ay.
               Bence şu an SageMaker'da kalalım, başka kazançları olan
               projelere odaklanalım. Q4'te tekrar bakalım."
```

### 5. **"Direct No"** — Açık red
> "**Hayır.** Çünkü..."

Bazı durumlar belirsizliği kaldırmaz:
```
Talep:  "Production'da debug için root access ver bana."
Direct No: "Hayır. Audit + compliance ihlal eder. Debug için 
            staging'de aynı senaryo + tail-sample alalım. 
            Yardımcı olayım."
```

> 🔑 "Direct No" güvenlik, etik, yasal sınırlarda. **Tartışılmaz.**

---

## 📐 "Hayır"ın Çerçevesi

### 3-cümle reçetesi
```
1. ANLADIM: "X istediğini anlıyorum, niye önemli."
2. NEDEN OLAMAZ: "Şu sebepten yapamayız." (gerçek sebep)
3. ALTERNATİF: "Şunu yapabilirim." veya "Şu kişiye sorabiliriz."
```

```
Talep: "Cuma akşamına kadar K8s upgrade'i bitir."
Yanıt: 
  1. "Upgrade'in bu sprint'te bitmesi mobil release'i için kritik, anlıyorum.
  2. Cuma akşam zorlamak prod stability'i riske atar — etcd backup + dry-run
     için 2 gün gerek, kalan 1 gün canary için yetmiyor.
  3. Önümüzdeki çarşamba bitirebilirim — mobil ekibiyle release date'i
     1 hafta öteleme alternatifi de var. Hangisini tercih edersin?"
```

---

## 🚦 Politik Manevralar

### "Sandwich" yöntemi (kibar ama net)
1. Pozitif: "Bu projeye ilgi gösterdiğin için teşekkür."
2. "Hayır": "Ben bu sprint'te alamayacağım."
3. Pozitif: "Yardım edebileceğim başka şey?"

### "Ben değil, sistem" yöntemi
> "Capacity planning'imiz sprint'te 60 saat veriyor. Bu eklersek
> 80 saat. Sistem buna izin vermiyor."

→ Kişisel ret değil, **objektif sınır**.

### "Görünür liste" yöntemi
> "Şu an benim listede şunlar var: A, B, C. Yeni X'i nereye koyalım?"

→ Karar vereni **karara dahil** et. Sırayı o belirler.

---

## 💬 Spesifik Senaryolar

### Yöneticiye "hayır"
**Yapma:**
- "Yapamam, çok meşgulüm." (kişisel)

**Yap:**
- "Şu öncelik listemize bakar mısınız? X yeni eklenirse Y düşmesi gerek. Hangisini tercih edersin?"

> Yönetici bilmiyor: "ben aldığım iş kadar veriyorum sandı." Liste önüne konunca **iyi karar** verir.

### Müşteriye "hayır"
**Yapma:**
- "Bu özelliği yapamayız."

**Yap:**
- "Bu spesifik istek roadmap'imizde değil ama [yakın bir özellik] var. Onunla aradığını bulabiliriz mi? Eğer değilse, [vendor X] sizin için daha iyi olabilir."

> Müşteri "no" almaya değil, **çözüm** almaya gelmiştir.

### Peer'a "hayır"
**Yapma:**
- "Şu an yardım edemem."

**Yap:**
- "Senin sorununu anlıyorum — şu an X'le boğuşuyorum, 2 saat sonra gerçekten yardım edebilirim. Acilse @bob daha uygun olabilir, ya da pair yapalım o zaman."

### Vendor'a "hayır"
**Yapma:**
- "Sözleşme imzalamayacağız."

**Yap:**
- "Şu noktalar bizim için engelleyici: data residency Türkiye'de değil, SLA 99.5% altta, güvenlik audit raporu eksik. Bunlar düzeltilirse Q3'te yeniden konuşabiliriz."

---

## 🎯 "Evet"e Karşı "Hayır"ın Maliyet Analizi

| Durum | Hayır demenin maliyeti | Evet demenin maliyeti |
|---|---|---|
| Kapasite üstü iş | "Birey rahatsızlık" (kısa) | Tükenmişlik + ilişki + hata |
| Yanlış teknik karar | "Patron mutsuz" (kısa) | 6 ay tech debt + müşteri kayıp |
| Compliance ihlali | "Müşteri kızgın" (kısa) | Yasal ceza + güven kayıp |
| Düşük öncelikli feature | "Bu sprint atlanır" (kısa) | Kritik feature gecikir |

> 🔑 **Pratik:** "Hayır"ın maliyeti **kısa süreli sosyal**, "evet"in maliyeti
> **uzun süreli organizasyonel**.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Belirsiz "belki bakarım" | Hayır anlamına gelse bile umut bıraktın | Net evet/hayır |
| "Onu zaman bulduğumda yaparım" | Asla zaman olmaz, taraf umuyor | Kalendarda slot ya da net "hayır" |
| Sürekli evet → tükenmişlik | İstifa, ekip kaybı | Quarterly capacity review |
| "Hayır" + gerekçe yok | İlişkiyi bozar | Gerekçe + alternatif |
| Hayır deyip yine de yapma | Karşı taraf 2 kez kandırılmış olur | Hayır = hayır |
| Hayır deme baskısı altında "evet" | Sonra deadline kaçar | Hemen değil "yarın geri dönüyorum" |
| Public ortamda peer'ı "hayır"la rezil | İlişki kalıcı zarar | DM ya da 1:1 |
| Üst yönetime "yapamam" | Profesyonelce değil | "Şu trade-off ile yapabilirim" |
| Customer success'e "hayır" tek başına | Müşteri kaybı riski | Alternative çözüm + neden |
| Hayır demek "negatif kişi" yapıyor sanma | Kötü hayırların algısı | Doğru hayır → güven |

---

## 📋 "Hayır" Demeyi Pratik Hale Getirme

```
[ ] Quarterly: kapasite review (neyle uğraşıyorum, ne ayrılır?)
[ ] Public görünür roadmap (ne öncelikli)
[ ] "Yes-If" + "Not-Now" + "Not-By-Me" + "Not-Worth-It" + "Direct No" cep'te
[ ] 24-saat kuralı: hemen evet/hayır demek zorunda değilsin
[ ] Manager 1:1: "Şu an boğuşuyorum, ne düşürelim?"
[ ] Trade-off göster: hep alternatif sun
[ ] Gerekçeyi yaz (e-mail/Slack), söz olarak bırakma
[ ] Hayır deyince hayatını rahat hissedeceksen: doğru karar
[ ] Hayır deyince kendine sinirleneceksen: belki evet'tir
[ ] Geriye dönüp "keşke hayır deseydim" hissi varsa: pattern, eğit kendini
```

---

## 🗣️ Cümle Kataloğu — Çekmecede Tut

### Soft "hayır"
- "İlginç bir öneri, ama şu an benim listemde X, Y, Z var. Sıralamada hangisi geri kalsın?"
- "Bunu alabilmek için kapasitemizde değişiklik gerekecek; konuşalım mı?"

### Net "hayır" + alternatif
- "Bu yaklaşımı şu sebepten önermiyorum: [X]. Alternatif olarak [Y] aynı sonucu daha güvenli verir."
- "Bu spesifik istek roadmap'imizde değil ama [yakın özellik] yardımcı olabilir."

### Erteleme
- "Bu çeyrek capacity yok, Q3'te slot var."
- "İlk olarak X'i bitireyim, sonra buna geri dönerim."

### Yönlendirme
- "Bu @alice'in alanı — daha hızlı yardımcı olur."

### Cesur "hayır"
- "Hayır. Compliance / etik / güvenlik açısından buna izin veremem."
- "Hayır, çünkü 6 ay sonra postmortem'de bu kararın bedelini ödüyor olacağız."

---

## 📚 Referanslar

- **The Power of a Positive No** — William Ury (Harvard Negotiation)
- **Crucial Conversations** — Patterson et al.
- **Staff Engineer** — Will Larson (saying-no chapter)
- **An Elegant Puzzle** — Will Larson (capacity, prioritization)
- [`Stakeholder-Management.md`](Stakeholder-Management.md)
- [`Oncall-Sustainability.md`](Oncall-Sustainability.md)
- [`Working-with-Security-Team.md`](Working-with-Security-Team.md)

---

> *"Sürekli 'evet' diyen mühendis, **hiçbir şeyin sahibi**
> değildir. 'Hayır'ları seçmeyen kariyerin yönetiminde değil, **rüzgârın
> savurduğu** yerdedir."*
