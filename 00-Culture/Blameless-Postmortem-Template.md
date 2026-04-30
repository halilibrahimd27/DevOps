# Blameless Postmortem — Felsefe ve Şablon

> *"Blameless" = "Suçsuz" değil; **suçlamayan**. Sistem hatasını
> anlamak için kişilere odaklanmaktan vazgeçmek demek.*

---

## 🎯 Niye blameless?

Blameful kültürde olanlar:
- Mühendisler hata yapma korkusuyla **risk almaz** → inovasyon ölür
- Gerçek kök neden raporlanmaz, "kahraman X düzeltti" denir
- Aynı incident 6 ay sonra tekrar yaşanır
- En iyi mühendisler ayrılır (ortam toksik)

Blameless kültürde:
- Sistem zayıflıkları **nokta atışı** açıklığa çıkar
- Aksiyon maddeleri **gerçekten** kapatılır
- Yeni gelen biri günlerce eski incident'leri okuyup öğrenir

---

## 🚫 Anti-örnekler ("blameful" tonun nasıl olur")

| Blameful | Blameless |
|---|---|
| "Charlie yanlış kod yazdı" | "Code review sürecimizde N+1 detector yoktu" |
| "Op ekibi prod'a yanlış deploy etti" | "Manuel deploy süreci human error'a açıktı; otomasyon eksikti" |
| "Geliştirici test yazmadı" | "Test policy'miz lokal seviyede, CI gating'i yoktu" |
| "Manager onaylamadı" | "Approval flow'umuzda escalation path tanımsızdı" |
| "Charlie unutmuş" | "Sistemimiz unutmaya tolerant değildi" |

> 🔑 **Kural:** "X yapmadı" diyebileceğin yerde "Sistemimiz X'e dirençli değildi" yaz.

---

## 📐 Postmortem nedir? (kapsam)

- **Bir incident'in** nedenleri, etkisi, zamanlaması, alınan dersler
- **Statik doküman** değil — review edilir, güncellenir, aksiyonları takip edilir
- Gizli değil — şirket içinde **herkese açık** (varsa müşteri-impacting tarafı redact edilir)
- "Olay raporu" değil — **öğrenme aracı**

---

## ⏱️ Ne zaman yazılmalı?

Trigger'lar:
- ✅ Customer-impacting outage (her zaman)
- ✅ SLO breach (error budget yendi)
- ✅ Significant near-miss (patlamadı ama kıl payı)
- ✅ Sürpriz davranış (sistem tahminden farklı çalıştı)
- ✅ Manuel olarak istenirse

24-48 saat içinde **ilk draft**. 1 hafta içinde finalize. Her aksiyon bir
ticket'a dönüşmeli, bir owner'a atanmalı.

---

## 🧑‍💻 Roller

| Rol | Sorumluluk |
|---|---|
| **Author** | Postmortem'i yazar (genelde IC = incident commander) |
| **Reviewer (≥2)** | Eksik perspektif, blameful tone, eksik aksiyon yakalar |
| **Service owner** | Aksiyon maddelerini sahiplenir |
| **Engineering manager** | Aksiyonların kapatıldığını takip eder |

---

## 🧩 Postmortem Şablonu (kopyala-doldur)

> Kullanıma hazır şablon: [`17-Templates/runbooks/postmortem-template.md`](../17-Templates/runbooks/postmortem-template.md)

Bölümler:

```
1. TL;DR (3 cümle)
2. Etki (metrik tablo: downtime, kullanıcı, revenue, SLO impact)
3. Zaman çizelgesi (UTC, dakika hassasiyetinde)
4. Kök Neden (sistem perspektifinden)
5. Niye yakalanmadı? (savunma katmanlarının her biri)
6. Ne iyi gitti?
7. Ne iyi gitmedi?
8. Aksiyon Maddeleri (owner, due, measurable)
9. Metrik delillerine link (dashboard, PR, log)
10. Öğrenilenler (ders)
11. Postmortem'e katılanlar
```

---

## 🛡️ Reviewer Checklist

Postmortem PR'ında reviewer şunları kontrol etmeli:

### Tone
- [ ] Hiçbir cümle bir kişiyi suçlu gibi göstermiyor
- [ ] "X yapmadı" yerine "sistemimiz X'e dirençli değildi"
- [ ] Pasif ses kullanılmamış (gizli özne yok)

