# L19 — SLO'ya bağlı bir alarm kur, bir kez ateşlet

> Modül: [`E2`](../../../block-e-ownership/E2-alerting-oncall.md) · Süre: ~3 saat · Kırık lab: yok

E1'de bir SLI seçip error budget'ı hesapladın. Burada o eşiği bir **alarma**
çevirirsin: hata oranı SLO'yu aştığında ateşleyen, çözülünce sönen bir kural.
Sonra alarmı "gece 3'te uyandırmalı mı?" testine göre **page / ticket / log**
diye sınıflar ve çözülmezse kime yükseleceğini (eskalasyon) yazarsın. Amaç kural
yazmak değil; **gürültü ile eylem çağıran alarmı ayırmak.**

## Gerekenler
- `docker` + `docker compose` (yerel; K8s **gerekmez**). Tarayıcı.

## Görev

1. **Alarm kuralını yaz.** `starter/alerts.yml` dosyasını sen oluştur. Hata oranı
   son 1 dakikada `%1`'i aşarsa ateşleyen bir kural yaz (app `%5` hatayla çalışır,
   yani eşiği geçecek):
   ```promql
   sum(rate(http_requests_total{status="500"}[1m]))
     / sum(rate(http_requests_total[1m])) > 0.01
   ```
2. **Alertmanager'ı yapılandır.** `starter/alertmanager.yml` dosyasını sen oluştur:
   bir `route` + bir `receiver` yeter (dış entegrasyon şart değil; alarm Alertmanager
   içinde "active" görünür).
3. **Yığını başlat, alarmı gör.**
   ```bash
   cd starter && docker compose up -d
   # Prometheus:     http://127.0.0.1:9090  (Status → Rules, Alerts)
   # Alertmanager:   http://127.0.0.1:9093
   ```
   `for:` süresi dolunca alarm `PENDING → FIRING` olur. Ateşlediğini bir yerden
   **kanıtla** (Prometheus Alerts sekmesi veya Alertmanager UI) ve `report.txt`'e yaz.
4. **Sınıflandır.** Bu alarmı ve en az iki örnek alarmı (biri kasıtlı **gürültü**,
   ör. "CPU %80") `report.txt`'te bir tabloyla page / ticket / log diye ayır. Her
   satıra bir cümle gerekçe.
5. **Eskalasyon.** Alarm 15 dk içinde ack'lenmezse kime/nereye yükseleceğini bir
   cümleyle `report.txt`'e yaz.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `starter/alerts.yml` `http_requests_total` üzerine kurulu, ateşleyen bir alarm içeriyor.
- [ ] `starter/alertmanager.yml` bir `route` + `receiver` içeriyor.
- [ ] `report.txt` alarmın ateşlediğinin kanıtını içeriyor (Prometheus/Alertmanager çıktısı).
- [ ] `report.txt` page/ticket/log sınıflandırma tablosunu (biri gürültü örneği) ve eskalasyon kuralını içeriyor.

## İpucu (çözüm değil)
- Alarm **semptoma** bağlanmalı (kullanıcı etkisi = hata oranı), sebebe değil
  (CPU). "CPU %80" tek başına gece uyandırmaz — o bir ticket/log'dur.
- `for: 1m` alarmın anlık dalgalanmada değil, süregelen ihlalde ateşlemesini sağlar.
- Alertmanager'da alıcı boş bir `receiver` olabilir; alarm yine `active` görünür.
  Dış bildirim kurmana gerek yok — burada ölçtüğün şey **kural**, kanal değil.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
