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
👉 [`labs/broken/K07-incident-sim/`](../labs/broken/K07-incident-sim/) — Belirti: çok-arızalı bir incident
simülasyonu; birden fazla sinyal, gerçek zaman baskısı. Teşhis + iletişim birlikte ölçülür.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] K07 çok-arızalı incident simülasyonu UTC dakika hassasiyetli bir zaman çizelgesiyle yönetildi — yazılı timeline
- [ ] Suçlamasız bir postmortem yazıldı: sayısal etki + kök sebep + "niçin daha erken yakalanmadı"
- [ ] Postmortem'den en az bir izlenebilir eylem maddesi (sahip + son tarih) çıkarıldı
- [ ] `bash labs/broken/K07-incident-sim/verify.sh` çözümden sonra sıfır hatayla geçiyor

## 🧪 Kendini test et
1. Incident'te ilk atanması gereken rol nedir ve niçin teknik düzeltmeden önce gelir?
2. "İnsan hatası" niçin bir kök sebep değildir?
3. Postmortem'de daha değerli bölüm hangisi: kök sebep mi, "niçin daha erken yakalanmadı" mı?

<details><summary>Cevaplar</summary>

1. Incident Commander (koordinasyon + iletişim). Çünkü paralel çalışan kişiler tek karar noktası ve net iletişim olmadan birbirini ezer; düzeltme kaosa döner. Rol ayrımı [`11-SRE/Incident-Response.md`](../../11-SRE/Incident-Response.md)'de.
2. Çünkü sistemi bir insanın yanlış yapmasına izin verecek şekilde tasarladıysan hata kaçınılmazdı — kök sebep o tasarımdır (eksik guard-rail, kırılgan süreç). "İnsan hatası" araştırmayı durdurur, sistemi değiştirmez.
3. İkincisi. Kök sebep bu olayı açıklar; "niçin daha erken yakalanmadı" (eksik alarm/test/inceleme) tekrarı önleyen katmandır — asıl öğrenme oradadır. Şablon [`00-Culture/Blameless-Postmortem-Template.md`](../../00-Culture/Blameless-Postmortem-Template.md)'de.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Herkes aynı anda düzeltmeye çalışıyor | Koordinasyon rolü yok | Bir Incident Commander ata; roller ve tek karar noktası netleşsin |
| Timeline sonradan çıkarılamıyor | Anlık kayıt tutulmadı | Olay anında zaman damgalı not tut (bir chat kanalı yeter) |
| Postmortem kişiyi suçluyor | Blameless çerçeve yok | Dili sisteme çevir: "X kişisi hata yaptı" değil "sistem X'e izin verdi" |
| Eylem maddeleri takip edilmiyor | Sahip/tarih yok | Her maddeye sahip + son tarih + izleneceği yeri ekle |

## 💼 Portfolyo çıktısı
Yazılmış bir blameless postmortem — F4'te yazma örneği olarak da kullanılır.

## ⏭️ Sırada
[`E4 — Veritabanı Production (Restore)`](E4-veritabani-restore.md)

---

> *"'İnsan hatası' bir kök sebep değil, bir sistemin bir insanın hata yapmasına izin verdiğinin kanıtıdır."*
