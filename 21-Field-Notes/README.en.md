---
description: "Raw DevOps field notes left over from production setups: as-is command dumps for Ansible, Terraform, Kubernetes, kubectl and system guides."
tags:
  - Field Notes
  - Kubernetes
  - Terraform
  - IaC
  - Cheatsheet
---
# 21 · Field Notes

> *"Not a polished deep-dive; raw reality lived through and jotted down in production."*

This section is a different content class from the numbered deep-dives: **raw
commands, configuration and installation guides** left over from real
setups. They were deliberately not forced into deep-dive anatomy (epigraph →
concept table → anti-pattern → checklist) — their value lies in being "working
/ having-worked as-is". Adapt them to your own environment and use them.

> ⚠️ The IP/password/domain values here are **examples** and must be read with
> placeholder logic. Never copy your own secrets directly.

---

## 🎯 Contents

### Ansible
| File | What it covers |
|---|---|
| [System Preparation](ansible/system-preparation.md) | Pre-k8s inventory + node preparation commands |
| [SSH Connectivity Test](ansible/ssh-connectivity-test.md) | Bulk SSH access verification to nodes |

### Terraform
| File | What it covers |
|---|---|
| [Proxmox Full Configuration](terraform/proxmox-configuration.md) | End-to-end VM provisioning on Proxmox |
| [Creating VMs with Modules](terraform/modules-create-vm.md) | Manual Terraform module + VM creation script |

### System Setup
| File | What it covers |
|---|---|
| [Kubernetes Cluster Installation](system/kubernetes-cluster-installation.md) | Cluster installation on Proxmox/Ubuntu |
| [Production-Ready Repo Layout](system/production-ready-repo-layout.md) | Laravel + TS + Flutter + K8s monorepo skeleton |
| [GitHub Actions Pipeline Setup](system/github-actions-pipeline-setup.md) | CI/CD pipeline step by step |
| [Inventory Management Example](system/inventory-management-example.md) | DevOps inventory master template |
| [External Access Solutions](system/external-access-solutions.md) | External access / port-forward / ingress solutions |
| [DevOps Certification Gates](system/devops-certification-roadmap.md) | Redirects to the learning path's 3 certification gates (3 gates, not 10) |

### kubectl
| File | What it covers |
|---|---|
| [Logging (ElasticSearch)](kubectl/logging-elasticsearch.md) | Cluster log collection notes |
| [Cluster Passwords](kubectl/cluster-passwords.md) | Script to collect service passwords |

### Network / SIEM
| File | What it covers |
|---|---|
| [Network Segmentation + Wazuh SIEM](network/network-segmentation-wazuh-siem.md) | VLAN segmentation + Wazuh integration |

---

> *"A field note says what a sterile document won't: what actually broke, and what actually worked."*
