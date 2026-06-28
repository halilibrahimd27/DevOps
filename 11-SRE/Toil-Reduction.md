---
description: "Google SRE Book'un toil kavramını, nasıl ölçüleceğini, %50 kuralını ve toil'i azaltmanın somut tekniklerini anlatan pratik rehber."
tags:
  - SRE
  - Culture
  - Performance
  - Field Notes
---
# Toil Reduction — "Ekibin %50'si Toil'da" Demek

> *"Toil = manuel + tekrarlayan + value yaratmayan iş. SRE
> ekibinin %50'sinden fazlası toil'la geçiyorsa, **ekip büyümüyor —
> tükenniyor**. Toil ölçülmeden azaltılamaz."*

Bu rehber Google SRE Book'un **toil** kavramını, nasıl ölçüleceğini,
%50 kuralını, ve azaltmanın somut tekniklerini anlatır.

---

## 🎯 Toil Nedir?

> **Toil**: 4 özelliğe sahip iş:
> 1. **Manuel** (otomatize edilebilir)
> 2. **Tekrarlayan**
> 3. **Reactive / interrupt-driven**
> 4. **Servis büyümesiyle linear ölçeklenir** (otomatize edilmemiş)
> 5. **Engineering value yaratmaz**

### Toil olmayan örnekler
- Yeni feature yazma → engineering work
- Postmortem yazma → öğrenme
- Mentoring → leverage
- Mimari karar → strategic

### Toil örnekler
- Disk dolan node'a SSH ile log temizleme
- DB user şifresi rotation manuel
- "Servisimi prod'a deploy edebilir misin?" ticket'larına cevap
- Aynı alarmı her sabah ack etme
- DNS değişikliği için ticket'ı manuel apply etme
- Yıllık SSL cert renew (cert-manager kullanmadan)

---

## 📊 Toil Ölçümü

### Self-tracking
Her ekip üyesi haftalık:
```
Pazartesi: 4 saat — Vault rotation, manuel
Salı: 2 saat — Pod restart ticket'ları (3 adet)
Çarşamba: 3 saat — DNS update için PR review + apply
Perşembe: 6 saat — Yeni feature build
Cuma: 4 saat — Incident response
```

→ Toil: 9 saat / haftalık 40 = **%22.5**.

### Otomatik (PagerDuty / ticket data)
```promql
# Quarterly toil ratio
toil_hours_per_week / total_engineering_hours_per_week
```

### Hedef: < %50
> Google SRE Book: "Eğer SRE ekibi %50+ toil yapıyorsa, ekip büyüklüğü
> artırılmalı veya **toil otomasyonu** öncelik."

---

## 🚦 Toil Sınıflandırması

| Kategori | Örnek | Otomasyon zorluğu |
|---|---|---|
| **Cluster ops** | Node drain, scale up | Düşük (HPA, Karpenter) |
| **Access** | Yeni dev cluster erişimi | Düşük (OIDC + RBAC) |
| **Deploy** | "PR'ı prod'a yolla" | Düşük (ArgoCD self-sync) |
| **Cert / secret rotation** | TLS, DB password | Orta (cert-manager, Vault rotation) |
| **Monitoring response** | Alarm ack + restart | Orta (auto-remediation) |
| **Migration / upgrade** | K8s version bump | Yüksek (testing + planning) |
| **Compliance / audit** | Annual SOC2 evidence | Yüksek (audit log automation) |

---

## 🛠️ Toil Otomasyon Pattern'leri

### 1. Self-service (en güçlü)
**Eski**: Dev → DevOps ticket → "yeni S3 bucket"
**Yeni**: Dev → Backstage scaffolder → otomatik

```yaml
# Backstage scaffolder action
- id: create-s3-bucket
  action: terraform:apply
  input:
    module: ./modules/s3
    vars:
      bucket_name: ${{ parameters.bucketName }}
      env: ${{ parameters.env }}
```

### 2. Auto-remediation
**Eski**: Alarm düştü → SSH → restart
**Yeni**: Alarm → webhook → otomatik action

```yaml
# Argo Events: pod CrashLoopBackOff → otomatik delete
spec:
  triggers:
    - template:
        name: delete-crashing-pod
        k8s:
          operation: delete
          source:
            resource: '{{ .body.pod }}'
```

### 3. ChatOps
**Eski**: "@ops bunu prod'a uygula"
**Yeni**: Slack `/deploy <service> <env>` → bot çalıştırır

### 4. Operator pattern
**Eski**: Postgres maintenance her hafta manuel
**Yeni**: CloudNativePG operator → declarative

### 5. GitOps
**Eski**: `kubectl apply` her zaman
**Yeni**: PR merge → ArgoCD sync

---

## 🎯 Toil Reduction Project'leri

### Quarterly: Top 3 toil seç + projeye al

```
Quarterly Toil Review

Tracked toil (Q3 ortalama):
  1. Manual cluster upgrade: 16 saat/hafta
  2. Cert renewal: 8 saat/hafta
  3. Access provisioning: 6 saat/hafta
  4. Random pod restart: 5 saat/hafta
  5. Diğer: 12 saat/hafta

Q4 Action Items:
  - P0: cert-manager universal adoption (tasarruf: 8h/hafta)
  - P1: K8s rolling upgrade automation (tasarruf: 12h/hafta)
  - P2: OIDC+RBAC provisioning self-service (tasarruf: 5h/hafta)

Beklenen tasarruf: 25 saat/hafta = 1 ek mühendisin işi
```

