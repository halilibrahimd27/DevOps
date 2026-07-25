---
description: "Self-hosted LLM: setup with vLLM, Ollama, and Llama Stack, GPU capacity planning, production recommendations; the upsides of self-hosting for privacy, cost, and offline."
tags:
  - AI/LLMOps
  - Kubernetes
  - Cost Optimization
  - Performance
  - Security
---
# Self-Hosted LLM — vLLM, Ollama, Llama Stack

> *"Using the OpenAI / Anthropic API is fast but: you send data,
> you pay per token, vendor lock-in. **Self-host** = privacy +
> cost predictability + offline + multi-tenant control."*

This guide covers setting up the self-hosted LLM stack — vLLM, Ollama, Llama Stack —
planning GPU capacity, and production recommendations.

---

## 🎯 Why Self-Host?

| Question | Self-host advantage |
|---|---|
| **Privacy / compliance** | Data doesn't leave for an external service (KVKK / HIPAA / GDPR relaxed) |
| **Cost predictability** | $5K/month flat vs $0.01 token (cheaper at scale) |
| **Offline / air-gapped** | No internet access, must work |
| **Latency** | < 100ms first token (no network round-trip) |
| **Custom fine-tuning** | Domain-specific model |
| **Multi-tenant control** | Per-team rate limit, audit |

### Self-host **downsides**
- Initial GPU CapEx ($10K-100K)
- Ops burden (model serving, monitoring)
- When a new model ships, the "how do we update?" solution
- Quality — frontier models (Claude / GPT-4/5) are still ahead

---

## ⚖️ Self-Hostable Models in 2026

| Model | Size | GPU |
|---|---|---|
| **Llama 3.3 70B** | 70B param | 2× A100 80GB or 1× H100 |
| **Llama 3.3 8B** | 8B param | 1× A10 / RTX 4090 |
| **Mistral Large** | 123B param | 4× A100 80GB |
| **Qwen 2.5 72B** | 72B param | 2× A100 80GB |
| **DeepSeek R1** | 671B param (MoE, ~37B active) | 8× H100 |
| **Phi-3.5** (Microsoft) | 3.8B-14B | 1× RTX 4090 |
| **Gemma 2** (Google) | 9B-27B | 1× A100 |

> 🔑 **2026 recommendation**: Llama 3.3 8B (general purpose) or Llama 3.3 70B (advanced).

---

## 🚀 Tooling Comparison

| Tool | Niche |
|---|---|
| **vLLM** | Production-grade, high throughput, K8s native |
| **Ollama** | Local dev, easy CLI, single user |
| **Llama Stack (Meta)** | Enterprise reference impl |
| **TGI** (HuggingFace) | Production, HF ecosystem |
| **TensorRT-LLM** (NVIDIA) | NVIDIA GPU optimal, fastest |
| **llama.cpp** | CPU-only / Apple Silicon |
| **LocalAI** | OpenAI-compatible API self-hosted |

> 🔑 **Production**: vLLM (multi-user, K8s). **Dev/laptop**: Ollama.

---

## 🛠️ vLLM Setup (K8s)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vllm-llama3-8b
spec:
  replicas: 2
  template:
    spec:
      nodeSelector:
        nvidia.com/gpu: "true"
      containers:
        - name: vllm
          image: vllm/vllm-openai:latest
          args:
            - --model=meta-llama/Llama-3.3-8B-Instruct
            - --tensor-parallel-size=1
            - --max-model-len=8192
            - --gpu-memory-utilization=0.9
          resources:
            limits:
              nvidia.com/gpu: 1
              memory: 32Gi
            requests:
              nvidia.com/gpu: 1
              memory: 32Gi
          env:
            - name: HF_TOKEN
              valueFrom: {secretKeyRef: {name: hf-creds, key: token}}
          ports:
            - containerPort: 8000
```

### OpenAI-compatible API
```bash
# vLLM exposes OpenAI-compatible endpoint
curl http://vllm-svc:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Llama-3.3-8B-Instruct",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

→ OpenAI SDK code change minimum:
```python
from openai import OpenAI

client = OpenAI(
    base_url="http://vllm-svc:8000/v1",
    api_key="dummy"   # internal, no auth
)

response = client.chat.completions.create(
    model="meta-llama/Llama-3.3-8B-Instruct",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

---

## 💾 Ollama (Local Dev)

```bash
# Install
curl -fsSL https://ollama.com/install.sh | sh

# Pull model
ollama pull llama3.3:8b

# Run
ollama run llama3.3:8b
> "Hello, how can I help?"

# API mode
ollama serve
curl http://localhost:11434/api/generate \
  -d '{"model": "llama3.3:8b", "prompt": "Hello"}'
