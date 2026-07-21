---
description: "Supply chain: image tarama + imzalama — C2 pipeline'ının devamı olarak, ayrı bir güvenlik dersi değil."
level: D
module: D4
estimated_hours: 14
prerequisites: [C2, D1]
tags: [Learning Path, Security, Supply-Chain]
---
# D4 — Supply Chain: Image Tarama + İmzalama

> *"Bu ayrı bir güvenlik dersi değil; C2'de kurduğun pipeline'ın bir sonraki adımıdır."*

**Blok:** D — Orkestrasyon · **Süre:** ~14 saat · **Ön koşul:** [`C2`](../block-c-reproducibility/C2-ci.md), [`D1`](D1-k8s-temel.md)

## 🎯 Bu modülü bitirdiğinde
- C2 pipeline'ına image açık taraması (vuln scan) ekler, kırılma eşiğini belirlersin.
- Image'ı imzalar ve cluster'ın yalnızca imzalı image kabul etmesini sağlarsın.
- Bir SBOM'un ne işe yaradığını ve tedarik zinciri riskini nasıl azalttığını açıklarsın.

## 🧠 Niye bu, niye şimdi
C2'de image üretip yayımladın; ama neyi yayımladığını doğrulamadın. D4 o
pipeline'a güvenlik iplik olarak eklenir — tarama ve imzalama build adımının
parçası olur, sonradan yapılan ayrı bir iş değil.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`08-Security/Container-Image-Scanning.md`](../../08-Security/Container-Image-Scanning.md) | tarama (Trivy) | ~30 dk |
| [`04-Containers/Image-Signing-Cosign.md`](../../04-Containers/Image-Signing-Cosign.md) | imzalama (cosign) | ~25 dk |
| [`08-Security/DevSecOps-Pipeline.md`](../../08-Security/DevSecOps-Pipeline.md) | pipeline'a yerleştirme | ~25 dk |

## 🔨 Lab
👉 `labs/build/L16-supply-chain/` — Faz 5'te (C2 pipeline'ının üstüne).

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 3): pipeline'da image taraması var ve eşik aşımında kırılıyor — kanıt
- [ ] TODO (Faz 3): image imzalanıyor ve doğrulanıyor — cosign çıktısı
- [ ] TODO (Faz 3): "imzasız image'ı cluster niçin reddetmeli" (yazılı)

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
Tarama + imzalama adımları olan bir CI pipeline'ı — DevSecOps'un somut kanıtı.

## ⏭️ Sırada
[`D5 — GitOps (ArgoCD)`](D5-gitops-argocd.md)

---

> *"İmzasız bir image, kimin yazdığı bilinmeyen bir sözleşmeyi imzalamaktır."*
