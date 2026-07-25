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
- ArgoCD'yi kurar, tek bir uygulamayı Git'ten **bildirimsel olarak** (declarative — istenen durumu Git'te tanımlar, ArgoCD uygular) yönetirsin.
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
👉 [`labs/build/L17-gitops-argocd/`](../labs/build/L17-gitops-argocd/README.md) — yerel: kind + ArgoCD.

## 💥 Kırık lab
👉 [`labs/broken/K06-argocd-out-of-sync/`](../labs/broken/K06-argocd-out-of-sync/README.md) — Belirti: "Uygulama Git'le
uyumsuz / senkron olmuyor." (Gerçekçi sebep gizli: drift / hatalı manifest / erişim.)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] Tek bir uygulama ArgoCD ile Git'ten yönetiliyor ve `Synced/Healthy` durumda — kanıt
- [ ] Elle yapılan bir drift ArgoCD tarafından `OutOfSync` gösteriliyor ve (auto/manual) düzeltiliyor
- [ ] `bash labs/broken/K06-argocd-out-of-sync/verify.sh` çözümden sonra sıfır hatayla geçiyor
- [ ] "Git tek gerçek kaynak" ilkesinin bir operasyonel sonucunu (elle değişiklik niçin geri alınır) anlatabiliyorsun

## 🧪 Kendini test et
1. GitOps'ta bir üretim değişikliğini nasıl yaparsın; `kubectl edit` niçin anti-pattern?
2. ArgoCD bir Pod'u sürekli eski hâline döndürüyor. Sebebi ne, bu bir hata mı?
3. Tek app'i GitOps'la sağlam yönetmeden App-of-Apps / ApplicationSet'e geçmek niçin erken?

<details><summary>Cevaplar</summary>

1. Değişikliği **Git'te** (manifest) yapar, ArgoCD'nin cluster'ı ona yakınsamasını izlersin. `kubectl edit` cluster'ı Git'in bilmediği bir duruma sokar (drift); ArgoCD ya geri alır ya `OutOfSync` gösterir → kaynak-of-truth ikiye bölünür. Kurulum [`06-GitOps/ArgoCD-Setup.md`](../../06-GitOps/ArgoCD-Setup.md)'de.
2. Biri Git dışında elle değişiklik yapmıştır; ArgoCD auto-sync ile bunu Git'teki hâle geri çeker. Bu bir hata değil, **tasarlanan davranıştır** — drift'i düzeltmek GitOps'un işidir.
3. Çünkü çoklu-app soyutlamaları tek app'in sorunlarını (drift, sync, sır) çözmez, çoğaltır. Önce bir app'i güvenle yönet. Erken karmaşıklık gerekçesi [`NOT-YET.md`](../NOT-YET.md)'de.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| App `OutOfSync` kalıyor | Git'te olmayan elle değişiklik / hatalı manifest | Git'i doğru kaynak yap; farkı ArgoCD diff'inden oku |
| ArgoCD Git'e erişemiyor | Repo kimlik / erişim yok | Repo credential'ını ve URL'i doğrula |
| Değişiklik uygulanmıyor | Auto-sync kapalı / izlenen path yanlış | Sync policy'yi ve izlenen path'i kontrol et |
| Sır ArgoCD üzerinden sızıyor | Düz metin manifest | D3'e dön: şifreli referans / harici store kullan |

## 💼 Portfolyo çıktısı
Git'ten yönetilen tek bir uygulama (ArgoCD) — GitOps'un somut örneği.

## ⏭️ Sırada
Blok D bitti → **kapı projesi**: [`Capstone 2`](../capstones/CAP2-blok-d-sonu.md).
Sonra [`E1 — SLI/SLO`](../block-e-ownership/E1-sli-slo-error-budget.md).

---

> *"Elle yapılan her müdahale, GitOps'un görmediği bir yalandır — ArgoCD onu ortaya çıkarır."*
