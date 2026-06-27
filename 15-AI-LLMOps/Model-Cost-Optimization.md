---
description: "LLM maliyet optimizasyonu: token fiyatlandirma, model tier secimi, prompt caching, batch API, semantic cache ve fine-tuning ROI ile ayni isi %70 ucuza yapma."
---
# Model Cost Optimization — LLM Bill'i Yönetmek

> *"OpenAI bill ay sonu $20K. 'Çok mu kullandık?' Hayır, **yanlış
> kullandık**. Model selection + caching + batching + prompt caching
> = aynı iş **%70 ucuza**."*

Bu rehber LLM cost optimization tekniklerini — model tier seçimi,
prompt caching, batch API, semantic cache, fine-tuning ROI — somut
örneklerle anlatır.

---

## 💰 LLM Cost Driver'ları

### Token-based pricing (2026 referans)
```
Anthropic Claude Opus 4.7:
  Input:  $15/M token
  Output: $75/M token

Anthropic Claude Sonnet 4.6:
  Input:  $3/M
  Output: $15/M

Anthropic Claude Haiku 4.5:
  Input:  $0.25/M
  Output: $1.25/M

OpenAI GPT-5:
  Input:  $5/M
  Output: $15/M

OpenAI GPT-5-mini:
  Input:  $0.5/M
  Output: $2/M

Self-hosted Llama 3.3 70B:
  ~$0.50/M token equivalent (GPU amortize)
```

> 🔑 **Output token genelde 5× input price**. Output uzunluğu kontrol kritik.

---

## 🎯 Optimization Stratejileri

### 1️⃣ **Right Model for Right Task**

| Task | Model |
|---|---|
| Simple classification | Haiku / GPT-5-mini |
| Summary / extraction | Haiku / Sonnet |
| Complex reasoning | Sonnet / GPT-5 |
| Multi-step agent | Opus / GPT-5 |
| Code generation | Sonnet (Claude best) |
| Fine-tuned classification | Self-host distilled model |

> 🔑 **Haiku %95 use case'de yetiyor**. Opus sadece complex reasoning için.

### Tiered approach
```python
def llm_call(task_type, content):
    if task_type == "classify":
        return claude_haiku(content)         # ucuz
    elif task_type == "summary":
        return claude_sonnet(content)        # orta
    elif task_type == "complex_reasoning":
        return claude_opus(content)          # pahalı, kritik için
```

---

### 2️⃣ **Prompt Caching (2024+)**

> Aynı system prompt birden fazla request'te kullanılıyorsa **cache**.

```python
# Anthropic prompt caching
response = client.messages.create(
    model="claude-sonnet-4-6",
    system=[
        {
            "type": "text",
            "text": LARGE_SYSTEM_PROMPT,   # 5000 token örn
            "cache_control": {"type": "ephemeral"}
        }
    ],
    messages=[...]
)
```

→ İlk çağrı: tam fiyat. Sonraki çağrılar (5 dakika içinde): **%90 ucuz** input cost.

### Use case
- RAG: aynı document context tekrar kullanılır
- Multi-turn chat: history yeniden gönderilir
- Few-shot: örnekler her seferinde
- Tool use: tool definitions

> 🔑 **Tasarruf %50-90** input cost'tan, sık kullanılan promptlarda.

---

### 3️⃣ **Batch API (Latency Tolerant)**

```python
# Anthropic Message Batches API (24h SLA)
batch = client.messages.batches.create(
    requests=[
        {"custom_id": "1", "params": {...}},
        {"custom_id": "2", "params": {...}},
        # 1000+ requests
    ]
)
```

→ **%50 indirim**. Async processing (24 saat SLA).

### Use case
- Nightly log analysis
- Bulk summarization
- Embedding generation
- Offline classification

---

### 4️⃣ **Semantic Cache**

```python
# Redis-backed semantic cache
import hashlib

def cached_llm(prompt: str) -> str:
    # Embed query
    query_embed = embed(prompt)
    
    # Find similar cached
    similar = redis_vector_search(query_embed, threshold=0.95)
    
    if similar:
        return similar.cached_response
    
    response = llm.complete(prompt)
    redis_vector_store(query_embed, response, ttl=3600)
    return response
```

→ Aynı / benzer query'ler API'ye gitmez. **%30-60** cost cut, FAQ pattern'lerinde.

---

### 5️⃣ **Output Length Control**

```python
response = llm.complete(
    prompt=prompt,
    max_tokens=200,    # ❌ output sınırla
    stop_sequences=["\n\n"]   # ❌ erken durdur
)
```

```python
# System prompt'ta da
SYSTEM = """Cevapları MAX 100 kelime tut."""
```

→ Output token = 5× input price. Sınırlamak büyük tasarruf.

---

### 6️⃣ **Fine-Tuning ROI**

