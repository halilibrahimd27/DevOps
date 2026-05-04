# Alerting Done Right — Symptom-Based, Actionable, Az

> *"50 alarm/gün gelen ekibin SRE'si **bağışıklık** geliştirir.
> Gerçek incident'ı kaçırır. **Az + actionable + symptom-based**
> alarm = ekibin uyumlu sinir sistemi."*

Bu rehber alerting disiplini — symptom vs cause, actionability,
fatigue, runbook ve alert review pratiklerini anlatır.

---

## 🎯 Alarm'ın 3 Şartı

```
1. ACTIONABLE   → mühendis bir şey yapabilmeli
2. URGENT       → şimdi yapılmalı (yoksa ticket)
3. SYMPTOM      → kullanıcı etkisi (cause değil)
```

Eğer 3 şart sağlanmıyorsa **alarm değil**.

---

## 🔥 Symptom-Based vs Cause-Based

### Cause-based (yapma)
```yaml
- alert: HighCPU
  expr: cpu_usage > 90%
- alert: PodRestart
  expr: rate(kube_pod_container_status_restarts_total[5m]) > 0
- alert: DBConnectionsHigh
  expr: db_connections > 80
```

→ %90 CPU **kullanıcı etkisi yoksa** alarm değil. False positive.

### Symptom-based (yap)
```yaml
- alert: PaymentsHighErrorRate
  expr: |
    sum(rate(http_requests_total{service="payments",status=~"5.."}[5m]))
    /
    sum(rate(http_requests_total{service="payments"}[5m])) > 0.05
- alert: PaymentsHighLatency
  expr: |
    histogram_quantile(0.99,
      sum(rate(http_request_duration_seconds_bucket{service="payments"}[5m])) by (le)
    ) > 2
```

→ "Müşteri etkilenmiş mi?" sorusu. Evet → page.

> 🔑 **Kullanıcının deneyimi etkilenmiyorsa, alarm değil.**

---

## 🏷️ Severity Levels

```yaml
labels:
  severity: page    # uyandır (gece dahil)
  severity: warn    # iş saatinde + Slack
  severity: ticket  # JIRA / Linear
```

### Page criteria
- Production müşteri etkisi
- SLO breach yakın (burn rate)
- Veri kayıp / bütünlük tehdidi
- Security breach

### Warn criteria
- Yaklaşan capacity limit (24+ saat)
- Performance degrade (kullanıcıyı henüz etkilemedi)
- Backup başarısız (yarın retry)

### Ticket criteria
- Sustained issue ama immediate değil
- Refactor önerisi
- Long-term trend

---

## 📚 Runbook URL Zorunlu

```yaml
- alert: ...
  annotations:
    summary: "Payments error rate %5+"
    description: "..."
    runbook_url: "https://runbooks.<DOMAIN>/payments-high-error"
    dashboard_url: "https://grafana.<DOMAIN>/d/payments"
    impact: "Customers can't checkout"
    triage_steps: |
      1. Dashboard'a bak
      2. Recent deploy var mı?
      3. Rollback hazırla
```

> 🔑 **Runbook olmayan alarm yok**. Bkz [`11-SRE/Runbook-Template.md`](../11-SRE/Runbook-Template.md).

---

## 📊 Alert Volume — Sağlık Göstergesi

| Sayı/gün/kişi | Anlam |
|---|---|
| < 3 | İdeal |
| 3-10 | Tolere edilebilir |
| 10-30 | **Alarm fatigue** başlangıç |
| 30+ | Ekip iflas etmiş |

### Quarterly alert review
```
1. Son 90 gün alert listesi (count by alertname)
2. Her alarm için:
   - Action gerektirdi mi? (yes/no)
   - False positive oranı?
   - Runbook var mı?
3. NO → alarm sil veya severity düşür
4. Top 5 noisy → tune (threshold, for-duration)
```

---

## 🔇 Alertmanager Routing

```yaml
route:
  group_by: ['alertname', 'severity', 'cluster']
  group_wait: 30s          # ilk alert'i 30s bekle (batch)
  group_interval: 5m       # benzer alarm'ları 5dk grup'la
  repeat_interval: 4h      # çözülmedi → 4 saatte 1 hatırlat

  routes:
    # Page → PagerDuty
    - match: {severity: page}
      receiver: pagerduty
      group_wait: 0s        # immediate
      continue: true        # Slack'e de gönder

    # Warn → Slack
    - match: {severity: warn}
      receiver: slack-alerts
      group_wait: 5m

    # Ticket → JIRA
    - match: {severity: ticket}
      receiver: jira-webhook

    # Per-team routing
    - match: {team: payments}
      receiver: payments-slack
      continue: true

    # Maintenance silence
    - match_re: {alertname: ^Postgres.*}
      receiver: 'null'
      active_time_intervals: [maintenance-window]

receivers:
  - name: pagerduty
    pagerduty_configs:
      - service_key: <KEY>

  - name: slack-alerts
    slack_configs:
      - api_url: <WEBHOOK>
        channel: '#alerts'
        title: '{{ .GroupLabels.alertname }}'
        text: |
          {{ range .Alerts }}{{ .Annotations.summary }}
          Runbook: {{ .Annotations.runbook_url }}
          {{ end }}

  - name: 'null'
    # silenced
```

