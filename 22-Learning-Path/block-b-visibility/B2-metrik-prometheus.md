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
- A6'daki VM'de bir exporter çalıştırıp Prometheus'un metriği nasıl **çekerek** (pull) topladığını gösterirsin.
- İlk PromQL sorgunu yazar, bir sistemin temel sağlık göstergesini (CPU, bellek, istek hızı) okursun.
- Cardinality'nin niçin bir maliyet ve risk olduğunu ve hangi etiketten kaçınacağını açıklarsın.

## 🧠 Niye bu, niye şimdi
B1'de tek bir **olayı** gördün: "şu istek şu anda başarısız oldu". Ama "son bir saatte
hata oranı arttı mı?" sorusunu log tek tek okuyarak yanıtlayamazsın — bu bir **eğilim**dir
ve metrik işidir. E1'deki SLO'lar (hata bütçesi, latency hedefleri) doğrudan bu metriklerin
üstüne kurulur; ölçmediğin şeye SLO koyamazsın. Bu modül **container'dan önce**, A6'daki
VM üzerinde çalışır; K8s tabanlı Prometheus kurulumu D bloğundadır.

## 📖 Nasıl çalışılır
A6 VM'inde node_exporter + Prometheus'u elle kur, tarayıcıdan Prometheus arayüzünü aç ve
sorguları orada dene. Her metriği **gör**: `up`, `node_cpu_seconds_total`. Cardinality
derinliğini [`Prometheus-Best-Practices.md`](../../07-Observability/Prometheus-Best-Practices.md)'ten
oku — bu modül seni oraya okuyabilecek düzeye getirir, tekrarını yapmaz.

## 📚 Kavram haritası
| Terim | Bir cümlede |
|---|---|
| **Metrik** | Zamanla değişen, sayısal bir ölçüm (CPU %, istek sayısı, gecikme) |
| **Pull modeli** | Prometheus hedeflerin `/metrics` ucundan veriyi **çeker** (uygulama itmez) |
| **Exporter** | Bir sistemin durumunu Prometheus'un okuyacağı biçimde sunan aracı (ör. node_exporter) |
| **Label (etiket)** | Metriği boyutlandıran anahtar-değer (ör. `method="GET"`) |
| **Cardinality** | Bir metriğin etiket kombinasyonlarının sayısı — patlarsa Prometheus'u boğar |
| **PromQL** | Prometheus'un sorgu dili |
| **Counter / Gauge / Histogram** | Üç temel metrik türü |

---

## 1️⃣ Metrik nedir, log'dan farkı ne

Log bir **olay** kaydıdır ("10:03:12'de istek başarısız"). Metrik ise bir **sayının
zaman içindeki değeri**dir: her 15 saniyede bir "şu an aktif bağlantı: 42", "toplam
istek: 19.204". Log'la "şu an ne oldu"yu, metrikle "eğilim ne" sorusunu yanıtlarsın.

| | Log | Metrik |
|---|---|---|
| Birim | Tek olay | Zamana yayılı sayı |
| Sorusu | "Tam olarak ne oldu?" | "Ne kadar / ne sıklıkla / eğilim ne?" |
| Maliyet | Satır sayısıyla büyür | Seri (etiket kombinasyonu) sayısıyla büyür |
| Örnek | "Login başarısız (u_123)" | "Son 5 dk login hata oranı: %2" |

## 2️⃣ Pull modeli: Prometheus çeker, uygulama itmez

Prometheus, izlediği her hedefin `/metrics` ucunu **düzenli aralıkla ziyaret eder** ve o
anki değerleri okur (scrape). Uygulama veri "göndermez"; sadece güncel değerleri bir HTTP
ucunda sunar. Bir metrik ucu ham hâlde şöyle görünür:

```
# HELP http_requests_total Toplam HTTP istek sayısı
# TYPE http_requests_total counter
http_requests_total{method="GET",status="200"} 1027
http_requests_total{method="GET",status="500"} 3
```

Prometheus bunu `<VM_IP>:9100/metrics` gibi bir adresten çeker. "Kim kimi çeker" ilişkisi
`prometheus.yml`'deki `scrape_configs`'te tanımlanır.

## 3️⃣ Exporter kur ve topla

A6 VM'inde node_exporter'ı (makine metrikleri: CPU/bellek/disk) **systemd servisi olarak**
kur — Docker gerekmez (o Blok C konusu):

