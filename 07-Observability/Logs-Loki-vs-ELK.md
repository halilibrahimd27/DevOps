---
description: "Loki ve ELK (Elasticsearch + Logstash + Kibana) log stack karsilastirmasi: indexleme felsefesi, depolama maliyeti, sorgu desenleri ve Wazuh entegrasyonu."
tags:
  - Observability
  - Monitoring
  - Security
  - Cost Optimization
---
# Logs — Loki vs ELK Stack

> *"Log stack 'yıllarca aynı' kaldı (ELK), 2020'de Loki geldi —
> **'log için Prometheus modeli'**. ELK 1 TB için 100 GB'lık Loki
> ekibe **maliyet farkı** anlamına gelir."*

Bu rehber Loki ve ELK (Elasticsearch + Logstash + Kibana) stack'lerini
karşılaştırır, hangi senaryoda hangisinin tercih edileceğini ve TR
tarafında popüler **Wazuh** ile entegrasyonu anlatır.

---

## ⚖️ Tek Cümlede

| Stack | Felsefe |
|---|---|
| **ELK / Elastic** | "Log içeriğini full-text index'le, sorgulanabilir yap" |
| **Loki** | "Log içeriğini index'leme, **label-based** stream gibi tut" |

→ Loki **disk + maliyet** odaklı; ELK **search hızı** odaklı.

---

## 📊 Detaylı Karşılaştırma

| Boyut | **Elastic Stack** | **Loki** |
|---|---|---|
| **Indexing** | Full-text content | Sadece label (Prometheus-tarzı) |
| **Storage** | High (3-5x raw size) | Low (1-1.5x raw size) |
| **Maliyet** | Yüksek | Düşük (~%80 ucuz) |
| **Search hızı** | Çok hızlı (full-text) | Orta (label filter + grep) |
| **Dashboard** | Kibana | Grafana |
| **Visualizations** | Çok zengin | Orta |
| **Aggregation** | Çok güçlü | Sınırlı |
| **Retention** | Pahalı uzun retention | Ucuz uzun retention |
| **Scaling** | Karmaşık (sharding) | Modular (yatay scale kolay) |
| **Multi-tenancy** | License (Elastic Premium) | Native, free |
| **Open source** | Elastic License v2 (BSL-tarzı) | Apache 2 |
| **Topluluk** | Çok büyük | Yükselişte |

---

## 🌳 Karar Ağacı

```
START
  │
  ├── Maliyet kritik (1+ TB log/gün)?
  │     │
  │     └── Loki (~%80 ucuz)
  │
  ├── Full-text search agresif (security investigation)?
  │     │
  │     └── ELK (full-text index gücü)
  │
  ├── Grafana ekosistemi merkezde mi (Prometheus + Tempo)?
  │     │
  │     └── Loki (LGTM stack — Loki + Grafana + Tempo + Mimir)
  │
  ├── Kompleks aggregation / ML log analizi?
  │     │
  │     └── ELK (zengin query DSL)
  │
  ├── Audit log + compliance retention (1+ yıl)?
  │     │
  │     └── Loki + S3 (ucuz long-term)
  │
  └── Default 2026 → Loki (cost-effective + Grafana ekosistem)
```

---

## 🚀 Loki Quick Start

### Helm install
```bash
helm install loki grafana/loki-stack \
  -n loki --create-namespace \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=100Gi \
  --set promtail.enabled=true \
  --set fluent-bit.enabled=false
```

### Promtail (log shipper)
```yaml
# values.yaml
promtail:
  config:
    snippets:
      pipelineStages:
        - cri: {}    # K8s container log format
        - json:
            expressions:
              level: level
              user: user
        - labels:
            level:
            user:
```

### LogQL queries
```logql
# Tüm log
{namespace="payments"}

# Filter
{namespace="payments"} |= "ERROR"
{namespace="payments"} |~ "5\\d\\d"          # regex 5xx

# JSON parse + filter
{app="payments"} | json | level="error"

# Aggregation
sum(count_over_time({namespace="payments", level="error"}[5m])) by (pod)

# Pattern detection
{app="payments"} |~ "panic" | rate [5m]
```

---

## 🚀 ELK Stack Setup

### Helm install
```bash
# Elasticsearch
helm install elasticsearch elastic/elasticsearch \
  -n logging --create-namespace \
  --set replicas=3

# Kibana
helm install kibana elastic/kibana \
  -n logging \
  --set ingress.enabled=true

# Filebeat (log shipper)
helm install filebeat elastic/filebeat \
  -n logging
```

### Lucene queries
```
# Kibana KQL
namespace: "payments" AND level: "error"
http.status: [500 TO 599]
@timestamp >= "now-1h" AND service: "payments"

# Elastic Query DSL
{
  "query": {
    "bool": {
      "must": [
        {"match": {"namespace": "payments"}},
        {"range": {"@timestamp": {"gte": "now-1h"}}}
      ]
    }
  },
  "aggs": {
    "errors_by_pod": {
      "terms": {"field": "pod.keyword"}
    }
  }
}
```

---

## 📦 OpenSearch (ELK alternative)

> Elastic'in BSL license sorunu sonrası AWS forklayıp **OpenSearch** açtı.

```bash
helm install opensearch opensearch/opensearch \
  -n logging --create-namespace
```

→ Aynı API, Apache 2 license.

