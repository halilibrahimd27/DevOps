---
description: "Alert runbook template: step-by-step initial diagnosis commands, possible causes and fixes, rollback procedure, escalation matrix, and incident-closure verification."
tags:
  - Template
  - Incident Response
  - SRE
  - Observability
---
# Runbook: <ALERT_NAME / SCENARIO>

> **Severity:** P1 / P2 / P3
> **Service:** `<service-name>`
> **Owners:** @team-handle (Slack: `#team-channel`)
> **On-call rotation:** [PagerDuty link]
> **Last verified:** YYYY-MM-DD

---

## 🎯 What is this page for?

A **step-by-step** guide to what to do when this alert fires /
this situation occurs. Even someone who isn't a senior DevOps should be able to follow it
and solve 80% of the problem.

## 🚨 What does the alert mean?

`<ALERT_NAME>` fires when:
- Condition: `<e.g. error_rate > 1% within the last 5 min>`
- Threshold: `<specific value>`
- Window: `<5m / 10m / 1h>`

## 🩺 Initial diagnosis (60 seconds)

```bash
# 1. Is the service alive
kubectl get pods -n <NS> -l app=<APP>
kubectl top pods -n <NS> -l app=<APP>

# 2. Pods that restarted in the last 10 min
kubectl get pods -n <NS> -l app=<APP> -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].restartCount}{"\n"}{end}'

# 3. Error logs (last 100 lines)
kubectl logs -n <NS> -l app=<APP> --tail=100 --all-containers | grep -i 'error\|fatal\|panic'

# 4. Metric dashboard
# → [Grafana link to dashboard]
```

## 🔧 Possible causes and fixes

### Cause 1: <Common scenario>

**Symptom:** *(what shows up in logs, metric pattern, etc.)*

**Verification:**
```bash
<specific command>
```

**Fix:**
```bash
<step 1>
<step 2>
```

**Verification (after):**
```bash
<is everything OK?>
```

---

### Cause 2: <Other scenario>

(...similar structure...)

---

### Cause 3: <Worst case — failover needed>

**Symptom:** Multiple pods down, no recovery

**Action:**

1. Run the `/incident sev-1 <APP> down` command in the incident channel
2. Page the manager + service owner
3. Run the rollback procedure below

```bash
# Rollback: go back to the previous revision
kubectl rollout undo deployment/<APP> -n <NS>
kubectl rollout status deployment/<APP> -n <NS>
```

4. If rollback isn't enough: shift traffic to the secondary cluster
   ```bash
   <DNS / Load balancer command>
   ```

## 🆘 Escalation

| Time | Action |
|---|---|
| 0-15 min | On-call IC tries to resolve |
| 15-30 min | Service owner gets paged |
| 30-60 min | Engineering manager + secondary on-call |
| 60+ min | Director + comms (status page update) |

## 📞 Communication channels

- **Internal:** `#incident-<APP>` Slack channel (auto-created)
- **Status page:** [https://status.example.com](https://status.example.com)
- **Customer comms:** Managed by the comms team; `#comms-incident` channel

## 🧠 Past incidents (reference)

- [INC-1234](https://example.com/inc/1234) — 2026-01-15 — DB connection pool exhausted
- [INC-2345](https://example.com/inc/2345) — 2026-02-22 — Memory leak in <COMPONENT>

## 📚 Related resources

- [Service architecture diagram]
- [Capacity planning doc]
- [Recent postmortems]

## ✅ Verification (at incident closure)

- [ ] Error rate back to normal (`<METRIC_LINK>`)
- [ ] p99 latency below target
- [ ] No customer-facing impact
- [ ] Postmortem ticket opened: [link]
- [ ] Incident channel closed

---

> 📝 If something is missing in this runbook — open a PR **right now**. Runbooks
> where people say "I'll fix it later" recreate the same problem at the next incident.
