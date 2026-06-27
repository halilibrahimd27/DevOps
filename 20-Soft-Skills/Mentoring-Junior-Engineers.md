---
description: "DevOps/SRE/Platform alanında junior mühendisi yetiştirmenin somut tekniklerini, on-boarding planını, shadow-solo geçişini ve TR iş kültürünü anlatır."
---
# Mentoring Junior Engineers — Infra/SRE Öğretmek

> *"Senior'ın görevi 'kendi başına en hızlı kim?' yarışı değil —
> **6 ay sonra ekipte 5 senior**'lık iş yaparak kim kalır.
> Mentoring, **leverage'ı çoğaltma sanatı**."*

Bu rehber DevOps/SRE/Platform alanında junior mühendisi yetiştirmenin
somut tekniklerini, on-boarding planını, "shadow → solo" geçiş
disiplinini, ve TR iş kültüründeki spesifik dinamikleri anlatır.

---

## 🎯 Niye Mentoring?

| Olmazsa | Olunca |
|---|---|
| Senior bus factor 1, ayrılırsa felaket | Bilgi yayılmış |
| Junior 1 yılda istifa | Junior senior'a evrildi |
| "Aynı incident 3 kez" | Junior çözüyor, senior delegasyon yapabiliyor |
| Manager 24 saat ticket fakirliği | Self-service ekip |

> 🔑 **Mentoring = ekip leverage'ı.** Senior'ın yaptığı şey değil,
> **yapma kapasitesini çoğaltan şey**.

---

## 🪜 4-Aşamalı On-Boarding

### Aşama 1: Shadow (1-2 hafta)
> "İzle, sor, **bir şey yapma**."

Junior:
- IC'nin yanında oturur (incident'ta)
- Code review'lara dahil edilir (yorum yapmaz, okur)
- Standup'lara katılır
- 1:1'lerle ekip yapısını öğrenir

Mentor görevi:
- Kararlarının **gerekçesini** sesli düşün
- "Niye bunu yaptım?" diye sorulan ihtimalleri açıkla
- Junior'a **soru sorma** alanı yarat

### Aşama 2: Pair (2-4 hafta)
> "Birlikte yap."

Junior:
- Senior ile pair coding
- Senior'ın kodunu junior klavyeye yazıyor (mental model'i geliştirir)
- Küçük PR'lar — senior review

Mentor görevi:
- "Sen yap, ben izliyorum" — ama müdahale et yanlış gittiğinde
- Hata yapması için alan yarat (nondestructive contexts)

### Aşama 3: Deputy (1-3 ay)
> "Sen yap, **ben yedek**."

Junior:
- Solo PR açar, senior reviewer
- On-call shadow → secondary
- Küçük incident'larda IC

Mentor görevi:
- Geri planda izle
- Sadece **kritik durumlarda** müdahale
- Daily 1:1 (ilk 2 hafta), sonra weekly

### Aşama 4: Solo (3+ ay)
> "Bağımsız çalışıyor, **sen sıradaki yetiştiriyorsun**."

Junior:
- Solo on-call primary
- Kendi PR'larını sahipleniyor
- **Yeni junior'a mentor**

---

## 🧠 Bilgi Aktarım Yöntemleri

### 1. **Sesli Düşünme** (Senior'ın gücü)
```
Senior: "Bu pod CrashLoopBackOff. Önce niye olduğunu görmek için
         events'lara bakacağım. `kubectl describe pod` yerine
         `kubectl get events --sort-by=.lastTimestamp` daha temiz
         çünkü..."
```

> Junior senior'ın **karar yapısını** öğrenir, sadece komutu değil.

### 2. **"Niye?" Cevabını Hep Yaz**
- PR review'da "şunu yap" yerine "şunu yap çünkü..."
- ADR / RFC'lerde "niye?" 50% içerik

### 3. **Failure Story Anlat**
```
"3 yıl önce şu hatayı yaptım: production'da migration
 expand/contract olmadan deploy ettim. Sonuç: 30 dakika downtime.
 O günden beri her schema migration'da expand/contract pattern."
```