```bash
# 1) binary'yi indir — <VERSION> yerine resmi release'teki güncel sürümü yaz (:latest yok)
VER=<VERSION>
curl -sSL -o /tmp/node_exporter.tgz \
  "https://github.com/prometheus/node_exporter/releases/download/v${VER}/node_exporter-${VER}.linux-amd64.tar.gz"
tar -xzf /tmp/node_exporter.tgz -C /tmp
sudo install "/tmp/node_exporter-${VER}.linux-amd64/node_exporter" /usr/local/bin/

# 2) ayrı servis kullanıcısı + systemd unit (A6'daki kalıp)
sudo useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter
sudo tee /etc/systemd/system/node_exporter.service >/dev/null <<'UNIT'
[Unit]
Description=Prometheus Node Exporter
After=network.target
[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter --web.listen-address=127.0.0.1:9100
Restart=on-failure
[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload && sudo systemctl enable --now node_exporter
curl -s http://127.0.0.1:9100/metrics | head    # metrikler geliyor mu (A3 curl)
```

Prometheus'un kendisi de aynı kalıpla kurulur (release'ten binary indir, `prometheus.yml`
ile `--config.file` vererek systemd unit'i yaz). Hızlı yol istersen L08 lab'ı aynı yığını
küçük bir `docker compose` ile de verir — ama Docker'ı **C1'de** öğreneceksin; oradaki
`docker compose up -d` şimdilik yalnız hazır bir reçetedir.

`prometheus.yml` — hedefi tanımla:

```yaml
scrape_configs:
  - job_name: node
    static_configs:
      - targets: ["127.0.0.1:9100"]
```

Prometheus'u başlat, arayüzünde **Status → Targets** ile hedefin `UP` olduğunu doğrula.
`up` metriğinin kendisi ilk sağlık göstergendir: `1` = hedef erişilebilir, `0` = değil.

## 4️⃣ Üç metrik türü

| Tür | Ne yapar | Örnek |
|---|---|---|
| **Counter** | Yalnız artar (ya da sıfırlanır) | `http_requests_total` — toplam istek |
| **Gauge** | İ­ner-çıkar, anlık değer | `node_memory_available_bytes` — boş bellek |
| **Histogram** | Değerleri kovalara dağıtır | `http_request_duration_seconds` — gecikme dağılımı |

Kural: bir şeyin **oranını/hızını** istiyorsan counter (üstüne `rate()` uygula);
**anlık seviye** istiyorsan gauge; **dağılım/percentile** istiyorsan histogram. (p95 gecikme =
isteklerin %95'inin altında kaldığı süre; ortalamadan daha dürüsttür, çünkü birkaç yavaş
isteği ortalama gizler ama p95 gizlemez.)

## 5️⃣ İlk PromQL sorguların

Prometheus arayüzünde (Graph sekmesi) dene:

```promql
up                                        # hangi hedefler ayakta (1/0)
rate(node_cpu_seconds_total{mode="idle"}[5m])   # 5 dk'lık CPU idle hızı
node_memory_MemAvailable_bytes            # anlık boş bellek
rate(http_requests_total{status="500"}[5m])     # 5 dk'lık hata hızı (uygulama exporter'ıyla)
```

`rate(...[5m])` bir counter'ın son 5 dakikadaki saniyelik artış hızını verir — "toplam
istek" değil, "saniyede kaç istek". Counter'ları neredeyse her zaman `rate()` ile okursun;
ham counter değeri (sürekli artan bir sayı) tek başına anlamsızdır.

## 6️⃣ Neyi ölçersin: dört altın sinyal

Her şeyi ölçmeye çalışma; bir servis için şu dördüyle başla (Google SRE'nin "four golden
signals"ı — E1'de SLO'ya dönüşecek):

| Sinyal | Sorusu | Örnek metrik |
|---|---|---|
| **Latency** | İstek ne kadar sürüyor? | `http_request_duration_seconds` (p95) |
| **Traffic** | Ne kadar yük var? | `rate(http_requests_total[5m])` |
| **Errors** | Ne kadarı başarısız? | `rate(http_requests_total{status=~"5.."}[5m])` |
| **Saturation** | Kaynak ne kadar dolu? | CPU/bellek/disk doluluk |

Bu dördü, bir servisin sağlığını tek bakışta özetler. Fazlasını sonra eklersin.

> ⚠️ Latency/Traffic/Errors örnekleri (`http_requests_total`, `http_request_duration_seconds`)
> bir **uygulama exporter'ı** gerektirir — uygulamayı enstrümante etmeyi ileride (E1'de SLO
> kurarken) yaparsın; bu modülde henüz üretmiyorsun. Şimdi node_exporter'ın verdiği
> **Saturation** (CPU/bellek/disk) ile pratik yap — L08 lab'ı tam bunu yaptırır.

