# L18 — Referans çözüm

> **Önce kendin dene.** Error budget'ı elle hesaplamadan "43 dakika" bir sayı değil,
> ezber olur.

## 1. Yığın
```bash
cd starter && docker compose up -d
# http://127.0.0.1:9090 → Status → Targets → app UP
```

## 2. Başarı-oranı SLI'ı (PromQL)
```promql
sum(rate(http_requests_total{status!~"5.."}[5m]))
  / sum(rate(http_requests_total[5m]))
```
Bu oran ~`0.995` (yani %99.5) döner, çünkü app `ERROR_RATE=0.005` ile çalışıyor.

**Niçin bu tarafı ölçüyoruz:** kullanıcı sunucunun ayakta olmasını değil, isteğinin
sonuç vermesini umursar. "Sunucu ayakta mı" probu yeşilken app 500 dönebilir; SLI
kullanıcının gerçekten aldığı sonuca bağlanmalı.

## 3. SLO + error budget hesabı

Pencere = 30 gün = **43 200 dakika**. Budget = `(1 − SLO) × pencere`:

| SLO (30 gün) | İzin verilen hata | Error budget |
|---|---|---|
| %99.0 | %1.0 | ~432 dk (~7.2 saat) |
| %99.9 | %0.1 | ~43.2 dk |
| %99.95 | %0.05 | ~21.6 dk |
| %99.99 | %0.01 | ~4.32 dk |

Örnek seçim: **SLO = %99.9 → error budget ≈ 43 dk/ay.** Bu bütçe, planlı riski
(yayın, deney) bilinçli harcadığın bir paydır — sıfır hata hedeflemek yerine kalanı
gözle harcarsın.

> Matematik ve niçin sıfır hedeflenmediği: [`11-SRE/SLI-SLO-Error-Budget.md`](../../../../../11-SRE/SLI-SLO-Error-Budget.md).

## 4. Bütçe yanıyor mu?

Ölçülen SLI %99.5, hedef %99.9. Ölçülen değer hedefin **altında** → bu ay için ayrılan
43 dk'lık bütçe zaten aşılmış demektir. Prometheus'ta 30 günlük hata bütçesi kalanını
şöyle görebilirsin:
```promql
1 - (
  (1 - sum(rate(http_requests_total{status!~"5.."}[30d])) / sum(rate(http_requests_total[30d])))
  / (1 - 0.999)
)
```
Sonuç negatifse bütçe bitmiş, pozitifse kalan pay oranıdır.

## Bütçe tükendiğinde ne değişir
Bütçe bittiğinde risk iştahı düşer: **yeni özellik yayınları dondurulur**, öncelik
güvenilirlik işine (hata kaynağını gidermek, alarm/otomatik geri-alma eklemek) kayar.
Bütçe bolsa tersi geçerlidir — daha hızlı yayın yapılabilir. SLO bir his değil, bir
hız↔güvenilirlik pazarlığıdır ve bu pazarlığı bütçe yürütür.

## Ders
"Sistem sağlıklı mı?" sorusunun mühendislik cevabı bir SLI değerinden gelir; o değerin
"yeterli mi" olması bir SLO'ya, o SLO'nun sana verdiği hareket alanı da bir dakikalık
bütçeye çevrilir. Üçü olmadan güvenilirlik tartışması hisle yapılır.