---

## 🤐 Silence — Maintenance Window

```yaml
# Alertmanager API
amtool silence add \
  --comment="Postgres upgrade" \
  --duration=2h \
  --start="2026-05-04T22:00:00Z" \
  alertname=PostgresDown
```

Veya UI'dan:
- Reason zorunlu
- Duration sınırlı (max 24h)
- Audit log

---

## 🎯 Alert Tuning

### `for:` duration kullan
```yaml
- alert: HighErrorRate
  expr: error_rate > 0.05
  for: 5m   # 5 dk sürmesi gerekir, spike değil
```

→ Transient spike alarmı tetiklemez.

### Hysteresis (oscillation engelleme)
```yaml
- alert: PodMemoryHigh
  expr: |
    pod_memory_usage / pod_memory_limit > 0.9
    unless
    pod_memory_usage / pod_memory_limit < 0.7
```

→ %90 üstü tetikler, %70 altına düşene kadar silinmiş kabul etme.

### Multi-window (false positive ↓)
Bkz [`SLO-Engineering.md`](SLO-Engineering.md).

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Cause-based alerts (CPU, restart) | False positive | Symptom-based (error rate, latency) |
| Tüm alarm severity: page | Alarm fatigue | severity: page/warn/ticket |
| Runbook URL yok | Yorgun mühendis ne yapsın? | Runbook zorunlu |
| `for:` duration yok | Transient spike alarmı tetikler | 5m+ for |
| Silence audit yok | Sessiz silmeler | Reason + duration zorunlu |
| Alarm count haftalık ölçülmüyor | Fatigue tespit edilmiyor | Quarterly review |
| Notification spam ($N alarm 1 dk'da) | Duplicate | group_wait + group_interval |
| PagerDuty escalation 30 dk | İlk responder uyumadan ack | 5 dk escalation |
| Per-service routing yok | Yanlış ekip uyanır | Team labels + routing |
| Alert as monitoring (her metric'e) | Aşırı yük | Symptom + actionable filter |
| Cron job başarı alarmı | Negatif logic kötü | Cron job started + finished |

---

## 📋 Alert Hijyeni Checklist

```
[ ] Tüm alarm: symptom-based (kullanıcı etkisi)
[ ] Severity 3 level: page / warn / ticket
[ ] Runbook URL her alarm
[ ] dashboard URL her alarm
[ ] for: duration (transient skip)
[ ] Multi-window burn rate (SLO)
[ ] Alertmanager HA (3 replica)
[ ] Routing: per-team + per-severity
[ ] Silence: reason + max duration
[ ] PagerDuty: 5 dk escalation
[ ] Quarterly: alert review (volume + actionable)
[ ] Top 5 noisy → tune veya kaldır
[ ] Yıllık alert volume hedef: < 10/gün/kişi
[ ] Postmortem: alarm gap'i action item'a
```

---

## 📚 Referanslar

- **Google SRE Book** — Bölüm 6: Monitoring
- **My Philosophy on Alerting** — Rob Ewaschuk (Google)
- **Alertmanager** — prometheus.io/docs/alerting/latest/alertmanager/
- **PagerDuty Best Practices** — pagerduty.com/resources/learn/
- [`Prometheus-Best-Practices.md`](Prometheus-Best-Practices.md)
- [`SLO-Engineering.md`](SLO-Engineering.md)
- [`OpenTelemetry-Adoption.md`](OpenTelemetry-Adoption.md)
- [`11-SRE/Runbook-Template.md`](../11-SRE/Runbook-Template.md)
- [`11-SRE/Toil-Reduction.md`](../11-SRE/Toil-Reduction.md)
- [`20-Soft-Skills/Oncall-Sustainability.md`](../20-Soft-Skills/Oncall-Sustainability.md)

---

> *"Alarm'ın değeri **sayısı değil, her birinin kalitesi**. Az +
> actionable + symptom-based + runbook'lu = ekibin **iyi
> uyuduğu** sistem. Spam = burnout fabrikası."*
