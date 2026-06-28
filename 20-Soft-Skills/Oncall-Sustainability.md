---
description: "On-call'ı sağlıklı yönetilebilir bir disiplin olarak ele alır: vardiya tasarımı, post-incident dinlenme, burnout sinyalleri ve önleme taktikleri."
tags:
  - Soft Skills
  - SRE
  - Incident Response
  - Sustainability
  - Culture
---
# On-Call Sürdürülebilirliği — Burnout Olmadan Yangın Söndürme

> *"On-call **işin bir parçası**, ama **işin tamamı** olmamalı.
> Senior'ın istifa nedeni 'iş yoğunluğu' değil, **2 yıldır gece
> uyumamış olmak**."*

Bu rehber on-call'ın "kaçınılmaz kötülük" değil, **sağlıklı yönetilebilir
disiplin** olduğunu varsayar. Vardiya tasarımı, post-incident dinlenme,
burnout sinyalleri ve nasıl önlenir — somut taktiklerle.

---

## 🎯 İlk İlke: On-Call **Ücretli + Düzenli + Sınırlı**

### Ücretli
- Stand-by: saatlik ücret (lokal yasal zorunluluk olabilir)
- Aktif çağrı: ekstra ücret veya izin (TR'de 1 saat aktif → 1.5 saat izin yaygın)
- Hafta sonu / gece: ek katsayı

> 🔑 **Ücretsiz on-call = yasal sorun + moral sorun.** "Senior'lar nasılsa
> yapıyor" mantığı = burnout inkübatörü.

### Düzenli
- Rotasyon **planlı**, son dakika değişim minimum
- Vardiya kalendarda görünür
- Devir teslim resmi (kim, neyin nesi, açık incident)

### Sınırlı
- Primary: **max 1 hafta**, sonra dinlenme
- Yıllık on-call yükü: **8 hafta üst limiti** (savunulabilir)
- 12 ay süreyle aralıksız on-call → istifa riski yüksek

---

## 📐 Sağlıklı Vardiya Tasarımları

### Pattern 1: "Follow the Sun" (Multi-region ekipler)
```
Türkiye saati:  09:00 ────── 17:00
                    [İstanbul ekibi primary]

UTC -5 (NY):           14:00 ────── 22:00
                            [NY ekibi primary]

UTC +9 (Tokyo):                         07:00 ────── 15:00
                                          [Tokyo ekibi primary]
```
- Hiç gece vardiyası yok (ideal)
- Ekip büyük olmalı (3 region)
- Devir teslim disiplini kritik

### Pattern 2: "Primary + Secondary" (tek bölge)
```
Hafta 1:  Alice = Primary,  Bob = Secondary
Hafta 2:  Bob = Primary,    Carol = Secondary
Hafta 3:  Carol = Primary,  Dave = Secondary
...
```
- Primary ack edemezse → secondary'ye otomatik escalation (15 dk)
- Yorgun primary'ı secondary kurtarır

### Pattern 3: "Day + Night Split"
```
Hafta:  Alice = Gündüz primary (09:00-21:00)
        Bob   = Gece primary (21:00-09:00)
```
- 12 saat → 7-8 saat uyku tolere edilebilir
- Gece vardiyası daha kısa rotasyonda olmalı (max 1 hafta)

### Pattern 4: "On-Call Daysoff" (Recovery)
```
On-call hafta sonu → ertesi hafta Pazartesi izinli
Gece sayfa aldıysan → ertesi gün izinli ya da geç başla
```

---

## 🌅 Post-Incident Recovery

### "Post-incident exhaustion" gerçek
SEV1 4 saatlik incident'tan sonra:
- Adrenaline crash (3-6 saat sonra)
- Konsantrasyon: %30-50 düşük (24-48 saat)
- Karar kalitesi: **kötü** (yorgunluk + stres)
- Aile/kişisel ilişkiler: ihmal edildiği için stres

### Politika
| Incident sonrası | Kural |
|---|---|
| SEV1 / 2+ saat | Ertesi gün **izinli** (zorunlu, opsiyonel değil) |
| Gece SEV1 | Ertesi gün izin + 1 hafta on-call istisnası |
| 2 SEV1 üst üste (1 hafta içinde) | Ekibe geri çek, bireysel review |
| Postmortem yazımı | İzin ertesi (yorgun yazılan postmortem zayıf) |

### Manager'in görevi
- "Ne kadar yorgunsun, hayatımı kontrol etmem lazım mı?" — proaktif sor
- Ekipçe takdir et (postmortem'de "great IC work")
- HR / wellness desteği önerisi

---

## 🚨 Burnout Sinyalleri — Erken Yakalama

### Davranışsal değişiklik (peer'lar fark eder)
- "Slack'te dalga geçen" insan suskun
- Toplantıda fikir üretmiyor
- "Nasıl olsa" tonunun artması
- Vardiya değişim taleplerini reddetmiyor (eskiden hayır derdi)

### Performans
- Code review'larda yüzeysel
- PR yorumları azalıyor
- Dokümana zaman ayırmıyor
- "Quick fix" sıklığı artıyor

### Sağlık
- Hasta gün artışı
- "Tatil yok" — son tatili 8+ ay önce
- Kahve / enerji içeceği artışı (kendi raporu)
- Uyku şikâyeti

### Yıllık check-in
1:1'lerde sor:
- "On-call yükün makul mü?"
- "Son tatilin ne zamandı?"
- "Şu an istiyor olduğun değişiklik var mı?"
- **Skip-level 1:1**: manager-of-manager periyodik konuşma

---

## 🛡️ Burnout Önleyici Mühendislik Pratikleri

### Alert Hijyeni — En Önemli
**Burnout'un ana kaynağı: gereksiz alarm.**

| Sayı | Anlam |
|---|---|
| < 3 alert/gün | İdeal |
| 3-10 alert/gün | Tolere edilebilir, hijyen başlangıcı |
| 10-30 alert/gün | Alert spam — sustainability tehlikede |
| 30+ alert/gün | Ekip iflas etmiş, alarm bağışıklığı |

#### Alert review playbook
```
Quarterly:
  1. Son 90 gün alert listesi çıkar
  2. Her alert için: actionable mi? (yes/no)
  3. NO → KAPAT (silinir veya severity düşürülür)
  4. YES → "Bu alert düştüğünde ne yaparım?" runbook var mı?
            yoksa yaz veya alert'i sil
  5. Top 5 noisy alert: dedup / threshold tuning
```

#### Alert kalitesi kuralları
- ✅ Action gerektirir (sadece "FYI" değil)
- ✅ Runbook linki var
- ✅ Severity doğru (PAGE = uyandır, WARN = saat içinde)
- ✅ Spesifik (servis + endpoint adı)
- ✅ Suppression sırasında uygun (maintenance window)

### Runbook'lar
- Her alert → runbook
- Runbook = adım adım: "ne kontrol et, ne dene, ne ile escalate et"
- Şablon: [`17-Templates/runbooks/runbook-template.md`](../17-Templates/runbooks/runbook-template.md)

### Self-healing
- Auto-remediation: pod restart, pool recycle, scale up
- Insan müdahale gerektirmeyen → page yok

### Toil reduction
- "Toil" = manuel + tekrarlayan + value yaratmayan
- Hedef: oncall'ın < %50'si toil
- Quarterly: toil ölçümü + reduction project

---

## 📞 Çağrı Anında Sağlıklı Davranış

### Kişisel
- ✅ Önce 30 saniye nefes al, su iç
- ✅ Çok uykudaysan ack et + secondary'i çağır
- ✅ "Bilmiyorum, sor X SME'ye" demeyi öğren
- ❌ Her şeyi tek başına çözmeye çalışma
- ❌ "Yorgunum" demekten utanma

### Ekip
- IC tek karar verici (klavyeye dokunmaz)
- 4 saatten uzun incident → IC rotate
- Bridge'de "moral check" — "kim yorgun?" 2 saatte bir

### Manager
- Bridge'e "müdahale etmeden" gözlem
- Kahve / yemek getirmek (gerçek)
- Aile durumlarını sor: "X eve ihtiyaç var mı?"
- Ertesi gün sıkı izin enforce

---

## 💸 Tazminat — Türkiye Bağlamı

### Yasal çerçeve (özet, hukuk ekibi onaylı olmalı)
- 4857 sayılı İş Kanunu: hafta tatili, gece çalışma, fazla mesai
- Stand-by süre tartışmalı — sözleşmede tanımlı olmalı
- Aktif çağrı zamanı **mesai sayılır**, ödenmeli veya izinli

### Yaygın tazminat modelleri (TR private sector)
| Tip | Yaygın aralık |
|---|---|
| Stand-by ücret (saatlik) | %15-30 normal saatlik ücret |
| Aktif gece çağrı | 1.5x mesai ücreti |
| Hafta sonu vardiyası | Ek günlük flat fee veya 1.5x izin |
| On-call rotation premium | Aylık flat (örn: $200-500) |

> 🔑 **Şirkete göre değişir.** Önemli olan **yazılı + tutarlı**.

---

## 🏃 Recovery Practices

### Tatil ve disconnect
- Yıllık 14+ iş günü tatil zorunlu (yasal min)
- **Gerçek disconnect** — laptop kapalı, Slack kapalı
- Geri dönüşte **on-call değil** (ilk 1 hafta)

### Sabbatical (uzun süre kıdemli için)
- 5 yılda 1 ay ücretli izin
- Mental reset, yenilenme

### Mental health
- **EAP** (Employee Assistance Program) — terapi erişimi
- Mental health stigma kırma (manager kendisi konuşur)
- "Mental health day" izin tipini kabul

### Egzersiz / hobi
- Şirketin gym membership desteği
- Hobi grubu (ekip içi)
- Yürüyüş 1:1'leri

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "Senior'lar zaten yapıyor" — formal rotation yok | Tek kişi yorulur, bus factor 1 | Resmi rotation + ücret |
| Stand-by ücretsiz | Yasal + moral sorun | Tazminat politikası yazılı |
| Gece SEV1 sonrası tam mesai | Recovery yok, çürüme başlar | Zorunlu izin |
| Alert volume 50+/gün | Bağışıklık + burnout | Alert review quarterly |
| Manager bridge'de panik | IC işini bozar, ekip stresi | Manager destek modunda, müdahale dışı |
| "Tatil yapma" baskısı | Burnout senkronize | Tatil zorunlu, 14+ gün |
| Yeni mühendis 1. ayında primary | Hazır değil, panik | Önce shadow → secondary → primary |
| Postmortem'de bireysel suçlama | Blameless culture yok | Sistem hatası ekiplemek |
| 2 yıl aralıksız aynı kişi primary | "Hero" pattern, istifa | Maksimum 8 hafta/yıl on-call |
| Mental health konuşulmaz | İstifa zamanı dile gelir | Manager periyodik check-in |

---

## 📋 Sürdürülebilir On-Call Checklist

```
[ ] Rotation planlı, 4-8 hafta önceden görünür
[ ] Primary + secondary (escalation 15 dk)
[ ] Vardiya max 1 hafta primary
[ ] Yıllık on-call yükü <= 8 hafta/kişi
[ ] Stand-by ücret + aktif çağrı tazminat yazılı
[ ] Gece SEV1 → ertesi gün zorunlu izin
[ ] 2-saat+ incident → recovery day
[ ] Alert volume < 10/gün/kişi (hedef)
[ ] Quarterly alert hijyeni review
[ ] Her alert → runbook linkli
[ ] Auto-remediation: pod restart, scaling automatic
[ ] Toil < %50 oncall zamanı
[ ] Post-incident retro (hot wash 30 dk içinde)
[ ] Postmortem blameless, action item'lı
[ ] Manager 1:1'de oncall yükü konusu standart
[ ] Skip-level 1:1 6 ayda bir
[ ] Burnout signal training (manager + peer)
[ ] Mental health stigma azaltma (EAP, talk hour)
[ ] Yıllık tatil 14+ gün enforce
[ ] Sabbatical politikası (uzun kıdem için)
```

---

## 📚 Referanslar

- **Google SRE Workbook** — Bölüm 11: Being On-Call
- **PagerDuty Incident Response Documentation**
- **Operations: A Developer's Guide** — Camille Fournier
- **The Manager's Path** — Camille Fournier
- **4857 Sayılı İş Kanunu** — TR yasal çerçeve
- [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md)
- [`00-Culture/On-Call-Playbook.md`](../00-Culture/On-Call-Playbook.md)
- [`Postmortem-Conversation.md`](Postmortem-Conversation.md)

---

> *"Sustainable on-call yapan ekip, **yangın çıkmaz** demez —
> yangın çıktığında **yangıncı yorulup işsiz kalmasın** der.
> Yangıncın değeri, **gelecek yangında oradadır**."*
