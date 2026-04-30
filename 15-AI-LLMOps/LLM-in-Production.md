# LLM Uygulamalarını Production'a Almak

> *"Demo'mda harikaydı; production'da p99 latency 12 saniye, bir tenant
> tüm token bütçemi yedi, model halüsinasyon görüyor — şimdi ne?"*

LLMOps = MLOps'un farklı bir alt dalı. Token'ı, prompt versiyonlamayı,
eval'i, güvenlik guardrail'lerini bir arada yönetmek gerekiyor.

---

## 📐 Production-Ready LLM uygulaması mimarisi

```
                  ┌──────────────┐
                  │ User request │
                  └──────┬───────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Rate limit / quota │  per-tenant RPS, daily token cap
              └──────────┬───────────┘
                         ▼
              ┌──────────────────────┐
              │  Input safety filter │  PII redaction, prompt injection detect
              └──────────┬───────────┘
                         ▼
              ┌──────────────────────┐
              │   Prompt template    │  versiyonlu, A/B'li, registry'den
              │   composer           │
              └──────────┬───────────┘
                         ▼
              ┌──────────────────────┐
              │   RAG retrieval      │  hybrid search: BM25 + vector
              │   (vector DB)        │  reranker (cross-encoder)
              └──────────┬───────────┘
                         ▼
              ┌──────────────────────┐
              │   LLM gateway        │  model routing, semantic cache,
              │   (Helicone/Portkey/ │  fallback, retry, budget control
              │    LiteLLM/Vellum)   │
              └──────────┬───────────┘
                         ▼
              ┌──────────────────────┐
              │  Output validation   │  schema, max length, refusal detect
              └──────────┬───────────┘
                         ▼
              ┌──────────────────────┐
              │   Trace + metrics    │  Langfuse / LangSmith / Phoenix
              │   (token, latency,   │  per-tenant cost
              │    eval score)       │
              └──────────┬───────────┘
                         ▼
                  ┌──────────────┐
                  │   Response   │
                  └──────────────┘
```

---

## 🎯 1. Model Seçimi

### Karar matrisi (2026)

| Kullanım | Önerilen model |
|---|---|
| Genel-amaç chat (kalite öncelik) | Claude 4.x Sonnet/Opus, GPT-5 (varsa), Gemini 2.x Pro |
| Agentic / tool use | Claude Sonnet/Opus (geniş context, tool calling sağlam) |
| Fiyat-performans dengesi | Claude Haiku, GPT-mini, Gemini Flash |
| Yüksek hacim, kısa cevap | Haiku, GPT-mini (paralel batch) |
| Self-host (compliance) | Llama-4, Qwen-2.5, Mistral |
| Code-specific | Claude (genel kod), DeepSeek-Coder |
| Embedding | text-embedding-3-large, voyage-3, BGE-M3 |
| Vision | Claude Sonnet, GPT-4o, Gemini |

### Kuralları

- **Sabit string ile model adı yazma** — `claude-sonnet-4-6` gibi versiyonlu kullan
- **Fallback chain** kur: primary fail → cheaper fast → static error message
- **Cost-per-task hesapla**: prompt tokens × input cost + output tokens × output cost
- **Latency profile** ölç: TTFT (time-to-first-token), tokens/sec, end-to-end

---

## 📝 2. Prompt Engineering (Production)

### Prompt'lar = kod

```
prompts/
├── customer-support/
│   ├── v1.0.0.md
│   ├── v1.1.0.md
│   └── v2.0.0-rc.1.md
└── content-summarize/
    └── v1.0.0.md
```

Her promptun:
- **Versiyon numarası** (semver)
- **Test seti** (input → expected behavior)
- **Eval score** (otomatik koşan)
- **Changelog** (neden değişti)

### Anti-pattern: hardcoded prompt

```python
# ❌ Kötü
def summarize(text):
    return llm.complete(f"Summarize this: {text}")

# ✅ Versiyonlu prompt registry
def summarize(text):
    prompt = prompt_registry.get("summarize", version="v2.0.0")
    return llm.complete(prompt.render(text=text))
```

### A/B test prompt versiyonu

```python
prompt_version = ab_test.assign(user_id, ["v1.5.0", "v2.0.0-rc.1"])
output = llm.complete(prompts[prompt_version].render(...))
log.info("prompt_version", version=prompt_version, output_quality=...)
```

---

## 🔍 3. RAG (Retrieval-Augmented Generation)

### Mimari kararlar

