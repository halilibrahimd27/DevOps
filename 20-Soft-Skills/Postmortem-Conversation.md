# Postmortem Conversation — Blameless'i Konuşmaya Yansıtmak

> *"Postmortem dokümanı 'blameless' olabilir; ama ekibin **kullandığı
> dil** suçlamayla doluysa, doküman süslemedir. **Konuşma** kültürün
> taşıyıcısıdır."*

Bu rehber blameless culture'ı **gerçek konuşmaya** nasıl yansıtacağını,
fasilitasyon teknikleri, karşılaşılan tipik dil tuzakları, ve "psikolojik
güvenlik" yaratmanın somut adımlarını anlatır.

---

## 🎯 İlk İlke: Psikolojik Güvenlik

> **Psikolojik güvenlik**: "Hata yaparsam ya da bilmediğimi söylersem,
> ekipte cezalandırılmam." (Amy Edmondson, Harvard)

| Yüksek psikolojik güvenlik | Düşük psikolojik güvenlik |
|---|---|
| "Bu kararı ben verdim, X şey hesap edememişim" | Suskunluk, açıklama yok |
| "Burada gap görüyorum, fix önerim..." | Sadece senior konuşur |
| Junior soru sorar | Sorular toplantı sonrası 1:1'de |
| Yanlış varsayım açıkça düzeltilir | Yanlış varsayım üzerine inşa |
| Postmortem'de detaylı timeline | "Çözüldü, bir daha olmaz" |

---

## 💬 Dil Tuzakları (yapma)

### "Yapma" listesi
| Cümle | Sorun |
|---|---|
| "Niye bunu kontrol etmedin?" | Kişiyi hedef alır |
| "Aslında çok basitti, fark etmemen tuhaf" | Küçümser |
| "Senior olarak bunu bilmen gerekirdi" | Otorite + suçlama |
| "Biz bunu hep yaparız, ilk kez mi görüyorsun?" | İçeriden/dışarıdan ayrımı |
| "Bu hata bir daha olmamalı" | Kişiselleştirir, sistem değil |
| "Konsantre olmalıydın" | Bireysel suçlama |
| "Test yazmamış olman büyük hata" | Dürtüsel, sebep aramaz |
| "Bu kararı kim verdi?" | Bulup-cezalandırma akışı |
| "Production'da ne işin vardı?" | Suçlama tonu |
| "Şu kişi bunu yaptı" | Etiketleme |

### "Yap" listesi
| Cümle | Niye iyi |
|---|---|
| "Hangi süreç bu hatayı yakalamadı?" | Sistem-perspektifli |
| "O an o adımı atmana hangi sinyal yönlendirdi?" | Karar bağlamını çıkarır |
| "Eğer X bilseydin farklı yapar mıydın?" | Bilgi gap'i araştırır |
| "Bu kararın o anki bilgiye göre **mantıklıydı**" | Hindsight bias engellerz |
| "Burada bir gap görüyorum: ..." | Sistem önerisi |
| "Hangi tool bunu fark ettirseydi yardımcı olurdu?" | Yapısal çözüm sorgulama |
| "Postmortem'de bu pattern tekrar var mı?" | Sistemic perspektif |
| "Bu konu hassas; konuşmak ister misin?" | Empati |
| "Sen orada olduğun için elimizden geleni yaptık" | Takdir |
| "Hangi tarafı daha iyi yapardık birlikte?" | Birlikte öğrenme |

---

## 🎤 Fasilitasyon Pratikleri

### 1. Tone Setting (ilk 5 dakika)
```
"Bu postmortem'in amacı:
 - Ne olduğunu net anlamak
 - Sistem hatalarını bulup gelecek için kapatmak
 - Ekibin öğrenmesi

Bu postmortem'in amacı DEĞİL:
 - Suçlu bulmak
 - Performans değerlendirmesi
 - HR documentation

Soruyu 'kim' ile başlatırsak fasilitatör olarak yöneltirim.
Soruyu 'ne, niye, nasıl' ile başlatın."
```

