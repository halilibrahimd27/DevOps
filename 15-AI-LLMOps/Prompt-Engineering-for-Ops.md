# Prompt Engineering for Ops — DevOps İçin Pratik LLM Kullanımı

> *"LLM'e 'şunu yap' demek = junior'a yarım talimat vermek. Spesifik
> + örnekli + bağlamlı prompt = senior'a brief vermek. **Prompt
> kalitesi**, output kalitesidir."*

Bu rehber DevOps/SRE'nin gündelik işlerinde — log analizi, runbook
generation, incident summary, code review, postmortem yazımı —
pratik prompt pattern'lerini somut örneklerle gösterir.

---

## 🎯 Prompt Mühendisliği Temelleri

### Anatomi
```
[Context]    "Sen bir SRE asistanısın..."
[Task]       "Şu log'u incele..."
[Format]     "Output JSON yapısında olsun..."
[Examples]   (few-shot, opsiyonel)
[Input]      "<actual log here>"
```

### 5 prensip
1. **Spesifik ol** — "log analiz et" değil, "5xx pattern'leri bul"
2. **Format tanımla** — JSON / markdown / table?
3. **Bağlam ver** — domain, audience, kısıt
4. **Örnek sun** (few-shot) — kompleks task için
5. **Hata için izin** — "bilmiyorum" diyebilmesini sağla

---

## 🛠️ Use Case 1: Log Analizi

### Naif prompt (kötü)
```
"Bu log'u analiz et: <LOG>"
```

→ Generic özet, actionable değil.

### İyi prompt
```
Sen bir SRE asistanısın. Aşağıdaki Postgres log'unu incele:

1. Anomali / hata pattern'lerini bul (ERROR, FATAL, slow query > 1s).
2. Her bulgu için:
   - Severity (CRITICAL / WARNING / INFO)
   - Olası kök neden
   - Önerilen aksiyon (komut + runbook adımı)
3. Çıktıyı JSON formatında ver:
   ```json
   {
     "findings": [
       {"severity": "...", "pattern": "...", "root_cause": "...", "action": "..."}
     ],
     "summary": "..."
   }
   ```

Log:
<LOG_PASTE>
```

→ Yapısal, parse edilebilir, action item'lı.

---

## 🛠️ Use Case 2: Runbook Generation

### Prompt
```
Sen bir SRE asistanısın. Aşağıdaki Prometheus alarm tanımı için
runbook yaz:

Alarm: PostgresHighConnections
Expr: pg_stat_activity_count / pg_settings_max_connections > 0.85
Severity: SEV-2

Runbook formatı:
- TL;DR (30 saniyede özet)
- 1. Verify (alarm gerçek mi)
- 2. Quick Mitigation (5-10 dk)
- 3. Investigation (15-30 dk)
- 4. Common Causes (tablo)
- 5. Escalation
- 6. After the fix

Türkçe yaz, somut komutlar ver, [`11-SRE/Runbook-Template.md`] formatına uy.
```

→ İlk taslak %80 doğru, manuel review ile prod-ready.

---

## 🛠️ Use Case 3: Incident Summary (Executive)

### Prompt
```
CTO için executive summary yaz. Şu detayları kullan:

INPUT:
- Olay başladı: 15:30
- Çözüldü: 15:48
- Etkilenen: ~%35 EU traffic
- Servis: payment endpoint
- Cause: connection pool 100 → 50 yapılmış son deploy'da
- Fix: rollback + pool 200'e çıkar

KURALLAR:
- 5 satır, business etkisi vurgulu
- Teknik jargon yok
- Net önerin / sonraki adım

ÇIKTI:
What:
Impact:
Cause:
Fix:
Action:
```

### Sonuç
```
What:    Payment endpoint 18 dakika down (15:30-15:48).
Impact:  ~340 müşteri etkilendi, ~$12K kayıp gelir.
Cause:   Son deploy'da DB connection pool 100 → 50 düşürdü, traffic spike'ında pool tükendi.
Fix:     Rollback yapıldı, pool 200'e çıkarıldı.
Action:  Postmortem 5 iş günü içinde. Bütçe etkisi yok.
```

