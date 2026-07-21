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
- [ ] Bir sır Pod'a image/repo dışından (Secret referansı / harici store) iletiliyor — `kubectl` / uygulama kanıtı
- [ ] Repoda düz metin sır olmadığını gösteren bir tarama (ör. gitleaks / `trivy fs`) çıktısı
- [ ] "K8s Secret niçin tek başına yeterli değil (varsayılan sadece base64, şifreleme değil)" — yazılı
- [ ] Bir sırrı GitOps akışına düz metin koymadan taşımanın en az bir yolunu anlatabiliyorsun

## 🧪 Kendini test et
1. K8s Secret varsayılanda veriyi nasıl saklar; base64 niçin "güvenlik" değildir?
2. Bir sır yanlışlıkla commit edildi ve sonra silindi. Niçin hâlâ sızmış sayılır, ne yaparsın?
3. GitOps'ta "her şey Git'te" ilkesiyle "sır Git'te olmamalı" kuralını nasıl uzlaştırırsın?

<details><summary>Cevaplar</summary>

1. Varsayılanda base64 **kodlanmış** olarak etcd'de durur — base64 geri çevrilebilir bir kodlamadır, şifreleme değildir; erişimi olan herkes okur. Gerçek koruma için etcd şifrelemesi ve/veya harici bir secret store gerekir. Desenler [`08-Security/Secrets-Management.md`](../../08-Security/Secrets-Management.md)'de.
2. Git geçmişi kalıcıdır: silsen de eski commit'te durur, klonlayan herkes görebilir. Doğru refleks dosyayı silmek değil, **sırrı iptal edip yenilemek (rotate)** — çünkü sızmış bir sır artık güvenilmez.
3. Sırrın kendisini değil, ona bir **referansı** ya da **şifreli** hâlini Git'e koyarsın: Sealed Secrets (şifreli), harici secret store + `secretKeyRef`, ya da SOPS. Karar [`06-GitOps/Secrets-in-GitOps.md`](../../06-GitOps/Secrets-in-GitOps.md)'de.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Pod sırra erişemiyor | Secret adı/anahtarı yanlış ya da namespace farklı | `secretKeyRef` ad + anahtarını ve namespace'i doğrula |
| Sır loglarda görünüyor | Uygulama env'i / hata mesajını logluyor | Sır loglamayı kapat; env yerine dosya olarak mount etmeyi değerlendir |
| Repoda sır yakalandı | Düz metin commit | Sırrı iptal et/rotate; geçmişi temizlemek tek başına yetmez |
| GitOps sırrı düz metin istiyor | Şifreleme katmanı yok | Sealed Secrets / harici store + referans kullan |

## 💼 Portfolyo çıktısı
Sır sızıntısı olmayan, harici referansla çalışan bir manifest + tarama kanıtı.

## ⏭️ Sırada
[`D4 — Supply Chain`](D4-supply-chain.md)

---

> *"En iyi sır, koda hiç girmemiş olandır."*