```

> 🔑 **Ollama** is ideal for dev/laptop. For production scale, vLLM.

---

## 📊 GPU Capacity Planning

### Throughput estimation
| Model | GPU | Throughput (tokens/sec) | Concurrent users |
|---|---|---|---|
| Llama 3.3 8B (FP16) | A10 24GB | ~80 t/s | ~4-8 |
| Llama 3.3 8B (INT8) | A10 24GB | ~150 t/s | ~10 |
| Llama 3.3 70B (FP16) | 2×A100 80GB | ~30 t/s | ~3-5 |
| Llama 3.3 70B (FP8) | 2×A100 80GB | ~60 t/s | ~8-10 |

### Cost comparison
```
Use case: 1M token/day

Cloud API (Claude Haiku):
  Input: 1M × $0.25/1M = $0.25/day
  Output: ... → ~$0.50/day
  Monthly: ~$15

Self-host (Llama 3.3 8B):
  GPU: 1× A10 → AWS g5.xlarge $0.40/hour × 720 = $288/month
  Engineering ops: $X
  
→ Cloud API CHEAPER for low-volume.
→ Self-host CHEAPER for >10M token/day or if privacy is mandatory.
```

---

## 🔄 Quantization (FP16 → INT8 / INT4)

> **Quantization**: Lower precision, gain speed + memory, lose a bit of quality.

| Precision | Memory | Speed | Quality |
|---|---|---|---|
| FP32 | 4× model size | Slow | Best |
| FP16 | 2× | Medium | Very good |
| FP8 | 1× | Fast | Good |
| INT8 | 0.5× | Fast | Usually good |
| INT4 | 0.25× | Fastest | Sometimes lossy |

```bash
# INT8 quantization with vLLM
vllm --model=meta-llama/Llama-3.3-70B-Instruct --quantization=fp8
```

> 🔑 **INT8 quantization** is transparent for most use cases. Fine-tuned models sometimes lose quality.

---

## 🚧 Production Concerns

### 1. Multi-tenant rate limit
```python
# gateway in front of vLLM (FastAPI)
@app.post("/v1/chat/completions")
@rate_limit(per_user=10, window="1m")
async def chat(request, user: User):
    return await vllm_proxy(request)
```

### 2. Monitoring
```promql
# vLLM Prometheus metrics
vllm_request_latency_seconds_bucket
vllm_tokens_total
vllm_gpu_utilization
vllm_kv_cache_usage_percentage
```

### 3. Model versioning
- Model registry (MLflow / Hugging Face Hub mirror)
- Canary: new model 5% traffic
- Rollback: previous version ready

### 4. Failover
- Multi-region GPU
- Cloud API fallback (vLLM down → Anthropic API)

### 5. Audit
- Per-call log
- 6+ month retention for EU AI Act high-risk

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Self-host for everything | Low volume, extra ops | Hybrid: cloud API + self-host critical |
| GPU over-provision | $$$ idle | Karpenter spot GPU + auto-scale |
| 70B without quantization | Too much memory | INT8 / FP8 quantization |
| Single replica | SPOF | 2+ replica, multi-AZ |
| No model versioning | Surprise regression | Canary + rollback |
| No audit log | Compliance | Per-call structured log |
| No cloud API + self-host A/B test | "Is it good?" unknown | Eval set + metrics |
| No rate limit | 1 user all GPU | Per-user limit |
| No cold start optimization | First request 30s | Pre-warm replicas |
| HF model token in Git | Compromise | Vault + ESO |

---

## 📋 Self-Hosted LLM Production Checklist

```
[ ] Use case justified (privacy / volume / cost)
[ ] Model selection (Llama 3.3 8B / 70B)
[ ] vLLM K8s deploy
[ ] GPU: NVIDIA A10/A100/H100, capacity planned
[ ] Quantization (INT8/FP8 mostly)
[ ] OpenAI-compatible API (easy migration)
[ ] HF token in Vault + ESO
[ ] Multi-replica HA
[ ] Rate limit per user/team
[ ] Prometheus metrics + Grafana dashboard
[ ] Audit log per-call (compliance)
[ ] Model versioning + canary
[ ] Cloud API fallback
[ ] Eval set: cloud API vs self-host quality compare
[ ] Quarterly: cost + quality review
```

---

## 📚 References

- **vLLM** — vllm.ai
- **Ollama** — ollama.com
- **Llama (Meta)** — llama.com
- **Hugging Face** — huggingface.co
- **TGI** — github.com/huggingface/text-generation-inference
- **TensorRT-LLM** — github.com/NVIDIA/TensorRT-LLM
- **vLLM Cookbook** — vllm.ai/cookbook
- [`LLM-in-Production.md`](LLM-in-Production.md)
- [`RAG-Architecture.md`](RAG-Architecture.md)
- [`Safety-and-Guardrails.md`](Safety-and-Guardrails.md)
- [`Model-Cost-Optimization.md`](Model-Cost-Optimization.md)
- [`19-Compliance/EU-AI-Act.md`](../19-Compliance/EU-AI-Act.md)
- [`19-Compliance/KVKK-Practical.md`](../19-Compliance/KVKK-Practical.md)

---

> *"Self-host isn't 'cool' — it's a **strategic decision**. If privacy is
> mandatory, if volume is high, if you want to avoid vendor lock-in, **vLLM
> + GPU** is the right choice. Otherwise Cloud API is cheap + fast."*