> 🔑 **Açılışta** bunu söylemek herkesin standardı internalleştirmesini sağlar.

### 2. Round-Robin Soru
"Senin perspektifinden ne oldu?" — herkes sırayla konuşur. **Sessiz olanı söze davet et.**

```
Fasilitatör: "@junior, sen log'lara baktın o sırada, ne gördün?"
              (önce junior'a soru → senior baskı yapamıyor)
```

### 3. Silence is Data
3 saniye sessizlik OK. "Doldurma" ihtiyacı duyma. Sessizlik insanlara düşünme alanı verir.

### 4. "Bu noktada hangi bilgi vardı?"
Hindsight bias engellemek için:
```
"O an screenshot'taki dashboard'u gördüğünde ne karar verdin?"
"O dashboard'u görseydim ben de aynı kararı verirdim — ne olabilir?"
```

### 5. "Bu kararı veren tek kişi sen değildin" tonlamasıyla
- "X'i sen mi yapmıştın?" yerine
- "X yapıldı, hangi süreçten geçti?"

### 6. Defansiviteyi tespit et + redirect
```
Senior (defensif): "Test yapamam, zaten 5 incident'tan dolayı yorgundum"
Fasilitatör: "Yorgunluk bağlamı önemli. Ekibin yük dağılımı bu olayda
              katkı yapmış olabilir. Bunu Action Item'a ekleyelim?"
```

→ Suçtan **sistemli iyileştirmeye** geçirir.

---

## 🚫 Konuşmada Sık Karşılaşılan Tuzaklar

### Tuzak 1: "5-Whys" yüzeysel kalır
```
Niye: Pool tükendi
Niye: Config 100 → 50 yapıldı
Niye: Test'te 50 yetiyordu  ← STOP, çok yüzeysel
```

**Daha derin gitme**:
```
Niye test prod'u temsil etmiyordu?
  → Load test setup eksik
Niye eksik?
  → SRE backlog'da, yapılmadı
Niye SRE backlog büyük?
  → Platform team yetersiz personel
  → ✓ Sistem-level action
```

### Tuzak 2: "Bu çok karmaşık, çoğunluk anlamaz"
**Çözüm**: Karmaşık konu varsa bridge'i daha kalabalık yap, ama **fasilitatör** açıklamayı kontrol etsin. Junior'ın "anlamadım" dediği yerde **diagram çiz**.

### Tuzak 3: Hot wash'te tartışma uzaması
**Çözüm**: 30 dakika kuralı. Süre dolduğunda:
```
"Bu noktayı action item'a ekledim, postmortem review'da derinleşeceğiz."
```

### Tuzak 4: Manager'in postmortem'de süpresif olması
**Sorun**: Manager "ben anlatayım" → ekip susar.
**Çözüm**: Manager **fasilitatör değil**. Author + IC anlatsın, manager **dinleyici**.

### Tuzak 5: Postmortem'in "show" olması (CEO için)
**Sorun**: Postmortem internal değil, executive show.
**Çözüm**: Iki farklı doküman:
- **Internal blameless postmortem**: timeline, root cause, action items
- **Executive summary**: 5 satır (impact, cause, fix, action)

---

## 🇹🇷 Türkçe Bağlam

### Hiyerarşi pattern'i
- "Müdür değiniyorsa o doğru" → blameless'e zarar
- Junior senior'ı düzeltmekten çekinir
- "Ben senin yerinde olsam yapmazdım" → kibir

### Çözüm: Açık sözlü kültür
- Manager **kendi hatasını** ilk anlatır ("Ben şu kararı 6 ay önce verdim, geriye dönüp bakınca...")
- Junior'a sorulan ilk soru
- Türkçe nüans: "kabahatli" / "hata yapan" gibi suçlayıcı kelimeleri kaldır

