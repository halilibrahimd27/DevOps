---
description: "K8s fundamentals: Pod, Deployment, Service, Ingress — and RBAC + NetworkPolicy in from day one. Security isn't bolted on later."
level: D
module: D1
estimated_hours: 28
prerequisites: [C1, C2]
tags: [Learning Path, Kubernetes, Security]
---
# D1 — K8s Fundamentals: Pod/Deployment/Service/Ingress (RBAC + NetworkPolicy From Day One)

> *"Teaching K8s without security repeats the exact 'leave security for later' mistake this repo itself criticizes. This module doesn't repeat it."*

**Block:** D — Orchestration · **Duration:** ~28h · **Prerequisites:** [`C1`](../block-c-reproducibility/C1-container.md), [`C2`](../block-c-reproducibility/C2-ci.md)

## 🎯 When you finish this module
- You run C1's image as a Pod/Deployment, and expose it to the outside via Service + Ingress.
- You apply least-privilege access with RBAC and traffic restriction with NetworkPolicy **from day one**.
- You can narrow down and explain why a Pod is `Pending`/`CrashLoop`.

## 🧠 Why this, why now
In C1 you packaged the image, in C2 you produced it via a pipeline; now you run that
container not by hand, but with an orchestrator. (This module runs entirely locally
with **kind** from start to finish — kind = *Kubernetes-in-Docker*: a local single-machine
cluster that runs inside Docker containers, no cloud/money needed. C3/C4's
cloud/Terraform is **not a prerequisite** here; you can wire it in later if you want.)
RBAC and NetworkPolicy are not this module's **bolted-on-later section — they're its
day one** — because security isn't a block, it's a thread woven through the blocks.

## 🌉 Bridge: Pod → Deployment → Service → Ingress + RBAC + NetworkPolicy
The `05-Kubernetes/` and `08-Security/` docs assume you already know these concepts. Short definitions here — the rest is in the lab:

- **Pod:** the smallest unit K8s runs; holds one (sometimes a few) container(s). Short-lived — it dies and is reborn with a new IP. That's why you never connect to a Pod directly.
- **Deployment:** says "always keep N copies of this image running." If a Pod dies it spins up a new one; on an update it slowly swaps the old for the new (rolling update).
- **Service:** a **stable internal address** in front of changing Pod IPs. It answers "which Pod?" via a `label selector` — so a wrong label means no traffic gets through.
- **Ingress:** a rule that routes HTTP(S) traffic coming from **outside** the cluster to a Service; TLS termination usually happens here. The rule alone isn't enough — an **ingress controller** (e.g. ingress-nginx) that actually handles the traffic must be installed in the cluster; otherwise the rule is on paper but nobody enforces it.
- **RBAC** (Role-Based Access Control): **who can do what.** A Role defines permissions (resource + verb, e.g. "read pods"), a RoleBinding attaches it to a user/ServiceAccount. Principle: **least privilege** — grant only what's needed, don't hand out `cluster-admin`.
- **NetworkPolicy:** the firewall rule for network traffic between Pods. By default in K8s every Pod can reach every Pod; with **default-deny** you cut everything off first, then **explicitly** open only the flow you need.

If this chain breaks (wrong selector, missing Ingress rule) the app ends up "running but unreachable" — the exact scenario of K04's broken lab.

## 📖 Read first
| Source | For what | Time |
|---|---|---|
| [`08-Security/Kubernetes-Hardening.md`](../../08-Security/Kubernetes-Hardening.md) | **RBAC, NetworkPolicy, PSS — from day one** | ~40 min |
| [`05-Kubernetes/Debugging-Pods.md`](../../05-Kubernetes/Debugging-Pods.md) | Narrowing down Pod failures | ~25 min |

## 🔨 Lab
👉 [`labs/build/L13-k8s-temel/`](../labs/build/L13-k8s-temel/) — local: kind/k3s.

## 💥 Broken lab
👉 [`labs/broken/K04-imagepullbackoff-rbac/`](../labs/broken/K04-imagepullbackoff-rbac/) — Symptom: "Pods won't
come up / unreachable." (Real cause hidden: ImagePullBackOff / wrong label
selector / RBAC forbidden / NetworkPolicy block.)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] the image is running as a Deployment; reachable from outside via Service + Ingress — `kubectl get` / curl proof
- [ ] a least-privilege RBAC Role/RoleBinding + a NetworkPolicy applied; unauthorized access shown to be denied
- [ ] `bash labs/broken/K04-imagepullbackoff-rbac/verify.sh` passes with zero errors after the fix
- [ ] you can narrow down why a Pod is `Pending`/`CrashLoopBackOff` in three commands

## 🧪 Test yourself
1. A Pod is stuck in `Pending`. Without looking at the doc, what are your first three checks?
2. The Service exists, the Pods are up, but no traffic gets through. What's the most likely cause?
3. You're about to give a new team member cluster access. Why give a narrow Role instead of `cluster-admin`?

<details><summary>Answers</summary>

1. (a) `kubectl describe pod <name>` → the `Events` section (fastest clue); (b) node resources / scheduling — is there enough CPU/memory, is there a taint/toleration; (c) is the image actually pulling (`ImagePullBackOff`?). The narrowing-down walkthrough is in [`05-Kubernetes/Debugging-Pods.md`](../../05-Kubernetes/Debugging-Pods.md).
2. **Label selector mismatch.** If the Service's selector doesn't match the Pod's labels, `kubectl get endpoints <svc>` comes back empty and traffic reaches no Pod at all. Check endpoints first.
3. Least privilege: even if a narrow Role leaks, the damage stays limited to that namespace/verb; if `cluster-admin` leaks, the attacker takes over the entire cluster. Security is in from day one, not a block — the reasoning is in [`08-Security/Kubernetes-Hardening.md`](../../08-Security/Kubernetes-Hardening.md).
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| `ImagePullBackOff` | Wrong image name/tag or registry auth | `kubectl describe pod` events; verify the tag and pull secret |
| Pod stays `Pending` | No node resources / scheduling constraint | `describe` events; node `Allocatable`; check taint/toleration (taint = the node's "don't pick me" mark, toleration = the Pod's permission to be picked anyway — [`Glossary.md`](../../Glossary.md)) |
| No traffic reaching the Service | Selector doesn't match the Pod's labels | is `kubectl get endpoints <svc>` empty; align the labels |
| `kubectl` says "forbidden" | No RBAC permission | `kubectl auth can-i ...`; add the needed verb/resource to a narrow Role |
| Connectivity broke after NetworkPolicy | The policy also blocked traffic you needed | default-deny first, then **explicitly** allow the flow you need |

## 💼 Portfolio output
A manifest set for an app running with RBAC + NetworkPolicy on kind/k3s.

## ⏭️ Up next
[`D2 — K8s Production`](D2-k8s-production.md)

---

> *"A 'working cluster' without RBAC and without NetworkPolicy is just a cluster that hasn't been exploited yet."*