→ Senior'ın hataları **junior'ın eğitimi**.

### 4. **Kod Okuma Ekzersizi**
Haftalık 30 dakika:
- Senior bir open-source repo açar (örn: Cilium, ArgoCD)
- Birlikte 1 dosya okur
- "Niye böyle yazılmış?" tartışılır

> Junior **kod okumayı** öğrenir, sadece yazmayı değil.

---

## 🇹🇷 Türkçe Bağlam — Junior'ın "Soru Sorma" Çekincesi

### Pattern (Türkiye/Pakistan/Hindistan)
- Hiyerarşik kültürde junior senior'a soru sormaktan çekinir
- "Bilmiyorum" demek = yetersizlik gibi algılanır
- Senior "ben de bilmiyorum" derse junior güveni gelir

### Yapılması gerekenler
- Senior **kendi bilmediğini ilk söyler**: "Bu konu için emin değilim, X dokümana bakalım"
- Junior'a "aptal soru yok" derken **gerçekten** uygula
- "Ben senin yerinde olsam yapmam" gibi kibirli ifade kaldır
- "Sorman güzel, ben de bilmiyordum bir zamanlar" → güven veren ton

### Anti-pattern: junior'a "test" yapma
- "Bunu sen biliyor musun?" diyip cevap bekleme = sınav korkusu
- Onun yerine: "Bu konuyu birlikte keşfedelim"

---

## 📋 1:1 Yapısı (Junior İçin)

### Frequency
- İlk ay: **günlük** 15 dk
- 2-3. ay: **haftalık** 30 dk
- 3+ ay: **iki haftada bir** 30-45 dk

### Şablon
```
1. Nasılsın? (5 dk)
   - İş yükü makul mü?
   - Aşırı stres var mı?
   - Yeterince uyuyor musun?

2. Bu hafta ne öğrendin? (10 dk)
   - Spesifik teknik
   - Karar / yargı
   - Failure (yapan değil)

3. Engel var mı? (10 dk)
   - Tool / erişim
   - Bilgi gap'i
   - İlişkisel zorluk

4. Sonraki çeyrek hedef? (5 dk)
   - 1-2 spesifik öğrenme alanı
   - Sahiplenmek istediği proje
   - Conference / kurs?
```

> 🔑 1:1 **status update değil** — kişisel gelişim.

---

## 🎯 Spesifik Öğrenme Yolları (DevOps Junior)

### İlk 3 ay: Foundations
- Linux process / file system / networking basics
- Git fundamentals + workflow
- Docker basics + multi-stage build
- Kubernetes basics: Pod, Deployment, Service
- One programming language (Python / Go / Bash)

### 3-6 ay: Production
- Observability: metrics + logs + traces (OTel)
- CI/CD: GitHub Actions / GitLab pipeline yazımı
- IaC: Terraform / OpenTofu basics
- Incident response: shadow IC

### 6-12 ay: Advanced
- Service mesh / NetworkPolicy
- Database fundamentals (Postgres prod)
- Security: scan, signing, policy
- Cost optimization
- Threat modeling

