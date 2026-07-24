---
description: "Practical uses of the LLM in the DevOps workflow: log analysis, runbook, postmortem, alarm triage; agent patterns, use-case matrix, and the automation-human balance."
tags:
  - AI/LLMOps
  - SRE
  - Incident Response
  - Observability
  - Security
---
# AI-Augmented Operations — DevOps Work with an LLM

> *"Treating the LLM as a 'chatbot' was 2024. By 2026 it's the DevOps
> engineer's **co-pilot**: log analysis, runbook generation, postmortem
> draft, alarm triage. Not **'AI replaces SRE'** — **'AI accelerates SRE'**."*

This guide covers the LLM's practical use cases in the daily DevOps
workflow, agent patterns, and answers the question of "what should be
automated, what should stay with a human."

---

## 🎯 Use Case Matrix

| Use case | Automation level | Risk |
|---|---|---|
| **Log analysis / pattern detect** | Fully automatic | Low |
| **Runbook generation** (draft) | Human-in-the-loop | Low |
| **Postmortem draft** | Human review | Low |
| **Alarm triage** (severity, owner) | Fully automatic | Low |
| **Code review (advisory)** | Pre-screen, human approval | Low |
| **Incident summary (executive)** | Fully automatic | Low |
| **K8s manifest gen** | Human review | Medium |
| **Auto-remediation** | Approval-gated | High |
| **Production query** | Read-only OK, write stays **with a human** | High |
| **Direct production deploy** | **Don't** | Very high |

> 🔑 **Rule**: if the LLM action is **destructive**, human-in-the-loop. Fully automatic for read-only / advisory.

---

## 🛠️ 1. Log Analysis (Automatic)

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
You are an SRE assistant. In the given log:
1. Find anomaly / error patterns
2. Determine severity
3. Suggest a probable root cause
4. Recommended runbook step

Return JSON output.
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
    Write a runbook for the following Prometheus alert:
    {alert_definition}
    
    Format:
    - TL;DR
    - 1. Verify
    - 2. Quick Mitigation (5-10 min)
    - 3. Investigation
    - 4. Common Causes (table)
    - 5. Escalation
    - 6. After fix
    """)
```

> 🔑 The LLM produces a **draft**, the engineer **reviews + applies it to production**.

---

## 🛠️ 3. Alarm Triage Bot

```python
async def triage_alert(alert: dict) -> dict:
    response = await llm.complete(f"""
    Alert details: {alert}
    Recent metrics (Prometheus): {fetch_metrics(alert)}
    Recent traces (Tempo): {fetch_traces(alert)}
    Recent logs (Loki): {fetch_logs(alert)}
    
    Determine:
    1. Severity (page/warn/info)
    2. Owner team
    3. Likely cause (3 hypothesis)
    4. Recommended runbook URL
    """)
    return parse(response)

# Alertmanager webhook → triage → enriched route
```

→ "Generic alarm" → "specific enriched alarm + recommended action".

---

## 🛠️ 4. Postmortem Draft

```python
def draft_postmortem(timeline: list, metrics: dict) -> str:
    return llm.complete(f"""
    Timeline: {timeline}
    Metrics during incident: {metrics}
    
    Write a blameless postmortem:
    - Executive summary (3 sentences)
    - Impact (customer + revenue)
    - Timeline (UTC)
    - Root cause (5-Whys)
    - What went well
    - What went wrong
    - Where we got lucky
    - Action items (owner + due date placeholder)
    """)
```

→ 70% ready draft → engineer does a 30 min review + edit → final.

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

> ⚠️ Auto-remediation is for **whitelisted** actions only. Unknown issue → human.

---

## 🛡️ Production Concerns

### 1. Hallucination
- Don't let the LLM avoid saying "I don't know" → confidence flag
- Citation is mandatory (RAG)
- See [`Safety-and-Guardrails.md`](Safety-and-Guardrails.md)

### 2. Cost
- Cache (semantic) — keep frequent queries
- Token limit per request
- Selective: detailed analysis only for SEV1+

### 3. PII
- If the log contains PII → mask + hash
- Audit log: what the agent did, what data it saw

### 4. Latency
- LLM takes 1-5 seconds
- Keep it off the critical path (alarm enrichment can be async)

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
| **OpenAI GPT-4/5** | Broad ecosystem |
| **Google Gemini** | Multi-modal, context window |
| **Self-hosted Llama** | Privacy + cost (for large orgs) |
| **LangChain / LangGraph** | Agent framework |
| **AutoGen** (MS) | Multi-agent orchestration |
| **CrewAI** | Role-based agents |

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| LLM with direct production action | Hallucination + destructive | Human-in-the-loop |
| LLM "for everything" | Cost + latency | Specific use case |
| No hallucination check | Fake report | Citation + confidence |
| No PII filter | Compliance violation | Mask + hash |
| No cost monitoring | Budget surprise | Token + cost dashboard |
| No audit log | EU AI Act violation | Per-call audit |
| No prompt versioning | Regression invisible | In Git + eval |
| No tool allowlist | Agent can do anything | Whitelist |
| No test set | "I think it works" | Eval set + metrics |
| No LLM cache | Repeated inferences | Semantic cache |

---

## 📋 AI-Augmented Ops Checklist

```
[ ] Use case prioritization (read-only first)
[ ] LLM provider selection (Claude / GPT / Gemini)
[ ] Prompts versioned in Git
[ ] PII filter (input + output)
[ ] Citation / confidence (hallucination control)
[ ] Audit log (every LLM call)
[ ] Token + cost dashboard
[ ] Semantic cache (frequent queries)
[ ] Action allowlist (for destructive ops)
[ ] Human-in-the-loop for critical actions
[ ] Eval set (regression testing)
[ ] Quarterly: agent effectiveness review
[ ] EU AI Act compliance (normal if not high-risk)
[ ] Onboarding: agent usage rules for devs
```

---

## 📚 References

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

> *"AI Augmented Ops isn't about 'replacing the SRE' — it's about
> **multiplying the SRE's productivity**. Log triage goes 30 min → 3 min;
> postmortem draft 4 hours → 30 min. The engineer focuses on **logic + approval**."*