| Karar | Seçenek | Notu |
|---|---|---|
| Vector DB | Qdrant, Weaviate, Pinecone, pgvector | Self-host: Qdrant; managed: Pinecone |
| Embedding model | text-embedding-3-large, voyage-3, BGE-M3 | Multilingual: BGE-M3, voyage-3 |
| Chunking strategy | Sliding window, semantic, hierarchical | Hierarchical (parent-child) en iyi sonuç verir |
| Reranker | cross-encoder, cohere-rerank, voyage-rerank | Top-N retrieve → top-K rerank |
| Hybrid search | BM25 + dense | Tek başına dense yetmez |

### Pipeline

```
┌────────────┐
│ Document   │
│ ingest     │  PDF / HTML / Markdown
└─────┬──────┘
      ▼
┌────────────┐
│ Chunker    │  parent (1500 tok) → child (300 tok)
└─────┬──────┘
      ▼
┌────────────┐
│ Embed      │  child chunks
└─────┬──────┘
      ▼
┌────────────┐
│ Vector DB  │  index: (vector, parent_id, metadata)
└─────┬──────┘
      ▼
─── Query time ─────────────────────
┌────────────┐
│ Embed query│
└─────┬──────┘
      ▼
┌────────────┐
│ Hybrid     │  vector(top 50) UNION BM25(top 20)
│ retrieve   │
└─────┬──────┘
      ▼
┌────────────┐
│ Rerank     │  cross-encoder top-K
│ (top 5)    │
└─────┬──────┘
      ▼
┌────────────┐
│ Fetch      │  child → parent context
│ parent     │
└─────┬──────┘
      ▼
┌────────────┐
│ Compose    │  prompt + parent contexts
│ prompt     │
└─────┬──────┘
      ▼
┌────────────┐
│ LLM        │
└────────────┘
```

### Eval metrikleri (RAG-spesifik)

- **Retrieval recall@K** — doğru chunk top-K'de mi?
- **Faithfulness** — yanıt context'e dayanıyor mu (hallucination yok mu)?
- **Answer relevance** — yanıt soruya cevap veriyor mu?
- **Context precision** — gönderilen context'in ne kadarı gerçekten kullanıldı?

Tools: **Ragas**, **TruLens**, **Phoenix Evals**.

---

## 💰 4. Token Cost Management

### Sorunlar

- Tek bir tenant tüm aylık bütçeyi yer
- Prompt'lar büyürken kimse fark etmez (1 → 5K token sessizce)
- Output streaming yokken kullanıcı bekleyince timeout retry → 2x cost

### Pattern'ler

#### Per-tenant rate limit + quota

```python
# Pseudocode
async def chat(user_id, msg):
    tenant = get_tenant(user_id)

    # 1. Rate limit (per-second)
    if not rate_limiter.allow(tenant.id, max_rps=tenant.tier_rps):
        return error(429, "Rate limit exceeded")

    # 2. Daily token budget
    if tenant.tokens_today >= tenant.daily_quota:
        return error(429, "Daily token quota exceeded")

    # 3. LLM call
    response = await llm.chat(msg)

    # 4. Track usage
    tenant.tokens_today += response.usage.total_tokens
    metrics.tokens_used.labels(tenant=tenant.id).inc(response.usage.total_tokens)

    return response
```

#### Semantic cache

Aynı (veya benzer) sorgu için cache.

```python
# Embedding ile similarity check
query_embedding = embed(user_msg)
cache_hit = vector_cache.search(query_embedding, threshold=0.95)
if cache_hit:
    return cache_hit.response   # token harcanmadı

response = llm.chat(user_msg)
vector_cache.set(query_embedding, response, ttl=3600)
```

GPT-Cache, Helicone semantic cache, custom Redis ile yapılabilir.

#### Model routing

Soru complexity'sine göre model seç:

```python
def route_model(question):
    complexity = classify_complexity(question)
    if complexity == "simple":
        return "haiku"     # 10x ucuz
    elif complexity == "medium":
        return "sonnet"
    else:
        return "opus"
```

#### Streaming response (TTFT < 1s)

```python
# Backend
async for chunk in llm.stream(msg):
    yield chunk    # ws / SSE

# Frontend
const eventSource = new EventSource('/chat')
eventSource.onmessage = (e) => appendToken(e.data)
```

Streaming'siz: kullanıcı 8 saniye dondu, refresh basıp tekrar request → cost 2x.

---

## 🛡️ 5. Safety Guardrails

### Input filtering

```python
# 1. PII redaction
msg_clean = pii_redactor.redact(user_msg, types=["email", "phone", "credit_card"])

# 2. Prompt injection detection
if injection_detector.is_suspicious(user_msg):
    return error(400, "Suspicious input detected")

# 3. Topic restriction
if not topic_classifier.is_in_scope(user_msg, allowed_topics):
    return "Bu konu kapsam dışı."
```

