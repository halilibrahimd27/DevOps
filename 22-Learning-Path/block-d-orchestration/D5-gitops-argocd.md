---
description: "GitOps (ArgoCD): tek uygulama, basit kurulum — Git tek gerçek kaynak, cluster ona yakınsar."
level: D
module: D5
estimated_hours: 14
prerequisites: [D1, C2]
tags: [Learning Path, GitOps]
---
# D5 — GitOps (ArgoCD): Tek Uygulama

> *"GitOps'ta cluster'a elle dokunmazsın; Git'i değiştirir, cluster'ın ona yakınsamasını izlersin."*

**Blok:** D — Orkestrasyon · **Süre:** ~14 saat · **Ön koşul:** [`D1`](D1-k8s-temel.md), [`C2`](../block-c-reproducibility/C2-ci.md)

## 🎯 Bu modülü bitirdiğinde
- ArgoCD'yi kurar, tek bir uygulamayı Git'ten declaratively yönetirsin.
- Drift (elle yapılan değişiklik) olduğunda ArgoCD'nin nasıl davrandığını gösterirsin.
- "Git tek gerçek kaynak" ilkesinin operasyonel sonuçlarını açıklarsın.

## 🧠 Niye bu, niye şimdi
D1–D4'te manifest'leri elle/CI ile uyguladın. D5 bu uygulamayı Git'e bağlar:
değişiklik Git'te olur, cluster otomatik yakınsar. Çoklu-app soyutlamaları
(App-of-Apps, ApplicationSet) **henüz değil** — bkz. [`NOT-YET.md`](../NOT-YET.md).

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`06-GitOps/ArgoCD-Setup.md`](../../06-GitOps/ArgoCD-Setup.md) | kurulum + tek app | ~30 dk |
| [`06-GitOps/Helm-vs-Kustomize-vs-Raw.md`](../../06-GitOps/Helm-vs-Kustomize-vs-Raw.md) | manifest yaklaşımı | ~20 dk |

## 🔨 Lab
👉 `labs/build/L17-gitops-argocd/` — Faz 5'te (yerel: kind + ArgoCD).

## 💥 Kırık lab
👉 `labs/broken/K06-argocd-out-of-sync/` — Faz 5'te. Belirti: "Uygulama Git'le
uyumsuz / senkron olmuyor." (Gerçekçi sebep gizli: drift / hatalı manifest / erişim.)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 3): tek uygulama ArgoCD ile Git'ten yönetiliyor, senkron — doğrulama
- [ ] TODO (Faz 3): elle yapılan bir drift ArgoCD tarafından gösteriliyor/düzeltiliyor
- [ ] TODO (Faz 3): K06 kırık lab'ı çözüldü, `verify.sh` geçiyor

## 🧪 Kendini test et
1. TODO (Faz 3)
2. TODO (Faz 3)
3. TODO (Faz 3)

<details><summary>Cevaplar</summary>TODO (Faz 3)</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| TODO | TODO | TODO |

## 💼 Portfolyo çıktısı
Git'ten yönetilen tek bir uygulama (ArgoCD) — GitOps'un somut örneği.

## ⏭️ Sırada
Blok D bitti → **kapı projesi**: [`Capstone 2`](../capstones/CAP2-blok-d-sonu.md).
Sonra [`E1 — SLI/SLO`](../block-e-ownership/E1-sli-slo-error-budget.md).

---

> *"Elle yapılan her müdahale, GitOps'un görmediği bir yalandır — ArgoCD onu ortaya çıkarır."*
