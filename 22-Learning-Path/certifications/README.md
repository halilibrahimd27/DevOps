---
description: "Öğrenme patikasının tek sertifika duruşu: 3 kapı, 10 değil. Sertifika patikayı bitirdiğinin dış doğrulamasıdır, yerine geçmez."
tags:
  - Learning Path
  - Sertifika
---
# Sertifikalar — 3 Kapı, 10 Değil

> *"Sertifika, patikayı bitirdiğinin dış doğrulamasıdır — yerine geçmez."*

> ⏳ **Sürüm uyarısı:** Sınav müfredatı ve tool sürümleri değişir. Bu sayfa 2026-07-22
> itibarıyla doğrudur; resmi kaynakla çeliştiğinde **resmi kaynak doğrudur**.

Bu sayfa reponun sertifika konusundaki **tek** duruşunu ilan eder. Sertifika ne zaman
işe yarar, ne zaman zaman kaybıdır ve bu patikanın neden 10 değil 3 sınav önerdiğini
okuduğunda bileceksin. Sertifika arayan biri buradan başlar; başka sayfada çelişen bir
cümle bulmayacak.

---

## 🎯 Duruş

Sertifika **bir kapıdır, hedef değil.** Kapı şunu doğrular: "bu bloğu gerçekten
bitirdim, kendi beyanımdan bağımsız bir dış ölçüt de onayladı." Kapı olmadan da blok
biter; kapı yalnız **dışarıya kanıt** üretir (mülakat, ilk iş, ekip içi güven).

Üç kapı, blok sınırlarına oturur:

| Kapı | Ne zaman | Sertifika | Niye burada |
|---|---|---|---|
| [`G1`](G1-kcna-terraform.md) | Blok C sonu | **KCNA** *veya* **Terraform Associate** | Ucuz, çoktan seçmeli, ilk dış doğrulama |
| [`G2`](G2-cka.md) | Blok D sonu | **CKA** | Performansa dayalı; canlı cluster'da iş görürsün |
| [`G3`](G3-cks-aws-saa.md) | Blok E sonu | **CKS** *veya* **AWS SAA** | Dal seçimi: güvenlik derinliği mi, bulut genişliği mi |

Sırayı **atlamazsın.** G2 (CKA) canlı bir cluster'da 2 saat iş yapmanı ister; Blok D
bitmeden bu sınav seni yener. G3 (CKS dalı) geçerli bir CKA şart koşar. Kapılar
patikanın bağımlılık zincirini takip eder, takvimi değil.

---

## 🚫 Niye 10 değil 3

Sertifika **koleksiyonu** bir anti-pattern'dir — bu reponun `RoadMap/README.md`'de de
söylediği şey. 48 ayda 10 sertifika toplamak CV'yi şişirir, mühendis yetiştirmez.

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "En değerli 10 sertifikayı sırayla al" | Her biri hazırlık+sınav; toplamda yıllar, üretilen kanıt tekrar eder | Blok başına 1 kapı: 3 farklı yetkinliği doğrular |
| Aynı alanda üst üste sertifika (CKA+CKAD+CKS peş peşe) | CKAD, CKA'nın alt kümesini test eder; ikisi birden CV süsü | Bir orchestration kapısı (CKA), sonra bir dal (CKS) |
| Deneyimsiz professional sınav (AWS DevOps Pro, junior'ken) | Associate'i ve gerçek işi atlayıp üst seviye ezberlemek | Önce blok, sonra kapı; professional çok sonra |
| Sertifikayı iş/yetkinlik yerine koymak | Sınav laboratuvarı ölçer, production'ı değil | Kapı = blok bitti kanıtı; production'ı iş öğretir |
| "Şu sertifika şu kadar getiri sağlar" | Doğrulanamaz vaat; piyasa kişiye/kuruma göre değişir | Sertifika yalnız "bildiğini gösterir", söz vermez |

Bir sertifika seni bir seviyeye **çıkarmaz** — seviyeni deneyim, kurum ve piyasa
belirler. Sertifika yalnız o an bir şeyi bildiğinin dış işaretidir. Bu ayrımı bu
sayfada net tutuyoruz çünkü sertifika satan her yer tersini söyler.

---

## 🗺️ Neyi nerede okursun

| Dosya | Ne için |
|---|---|
| [`G1-kcna-terraform.md`](G1-kcna-terraform.md) | Blok C kapısı: hazır mısın, ne ölçer, hangi modüller karşılar |
| [`G2-cka.md`](G2-cka.md) | Blok D kapısı: CKA — performans sınavı mekaniği |
| [`G3-cks-aws-saa.md`](G3-cks-aws-saa.md) | Blok E kapısı: CKS *veya* AWS SAA dal seçimi |
| [`HOW-TO-CERTIFY.md`](HOW-TO-CERTIFY.md) | Sınava hazırlanmanın **kendisi** bir beceri: müfredat eşleme, aktif hatırlama, zaman yönetimi, ne zaman girilmez |

---

## 🚪 Bu patikanın parçası olmayan sertifikalar

3 kapı bir **seçim**dir, koleksiyon değil. Aşağıdakiler kasıtlı olarak dışarıda —
neyi niye ertelediğimiz [`../NOT-YET.md`](../NOT-YET.md)'de:

- **CKAD** — CKA'nın alt kümesini test eder; ikisi birden CV süsü.
- **AWS DevOps Pro / GCP Professional** — professional seviye; associate'i ve gerçek işi atlamak. Çok sonra.
- **Vault Associate, Prometheus (PCA)** — dar araç sınavları; blok kapısı değil, merak.

> ⚠️ **Docker DCA** öneri listesinde **yok.** 2019'da Mirantis'e devredildi; bugünkü
> statüsü kaynaklarda çelişkili ve piyasa Linux Foundation Kubernetes hattına (CKA/CKS)
> kaydı. Legacy / tartışmalı statü — bir kenarda not olarak kalır, kapı değil.

---

## 📋 Sertifikaya girmeden önce checklist

```
[ ] İlgili bloğun tüm modül kabul kriterlerini geçtim (kendi beyanım değil, komut çıktısı)
[ ] O bloğun STAGE-EXAM.md'sini çözdüm
[ ] Kapının "Hazır olduğunu nereden anlarsın" sinyalini objektif olarak karşıladım
[ ] Resmi müfredatı (tek gerçek kaynak) okudum, bu sayfayı değil
[ ] Pratik ortamımı yerelde (kind/k3s/LocalStack) kurdum, para harcamadan
[ ] Sınav ücretini ve indirim takvimini kontrol ettim (resmi sayfa)
```

---

## 📚 Referanslar
- [Linux Foundation Training & Certification](https://training.linuxfoundation.org/certification-catalog/) — KCNA, CKA, CKS resmi kaynağı
- [CNCF Certification](https://www.cncf.io/training/certification/)
- [HashiCorp Certifications](https://developer.hashicorp.com/certifications) — Terraform Associate
- [AWS Certification](https://aws.amazon.com/certification/) — Solutions Architect Associate
- Repo içi: [`../CURRICULUM.md`](../CURRICULUM.md) · [`../../RoadMap/README.md`](../../RoadMap/README.md) · [`../../18-Career/CV-Tips.md`](../../18-Career/CV-Tips.md)

---

> *"Kapıyı geç, ama kapının senin yerine iş yapmasını bekleme. Kapı der ki 'bu kişi
> girdi'; ne yaptığını hâlâ sen gösterirsin."*