### Action item formula
```
Tasarruf (saat/hafta)
÷
Otomasyon maliyeti (saat)
=
ROI (hafta)
```

> Örn: 8h/hafta toil + 80h otomasyon = 10 hafta'da break-even. Sonra net kazanç.

---

## 🚧 Toil Reduction Anti-Pattern'leri

### "Tüm toil otomatize edilebilir" iddiası
- Bazı toil **inherently manual** (insanın karar vermesi gerekir)
- "Postmortem yazma toil" — hayır, **yüksek leverage**
- Tüm toil sıfır = imkansız hedef

### Otomasyon = ek toil
- Otomasyon kendi de bakım ister
- "Otomate ettim, unuttum" → 6 ay sonra bug
- Net toil değerlendirmesi

### Toil tracking interrupt
- "Toil log tutmak da toil" şikâyeti
- Çözüm: PagerDuty + ticket data otomatik aggregate

---

## 📊 Healthy Ekip Toil Dağılımı (Google SRE örnekleminden)

```
Toil               %25-50
Engineering work   %50+
Overhead           %0-15
On-call            %0-25 (rotasyona göre)
```

> 🔑 Toil **sıfır olamaz** ama **dominant olmamalı**.

---

## 🔄 Toil Migration Akışı

### Aşamalı azaltma
```
1. Tier 1 (kolay otomasyon): self-service form, runbook auto-action
2. Tier 2 (orta): operator pattern, GitOps
3. Tier 3 (zor): policy-as-code, ML-based prediction
```

### "Run book → action book" geçişi
- Runbook adımı: "kubectl rollout restart"
- Action book: "alert → webhook → otomatik kubectl"

```python
# Auto-remediation server (basit)
@app.post("/auto-action")
async def handle_alert(alert: dict):
    if alert["alertname"] == "HighDiskUsage":
        node = alert["labels"]["node"]
        await k8s.exec(node, "logrotate -f /etc/logrotate.conf")
        await notify_slack(f"Auto-rotated logs on {node}")
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Toil ölçülmüyor | Bilmediğini azaltamazsın | Quarterly self-track |
| %80 toil normal sanmak | Tükenmişlik garantisi | < %50 hedefi |
| "Hep böyle yapıyoruz" | Otomasyon görmezden gelinir | Quarterly toil review |
| Otomasyon bakım ihmal | Otomasyon kendi de toil olur | Ownership + monitoring |
| Tek mühendis tüm toil sahipleniyor | Burnout | Rotasyon + paylaşım |
| Self-service mevcut, dev kullanmıyor | Adoption düşük | Marketing + onboarding |
| Auto-remediation aggressive ilk gün | False positive prod kapatır | Aşamalı |
| Manuel runbook günlük çalıştırılıyor | Otomasyon adayı | Cron / operator |
| Postmortem'da toil görünmez | Pattern keşfedilmez | "Bu manuel adım niye?" sor |
| OKR'da "toil reduce" yok | Ölçülmez, prioritize edilmez | Quarterly goal: -%X toil |

---

## 📋 Toil Reduction Checklist

```
[ ] Toil ölçüm mekanizması (self-track / PagerDuty)
[ ] Quarterly toil review meeting
[ ] Top 5 toil listesi (saatlik etki)
[ ] OKR'da toil reduction hedefi
[ ] Self-service (Backstage scaffolder, IDP)
[ ] Auto-remediation (Argo Events, custom)
[ ] ChatOps (Slack /command)
[ ] Operator pattern (Postgres, RabbitMQ, vb.)
[ ] GitOps (manual kubectl yok)
[ ] cert-manager universal
[ ] Vault rotation otomatik
[ ] Otomasyon ownership: kim maintain ediyor?
[ ] ROI hesaplaması (saat tasarruf / saat yatırım)
[ ] Annual: toil dağılımı raporu (yöneticilere)
[ ] Burnout sinyali: toil > %50 → escalate
```

---

## 📚 Referanslar

- **Google SRE Book** — Bölüm 5: Eliminating Toil
- **The Practice of System and Network Administration** — Limoncelli et al.
- **Argo Events** — argoproj.github.io/argo-events
- [`Incident-Response.md`](Incident-Response.md)
- [`Runbook-Template.md`](Runbook-Template.md) — auto-remediation
- [`SLI-SLO-Error-Budget.md`](SLI-SLO-Error-Budget.md)
- [`13-Platform-Engineering/Internal-Developer-Platform.md`](../13-Platform-Engineering/Internal-Developer-Platform.md) — self-service
- [`20-Soft-Skills/Oncall-Sustainability.md`](../20-Soft-Skills/Oncall-Sustainability.md)

---

> *"Toil 'kötü' değil — **görünmez** olduğunda kötü. Ölçülen toil
> projeye dönüştürülebilir; ölçülmeyen toil ekibi **sessizce
> yorar**."*