## 7️⃣ Cardinality: metriğin gizli maliyeti

Prometheus her **benzersiz etiket kombinasyonu** için ayrı bir zaman serisi tutar.
Etiketlere sınırsız değerli bir şey koyarsan seri sayısı patlar:

```
# ❌ cardinality bombası — her kullanıcı/istek ayrı seri
http_requests_total{user_id="u_1", request_id="r_abc", path="/x?t=1737451200"}

# ✅ sınırlı etiket seti
http_requests_total{method="GET", route="/orders/:id", status="500"}
```

`user_id`, `request_id`, ham URL, zaman damgası, e-posta gibi **sınırsız/yüksek çeşitlilikli**
değerler etiket olamaz — her biri milyonlarca seri üretir ve Prometheus'u belleğinden
çökertir (klasik OOM). Etiketler **sınırlı ve önceden bilinen** kümelerden gelmeli
(`method`, `status`, `route` şablonu). Bu, "log'a her şeyi yazma" (B1) ilkesinin metrik
karşılığıdır: çözünürlük bedava değildir.

> Derinlik (adlandırma kuralları, retention, recording rules, HA):
> [`Prometheus-Best-Practices.md`](../../07-Observability/Prometheus-Best-Practices.md).
> Şimdilik tek kural yeter: **yüksek-cardinality değeri etikete koyma.**

## 8️⃣ `[5m]` ne demek: anlık vektör vs aralık vektörü

PromQL'de her sorgu iki tür sonuçtan birini döndürür ve beginner'ı en çok bu ayrım
takar:

| Tür | Ne döndürür | Örnek |
|---|---|---|
| **Anlık vektör** (instant) | Her seri için **tek**, en güncel değer | `node_memory_MemAvailable_bytes` |
| **Aralık vektörü** (range) | Her seri için **son N zamanın ham noktaları** | `node_cpu_seconds_total[5m]` |

`[5m]` bir metriği aralık vektörüne çevirir: "son 5 dakikanın bütün ölçüm noktaları".
Tek başına grafiklenemez — bir **dizidir**, tek sayı değil. `rate()`, `increase()`,
`avg_over_time()` gibi fonksiyonlar **aralık vektörü ister** ve onu tek anlık değere
indirir:

```promql
node_cpu_seconds_total                 # anlık: sürekli artan ham counter (anlamsız)
node_cpu_seconds_total[5m]             # aralık: son 5 dk'nın ham noktaları (grafiklenemez)
rate(node_cpu_seconds_total[5m])       # ikisinin evliliği: saniyelik artış hızı ✅
```

"`expected type range vector` / no data" hatasının neredeyse tümü bu karışıklıktan gelir:
counter'ı `rate()`'siz koydun ya da gauge'a gereksiz `[5m]` verdin. Kural: **counter →
her zaman `rate(...[aralık])`; gauge → çıplak (anlık).**

## 9️⃣ Bir scrape'i adım adım izle + meta-metrikler

Her `scrape_interval`'de (ör. 15 sn) Prometheus tek tek şunu yapar: hedefin `/metrics`
ucuna bir `GET` atar → cevabı ayrıştırır → her seriye o anki değeri **kendi zaman
damgasıyla** yazar. Uygulama bu süreçten habersizdir; sadece güncel değerleri sunar.

Prometheus bu scrape'in kendisi hakkında da **meta-metrik** üretir — bunlar "gözü gören
göz" gibidir, hedeflerin sağlığını hedefe hiç dokunmadan gösterir:

| Meta-metrik | Ne söyler | Niçin bakarsın |
|---|---|---|
| `up` | Hedef erişilebildi mi (1/0) | İlk sağlık göstergen; alarmın çekirdeği (E2) |
| `scrape_duration_seconds` | Scrape ne kadar sürdü | Yavaşlıyorsa hedef veya `/metrics` şişiyor |
| `scrape_samples_scraped` | Kaç seri geldi | **Cardinality erken uyarısı** — aniden şişerse §7 |

