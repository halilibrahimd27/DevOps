---
description: "SLI / SLO / error budget: bir sistemin 'yeterince iyi'sini sayıyla tanımlamak — sahiplik buradan başlar."
level: E
module: E1
estimated_hours: 12
prerequisites: [B2, D2]
tags: [Learning Path, SRE]
---
# E1 — SLI / SLO / Error Budget

> *"'Sistem sağlıklı mı?' sorusunun mühendislik cevabı bir histen değil, bir sayıdan gelir."*

**Blok:** E — Sahiplik · **Süre:** ~12 saat · **Ön koşul:** [`B2`](../block-b-visibility/B2-metrik-prometheus.md), [`D2`](../block-d-orchestration/D2-k8s-production.md)

## 🎯 Bu modülü bitirdiğinde
- Bir servis için anlamlı bir SLI (gösterge) seçer ve niçin onu seçtiğini savunursun.
- Bir SLO (hedef) belirler ve error budget'ı hesaplarsın.
- Error budget tükendiğinde ne değişmesi gerektiğini (yayın durur mu) açıklarsın.

## 🧠 Niye bu, niye şimdi
B2'de metrikleri, D2'de production ayarlarını kurdun. E1 bu metrikleri bir
**sahiplik sözleşmesine** çevirir: neyin "yeterince iyi" olduğunu sen tanımlarsın.
Bütçe sabit değildir: ne kadar hızlı tükendiğine **burn rate** (yakma hızı) denir —
normal hızın kaç katıyla harcanıyor. E2'deki alerting bu SLO'ların ve burn rate'in
üstüne kurulur.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`11-SRE/SLI-SLO-Error-Budget.md`](../../11-SRE/SLI-SLO-Error-Budget.md) | kavram + matematik | ~35 dk |
| [`07-Observability/SLO-Engineering.md`](../../07-Observability/SLO-Engineering.md) | pratiğe dökme | ~25 dk |

## 🔨 Lab
👉 [`labs/build/L18-sli-slo/`](../labs/build/L18-sli-slo/README.md)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] Bir servis için bir SLI seçildi (ör. istek başarı oranı) ve Prometheus'ta ölçülüyor — sorgu/panel çıktısıyla kanıt
- [ ] Bu SLI için bir SLO (ör. 30 gün %99.9) ve karşılık gelen error budget (dk/ay) yazılı hesaplandı
- [ ] Error budget tükendiğinde ne değişeceği (yayın durur mu, işe ne öncelik verilir) bir cümleyle yazılı savunuldu

## 🧪 Kendini test et
1. `%99.9` aylık bir SLO'nun error budget'ı yaklaşık kaç dakikadır ve bu bütçe neyi "satın alır"?
2. Neden availability SLI'ı için "sunucu ayakta mı" değil de "kullanıcı isteği başardı mı" ölçülür?
3. Error budget'ın %80'i ayın 10'unda tükendi. Takım daha hızlı mı yayın yapmalı, yavaş mı — niçin?

<details><summary>Cevaplar</summary>

1. %99.9 → ayda %0.1 → 30 gün için ~43 dk. Bu bütçe, planlı riski (yayın, deney) bilinçli harcadığın bir paydır; sıfır hedeflemek yerine kalanı gözle harcarsın. Matematik [`11-SRE/SLI-SLO-Error-Budget.md`](../../11-SRE/SLI-SLO-Error-Budget.md)'de.
2. Çünkü kullanıcı sunucunun ayakta olmasını değil, isteğinin çalışmasını umursar. Sunucu `Running` ama 500 dönüyorsa "sunucu ayakta" SLI'ı sağlıklı der, kullanıcı mutsuzdur — SLI kullanıcı deneyimine bağlanmalı. Pratiğe dökme [`07-Observability/SLO-Engineering.md`](../../07-Observability/SLO-Engineering.md)'de.
3. Yavaşlamalı. Bütçe bitmek üzereyken risk iştahı düşer: yayın dondurulur, öncelik güvenilirliğe kayar. Bütçe bolsa tersine hızlanılabilir — SLO bir hız↔güvenilirlik pazarlığıdır, his değil.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| SLI hep %100 görünüyor | Yanlış tarafı (health-check) ölçüyorsun | Gerçek kullanıcı isteğinin sonucunu ölç; sentetik prob tek başına yetmez |
| Error budget hesabı tutmuyor | Pencere/oran karışık (haftalık↔aylık) | Sabit bir pencere seç (ör. 30 gün rolling), oranı ona göre çevir |
| SLO ekipçe takılmıyor | Hedef keyfi, kullanıcıyla bağı yok | Mevcut performansı ölç, hedefi ona +biraz koy; kullanıcı etkisini yaz |

## 💼 Portfolyo çıktısı
Bir servis için yazılı SLI/SLO tanımı + error budget hesabı.

## ⏭️ Sırada
[`E2 — Alerting + On-Call`](E2-alerting-oncall.md)

---

> *"%100 uptime bir hedef değil, bir yanılsamadır; error budget o yanılsamayı bir bütçeye çevirir."*
