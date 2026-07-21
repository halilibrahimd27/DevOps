---
description: "Secret yönetimi: sırları image'a ve repoya gömmeden, K8s ve GitOps akışında güvenle taşımak."
level: D
module: D3
estimated_hours: 12
prerequisites: [D1]
tags: [Learning Path, Security, Kubernetes]
---
# D3 — Secret Yönetimi

> *"Bir sır repoya bir kez girdiyse, geçmişten silinse bile sızmış sayılır."*

**Blok:** D — Orkestrasyon · **Süre:** ~12 saat · **Ön koşul:** [`D1`](D1-k8s-temel.md)

## 🎯 Bu modülü bitirdiğinde
- Bir sırrı image'a/repoya gömmeden bir Pod'a güvenle iletirsin.
- K8s Secret'ın ne olduğunu, ne olmadığını (varsayılan şifreleme değil) açıklarsın.
- GitOps akışında sırların nasıl taşındığını (referans, harici store) gerekçelendirirsin.

## 🧠 Niye bu, niye şimdi
D1'de uygulama çalışıyor ama gerçek uygulamalar sır (DB şifresi, API anahtarı)
ister. D5'teki GitOps'ta her şey Git'te olacağı için, sırların Git'e **girmeden**
nasıl yönetileceği kritik olur.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`08-Security/Secrets-Management.md`](../../08-Security/Secrets-Management.md) | sır yönetimi desenleri | ~30 dk |
| [`06-GitOps/Secrets-in-GitOps.md`](../../06-GitOps/Secrets-in-GitOps.md) | GitOps'ta sır | ~20 dk |

## 🔨 Lab
👉 `labs/build/L15-secret-yonetimi/` — Faz 5'te.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 3): bir sır Pod'a image/repo dışından iletiliyor — doğrulama
- [ ] TODO (Faz 3): repoda düz metin sır olmadığını gösteren tarama (leak) çıktısı
- [ ] TODO (Faz 3): "K8s Secret niçin tek başına yeterli değil" (yazılı)

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
Sır sızıntısı olmayan, harici referansla çalışan bir manifest + tarama kanıtı.

## ⏭️ Sırada
[`D4 — Supply Chain`](D4-supply-chain.md)

---

> *"En iyi sır, koda hiç girmemiş olandır."*
