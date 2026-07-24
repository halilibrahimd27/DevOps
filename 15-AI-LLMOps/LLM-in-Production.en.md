---
description: "Taking LLM applications to production: LLMOps architecture with rate limiting, input safety, prompt template registry, eval, observability, cost, and guardrails."
tags:
  - AI/LLMOps
  - Observability
  - Security
  - Cost Optimization
  - Platform Engineering
---
# Taking LLM Applications to Production

> *"It was great in my demo; in production p99 latency is 12 seconds, one
> tenant ate my entire token budget, the model is hallucinating — now what?"*

LLMOps is MLOps's own sub-discipline. You need to manage tokens, prompt
versioning, eval, and security guardrails together.

---

## 📐 Production-Ready LLM Application Architecture

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
              │   Prompt template    │  versioned, A/B-tested, from the registry
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

## 🎯 1. Model Selection

### Decision matrix (2026)

| Use case | Recommended model |
|---|---|
| General-purpose chat (quality priority) | Claude 4.x Sonnet/Opus, GPT-5 (if available), Gemini 2.x Pro |
| Agentic / tool use | Claude Sonnet/Opus (wide context, solid tool calling) |
| Price-performance balance | Claude Haiku, GPT-mini, Gemini Flash |
| High volume, short answers | Haiku, GPT-mini (parallel batch) |
| Self-host (compliance) | Llama-4, Qwen-2.5, Mistral |
| Code-specific | Claude (general code), DeepSeek-Coder |
| Embedding | text-embedding-3-large, voyage-3, BGE-M3 |
| Vision | Claude Sonnet, GPT-4o, Gemini |

### Rules

- **Don't hardcode the model name as a fixed string** — use a versioned tag like `claude-sonnet-4-6`
- Set up a **fallback chain**: primary fail → cheaper/fast → static error message
- **Calculate cost-per-task**: prompt tokens × input cost + output tokens × output cost
- Measure the **latency profile**: TTFT (time-to-first-token), tokens/sec, end-to-end

---

## 📝 2. Prompt Engineering (Production)

### Prompts = code

```
prompts/
├── customer-support/
│   ├── v1.0.0.md
│   ├── v1.1.0.md
│   └── v2.0.0-rc.1.md
└── content-summarize/
    └── v1.0.0.md
```

Each prompt needs:
- **Version number** (semver)
- **Test set** (input → expected behavior)
- **Eval score** (runs automatically)
- **Changelog** (why it changed)

### Anti-pattern: hardcoded prompt

```python
# ❌ Bad
def summarize(text):
    return llm.complete(f"Summarize this: {text}")

# ✅ Versioned prompt registry
def summarize(text):
    prompt = prompt_registry.get("summarize", version="v2.0.0")
    return llm.complete(prompt.render(text=text))
```

### A/B test a prompt version

```python
prompt_version = ab_test.assign(user_id, ["v1.5.0", "v2.0.0-rc.1"])
output = llm.complete(prompts[prompt_version].render(...))
log.info("prompt_version", version=prompt_version, output_quality=...)
```

---

## 🔍 3. RAG (Retrieval-Augmented Generation)

### Architecture decisions

| Decision | Option | Note |
|---|---|---|
| Vector DB | Qdrant, Weaviate, Pinecone, pgvector | Self-host: Qdrant; managed: Pinecone |
| Embedding model | text-embedding-3-large, voyage-3, BGE-M3 | Multilingual: BGE-M3, voyage-3 |
| Chunking strategy | Sliding window, semantic, hierarchical | Hierarchical (parent-child) gives the best results |
| Reranker | cross-encoder, cohere-rerank, voyage-rerank | Top-N retrieve → top-K rerank |
| Hybrid search | BM25 + dense | Dense alone isn't enough |

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

### Eval metrics (RAG-specific)

- **Retrieval recall@K** — is the correct chunk in the top-K?
- **Faithfulness** — is the answer grounded in the context (no hallucination)?
- **Answer relevance** — does the answer address the question?
- **Context precision** — how much of the sent context was actually used?

Tools: **Ragas**, **TruLens**, **Phoenix Evals**.

---

## 💰 4. Token Cost Management

### Problems

- A single tenant eats the entire monthly budget
- Prompts grow and nobody notices (1 → 5K tokens, silently)
- Without output streaming, the user waits, hits a timeout, retries → 2x cost

### Patterns

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

Cache identical (or similar) queries.

