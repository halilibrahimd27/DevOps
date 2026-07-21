# L08 — Referans çözüm

> **Önce kendin dene.** PromQL'i sorgu kutusuna yazıp sonucu görmeden anlamış olmazsın.

## 1. Yığın
```bash
cd starter && docker compose up -d
# http://127.0.0.1:9090  → Status → Targets → node UP
```

## 2. Altın sinyaller (PromQL)

**Doygunluk — CPU kullanımı (%):**
```promql
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Trafik — ağ (bayt/sn):**
```promql
sum by(instance) (rate(node_network_receive_bytes_total[5m]))
```

**Doygunluk — bellek (boşta bayt):**
```promql
node_memory_MemAvailable_bytes
```

> Dört altın sinyal: gecikme (latency), trafik (traffic), hata (errors),
> doygunluk (saturation). node_exporter'da doygunluk ve trafik hazır; gecikme ve
> hata için uygulamanın kendisi metrik yaymalı (D2'de göreceksin).

## 3. Cardinality patlaması
```bash
CARD=10     python3 starter/high_cardinality.py   # ayrı terminal
# Prometheus:  count({__name__="lab_requests_total"})  → 10
# durdur, CARD=1000 ile tekrar başlat → 1000
# CARD=100000 → 100000 seri; Prometheus belleği tırmanır, sorgu yavaşlar
```

**Neden felaket:** Prometheus her benzersiz etiket kombinasyonu için ayrı bir
zaman serisi tutar — her seri bellekte yer kaplar. `user_id`, `email`, `request_id`
gibi **sınırsız** değerli etiketler serileri milyonlara taşır; Prometheus şişer,
OOM olur, sorgular durur.

| İyi etiket (sınırlı) | Kötü etiket (sınırsız) |
|---|---|
| `method`, `status`, `region`, `env` | `user_id`, `email`, `ip`, `request_id`, `path` (parametreli) |

> Kural: etikete koymadan önce sor — "bu alanın kaç farklı değeri olabilir?"
> Cevap "sınırsız" ise etiket değil, **log** alanı olmalı.
