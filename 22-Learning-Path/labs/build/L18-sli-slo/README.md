# L18 — SLI seç, SLO belirle, error budget'ı hesapla

> Modül: [`E1`](../../../block-e-ownership/E1-sli-slo-error-budget.md) · Süre: ~3 saat · Kırık lab: yok

Bir servisin "yeterince iyi"sini bir histen değil bir **sayıdan** okumayı burada
kurarsın. Kendi trafiğini üreten bir servisi Prometheus'la ölçer, bir başarı-oranı
SLI'ı seçer, bir SLO belirler ve o SLO'nun sana kaç dakikalık **error budget**
verdiğini hesaplarsın. Sonra ölçülen SLI ile hedefi karşılaştırıp bütçenin ne hızda
yandığına bakarsın.

## Gerekenler
- `docker` + `docker compose` (yerel; K8s **gerekmez**). Tarayıcı (Prometheus UI).

## Görev

1. **Yığını başlat.**
   ```bash
   cd starter && docker compose up -d
   # Prometheus:  http://127.0.0.1:9090
   # app hedefi (kendi trafiğini üretir) otomatik scrape edilir.
   ```
2. **Hedefi doğrula.** Prometheus UI → Status → Targets: `app` hedefi `UP` olmalı.
   Birkaç dakika bekle ki `rate()` anlamlı bir pencere görsün.
3. **SLI'ı seç ve ölç.** Başarı oranını (5xx olmayan istek / tüm istek) PromQL ile
   sorgula, sonucu `report.txt`'e yaz:
   ```promql
   sum(rate(http_requests_total{status!~"5.."}[5m]))
     / sum(rate(http_requests_total[5m]))
   ```
   Niçin "sunucu ayakta mı" değil de "istek başardı mı" ölçüyorsun? Bir cümleyle yaz.
4. **SLO belirle + error budget hesapla.** Bir aylık (30 gün) SLO seç (ör. `%99.9`).
   O SLO'nun izin verdiği error budget'ı **dakika/ay** olarak elle hesapla ve
   `report.txt`'e yaz. (İpucu: 30 gün = 43 200 dk.)
5. **Bütçe yanıyor mu?** Ölçülen SLI'ını (bu lab'da ~%99.5) seçtiğin SLO ile
   karşılaştır. Bütçe tükeniyorsa **ne değişmeli** (yayın durur mu, öncelik nereye kayar)?
   Bir cümleyle `report.txt`'e yaz.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `report.txt` başarı-oranı SLI'ının PromQL sorgusunu ve sonucunu içeriyor.
- [ ] `report.txt` seçilen SLO'yu (%99.x) ve error budget'ı **dakika/ay** olarak hesaplı içeriyor.
- [ ] `report.txt` bütçe tükendiğinde ne değişeceğini bir cümleyle savunuyor.

## İpucu (çözüm değil)
- SLI = kullanıcı deneyimine bağlı bir oran. Sağlık probu tek başına SLI değildir —
  sunucu `Running` ama 500 dönüyorsa kullanıcı için servis çalışmıyordur.
- Error budget = `(1 − SLO) × pencere`. `%99.9` × 30 gün → `0.001 × 43 200 dk`.
- `rate(...[5m])` sayaç (counter) için; 5 dk'lık kayar pencerede saniyelik ortalama.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
