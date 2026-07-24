---
description: "A guide explaining what a runbook is, and why and how it's written, for responding to alerts in production; template, example, and anti-patterns."
tags:
  - SRE
  - Incident Response
  - Template
  - Field Notes
---
# Runbook — What to Do When an Alert Fires

> *"03:14 at night, the phone rings. Your brain is at 30% capacity.
> With no runbook, **a maze in front of your eyes**. With a runbook,
> **you follow the steps**."*

This guide explains what a **runbook** is — and why and how it's
written — for responding to alerts in production. Template + example + anti-pattern.

---

## 🎯 What Is a Runbook?

> **Runbook**: A **step-by-step** "check, try, escalate" guide for a
> specific alert/condition. Written for the **tired engineer**, not
> for the expert.

```
Alert: PostgresHighConnections
   │
   ▼
[Runbook link]
   │
   ▼
1. Dashboard link → check connection count
2. Which app is opening conns? Top 5 query
3. Pool exhaustion or a leak?
4. Mitigation: pool_size up / app restart / kill query
5. Escalate: @postgres-team
6. Postmortem: has this pattern recurred?
```

---

## 📐 Template — The Anatomy of a Runbook

```markdown
# Runbook: <ALERT_NAME>

**Severity:** SEV-1 / SEV-2 / SEV-3  
**Owner team:** @<TEAM>  
**Service:** <SERVICE>  
**Last updated:** YYYY-MM-DD  
**Related runbooks:** [list]

## TL;DR (30 seconds)
<One paragraph: what, how urgent, first action.>

## 1. Verify the alert
<False alarm? Verification steps.>
- Dashboard: <URL>
- Query: ```promql
  ...
  ```

## 2. Quick Mitigation (5-10 minutes)
<Do immediately — stop the bleeding. Not root cause.>
- [ ] Step 1: ...
- [ ] Step 2: ...

## 3. Investigation (15-30 minutes)
<Root-cause-finding steps.>
- [ ] Log: <log query>
- [ ] Trace: <trace query>
- [ ] Metric trend: <dashboard>

## 4. Common Causes
| Cause | Symptom | Fix |
|---|---|---|

## 5. Escalation
- Longer than 30 minutes → @<ON_CALL_LEAD>
- Longer than 1 hour → @<MANAGER>
- If there's customer impact → IC (incident commander)

## 6. Related links
- Dashboard: ...
- Architecture diagram: ...
- Postmortems with this pattern: ...
- Service runbook: ...

## 7. After the fix
- [ ] Postmortem? (SEV-1/2 yes)
- [ ] Update this runbook (if a gap surfaced)
- [ ] Permanent fix ticket: #...
```

---

## 📝 Example 1: PostgresHighConnections

```markdown
# Runbook: PostgresHighConnections

**Severity:** SEV-2  
**Owner team:** @platform  
**Service:** postgres-prod  
**Last updated:** 2026-04-15  

## TL;DR
Postgres connection count 85%+. The PgBouncer pool may be exhausted or
there may be an app leak. Mitigate within 30 min; if it runs longer than 1 hour, IC.

## 1. Verify the alert
- Dashboard: https://grafana.<DOMAIN>/d/pg-prod
- Query:
  ```promql
  pg_stat_activity_count / pg_settings_max_connections
  ```
  > 0.85 → alert; > 0.95 → SEV-1

## 2. Quick Mitigation (5 min)
- [ ] See the top connection openers:
  ```sql
  SELECT application_name, state, COUNT(*)
  FROM pg_stat_activity
  GROUP BY 1, 2
  ORDER BY 3 DESC
  LIMIT 10;
  ```
- [ ] If there's a lot of `idle in transaction` → these are leaks, kill them:
  ```sql
  SELECT pg_terminate_backend(pid)
  FROM pg_stat_activity
  WHERE state = 'idle in transaction'
    AND state_change < now() - interval '5 minutes';
  ```
- [ ] PgBouncer restart (last resort):
  ```bash
  kubectl rollout restart deploy/pgbouncer -n postgres
  ```

## 3. Investigation
- Which app opened conns? Filter by `application_name`, find the owner team.
- App-side connection pool config: hot reload or hardcoded?
- Any recent deploy? → was the conn pool config changed?

## 4. Common Causes
| Cause | Symptom | Fix |
|---|---|---|
| App pool size wrong | A single app 50%+ conns | App config patch + redeploy |
| `idle in transaction` leak | Conns in an old state | App-side: missing tx commit/rollback |
| PgBouncer pool exhaustion | client_active < 5%, db_used 100% | Increase `default_pool_size` |
| Attack / DDoS | Conns from external IPs | WAF rule + IP block |

## 5. Escalation
- 30 min → @postgres-team Slack
- 1 hour → open an IC + check customer impact
- Suspected data breach → Security team + KVKK 72h timer

## 6. Related links
- Dashboard: ...
- Architecture: ...
- Postmortems: INC-2026-02-08, INC-2026-04-12
- Service runbook: postgres-service.md

## 7. After the fix
- [ ] Postmortem per the SEV-2 rule
- [ ] Pool sizing review (if an app-side fix is needed)
- [ ] Update this runbook — if a new cause surfaced
```

