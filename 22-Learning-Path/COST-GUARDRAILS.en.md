---
description: "The local-first principle and the cloud budget alarm: every lab runs free/local first, and the cloud starts with a mandatory alarm."
tags: [Learning Path, FinOps]
---
# 💸 Cost Guardrails

> *"A cloud bill is the most expensive and most unnecessary lesson you can learn while studying. Every lab runs locally first."*

This path's rule is **local-first.** No lab costs money up through the end of Block C.
Cloud only enters at C4, and it starts with a **mandatory budget alarm lab**.
This page shows the local equivalent of each tool, and how to protect yourself
once you do move to the cloud.

---

## 🖥️ Local equivalents — without touching the cloud at all

| Need | Cloud (expensive) | Local equivalent (free) |
|---|---|---|
| VM / server (A6, C3) | EC2 / Compute Engine | VirtualBox / Multipass / Proxmox / an old laptop |
| Running containers (C1) | ECS / Cloud Run | Docker / Podman — your own machine |
| Kubernetes (D1–D5) | EKS / GKE / AKS | `kind` or `k3s` — a cluster on one machine |
| Registry (C2, D4) | ECR / Artifact Registry | a local `registry` container or GHCR (free quota) |
| CI (C2) | (most cloud CI charges by the minute) | GitHub Actions free quota / local `act` |
| Cloud API (C4) | real AWS/GCP | **LocalStack** — emulates most services locally |
| Object storage | S3 / GCS | MinIO (local S3-compatible) |

> Learning Kubernetes **does not require** a managed cluster (EKS/GKE). `kind`
> gives you a full cluster inside a single Docker container — RBAC, NetworkPolicy,
> and Ingress included. All of Block D runs locally.

---

## 🐧 Stand up a local Linux — A0/A1 starts here

You set up your environment in A0, and from A1 onward everything runs inside a Linux box.
Pick **one** of the options below; all of them are free. The goal: an Ubuntu you can
get into and run commands in.

### Windows → WSL2 (fastest)
```powershell
# Open PowerShell as administrator:
wsl --install -d Ubuntu
# reboot → set username + password → you're ready
wsl                            # this is how you enter the Linux shell from now on
```

### macOS / Linux / Windows → Multipass (real VM, portable)
```bash
# install: https://multipass.run  (macOS: brew install --cask multipass)
multipass launch --name lab --cpus 2 --memory 2G --disk 10G
multipass shell lab            # you're now inside the VM
```
> On Apple Silicon Macs, Multipass produces an **arm64** VM; verify the architecture
> with `uname -m` for any binaries you download (the node_exporter/Prometheus step
> in B2 does exactly this).

### Any OS → VirtualBox + Ubuntu Server (graphical install)
1. Download VirtualBox and the Ubuntu Server ISO.
2. New VM: 2 vCPU, 2 GB RAM, 10 GB disk; attach the ISO, complete the install.
3. Boot the VM, log in with the username + password you set.

Whichever one you picked, verify it **inside the box**:
```bash
uname -a && whoami && ip a     # should print your Linux kernel + user + network interfaces
```
If you get output, the environment is ready — head back to [`A1`](block-a-intuition/A1-linux-temeli.md).

---

## ☁️ When you move to the cloud — C4's first job is a budget alarm

C4 (cloud fundamentals) is your first touch of the cloud, and **its first lab is
setting up a budget alarm** — before doing anything else. The order is deliberate:
the mechanism that watches spending gets set up before any spending starts.

```
[ ] Billing alarm set up on the cloud account (e.g. a low monthly threshold)
[ ] Alarm is wired to a notification (email/SMS) and has been tested
[ ] Free tier limits noted — which service is free, which isn't
[ ] Habit of shutting down unused resources: `destroy` at the end of every lab
```

> ⚠️ **The most common and most expensive mistake:** forgetting to tear down a
> resource you spun up for a lab (a load balancer, a NAT gateway, a running cluster).
> These charge you hourly while you sleep. Every cloud lab ends with a
> `terraform destroy` / resource-deletion step.

---

## 🧯 Anti-patterns

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| Spinning up a managed cluster to learn K8s | Hourly cost + unnecessary for learning | Locally with `kind`/`k3s` |
| Using the cloud without a budget alarm | You see the bill at month-end — too late | C4's first lab is the alarm |
| Leaving lab resources running | You get billed while you sleep | `destroy` at the end of every lab |
| Attaching a credit card with a "I'll check on it later" attitude | Risk of a surprise bill | Read the free tier limits first |

---

## 📋 Checklist — before your first move to the cloud

```
[ ] I did everything up to C4 locally (kind/LocalStack/Docker)
[ ] Budget alarm is set up and I tested that it triggers
[ ] I know the free tier limits
[ ] I have a "destroy/cleanup" step for every cloud lab
```

---

> *"A cluster that breaks locally is free; a cluster forgotten in the cloud is a bill. Break the free one first."*