Worked örnek — A6 VM'inde kök diskin doluluk yüzdesini tek sorguyla oku (iki gauge'ı
böl, `1 -` ile "dolu" oranına çevir):

```promql
100 * (1 - node_filesystem_avail_bytes{mountpoint="/"}
           / node_filesystem_size_bytes{mountpoint="/"})
```

Bu, B1'deki `df -h`'nin metrik karşılığıdır: aynı gerçeği tek seferlik komut yerine
**zamanla** görürsün — disk yavaşça mı doluyor, birden mi sıçradı? "Disk dolu" bir kırık
lab kök sebebidir (B3); onu bir olaydan **önce** eğilim olarak görmek, arızayı önlemektir.

> **Staleness (bayatlık):** bir hedef kaybolursa Prometheus onun serilerini ~5 dk sonra
> "stale" işaretler ve grafik kesilir. `up == 0` gördüğünde, veri yokluğu değil **hedefin
> düştüğü** anlamına gelir — ikisini karıştırma.

`scrape_interval` bir **ödünleşimdir**: kısaltmak (ör. 5 sn) daha ince çözünürlük verir
ama her hedef için daha çok seri-noktası → daha çok disk/CPU. Uzatmak (ör. 60 sn) ucuzdur
ama iki ölçüm arasındaki ani sıçramayı kaçırırsın. Başlangıç için 15 sn makul; "daha sık
ölçmek" bir refleks değil, gerekçe isteyen bir karardır (retention hesabı deep-dive'da).

## 🔟 (Kısaca) görselleştirme

Metrik ham sayıdır; onu bir panoda görürsün (Grafana). Bu modülde amaç Prometheus'ta
sorguyu yazıp okuyabilmek; Grafana panosu ve alerting E bloğunda derinleşir. Şimdilik
Prometheus'un kendi Graph arayüzü yeter.

> 🔒 `/metrics` ucu içeriği sızdırabilir. Metriklere veya etiketlere **sır/PII koyma**
> (B1 ile aynı kural). Metrik ucunu internete açık bırakma; A6'daki gibi yalnız
> `127.0.0.1`/iç ağdan erişilir tut, gerekiyorsa önüne kimlik doğrulama koy — aksi hâlde
> saldırgan servisinin iç yapısını ve trafiğini okur.

---

## 🚫 Anti-pattern tablosu
| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Etikete `user_id`/`request_id`/ham URL koymak | Cardinality patlar, Prometheus OOM olur | Sınırlı, bilinen etiketler (`method`, `route` şablonu, `status`) |
| Ham counter'ı grafiğe koymak | Sürekli artan sayı anlamsız | `rate(counter[5m])` ile hız oku |
| Her metriği ölçmeye çalışmak | Gürültü + maliyet, sinyal kaybolur | Dört altın sinyalle başla |
| Metriğe/etikete sır/PII yazmak | `/metrics` sızdırır (B1 ile aynı) | Sır/PII asla metrikte; ucu içeride tut |
| `/metrics` ucunu internete açmak | İç yapı ve trafik ifşa olur | `127.0.0.1`/iç ağ + gerekiyorsa auth |
| Metrik var, log yok (veya tersi) | Biri eğilimi, diğeri olayı verir; yarısı kör | İkisini birlikte kullan (B1 + B2) |
| Retention/limit düşünmeden ölçmek | Disk/bellek dolar, 6 ay sonra OOM | Retention + cardinality bütçesi (deep-dive) |
| Exporter'ı `push` sanıp veri "göndermeye" çalışmak | Prometheus **çeker**; model yanlış | Uygulama `/metrics` sunar, Prometheus scrape eder |
| Counter'a `[5m]` verip `rate()` unutmak | "expected range vector" / anlamsız çizgi | Counter → `rate(...[5m])`; gauge → çıplak |
| `up == 0`'ı "veri yok" sanmak | Hedef düşmüş, susmak değil; alarm kaçar | `up`/`scrape_*` meta-metriklerini izle |

