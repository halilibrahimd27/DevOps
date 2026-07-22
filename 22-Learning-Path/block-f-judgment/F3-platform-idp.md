---
description: "Platform, IDP ve Team Topologies: developer acısını bir ürün gibi çözmek — platform tasarlanmadan önce."
level: F
module: F3
estimated_hours: 10
prerequisites: [D5, F1]
tags: [Learning Path, Platform-Engineering]
---
# F3 — Platform, IDP, Team Topologies

> *"Kimin hangi acıyı çektiğini bilmeden kurulan platform, kimsenin istemediği bir üründür."*

**Blok:** F — Karar · **Süre:** ~10 saat · **Ön koşul:** [`D5`](../block-d-orchestration/D5-gitops-argocd.md), [`F1`](F1-maliyet-finops.md)

## 🎯 Bu modülü bitirdiğinde
- Bir "platform"un ne zaman gerçek bir ihtiyaç, ne zaman erken bir soyutlama olduğunu ayırt edersin.
- Team Topologies kavramlarıyla ekipler arası bilişsel yükü tartışırsın.
- Bir iç geliştirici platformunun (IDP) çözmesi gereken somut acıyı tanımlarsın.

## 🧠 Niye bu, niye şimdi
D5'e kadar sistemleri sen kurdun ve işlettin; F1'de maliyet gözüyle baktın. F3
soruyu değiştirir: bu işi **başkaları için** nasıl tekrarlanabilir kılarsın? Ama
developer acısını yaşamadan platform tasarlanmaz — bkz. [`NOT-YET.md`](../NOT-YET.md).

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`13-Platform-Engineering/Platform-as-Product.md`](../../13-Platform-Engineering/Platform-as-Product.md) | platformu ürün gibi görmek, kullanıcı = developer | ~30 dk |
| [`13-Platform-Engineering/Golden-Paths.md`](../../13-Platform-Engineering/Golden-Paths.md) | altın patika: doğru olanı kolay yapmak | ~25 dk |
| [`00-Culture/Team-Topologies.md`](../../00-Culture/Team-Topologies.md) | ekipler arası bilişsel yük, platform ekibi tipi | ~25 dk |

## 🔨 Teslim edilebilir egzersiz
Çıktısı yazılı bir öneri taslağıdır — kod değil. Kendi patika deneyiminden (A6'dan
D5'e kadar) yaşadığın somut bir sürtünmeyi seç. `golden-path-onerisi.md` yaz:
1. Acıyı **kanıtla**, varsaymadan: hangi adım kaç kez tekrarlandı, ne kadar sürdü, nerede yanlış yapılabiliyor.
2. Bir golden path öner: bu acıyı çeken developer'ın "doğru olanı" nasıl varsayılan hâle getirirsin.
3. Bu platformun **ne zaman erken** olacağını yaz — hangi koşulda kurmazsın, niçin (bkz. [`NOT-YET.md`](../NOT-YET.md)).
4. Team Topologies diliyle: bu platformu hangi ekip tipi sahiplenir, hangi bilişsel yükü kimden alır.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] `golden-path-onerisi.md`'de somut bir developer acısı **kanıtla** tanımlandı (tekrar sayısı / süre / hata noktası)
- [ ] Bir golden path taslağı yazıldı: "doğru olan" nasıl varsayılan hâle geliyor, açıkça
- [ ] "Bu platform ne zaman erken olurdu" sorusu gerekçesiyle yanıtlandı (kurmama koşulu yazılı)
- [ ] Platformu sahiplenecek ekip tipi Team Topologies terimleriyle adlandırıldı

## 🧪 Kendini test et
1. Bir platform ile bir iç kütüphaneyi ayıran nedir — platform niçin bir ürün gibi yönetilmeli?
2. Golden path'i bir zorunlu kurala (mandate) çevirirsen ne kaybedersin?
3. Developer acısını yaşamadan platform tasarlamak niçin en pahalı hata türlerinden biridir?

<details><summary>Cevaplar</summary>

1. Platformun kullanıcısı vardır (developer'lar), benimsenmezse başarısızdır; bu yüzden ürün gibi — kullanıcı araştırması, geri bildirim, benimsenme metriği ile — yönetilir. Kütüphane bir bağımlılıktır, platform bir hizmettir — [`13-Platform-Engineering/Platform-as-Product.md`](../../13-Platform-Engineering/Platform-as-Product.md).
2. Gönüllü benimsenmeyi. Golden path "en kolay ve doğru yol"dur; zorlarsan developer onu atlatmanın yolunu arar ve platform güven kaybeder. Doğru olanı kolay yap, mecbur etme — [`13-Platform-Engineering/Golden-Paths.md`](../../13-Platform-Engineering/Golden-Paths.md).
3. Çünkü çözmediğin bir acıya çözüm üretirsin: kimsenin istemediği bir soyutlama, sürekli bakım borcu ve düşük benimsenme. Acıyı yaşamak gereksinimi doğru koyar — [`NOT-YET.md`](../NOT-YET.md).
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Acı soyut kalıyor | Kanıt yok, varsayım var | Bir adımı say: kaç kez, kaç dakika, kaç kez yanlış — sayı olmadan acı yoktur |
| Golden path bir mandate'e dönüşüyor | Kolaylık yerine zorlama seçildi | "Doğru olanı varsayılan yap"a geri dön; developer'ın kaçış yolunu kapatma |
| Platform çok erken kuruluyor | Developer acısı yaşanmadı | Önce elle/scriptle çöz; tekrar eden acı kanıtlanana kadar platformu erteleme |
| Kim sahiplenecek belirsiz | Ekip tipi düşünülmedi | Team Topologies'e dön: bu bir platform ekibi işi mi, yoksa geçici bir enabling mi? |

## 💼 Portfolyo çıktısı
Bir platform/golden path öneri taslağı — acıya dayalı, erken soyutlamaya karşı.

## ⏭️ Sırada
[`F4 — Yazma: ADR, RFC, Postmortem`](F4-yazma-adr-rfc.md)

---

> *"En iyi platform görünmezdir: developer onu fark etmeden doğru olanı yapar."*
