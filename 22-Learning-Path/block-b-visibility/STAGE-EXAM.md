---
description: "Blok B sınavı: log okuma, Prometheus metriği, kırık VM teşhisi — B→C geçiş kapısı. Kanıt mı, tahmin mi?"
level: B
tags: [Learning Path, Stage Exam]
---
# 📝 Blok B Sınavı — Görebilmek

> *"B → C geçiş sinyali: bir arızayı log ve metrikle **kanıtladın** mı, tahmin etmedin mi?"*

**Kapı:** Blok B sonu (B3'ten sonra, C0/C1'den önce) · **Ön koşul:** [`B1`](B1-log-okuma.md)–[`B3`](B3-ilk-kirik-lab.md) kabul kriterleri geçilmiş

> ℹ️ Tüm `bash labs/...` komutlarını **`22-Learning-Path/` kökünden** çalıştır.

Bu sınavın tek ölçütü şudur: **her iddianın arkasında bir çıktı var mı?** "Sanırım
DB yavaş" cevap değildir; "şu metrik şu eşiği şu dakikada aştı, şu log satırı bunu
doğruluyor" cevaptır. Her soru bir modülün kabul kriterine izlenebilir.

> 🔒 **Bu, patikanın en katı kapısıdır.** Göremediğin sistemi yönetemezsin. B3'ün
> kırık lab'ını **kanıtla** çözmeden C bloğuna (container, K8s) geçme.

---

## 1️⃣ Kavram soruları (yazılı)

| # | Soru | İzlenebilirlik (modül → kabul kriteri) |
|---|---|---|
| 1 | `journalctl` ile bir servisin **son hatalarını** nasıl süzersin? (`-u`, `--since`, `-p err`) Çıktının hangi alanı olayı tekilleştirir? | B1 → `journalctl … -p err` kriteri |
| 2 | Düz-metin log yerine structured (JSON) log niçin sorgulanabilir? Hangi alanlar sorguya girer? | B1 → structured log kriteri |
| 3 | Bir log satırına **asla** yazılmaması gereken iki alan söyle (bir sır + bir PII) ve niçin. | B1 → "ne loglanmaz" kriteri |
| 4 | Counter ile gauge farkı ne? Hangisini `rate()` ile okursun, niçin? | B2 → counter/gauge kriteri |
| 5 | Yüksek-cardinality'ye yol açan bir etiket örneği ver; niçin seri patlaması → OOM'a götürür? | B2 → cardinality kriteri |
| 6 | Bir arızayı "kanıtlamak" ile "tahmin etmek" arasındaki farkı bir örnekle yaz. | B3 → A→B/B→C sinyal kriteri |

**Geçme:** 6 sorunun **en az 5'i** doğru + gerekçeli. 3. soru (ne loglanmaz)
**zorunlu doğru** — sır/PII sızıntısı güvenlik ipliğinin ilk halkasıdır.

---

## 2️⃣ Uygulamalı görev — "kanıtla, tahmin etme"

**Görev A — Kırık VM'yi teşhis et (çekirdek):**
[`K01 — kırık VM`](../labs/broken/K01-kirik-vm/README.md) lab'ını çöz.

- [ ] `bash labs/broken/K01-kirik-vm/verify.sh` sıfır hatayla geçiyor
- [ ] Kök sebebi **log/metrik kanıtıyla** gösteren bir `teshis.md` yazdın:
      belirti → daraltma → kök sebep → düzeltme → doğrulama
- [ ] Düzeltmeden sonra belirtinin **gittiğini** ayrı bir komutla kanıtladın (sadece "düzelttim" değil)

**Görev B — Metrikle bir sağlık göstergesi:**
[`B2`](B2-metrik-prometheus.md)/[`L08`](../labs/build/L08-metrik/README.md) kurulumunu kullan.

- [ ] Prometheus **Targets** ekranında hedef `UP`; `up` sorgusu `1` döndürüyor
- [ ] Bir sağlık göstergesi için bir `rate(...[5m])` sorgusu yazdın ve çıktısını gösterdin

**Görev C — Üç komut, doküman yok:** Görev A'da kök sebebe inerken kullandığın
**üç komutu** ve niçin o sırayla geldiğini yaz. Bu, A→B sinyalinin B'de tekrar
sınanmasıdır: daraltma refleksi kalıcı mı?

---

## 🚫 Bu sınavı kendine karşı kaybetme

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "Sanırım/muhtemelen …" ile kök sebep | Tahmin; B bloğunun reddettiği tam şey | Metrik/log **çıktısı** ile göster |
| Düzeltip `verify.sh`'i geçip durmak | Belirtinin gittiğini kanıtlamadın | Ayrı bir komutla belirtinin yok olduğunu göster |
| Sır/PII'yi log'a yazıp "debug" demek | En sık gerçek incident sebebi | Maskele/çıkar; niçinini yaz |
| Her şeye etiket eklemek | Cardinality patlaması → Prometheus OOM | Sabit, sınırlı değer kümesi olan etiket kullan |
| `teshis.md`'yi atlayıp aklında tutmak | İzlenemez; postmortem (E3) kası hiç çalışmaz | Zaman damgalı yazılı teşhis bırak |

---

## ✅ Geçtin mi?

- [ ] Kavram: 6/6'nın en az 5'i doğru + 3. soru zorunlu doğru
- [ ] Uygulama: K01 `verify.sh` yeşil + kanıtlı `teshis.md` + `up=1` & bir `rate()` sorgusu
- [ ] Daraltma: kök sebebe üç komutla, kanıtla (tahminle değil) indin

Geçemediysen: log'da takıldıysan B1'e, metrik/PromQL'de takıldıysan B2'ye,
teşhis akışında takıldıysan B3'e dön.

## ⏭️ Sırada
Geçtiysen: [`C0 — Ops için Python`](../block-c-reproducibility/C0-ops-python.md)
veya [`C1 — Container`](../block-c-reproducibility/C1-container.md).

---

> *"Bir arızayı tahmin edebilirsin ama kanıtlayamıyorsan, onu tekrarlanabilir hâle getirmeye (Blok C) hazır değilsin — neyi tekrarladığını bilmiyorsun."*