> 🔑 ELK seçtiyseniz **OpenSearch tercih edin** (Apache 2 + AWS-managed).

---

## 🔗 Wazuh — TR Pazarında Popüler SIEM

[Wazuh](https://wazuh.com) — open-source SIEM + Elasticsearch tabanlı.

```
[Endpoint agent] → [Wazuh manager] → [Elasticsearch index]
                                            │
                                            ▼
                                       [Kibana dashboard]
```

### TR'de niye yaygın?
- Açık kaynak + ticari destek
- Log + IDS + file integrity + vulnerability mgmt birleşik
- KVKK için audit log + compliance reporting

> Detay: [`Network/Network Segmentation and Wazuh SIEM Integration Guide.md`](../21-Field-Notes/network/network-segmentation-wazuh-siem.md)

---

## 📋 Log Hygiene Best Practices

### 1. Structured logging (JSON)
```json
{
  "timestamp": "2026-05-04T14:30:00Z",
  "level": "error",
  "service": "payments",
  "trace_id": "abc123",
  "user_id_hash": "sha256(...)",   ← PII mask
  "method": "POST",
  "path": "/v1/charges",
  "status": 500,
  "duration_ms": 234,
  "error": "DB connection refused"
}
```

### 2. PII filter
```python
# Logging filter
def sanitize(record):
    if 'email' in record:
        record['email_hash'] = hash(record.pop('email'))
    if 'pan' in record:
        record['pan_last4'] = record.pop('pan')[-4:]
    return record
```

### 3. Log level discipline
- `DEBUG`: dev only
- `INFO`: routine events (login, request)
- `WARN`: recoverable issue (retry working)
- `ERROR`: failed operation
- `FATAL`: process down

### 4. Sampling (high-volume)
```python
# %1 sample DEBUG, %100 ERROR
if level == "DEBUG" and random() > 0.01:
    return  # skip
log(record)
```

---

## 💰 Cost Comparison

```
1 TB raw log/gün, 30 gün retention:

ELK:
  Storage: 30 TB × 3x indexing = 90 TB
  AWS EBS gp3: 90 TB × $0.08/GB/ay = $7,200/ay
  Compute: 6 m6i.2xlarge ES = $2,700/ay
  Total: ~$10,000/ay

Loki:
  Storage: 30 TB × 1.2x = 36 TB → S3 STANDARD_IA
  S3 IA: 36 TB × $0.0125/GB/ay = $450/ay
  Compute: 3 m6i.large = $400/ay
  Total: ~$850/ay

Tasarruf: ~%92
```

> 🔑 1 TB+/gün scale'de **Loki büyük tasarruf**.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Plain-text log (unstructured) | Parsing zor | JSON structured |
| PII log'a düşer | KVKK/GDPR ihlal | Mask + filter |
| Log retention sonsuz | Cost + compliance | Lifecycle 30/90/365 |
| ELK tek node | SPOF + scale yok | Multi-node + sharding |
| Loki cardinality yüksek (her field label) | OOM | Sadece anahtar label |
| Log level discipline yok | DEBUG prod'da | Level filter |
| Sampling yok yüksek-volume | Cost patlar | DEBUG sample %1 |
| Audit log + app log karışık | Forensic zor | Ayrı index/stream |
| Log encryption yok | Sensitive leak | TLS + at-rest encryption |
| Single-region log | Region down → kayıp | Cross-region replication |

---

## 📋 Logging Stack Checklist

```
[ ] Structured logging (JSON)
[ ] PII filter (mask + hash)
[ ] Log level discipline (DEBUG sample)
[ ] Stack seçimi: Loki / OpenSearch / ELK (ADR ile gerekçeli)
[ ] HA: multi-replica
[ ] Retention: 30 gün hot + 90 gün warm + 1 yıl cold
[ ] Cross-region replication (compliance + DR)
[ ] TLS in transit + at rest encryption
[ ] Audit log ayrı index/stream
[ ] Cardinality limit (Loki için)
[ ] Sampling policy (high-volume)
[ ] Wazuh integration (TR security)
[ ] Quarterly: log volume + cost review
[ ] Documentation: log query cookbook
```

---

## 📚 Referanslar

- **Loki** — grafana.com/oss/loki
- **LogQL** — grafana.com/docs/loki/latest/logql/
- **Elasticsearch** — elastic.co
- **OpenSearch** — opensearch.org
- **Wazuh** — wazuh.com
- **Filebeat** — elastic.co/beats/filebeat
- **Promtail** — grafana.com/docs/loki/latest/clients/promtail/
- [`OpenTelemetry-Adoption.md`](OpenTelemetry-Adoption.md)
- [`Tracing-with-Tempo.md`](Tracing-with-Tempo.md)
- [`Profiling-with-Pyroscope.md`](Profiling-with-Pyroscope.md)
- [`Network/Network Segmentation and Wazuh SIEM Integration Guide.md`](../21-Field-Notes/network/network-segmentation-wazuh-siem.md)
- [`19-Compliance/Audit-Evidence-Automation.md`](../19-Compliance/Audit-Evidence-Automation.md)

---

> *"Log stack 'install et, çalışıyor' değil — **cost vs query
> hızı** trade-off'u. 2026'da çoğu workload için **Loki + Grafana**
> sweet-spot; security / forensic odaklı için **OpenSearch / Wazuh**."*
