---
description: "LLM cost optimization: token pricing, model tier selection, prompt caching, batch API, semantic cache, and fine-tuning ROI to do the same work 70% cheaper."
tags:
  - AI/LLMOps
  - Cost Optimization
  - FinOps
  - Performance
---
# Model Cost Optimization — Managing the LLM Bill

> *"OpenAI bill at month-end: $20K. 'Did we use too much?' No, we
> **used it wrong**. Model selection + caching + batching + prompt caching
> = the same work **70% cheaper**."*

This guide covers LLM cost optimization techniques — model tier
selection, prompt caching, batch API, semantic cache, fine-tuning ROI —
with concrete examples.

---

## 💰 LLM Cost Drivers

### Token-based pricing (2026-Q2 reference — prices change fast, verify against the provider's page)
```
Anthropic Claude Opus 4.8:
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

> 🔑 **Output tokens are usually 5× the input price**. Controlling output length is critical.

---

## 🎯 Optimization Strategies

### 1️⃣ **Right Model for Right Task**

| Task | Model |
|---|---|
| Simple classification | Haiku / GPT-5-mini |
| Summary / extraction | Haiku / Sonnet |
| Complex reasoning | Sonnet / GPT-5 |
| Multi-step agent | Opus / GPT-5 |
| Code generation | Sonnet (Claude best) |
| Fine-tuned classification | Self-host distilled model |

> 🔑 **Haiku is enough for 95% of use cases**. Opus only for complex reasoning.

### Tiered approach
```python
def llm_call(task_type, content):
    if task_type == "classify":
        return claude_haiku(content)         # cheap
    elif task_type == "summary":
        return claude_sonnet(content)        # medium
    elif task_type == "complex_reasoning":
        return claude_opus(content)          # expensive, for critical cases
```

---

### 2️⃣ **Prompt Caching (2024+)**

> If the same system prompt is used across multiple requests, **cache it**.

```python
# Anthropic prompt caching
response = client.messages.create(
    model="claude-sonnet-4-6",
    system=[
        {
            "type": "text",
            "text": LARGE_SYSTEM_PROMPT,   # e.g. 5000 tokens
            "cache_control": {"type": "ephemeral"}
        }
    ],
    messages=[...]
)
```

→ First call: full price. Subsequent calls (within 5 minutes): **90% cheaper** input cost.

### Use case
- RAG: same document context reused
- Multi-turn chat: history resent
- Few-shot: examples every time
- Tool use: tool definitions

> 🔑 **Savings of 50-90%** on input cost, for frequently used prompts.

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

→ **50% discount**. Async processing (24-hour SLA).

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

→ Identical / similar queries never hit the API. **30-60%** cost cut, in FAQ patterns.

---

### 5️⃣ **Output Length Control**

```python
response = llm.complete(
    prompt=prompt,
    max_tokens=200,    # ❌ limit output
    stop_sequences=["\n\n"]   # ❌ stop early
)
```

```python
# In the system prompt too
SYSTEM = """Keep answers to MAX 100 words."""
```

→ Output token = 5× input price. Limiting it is a big saving.

---

### 6️⃣ **Fine-Tuning ROI**

```
Scenario: customer support classification
  Volume: 100K requests/day
  Generic Claude Sonnet: $3K/month
  
Fine-tuned Claude Haiku:
  Training: $500 one-time
  Inference: $300/month (Haiku price)
  
ROI: break-even in 3 months.
```

> 🔑 Fine-tuning **pays off** for **high-volume, narrow tasks**. **Unnecessary** for generic questions.

---

### 7️⃣ **Streaming + Early Termination**

```python
stream = llm.stream(prompt)
for chunk in stream:
    if condition_met(chunk):
        stream.close()   # stop early, reduces output cost
        break
    process(chunk)
```

---

### 8️⃣ **Distillation**

> Teaching a big model's knowledge to a "student" small model.

```
Teacher: Claude Opus (slow, expensive, accurate)
   ↓ trained on Opus outputs
Student: Llama 3.3 8B fine-tuned
   ↓
95% quality, 5% cost.
```

→ Big savings on high-volume tasks.

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
- Cache hit rate (target > 30%)
- Model distribution (Opus vs Haiku ratio)
- Optimization opportunities

---

## 🌳 Decision Flow

```
[New LLM use case]
   │
   ▼
[Volume estimate]
   │
   ├── Low volume (<1M tokens/day) → Cloud API (Claude/GPT)
   │
   ├── Medium volume + privacy → Cloud API + prompt caching
   │
   ├── High volume + cost-sensitive → Self-host Llama
   │
   └── Latency-tolerant + bulk → Batch API (50% discount)
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| All tasks on Opus | Unnecessary for 95% of work | Tiered model selection |
| Prompt caching not used | 90% input cost missed | Cache control |
| Batch API not used (for offline tasks) | 50% extra | Batch async |
| No semantic cache | Repeated API calls | Redis vector cache |
| No output limit | Long answer = expensive | max_tokens + stop |
| Fine-tune without ROI calc | Wasted investment | Volume threshold check |
| No per-user rate limit | 1 user $$$ | Token bucket |
| No cost alarm | Budget surprise | Daily $X threshold |
| No multi-model A/B test | Optimal model unknown | Eval per task |
| Streaming not used (UX) | Feels slow | Stream + early termination |

---

## 📋 LLM Cost Optimization Checklist

```
[ ] Tiered model selection (Haiku → Sonnet → Opus)
[ ] Prompt caching active (system prompt + RAG context)
[ ] Batch API (offline / nightly jobs)
[ ] Semantic cache (Redis vector)
[ ] Output length control (max_tokens + stop)
[ ] Per-user rate limit
[ ] Cost dashboard (per-team, per-model)
[ ] Daily cost alarm threshold
[ ] Fine-tune ROI calculation (high-volume narrow task)
[ ] Distillation candidate review
[ ] Streaming (latency-sensitive UX)
[ ] Model migration A/B test (trying a new provider)
[ ] Quarterly: cost optimization review
[ ] Annual: build vs buy (self-host migration threshold)
```

---

## 📚 References

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

> *"LLM cost explodes in the 'uncontrolled' budget line. Combining
> tiered model + prompt cache + batch + semantic cache makes **the
> same output 70% cheaper**. With quarterly review, $50K-500K in
> annual savings is real."*
