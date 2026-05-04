# Self-Hosted LLM — vLLM, Ollama, Llama Stack

> *"OpenAI / Anthropic API kullanmak hızlı ama: data gönderiyorsun,
> token başına ödüyorsun, vendor lock-in. **Self-host** = privacy +
> cost predictability + offline + multi-tenant control."*

Bu rehber self-hosted LLM stack'ini — vLLM, Ollama, Llama Stack —
kurmak, GPU kapasitesi planlamak, ve production önerilerini anlatır.

---

## 🎯 Niye Self-Host?

| Soru | Self-host avantaj |
|---|---|
| **Privacy / compliance** | Data dış servise gitmez (KVKK / HIPAA / GDPR rahat) |
| **Cost predictability** | $5K/ay flat vs $0.01 token (büyüklükte ucuzlar) |
| **Offline / air-gapped** | Internet erişimi yok, çalışmalı |
| **Latency** | < 100ms first token (network round-trip yok) |
| **Custom fine-tuning** | Domain-specific model |
| **Multi-tenant control** | Per-team rate limit, audit |

### Self-host **dezavantaj**
- Initial GPU CapEx ($10K-100K)
- Ops yükü (model serving, monitoring)
- Yeni model yayınlandığında "biz nasıl güncelleriz?" çözümü
- Kalite — frontier model'ler (Claude / GPT-4/5) hâlâ önde

---

## ⚖️ 2026'da Self-Hostable Modeller

| Model | Boyut | GPU |
|---|---|---|
| **Llama 3.3 70B** | 70B param | 2× A100 80GB veya 1× H100 |
| **Llama 3.3 8B** | 8B param | 1× A10 / RTX 4090 |
| **Mistral Large** | 123B param | 4× A100 80GB |
| **Qwen 2.5 72B** | 72B param | 2× A100 80GB |
| **DeepSeek R1** | 671B param (MoE, ~37B active) | 8× H100 |
| **Phi-3.5** (Microsoft) | 3.8B-14B | 1× RTX 4090 |
| **Gemma 2** (Google) | 9B-27B | 1× A100 |

> 🔑 **2026 önerisi**: Llama 3.3 8B (general purpose) veya Llama 3.3 70B (advanced).

---

## 🚀 Tooling Karşılaştırması

| Tool | Niche |
|---|---|
| **vLLM** | Production-grade, high throughput, K8s native |
| **Ollama** | Local dev, easy CLI, single user |
| **Llama Stack (Meta)** | Enterprise reference impl |
| **TGI** (HuggingFace) | Production, HF ekosistem |
| **TensorRT-LLM** (NVIDIA) | NVIDIA GPU optimal, en hızlı |
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

> 🔑 **Ollama** dev/laptop için ideal. Production scale için vLLM.

---

## 📊 GPU Capacity Planning

### Throughput estimation
| Model | GPU | Throughput (tokens/sec) | Concurrent users |
|---|---|---|---|
| Llama 3.3 8B (FP16) | A10 24GB | ~80 t/s | ~4-8 |
| Llama 3.3 8B (INT8) | A10 24GB | ~150 t/s | ~10 |
| Llama 3.3 70B (FP16) | 2×A100 80GB | ~30 t/s | ~3-5 |
| Llama 3.3 70B (FP8) | 2×A100 80GB | ~60 t/s | ~8-10 |

### Cost karşılaştırması
```
Use case: 1M token/gün

Cloud API (Claude Haiku):
  Input: 1M × $0.25/1M = $0.25/gün
  Output: ... → ~$0.50/gün
  Aylık: ~$15

Self-host (Llama 3.3 8B):
  GPU: 1× A10 → AWS g5.xlarge $0.40/saat × 720 = $288/ay
  Engineering ops: $X
  
→ Cloud API CHEAPER for low-volume.
→ Self-host CHEAPER for >10M token/gün veya privacy zorunluysa.
```

---

## 🔄 Quantization (FP16 → INT8 / INT4)

> **Quantization**: Precision'ı düşür, hız + memory kazan, kalite biraz kaybet.

| Precision | Memory | Speed | Quality |
|---|---|---|---|
| FP32 | 4× model size | Yavaş | En iyi |
| FP16 | 2× | Orta | Çok iyi |
| FP8 | 1× | Hızlı | İyi |
| INT8 | 0.5× | Hızlı | Genelde iyi |
| INT4 | 0.25× | En hızlı | Bazen kayıp |

```bash
# vLLM ile INT8 quantization
vllm --model=meta-llama/Llama-3.3-70B-Instruct --quantization=fp8
```

> 🔑 **INT8 quantization** çoğu use case'de transparency yok. Fine-tuned model'ler bazen kalite kaybeder.

---

## 🚧 Production Concerns

### 1. Multi-tenant rate limit
```python
# vLLM front'unda gateway (FastAPI)
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
- Canary: yeni model %5 traffic
- Rollback: önceki versiyon hazır

### 4. Failover
- Multi-region GPU
- Cloud API fallback (vLLM down → Anthropic API)

### 5. Audit
- Per-call log
- EU AI Act high-risk için 6+ ay retention

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Self-host her şey için | Düşük volume, ekstra ops | Hibrit: cloud API + self-host critical |
| GPU over-provision | $$$ idle | Karpenter spot GPU + auto-scale |
| Quantization olmadan 70B | Çok memory | INT8 / FP8 quantization |
| Single replica | SPOF | 2+ replica, multi-AZ |
| Model versioning yok | Sürpriz regression | Canary + rollback |
| Audit log yok | Compliance | Per-call structured log |
| Cloud API + self-host A/B test yok | "İyi mi?" bilinmez | Eval set + metrics |
| Rate limit yok | 1 user tüm GPU | Per-user limit |
| Cold start optimization yok | İlk request 30s | Pre-warm replicas |
| HF model token Git'te | Compromise | Vault + ESO |

---

## 📋 Self-Hosted LLM Production Checklist

```
[ ] Use case justify edildi (privacy / volume / cost)
[ ] Model seçimi (Llama 3.3 8B / 70B)
[ ] vLLM K8s deploy
[ ] GPU: NVIDIA A10/A100/H100, capacity planlandı
[ ] Quantization (INT8/FP8 mostly)
[ ] OpenAI-compatible API (kolay migration)
[ ] HF token Vault'ta + ESO
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

## 📚 Referanslar

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

> *"Self-host 'cool' değil — **strategic karar**. Privacy zorunluysa,
> volume yüksekse, vendor lock-in'den kaçınmak istiyorsan **vLLM
> + GPU** doğru tercih. Yoksa Cloud API ucuz + hızlı."*
