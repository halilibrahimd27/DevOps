---
description: "A guide to concrete ways of integrating chaos engineering into your team's culture with game day, fault injection, Litmus and Chaos Mesh."
tags:
  - SRE
  - Chaos Engineering
  - Kubernetes
  - Culture
---
# Chaos Engineering — Creating Controlled Failure

> *"A team that **waits for the incident** in production learns at the moment
> of breach. A team that **injects controlled failure** into production
> **catches the breach in simulation**. Game day is the only way to build
> confidence in prod."*

This guide explains concrete ways to integrate chaos engineering — game day,
fault injection, Litmus, Chaos Mesh — into your team's culture.

---

## 🎯 What Is Chaos Engineering?

> **Chaos Engineering**: Injecting **controlled failure** into the system to
> **verify** the behavior "expected to work in production".

```
Hypothesis: "If a region goes down, less than 1% of users are affected."
   │
   ▼
Experiment: simulate taking down the us-west-2 region
   │
   ▼
Observation: what did the real metric show?
   │
   ▼
Result: Hypothesis ✓ or gap (learning)
```

> 🔑 **Lesson**: learn **before** the real incident. Without a costly lesson.

---

## 🪜 Maturity Model

| Level | Practice |
|---|---|
| **L1** | Annual manual game day (1-2 scenarios) |
| **L2** | Quarterly game day, some tooling (Chaos Toolkit) |
| **L3** | Monthly game day + staging chaos test in CI |
| **L4** | Continuous chaos in production (controlled blast radius) |
| **L5** | Self-service chaos: devs test their own service |

> 🎯 **2026 target**: L3. L4 requires a mature team + solid observability.

---

## 🛠️ Chaos Tools

| Tool | Type | K8s |
|---|---|---|
| **Chaos Mesh** | CRD-based | ✅ Native |
| **Litmus Chaos** | CRD-based | ✅ Native |
| **AWS Fault Injection Simulator** | Cloud-native | AWS |
| **Gremlin** | SaaS | Cross-platform |
| **Chaos Toolkit** | CLI | Cross-platform |
| **Pumba** | Docker | Container-only |

> 🔑 K8s ecosystem → **Chaos Mesh** or **Litmus**. AWS-native → FIS.

---

## 🚀 Chaos Mesh — Quick Start

### Installation
```bash
helm install chaos-mesh chaos-mesh/chaos-mesh \
  -n chaos-mesh --create-namespace \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/containerd/containerd.sock
```

### Pod Kill experiment
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: payment-pod-kill
  namespace: chaos-mesh
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces: [payments]
    labelSelectors:
      app: payments-api
  duration: '0s'   # one-shot
  scheduler:
    cron: '@every 24h'   # daily
```

### Network delay
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: payment-db-latency
spec:
  action: delay
  mode: all
  selector:
    namespaces: [payments]
    labelSelectors: {app: payments-api}
  delay:
    latency: '500ms'
    correlation: '50'
    jitter: '50ms'
  direction: to
  target:
    selector:
      namespaces: [postgres]
    mode: all
  duration: '5m'
```

### CPU stress
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: api-cpu-stress
spec:
  mode: one
  selector:
    namespaces: [payments]
    labelSelectors: {app: payments-api}
  stressors:
    cpu:
      workers: 4
      load: 90
  duration: '10m'
```

---

## 🎮 Game Day Scenario Catalog

### Tier 1: Single component
| Scenario | Duration |
|---|---|
| Random pod kill | 10 min |
| Single node drain | 15 min |
| DB primary failover | 20 min |
| Redis cache flush | 10 min |
| Service mesh sidecar restart | 10 min |

### Tier 2: Network
| Scenario | Duration |
|---|---|
| Partition between services | 20 min |
| Internet egress block (3rd party) | 15 min |
| DNS failure | 15 min |
| Latency spike (50ms → 2s) | 30 min |
| Packet loss 10% | 20 min |

### Tier 3: Region / Cloud
| Scenario | Duration |
|---|---|
| Single AZ down | 30 min |
| Region failover | 60 min |
| Cloud provider API outage | 45 min |
| Certificate expiry | 30 min |

### Tier 4: Surprise (everything at once)
| Scenario | Duration |
|---|---|
| Random faults for 3 hours | 3h |
| Black Friday simulation (10x traffic + failure) | 4h |

---

## 📋 Game Day Flow

```
T-1 week:  Scenario + hypothesis written
T-1 day:   Announce to whole team, owner assigned
T+0:       Bridge opens, observability dashboards visible
T+5min:    Pre-flight check (is the system healthy?)
T+10min:   Fault inject
T+10-30min: Observe + intervene (abort if needed)
T+30min:   Clean up the fault
T+30-60min: Hot wash retrospective
T+1day:    Postmortem document written
T+1week:   Check whether action items are done
```

### Game Day check-list
```
Before:
[ ] Scenario written + hypothesis
[ ] Bridge URL shared
[ ] On-call team informed (pager not a false alarm)
[ ] Customer impact risk assessment
[ ] Abort criteria (stop if X happens)
[ ] Cleanup script ready

