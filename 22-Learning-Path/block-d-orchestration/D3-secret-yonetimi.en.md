---
description: "Secret management: carrying secrets safely through the K8s and GitOps flow without embedding them in the image or the repo."
level: D
module: D3
estimated_hours: 12
prerequisites: [D1]
tags: [Learning Path, Security, Kubernetes]
---
# D3 — Secret Management

> *"Once a secret has entered a repo, it counts as leaked even if it's later removed from history."*

**Block:** D — Orchestration · **Duration:** ~12h · **Prerequisite:** [`D1`](D1-k8s-temel.md)

## 🎯 When you finish this module
- You can safely deliver a secret to a Pod without embedding it in the image/repo.
- You can explain what a K8s Secret is, and what it isn't (not encryption by default).
- You can justify how secrets move through a GitOps flow (reference, external store) — *preview*: you'll learn GitOps in D5; here, just the principle "a secret is never written to Git in plaintext" is enough.

## 🧠 Why this, why now
In D1 the application runs, but real applications need secrets (DB password, API
key). Since everything will be in Git in D5's GitOps, how secrets get managed
**without entering** Git becomes critical.

## 📖 Read first
| Source | For what | Time |
|---|---|---|
| [`08-Security/Secrets-Management.md`](../../08-Security/Secrets-Management.md) | secret management patterns | ~30 min |
| [`06-GitOps/Secrets-in-GitOps.md`](../../06-GitOps/Secrets-in-GitOps.md) | secrets in GitOps | ~20 min |

## 🔨 Lab
👉 [`labs/build/L15-secret-yonetimi/`](../labs/build/L15-secret-yonetimi/)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] A secret is delivered to the Pod from outside the image/repo (Secret reference / external store) — `kubectl` / application evidence
- [ ] A scan (e.g. gitleaks / `trivy fs`) output showing there's no plaintext secret in the repo
- [ ] "Why a K8s Secret isn't sufficient on its own (default is just base64, not encryption)" — written
- [ ] You can explain at least one way to carry a secret into a GitOps flow without putting it there in plaintext

## 🧪 Test yourself
1. How does a K8s Secret store data by default; why isn't base64 "security"?
2. A secret was accidentally committed and then deleted. Why does it still count as leaked, and what do you do?
3. How do you reconcile GitOps's "everything is in Git" principle with the rule "secrets shouldn't be in Git"?

<details><summary>Answers</summary>

1. By default it sits in etcd **base64-encoded** — base64 is a reversible encoding, not encryption; anyone with access can read it. Real protection needs etcd encryption and/or an external secret store. Patterns are in [`08-Security/Secrets-Management.md`](../../08-Security/Secrets-Management.md).
2. Git history is permanent: even if you delete it, it stays in the old commit, and anyone who clones can see it. The right reflex isn't deleting the file — it's **revoking and rotating the secret**, because a leaked secret can no longer be trusted.
3. You put a **reference** to the secret, or its **encrypted** form, into Git — never the secret itself: Sealed Secrets (encrypted), an external secret store + `secretKeyRef`, or SOPS. The decision lives in [`06-GitOps/Secrets-in-GitOps.md`](../../06-GitOps/Secrets-in-GitOps.md).
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| Pod can't access the secret | Secret name/key is wrong or namespace differs | Verify the `secretKeyRef` name + key and the namespace |
| Secret shows up in logs | Application logs the env / an error message | Turn off logging the secret; consider mounting it as a file instead of env |
| Secret caught in the repo | Plaintext commit | Revoke/rotate the secret; cleaning up history alone isn't enough |
| GitOps wants the secret in plaintext | No encryption layer | Use Sealed Secrets / an external store + reference |

## 💼 Portfolio output
A manifest with no secret leak that works via an external reference, plus scan evidence.

## ⏭️ Up next
[`D4 — Supply Chain`](D4-supply-chain.md)

---

> *"The best secret is the one that never made it into the code."*
