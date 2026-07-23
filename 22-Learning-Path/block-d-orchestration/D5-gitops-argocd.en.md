---
description: "GitOps (ArgoCD): a single app, simple setup — Git is the single source of truth, the cluster converges to it."
level: D
module: D5
estimated_hours: 14
prerequisites: [D1, C2]
tags: [Learning Path, GitOps]
---
# D5 — GitOps (ArgoCD): Single App

> *"In GitOps you don't touch the cluster by hand; you change Git and watch the cluster converge to it."*

**Block:** D — Orchestration · **Duration:** ~14h · **Prerequisite:** [`D1`](D1-k8s-temel.md), [`C2`](../block-c-reproducibility/C2-ci.md)

## 🎯 When you finish this module
- You set up ArgoCD and manage a single application from Git **declaratively** (declarative — you define the desired state in Git, ArgoCD applies it).
- You show how ArgoCD behaves when drift (a manual change) occurs.
- You explain the operational consequences of the "Git is the single source of truth" principle.

## 🧠 Why this, why now
In D1–D4 you applied manifests by hand/CI. D5 ties that application to Git:
the change happens in Git, the cluster converges automatically. Multi-app
abstractions (App-of-Apps, ApplicationSet) are **not yet** in scope — see [`NOT-YET.md`](../NOT-YET.md).

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`06-GitOps/ArgoCD-Setup.md`](../../06-GitOps/ArgoCD-Setup.md) | setup + single app | ~30 min |
| [`06-GitOps/Helm-vs-Kustomize-vs-Raw.md`](../../06-GitOps/Helm-vs-Kustomize-vs-Raw.md) | manifest approach | ~20 min |

## 🔨 Lab
👉 [`labs/build/L17-gitops-argocd/`](../labs/build/L17-gitops-argocd/) — local: kind + ArgoCD.

## 💥 Broken lab
👉 [`labs/broken/K06-argocd-out-of-sync/`](../labs/broken/K06-argocd-out-of-sync/) — Symptom: "The application
is out of sync with Git / won't sync." (Realistic cause hidden: drift / bad manifest / access.)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] A single application is managed from Git via ArgoCD and is in `Synced/Healthy` state — evidence
- [ ] A manually made drift is shown as `OutOfSync` by ArgoCD and gets corrected (auto/manual)
- [ ] `bash labs/broken/K06-argocd-out-of-sync/verify.sh` passes with zero errors after the fix
- [ ] You can explain one operational consequence of the "Git is the single source of truth" principle (why a manual change gets reverted)

## 🧪 Test yourself
1. How do you make a production change in GitOps; why is `kubectl edit` an anti-pattern?
2. ArgoCD keeps reverting a Pod to its old state. What's the reason, is this a bug?
3. Why is it premature to move to App-of-Apps / ApplicationSet before solidly managing a single app with GitOps?

<details><summary>Answers</summary>

1. You make the change **in Git** (the manifest) and watch ArgoCD converge the cluster to it. `kubectl edit` puts the cluster into a state Git doesn't know about (drift); ArgoCD either reverts it or shows `OutOfSync` → the source of truth gets split in two. Setup is in [`06-GitOps/ArgoCD-Setup.md`](../../06-GitOps/ArgoCD-Setup.md).
2. Someone made a manual change outside Git; ArgoCD's auto-sync pulls it back to the state in Git. This isn't a bug, it's **the designed behavior** — correcting drift is GitOps's job.
3. Because multi-app abstractions don't solve a single app's problems (drift, sync, secrets), they multiply them. Manage one app safely first. The rationale for avoiding early complexity is in [`NOT-YET.md`](../NOT-YET.md).
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| App stays `OutOfSync` | A manual change not in Git / bad manifest | Make Git the correct source; read the difference from ArgoCD's diff |
| ArgoCD can't reach Git | No repo credentials / access | Verify the repo credential and the URL |
| The change isn't applying | Auto-sync off / wrong watched path | Check the sync policy and the watched path |
| A secret is leaking through ArgoCD | Plain-text manifest | Go back to D3: use an encrypted reference / external store |

## 💼 Portfolio output
A single application managed from Git (ArgoCD) — a concrete example of GitOps.

## ⏭️ Up next
Block D is done → **gate project**: [`Capstone 2`](../capstones/CAP2-blok-d-sonu.md).
Then [`E1 — SLI/SLO`](../block-e-ownership/E1-sli-slo-error-budget.md).

---

> *"Every manual intervention is a lie GitOps can't see — ArgoCD exposes it."*
