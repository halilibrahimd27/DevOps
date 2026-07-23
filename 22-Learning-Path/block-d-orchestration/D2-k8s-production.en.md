---
description: "K8s production: request/limit, probes, PDB, and HPA — the settings that take a cluster from 'running' to 'reliable'."
level: D
module: D2
estimated_hours: 16
prerequisites: [D1]
tags: [Learning Path, Kubernetes]
---
# D2 — K8s Production: request/limit, Probes, PDB, HPA

> *"The difference between 'running' and 'reliable in production' is a handful of YAML fields, and why they exist."*

**Block:** D — Orchestration · **Duration:** ~16h · **Prerequisite:** [`D1`](D1-k8s-temel.md)

## 🎯 When you finish this module
- You set correct request/limit values, preventing OOMKilled and resource starvation.
- You control when a Pod receives traffic using liveness/readiness probes.
- You define behavior under disruption and load using PDB and HPA.

## 🧠 Why this, why now
In D1 you got the app running; but staying up under real load and failure
requires production settings. Block E's SLO (E1) and chaos (E5) build on top of
these settings.

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`05-Kubernetes/Production-Checklist.md`](../../05-Kubernetes/Production-Checklist.md) | production checklist | ~30 min |
| [`05-Kubernetes/Resource-Limits-Guide.md`](../../05-Kubernetes/Resource-Limits-Guide.md) | request/limit | ~25 min |

## 🔨 Lab
👉 [`labs/build/L14-k8s-production/`](../labs/build/L14-k8s-production/)

## 💥 Broken lab
👉 [`labs/broken/K05-oomkilled-probe/`](../labs/broken/K05-oomkilled-probe/) — Symptom: "Pod keeps
restarting / not receiving traffic." (Realistic cause hidden: OOMKilled / wrong probe / missing limit.)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] Appropriate request/limit + readiness/liveness probes applied; verified with `kubectl describe`/metrics
- [ ] HPA increases replica count under load — `kubectl get hpa` / metric evidence (HPA needs metrics-server; kind setup is in the L14 README)
- [ ] A **PodDisruptionBudget** applied (`kubectl get pdb` shows `ALLOWED DISRUPTIONS`); you **explain in writing** why the PDB keeps at least one replica up during a voluntary disruption (drain) (a real drain isn't possible on single-node kind — describe the behavior via `min-available`/`maxUnavailable`)
- [ ] `bash labs/broken/K05-oomkilled-probe/verify.sh` passes with zero errors after the fix
- [ ] You can explain in writing the difference between request and limit, and why a Pod gets OOMKilled

## 🧪 Test yourself
1. What's the difference between request and limit? When is setting them equal good, and when is it wasteful?
2. What happens if you mix up liveness and readiness probes?
3. A Pod is getting `OOMKilled`. What question do you ask before raising the limit?

<details><summary>Answers</summary>

1. request is the floor the scheduler **guarantees** the Pod; limit is the ceiling it can't exceed. Setting them equal makes memory predictable (QoS `Guaranteed`) but can waste resources under inelastic load. The distinction is in [`05-Kubernetes/Resource-Limits-Guide.md`](../../05-Kubernetes/Resource-Limits-Guide.md).
2. A wrong/aggressive **liveness** probe keeps killing a healthy Pod (restart loop). A missing **readiness** probe puts the Pod into the Service before it's ready → the user gets 502/503. Liveness asks "is it alive?", readiness asks "can it take traffic?"
3. "Does the app genuinely need this much memory, or is it a leak, and is my limit actually sized to reality?" Measure first; blindly raising the limit just hides the leak.
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| Pod `OOMKilled` | Memory limit below actual usage / leak | Measure usage, size the limit to reality; address the leak |
| Pod in a restart loop | Liveness probe too aggressive / wrong path | Loosen the threshold/delay; verify the probe endpoint |
| 502/503 after deploy | No readiness probe, Pod took traffic before it was ready | Add readiness; keep it out of the Service until ready |
| HPA isn't scaling | No metrics-server / request undefined | Install metrics-server; HPA works off CPU request — set a request |

## 💼 Portfolio output
A set of manifests for a production-tuned Deployment (probes + limits + HPA + PDB).

## ⏭️ Up next
[`D3 — Secret Management`](D3-secret-yonetimi.md)

---

> *"A missing readiness probe comes back to the user as a 502."*