→ CEO 30 saniyede okur.

---

## 🛠️ Use Case 4: Code Review (PR'da)

### Prompt
```
Sen bir senior backend engineer'sın. Aşağıdaki Go PR'ını review et:

ODAK ALAN:
1. Concurrency: race condition?
2. Error handling: catch'in içi handle ediyor mu?
3. Security: input validation, SQL injection?
4. Performance: N+1, hot path allocation?
5. Test: coverage yeterli mi?

NOT:
- Sadece blocker / suggestion seviyesinde yorum yap.
- "nit" (kozmetik) önerme.
- Prefix: "blocker:", "suggestion:", "question:"
- Türkçe yaz.

DIFF:
<PR_DIFF>
```

→ Reviewer için pre-screen. İnsan reviewer kalan zamanını **tasarım**'a ayırır.

---

## 🛠️ Use Case 5: Postmortem Draft

### Prompt
```
Aşağıdaki incident timeline'ından blameless postmortem'in **draft**ını yaz:

TIMELINE:
[15:30] Deploy v1.4.2 başladı
[15:32] Payment endpoint p99 50ms → 8s
[15:35] Alert düştü
[15:38] On-call IC açtı
[15:42] Root cause: connection pool config
[15:45] Rollback başladı
[15:48] Resolved

KURALLAR:
- BLAMELESS: kişi suçlama yok
- Sistem perspektifli
- 5-Whys uygulanmış olsun
- Action item: spesifik + sahipli + tarihli
- Türkçe yaz

ŞABLON: [`11-SRE/Postmortem-Practice.md`] referans

ÇIKTI: tam postmortem doc (markdown)
```

→ %70 hazır draft. Author 30 dk review + edit ile final.

---

## 🛠️ Use Case 6: K8s Manifest Generation

### Prompt
```
Aşağıdaki gereksinimden K8s manifest yaz:

Servis: payments-api
Replica: 3
Resources: 500m CPU, 1Gi memory (request); 2 CPU, 2Gi (limit)
Image: ghcr.io/<ORG>/payments-api:1.4.0
Port: 8080
Probe: /healthz (liveness), /ready (readiness)
Secret: DATABASE_URL (mounted from secret "payments-db")

ZORUNLU:
- runAsNonRoot: true, runAsUser: 10001
- readOnlyRootFilesystem: true
- drop ALL capabilities
- securityContext.seccompProfile: RuntimeDefault
- automountServiceAccountToken: false
- PodDisruptionBudget (minAvailable: 2)
- HPA (CPU 70% target, min 3, max 10)

ÇIKTI: deployment.yaml + service.yaml + pdb.yaml + hpa.yaml
```

→ İlk taslak. Manuel review (security policy uyumu).

---

## 🎓 Pattern Kataloğu

### 1. **Chain-of-Thought (CoT)**
```
"Cevaba ulaşmadan önce step-by-step düşün:
 1. Önce X kontrol et
 2. Sonra Y hesapla
 3. Sonra cevabı ver"
```

→ Karmaşık reasoning'de daha doğru.

### 2. **Few-Shot Examples**
```
Örnek 1:
Q: <input>
A: <output>

Örnek 2:
Q: <input>
A: <output>

Sıra sende:
Q: <real input>
A:
```

→ Model formatı + tonu öğrenir.

### 3. **Role Prompting**
```
"Sen bir SOC analyst'sin, 10 yıl deneyimli. ..."
```

→ Domain expertise tonunu yakalar.

### 4. **Output Format**
```
"Cevabı şu JSON şemasında ver:
{
  'summary': string,
  'findings': [{'severity': 'CRIT|WARN|INFO', 'detail': string}],
  'next_actions': [string]
}"
```

→ Parse edilebilir, downstream automation.

### 5. **Constraint Definition**
```
"KURALLAR:
- Sadece kontekst'teki bilgiyi kullan
- Bilgi yoksa 'Bu konuda emin değilim' de
- Türkçe yaz
- Komut çalıştırma önerme; sadece açıklama"
```

