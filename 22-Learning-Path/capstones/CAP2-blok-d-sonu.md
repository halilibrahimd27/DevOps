---
description: "Capstone 2 (Blok D sonu): uygulamayı K8s'te güvenlik ipliğiyle (RBAC, NetworkPolicy, imzalı image) ve GitOps'la çalıştır."
level: D
tags: [Learning Path, Capstone]
---
# 🏁 Capstone 2 — Blok D Sonu: Orkestre + Güvenli Sistem

> *"Güvenlik sonradan eklenen bir bölüm değil; bu capstone'da RBAC, NetworkPolicy ve imzalı image ilk günden içeridedir."*

**Kapı:** Blok D sonu · **Süre:** ~20 saat · **Ön koşul:** Blok D tamamlandı ([`D1`](../block-d-orchestration/D1-k8s-temel.md)–[`D5`](../block-d-orchestration/D5-gitops-argocd.md))

## 🎯 Bu capstone'da
Capstone 1'deki uygulamayı bir K8s cluster'ında (yerel: kind/k3s) production
ayarlarıyla, güvenlik ipliği içeride ve GitOps ile çalıştırırsın.

## 📦 Şartname (Faz 6'da netleşir)
- Uygulama Deployment + Service + Ingress ile çalışıyor; RBAC ve NetworkPolicy uygulanmış.
- Production ayarları: request/limit, probe, HPA, PDB.
- Supply chain: pipeline'da tarama + imzalama; cluster imzasız image reddediyor.
- Tek uygulama ArgoCD ile Git'ten yönetiliyor.

## ✅ Kabul kriterleri
- [ ] TODO (Faz 6): uygulama RBAC + NetworkPolicy ile çalışıyor — doğrulama
- [ ] TODO (Faz 6): pipeline'da tarama + imzalama var, imzasız image reddediliyor
- [ ] TODO (Faz 6): uygulama ArgoCD ile senkron; elle drift gösteriliyor/düzeltiliyor

## 📊 Rubrik
TODO (Faz 6): güvenlik varsayılanları, production hazırlığı, GitOps disiplini, teşhis edilebilirlik.

## 💼 Portfolyo README şablonu
TODO (Faz 6): → `PORTFOLIO.md` (Faz 7'de eklenecek).

## ⏭️ Sırada
[`E1 — SLI/SLO`](../block-e-ownership/E1-sli-slo-error-budget.md)

---

> *"Bir cluster'ın 'çalışıyor' olması yetmez; kimin ne yapabildiği ve neyin çalıştığı da tanımlı olmalı."*