### Bilgi
- [ ] Zaman çizelgesi UTC ve dakika hassasiyetinde
- [ ] Etki sayısal (kaç dakika, kaç user, kaç EUR)
- [ ] PR/commit/dashboard linkleri var

### Aksiyonlar
- [ ] Her aksiyon bir owner ve due date sahip
- [ ] Aksiyonlar **measurable** ("daha dikkatli olalım" reject)
- [ ] En az bir "preventive" + bir "detective" aksiyon var
- [ ] Action item'lar JIRA/Linear'da ticket olarak açıldı

### Sistemik bakış
- [ ] "5 niye?" derinliği var (yüzeysel cevapta durmamış)
- [ ] Birden fazla savunma katmanının niye yetmediği analiz edilmiş
- [ ] "Bunu sıralı sebep zinciri" değil "swiss cheese model" diyor

---

## 🧠 "5 Whys" — niye 5?

Yüzeysel "neden"e takılmamak için. Örnek:

```
Q: Niye prod 14 dk down oldu?
A: Yeni deploy'da N+1 query DB'yi boğdu.

Q: Niye N+1 review'da yakalanmadı?
A: Reviewer ORM'in lazy-load davranışını bilmiyordu.

Q: Niye reviewer bilmiyordu?
A: Onboarding'de bu pattern öğretilmiyor.

Q: Niye onboarding'de yok?
A: Onboarding 6 ay önceki halde, ORM o zamandan beri değişti.

Q: Niye onboarding güncellenmedi?
A: Sahibi yok; "platform team yapar" diye bekleniyor.

→ Aksiyon: onboarding'in bir owner'ı olsun + 6 ayda bir review.
```

5 katman aşağı inmeden gerçek sistemik sebebe ulaşamazsın.

---

## 🎬 Postmortem toplantısı (review)

İlk draft'ın 1 hafta içinde — bir saatlik toplantı.

### Gündem (yapılandır)

```
[10 dk] Author postmortem'i okur (yüksek sesle, herkes aynı baseline'da)
[20 dk] Sorular ve eksiklikler — "şu kısım net değil"
[15 dk] Aksiyon maddeleri — owner ataması, due date
[10 dk] Diğer öğrenilenler — başka servislere transfer
[5 dk]  Follow-up sahipliği
```

### "Devil's advocate" rolü

Birini kasten "iyi durdu mu sahiden?" sorularıyla görevlendir.
Postmortem'in yanlı olmasını engeller.

---

## 📚 Postmortem'lerin değeri zamanla artar

- **Kurum hafızası** — yeni gelenler okur, aynı hataları tekrarlamaz
- **Pattern detection** — 6 postmortem aynı root cause'u gösterirse bu **yapısal bir sorun**
- **Onboarding aracı** — yeni mühendis için "hangi alanlar tehlikeli" belirir
- **Dış yayın** — bazı şirketler sanitized postmortem'leri public yayınlar (örn: Stripe, Cloudflare, GitHub) — community trust inşa eder

> Önerim: postmortem'leri **company wiki** veya **internal blog** gibi
> yerde host'la, search'lenebilir olsun. PDF veya kapalı doc'larda
> kaybolurlar.

---

## ✅ Sağlıklı kültür sinyalleri

- Junior bir mühendis postmortem yazmaktan **çekinmiyor**
- Aksiyon maddelerinin **>%70'i 2 hafta içinde** kapanıyor
- Her ay en az **1 postmortem** üretiliyor (yoksa: ya tane miss ediliyor ya stres altında saklanıyor)
- Senior mühendisler postmortem'leri **kendi başına okuyup kazanıyor**
- Postmortem'lerde "Manager X buna karar verdi" yerine "ekip Y'in trade-off'ları" var

---

## 📚 Devamı

- [Etsy's Debriefing Facilitation Guide](https://etsyjs.gitbook.io/debriefing-facilitation-guide/)
- [Google SRE Book — Chapter 15](https://sre.google/sre-book/postmortem-culture/)
- *The Field Guide to Understanding Human Error* — Sidney Dekker
- [`17-Templates/runbooks/postmortem-template.md`](../17-Templates/runbooks/postmortem-template.md) — kullanıma hazır
