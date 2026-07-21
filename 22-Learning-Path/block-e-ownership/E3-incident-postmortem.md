---
description: "Incident response + blameless postmortem: bir arızayı yönetmek ve ondan suçlamadan öğrenmek."
level: E
module: E3
estimated_hours: 14
prerequisites: [E2]
tags: [Learning Path, SRE]
---
# E3 — Incident Response + Blameless Postmortem

> *"Bir incident'in değeri, kimi suçladığında değil, sistemin nasıl değiştiğinde ölçülür."*

**Blok:** E — Sahiplik · **Süre:** ~14 saat · **Ön koşul:** [`E2`](E2-alerting-oncall.md)

## 🎯 Bu modülü bitirdiğinde
- Bir incident'i rol, iletişim ve zaman çizelgesiyle yönetirsin.
- Suçlamasız (blameless) bir postmortem yazar, kök sebebi sisteme bağlarsın.
- Postmortem'den çıkan eylem maddelerini takip edilebilir hâle getirirsin.

## 🧠 Niye bu, niye şimdi
E2'de alarm tetiklendiğinde ne yapacağın belliydi; E3 o anı bir sürece çevirir ve
ardından öğrenmeyi kurumsallaştırır. F4'teki yazma disiplini (ADR/RFC/postmortem)
bu modüldeki postmortem pratiğine dayanır.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`11-SRE/Incident-Response.md`](../../11-SRE/Incident-Response.md) | incident yönetimi | ~30 dk |
| [`00-Culture/Blameless-Postmortem-Template.md`](../../00-Culture/Blameless-Postmortem-Template.md) | şablon | ~20 dk |

## 💥 Kırık lab
👉 `labs/broken/K07-incident-sim/` — Faz 5'te. Belirti: çok-arızalı bir incident
simülasyonu; birden fazla sinyal, gerçek zaman baskısı. Teşhis + iletişim birlikte ölçülür.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 4): K07 incident simülasyonu bir zaman çizelgesiyle yönetildi
- [ ] TODO (Faz 4): suçlamasız bir postmortem yazıldı (kök sebep + eylem maddeleri)
- [ ] TODO (Faz 4): "hangi eylem maddesi tekrarı önler" (yazılı, izlenebilir)

## 🧪 Kendini test et
1. TODO (Faz 4)
2. TODO (Faz 4)
3. TODO (Faz 4)

<details><summary>Cevaplar</summary>TODO (Faz 4)</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| TODO | TODO | TODO |

## 💼 Portfolyo çıktısı
Yazılmış bir blameless postmortem — F4'te yazma örneği olarak da kullanılır.

## ⏭️ Sırada
[`E4 — Veritabanı Production (Restore)`](E4-veritabani-restore.md)

---

> *"'İnsan hatası' bir kök sebep değil, bir sistemin bir insanın hata yapmasına izin verdiğinin kanıtıdır."*