```python
# Similarity check via embedding
query_embedding = embed(user_msg)
cache_hit = vector_cache.search(query_embedding, threshold=0.95)
if cache_hit:
    return cache_hit.response   # no tokens spent

response = llm.chat(user_msg)
vector_cache.set(query_embedding, response, ttl=3600)
```

GPT-Cache, Helicone semantic cache, or a custom Redis setup can do this.

#### Model routing

Pick a model based on the question's complexity:

```python
def route_model(question):
    complexity = classify_complexity(question)
    if complexity == "simple":
        return "haiku"     # 10x cheaper
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

Without streaming: the user sits frozen for 8 seconds, hits refresh, sends the request again → cost 2x.

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
    return "This topic is out of scope."
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

# 4. Hallucination check (for RAG)
faithfulness = eval.faithfulness(question, context, response.content)
if faithfulness < 0.7:
    return "I couldn't find a reliable answer to this question."
```

---

## 📊 6. Observability — the "golden 4 signals," LLM edition

| Signal | What's measured |
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
- **Honeycomb / Datadog** — traditional APM + LLM extensions

### Trace example

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

A prompt change in CI = the eval suite must run. Catch regressions.

### Evaluation sets

```python
# tests/eval/customer-support.json
[
  {
    "input": "Where is my order?",
    "expected_intent": "order_status",
    "expected_tone": "helpful",
    "must_contain": ["order tracking", "tracking"],
    "must_not_contain": ["I don't know", "sorry"]
  },
  ...
]
```

### Eval methods

1. **Exact match** — for schema/intent
2. **Embedding similarity** — for semantic match
3. **LLM-as-judge** — for quality (have another LLM score it)
4. **Custom function** — domain-specific rules

### Pipeline integration

```yaml
- name: Run eval suite
  run: |
    python -m eval --suite customer-support \
      --prompt-version $(git describe --tags) \
      --baseline-version $(git describe --tags HEAD~1) \
      --fail-on-regression
```

Score diff posted as a PR comment:
```
prompt-customer-support v2.0.0-rc.1 vs v1.5.0
  - intent_accuracy:  0.92 → 0.94 (+0.02) ✅
  - tone_score:       4.2  → 4.5  (+0.3)  ✅
  - faithfulness:     0.88 → 0.85 (-0.03) ⚠️
  - cost_per_call:    $0.012 → $0.018 (+50%) ⚠️
```

---

## 🎯 "Demo → Production" 12-item checklist

- [ ] Model name/version is in config, not hardcoded in the code
- [ ] Prompts are versioned (Git, registry)
- [ ] Eval harness exists, runs in CI
- [ ] Token cost is tracked per-request
- [ ] Per-tenant rate limit + daily quota
- [ ] Streaming response (TTFT < 1s target)
- [ ] Output schema validation
- [ ] PII redaction (input + output)
- [ ] Prompt injection detection
- [ ] Trace ID for every request
- [ ] Fallback chain (primary fail → cheaper)
- [ ] Semantic cache (cost reduction)

---

## 📚 Continue Reading

- [`Prompt-Engineering-for-Ops.md`](Prompt-Engineering-for-Ops.md)
- [`RAG-Architecture.md`](RAG-Architecture.md)
- [`Safety-and-Guardrails.md`](Safety-and-Guardrails.md)
- [Anthropic — Building effective agents](https://www.anthropic.com/research/building-effective-agents)
- [LangChain — Building LLM apps in production](https://python.langchain.com)
- [Langfuse docs](https://langfuse.com/docs)

---

## 📚 References

- [`Safety-and-Guardrails.md`](Safety-and-Guardrails.md) — input/output guardrails, PII, prompt injection in depth
- [`Model-Cost-Optimization.md`](Model-Cost-Optimization.md) — token cost, semantic cache, model routing details
- [`RAG-Architecture.md`](RAG-Architecture.md) — hybrid search, chunking, reranker patterns
- [`../07-Observability/OpenTelemetry-Adoption.md`](../07-Observability/OpenTelemetry-Adoption.md) — trace/span infrastructure (this is where LLM tracing plugs in)
- [`../08-Security/Secrets-Management.md`](../08-Security/Secrets-Management.md) — API key/token storage, rotation
- [OpenTelemetry docs](https://opentelemetry.io/docs/) — the trace standard

---

> *"What keeps an LLM standing in production isn't the model; it's the surrounding environment — versioned prompts, eval in CI, per-tenant quotas, token cost, guardrails, and traces. Working in a demo proves nothing."*