Tools: Microsoft Presidio (PII), Lakera Guard, Rebuff, OpenAI Moderation API.

### Output validation

```python
# 1. Schema validation (structured output)
try:
    parsed = MyResponseSchema.model_validate_json(response.content)
except ValidationError:
    return retry_with_correction(response)

# 2. Refusal detection
if is_refusal(response.content):  # "I cannot help with that"
    log.warn("refusal", input=user_msg)

# 3. PII leak check
if pii_detector.contains_pii(response.content):
    response.content = pii_redactor.redact(response.content)

# 4. Hallucination check (RAG için)
faithfulness = eval.faithfulness(question, context, response.content)
if faithfulness < 0.7:
    return "Bu sorunun güvenilir bir cevabını bulamadım."
```

---

## 📊 6. Observability — LLM versiyonu "altın 4 sinyal"

| Sinyal | Ne ölçülür |
|---|---|
| **Latency** | TTFT, tokens/sec, end-to-end p50/p99 |
| **Token cost** | per-tenant, per-prompt-template, daily burn rate |
| **Quality** | LLM-as-judge eval score, user feedback (👍/👎), RAG faithfulness |
| **Safety** | refusal rate, PII detection rate, jailbreak attempt rate |

### Toolchain

- **Langfuse** (OSS, self-host) — trace, eval, prompt management
- **LangSmith** (LangChain, hosted)
- **Phoenix** (Arize, OSS) — eval focused
- **Helicone** — proxy + observability
- **Honeycomb / Datadog** — geleneksel APM + LLM extensions

### Trace örneği

```
trace_id: abc123
├── span: rag.embed_query        | 12ms
├── span: rag.vector_search       | 45ms (returned: 50 candidates)
├── span: rag.rerank              | 380ms
├── span: prompt.compose          | 5ms (1820 tokens)
├── span: llm.chat                | 4200ms (TTFT: 850ms, output: 280 tokens)
├── span: validation.schema       | 8ms
└── span: validation.faithfulness | 1500ms (score: 0.92)
                          total: 6150ms
```

---

## 🔬 7. Eval Harness

CI'da prompt değişikliği = eval suite'i koşmalı. Regression yakala.

### Evaluation sets

```python
# tests/eval/customer-support.json
[
  {
    "input": "Siparişim nerede?",
    "expected_intent": "order_status",
    "expected_tone": "helpful",
    "must_contain": ["sipariş takibi", "tracking"],
    "must_not_contain": ["bilmiyorum", "sorry"]
  },
  ...
]
```

### Eval methods

1. **Exact match** — schema/intent için
2. **Embedding similarity** — semantic match için
3. **LLM-as-judge** — kalite için (başka bir LLM puanlasın)
4. **Custom function** — domain-specific kurallar

### Pipeline'a entegrasyon

```yaml
- name: Run eval suite
  run: |
    python -m eval --suite customer-support \
      --prompt-version $(git describe --tags) \
      --baseline-version $(git describe --tags HEAD~1) \
      --fail-on-regression
```

PR'a comment olarak skor diff:
```
prompt-customer-support v2.0.0-rc.1 vs v1.5.0
  - intent_accuracy:  0.92 → 0.94 (+0.02) ✅
  - tone_score:       4.2  → 4.5  (+0.3)  ✅
  - faithfulness:     0.88 → 0.85 (-0.03) ⚠️
  - cost_per_call:    $0.012 → $0.018 (+50%) ⚠️
```

---

## 🎯 "Demo → Production" 12-madde checklist

- [ ] Model adı/versiyonu kod sabitlerinde değil config'de
- [ ] Prompt'lar versiyonlu (Git, registry)
- [ ] Eval harness var, CI'da koşuyor
- [ ] Token cost per-request track ediliyor
- [ ] Per-tenant rate limit + daily quota
- [ ] Streaming response (TTFT < 1s hedef)
- [ ] Output schema validation
- [ ] PII redaction (input + output)
- [ ] Prompt injection detection
- [ ] Trace ID her request için
- [ ] Fallback chain (primary fail → cheaper)
- [ ] Semantic cache (cost reduction)

---

## 📚 Devamı

- [`Prompt-Engineering-for-Ops.md`](Prompt-Engineering-for-Ops.md)
- [`RAG-Architecture.md`](RAG-Architecture.md)
- [`Safety-and-Guardrails.md`](Safety-and-Guardrails.md)
- [Anthropic — Building effective agents](https://www.anthropic.com/research/building-effective-agents)
- [LangChain — Building LLM apps in production](https://python.langchain.com)
- [Langfuse docs](https://langfuse.com/docs)
