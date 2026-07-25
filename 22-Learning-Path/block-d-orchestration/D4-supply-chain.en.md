---
description: "Supply chain: image scanning + signing — continuation of the C2 pipeline, not a separate security lesson."
level: D
module: D4
estimated_hours: 14
prerequisites: [C2, D1]
tags: [Learning Path, Security, Supply-Chain]
---
# D4 — Supply Chain: Image Scanning + Signing

> *"This isn't a separate security lesson; it's the next step in the pipeline you built in C2."*

**Block:** D — Orchestration · **Duration:** ~14h · **Prerequisite:** [`C2`](../block-c-reproducibility/C2-ci.md), [`D1`](D1-k8s-temel.md)

## 🎯 When you finish this module
- You add an image vulnerability scan (vuln scan) to the C2 pipeline and set a break threshold.
- You sign the image (`cosign`) and verify the signature; you explain **why and where (at admission time) the cluster should reject an unsigned/unscanned image**.
- You explain what an SBOM is for and how it reduces supply chain risk.

## 🧠 Why this, why now
In C2 you produced and published an image; but you never verified what you published. D4 adds security as a thread to that pipeline — scanning and signing become part of the build step, not a separate job done afterward.

> 🚪 **The signature is produced in the pipeline, enforced in the cluster.** This module's lab (L16) **produces and verifies** the signature — `cosign sign`/`verify`. The place that actually **enforces** the rule "the cluster should only accept signed images" is a different layer: an *admission controller* (Kyverno / Sigstore policy) checks every image before it's admitted to the API. In this module you learn admission **as a concept** (where it kicks in, why it's needed); setting up the policy by hand is a policy-as-code topic — the Kyverno document in "Read first" is your starting point.

## 📖 Read first
| Source | For what | Time |
|---|---|---|
| [`08-Security/Container-Image-Scanning.md`](../../08-Security/Container-Image-Scanning.md) | scanning (Trivy) | ~30 min |
| [`04-Containers/Image-Signing-Cosign.md`](../../04-Containers/Image-Signing-Cosign.md) | signing (cosign) | ~25 min |
| [`08-Security/DevSecOps-Pipeline.md`](../../08-Security/DevSecOps-Pipeline.md) | placing it in the pipeline | ~25 min |
| [`08-Security/Policy-as-Code-OPA-Kyverno.md`](../../08-Security/Policy-as-Code-OPA-Kyverno.md) | enforcing signatures via admission — where it kicks in | ~20 min |

## 🔨 Lab
👉 [`labs/build/L16-supply-chain/`](../labs/build/L16-supply-chain/README.md) — on top of the C2 pipeline.

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] Image scanning added to the C2 pipeline; the pipeline **breaks** once a defined threshold (e.g. HIGH/CRITICAL) is exceeded — evidence
- [ ] the image is signed and verified with `cosign verify` — output
- [ ] "why the cluster should reject an unsigned / unscanned image" — written rationale
- [ ] You can explain what an SBOM is and which question it answers (which component, which version)

## 🧪 Test yourself
1. Why does putting the image scan in as a report-only step that **doesn't break** the build usually not work?
2. What does signing an image prove, and what doesn't it prove?
3. A critical vulnerability was found but there's no fix yet. Break the pipeline, or open an exception? How do you decide?

<details><summary>Answers</summary>

1. A scan that doesn't break the build just produces a warning; nobody reads it, and the vulnerable image ships to production anyway. A control is only a control if it **breaks** something. Placing it in the pipeline is covered in [`08-Security/DevSecOps-Pipeline.md`](../../08-Security/DevSecOps-Pipeline.md).
2. A signature proves **who produced the image and that it hasn't changed since that day** (integrity + provenance). It does **not** prove the absence of vulnerabilities inside it — a signed image can still be vulnerable. That's why scanning + signing are needed together.
3. It's not binary: **break** the pipeline for HIGH/CRITICAL that **has a fix**; if there's no fix yet, open a time-boxed, justified, owned exception and close it once the fix lands. Blindly "break everything" just pushes the team to bypass the control.
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| Scan always green but a vulnerability exists | Threshold too loose / vulnerability DB not up to date | Set the threshold to break on HIGH/CRITICAL; update the scanner's DB |
| Pipeline breaks on every vulnerability, team is fed up | No noise management | Only break on HIGH+ that has a fix; keep exceptions time-boxed and justified |
| `cosign verify` fails | Signer identity / key mismatch | Match the signer identity and the verification key |
| Cluster accepts an unsigned image | No admission policy | Enforce signature verification with Kyverno/Gatekeeper |

## 💼 Portfolio output
A CI pipeline with scanning + signing steps — concrete evidence of DevSecOps.

## ⏭️ Up next
[`D5 — GitOps (ArgoCD)`](D5-gitops-argocd.md)

---

> *"An unsigned image is like signing a contract whose author you don't know."*
