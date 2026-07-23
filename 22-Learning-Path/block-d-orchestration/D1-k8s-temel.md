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
C1'de image'ı paketledin, C2'de pipeline'la ürettin; şimdi o container'ı elle değil,
bir orkestratörle çalıştırıyorsun. (Bu modül baştan sona yerelde **kind** ile çalışır —
kind = *Kubernetes-in-Docker*: Docker konteynerlerinin içinde çalışan yerel tek-makine
cluster, bulut/para gerekmez. C3/C4'ün bulut/Terraform'u burada **ön koşul değil**;
istersen sonra bağlarsın.) RBAC ve NetworkPolicy bu modülün **sonradan eklenen bölümü
değil, ilk günüdür** — çünkü güvenlik bir blok değil, bloklara dağılmış bir ipliktir.

## 🌉 Köprü: Pod → Deployment → Service → Ingress + RBAC + NetworkPolicy
`05-Kubernetes/` ve `08-Security/` dokümanları bu kavramları bildiğini varsayar. Kısa tanımlar — gerisi lab'da:

- **Pod:** K8s'in çalıştırdığı en küçük birim; içinde bir (bazen birkaç) container. Kısa ömürlüdür — ölür, yeni bir IP'yle yeniden doğar. Bu yüzden bir Pod'a doğrudan bağlanmazsın.
- **Deployment:** "Şu image'dan hep N kopya ayakta olsun" der. Pod ölürse yenisini açar; güncellemede eskiyi yenisiyle yavaşça değiştirir (rolling update).
- **Service:** Değişen Pod IP'lerinin önünde **sabit bir iç adres**. "Hangi Pod'a?" sorusunu `label selector` ile çözer — bu yüzden yanlış label = trafik gitmez.
- **Ingress:** Cluster **dışından** gelen HTTP(S) trafiğini bir Service'e yönlendiren kural; TLS sonlandırma genelde burada olur. Kural tek başına yetmez — trafiği fiilen karşılayan bir **ingress controller** (ör. ingress-nginx) cluster'da kurulu olmalı; yoksa kural yazılıdır ama kimse uygulamaz.
- **RBAC** (Role-Based Access Control): **kim neyi yapabilir.** Bir Role izinleri (kaynak + fiil, ör. "pod oku") tanımlar, RoleBinding onu bir kullanıcı/ServiceAccount'a bağlar. İlke: **en az yetki** — sadece işe yarayanı ver, `cluster-admin` dağıtma.
- **NetworkPolicy:** Pod'lar arası ağ trafiği için güvenlik duvarı kuralı. Varsayılan olarak K8s'te her Pod her Pod'a erişir; **default-deny** ile önce hepsini kes, sonra yalnız gereken akışı **açıkça** aç.

Bu zincir kırılırsa (yanlış selector, eksik Ingress kuralı) uygulama "çalışıyor ama erişilemiyor" olur — K04 kırık lab'ının tam senaryosu.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`08-Security/Kubernetes-Hardening.md`](../../08-Security/Kubernetes-Hardening.md) | **RBAC, NetworkPolicy, PSS — ilk günden** | ~40 dk |
| [`05-Kubernetes/Debugging-Pods.md`](../../05-Kubernetes/Debugging-Pods.md) | Pod arızası daraltma | ~25 dk |

## 🔨 Lab
👉 [`labs/build/L13-k8s-temel/`](../labs/build/L13-k8s-temel/) — yerel: kind/k3s.

## 💥 Kırık lab
👉 [`labs/broken/K04-imagepullbackoff-rbac/`](../labs/broken/K04-imagepullbackoff-rbac/) — Belirti: "Pod'lar ayağa
kalkmıyor / erişilemiyor." (Gerçekçi sebep gizli: ImagePullBackOff / yanlış label
selector / RBAC forbidden / NetworkPolicy engeli.)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] image bir Deployment olarak çalışıyor; Service + Ingress üzerinden dışarıdan erişiliyor — `kubectl get` / curl kanıtı
- [ ] En az yetkili bir RBAC Role/RoleBinding + bir NetworkPolicy uygulanmış; yetkisiz erişimin reddedildiği gösteriliyor
- [ ] `bash labs/broken/K04-imagepullbackoff-rbac/verify.sh` çözümden sonra sıfır hatayla geçiyor
- [ ] Bir Pod'un `Pending`/`CrashLoopBackOff` olma sebebini üç komutla daraltabiliyorsun

## 🧪 Kendini test et
1. Bir Pod `Pending` durumunda. Dokümana bakmadan ilk üç kontrolün ne?
2. Service var, Pod'lar ayakta ama trafik gitmiyor. En olası sebep ne?
3. Yeni bir ekip üyesine cluster erişimi vereceksin. Niçin `cluster-admin` yerine dar bir Role verirsin?

<details><summary>Cevaplar</summary>

1. (a) `kubectl describe pod <ad>` → `Events` bölümü (en hızlı ipucu); (b) node kaynağı / scheduling — CPU-bellek yetiyor mu, taint/toleration var mı; (c) image çekiliyor mu (`ImagePullBackOff`?). Daraltma yürüyüşü [`05-Kubernetes/Debugging-Pods.md`](../../05-Kubernetes/Debugging-Pods.md)'de.
2. **Label selector uyuşmazlığı.** Service'in selector'ı Pod label'larıyla eşleşmiyorsa `kubectl get endpoints <svc>` boş döner ve trafik hiçbir Pod'a gitmez. Önce endpoints'e bak.
3. En az yetki: dar bir Role sızsa bile hasar o namespace/fiil ile sınırlı kalır; `cluster-admin` sızarsa saldırgan tüm cluster'ı ele geçirir. Güvenlik bir blok değil, ilk günden içeride — gerekçe [`08-Security/Kubernetes-Hardening.md`](../../08-Security/Kubernetes-Hardening.md)'de.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `ImagePullBackOff` | Yanlış image adı/tag ya da registry auth | `kubectl describe pod` events; tag'i ve pull secret'ı doğrula |
| Pod `Pending` kalıyor | Node kaynağı yok / scheduling kısıtı | `describe` events; node `Allocatable`; taint/toleration kontrol et (taint = node'un "beni seçme" işareti, toleration = Pod'un yine de seçilebilme izni — [`Glossary.md`](../../Glossary.md)) |
| Service'e trafik gitmiyor | Selector Pod label'larıyla uyuşmuyor | `kubectl get endpoints <svc>` boş mu; label'ları eşitle |
| `kubectl` "forbidden" | RBAC yetkisi yok | `kubectl auth can-i ...`; gereken fiil/kaynağı dar bir Role'e ekle |
| NetworkPolicy sonrası bağlantı koptu | Politika gereken trafiği de kesti | Önce default-deny, sonra gereken akışı **açıkça** izin ver |

## 💼 Portfolyo çıktısı
kind/k3s üzerinde RBAC + NetworkPolicy ile çalışan bir uygulama manifest seti.

## ⏭️ Sırada
[`D2 — K8s Production`](D2-k8s-production.md)

---

> *"RBAC'siz ve NetworkPolicy'siz bir 'çalışan cluster', sadece henüz istismar edilmemiş bir cluster'dır."*