During:
[ ] Timeline scribe (timestamp every event)
[ ] Was the hypothesis confirmed or refuted?
[ ] Any unexpected impact?
[ ] Is customer/operational impact acceptable?

After:
[ ] Cleanup done (no lingering chaos)
[ ] Hot wash retrospective
[ ] Postmortem (gaps)
[ ] Action items (owned + due date)
```

---

## 🎯 Writing Hypotheses

### Bad hypothesis
> "Our system should not crash."

### Good hypothesis
> "When 1 of the payment-api pods is killed:
>  - p99 latency stays < 1s
>  - 5xx error rate < 0.5%
>  - HPA schedules a new pod within 30s
>  - No impact on the customer side"

→ **Measurable**, **falsifiable**, **clear control**.

---

## 🏭 Production Chaos (Continuous)

> ⚠️ **For mature teams only**. After gaining practice in staging.

### Blast radius control
```yaml
# Chaos Mesh — only 5% of pods
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
spec:
  mode: percentage
  value: '5'   # 5% of pods
  selector:
    labelSelectors: {tier: non-critical}   # Excluding critical services
```

### Auto-abort (panic button)
```yaml
spec:
  duration: '5m'
  # If error rate > 5% → abort
  abort:
    metricSelector: 'http_5xx_rate > 0.05'
```

### Communication
- #chaos-events Slack channel
- "Engineering exercise" note on the status page
- Not customer-facing (internal only)

---

## 📊 Reliability Metrics

| Metric | Target |
|---|---|
| **Game day frequency** | Monthly |
| **Scenario coverage** | At least 1 for the top 20 risks |
| **Hypothesis success rate** | > 70% (team is improving) |
| **Action item completion** | > 90% within 30 days |
| **MTTR trend** | Improving year over year |
| **Production incident rate** | Drop after game day adoption |

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| No hypothesis, "let's just hit this" | No learning | Written falsifiable hypothesis |
| Chaos on day one in production | Customer impact | Dev/staging first |
| No action items after game day | Same gap recurs | Owned + dated action |
| Insufficient observability, "result unknown" | You can't draw conclusions | Dashboard first, then chaos |
| One person owns it | Bus factor | Rotation: different person each sprint |
| Scenario got stale, random repeats | New risks aren't learned | Quarterly scenario refresh |
| Cleanup forgotten, chaos left in prod | Customer impact | Cleanup script + verify |
| Customer impact not checked | Game day = real outage | Blast radius + abort |
| Only technical, no business impact | Risk assessment incomplete | $ impact + user count |
| Everything manual, no automation | Reactive, not repeatable | Litmus / Chaos Mesh CRD |
| Game day out of fear, "the test environment will break" | Low adoption | Managers: "the test environment is already fragile, fix it" |

---

## 📋 Chaos Engineering Adoption Checklist

```
[ ] Chaos Mesh / Litmus / FIS installed (staging)
[ ] First 5 scenarios written (tier 1)
[ ] Quarterly game day (1+ person from each team)
[ ] Hypothesis template (falsifiable, measurable)
[ ] Observability: metrics / logs visible during chaos
[ ] Game day playbook (before / during / after)
[ ] Postmortem after every game day
[ ] Action item tracking
[ ] Scenario catalog in git (versioned)
[ ] Production chaos: blast radius < 5%, auto-abort
[ ] Customer impact risk assessment
[ ] Status page communication
[ ] New engineer on-boarding: shadow game day
[ ] MTTR trend dashboard
[ ] Annual: chaos engineering ROI report
```

---

## 📚 References

- **Chaos Engineering** — Casey Rosenthal, Nora Jones (book)
- **Principles of Chaos** — principlesofchaos.org
- **Netflix Chaos Monkey** — github.com/Netflix/chaosmonkey
- **Chaos Mesh** — chaos-mesh.org
- **Litmus** — litmuschaos.io
- **AWS Fault Injection Simulator** — aws.amazon.com/fis
- **Gremlin** — gremlin.com
- [`Incident-Response.md`](Incident-Response.md)
- [`Postmortem-Practice.md`](Postmortem-Practice.md)
- [`Runbook-Template.md`](Runbook-Template.md)
- [`SLI-SLO-Error-Budget.md`](SLI-SLO-Error-Budget.md)

---

> *"Chaos engineering isn't 'creating risk' — it's **learning risk**.
> A team that runs fire drills before a fire breaks out stays calm
> **in a real fire**."*

---

> 🎓 **Learning Path:** This document is used as a "Read first" resource in the [`E5`](../22-Learning-Path/block-e-ownership/E5-chaos.md) module.
