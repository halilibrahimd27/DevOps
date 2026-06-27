---
description: "LLM'in DevOps akisindaki pratik kullanimlari: log analiz, runbook, postmortem, alarm triage; agent pattern'leri, use case matrisi ve otomasyon-insan dengesi."
---
# AI-Augmented Operations — LLM ile DevOps İşi

> *"LLM'i 'chatbot' sanmak 2024'tü. 2026'da LLM, **DevOps mühendisinin
> co-pilot**'u: log analiz, runbook generation, postmortem draft, alarm
> triage. **'AI replaces SRE'** değil, **'AI accelerates SRE'**."*

Bu rehber LLM'in DevOps gündelik akışında pratik kullanım alanlarını,
agent pattern'lerini, ve "ne otomatize edilmeli, ne insanda kalmalı"
sorusuna cevap verir.

---

## 🎯 Use Case Matrisi

| Use case | Otomasyon seviyesi | Risk |
|---|---|---|
| **Log analiz / pattern detect** | Tam otomatik | Düşük |
| **Runbook generation** (taslak) | Human-in-the-loop | Düşük |
| **Postmortem draft** | Human review | Düşük |
| **Alarm triage** (severity, owner) | Tam otomatik | Düşük |
| **Code review (advisory)** | Pre-screen, human onay | Düşük |
| **Incident summary (executive)** | Tam otomatik | Düşük |
| **K8s manifest gen** | Human review | Orta |
| **Auto-remediation** | Onay gate'li | Yüksek |
| **Production query** | Read-only OK, write **insanda** | Yüksek |
| **Direct production deploy** | **Yapma** | Çok yüksek |

> 🔑 **Kural**: LLM action **destructive** ise human-in-the-loop. Read-only / advisory için tam otomatik.

---

## 🛠️ 1. Log Analiz (Otomatik)

### Pattern detection
```python
async def analyze_logs(log_text: str) -> dict:
    response = await anthropic.messages.create(
        model="claude-opus-4-7",
        system=LOG_ANALYZER_PROMPT,
        messages=[{"role": "user", "content": log_text}],
        max_tokens=1024
    )
    return json.loads(response.content[0].text)
```

```
LOG_ANALYZER_PROMPT:
Sen bir SRE asistanısın. Verilen log'da:
1. Anomali / hata pattern'lerini bul
2. Severity belirle
3. Olası kök neden öner
4. Önerilen runbook adımı

JSON çıktısı ver.
```

### Pipeline integration
```yaml
# Falco alert → Lambda → LLM → enriched alert
SourceLog → LLM analyze → {
  severity: "high",
  root_cause_hypothesis: "DB connection pool exhaustion",
  recommended_action: "Pool size increase or restart"
} → Slack alert (enriched)
```

---

## 🛠️ 2. Runbook Generation

```python
def generate_runbook(alert_definition: str) -> str:
    return llm.complete(f"""
    Aşağıdaki Prometheus alert için runbook yaz:
    {alert_definition}
    
    Format:
    - TL;DR
    - 1. Verify
    - 2. Quick Mitigation (5-10 dk)
    - 3. Investigation
    - 4. Common Causes (tablo)
    - 5. Escalation
    - 6. After fix
    """)
```

> 🔑 LLM **draft** üretir, mühendis **review + production'a uygula**.

---

## 🛠️ 3. Alarm Triage Bot

```python
async def triage_alert(alert: dict) -> dict:
    response = await llm.complete(f"""
    Alert details: {alert}
    Recent metrics (Prometheus): {fetch_metrics(alert)}
    Recent traces (Tempo): {fetch_traces(alert)}
    Recent logs (Loki): {fetch_logs(alert)}
    
    Belirle:
    1. Severity (page/warn/info)
    2. Owner team
    3. Likely cause (3 hypothesis)
    4. Recommended runbook URL
    """)
    return parse(response)

# Alertmanager webhook → triage → enriched route
```

→ "Generic alarm" → "spesifik enriched alarm + recommended action".

---

## 🛠️ 4. Postmortem Draft

```python
def draft_postmortem(timeline: list, metrics: dict) -> str:
    return llm.complete(f"""
    Timeline: {timeline}
    Metrics during incident: {metrics}
    
    Blameless postmortem yaz:
    - Executive summary (3 cümle)
    - Impact (customer + revenue)
    - Timeline (UTC)
    - Root cause (5-Whys)
    - What went well
    - What went wrong
    - Where we got lucky
    - Action items (owner + due date placeholder)
    """)
```

→ %70 hazır draft → mühendis 30 dk review + edit → final.

---

## 🤖 Agent Patterns

### Read-only Agent (auto-OK)
```
[Prometheus alert] → [LLM Agent: Loki query, Tempo trace, Grafana check]
                          ↓
                  [Slack: enriched alert + suggested action]
```

