---
description: "Alert runbook template: adım-adım ilk teşhis komutları, olası sebepler ve çözümler, rollback prosedürü, eskalasyon matrisi ve incident kapanış doğrulaması."
tags:
  - Template
  - Incident Response
  - SRE
  - Observability
---
# Runbook: <ALERT_NAME / SCENARIO>

> **Severity:** P1 / P2 / P3
> **Service:** `<service-name>`
> **Owners:** @team-handle (Slack: `#team-channel`)
> **On-call rotation:** [PagerDuty link]
> **Last verified:** YYYY-MM-DD

---

## 🎯 Bu sayfa ne için?

Bu alert düştüğünde / bu durum oluştuğunda ne yapılacağının
**adım-adım** rehberi. Senior DevOps olmayan biri de takip edip
problemin %80'ini çözebilmeli.

## 🚨 Alert ne demek?

`<ALERT_NAME>` şu durumda firing olur:
- Koşul: `<örn: error_rate > 1% son 5 dk içinde>`
- Eşik: `<spesifik değer>`
- Window: `<5m / 10m / 1h>`

## 🩺 İlk teşhis (60 saniye)

```bash
# 1. Servisin canlılığı
kubectl get pods -n <NS> -l app=<APP>
kubectl top pods -n <NS> -l app=<APP>

# 2. Son 10 dk'da yeniden başlatan pod'lar
kubectl get pods -n <NS> -l app=<APP> -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].restartCount}{"\n"}{end}'

# 3. Error log'ları (son 100 satır)
kubectl logs -n <NS> -l app=<APP> --tail=100 --all-containers | grep -i 'error\|fatal\|panic'

# 4. Metric dashboard
# → [Grafana link to dashboard]
```

## 🔧 Olası sebepler ve çözümler

### Sebep 1: <Yaygın senaryo>

**Belirti:** *(loglarda görünen şey, metric pattern, vb.)*

**Doğrulama:**
```bash
<spesifik komut>
```

**Çözüm:**
```bash
<adım 1>
<adım 2>
```

**Doğrulama (sonrası):**
```bash
<her şey OK mi?>
```

---

### Sebep 2: <Diğer senaryo>

(...benzer yapı...)

---

### Sebep 3: <En kötü senaryo — failover gerekli>

**Belirti:** Birden fazla pod down, recovery yok

**Aksiyon:**

1. Incident channel'da `/incident sev-1 <APP> down` komutu çalıştır
2. Manager + service owner'ı page'le
3. Aşağıdaki rollback prosedürünü çalıştır

```bash
# Rollback: önceki revision'a dön
kubectl rollout undo deployment/<APP> -n <NS>
kubectl rollout status deployment/<APP> -n <NS>
```

4. Eğer rollback yetmezse: traffic'i secondary cluster'a kaydır
   ```bash
   <DNS / Load balancer komut>
   ```

## 🆘 Eskalasyon

| Süre | Aksiyon |
|---|---|
| 0-15 dk | On-call IC çözmeye çalışır |
| 15-30 dk | Service owner page'lenir |
| 30-60 dk | Engineering manager + secondary on-call |
| 60+ dk | Director + comms (status page update) |

## 📞 İletişim kanalları

- **Internal:** `#incident-<APP>` Slack kanalı (otomatik açılır)
- **Status page:** [https://status.example.com](https://status.example.com)
- **Customer comms:** Comms ekibi yönetir; `#comms-incident` kanalı

## 🧠 Geçmiş incident'ler (referans)

- [INC-1234](https://example.com/inc/1234) — 2026-01-15 — DB connection pool exhausted
- [INC-2345](https://example.com/inc/2345) — 2026-02-22 — Memory leak in <COMPONENT>

## 📚 İlgili kaynaklar

- [Service architecture diagram]
- [Capacity planning doc]
- [Recent postmortem'ler]

## ✅ Doğrulama (incident kapanışında)

- [ ] Error rate normale döndü (`<METRIC_LINK>`)
- [ ] p99 latency target altında
- [ ] Customer-facing impact yok
- [ ] Postmortem ticket açıldı: [link]
- [ ] Incident channel kapatıldı

---

> 📝 Bu runbook'ta bir şey eksikse — **şu an** PR aç. "Sonra düzeltirim"
> denilen runbook'lar bir sonraki incident'te aynı sorunu tekrar yaratır.
