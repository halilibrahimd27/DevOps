---
description: "Not-yet list: topics deliberately kept off the path early, and why they're deferred."
tags: [Learning Path]
---
# ⏳ Not Yet

> *"The real damage a roadmap does isn't what it leaves out — it's what it puts in too early."*

The topics below are solid and real — but learning them at the wrong time
does harm. Each one only makes sense once you've felt the concrete pain that
demands it. Poke at them if you're curious; but not as the backbone of the
path, not now.

| Topic | When | Why not now |
|---|---|---|
| Service mesh (Istio/Linkerd) | Not before you've hit a concrete problem on a single cluster | A mesh added before you've felt the problem it solves (mTLS, retries, traffic splitting) is just operational overhead and a magic box. |
| Multi-cluster / multi-cloud | Not before a single cluster runs solidly | For someone who can't run one cluster reliably, a second one just doubles the failure surface — it doesn't add resilience. |
| eBPF / Cilium depth | Block F, at a curiosity level | Powerful but low-level; it won't become concrete until basic networking and observability have settled in. |
| ApplicationSet / App-of-Apps | Not before you manage a single ArgoCD app via GitOps | If you can't manage one app through the GitOps loop, a multi-app abstraction just adds complexity. |
| Platform Engineering / IDP | You don't design a platform without having felt developer pain | A platform built without knowing who suffers from what becomes a product nobody asked for. |
| Kafka / event-driven architecture | Not part of this path — a separate specialty | Not a goal of the DevSecOps path; when the need arises, it requires its own separate learning path. |
| Certificate collecting | 3 gates, not 10 certificates | A certificate is external validation that you finished the path — it doesn't replace it. See `certifications/README.md` (Phase 6.5). |

---

## 🧭 Rule

If a topic is on this list, adding it early isn't progress — it's a
distraction. Follow the path; when their turn comes, they'll show up either
in a module or in your next learning path.

---

> *"Knowing what not to learn is as much engineering as knowing what to learn."*
