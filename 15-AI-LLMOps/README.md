# 15 · AI / LLMOps

> *"Çalışıyor demo'mda; production'da p99 latency 12 saniye, bir tenant
> tüm token bütçemi yedi, model halüsinasyon görüyor — şimdi ne?"*

Generative AI uygulamalarının prod'a alınması yeni bir disiplin: LLMOps.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`LLM-in-Production.md`](LLM-in-Production.md) | RAG arch, eval, observability, cost, safety guardrail'ler |
| _`Prompt-Engineering-for-Ops.md`_ *(yakında)* | Prompt'lar kod gibi: versiyonlama, test, A/B |
| _`RAG-Architecture.md`_ *(yakında)* | Vector DB seçimi, chunking strategi, hybrid search, eval |
| _`AI-Augmented-Operations.md`_ *(yakında)* | Incident summarization, log search, root cause assist |
| _`Self-Hosted-LLM.md`_ *(yakında)* | vLLM, Triton, TGI; GPU node pool, autoscaling |
| _`Model-Cost-Optimization.md`_ *(yakında)* | Model routing, caching, batching, quantization |
| _`Safety-and-Guardrails.md`_ *(yakında)* | Prompt injection, PII redaction, jailbreak detection |

## "MLOps vs LLMOps"

| MLOps | LLMOps |
|---|---|
| Train → deploy → monitor → retrain | RAG ingest → prompt → eval → fine-tune (rare) |
| Feature store, training data | Vector store, prompt templates |
| Drift = data distribution shift | Drift = prompt regression, model deprecation |
| Eval = AUC, precision, recall | Eval = LLM-as-judge, golden datasets, BLEU/ROUGE |
| Latency: ms | Latency: 100ms – 30s (streaming için) |
| Cost: GPU training | Cost: token (input/output ayrı) |

## Production-ready LLM uygulaması mimarisi

```
                  ┌──────────────┐
                  │ User request │
                  └──────┬───────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Rate limit / quota │
              │ (per-tenant, RPS)    │
              └──────────┬───────────┘
                         ▼
              ┌──────────────────────┐
              │  Input safety filter │  (PII, prompt injection)
              └──────────┬───────────┘
                         ▼
              ┌──────────────────────┐
              │   Prompt template    │  (versiyonlu, A/B'li)
              │   composer           │
              └──────────┬───────────┘
                         ▼
              ┌──────────────────────┐
              │   RAG retrieval      │  (hybrid search: BM25 + vector)
              │   (vector DB)        │
              └──────────┬───────────┘
                         ▼
              ┌──────────────────────┐
              │   LLM gateway        │  (model routing, caching)
              │   (Helicone/Portkey/ │
              │    LiteLLM)          │
              └──────────┬───────────┘
                         ▼
              ┌──────────────────────┐
              │  Output validation   │  (schema, hallucination, guardrails)
              └──────────┬───────────┘
                         ▼
              ┌──────────────────────┐
              │   Trace + metrics    │  (Langfuse / LangSmith / Phoenix)
              │   (token, latency,   │
              │    eval score)       │
              └──────────┬───────────┘
                         ▼
                  ┌──────────────┐
                  │   Response   │
                  └──────────────┘
```

## Observability "altın 4 sinyal" — LLM versiyonu

1. **Latency** — TTFT (time-to-first-token), tokens/sec, end-to-end
2. **Token cost** — per-tenant, per-prompt-template, daily burn rate
3. **Quality** — eval score (LLM-as-judge), user feedback (👍/👎)
4. **Safety** — refusal rate, PII detection rate, jailbreak attempts

## "Demo → Production" geçiş checklist

- [ ] Model adı/versiyonu tag'li (`gpt-4o-2024-08-06`, mutable değil)
- [ ] Prompt template versiyonlu (Git, registry)
- [ ] Eval harness var, CI'da koşuyor
- [ ] Token cost per-request tracking
- [ ] Per-tenant rate limit + quota
- [ ] Streaming response (TTFT < 1s)
- [ ] Output validation (schema, max length)
- [ ] PII redaction input/output
- [ ] Jailbreak/prompt-injection detection
- [ ] Trace ID her request için (Langfuse/LangSmith)
- [ ] Fallback: primary model hatası → cheaper model
- [ ] Caching (semantic + exact) for cost
- [ ] Human review workflow (low-confidence cases)

## Anti-pattern'ler

- ❌ `gpt-4` sabit string (deprecate olunca app çöker — versiyonlu kullan)
- ❌ Prompt'u kod içinde hardcoded (değiştirmek deploy gerektirir)
- ❌ Eval yok — modeli değiştirince regression görmezsin
- ❌ Token cost tracking yok → ay sonu sürpriz
- ❌ Tek tenant abuse'i tüm sistemi yiyor (per-tenant quota yok)
- ❌ "Halüsinasyon olmaz" varsayımı — output validation şart
- ❌ Stream response yok → "AI 30 sn dondu, kullanıcı kaçtı"