### Action Agent (human-in-the-loop)
```
[Issue] → [Agent proposes action]
              ↓
        [Slack: "Restart pod X? [Approve / Deny]"]
              ↓ Approve
        [kubectl rollout restart deploy/X]
```

### Auto-Remediation Agent (high-confidence)
```
[Specific known issue: HighDiskUsage]
        ↓
[Agent: cat /etc/logrotate.conf check + execute]
        ↓ (confidence > 0.95)
[logrotate -f]
        ↓
[Slack: "Auto-remediated, free disk: 80%"]
```

> ⚠️ Auto-remediation **whitelist'li** action'lar için. Bilinmeyen issue → human.

---

## 🛡️ Production Concerns

### 1. Hallucination
- LLM "bilmiyorum" demesin → confidence flag
- Citation zorunlu (RAG)
- Bkz [`Safety-and-Guardrails.md`](Safety-and-Guardrails.md)

### 2. Cost
- Cache (semantic) — yaygın query'leri tut
- Token limit per request
- Selective: sadece SEV1+ için detailed analysis

### 3. PII
- Log'da PII varsa → mask + hash
- Audit log: agent ne yaptı, hangi data gördü

### 4. Latency
- LLM 1-5 saniye
- Critical path'ten uzak (alarm enrichment async OK)

### 5. Audit trail
```python
audit_log.write({
    "agent": "alarm-triage",
    "alert_id": alert.id,
    "input_hash": hash(alert),
    "llm_model": "claude-opus-4-7",
    "decision": triage_result,
    "action_taken": action,
    "human_approved": approval_id
})
```

---

## 🚧 Vendor Stack — 2026

| Tool | Niche |
|---|---|
| **Anthropic Claude** | Best for complex reasoning |
| **OpenAI GPT-4/5** | Geniş ekosistem |
| **Google Gemini** | Multi-modal, context window |
| **Self-hosted Llama** | Privacy + cost (büyük org için) |
| **LangChain / LangGraph** | Agent framework |
| **AutoGen** (MS) | Multi-agent orchestration |
| **CrewAI** | Role-based agents |

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| LLM ile direct production action | Hallucination + destructive | Human-in-the-loop |
| LLM "her şey için" | Cost + latency | Spesifik use case |
| Hallucination kontrolü yok | Fake report | Citation + confidence |
| PII filter yok | Compliance ihlal | Mask + hash |
| Cost monitoring yok | Bütçe sürpriz | Token + cost dashboard |
| Audit log yok | EU AI Act ihlal | Per-call audit |
| Prompt versioning yok | Regression görünmez | Git'te + eval |
| Tool allowlist yok | Agent her şey | Whitelist |
| Test set yok | "Çalışıyor sanırım" | Eval set + metrics |
| LLM cache yok | Tekrarlanan tahminler | Semantic cache |

---

## 📋 AI-Augmented Ops Checklist

```
[ ] Use case prioritization (read-only önce)
[ ] LLM provider seçimi (Claude / GPT / Gemini)
[ ] Prompt'lar Git'te versioned
[ ] PII filter (input + output)
[ ] Citation / confidence (hallucination control)
[ ] Audit log (her LLM call)
[ ] Token + cost dashboard
[ ] Semantic cache (frequent queries)
[ ] Action allowlist (destructive ops için)
[ ] Human-in-the-loop critical action'larda
[ ] Eval set (regression testing)
[ ] Quarterly: agent effectiveness review
[ ] EU AI Act compliance (yüksek-risk değilse normal)
[ ] Onboarding: dev'lere agent kullanım kuralları
```

---

## 📚 Referanslar

- **Anthropic Claude API** — docs.anthropic.com
- **LangChain** — python.langchain.com
- **AutoGen** — microsoft.github.io/autogen
- **CrewAI** — crewai.com
- **OpenTelemetry GenAI Semantic Conventions** — opentelemetry.io
- [`LLM-in-Production.md`](LLM-in-Production.md)
- [`RAG-Architecture.md`](RAG-Architecture.md)
- [`Prompt-Engineering-for-Ops.md`](Prompt-Engineering-for-Ops.md)
- [`Safety-and-Guardrails.md`](Safety-and-Guardrails.md)
- [`Self-Hosted-LLM.md`](Self-Hosted-LLM.md)
- [`Model-Cost-Optimization.md`](Model-Cost-Optimization.md)
- [`19-Compliance/EU-AI-Act.md`](../19-Compliance/EU-AI-Act.md)

---

> *"AI Augmented Ops 'SRE'i replace etmek' değil — **SRE'in
> productivity'sini katlamak**. Log triage 30 dk → 3 dk; postmortem
> draft 4 saat → 30 dk. Mühendis **mantık + onay**'a odaklanır."*
