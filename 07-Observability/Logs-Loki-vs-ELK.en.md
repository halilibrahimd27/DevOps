---
description: "Loki vs ELK (Elasticsearch + Logstash + Kibana) log stack comparison: indexing philosophy, storage cost, query patterns, and Wazuh integration."
tags:
  - Observability
  - Monitoring
  - Security
  - Cost Optimization
---
# Logs — Loki vs ELK Stack

> *"The log stack stayed 'the same for years' (ELK), then Loki arrived
> in 2020 — **'the Prometheus model for logs'**. Where ELK needs 1 TB,
> Loki's 100 GB means a real **cost difference** for the team."*

This guide compares the Loki and ELK (Elasticsearch + Logstash + Kibana)
stacks, covers which scenario favors which, and explains integration
with **Wazuh**, a tool popular in the Turkish market.

---

## ⚖️ In One Sentence

| Stack | Philosophy |
|---|---|
| **ELK / Elastic** | "Full-text index the log content, make it searchable" |
| **Loki** | "Don't index the log content, treat it like a **label-based** stream" |

→ Loki is focused on **disk + cost**; ELK is focused on **search speed**.

---

## 📊 Detailed Comparison

| Dimension | **Elastic Stack** | **Loki** |
|---|---|---|
| **Indexing** | Full-text content | Label only (Prometheus-style) |
| **Storage** | High (3-5x raw size) | Low (1-1.5x raw size) |
| **Cost** | High | Low (~80% cheaper) |
| **Search speed** | Very fast (full-text) | Medium (label filter + grep) |
| **Dashboard** | Kibana | Grafana |
| **Visualizations** | Very rich | Medium |
| **Aggregation** | Very powerful | Limited |
| **Retention** | Expensive long retention | Cheap long retention |
| **Scaling** | Complex (sharding) | Modular (horizontal scale is easy) |
| **Multi-tenancy** | License (Elastic Premium) | Native, free |
| **Open source** | Elastic License v2 (BSL-style) | Apache 2 |
| **Community** | Very large | Growing |

---

## 🌳 Decision Tree

```
START
  │
  ├── Is cost critical (1+ TB log/day)?
  │     │
  │     └── Loki (~80% cheaper)
  │
  ├── Aggressive full-text search (security investigation)?
  │     │
  │     └── ELK (full-text index power)
  │
  ├── Is the Grafana ecosystem central (Prometheus + Tempo)?
  │     │
  │     └── Loki (LGTM stack — Loki + Grafana + Tempo + Mimir)
  │
  ├── Complex aggregation / ML log analysis?
  │     │
  │     └── ELK (rich query DSL)
  │
  ├── Audit log + compliance retention (1+ year)?
  │     │
  │     └── Loki + S3 (cheap long-term)
  │
  └── Default 2026 → Loki (cost-effective + Grafana ecosystem)
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
# All logs
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

> After Elastic's BSL license issue, AWS forked it and opened **OpenSearch**.

```bash
helm install opensearch opensearch/opensearch \
  -n logging --create-namespace
```

→ Same API, Apache 2 license.

> 🔑 If you're choosing ELK, **prefer OpenSearch** (Apache 2 + AWS-managed).

---

## 🔗 Wazuh — Popular SIEM in the Turkish Market

[Wazuh](https://wazuh.com) — open-source SIEM, built on Elasticsearch.

```
[Endpoint agent] → [Wazuh manager] → [Elasticsearch index]
                                            │
                                            ▼
                                       [Kibana dashboard]
```

### Why is it common in Turkey?
- Open source + commercial support
- Log + IDS + file integrity + vulnerability mgmt combined
- Audit log + compliance reporting for KVKK

> Details: [`Network/Network Segmentation and Wazuh SIEM Integration Guide.md`](../21-Field-Notes/network/network-segmentation-wazuh-siem.md)

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
# 1% sample DEBUG, 100% ERROR
if level == "DEBUG" and random() > 0.01:
    return  # skip
log(record)
```

---

## 💰 Cost Comparison

```
1 TB raw log/day, 30 day retention:

ELK:
  Storage: 30 TB × 3x indexing = 90 TB
  AWS EBS gp3: 90 TB × $0.08/GB/month = $7,200/month
  Compute: 6 m6i.2xlarge ES = $2,700/month
  Total: ~$10,000/month

Loki:
  Storage: 30 TB × 1.2x = 36 TB → S3 STANDARD_IA
  S3 IA: 36 TB × $0.0125/GB/month = $450/month
  Compute: 3 m6i.large = $400/month
  Total: ~$850/month

Savings: ~92%
```

> 🔑 At 1 TB+/day scale, **Loki delivers big savings**.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct approach |
|---|---|---|
| Plain-text log (unstructured) | Hard to parse | JSON structured |
| PII ends up in logs | KVKK/GDPR violation | Mask + filter |
| Infinite log retention | Cost + compliance | Lifecycle 30/90/365 |
| ELK single node | SPOF + no scale | Multi-node + sharding |
| High Loki cardinality (every field as a label) | OOM | Only key labels |
| No log level discipline | DEBUG in prod | Level filter |
| No sampling at high volume | Cost explodes | 1% DEBUG sample |
| Audit log + app log mixed | Hard forensics | Separate index/stream |
| No log encryption | Sensitive data leak | TLS + at-rest encryption |
| Single-region log | Region down → data loss | Cross-region replication |

---

## 📋 Logging Stack Checklist

```
[ ] Structured logging (JSON)
[ ] PII filter (mask + hash)
[ ] Log level discipline (DEBUG sample)
[ ] Stack selection: Loki / OpenSearch / ELK (justified with an ADR)
[ ] HA: multi-replica
[ ] Retention: 30 day hot + 90 day warm + 1 year cold
[ ] Cross-region replication (compliance + DR)
[ ] TLS in transit + at rest encryption
[ ] Audit log in a separate index/stream
[ ] Cardinality limit (for Loki)
[ ] Sampling policy (high-volume)
[ ] Wazuh integration (Turkish security landscape)
[ ] Quarterly: log volume + cost review
[ ] Documentation: log query cookbook
```

---

## 📚 References

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

> *"The log stack isn't 'install it and it works' — it's a **cost vs
> query speed** trade-off. For most workloads in 2026, **Loki + Grafana**
> is the sweet spot; for security / forensic-focused needs, **OpenSearch / Wazuh**."*