## 📖 Önce/İleri oku
| Kaynak | Ne için | Ne zaman |
|---|---|---|
| [`07-Observability/Prometheus-Best-Practices.md`](../../07-Observability/Prometheus-Best-Practices.md) | Cardinality, adlandırma, retention, recording rules | Bu modülü bitirince (derinlik) |
| [`07-Observability/Alerting-Done-Right.md`](../../07-Observability/Alerting-Done-Right.md) | Metrikten alarma geçiş | **E2 öncesi** — şimdi değil |

## 🔨 Lab
👉 [`labs/build/L08-metrik/`](../labs/build/L08-metrik/) — (Görev taslağı: A6 VM'inde
node_exporter + Prometheus'u systemd ile kur, dört altın sinyalden en az ikisini PromQL
ile sorgula, bir de bilerek yüksek-cardinality bir etiket ekleyip seri sayısının nasıl
patladığını gözlemle.)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] VM'de bir exporter çalışıyor, Prometheus **Targets** ekranında hedef `UP`; `up` sorgusu `1` döndürüyor.
- [ ] Bir sağlık göstergesini döndüren bir PromQL sorgusu yazdın (ör. `rate(...[5m])`) ve çıktısını gösterdin.
- [ ] Yüksek-cardinality'ye yol açan bir etiket örneği verdin ve niçin kaçınıldığını (seri patlaması → OOM) **yazılı** açıkladın.
- [ ] Counter ile gauge farkını, hangisini `rate()` ile okuduğunu bir örnekle **yazdın**.

## 🧪 Kendini test et
1. Prometheus'un "pull" modeli ne demek? Uygulama veriyi göndermiyorsa Prometheus onu nasıl alıyor?
2. **Senaryo:** Bir grafik `http_requests_total`'ı çiziyor ve sürekli artan düz bir çizgi görüyorsun; "istek hızı" istiyorsun. Sorguyu nasıl düzeltirsin?
3. **Tasarım:** Bir mühendis "her isteği ayrı görebilmek için metriğe `request_id` etiketi ekleyelim" diyor. Ne dersin ve niçin?

<details><summary>Cevaplar</summary>

1. Prometheus, izlediği her hedefin `/metrics` HTTP ucunu düzenli aralıklarla (scrape interval) ziyaret edip o anki değerleri **çeker**. Uygulama hiçbir yere göndermez; sadece güncel metrikleri bir uçta sunar. "Kim kimi çeker" `scrape_configs`'te tanımlıdır.

2. `http_requests_total` bir counter; ham hâli sürekli artan bir sayı olduğu için anlamsız. Hızı görmek için `rate(http_requests_total[5m])` kullanırsın — bu, son 5 dakikadaki saniyelik artış oranını verir, yani "saniyede kaç istek".

3. **Hayır.** `request_id` sınırsız çeşitliliktedir; her benzersiz değer ayrı bir zaman serisi yaratır ve cardinality'yi patlatarak Prometheus'u OOM'a sürükler. İstek çözünürlüğü metriğin değil, **log'un** (B1) işidir — orada `request_id` bir alandır. Metrik eğilim içindir; etiketleri sınırlı, bilinen kümelerden (`method`, `status`, `route` şablonu) gelmeli.

</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Target `DOWN` / `up`=0 | Exporter çalışmıyor veya port kapalı | `systemctl status`; `curl 127.0.0.1:9100/metrics` (A6/A2) |
| `/metrics` boş / bağlanamıyor | Exporter yanlış adres dinliyor | `ss -tlnp` ile gerçek portu doğrula (A2) |
| PromQL "no data" | Metrik adı/etiket yanlış | Arayüzde metrik adını autocomplete ile bul |
| Counter grafiği hep artıyor | `rate()` kullanılmadı | `rate(metric[5m])` ile sar |
| Prometheus belleği şişiyor / OOM | Cardinality patlaması | Yüksek-cardinality etiketi kaldır (deep-dive) |
| Sorgu çok yavaş | Geniş aralık / çok seri | Aralığı daralt; recording rule (deep-dive) |

## 💼 Portfolyo çıktısı
Çalışan bir temel metrik kurulumu (exporter + Prometheus + birkaç PromQL sorgusu) —
E1'de SLO'ya, E2'de alarma evrilecek. Kurulum adımlarını A6'daki gibi belgele.

## ⏭️ Sırada
[`B3 — İlk Kırık Lab`](B3-ilk-kirik-lab.md)

---

> *"Her şeyi ölçemezsin; neyi ölçmediğini bilmek de bir karardır."*
