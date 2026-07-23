---
description: "İleri kırık lab / chaos: sistemi kontrollü biçimde bozup dayanıklılığını kanıtlamak — game day."
level: E
module: E5
estimated_hours: 12
prerequisites: [E3, D2]
tags: [Learning Path, SRE, Chaos]
---
# E5 — İleri Kırık Lab / Chaos

> *"Sistemin nasıl bozulduğunu bilmiyorsan, onun güvenilir olduğunu da bilemezsin — sadece henüz bozulmadığını bilirsin."*

**Blok:** E — Sahiplik · **Süre:** ~12 saat · **Ön koşul:** [`E3`](E3-incident-postmortem.md), [`D2`](../block-d-orchestration/D2-k8s-production.md)

## 🎯 Bu modülü bitirdiğinde
- Kontrollü bir şekilde (blast radius sınırlı) bir arıza enjekte edersin.
- Bir game day yürütür, hipotez → deney → gözlem döngüsünü uygularsın.
- Bulduğun zayıflığı bir eylem maddesine ve (varsa) yeni bir alarma çevirirsin.

## 🧠 Niye bu, niye şimdi
E1–E4'te sistemi ölçtün, alarmladın, incident yönettin, restore ettin. E5 bunu
proaktif yapar: arızayı beklemeden, kontrollü biçimde sen çıkarırsın. Bu, E → F
geçişinden önceki son sahiplik sınavıdır.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`11-SRE/Chaos-Engineering.md`](../../11-SRE/Chaos-Engineering.md) | chaos ilkeleri + game day | ~30 dk |
| [`11-SRE/Capacity-Planning.md`](../../11-SRE/Capacity-Planning.md) | yük/kapasite bağı | ~20 dk |

## 💥 Kırık lab
👉 [`labs/broken/K09-chaos-gameday/`](../labs/broken/K09-chaos-gameday/) — Çok-arızalı, hipotez temelli bir
game day; blast radius sınırlı, gözlem ve öğrenme merkezde.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] Sınırlı blast radius ile bir arıza (ör. bir Pod/bağımlılık düşürme) enjekte edildi ve etkisi gözlemlendi — metrik/log kanıtı
- [ ] Game day bir hipotez → deney → sonuç raporuyla yazıldı
- [ ] Deneyin çıktısı bir eyleme bağlandı: bulunan bir zayıflık bir eylem maddesine/alarma çevrildi **ya da** (zayıflık çıkmadıysa) doğrulanan dayanıklılığın hangi kanıtla artık izlendiği/korunduğu yazıldı
- [ ] `bash labs/broken/K09-chaos-gameday/verify.sh` çözümden sonra sıfır hatayla geçiyor

## 🧪 Kendini test et
1. Chaos deneyine başlamadan önce yazılması gereken tek şey nedir?
2. "Blast radius'u sınırlamak" pratikte ne demek?
3. Hiçbir şey bozulmadan geçen bir game day başarısız mıdır?

<details><summary>Cevaplar</summary>

1. Bir hipotez: "X düşerse sistem Y şekilde bozulmadan ayakta kalır." Hipotezsiz deney kurcalamadır; ölçülebilir bir beklenti olmadan sonucu yorumlayamazsın. İlkeler [`11-SRE/Chaos-Engineering.md`](../../11-SRE/Chaos-Engineering.md)'de.
2. Deneyi en küçük güvenli kapsama hapsetmek: tek replica, tek namespace, düşük trafik penceresi ve hazır bir geri-alma. Amaç öğrenmek, gerçek kullanıcıyı vurmak değil.
3. Hayır — hipotezini doğruladıysan (sistem beklendiği gibi dayandı) bu değerli bir kanıttır. Ama hiç zayıflık çıkmıyorsa deney fazla küçük olabilir; kapsamı kontrollüce büyüt. Kapasite bağı [`11-SRE/Capacity-Planning.md`](../../11-SRE/Capacity-Planning.md)'de.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Deney gerçek kullanıcıyı vurdu | Blast radius sınırlanmadı | Kapsamı küçült (tek replica/namespace), düşük trafikte ve geri-alma hazırken yap |
| Sonuç yorumlanamıyor | Hipotez yoktu | Önce "beklentim şu" yaz, sonra enjekte et; sapmayı ölç |
| Bulgu kayboldu | Rapor/eylem maddesi yok | Game day'i hipotez→sonuç formatında yaz; zayıflığı eylem/alarma bağla |
| Aynı arıza tekrar sürpriz oldu | Öğrenme alarma dönüşmedi | Bulunan zayıflık için E2 tarzı bir alarm ekle |

## 💼 Portfolyo çıktısı
Bir game day raporu (hipotez, deney, bulgu, eylem) — olgun bir sahiplik kanıtı.

## ⏭️ Sırada
Blok E bitti → **kapı projesi**: [`Capstone 3`](../capstones/CAP3-blok-e-sonu.md).
Sonra [`F1 — Maliyet (FinOps)`](../block-f-judgment/F1-maliyet-finops.md).

---

> *"Chaos, sistemi kırmak değil; onun nerede kırılgan olduğunu güvenli bir günde öğrenmektir."*
