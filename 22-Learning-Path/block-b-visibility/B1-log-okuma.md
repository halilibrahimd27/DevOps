---
description: "Log okuma: journalctl, structured logging ve ne loglanır ne loglanmaz — göremediğin sistemi yönetemezsin."
level: B
module: B1
estimated_hours: 12
prerequisites: [A6]
tags: [Learning Path, Observability]
---
# B1 — Log Okuma: journalctl, Structured Logging

> *"Göremediğin sistemi yönetemezsin. Log, sistemin sana anlattığı ilk hikâyedir."*

**Blok:** B — Görebilmek · **Süre:** ~12 saat · **Ön koşul:** [`A6`](../block-a-intuition/A6-elle-deploy.md)

## 🎯 Bu modülü bitirdiğinde
- `journalctl` ile bir servisin loglarını zamana/önem düzeyine göre süzebilirsin.
- Yapılandırılmış (structured) log ile düz metin log arasındaki farkı ve niçinini açıklarsın.
- Neyin loglanması, neyin (sır/PII) loglanmaması gerektiğine karar verirsin.

## 🧠 Niye bu, niye şimdi
A6'da kurduğun servis bozulacak; onu görebilmek için önce logunu okumayı bilmen
gerekir. B2'deki metrik ve B3'teki kırık lab bu beceri üstüne kurulur.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| (bu modülün gövdesi — Faz 2'de sıfırdan yazılacak) | journalctl + log hijyeni | — |
| İleri (sonraya): [`07-Observability/Logs-Loki-vs-ELK.md`](../../07-Observability/Logs-Loki-vs-ELK.md) | log stack'i (container sonrası) | ~20 dk |

## 🔨 Lab
👉 `labs/build/L07-log-okuma/` — Faz 5'te oluşturulacak.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 2): bir servisin son hatalarını `journalctl` ile süzen komut + çıktı
- [ ] TODO (Faz 2): bir olayı log satırıyla zaman damgasına kadar izleme
- [ ] TODO (Faz 2): "hangi alan loglanmamalı, niçin" (yazılı — sır/PII)

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
Doğrudan çıktı yok; B3 ve E bloğundaki incident çalışmalarında kullanılır.

## ⏭️ Sırada
[`B2 — Metrik`](B2-metrik-prometheus.md)

---

> *"Loga her şeyi yazmak da körlüktür: gürültü, sinyali gömer."*
