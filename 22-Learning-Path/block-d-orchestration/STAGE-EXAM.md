---
description: "Blok D sınavı: K8s temel + production, secret, supply chain, GitOps — güvenlik iplik olarak içeride. D→E geçiş kapısı."
level: D
tags: [Learning Path, Stage Exam]
---
# 📝 Blok D Sınavı — Orkestrasyon

> *"Bir cluster'ın 'çalışıyor' olması yetmez; kimin ne yapabildiği ve neyin çalıştığı da tanımlı olmalı."*

**Kapı:** Blok D sonu (D5'ten sonra, E1'den önce) · **Ön koşul:** [`D1`](D1-k8s-temel.md)–[`D5`](D5-gitops-argocd.md) kabul kriterleri geçilmiş

> ℹ️ Her `verify.sh`'i ilgili lab dizininde ya da `22-Learning-Path/` kökünden (`bash labs/broken/…/verify.sh`) çalıştır. K04–K06 canlı bir cluster (kind) gerektirir; cluster yoksa `verify.sh` **kırmızı** döner (atlanmış sayılmaz).

Blok D bir DevSecOps bloğudur: güvenlik ayrı bir bölüm değil, **her modülün
içindeki iplik.** Bu sınav da öyle — RBAC, NetworkPolicy, secret ve supply-chain
soruları K8s sorularından ayrılmaz. Her soru bir modülün kabul kriterine izlenebilir.

> 🧵 **Güvenlik ipliği kuralı:** Aşağıdaki soruların yarısı güvenliktir. Bir K8s
> sorusuna doğru cevap verip RBAC/NetworkPolicy sorusunda takılırsan **geçmedin** —
> reponun kendi eleştirdiği "güvenliği sona bırakma" hatasına düşmüşsündür.

---

## 1️⃣ Kavram soruları (yazılı)

| # | Soru | İzlenebilirlik (modül → kabul kriteri) |
|---|---|---|
| 1 | Bir Pod niçin `Pending` veya `CrashLoopBackOff` olur? Sebebi üç komutla nasıl daraltırsın? | D1 → Pending/CrashLoop daraltma kriteri |
| 2 | En az yetkili bir RBAC Role neye izin verir, neye vermez? "delete yok" niçin bilinçli bir seçim? | D1 → RBAC + NetworkPolicy kriteri |
| 3 | Default-deny bir NetworkPolicy ne yapar? Bir Pod `Running` olduğu hâlde niçin erişilemez olabilir? | D1 → NetworkPolicy kriteri |
| 4 | request ile limit farkı ne? Bir Pod niçin `OOMKilled` (137) olur? | D2 → request/limit + OOMKilled kriteri |
| 5 | K8s Secret niçin **tek başına** yeterli değil? (varsayılan base64 = şifreleme değil) Bir alternatif söyle. | D3 → "base64 ≠ şifreleme" kriteri |
| 6 | İmzasız / taranmamış bir image'ı cluster niçin reddetmeli? SBOM hangi soruyu yanıtlar? | D4 → supply-chain + SBOM kriteri |
| 7 | "Git tek gerçek kaynak" ilkesinin bir operasyonel sonucu ne? Elle yapılan drift niçin geri alınır? | D5 → GitOps drift kriteri |

**Geçme:** 7 sorunun **en az 6'sı** doğru. Soru 2, 3, 5, 6 (güvenlik ipliği) —
**en az 3'ü zorunlu doğru.** Güvenlik sorularının çoğunu kaçırırsan D geçilmedi.

---

## 2️⃣ Uygulamalı görev — cluster + güvenlik ipliği

**Görev A — Üç kırık lab (çekirdek, ikisi çok-arızalı):**