```
Senaryo: customer support classification
  Volume: 100K request/gün
  Generic Claude Sonnet: $3K/ay
  
Fine-tuned Claude Haiku:
  Training: $500 one-time
  Inference: $300/ay (Haiku price)
  
ROI: 3 ayda break-even.
```

> 🔑 **High-volume, narrow task** için fine-tune **kazanç**. Generic question için **gereksiz**.

---

### 7️⃣ **Streaming + Early Termination**

```python
stream = llm.stream(prompt)
for chunk in stream:
    if condition_met(chunk):
        stream.close()   # erken durdur, output cost azalır
        break
    process(chunk)
```

---

### 8️⃣ **Distillation**

> Büyük model'in "student" küçük model'e öğretilmesi.

```
Teacher: Claude Opus (slow, expensive, accurate)
   ↓ trained on Opus outputs
Student: Llama 3.3 8B fine-tuned
   ↓
%95 quality, %5 cost.
```

→ High-volume task'larda büyük tasarruf.

---

## 📊 Cost Tracking Dashboard

```promql
# Per-team token usage
sum by (team) (rate(llm_input_tokens_total[1d]))

# Per-model spend
sum by (model) (rate(llm_cost_usd_total[7d]))

# Cache hit rate
rate(llm_cache_hits_total[1h]) / rate(llm_requests_total[1h])
```

### Quarterly review
- Top spending teams
- Cache hit rate (target > %30)
- Model distribution (Opus vs Haiku ratio)
- Optimization opportunities

---

## 🌳 Karar Akışı

```
[Yeni LLM use case]
   │
   ▼
[Volume estimate]
   │
   ├── Düşük volume (<1M token/gün) → Cloud API (Claude/GPT)
   │
   ├── Orta volume + privacy → Cloud API + prompt caching
   │
   ├── Yüksek volume + cost-sensitive → Self-host Llama
   │
   └── Latency-tolerant + bulk → Batch API (%50 indirim)
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tüm task Opus | %95 işte gereksiz | Tiered model selection |
| Prompt caching kullanılmıyor | %90 input cost kaçırılır | Cache control |
| Batch API kullanılmıyor (offline task'lerde) | %50 fazla | Batch async |
| Semantic cache yok | Tekrarlanan API | Redis vector cache |
| Output limit yok | Uzun cevap = pahalı | max_tokens + stop |
| Fine-tune ROI hesaplamadan | Yatırım israf | Volume threshold check |
| Per-user rate limit yok | 1 user $$$ | Token bucket |
| Cost alarm yok | Bütçe sürpriz | Daily $X threshold |
| Multi-model A/B test yok | Optimal model bilinmez | Eval per task |
| Streaming kullanılmıyor (UX) | Yavaş feel | Stream + early termination |

---

## 📋 LLM Cost Optimization Checklist

```
[ ] Tiered model selection (Haiku → Sonnet → Opus)
[ ] Prompt caching aktif (system prompt + RAG context)
[ ] Batch API (offline / nightly job'lar)
[ ] Semantic cache (Redis vector)
[ ] Output length control (max_tokens + stop)
[ ] Per-user rate limit
[ ] Cost dashboard (per-team, per-model)
[ ] Daily cost alarm threshold
[ ] Fine-tune ROI hesaplaması (high-volume narrow task)
[ ] Distillation candidate review
[ ] Streaming (latency-sensitive UX)
[ ] Model migration A/B test (yeni provider denemesi)
[ ] Quarterly: cost optimization review
[ ] Annual: build vs buy (self-host migration eşik)
```

---

## 📚 Referanslar

- **Anthropic Pricing** — anthropic.com/api
- **OpenAI Pricing** — openai.com/api/pricing
- **Anthropic Prompt Caching** — docs.anthropic.com/en/docs/build-with-claude/prompt-caching
- **Anthropic Message Batches** — docs.anthropic.com/en/docs/build-with-claude/batch-processing
- **Self-Hosted-LLM.md** — self-host migration
- [`LLM-in-Production.md`](LLM-in-Production.md)
- [`RAG-Architecture.md`](RAG-Architecture.md)
- [`Prompt-Engineering-for-Ops.md`](Prompt-Engineering-for-Ops.md)
- [`AI-Augmented-Operations.md`](AI-Augmented-Operations.md)
- [`Self-Hosted-LLM.md`](Self-Hosted-LLM.md)
- [`12-FinOps/Cloud-Cost-Allocation.md`](../12-FinOps/Cloud-Cost-Allocation.md)

---

> *"LLM cost 'kontrolü olmayan' kalemde patlar. Tiered model +
> prompt cache + batch + semantic cache 4'lüsü ile **aynı çıktı
> %70 ucuza** mümkün. Quarterly review ile yıllık $50K-500K
> tasarruf gerçek."*
