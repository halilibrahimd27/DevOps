---
description: "Yazma: ADR, RFC, postmortem — bir kararı, bir öneriyi ve bir öğrenmeyi başkalarının okuyabileceği biçimde kaydetmek."
level: F
module: F4
estimated_hours: 10
prerequisites: [E3]
tags: [Learning Path, Soft-Skills]
---
# F4 — Yazma: ADR, RFC, Postmortem

> *"Yazılmayan bir karar, altı ay sonra kimsenin niçinini hatırlamadığı bir gizemdir."*

**Blok:** F — Karar · **Süre:** ~10 saat · **Ön koşul:** [`E3`](../block-e-ownership/E3-incident-postmortem.md)

## 🎯 Bu modülü bitirdiğinde
- Bir mimari kararı bir ADR (Architecture Decision Record) olarak yazarsın.
- Bir öneriyi bir RFC ile tartışmaya açar, itirazları önceden karşılarsın.
- Bir postmortem'i suçlamasız ve eyleme dönük biçimde yazarsın.

## 🧠 Niye bu, niye şimdi
E3'te bir postmortem yazdın; F4 yazmayı bir **karar aracı** olarak genişletir. L2
seviyesinde etkin olmak, çoğu zaman kod yazmak değil, bir kararı ikna edici ve
izlenebilir biçimde yazmaktır. Bu modül saf okuma değil, **yazma egzersizidir.**

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`20-Soft-Skills/Documentation-as-Communication.md`](../../20-Soft-Skills/Documentation-as-Communication.md) | yazmak bir iletişim aracıdır, okuyucu odaklı | ~30 dk |
| [`00-Culture/Documentation-Culture.md`](../../00-Culture/Documentation-Culture.md) | kararı yazılı tutma kültürü | ~20 dk |
| [`00-Culture/Blameless-Postmortem-Template.md`](../../00-Culture/Blameless-Postmortem-Template.md) | postmortem şablonu (E3'ten hatırla) | ~15 dk |

## 🔨 Teslim edilebilir egzersiz
Bu modülün çıktısı **yazılı eserdir**, saf okuma değil. İki belge üret:
1. **Bir ADR** (Architecture Decision Record): patika boyunca verdiğin gerçek bir kararı belgele —
   örn. "C1'de multi-stage image niçin", "D3'te secret'i niçin şu yolla yönettim". Bölümler:
   bağlam → değerlendirilen seçenekler → verilen karar → sonuçları (olumlu ve olumsuz).
2. **Bir postmortem'i rubrikle değerlendir**: E3'te (ya da K07'de) yazdığın postmortem'i aşağıdaki
   rubrikle puanla, düşük eksenleri **düzelt**, düzeltilmiş sürümü teslim et.

**Rubrik (her eksen 0–2):** karar/kök-sebep netliği · değerlendirilen alternatifler · sonuçların
dürüstlüğü (olumsuzlar da yazılı mı) · izlenebilir eylem maddeleri (sahip + son tarih).

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] Bir `adr-001-<konu>.md` yazıldı: bağlam, en az 2 seçenek, karar ve **olumsuz** sonuçlar dahil
- [ ] Bir postmortem yukarıdaki rubrikle puanlandı; her eksen için puan + düşük eksenlerin düzeltmesi yazılı
- [ ] "Bir RFC'de en güçlü itirazı önceden nasıl karşılarsın" bir paragrafta yazıldı
- [ ] ADR'deki her eylem/sonuç maddesi izlenebilir (sahip veya kaynak modül adı taşıyor)

## 🧪 Kendini test et
1. Bir ADR'de "değerlendirilen seçenekler" bölümü niçin "verilen karar" bölümünden daha değerlidir?
2. Bir RFC'yi yayımlamadan önce en güçlü itirazı kendin yazmak niçin ikna gücünü artırır?
3. Postmortem'de "olumsuz sonuçlar" bölümünü boş bırakmak niçin bir kırmızı bayraktır?

<details><summary>Cevaplar</summary>

1. Çünkü kararın *niçin* verildiğini ve hangi alternatiflerin niçin elendiğini gösterir; altı ay sonra "niye böyle yapmışız?" sorusunun cevabı orada. Yalnız sonuç, bağlam olmadan yeniden tartışılır — [`20-Soft-Skills/Documentation-as-Communication.md`](../../20-Soft-Skills/Documentation-as-Communication.md).
2. İtirazı okuyucudan önce sen dile getirirsen tartışma "haklı mısın" değil "hangi trade-off" eksenine kayar; savunmacı değil, güvenilir görünürsün. En sık itirazları önceden karşıla — [`00-Culture/Documentation-Culture.md`](../../00-Culture/Documentation-Culture.md).
3. Her kararın bedeli vardır; olumsuz yok demek ya dürüst değilsin ya yeterince düşünmedin demektir. Trade-off'u yazmayan doküman güven kaybettirir — [`20-Soft-Skills/Documentation-as-Communication.md`](../../20-Soft-Skills/Documentation-as-Communication.md).
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| ADR "şunu yaptık" listesine dönüyor | Bağlam ve alternatifler atlandı | Önce problemi ve elenen seçenekleri yaz; karar en sona gelir |
| Postmortem kişiyi suçluyor | Blameless çerçeve yok | Dili sisteme çevir (E3) — "sistem X'e izin verdi"; şablona dön |
| RFC savunmacı okunuyor | İtirazlar bastırılıyor | En güçlü itirazı kendin yaz ve yanıtla; tartışmayı trade-off'a taşı |
| Eylem maddeleri takip edilemiyor | Sahip/tarih yok | Her maddeye sahip + son tarih + izleneceği yer ekle |

## 💼 Portfolyo çıktısı
Yazılmış bir ADR + bir postmortem — L2 iletişiminin en somut kanıtı.

## ⏭️ Sırada
[`F5 — Stakeholder, "Hayır" Demek, Vendor`](F5-stakeholder-vendor.md)

---

> *"Bir kararın kalitesi, onu okuyan ve karşı çıkamayanların sayısıyla ölçülür."*