- [ ] [`K04 — ImagePullBackOff + NetworkPolicy`](../labs/broken/K04-imagepullbackoff-rbac/): `verify.sh` yeşil; **iki** arızayı da (yok-olan tag + izinsiz default-deny) buldun (RBAC `forbidden` burada refleks olarak `solution.md`'de anlatılır, bu lab'da arıza değil)
- [ ] [`K05 — OOMKilled + probe`](../labs/broken/K05-oomkilled-probe/): `verify.sh` yeşil; **iki** arızayı da (32Mi limit + yanlış probe portu) buldun
- [ ] [`K06 — ArgoCD OutOfSync`](../labs/broken/K06-argocd-out-of-sync/): `verify.sh` yeşil; auto-sync geri açıldı

**Görev B — Güvenlik ipliği ayakta (zorunlu):**
[`D1`](D1-k8s-temel.md)/[`L13`](../labs/build/L13-k8s-temel/) + [`D4`](D4-supply-chain.md)/[`L16`](../labs/build/L16-supply-chain/).

- [ ] Uygulama Deployment + Service + Ingress ile çalışıyor; RBAC Role/RoleBinding + NetworkPolicy uygulanmış
- [ ] `kubectl auth can-i delete pods --as=<SA>` → **no**; yetkisiz erişimin reddedildiğini gösterdin
- [ ] Pipeline'da image taraması var; HIGH/CRITICAL eşiği aşılınca pipeline **kırılıyor** (kanıt)
- [ ] Image imzalanıyor ve `cosign verify` ile doğrulanıyor

**Görev C — Secret repo dışında:**
[`D3`](D3-secret-yonetimi.md)/[`L15`](../labs/build/L15-secret-yonetimi/).

- [ ] Bir sır Pod'a image/repo dışından (Secret referansı / harici store) iletiliyor
- [ ] Repoda düz metin sır olmadığını gösteren bir tarama (`gitleaks` / `trivy fs`) çıktısı temiz

---

## 🚫 Bu sınavı kendine karşı kaybetme

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| RBAC'siz "ama çalışıyor" cluster | Herkes her şeyi yapabilir; blast radius sınırsız | En az yetkili Role + `can-i` ile kanıtla |
| NetworkPolicy'yi "sonra ekleriz" | D1'in tam reddettiği "güvenliği sona bırakma" | Default-deny ilk gün, izinleri açarak genişlet |
| Secret'ı manifest'e düz metin yazmak | Git geçmişine sızar; geri alınamaz | Secret referansı / harici store; repoyu tara |
| Tarama kapısını "warning"e almak | Kırmızı olamayan kapı, kapı değildir | Eşik aşılınca pipeline `exit 1` |
| İmzasız image'ı cluster'a almak | Kaynağı doğrulanmamış artefakt | `cosign verify` geçmeyen image reddedilir |
| K05'te tek arızayı bulup durmak | Çok-arızalı; ikincisi hâlâ bozuk | `Last State` + probe portunu ayrı ayrı doğrula |

---

## ✅ Geçtin mi?

- [ ] Kavram: 7/7'nin en az 6'sı + güvenlik sorularından (2,3,5,6) en az 3'ü doğru
- [ ] Uygulama: K04 + K05 + K06 yeşil (çok-arızalıların her iki arızası bulundu)
- [ ] Güvenlik ipliği: RBAC + NetworkPolicy + `can-i` reddi + tarama kapısı + `cosign verify` + repo temiz

Geçemediysen: temelde D1, production'da D2, secret'ta D3, supply-chain'de D4,
GitOps'ta D5'e dön.

## ⏭️ Sırada
Geçtiysen önce [`Capstone 2`](../capstones/CAP2-blok-d-sonu.md), sonra
[`E1 — SLI/SLO`](../block-e-ownership/E1-sli-slo-error-budget.md).

---

> *"Bir sistemi çalıştırmak ile sahiplenmek (Blok E) arasındaki fark: çalıştıran kişi 'up mı?' diye sorar, sahibi 'kim ne yapabilir, ne kadar dayanır, bozulursa kim çağrılır?' diye sorar."*
