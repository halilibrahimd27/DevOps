---
description: "Capstone 2 (Blok D sonu): uygulamayı K8s'te güvenlik ipliğiyle (RBAC, NetworkPolicy, imzalı image) ve GitOps'la çalıştır."
level: D
tags: [Learning Path, Capstone]
---
# 🏁 Capstone 2 — Blok D Sonu: Orkestre + Güvenli Sistem

> *"Güvenlik sonradan eklenen bir bölüm değil; bu capstone'da RBAC, NetworkPolicy ve imzalı image ilk günden içeridedir."*

**Kapı:** Blok D sonu · **Süre:** ~20 saat · **Ön koşul:** Blok D tamamlandı ([`D1`](../block-d-orchestration/D1-k8s-temel.md)–[`D5`](../block-d-orchestration/D5-gitops-argocd.md)) + [`Blok D sınavı`](../block-d-orchestration/STAGE-EXAM.md) geçildi

## 🎯 Bu capstone'da
Capstone 1'deki uygulamayı bir K8s cluster'ında (yerel: kind/k3s) production
ayarlarıyla, güvenlik ipliği içeride ve GitOps ile çalıştırırsın. Güvenlik ayrı bir
teslimat değil — kabul kriterlerinin yarısıdır.

## 📦 Şartname
Capstone 1'in git reposunu genişletirsin. Eklenenler:

- **Deploy manifestleri (`k8s/` veya Helm/Kustomize):** Deployment + Service + Ingress.
  Uygulama dışarıdan erişiliyor.
- **Güvenlik ipliği (zorunlu, ayrı dosya değil — manifestlerin içinde):**
  - En az yetkili RBAC Role/RoleBinding (`delete` gibi gereksiz fiiller yok).
  - Default-deny NetworkPolicy + yalnız gereken trafiği açan kurallar.
  - `automountServiceAccountToken: false` (Pod token'a ihtiyaç duymuyorsa).
- **Production ayarları:** request/limit, readiness + liveness probe, PDB, HPA.
- **Supply chain (C2 pipeline'ının devamı):** pipeline'da `trivy` taraması —
  HIGH/CRITICAL eşiği aşılınca **kırılıyor**; image `cosign` ile imzalı ve doğrulanıyor.
- **Secret:** repo dışından (Secret referansı / harici store); repoda düz metin sır yok.
- **GitOps:** tek uygulama ArgoCD ile Git'ten yönetiliyor, `Synced/Healthy`.
- **`SECURITY.md`:** hangi kontrol nerede — RBAC, NetworkPolicy, tarama kapısı, imzalama,
  secret akışı. Bir denetçinin tek bakışta göreceği tablo.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan capstone tamamlanmadı:
- [ ] Uygulama Deployment + Service + Ingress ile çalışıyor — `kubectl get` / curl kanıtı
- [ ] `kubectl auth can-i delete pods --as=system:serviceaccount:<NS>:<SA>` → **no**
- [ ] Default-deny NetworkPolicy uygulanmışken izinsiz bir Pod hedefe **erişemiyor** — kanıt
- [ ] request/limit + iki probe + HPA + PDB uygulanmış — `kubectl describe` kanıtı
- [ ] Pipeline'da tarama kapısı HIGH/CRITICAL'da **kırılıyor**; `cosign verify` geçiyor
- [ ] Repoda düz metin sır yok — `gitleaks` / `trivy fs` çıktısı temiz
- [ ] Uygulama ArgoCD'de `Synced/Healthy`; elle bir drift `OutOfSync` gösterilip düzeltiliyor

## 📊 Rubrik
Her eksen 0–2. **Geçme ≥ 10/12 ve güvenlik eksenlerinin hiçbiri 0/1 değil.**

| Eksen | 0 | 1 | 2 |
|---|---|---|---|
| RBAC (en az yetki) | Yok / cluster-admin | Role var, fazla geniş | En az yetki + `can-i` reddi kanıtlı |
| NetworkPolicy | Yok | Var, default-deny değil | Default-deny + gerekçeli izinler |
| Production hazırlığı | request/limit/probe eksik | Bir kısmı var | request/limit + probe + HPA + PDB tam |
| Supply chain | Tarama/imza yok | Tarama var, kapı kırmıyor | Kapı kırıyor + `cosign verify` geçiyor |
| Secret disiplini | Manifest'te düz metin | Referans var, repo taranmamış | Referans + repo taraması temiz |
| GitOps | Elle `kubectl apply` | ArgoCD var, drift denenmemiş | Synced/Healthy + drift gösterildi |

## 💼 Portfolyo çıktısı
CV'de "K8s + güvenlik ipliği" satırının kanıtı. `SECURITY.md`, mülakatta "güvenliği
nasıl entegre ettin?" sorusunun somut cevabıdır. Repo README şablonu (Faz 7'de
`PORTFOLIO.md` modül↔CV eşlemesini ekleyecek):

```markdown
# <PROJE_ADI> — K8s'te Güvenli Deploy

**Ne:** Bir uygulamayı K8s'te production ayarları ve güvenlik ipliği
(RBAC, NetworkPolicy, imzalı image) ile GitOps üzerinden çalıştırır.
(DevSecOps Handbook · Capstone 2)

## Güvenlik kontrolleri (bkz. SECURITY.md)
- En az yetkili RBAC + default-deny NetworkPolicy
- Pipeline'da tarama kapısı (HIGH/CRITICAL kırar) + cosign imza doğrulama
- Secret repo dışından; repo gitleaks ile temiz

## Production ayarları
- request/limit, readiness+liveness probe, HPA, PDB

## Teslimat modeli
- Tek uygulama ArgoCD ile Git'ten (Synced/Healthy)

## Hangi kararı niçin verdim
- <örn. default-deny niçin, delete fiili niçin yok, imzasız image niçin reddedilir>
```

## ⏭️ Sırada
[`E1 — SLI/SLO`](../block-e-ownership/E1-sli-slo-error-budget.md)

---

> *"Bir cluster'ın 'çalışıyor' olması yetmez; kimin ne yapabildiği ve neyin çalıştığı da tanımlı olmalı."*
