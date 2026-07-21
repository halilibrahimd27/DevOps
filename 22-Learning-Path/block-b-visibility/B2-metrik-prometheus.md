---
description: "Metrik: Prometheus temeli, neyi ölçersin ve cardinality — bir sistemin nabzını sayılarla tutmak."
level: B
module: B2
estimated_hours: 12
prerequisites: [A6, B1]
tags: [Learning Path, Observability]
---
# B2 — Metrik: Prometheus Temeli, Cardinality

> *"Log bir olayı anlatır; metrik bir eğilimi gösterir. İkisi de olmadan tahmin edersin."*

**Blok:** B — Görebilmek · **Süre:** ~12 saat · **Ön koşul:** [`A6`](../block-a-intuition/A6-elle-deploy.md), [`B1`](B1-log-okuma.md)

## 🎯 Bu modülü bitirdiğinde
- VM'de bir exporter çalıştırıp Prometheus'un metriği nasıl topladığını gösterirsin.
- İlk PromQL sorgunu yazar, bir sistemin temel sağlık göstergesini okursun.
- Cardinality'nin niçin bir maliyet ve risk olduğunu, hangi etiketten kaçınacağını açıklarsın.

## 🧠 Niye bu, niye şimdi
B1'de olayı gördün; B2'de eğilimi görürsün. E1'deki SLO'lar bu metriklerin üstüne
kurulur. Bu modül **container'dan önce**, VM üzerinde çalışır — K8s tabanlı
kurulum burada değil, D bloğundadır.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| (giriş gövdesi — Faz 2: metrik nedir, exporter, ilk PromQL) | temel | — |
| [`07-Observability/Prometheus-Best-Practices.md`](../../07-Observability/Prometheus-Best-Practices.md) | cardinality + adlandırma | ~30 dk |

## 🔨 Lab
👉 `labs/build/L08-metrik/` — Faz 5'te oluşturulacak.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 2): VM'de exporter çalışıyor, Prometheus onu topluyor — doğrulama
- [ ] TODO (Faz 2): bir sağlık göstergesini döndüren PromQL sorgusu + çıktı
- [ ] TODO (Faz 2): "yüksek cardinality'ye yol açan bir etiket örneği ve niçin kaçınılır" (yazılı)

## 🧪 Kendini test et
1. TODO (Faz 2)
2. TODO (Faz 2)
3. TODO (Faz 2)

<details><summary>Cevaplar</summary>TODO (Faz 2)</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| TODO | TODO | TODO |

## 💼 Portfolyo çıktısı
Çalışan bir temel metrik kurulumu — E1'de SLO'ya evrilecek.

## ⏭️ Sırada
[`B3 — İlk Kırık Lab`](B3-ilk-kirik-lab.md)

---

> *"Her şeyi ölçemezsin; neyi ölçmediğini bilmek de bir karardır."*
