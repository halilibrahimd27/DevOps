---
description: "AI/LLMOps section index: RAG, prompt engineering, self-hosted LLM, cost optimization, safety guardrails, and MLOps vs LLMOps comparison."
tags:
  - AI/LLMOps
  - Observability
  - Cost Optimization
  - Security
  - Roadmap
---
# 15 · AI / LLMOps

> *"It works in my demo; in production p99 latency is 12 seconds, one
> tenant ate my whole token budget, the model is hallucinating — now what?"*

Taking generative AI applications to production is a new discipline: LLMOps.

## Contents

| File | Topic |
|---|---|
| [`LLM-in-Production.md`](LLM-in-Production.md) | RAG architecture, eval, observability, cost, safety guardrails |
| [`Prompt-Engineering-for-Ops.md`](Prompt-Engineering-for-Ops.md) | Prompts as code: versioning, testing, A/B |
| [`RAG-Architecture.md`](RAG-Architecture.md) | Vector DB selection, chunking strategy, hybrid search, eval |
| [`AI-Augmented-Operations.md`](AI-Augmented-Operations.md) | Incident summarization, log search, root cause assist |
| [`Self-Hosted-LLM.md`](Self-Hosted-LLM.md) | vLLM, Triton, TGI; GPU node pool, autoscaling |
| [`Model-Cost-Optimization.md`](Model-Cost-Optimization.md) | Model routing, caching, batching, quantization |
| [`Safety-and-Guardrails.md`](Safety-and-Guardrails.md) | Prompt injection, PII redaction, jailbreak detection |

## "MLOps vs LLMOps"

| MLOps | LLMOps |
|---|---|
| Train → deploy → monitor → retrain | RAG ingest → prompt → eval → fine-tune (rare) |
| Feature store, training data | Vector store, prompt templates |
| Drift = data distribution shift | Drift = prompt regression, model deprecation |
| Eval = AUC, precision, recall | Eval = LLM-as-judge, golden datasets, BLEU/ROUGE |
| Latency: ms | Latency: 100ms – 30s (for streaming) |
| Cost: GPU training | Cost: token (input/output separate) |

## Production-ready LLM application architecture

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
              │   Prompt template    │  (versioned, A/B-tested)
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

## Observability "golden 4 signals" — LLM edition

1. **Latency** — TTFT (time-to-first-token), tokens/sec, end-to-end
2. **Token cost** — per-tenant, per-prompt-template, daily burn rate
3. **Quality** — eval score (LLM-as-judge), user feedback (👍/👎)
4. **Safety** — refusal rate, PII detection rate, jailbreak attempts

## "Demo → Production" transition checklist

- [ ] Model name/version is tagged (`gpt-4o-2024-08-06`, not mutable)
- [ ] Prompt template is versioned (Git, registry)
- [ ] Eval harness exists, runs in CI
- [ ] Token cost per-request tracking
- [ ] Per-tenant rate limit + quota
- [ ] Streaming response (TTFT < 1s)
- [ ] Output validation (schema, max length)
- [ ] PII redaction input/output
- [ ] Jailbreak/prompt-injection detection
- [ ] Trace ID for every request (Langfuse/LangSmith)
- [ ] Fallback: primary model failure → cheaper model
- [ ] Caching (semantic + exact) for cost
- [ ] Human review workflow (low-confidence cases)

## Anti-patterns

- ❌ `gpt-4` as a fixed string (app breaks when it's deprecated — use a versioned tag)
- ❌ Prompt hardcoded in code (changing it requires a deploy)
- ❌ No eval — you won't catch regressions when you swap models
- ❌ No token cost tracking → end-of-month surprise
- ❌ One tenant's abuse eats the whole system (no per-tenant quota)
- ❌ The "it won't hallucinate" assumption — output validation is mandatory
- ❌ No streaming response → "AI froze for 30s, user left"
