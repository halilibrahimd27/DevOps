---
description: "A practical guide to the Google SRE Book's toil concept, how to measure it, the 50% rule, and concrete techniques for reducing toil."
tags:
  - SRE
  - Culture
  - Performance
  - Field Notes
---
# Toil Reduction — When "50% of the Team Is on Toil"

> *"Toil = manual + repetitive + non-value work. If more than 50% of an
> SRE team's time goes to toil, the **team isn't growing — it's
> burning out**. Toil can't be reduced until it's measured."*

This guide explains the Google SRE Book's **toil** concept, how to measure
it, the 50% rule, and concrete techniques for reducing it.

---

## 🎯 What Is Toil?

> **Toil**: work with 4 characteristics:
> 1. **Manual** (can be automated)
> 2. **Repetitive**
> 3. **Reactive / interrupt-driven**
> 4. **Scales linearly with service growth** (if not automated)
> 5. **Creates no engineering value**

### Examples that are not toil
- Writing a new feature → engineering work
- Writing a postmortem → learning
- Mentoring → leverage
- Architectural decision → strategic

### Examples of toil
- SSHing into a node with a full disk to clean logs
- Rotating a DB user password by hand
- Answering "can you deploy my service to prod?" tickets
- Acking the same alarm every morning
- Manually applying the ticket for a DNS change
- Annual SSL cert renewal (without cert-manager)

---

## 📊 Measuring Toil

### Self-tracking
Each team member, weekly:
```
Monday: 4 hours — Vault rotation, manual
Tuesday: 2 hours — Pod restart tickets (3 of them)
Wednesday: 3 hours — PR review + apply for DNS update
Thursday: 6 hours — New feature build
Friday: 4 hours — Incident response
```

→ Toil: 9 hours / 40 per week = **22.5%**.

### Automatic (PagerDuty / ticket data)
```promql
# Quarterly toil ratio
toil_hours_per_week / total_engineering_hours_per_week
```

### Target: < 50%
> Google SRE Book: "If an SRE team is doing 50%+ toil, the team size
> should be increased or **toil automation** made a priority."

---

## 🚦 Toil Classification

| Category | Example | Automation difficulty |
|---|---|---|
| **Cluster ops** | Node drain, scale up | Low (HPA, Karpenter) |
| **Access** | New dev cluster access | Low (OIDC + RBAC) |
| **Deploy** | "Ship the PR to prod" | Low (ArgoCD self-sync) |
| **Cert / secret rotation** | TLS, DB password | Medium (cert-manager, Vault rotation) |
| **Monitoring response** | Alarm ack + restart | Medium (auto-remediation) |
| **Migration / upgrade** | K8s version bump | High (testing + planning) |
| **Compliance / audit** | Annual SOC2 evidence | High (audit log automation) |

---

## 🛠️ Toil Automation Patterns

### 1. Self-service (the most powerful)
**Old**: Dev → DevOps ticket → "new S3 bucket"
**New**: Dev → Backstage scaffolder → automatic

```yaml
# Backstage scaffolder action
- id: create-s3-bucket
  action: terraform:apply
  input:
    module: ./modules/s3
    vars:
      bucket_name: ${{ parameters.bucketName }}
      env: ${{ parameters.env }}
```

### 2. Auto-remediation
**Old**: Alarm fires → SSH → restart
**New**: Alarm → webhook → automatic action

```yaml
# Argo Events: pod CrashLoopBackOff → automatic delete
spec:
  triggers:
    - template:
        name: delete-crashing-pod
        k8s:
          operation: delete
          source:
            resource: '{{ .body.pod }}'
```

### 3. ChatOps
**Old**: "@ops apply this to prod"
**New**: Slack `/deploy <service> <env>` → bot runs it

### 4. Operator pattern
**Old**: Postgres maintenance by hand every week
**New**: CloudNativePG operator → declarative

### 5. GitOps
**Old**: `kubectl apply` every time
**New**: PR merge → ArgoCD sync

---

## 🎯 Toil Reduction Projects

### Quarterly: pick the top 3 toils + turn them into a project

```
Quarterly Toil Review

Tracked toil (Q3 average):
  1. Manual cluster upgrade: 16 hours/week
  2. Cert renewal: 8 hours/week
  3. Access provisioning: 6 hours/week
  4. Random pod restart: 5 hours/week
  5. Other: 12 hours/week

Q4 Action Items:
  - P0: cert-manager universal adoption (saving: 8h/week)
  - P1: K8s rolling upgrade automation (saving: 12h/week)
  - P2: OIDC+RBAC provisioning self-service (saving: 5h/week)

Expected saving: 25 hours/week = the work of 1 extra engineer
```