### 1-2 yıl: Senior path
- Mimari kararlar
- Cross-team etki
- RFC yazma
- Mentoring (yeni junior'a)

> 📚 Bu repo'nun **00-18 numaralı bölümleri** bu yolu takip eder.

---

## 🛠️ Pratik Ödev Örnekleri

### "Toy" production cluster
- Kendi K8s cluster'ı (kind / minikube / lab)
- Bir microservice deploy et: build → push → CI → ArgoCD
- HPA + alarm + dashboard kur

### Code reading
- ArgoCD'nin sync logic'i: `controller/sync.go`
- Cilium'un L7 policy: kafka filtering
- Postgres `pg_stat_activity` query'leri

### Side project
- Internal tool (örn: pod yaş raporlayıcı)
- 6 hafta solo proje
- Sonunda demo + retrospective

---

## ⚠️ Mentoring Anti-Pattern'leri

### Mentor tarafı
| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "Hadi sen yap, çıktıda gör" | Frustrasyon | Aşamalı (shadow → pair → solo) |
| "Bu basit, niye anlamadın?" | Junior susar | "Bu kavramı geliştirmek için..." |
| Sürekli müdahale | Junior öğrenemez | Hata için alan ver |
| "Hep böyle yapılır" | Otorite + öğrenme yok | Gerekçeyi açıkla |
| Code review'da sadece syntax | Tasarım öğrenmiyor | Tasarım sorularıyla derinleş |
| Boş "tebrikler" | Junior sahte güven | Spesifik takdir |
| Mentoring zamanı yok | Junior gelişmiyor | Manager: mentor zamanını **iş** sayar |
| Tek tip mentoring | Herkes farklı öğrenir | Kişiye uyarlanmış |

### Junior tarafı
| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Soru sormaktan çekinmek | Yanlış kavramla ilerler | "Aptal" sorulara izin ver kendine |
| Aldığı her tavsiyeye evet | Eleştirel düşünce gelişmez | "Niye böyle?" sorgu |
| Mevcut sürüyü taklit | Junior'lık etiketinde kalır | Yeni öneriler getir |
| Tatil yok / aşırı çalışma | Burnout 6 ayda | Sürdürülebilir tempo |
| 1:1'e hazırlıksız | Mentoring değer kaybı | Konu listesi hazırla |
| "Mentor'umun zamanını almayayım" | Öğrenme yavaş | Mentor için mentoring **iş** |

---

## 🎓 Mentor Olarak Sen — Kalite Ölçümü

### Junior'ın 6 ay sonraki durumu
- Tek başına PR sahipleniyor mu?
- Code review yapabiliyor mu?
- Incident'ta IC olabiliyor mu?
- Senior mu eğitmeye başladı?

### Mentee feedback (anonim)
Quarterly:
- "Mentor'un sana en fayda sağladığı 3 şey?"
- "Mentor'un sana fayda sağlamayan 1 şey?"
- "Sonraki çeyrekte ne odaklansın?"

### Self-reflection
- Bu hafta junior'a ne öğrettim?
- Hangi karar gerekçesini sözlüğe çıkardım?
- Junior'ın hatalarına nasıl tepki verdim?

---

## 📋 Mentoring Checklist

```
[ ] Junior on-boarding planı (4 aşama: shadow → pair → deputy → solo)
[ ] İlk ay günlük 1:1
[ ] Aşamalar net: ne zaman shadow biter, ne zaman solo başlar
[ ] Junior'a yazılı öğrenme yolu (3 / 6 / 12 ay hedefler)
[ ] Pair coding session'ları (haftada 2-3 saat)
[ ] Code reading ekzersizi (haftalık 30 dk)
[ ] Failure story sharing (senior'ın hataları)
[ ] On-call shadow → secondary → primary akışı
[ ] Mentor zamanı **iş** sayılır (manager onaylı)
[ ] Junior'ın tatili erken sprint'lerde garantili
[ ] Quarterly mentee feedback (anonim)
[ ] Mentor self-reflection
[ ] Yeni junior'a mentoring zinciri (junior → senior → yeni junior)
[ ] TR-spesifik: "soru sormak güç değil" mesajı tekrarla
```

---

## 📚 Referanslar

- **The Manager's Path** — Camille Fournier
- **An Elegant Puzzle** — Will Larson
- **Staff Engineer** — Will Larson
- **The Effective Engineer** — Edmond Lau
- **Radical Candor** — Kim Scott
- [`Postmortem-Conversation.md`](Postmortem-Conversation.md) — psikolojik güvenlik
- [`Stakeholder-Management.md`](Stakeholder-Management.md)
- [`Saying-No.md`](Saying-No.md)
- [`Oncall-Sustainability.md`](Oncall-Sustainability.md) — junior'ı yorma

---

> *"Junior'ı senior yapmanın fark'ı senin değer'in değil — **ekibin
> bir mühendis daha kazandığı**. 6 ay sonra senin yapmadığın işin
> birinin yaptığını gördüğünde, **mentoring'in tanımı budur**."*
