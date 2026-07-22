# L08 — Metrik: Prometheus temeli ve cardinality tuzağı

> Modül: [`B2`](../../../block-b-visibility/B2-metrik-prometheus.md) · Süre: ~2 saat · Kırık lab: yok

Yerel bir Prometheus + node_exporter ayağa kaldırır, dört altın sinyalden en az
ikisini PromQL ile sorgular, sonra bilerek **yüksek-cardinality** bir etiket ekleyip
seri sayısının nasıl patladığını gözlemlersin. Cardinality, Prometheus'u öldüren
bir numaralı hatadır — bir kez gözünle görmen gerekir.

## Gerekenler
- **Container'dan önce olduğun için asıl yol systemd:** node_exporter + Prometheus'u
  A6 VM'inde systemd ile kur — tam adımlar [`B2` §3](../../../block-b-visibility/B2-metrik-prometheus.md)'te.
- **Hızlı yol (isteğe bağlı):** `docker` + `docker compose` varsa aşağıdaki yığını tek
  komutla ayağa kaldırırsın. Docker'ı **C1'de** öğreneceksin; buradaki `docker compose up -d`
  şimdilik yalnız hazır bir reçetedir, kavramı değil. Tarayıcı (Prometheus UI) gerekir.

## Görev

1. **Yığını başlat.** (systemd yolunu izlediysen node_exporter+Prometheus'u B2 §3'te
   zaten kurdun — bu docker adımını atla, doğrudan 2'ye geç.)
   ```bash
   cd starter && docker compose up -d
   # Prometheus:  http://127.0.0.1:9090
   # node-exporter hedefi otomatik scrape edilir.
   ```
2. **Hedefi doğrula.** Prometheus UI → Status → Targets: `node` hedefi `UP` olmalı.
3. **Altın sinyaller (en az 2).** PromQL ile sorgula ve sonucu `report.txt`'e yaz:
   - Doygunluk (saturation): CPU kullanımı, örn. `100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
   - Trafik: ağ, örn. `rate(node_network_receive_bytes_total[5m])`
   - (İsteğe bağlı) bellek doygunluğu: `node_memory_MemAvailable_bytes`
4. **Cardinality patlaması.** `starter/high_cardinality.py`'yi çalıştır (Prometheus onu da
   scrape eder). `CARD` değerini 10 → 1000 → 100000 yaparak yeniden başlat ve
   `count({__name__="lab_requests_total"})` ile seri sayısının nasıl büyüdüğünü gör.
   Neden `user_id` gibi bir etiketin metrik'e konması felakettir? `report.txt`'e yaz.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `report.txt` en az iki altın sinyal PromQL sorgusu ve sonucunu içeriyor.
- [ ] `report.txt` cardinality patlamasını sayıyla (seri adedi) ve sebebiyle açıklıyor.

## İpucu (çözüm değil)
- `rate()` sayaç (counter) metriklerinde kullanılır; gauge'da değil.
- Cardinality = etiket kombinasyonlarının çarpımı. `user_id` gibi **sınırsız** değerli
  bir etiket, her yeni değerde yeni bir zaman serisi yaratır → bellek patlar.
- Kural: etiket değerleri **sınırlı ve önceden bilinen** kümelerden olmalı (`method`,
  `status`, `region`) — kimlik/e-posta/id **asla**.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
