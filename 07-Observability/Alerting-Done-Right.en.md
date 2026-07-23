---
description: "A guide to designing symptom-based, actionable, and few-in-number alerts: the 3 requirements of an alert, cause vs symptom distinction, alert fatigue, runbook and alert review practices."
tags:
  - Observability
  - Monitoring
  - Incident Response
  - SRE
---
# Alerting Done Right — Symptom-Based, Actionable, Few

> *"The SRE on a team that gets 50 alerts/day builds up **immunity**.
> They miss the real incident. **Few + actionable + symptom-based**
> alerts = the team's well-tuned nervous system."*

This guide covers alerting discipline — symptom vs cause, actionability,
fatigue, runbook and alert review practices.

---

## 🎯 The 3 Requirements of an Alert

```
1. ACTIONABLE   → an engineer must be able to do something
2. URGENT       → must be done now (otherwise a ticket)
3. SYMPTOM      → user impact (not cause)
```

If all 3 requirements aren't met, it's **not an alert**.

---

## 🔥 Symptom-Based vs Cause-Based

### Cause-based (don't)
```yaml
- alert: HighCPU
  expr: cpu_usage > 90%
- alert: PodRestart
  expr: rate(kube_pod_container_status_restarts_total[5m]) > 0
- alert: DBConnectionsHigh
  expr: db_connections > 80
```

→ 90% CPU **without user impact** isn't an alert. False positive.

### Symptom-based (do)
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

→ The question is "Was the customer affected?" Yes → page.

> 🔑 **If the user's experience isn't affected, it's not an alert.**

---

## 🏷️ Severity Levels

```yaml
labels:
  severity: page    # wake someone up (including at night)
  severity: warn    # business hours + Slack
  severity: ticket  # JIRA / Linear
```

### Page criteria
- Production customer impact
- SLO breach imminent (burn rate)
- Data loss / integrity threat
- Security breach

### Warn criteria
- Approaching capacity limit (24+ hours)
- Performance degradation (hasn't affected the user yet)
- Backup failed (retry tomorrow)

### Ticket criteria
- Sustained issue but not immediate
- Refactor suggestion
- Long-term trend

---

## 📚 Runbook URL Mandatory

```yaml
- alert: ...
  annotations:
    summary: "Payments error rate 5%+"
    description: "..."
    runbook_url: "https://runbooks.<DOMAIN>/payments-high-error"
    dashboard_url: "https://grafana.<DOMAIN>/d/payments"
    impact: "Customers can't checkout"
    triage_steps: |
      1. Check the dashboard
      2. Is there a recent deploy?
      3. Prepare a rollback
```

> 🔑 **No alert without a runbook**. See [`11-SRE/Runbook-Template.md`](../11-SRE/Runbook-Template.md).

---

## 📊 Alert Volume — A Health Indicator

| Count/day/person | Meaning |
|---|---|
| < 3 | Ideal |
| 3-10 | Tolerable |
| 10-30 | **Alarm fatigue** onset |
| 30+ | Team has broken down |

### Quarterly alert review
```
1. Alert list for the last 90 days (count by alertname)
2. For each alert:
   - Did it require action? (yes/no)
   - False positive rate?
   - Is there a runbook?
3. NO → delete the alert or lower severity
4. Top 5 noisiest → tune (threshold, for-duration)
```

---

## 🔇 Alertmanager Routing

```yaml
route:
  group_by: ['alertname', 'severity', 'cluster']
  group_wait: 30s          # wait 30s for the first alert (batch)
  group_interval: 5m       # group similar alerts within 5min
  repeat_interval: 4h      # unresolved → remind every 4 hours

  routes:
    # Page → PagerDuty
    - match: {severity: page}
      receiver: pagerduty
      group_wait: 0s        # immediate
      continue: true        # also send to Slack

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

Or from the UI:
- Reason mandatory
- Duration limited (max 24h)
- Audit log

---

## 🎯 Alert Tuning

### Use `for:` duration
```yaml
- alert: HighErrorRate
  expr: error_rate > 0.05
  for: 5m   # must last 5 min, not a spike
```

→ Doesn't trigger on a transient spike.

### Hysteresis (prevents oscillation)
```yaml
- alert: PodMemoryHigh
  expr: |
    pod_memory_usage / pod_memory_limit > 0.9
    unless
    pod_memory_usage / pod_memory_limit < 0.7
```

→ Triggers above 90%, don't consider it resolved until it drops below 70%.

### Multi-window (reduces false positives)
See [`SLO-Engineering.md`](SLO-Engineering.md).

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| Cause-based alerts (CPU, restart) | False positive | Symptom-based (error rate, latency) |
| Every alert severity: page | Alarm fatigue | severity: page/warn/ticket |
| No runbook URL | What's a tired engineer supposed to do? | Runbook mandatory |
| No `for:` duration | Transient spike triggers an alert | 5m+ for |
| No silence audit | Silent deletions | Reason + duration mandatory |
| Alert count not measured weekly | Fatigue goes undetected | Quarterly review |
| Notification spam ($N alerts in 1 min) | Duplicate | group_wait + group_interval |
| PagerDuty escalation 30 min | First responder doesn't wake up before ack | 5 min escalation |
| No per-service routing | Wrong team wakes up | Team labels + routing |
| Alert as monitoring (on every metric) | Excessive load | Symptom + actionable filter |
| Cron job success alert | Negative logic is bad | Cron job started + finished |

---

## 📋 Alert Hygiene Checklist

```
[ ] All alerts: symptom-based (user impact)
[ ] 3 severity levels: page / warn / ticket
[ ] Runbook URL on every alert
[ ] dashboard URL on every alert
[ ] for: duration (transient skip)
[ ] Multi-window burn rate (SLO)
[ ] Alertmanager HA (3 replicas)
[ ] Routing: per-team + per-severity
[ ] Silence: reason + max duration
[ ] PagerDuty: 5 min escalation
[ ] Quarterly: alert review (volume + actionable)
[ ] Top 5 noisiest → tune or remove
[ ] Annual alert volume target: < 10/day/person
[ ] Postmortem: turn alarm gaps into action items
```

---

## 📚 References

- **Google SRE Book** — Chapter 6: Monitoring
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

> *"An alert's value isn't **its count, but the quality of each one**. Few +
> actionable + symptom-based + runbook'd = a system where the team
> **sleeps well**. Spam = a burnout factory."*

---

> 🎓 **Learning Path:** This document is used as the "read first" resource in the [`E2`](../22-Learning-Path/block-e-ownership/E2-alerting-oncall.md) module.
