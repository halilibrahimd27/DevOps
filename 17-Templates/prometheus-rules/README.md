---
description: "Prometheus SLO recording + alerting rule şablonu: çok-pencereli çok-burn-rate uyarı (fast/slow burn) ve p99 latency alarmı; %99.9 availability örneği."
tags:
  - Template
  - Observability
  - SRE
  - Prometheus
---
# Prometheus SLO Kuralları

> SLI'yi recording rule ile önceden hesapla, SLO ihlalini çok-pencereli
> çok-burn-rate ile uyar. Kağıttaki %99.9 hedefini çalışan alarma çevirir.
> Placeholder'lar `<UPPER_CASE>` ile. Bu sayfa komşu dosyanın gömülü halidir;
> kaynak dosya aynı klasörde.

## Dosya

| Dosya | Kind | Ne sağlar |
|---|---|---|
| [`slo-recording-rules.yaml`](slo-recording-rules.yaml) | PrometheusRule | 5m–3d availability SLI + fast/slow burn + latency alarmı |

Kavram + matematik: [`11-SRE/SLI-SLO-Error-Budget.md`](../../11-SRE/SLI-SLO-Error-Budget.md).

## Niye çok-pencereli çok-burn-rate

Tek eşik ya çok gürültülü (her mikro-hata alarm) ya çok geç (budget bitmeden uyarmaz).
İki pencere birden kontrol edilir:

- **Fast burn** (5m + 1h, 14.4x): budget'ı ~2 saatte yakan hızlı bozulma → `critical`, hemen sayfa.
- **Slow burn** (1h + 6h, 6x): yavaş sızıntı → `warning`, iş saatinde bak.

Kısa pencere "şimdi kötü mü", uzun pencere "gerçekten trend mi" sorusunu yanıtlar; ikisi birden yanınca alarm gürültüsü düşer.

### `slo-recording-rules.yaml`

```yaml
# Prometheus recording + alerting rules
# SLO: %99.9 successful requests / 30 günlük rolling window
# Multi-window multi-burn-rate alerting (Google SRE workbook)

apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: <APP_NAME>-slo
  namespace: monitoring
  labels:
    role: alert-rules
    prometheus: kube-prometheus
spec:
  groups:
    # ───── Recording rules: SLI hesaplaması ─────
    - name: <APP_NAME>.sli.rules
      interval: 30s
      rules:
        # 5 dakikalık availability oranı
        - record: sli:<APP_NAME>:availability:5m
          expr: |
            sum(rate(http_requests_total{app="<APP_NAME>",code!~"5.."}[5m]))
            /
            sum(rate(http_requests_total{app="<APP_NAME>"}[5m]))

        # 1 saatlik
        - record: sli:<APP_NAME>:availability:1h
          expr: |
            sum(rate(http_requests_total{app="<APP_NAME>",code!~"5.."}[1h]))
            /
            sum(rate(http_requests_total{app="<APP_NAME>"}[1h]))

        # 6 saatlik
        - record: sli:<APP_NAME>:availability:6h
          expr: |
            sum(rate(http_requests_total{app="<APP_NAME>",code!~"5.."}[6h]))
            /
            sum(rate(http_requests_total{app="<APP_NAME>"}[6h]))

        # 1 günlük
        - record: sli:<APP_NAME>:availability:1d
          expr: |
            sum(rate(http_requests_total{app="<APP_NAME>",code!~"5.."}[1d]))
            /
            sum(rate(http_requests_total{app="<APP_NAME>"}[1d]))

        # 3 günlük
        - record: sli:<APP_NAME>:availability:3d
          expr: |
            sum(rate(http_requests_total{app="<APP_NAME>",code!~"5.."}[3d]))
            /
            sum(rate(http_requests_total{app="<APP_NAME>"}[3d]))

        # SLO target (sabit, dashboard için)
        - record: slo:<APP_NAME>:target
          expr: vector(0.999)

    # ───── Alerting rules: multi-window multi-burn-rate ─────
    - name: <APP_NAME>.slo.alerts
      rules:
        # FAST burn — 5dk + 1saat penceresi, 14.4x burn rate
        # → 30 günlük budget'ı 2 saatte yakar
        - alert: <APP_NAME>HighErrorBudgetBurnRate
          expr: |
            (
              (1 - sli:<APP_NAME>:availability:5m) > (14.4 * (1 - 0.999))
              and
              (1 - sli:<APP_NAME>:availability:1h) > (14.4 * (1 - 0.999))
            )
          for: 2m
          labels:
            severity: critical
            slo: <APP_NAME>-availability
          annotations:
            summary: "<APP_NAME> error budget hızla tükeniyor (fast burn)"
            description: |
              Son 5 dakika ve 1 saatte error rate, 30 günlük SLO bütçesinin
              14.4x hızında yanıyor. 2 saat içinde tüm budget tükenir.
              Acil müdahale gerekli.
            runbook_url: https://github.com/<ORG>/runbooks/<APP_NAME>/error-budget-burn.md
            dashboard_url: https://grafana.example.com/d/<DASH_ID>

        # SLOW burn — 1saat + 6saat penceresi, 6x burn rate
        # → 30 günlük budget'ı 5 günde yakar
        - alert: <APP_NAME>SustainedErrorBudgetBurn
          expr: |
            (
              (1 - sli:<APP_NAME>:availability:1h) > (6 * (1 - 0.999))
              and
              (1 - sli:<APP_NAME>:availability:6h) > (6 * (1 - 0.999))
            )
          for: 15m
          labels:
            severity: warning
            slo: <APP_NAME>-availability
          annotations:
            summary: "<APP_NAME> sustained error budget burn"
            description: |
              Son 1 saat ve 6 saatte error rate, 30 günlük SLO bütçesinin
              6x hızında yanıyor. 5 gün içinde budget tükenir.
            runbook_url: https://github.com/<ORG>/runbooks/<APP_NAME>/error-budget-burn.md

        # Latency SLO (p99 < 500ms ana request türü için)
        - alert: <APP_NAME>HighLatency
          expr: |
            histogram_quantile(0.99,
              sum by (le) (rate(http_request_duration_seconds_bucket{app="<APP_NAME>"}[5m]))
            ) > 0.5
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "<APP_NAME> p99 latency > 500ms"
            description: "p99: {{ $value }}s"
```

---

## 🚫 Anti-Pattern

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tek eşikli alarm (`error_rate > 0`) | Ya gürültü ya geç kalma | Çok-pencereli çok-burn-rate |
| SLI'yi alarm anında hesaplama | Ağır sorgu, yavaş değerlendirme | Recording rule ile önceden hesapla |
| `runbook_url` olmayan alarm | Sayfayı alan kişi ne yapacağını bilmez | Her alarmda runbook + dashboard linki |
| SLO'yu ortalamayla ölçme | Ortalama kuyruk latency'sini gizler | p99/p99.9 histogram_quantile |

> *"SLO, 'ne zaman uyanılır'ın matematiğidir; burn rate onu 'şimdi mi, sabaha mı' kararına çevirir."*
