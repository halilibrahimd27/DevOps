---
description: "Maliyet ve trade-off (FinOps): aynı sistemlere para gözüyle bakmak — üçüncü bakışın ilk adımı."
level: F
module: F1
estimated_hours: 10
prerequisites: [C4, D2]
tags: [Learning Path, FinOps]
---
# F1 — Maliyet ve Trade-off (FinOps)

> *"Aynı cluster'a D'de nasıl çalıştığı için baktın; F'de ne kadara mal olduğu için bakıyorsun."*

**Blok:** F — Karar · **Süre:** ~10 saat · **Ön koşul:** [`C4`](../block-c-reproducibility/C4-bulut-butce-alarmi.md), [`D2`](../block-d-orchestration/D2-k8s-production.md)

## 🎯 Bu modülü bitirdiğinde
- Bir iş yükünün maliyetini bileşenlerine ayırır (compute, depolama, ağ/egress) hesaplarsın.
- Right-sizing / spot / reserved gibi bir trade-off'u sayıyla gerekçelendirirsin.
- Bir maliyet kararını mühendislik ve iş dilinde birlikte savunursun.

## 🧠 Niye bu, niye şimdi
Bu blok A–E'nin devamı değil, **üçüncü bakıştır.** Aynı sistemlere şimdi para
gözüyle bakılır. C4'te bütçe alarmını kurdun; F1 o farkındalığı bir karar
disiplinine çevirir.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`12-FinOps/README.md`](../../12-FinOps/README.md) | maliyet eksenleri: compute / depolama / egress, birim maliyet | ~30 dk |
| [`12-FinOps/Right-Sizing.md`](../../12-FinOps/Right-Sizing.md) | D2'deki request/limit'i faturaya bağlamak, over-provisioning | ~25 dk |
| [`12-FinOps/Spot-Instance-Strategy.md`](../../12-FinOps/Spot-Instance-Strategy.md) | spot / reserved / on-demand trade-off'u | ~20 dk |

## 🔨 Teslim edilebilir egzersiz
Bu modül saf okuma değildir; çıktısı yazılı bir analizdir. Bir iş yükü seç — D2'de
çalıştırdığın uygulama ya da [`Capstone 1`](../capstones/CAP1-blok-c-sonu.md)/[`Capstone 2`](../capstones/CAP2-blok-d-sonu.md) sistemin. `finops-analiz.md` yaz:
1. Maliyeti üç eksene ayır (compute, depolama, ağ/egress) — senaryo değerleriyle, gerçek fatura değil.
2. Bir birim maliyet hesapla (1000 istek başına ya da GB-ay) — varsayımlarını yaz.
3. Bir optimizasyon öner (right-sizing / spot / depolama sınıfı) ve tasarrufu **mutlak farkla** göster (önce → sonra).
4. Aynı kararı bir paragrafta iş tarafına savun (teknik + iş dili).

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] `finops-analiz.md`'de maliyet üç eksene (compute / depolama / egress) ayrılmış bir tablo var
- [ ] Bir birim maliyet sayıyla hesaplandı ve altındaki varsayımlar yazılı
- [ ] Bir optimizasyon önerisi önce → sonra mutlak farkıyla gerekçelendirildi (yüzde değil, mutlak sayı)
- [ ] Aynı karar `finops-analiz.md` içinde ayrı bir "İş tarafı" paragrafında iş diliyle savunuldu (aylık maliyet + kesinti/risk sonucu — yalnız teknik terim değil)

## 🧪 Kendini test et
1. Compute maliyeti sabitken egress faturası niçin sürpriz yapar ve nasıl daraltılır?
2. Bir servis CPU'sunun sekizde birini kullanıyor ama 2 vCPU reserve edilmiş. İlk üç kontrolün ne?
3. Gece çalışan, kesintiye toleranslı bir batch işi için spot / on-demand / reserved'dan hangisini seçerdin, niçin?

<details><summary>Cevaplar</summary>

1. Egress çoğu bulutta ayrı fiyatlanır ve cluster-içi/AZ-arası/internete-çıkış trafiği farklı ücretlenir; bir servis fazla veri dışarı gönderiyorsa compute sabit kalsa da fatura şişer. Daraltma: veri yerelleştirme, cache, sıkıştırma — [`12-FinOps/Egress-Cost-Reduction.md`](../../12-FinOps/Egress-Cost-Reduction.md).
2. Gerçek kullanımı ölç (D2'deki metrikler / `kubectl top`), request'i gerçek kullanıma yaklaştır, sonra node tipini/sayısını gözden geçir. Right-sizing önce ölçüm ister — [`12-FinOps/Right-Sizing.md`](../../12-FinOps/Right-Sizing.md).
3. Spot: kesintiye toleranslı ve yeniden başlatılabilir iş için en ucuzu, kesinti riskini iş tasarımı karşılıyor. On-demand esneklik ister, reserved öngörülebilir sürekli yük içindir. Batch + toleranslı → spot mantıklı — [`12-FinOps/Spot-Instance-Strategy.md`](../../12-FinOps/Spot-Instance-Strategy.md).
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Maliyeti eksenlere ayıramıyorsun | Tek bir toplam rakama bakıyorsun | Faturayı compute / depolama / ağ olarak üçe böl; her birini ayrı satıra yaz |
| "Tasarruf" sayı vermeden söyleniyor | Önce/sonra ölçülmemiş | Değişiklikten önceki ve sonraki maliyeti ayrı yaz, farkı mutlak sayıyla göster |
| Right-sizing tahminle yapılıyor | Gerçek kullanım ölçülmedi | Metriğe dön (B2/D2); request'i p95 kullanıma göre ayarla, tahminle değil |
| İş tarafı ikna olmuyor | Yalnız teknik dil kullanıldı | Kararı "aylık X birim, kesinti riski Y" gibi iş sonucuna çevir |

## 💼 Portfolyo çıktısı
Bir maliyet analizi + optimizasyon önerisi — L2 karar vericiliğinin kanıtı.

## ⏭️ Sırada
[`F2 — Tehdit Modelleme + Uyum`](F2-tehdit-uyum.md)

---

> *"En ucuz mimari değil, doğru trade-off'u bilerek seçilmiş mimari kazanır."*
