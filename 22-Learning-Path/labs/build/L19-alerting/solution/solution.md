# L19 — Referans çözüm

> **Önce kendin dene.** Alarm kuralı yazmak kolay; **hangi alarmın page, hangisinin
> ticket olduğuna** karar vermek zordur — asıl ders orada.

## 1. Alarm kuralı (`starter/alerts.yml`)

Bu repodaki [`alerts.yml`](alerts.yml) dosyasını `starter/alerts.yml`'e kopyala.
Özü: hata oranı son 1 dk `%1`'i aşarsa `for: 1m` sonra `FIRING`.

```promql
sum(rate(http_requests_total{status="500"}[1m]))
  / sum(rate(http_requests_total[1m])) > 0.01
```

App `ERROR_RATE=0.05` (%5) ile çalışır → eşiği rahatça geçer → alarm ateşler.

## 2. Alertmanager (`starter/alertmanager.yml`)

[`alertmanager.yml`](alertmanager.yml)'i kopyala. Boş bir `receiver` yeter; alarm
Alertmanager'da `active` görünür. Kanal (Slack/e-posta) burada tanımlanır ama
lab'da test edilen şey **kural**, kanal değil.

## 3. Ateşlediğini kanıtla

```bash
cd starter && docker compose up -d
# Prometheus → Alerts:  YuksekHataOrani  PENDING → FIRING (~1 dk)
curl -s http://127.0.0.1:9090/api/v1/alerts | grep -o '"state":"[a-z]*"'
curl -s http://127.0.0.1:9093/api/v2/alerts | head -c 200
```
`report.txt`'e `FIRING` çıktısını yapıştır.

## 4. Sınıflandırma — asıl ders

| Alarm | Sınıf | Niçin |
|---|---|---|
| Hata oranı budget'ı hızla yakıyor | **page** | Kullanıcı etkili, eyleme çağırır, geciktirilemez |
| Disk 30 gün içinde dolacak | **ticket** | Gerçek ama acil değil; mesai içinde çözülür |
| CPU %80 | **log** | Tek başına eylem gerektirmez; sık gürültü, sadece kayıt |

"CPU %80" kasıtlı **gürültü** örneğidir: sebebe (cause) bağlı, semptoma değil.
Sık ateşler, çoğu zaman kendiliğinden düşer → görevliyi köreltir. Page yalnızca
**kullanıcı etkili + actionable** olana verilir.

## 5. Eskalasyon

Page 15 dk içinde ack'lenmezse ikincil nöbetçiye (secondary on-call), o da 15 dk
içinde yanıtlamazsa ekip liderine yükselir. Susturma (silence) yalnız bilinçli,
süreli ve denetim kaydı bırakan bir işlem olur — semptomu gizlemek için değil.

## Ders

Alarmın değeri kuralın zarafetinde değil, **doğru sınıfta** olmasındadır. Her şeye
page koymak, hiçbir şeye page koymamakla aynı sonucu verir: görevli artık bakmaz.
İyi bir alarm bir soru sormaz, bir eylem söyler.
