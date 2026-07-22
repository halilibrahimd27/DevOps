---
description: "Stakeholder yönetimi, 'hayır' demek ve vendor: teknik doğruyu örgütsel gerçeğe çevirmek — L2 kapısı."
level: F
module: F5
estimated_hours: 6
prerequisites: [F3]
tags: [Learning Path, Soft-Skills]
---
# F5 — Stakeholder Yönetimi, "Hayır" Demek, Vendor

> *"'Hayır' diyebilmek bir tutum değil, gerekçesini yazılı savunabilmektir — E → F geçişinin ta kendisi."*

**Blok:** F — Karar · **Süre:** ~6 saat · **Ön koşul:** [`F3`](F3-platform-idp.md)

## 🎯 Bu modülü bitirdiğinde
- Bir isteğe gerekçeli ve yapıcı biçimde "hayır" der, alternatifini sunarsın.
- Farklı stakeholder'ların önceliklerini okuyup bir kararı onların diliyle savunursun.
- Bir vendor kararını (satın al vs kur, kilitlenme riski) trade-off'larıyla değerlendirirsin.

## 🧠 Niye bu, niye şimdi
Bu patikanın son modülüdür ve **L1 → L2 kapısını** kapatır: artık hangi sistemin
var olması gerektiğine karar veriyor ve gerektiğinde "hayır" diyorsun. Geçiş
sinyali E → F ile birebir: bir şeye "hayır" dedin ve gerekçeni yazılı savundun mu?

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`20-Soft-Skills/Saying-No.md`](../../20-Soft-Skills/Saying-No.md) | gerekçeli, alternatifli "hayır" | ~25 dk |
| [`20-Soft-Skills/Vendor-Management.md`](../../20-Soft-Skills/Vendor-Management.md) | satın al vs kur, kilitlenme riski | ~20 dk |
| [`20-Soft-Skills/Stakeholder-Management.md`](../../20-Soft-Skills/Stakeholder-Management.md) | aynı kararı farklı dillerde savunmak | ~20 dk |

## 🔨 Teslim edilebilir egzersiz
Bu, patikanın son teslimidir ve E → F geçiş sinyalinin ta kendisi: bir şeye "hayır"
de ve gerekçeni **yazılı** savun. `karar-yazisi.md` üret:
1. Gerçekçi bir isteğe (örn. "yeni bir servis mesh kur", "bu vendor'ı hemen al") **gerekçeli bir "hayır"** yaz:
   niçin hayır + hangi alternatif + hangi koşulda evet olurdu.
2. Bir vendor kararını "satın al vs kendin kur" olarak değerlendir: maliyet, bakım yükü,
   **kilitlenme (lock-in)** riski ve çıkış maliyeti — trade-off tablosuyla.
3. Aynı kararı iki farklı stakeholder'a (örn. bir developer ve bir yönetici) **onların diliyle** anlat.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] `karar-yazisi.md`'de bir isteğe alternatifli, gerekçeli bir "hayır" yazıldı (niçin + alternatif + evet koşulu)
- [ ] Bir vendor kararı satın-al/kur trade-off'larıyla, kilitlenme ve çıkış maliyeti dahil, tabloyla değerlendirildi
- [ ] Aynı karar iki farklı stakeholder'ın diliyle iki ayrı paragrafta anlatıldı
- [ ] "Hayır"ın gerekçesi bir kişiyi değil bir trade-off'u işaret ediyor (metinde kontrol edilir)

## 🧪 Kendini test et
1. Gerekçeli bir "hayır" ile inatçı bir "hayır"ı ayıran nedir?
2. Bir vendor kararında en kolay atlanan maliyet hangisidir ve niçin en pahalıya patlar?
3. Aynı teknik kararı developer'a ve yöneticiye niçin farklı çerçevelerle anlatırsın — bu manipülasyon mu?

<details><summary>Cevaplar</summary>

1. Gerekçeli "hayır" bir alternatif ve bir "evet koşulu" sunar; tartışmayı kapatmaz, doğru eksene taşır. İnatçı "hayır" yalnız kişisel duruştur, savunulamaz — [`20-Soft-Skills/Saying-No.md`](../../20-Soft-Skills/Saying-No.md).
2. Kilitlenme ve çıkış maliyeti. Satın alırken görünmez, göç etmek gerektiğinde ortaya çıkar; veri formatı, API bağımlılığı ve öğrenilmiş süreç seni tutar — [`20-Soft-Skills/Vendor-Management.md`](../../20-Soft-Skills/Vendor-Management.md).
3. Karar aynıdır, yalnız her stakeholder'ın önemsediği sonuç farklıdır (developer: bakım yükü; yönetici: risk/maliyet). Aynı gerçeği farklı sonuç diliyle anlatmak manipülasyon değil, iletişimdir — yalan söylersen manipülasyon olur — [`20-Soft-Skills/Stakeholder-Management.md`](../../20-Soft-Skills/Stakeholder-Management.md).
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| "Hayır" tartışmayı kilitliyor | Alternatif sunulmadı | Her "hayır"a bir alternatif ve bir "evet koşulu" ekle |
| Vendor kararı yalnız fiyata bakıyor | Kilitlenme/çıkış maliyeti atlandı | Trade-off tablosuna bakım yükü + göç maliyeti satırı ekle |
| Herkese aynı cümle söyleniyor | Stakeholder dili okunmadı | Her tarafın önemsediği sonucu ayrı yaz; kararı o sonuca bağla |
| "Hayır"ın gerekçesi kişiyi işaret ediyor | Duruş var, argüman yok | Gerekçeyi bir trade-off'a çevir — kişiye değil, karara odaklan |

## 💼 Portfolyo çıktısı
Gerekçeli bir "hayır" + bir vendor değerlendirmesi — L2 karar vericiliğinin kanıtı.

## ⏭️ Sırada
Patikanın son modülü. Buradan sonrası daha çok okumak değil: sahiplik, on-call ve
gerçek kullanıcı. Bkz. [`README.md`](../README.md) → Dürüst tavan. Şimdi ürettiğin
eserleri CV'ye çevir: [`PORTFOLIO.md`](../PORTFOLIO.md) → hangi modül hangi CV satırına
karşılık gelir.

---

> *"L2, en çok araca sahip olan değil; en isabetli 'hayır'ı yazabilen mühendistir."*