→ Hallucination + kapsam kayması önleme.

### 6. **Step-back prompting**
```
"Önce bu sorunun kavramsal arka planını açıkla.
 Sonra spesifik soruya cevap ver."
```

→ Daha derin cevap.

---

## 🛡️ Production'da Prompt Engineering

### Versioning
```python
# prompts/log_analysis_v3.txt
PROMPT_VERSIONS = {
    "log_analysis": {
        "v1": "...",
        "v2": "...",
        "v3": "Sen bir SRE asistanısın..."
    }
}
```

→ A/B test, regression detection, rollback.

### Eval set
```python
# Her prompt için test case'ler
test_cases = [
    {
        "input": "<sample log>",
        "expected_pattern": "should mention 'connection pool'",
        "must_not": "should not hallucinate version numbers"
    }
]

for case in test_cases:
    response = llm(prompt.format(input=case["input"]))
    assert case["expected_pattern"] in response.lower()
```

### Cost tracking
```python
# Token usage telemetry
metrics.histogram(
    "llm_input_tokens",
    response.usage.input_tokens,
    {"prompt": "log_analysis", "version": "v3"}
)
```

### Cache (semantic)
```python
# Aynı / benzer query → cache hit
cache_key = hash(embed(query))
if cached := redis.get(cache_key):
    return cached

response = llm(prompt)
redis.set(cache_key, response, ex=3600)
```

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tek-cümle prompt | Genel cevap | Spesifik + format + kısıt |
| Output format yok | Parse zor | JSON / markdown şema |
| Few-shot yok karmaşık task'te | Model formatı bilmez | 2-3 örnek |
| "Bilmiyorum" izni yok | Hallucination | Explicit izin |
| Kontekst'siz role | Generic ton | "Sen bir SRE'sin..." |
| Cost / token tracking yok | Bütçe sürpriz | Per-prompt telemetry |
| Prompt Git'te değil | Versioning yok | Code review + diff |
| LLM output direkt prod | Hallucination prod'a | Human-in-the-loop / validation |
| Cache yok | Tekrar query'ler pahalı | Semantic cache |
| TR için EN-only model | Kalite düşer | Multilingual / Türkçe destekleyen |
| Prompt'ta PII var | Veri sızıntısı | Pre-process (mask) |

---

## 📋 Prompt Engineering Checklist

```
[ ] Prompt'lar Git'te (versioned)
[ ] Code review ile prompt değişikliği
[ ] Eval set per-prompt
[ ] A/B test infrastructure (v1 vs v2)
[ ] Output format tanımlı (JSON / markdown)
[ ] "Bilmiyorum" / fail-safe izni
[ ] Few-shot örnekler (karmaşık task'te)
[ ] Constraint section (kurallar)
[ ] Token usage telemetry
[ ] Cost dashboard (per-prompt)
[ ] Latency monitoring
[ ] Semantic cache
[ ] PII pre-processing
[ ] Human-in-the-loop critical task'lerde
[ ] Hallucination rate ölçümü
[ ] Prompt'lara linked dokumandasyon (RFC / runbook)
```

---

## 📚 Referanslar

- **Anthropic Prompt Engineering Docs** — docs.anthropic.com/claude/docs/prompt-engineering
- **OpenAI Cookbook** — cookbook.openai.com
- **Prompt Engineering Guide** — promptingguide.ai
- **Lilian Weng — Prompt Engineering** (blog)
- [`LLM-in-Production.md`](LLM-in-Production.md)
- [`RAG-Architecture.md`](RAG-Architecture.md)
- _`Safety-and-Guardrails.md`_ *(yakında)*
- [`19-Compliance/EU-AI-Act.md`](../19-Compliance/EU-AI-Act.md)
- [`11-SRE/Runbook-Template.md`](../11-SRE/Runbook-Template.md)
- [`11-SRE/Postmortem-Practice.md`](../11-SRE/Postmortem-Practice.md)

---

> *"İyi prompt = iyi mühendislik. Spesifik + bağlamlı + örnekli +
> kısıtlı prompt = production-ready output. **Vague prompt** =
> **vague hata**."*
