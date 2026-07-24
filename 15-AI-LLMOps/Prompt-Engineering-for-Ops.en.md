---
description: "Practical prompt engineering for DevOps/SRE: concrete prompt patterns for log analysis, runbook generation, incident summary, and postmortem, plus 5 core principles."
tags:
  - AI/LLMOps
  - SRE
  - Incident Response
  - Template
---
# Prompt Engineering for Ops — Practical LLM Use for DevOps

> *"Telling an LLM 'just do this' is like giving a junior half an
> instruction. A specific + example-driven + contextual prompt is
> like briefing a senior. **Prompt quality** is output quality."*

This guide shows practical prompt patterns with concrete examples
for DevOps/SRE's daily work — log analysis, runbook generation,
incident summary, code review, postmortem writing.

---

## 🎯 Prompt Engineering Fundamentals

### Anatomy
```
[Context]    "You are an SRE assistant..."
[Task]       "Inspect this log..."
[Format]     "Output should be in JSON..."
[Examples]   (few-shot, optional)
[Input]      "<actual log here>"
```

### 5 principles
1. **Be specific** — not "analyze the log," but "find 5xx patterns"
2. **Define the format** — JSON / markdown / table?
3. **Give context** — domain, audience, constraints
4. **Provide examples** (few-shot) — for complex tasks
5. **Allow for failure** — let it say "I don't know"

---

## 🛠️ Use Case 1: Log Analysis

### Naive prompt (bad)
```
"Analyze this log: <LOG>"
```

→ Generic summary, not actionable.

### Good prompt
```
You are an SRE assistant. Inspect the following Postgres log:

1. Find anomaly / error patterns (ERROR, FATAL, slow query > 1s).
2. For each finding:
   - Severity (CRITICAL / WARNING / INFO)
   - Probable root cause
   - Recommended action (command + runbook step)
3. Give the output in JSON format:
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

→ Structured, parseable, with action items.

---

## 🛠️ Use Case 2: Runbook Generation

### Prompt
```
You are an SRE assistant. Write a runbook for the following
Prometheus alert definition:

Alarm: PostgresHighConnections
Expr: pg_stat_activity_count / pg_settings_max_connections > 0.85
Severity: SEV-2

Runbook format:
- TL;DR (summary in 30 seconds)
- 1. Verify (is the alert real)
- 2. Quick Mitigation (5-10 min)
- 3. Investigation (15-30 min)
- 4. Common Causes (table)
- 5. Escalation
- 6. After the fix

Write in English, give concrete commands, follow the [`11-SRE/Runbook-Template.md`] format.
```

→ First draft is 80% correct, becomes prod-ready with manual review.

---

## 🛠️ Use Case 3: Incident Summary (Executive)

### Prompt
```
Write an executive summary for the CTO. Use these details:

INPUT:
- Incident started: 15:30
- Resolved: 15:48
- Affected: ~35% EU traffic
- Service: payment endpoint
- Cause: connection pool dropped 100 → 50 in the last deploy
- Fix: rollback + raise pool to 200

RULES:
- 5 lines, emphasize business impact
- No technical jargon
- Clear recommendation / next step

OUTPUT:
What:
Impact:
Cause:
Fix:
Action:
```

### Result
```
What:    Payment endpoint was down for 18 minutes (15:30-15:48).
Impact:  ~340 customers affected, ~$12K in lost revenue.
Cause:   Last deploy dropped the DB connection pool 100 → 50; the pool was exhausted during a traffic spike.
Fix:     Rolled back, pool raised to 200.
Action:  Postmortem within 5 business days. No budget impact.
```

→ The CEO reads it in 30 seconds.

---

## 🛠️ Use Case 4: Code Review (in a PR)

### Prompt
```
You are a senior backend engineer. Review the following Go PR:

FOCUS AREAS:
1. Concurrency: race condition?
2. Error handling: does the catch actually handle it?
3. Security: input validation, SQL injection?
4. Performance: N+1, hot path allocation?
5. Test: is coverage sufficient?

NOTE:
- Only comment at the blocker / suggestion level.
- Don't suggest "nit" (cosmetic) comments.
- Prefix: "blocker:", "suggestion:", "question:"
- Write in English.

DIFF:
<PR_DIFF>
```

→ Pre-screen for the reviewer. The human reviewer spends the freed-up time on **design**.

---

## 🛠️ Use Case 5: Postmortem Draft

### Prompt
```
Write the **draft** of a blameless postmortem from the following incident timeline:

TIMELINE:
[15:30] Deploy v1.4.2 started
[15:32] Payment endpoint p99 50ms → 8s
[15:35] Alert fired
[15:38] On-call opened an IC
[15:42] Root cause: connection pool config
[15:45] Rollback started
[15:48] Resolved

RULES:
- BLAMELESS: no blaming individuals
- System perspective
- Apply the 5-Whys
- Action items: specific + owned + dated
- Write in English

TEMPLATE: reference [`11-SRE/Postmortem-Practice.md`]

OUTPUT: full postmortem doc (markdown)
```

→ 70% ready draft. Author finalizes it with a 30 min review + edit.

---

## 🛠️ Use Case 6: K8s Manifest Generation

### Prompt
```
Write a K8s manifest from the following requirements:

Service: payments-api
Replica: 3
Resources: 500m CPU, 1Gi memory (request); 2 CPU, 2Gi (limit)
Image: ghcr.io/<ORG>/payments-api:1.4.0
Port: 8080
Probe: /healthz (liveness), /ready (readiness)
Secret: DATABASE_URL (mounted from secret "payments-db")

REQUIRED:
- runAsNonRoot: true, runAsUser: 10001
- readOnlyRootFilesystem: true
- drop ALL capabilities
- securityContext.seccompProfile: RuntimeDefault
- automountServiceAccountToken: false
- PodDisruptionBudget (minAvailable: 2)
- HPA (CPU 70% target, min 3, max 10)

OUTPUT: deployment.yaml + service.yaml + pdb.yaml + hpa.yaml
```

→ First draft. Manual review (security policy compliance).

---

## 🎓 Pattern Catalog

### 1. **Chain-of-Thought (CoT)**
```
"Think step-by-step before you reach the answer:
 1. First check X
 2. Then calculate Y
 3. Then give the answer"
```

→ More accurate for complex reasoning.

### 2. **Few-Shot Examples**
```
Example 1:
Q: <input>
A: <output>

Example 2:
Q: <input>
A: <output>

Your turn:
Q: <real input>
A:
```

→ The model learns the format + tone.

### 3. **Role Prompting**
```
"You are a SOC analyst with 10 years of experience. ..."
```

→ Captures the domain-expertise tone.

### 4. **Output Format**
```
"Give the answer in the following JSON schema:
{
  'summary': string,
  'findings': [{'severity': 'CRIT|WARN|INFO', 'detail': string}],
  'next_actions': [string]
}"
```

→ Parseable, downstream automation.

### 5. **Constraint Definition**
```
"RULES:
- Only use information from the context
- If there's no information, say 'I'm not sure about this'
- Write in English
- Don't suggest running commands; explanation only"
```

→ Prevents hallucination + scope creep.

### 6. **Step-back prompting**
```
"First explain the conceptual background of this question.
 Then answer the specific question."
```

→ A deeper answer.

---

## 🛡️ Prompt Engineering in Production

### Versioning
```python
# prompts/log_analysis_v3.txt
PROMPT_VERSIONS = {
    "log_analysis": {
        "v1": "...",
        "v2": "...",
        "v3": "You are an SRE assistant..."
    }
}
```

→ A/B test, regression detection, rollback.

### Eval set
```python
# Test cases per prompt
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
# Same / similar query → cache hit
cache_key = hash(embed(query))
if cached := redis.get(cache_key):
    return cached

response = llm(prompt)
redis.set(cache_key, response, ex=3600)
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| One-sentence prompt | Generic answer | Specific + format + constraints |
| No output format | Hard to parse | JSON / markdown schema |
| No few-shot for a complex task | Model doesn't know the format | 2-3 examples |
| No permission to say "I don't know" | Hallucination | Explicit permission |
| Role without context | Generic tone | "You are an SRE..." |
| No cost / token tracking | Budget surprise | Per-prompt telemetry |
| Prompt not in Git | No versioning | Code review + diff |
| LLM output goes straight to prod | Hallucination reaches prod | Human-in-the-loop / validation |
| No cache | Repeated queries are expensive | Semantic cache |
| EN-only model for TR | Quality drops | Multilingual / one that supports Turkish |
| PII in the prompt | Data leak | Pre-process (mask) |

---

## 📋 Prompt Engineering Checklist

```
[ ] Prompts are in Git (versioned)
[ ] Prompt changes go through code review
[ ] Eval set per-prompt
[ ] A/B test infrastructure (v1 vs v2)
[ ] Output format defined (JSON / markdown)
[ ] "I don't know" / fail-safe permission
[ ] Few-shot examples (for complex tasks)
[ ] Constraint section (rules)
[ ] Token usage telemetry
[ ] Cost dashboard (per-prompt)
[ ] Latency monitoring
[ ] Semantic cache
[ ] PII pre-processing
[ ] Human-in-the-loop for critical tasks
[ ] Hallucination rate measurement
[ ] Prompts linked to documentation (RFC / runbook)
```

---

## 📚 References

- **Anthropic Prompt Engineering Docs** — docs.anthropic.com/claude/docs/prompt-engineering
- **OpenAI Cookbook** — cookbook.openai.com
- **Prompt Engineering Guide** — promptingguide.ai
- **Lilian Weng — Prompt Engineering** (blog)
- [`LLM-in-Production.md`](LLM-in-Production.md)
- [`RAG-Architecture.md`](RAG-Architecture.md)
- [`Safety-and-Guardrails.md`](Safety-and-Guardrails.md)
- [`19-Compliance/EU-AI-Act.md`](../19-Compliance/EU-AI-Act.md)
- [`11-SRE/Runbook-Template.md`](../11-SRE/Runbook-Template.md)
- [`11-SRE/Postmortem-Practice.md`](../11-SRE/Postmortem-Practice.md)

---

> *"A good prompt is good engineering. A specific + contextual +
> example-driven + constrained prompt = production-ready output.
> **Vague prompt** = **vague error**."*
