---
description: "Nasıl çalışılır: okuma/yapma oranı, aktif hatırlama ve dış kaynak sözleşmesi (dört alanlı link kuralı)."
tags: [Learning Path]
---
# 📚 Çalışma Yöntemi

> *"Okumak anlamak değildir. Anlamak, bozup geri getirebilmektir."*

Bu patika bir okuma listesi değil, müfredattır. Aşağıdaki yöntem, okuduğunu
**yetkinliğe** çevirmen içindir. Kısa oku, çok yap, kanıtla.

---

## ⚖️ Okuma / yapma oranı

Kaba hedef: **1 birim okuma → 2 birim yapma.** Bir modülün "Önce oku" tablosunu
bitirince durma; asıl öğrenme lab'da ve kırık lab'da olur. Bir kavramı
okuduğunda anladığını sanırsın; onu bir sistemde uygulayıp bozunca gerçekten
öğrenirsin.

| Aşama | Ne yaparsın | Amaç |
|---|---|---|
| Oku | "Önce oku" tablosundaki kaynakları geç | Kavram + "niye" |
| İnşa et | `labs/build/` görevini bitir | Elle yapabilmek |
| Boz & tamir et | `labs/broken/` kırık lab'ı çöz | Teşhis sezgisi |
| Kanıtla | Kabul kriterlerini komutla geçir | Objektif doğrulama |
| Anlat | Bir kavramı kendi cümlelerinle yaz | Kalıcılık (aktif hatırlama) |

---

## 🔁 Aktif hatırlama ve aralıklı tekrar

- Her modül sonunda `🧪 Kendini test et` sorularını **kapaklar kapalı** cevapla.
- Bir haftalık ara verdikten sonra önceki bloğun kabul kriterlerinden birini tekrar çalıştır.
- Kavramı başkasına (ya da boş bir sayfaya) anlatamıyorsan, öğrenmemişsindir.

---

## 🌐 Dış kaynak sözleşmesi — dört alanlı link kuralı

Bu repo **küratördür**, dünyanın kopyası değil. Hedef "başka kaynağa ihtiyaç
kalmaması" değil, **"yönlendirilmemiş hiçbir an kalmaması."** Bu yüzden patikadaki
her dış link şu dört alanı doldurur:

| Kaynak | Niye gidiyorsun | Orada tam olarak ne yapacaksın | Süre | Dönünce nasıl doğrulanır |
|---|---|---|---|---|
| (örnek) resmi Terraform tutorial | State kavramını resmi kaynaktan görmek | `terraform apply` → state dosyasını incele | ~30 dk | `terraform state list` çıktısını modüldeki lab ile karşılaştır |

Dört alanı olmayan dış link **link dökümüdür ve bu patikada yasaktır.** Bir modülde
sadece "şu adrese bak" yazan bir link görürsen, o bir hatadır — Faz 9 denetiminde
düzeltilir.

> **İki istisna — bunlar link dökümü değildir:**
> 1. **İhtiyaç-anında tekil referans.** Bir `man` sayfası, tool wiki'si ya da bir
>    GitHub release'inin güncel sürüm numarası gibi, "gidip bir şey öğrenmek" için
>    değil, tek bir bilgiyi **anında** almak için bakılan kaynak dört alan istemez.
>    Yönlendirilmiş okuma değil, sözlük bakışıdır.
> 2. **Repo-içi "Önce oku" linkleri.** Modüllerin `📖 Önce oku` tablosundaki
>    deep-dive linkleri dış kaynak değildir; kaynak + ne için + süre (üç alan) yeter.
>    "Dönünce doğrulama" işini modülün **kabul kriterleri** zaten yapar.

---

## 🧱 Takıldığında

1. Modülün `🆘 Takıldıysan` tablosuna bak (belirti → muhtemel sebep → ne yap).
2. Genel hatalar: [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).
3. Kırık lab'da `hints/` klasörü kademelidir: `hint-1` (yön) → `hint-2` (daralt) →
   `hint-3` (neredeyse cevap). Sırayla aç; ilk hamlede `solution.md`'yi açma.

> Takılmak arıza değil, sürecin kendisidir. Bir hatayı yardımsız daraltmak, bu
> patikanın öğrettiği asıl beceridir.

---

## 🚫 Anti-pattern'ler

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Tüm blok'u okuyup hiç lab yapmamak | Okuma yetkinlik değildir; ilk gerçek görevde çökersin | Her modülde en az bir lab bitir |
| Kabul kriterini "anladım" diye geçmek | Öznel; kanıtlanamaz | Komutla / dosya varlığıyla / yazılı çıktıyla kanıtla |
| İlk zorlukta `solution.md` açmak | Teşhis kasını hiç çalıştırmazsın | Önce `hint-1`, kendi hipotezini kur |
| Blok atlamak ("bunları biliyorum") | Boşluk sonra bir duvar olarak çıkar | Kontrol testini geç, sonra atla |
| Dış linke dalıp geri dönmemek | Yönsüz kalırsın, saatler kaybolur | Dört alanlı sözleşmeye uy: süre + dönüş doğrulaması |

---

## 📋 Checklist — bir modülü "bitti" saymadan önce

```
[ ] "Önce oku" kaynaklarını geçtim
[ ] Lab'ı bitirdim, verify.sh sıfır hatayla geçti
[ ] (Varsa) kırık lab'ı yardımsız (en fazla hint-1/2 ile) çözdüm
[ ] Tüm kabul kriterlerini komut/çıktı ile kanıtladım
[ ] Kendini test et sorularını kapaklar kapalı cevapladım
[ ] Portfolyo çıktısını (varsa) kaydettim
```

---

> *"Hız hedef değil. Bir bloğu gerçekten geçmek, iki bloğu yarım bilmekten değerlidir."*