### Action item formula
```
Saving (hours/week)
÷
Automation cost (hours)
=
ROI (weeks)
```

> E.g.: 8h/week toil + 80h automation = break-even in 10 weeks. Net gain after that.

---

## 🚧 Toil Reduction Anti-Patterns

### The "all toil can be automated" claim
- Some toil is **inherently manual** (a human has to make the call)
- "Writing a postmortem is toil" — no, it's **high leverage**
- Zero toil everywhere = an impossible target

### Automation = extra toil
- Automation itself needs maintenance too
- "Automated it, forgot it" → bug 6 months later
- Evaluate net toil

### Toil tracking interrupt
- The "keeping a toil log is itself toil" complaint
- Fix: aggregate PagerDuty + ticket data automatically

---

## 📊 Healthy Team Toil Distribution (from the Google SRE sample)

```
Toil               25-50%
Engineering work   50%+
Overhead           0-15%
On-call            0-25% (depending on rotation)
```

> 🔑 Toil **can't be zero** but it **shouldn't be dominant**.

---

## 🔄 Toil Migration Flow

### Phased reduction
```
1. Tier 1 (easy automation): self-service form, runbook auto-action
2. Tier 2 (medium): operator pattern, GitOps
3. Tier 3 (hard): policy-as-code, ML-based prediction
```

### The "run book → action book" transition
- Runbook step: "kubectl rollout restart"
- Action book: "alert → webhook → automatic kubectl"

```python
# Auto-remediation server (simple)
@app.post("/auto-action")
async def handle_alert(alert: dict):
    if alert["alertname"] == "HighDiskUsage":
        node = alert["labels"]["node"]
        await k8s.exec(node, "logrotate -f /etc/logrotate.conf")
        await notify_slack(f"Auto-rotated logs on {node}")
```

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Toil isn't measured | You can't reduce what you don't know | Quarterly self-track |
| Thinking 80% toil is normal | Burnout guaranteed | < 50% target |
| "We've always done it this way" | Automation is ignored | Quarterly toil review |
| Automation maintenance neglected | Automation becomes toil itself | Ownership + monitoring |
| One engineer owns all the toil | Burnout | Rotation + sharing |
| Self-service exists, devs don't use it | Low adoption | Marketing + onboarding |
| Auto-remediation aggressive on day one | A false positive takes prod down | Phased |
| A manual runbook run daily | An automation candidate | Cron / operator |
| Toil invisible in postmortems | The pattern goes undiscovered | Ask "why is this step manual?" |
| No "reduce toil" in the OKRs | Not measured, not prioritized | Quarterly goal: -X% toil |

---

## 📋 Toil Reduction Checklist

```
[ ] Toil measurement mechanism (self-track / PagerDuty)
[ ] Quarterly toil review meeting
[ ] Top 5 toil list (hourly impact)
[ ] Toil reduction goal in the OKRs
[ ] Self-service (Backstage scaffolder, IDP)
[ ] Auto-remediation (Argo Events, custom)
[ ] ChatOps (Slack /command)
[ ] Operator pattern (Postgres, RabbitMQ, etc.)
[ ] GitOps (no manual kubectl)
[ ] cert-manager universal
[ ] Vault rotation automatic
[ ] Automation ownership: who maintains it?
[ ] ROI calculation (hours saved / hours invested)
[ ] Annual: toil distribution report (for managers)
[ ] Burnout signal: toil > 50% → escalate
```

---

## 📚 References

- **Google SRE Book** — Chapter 5: Eliminating Toil
- **The Practice of System and Network Administration** — Limoncelli et al.
- **Argo Events** — argoproj.github.io/argo-events
- [`Incident-Response.md`](Incident-Response.md)
- [`Runbook-Template.md`](Runbook-Template.md) — auto-remediation
- [`SLI-SLO-Error-Budget.md`](SLI-SLO-Error-Budget.md)
- [`13-Platform-Engineering/Internal-Developer-Platform.md`](../13-Platform-Engineering/Internal-Developer-Platform.md) — self-service
- [`20-Soft-Skills/Oncall-Sustainability.md`](../20-Soft-Skills/Oncall-Sustainability.md)

---

> *"Toil isn't 'bad' — it's bad when it's **invisible**. Measured toil
> can be turned into a project; unmeasured toil **quietly wears the
> team down**."*