---

## 📝 Example 2: PodOOMKilled

```markdown
# Runbook: PodOOMKilled

**Severity:** SEV-3 (single pod) / SEV-2 (multi-pod)

## TL;DR
Pod OOMKilled (exceeded the memory limit). Memory leak or insufficient limit.

## 1. Verify
- ```bash
  kubectl get events -n <NS> | grep OOMKilled
  kubectl describe pod <POD> -n <NS> | grep -A 5 "Last State"
  ```
- Grafana: container_memory_usage trend

## 2. Quick Mitigation
- [ ] Increase the memory limit (temporary):
  ```bash
  kubectl set resources deployment/<APP> -n <NS> \
    --limits=memory=2Gi
  ```
- [ ] Increase replicas (load split):
  ```bash
  kubectl scale deployment/<APP> -n <NS> --replicas=5
  ```

## 3. Investigation
- Memory leak? → is the trend rising over time?
- Spike? → was it triggered by a deploy?
- Take a heap dump (Java/Go pprof):
  ```bash
  kubectl exec <POD> -- jmap -dump:format=b,file=/tmp/heap.hprof <PID>
  kubectl cp <POD>:/tmp/heap.hprof ./heap.hprof
  ```

## 4. Common Causes
| Cause | Symptom | Fix |
|---|---|---|
| Memory leak | Trend rises over time | Code fix |
| Cache size wrong | Spike at certain traffic | Cache tune |
| GC pressure | CPU high + memory rising | GC tuning or rewrite |
| Limit insufficient | Traffic higher than expected | Increase limit + HPA |
```

---

## 🔗 Wire the Runbook to the Alert

### Prometheus alert
```yaml
groups:
  - name: postgres
    rules:
      - alert: PostgresHighConnections
        expr: pg_stat_activity_count / pg_settings_max_connections > 0.85
        for: 5m
        labels:
          severity: page
          team: platform
        annotations:
          summary: "Postgres conn 85%+: {{ $value | humanizePercentage }}"
          runbook_url: "https://runbooks.<DOMAIN>/postgres-high-connections"
          dashboard_url: "https://grafana.<DOMAIN>/d/pg-prod"
```

`runbook_url` appears in the PagerDuty alert payload → the engineer opens it with one click.

---

## 🛠️ Where Should You Keep the Runbook?

| Location | Pro | Con |
|---|---|---|
| **Repo (Git)** | Versioned, PR review | An extra click to reach it from Slack |
| **Backstage TechDocs** | Searchable, embed | Setup |
| **Confluence / Notion** | Widespread | No sync with code, goes stale |
| **Repo + alert annotation** | ✅ Ideal combination | — |

> 🔑 **Recommended**: Markdown in the repo + a link from the alert. Updates go
> through PR review. Review every 6 months.

---

## 📊 Runbook Maturity Model