### Türkçe blameless dil sözlüğü
| ❌ Suçlayıcı | ✅ Blameless |
|---|---|
| "Hata yaptın" | "Bu adımda sürpriz vardı" |
| "Kabahat sende" | "Sistem bu noktayı kapatmamış" |
| "Bilmen gerekirdi" | "Bu bilgi nasıl iletilebilirdi?" |
| "Dikkatsizlik" | "Süreç boşluğu" |
| "Yanlış yaptın" | "O an mevcut bilgiyle mantıklı bir karardı" |
| "Yine X yaptı" | "Bu pattern tekrar etti" |

---

## 🎓 Junior'ın Postmortem'e Hazırlanması

### Onboarding
- 3 önceki postmortem'i oku
- Bir postmortem'in fasilitasyonunda **shadow** ol
- Fasilitatörden feedback al

### "Bilmiyorum" demeyi öğren
```
"Bu konu için yeterli context'im yok. @senior açıklayabilir mi?"
```
**Junior gücü**: gerçekten anlamadığını gösterebilmek. Senior'ın "ben de tam emin değildim" cesareti junior'ın bunu öğrenmesinden gelir.

---

## 🛠️ Fasilitasyon Araçları

### Anonymous feedback toplama
Bazı insanlar bridge'de söyleyemez:
- Postmortem öncesi anonim form (Google Form / Tally)
- Soru: "Bu olayda dile getirilmemiş bir şey var mı?"
- Fasilitatör cevapları derler, anonim sunar

### Pre-mortem (proactive)
Yeni feature öncesi:
```
"Bu feature 6 ay sonra postmortem'e neden olabilir?"
   - Edge case'ler
   - Skala problemi
   - Vendor bağımlılığı
   - Migration riski
```

→ Hata olmadan önce **fikir egzersizi**.

### "What did we learn?" segment
Postmortem sonunda:
```
Round-robin: "Bu olaydan sen şahsen ne öğrendin?"
```

> Personalleşmiş öğrenme + ekip içi paylaşım.

---

## 📋 Postmortem Conversation Disiplin Checklist

```
[ ] Fasilitatör atanmış (IC değil ideal)
[ ] Açılışta blameless reminder (5 dk)
[ ] Round-robin: junior önce konuşur
[ ] "Niye?" soruları sistem'e yöneltilir, kişiye değil
[ ] Hindsight bias engellenir ("o an hangi bilgi vardı?")
[ ] Defansiviteyi tespit + redirect
[ ] Suçlayıcı dil yakalanır + reframe
[ ] Manager dinleyici, fasilitasyon değil
[ ] Karmaşık konularda diagram çizilir
[ ] Pre-mortem yapılır (önemli feature için)
[ ] Anonymous feedback opsiyonu (sensitive konular)
[ ] "Ne öğrendik" segment sonda
[ ] Action item: spesifik, sahipli, tarihli
[ ] Junior'a postmortem onboarding
[ ] Quarterly: postmortem facilitation training
[ ] Yıllık: psikolojik güvenlik survey
```

---

## 📚 Referanslar

- **Amy Edmondson — The Fearless Organization** (psikolojik güvenlik)
- **Etsy Debriefing Facilitation Guide**
- **John Allspaw — Blameless PostMortems and a Just Culture**
- **Crucial Conversations** — Patterson et al.
- [`Oncall-Sustainability.md`](Oncall-Sustainability.md)
- [`Working-with-Security-Team.md`](Working-with-Security-Team.md)
- [`Stakeholder-Management.md`](Stakeholder-Management.md)
- [`11-SRE/Postmortem-Practice.md`](../11-SRE/Postmortem-Practice.md) — yapısal süreç
- [`00-Culture/Blameless-Postmortem-Template.md`](../00-Culture/Blameless-Postmortem-Template.md)

---

> *"Blameless **doküman değil, kelime seçimidir**. 'Niye sen?' yerine
> 'niye sistem fark etmedi' diye soran ekip, **6 ay sonra** birinin
> ayrılma sebebini değil, **birinin neyi geliştirdiğini** anlatır."*
