---
description: "Block D exam: K8s fundamentals + production, secrets, supply chain, GitOps — security as a thread running through all of it. D→E transition gate."
level: D
tags: [Learning Path, Stage Exam]
---
# 📝 Block D Exam — Orchestration

> *"A cluster being 'up' isn't enough; who can do what, and what's actually running, must also be defined."*

**Gate:** End of Block D (after D5, before E1) · **Prerequisite:** [`D1`](D1-k8s-temel.md)–[`D5`](D5-gitops-argocd.md) acceptance criteria passed

> ℹ️ Run every `verify.sh` from its lab directory, or from the `22-Learning-Path/` root (`bash labs/broken/…/verify.sh`). K04–K06 need a live cluster (kind); if there's no cluster, `verify.sh` comes back **red** (this doesn't count as skipped).

Block D is a DevSecOps block: security isn't a separate section, it's the
**thread running through every module.** This exam is the same way — RBAC,
NetworkPolicy, secrets, and supply-chain questions aren't separable from the K8s
questions. Every question traces back to a module's acceptance criterion.

> 🧵 **Security-thread rule:** Half of the questions below are security. If you
> answer a K8s question correctly but get stuck on the RBAC/NetworkPolicy question,
> **you haven't passed** — you've fallen into the exact "leave security for last"
> mistake this repo criticizes.

---

## 1️⃣ Concept questions (written)

| # | Question | Traceability (module → acceptance criterion) |
|---|---|---|
| 1 | Why does a Pod end up `Pending` or `CrashLoopBackOff`? How do you narrow down the cause with three commands? | D1 → Pending/CrashLoop narrowing criterion |
| 2 | What does a least-privilege RBAC Role allow, and what does it not allow? Why is "no delete" a deliberate choice? | D1 → RBAC + NetworkPolicy criterion |
| 3 | What does a default-deny NetworkPolicy do? Why might a Pod be unreachable even though it's `Running`? | D1 → NetworkPolicy criterion |
| 4 | What's the difference between request and limit? Why does a Pod end up `OOMKilled` (137)? | D2 → request/limit + OOMKilled criterion |
| 5 | Why isn't a K8s Secret **on its own** sufficient? (base64 by default ≠ encryption) Name one alternative. | D3 → "base64 ≠ encryption" criterion |
| 6 | Why should a cluster reject an unsigned / unscanned image? What question does an SBOM answer? | D4 → supply-chain + SBOM criterion |
| 7 | What's one operational consequence of the "Git is the single source of truth" principle? Why does manual drift get reverted? | D5 → GitOps drift criterion |

**Passing:** **At least 6 of the 7** questions correct. Questions 2, 3, 5, 6 (the
security thread) — **at least 3 of these must be correct.** If you miss most of
the security questions, you haven't passed D.

---

## 2️⃣ Applied task — cluster + security thread

**Task A — Three broken labs (core, two of them multi-fault):**

- [ ] [`K04 — ImagePullBackOff + NetworkPolicy`](../labs/broken/K04-imagepullbackoff-rbac/README.md): `verify.sh` green; you found **both** faults (a nonexistent tag + an unauthorized default-deny) (the RBAC `forbidden` reflex here is covered in `solution.md` — it isn't a fault in this lab)
- [ ] [`K05 — OOMKilled + probe`](../labs/broken/K05-oomkilled-probe/README.md): `verify.sh` green; you found **both** faults (32Mi limit + wrong probe port)
- [ ] [`K06 — ArgoCD OutOfSync`](../labs/broken/K06-argocd-out-of-sync/README.md): `verify.sh` green; auto-sync turned back on

**Task B — Security thread standing (mandatory):**
[`D1`](D1-k8s-temel.md)/[`L13`](../labs/build/L13-k8s-temel/README.md) + [`D4`](D4-supply-chain.md)/[`L16`](../labs/build/L16-supply-chain/README.md).

- [ ] The app is running via Deployment + Service + Ingress; RBAC Role/RoleBinding + NetworkPolicy applied
- [ ] `kubectl auth can-i delete pods --as=<SA>` → **no**; you showed unauthorized access gets denied
- [ ] The pipeline scans images; when the HIGH/CRITICAL threshold is exceeded, the pipeline **breaks** (with proof)
- [ ] The image is signed and verified with `cosign verify`

**Task C — Secret outside the repo:**
[`D3`](D3-secret-yonetimi.md)/[`L15`](../labs/build/L15-secret-yonetimi/README.md).

- [ ] A secret reaches the Pod from outside the image/repo (Secret reference / external store)
- [ ] A scan (`gitleaks` / `trivy fs`) comes back clean, showing no plaintext secret in the repo

---

## 🚫 Don't lose this exam to yourself

| Anti-pattern | Why it's bad | Right |
|---|---|---|
| A cluster that's "working, but has no RBAC" | Everyone can do everything; blast radius unlimited | Least-privilege Role + prove it with `can-i` |
| Telling yourself "we'll add NetworkPolicy later" | Exactly the "leave security for last" mistake D1 rejects | Default-deny from day one, widen by granting permissions |
| Writing a secret into a manifest in plaintext | Leaks into Git history; can't be undone | Secret reference / external store; scan the repo |
| Downgrading the scan gate to a "warning" | A gate that can never turn red isn't a gate | Pipeline does `exit 1` once the threshold is exceeded |
| Letting an unsigned image into the cluster | An artifact with unverified provenance | Reject any image that fails `cosign verify` |
| Finding one fault in K05 and stopping | It's multi-fault; the second one is still broken | Verify `Last State` and the probe port separately |

---

## ✅ Did you pass?

- [ ] Concept: at least 6 of 7 correct, plus at least 3 of the security questions (2, 3, 5, 6)
- [ ] Application: K04 + K05 + K06 green (both faults found in the multi-fault ones)
- [ ] Security thread: RBAC + NetworkPolicy + `can-i` denial + scan gate + `cosign verify` + repo clean

If you didn't pass: go back to D1 for fundamentals, D2 for production, D3 for
secrets, D4 for supply chain, D5 for GitOps.

## ⏭️ Up next
If you passed, go to [`Capstone 2`](../capstones/CAP2-blok-d-sonu.md) first, then
[`E1 — SLI/SLO`](../block-e-ownership/E1-sli-slo-error-budget.md).

---

> *"The difference between running a system and owning it (Block E): the operator asks 'is it up?'; the owner asks 'who can do what, how much can it take, and who gets paged when it breaks?'"*