| Level | State |
|---|---|
| **L0** | No runbook at all, "whatever @oncall does is what's done" |
| **L1** | A Confluence page for some critical services, stale |
| **L2** | A runbook for every SEV-1 alert, in the repo |
| **L3** | Every alert (SEV-1 through SEV-3) has a runbook, linked via alert annotation |
| **L4** | Auto-remediation: some runbook steps automated in code |

> 🎯 **2026 target:** L3. New alert — **no PR is merged without a runbook**.

---

## 🤖 Auto-Remediation (L4)

Runbook steps can be automated:

```yaml
# Argo Events / Kubernetes operator
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: pod-restart-on-oom
spec:
  triggers:
    - template:
        name: restart-deployment
        k8s:
          operation: patch
          source:
            resource:
              apiVersion: apps/v1
              kind: Deployment
              metadata:
                name: "{{ .body.deployment }}"
                namespace: "{{ .body.namespace }}"
              spec:
                template:
                  metadata:
                    annotations:
                      kubectl.kubernetes.io/restartedAt: "{{ time }}"
```

Or a Python webhook responder (from alarms like Falco):
```python
async def auto_remediate(alert):
    if alert.name == "DiskUsageHigh" and alert.severity == "WARN":
        # Auto-cleanup old logs
        await k8s.exec_pod(alert.pod, "logrotate -f /etc/logrotate.conf")
        notify_slack(f"Auto-cleaned logs on {alert.pod}")
    elif alert.name == "PodCrashLoop" and alert.crash_count > 5:
        # Auto-rollback
        await argocd.rollback(alert.app, "previous")
```

> 🔑 **Auto-remediation is phased:** first alert, then a "soft action" (label),
> then aggressive (restart). Don't let a false positive take prod down.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| No runbook, relying on "expertise" | Bus factor 1 | A written runbook for every alert |
| Runbook 6 months old | Steps have changed, doesn't work | Quarterly review, drill |
| Runbook too generic ("check the logs") | What should a tired engineer look for? | Specific query + dashboard URL |
| Runbook 50 pages | No one reads it at night | Short, stepwise, dotted with links |
| Runbook in Confluence, not on the alert | The engineer gives up searching | `runbook_url` alert annotation |
| The written runbook isn't tested | You notice in a drill | Try it in game day scenarios |
| Runbook English-only | A language barrier for a tired Turkish team | TR (at least the examples) |
| Auto-remediation aggressive on day one | A false positive takes prod down | Phased: alert → label → action |
| The runbook gap isn't recorded in the postmortem | The same surprise recurs | Postmortem action: runbook update |
| No runbook owner | No one notices as it goes stale | Assign a team via CODEOWNERS |

---

## 📋 Runbook Discipline Checklist

```
[ ] A runbook exists for every SEV-1 alert
[ ] 80%+ of SEV-2 alerts have runbooks
[ ] `runbook_url` in the alert annotation
[ ] Runbook in Markdown, in Git (PR review)
[ ] Follows the template (TL;DR + Verify + Mitigate + Investigate + Escalate)
[ ] Specific command + dashboard URL
[ ] Single-paragraph TL;DR (summary in 30 seconds)
[ ] CODEOWNERS: the owning team is defined
[ ] Quarterly review (any stale steps?)
[ ] Tested in a game day
[ ] Postmortem gaps feed back into the runbook
[ ] Auto-remediation map (which ones can be automated?)
[ ] New service on-boarding: gate on whether a runbook was added
```

---

## 📚 References

- **Google SRE Workbook** — Chapter 12: Practical Alerting
- **PagerDuty Runbook Best Practices**
- **AWS Well-Architected: Operational Excellence**
- [`Incident-Response.md`](Incident-Response.md)
- [`Postmortem-Practice.md`](Postmortem-Practice.md)
- [`17-Templates/runbooks/runbook-template.md`](../17-Templates/runbooks/runbook-template.md)
- [`20-Soft-Skills/Oncall-Sustainability.md`](../20-Soft-Skills/Oncall-Sustainability.md)

---

> *"A good runbook isn't the one that 'explains everything' — it's the one
> that **gives the right steps in the right order**. The link a tired
> engineer clicks at 03:14 determines the **value of the work**."*
