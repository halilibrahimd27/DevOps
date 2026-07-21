---
description: "K8s temel: Pod, Deployment, Service, Ingress — ve RBAC + NetworkPolicy ilk günden içeride. Güvenlik sonradan eklenmez."
level: D
module: D1
estimated_hours: 28
prerequisites: [C1, C2]
tags: [Learning Path, Kubernetes, Security]
---
# D1 — K8s Temel: Pod/Deployment/Service/Ingress (RBAC + NetworkPolicy İlk Günden)

> *"K8s'i güvenliksiz öğretmek, reponun kendi eleştirdiği 'güvenliği sona bırakma' hatasını tekrarlamaktır. Bu modül onu tekrarlamaz."*

**Blok:** D — Orkestrasyon · **Süre:** ~28 saat · **Ön koşul:** [`C1`](../block-c-reproducibility/C1-container.md), [`C2`](../block-c-reproducibility/C2-ci.md)

## 🎯 Bu modülü bitirdiğinde
- C1'deki image'ı bir Pod/Deployment olarak çalıştırır, Service + Ingress ile dışarı açarsın.
- **İlk günden** RBAC ile en az yetki ve NetworkPolicy ile trafik kısıtı uygularsın.
- Bir Pod'un neden `Pending`/`CrashLoop` olduğunu daraltıp açıklarsın.

## 🧠 Niye bu, niye şimdi
C3'te altyapıyı kod yaptın; şimdi container'ları elle değil, bir orkestratörle
çalıştırıyorsun. RBAC ve NetworkPolicy bu modülün **sonradan eklenen bölümü değil,
ilk günüdür** — çünkü güvenlik bir blok değil, bloklara dağılmış bir ipliktir.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| (K8s kavram girişi köprüsü — Faz 3: Pod/Deployment/Service/Ingress) | temel | — |
| [`08-Security/Kubernetes-Hardening.md`](../../08-Security/Kubernetes-Hardening.md) | **RBAC, NetworkPolicy, PSS — ilk günden** | ~40 dk |
| [`05-Kubernetes/Debugging-Pods.md`](../../05-Kubernetes/Debugging-Pods.md) | Pod arızası daraltma | ~25 dk |

## 🔨 Lab
👉 `labs/build/L13-k8s-temel/` — Faz 5'te (yerel: kind/k3s).

## 💥 Kırık lab
👉 `labs/broken/K04-imagepullbackoff-rbac/` — Faz 5'te. Belirti: "Pod'lar ayağa
kalkmıyor / erişilemiyor." (Gerçekçi sebep gizli: ImagePullBackOff / yanlış label
selector / RBAC forbidden / NetworkPolicy engeli.)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 3): image bir Deployment olarak çalışıyor, Service + Ingress'ten erişiliyor
- [ ] TODO (Faz 3): en az yetkili bir RBAC rolü + bir NetworkPolicy uygulanmış — doğrulama
- [ ] TODO (Faz 3): K04 kırık lab'ı çözüldü, `verify.sh` geçiyor

## 🧪 Kendini test et
1. TODO (Faz 3)
2. TODO (Faz 3) — senaryo: "Pod Pending, ilk üç kontrolün?"
3. TODO (Faz 3)

<details><summary>Cevaplar</summary>TODO (Faz 3)</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| TODO | TODO | TODO |

## 💼 Portfolyo çıktısı
kind/k3s üzerinde RBAC + NetworkPolicy ile çalışan bir uygulama manifest seti.

## ⏭️ Sırada
[`D2 — K8s Production`](D2-k8s-production.md)

---

> *"RBAC'siz ve NetworkPolicy'siz bir 'çalışan cluster', sadece henüz istismar edilmemiş bir cluster'dır."*
