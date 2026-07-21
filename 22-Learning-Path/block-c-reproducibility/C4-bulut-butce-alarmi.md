---
description: "Bulut temelleri + zorunlu bütçe alarmı: VPC/IAM/işlem kavramları ve buluta ilk dokunuşta harcamayı görmek."
level: C
module: C4
estimated_hours: 12
prerequisites: [C3]
tags: [Learning Path, Cloud]
---
# C4 — Bulut Temelleri + Bütçe Alarmı

> *"Buluta ilk işin bir kaynak açmak değil, harcamayı görecek alarmı kurmaktır."*

**Blok:** C — Tekrarlanabilirlik · **Süre:** ~12 saat · **Ön koşul:** [`C3`](C3-terraform.md)

## 🎯 Bu modülü bitirdiğinde
- Bir bulutta VPC, IAM ve işlem (compute) kavramlarının ne olduğunu açıklarsın.
- **Herhangi bir şey yapmadan önce** bir bütçe/faturalama alarmı kurar ve test edersin.
- Her lab kaynağını iş bitince kapatma (`destroy`) alışkanlığını uygularsın.

## 🧠 Niye bu, niye şimdi
Bu, patikanın **bulut kullanan ilk modülüdür.** C3'te öğrendiğin Terraform'u
buluta taşırsın; ama önce maliyet korkuluğunu kurarsın. Yerel-önce ilkesi burada
biter ve dikkatli bulut kullanımı başlar.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`16-Cheatsheets/aws-cli.md`](../../16-Cheatsheets/aws-cli.md) | temel CLI komutları | ~20 dk |
| [`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md) | yerel alternatif + bütçe alarmı | ~15 dk |

## 🔨 Lab
👉 `labs/build/L12-bulut-butce-alarmi/` — Faz 5'te. **İlk adım: bütçe alarmı.**

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] Faturalama/bütçe alarmı kuruldu, bir bildirim kanalına bağlı ve **tetiklenerek** test edildi — kanıt
- [ ] Küçük bir kaynak Terraform ile açıldı, `destroy` ile kapatıldı — açık kaynak kalmadığı doğrulandı
- [ ] Hangi servislerin free tier kapsamında, hangilerinin saat/GB başına ücretli olduğunu yazılı listeledin
- [ ] VPC, IAM ve compute kavramlarını kendi cümlelerinle tanımlayabiliyorsun

## 🧪 Kendini test et
1. Buluta ilk dokunuşta **kaynak açmadan önce** bütçe alarmı kurmak niçin bir tercih değil, kural?
2. IAM'de "en az yetki" ne demek; root/admin anahtarıyla günlük iş yapmak niçin tehlikeli?
3. Bir lab bitti. Maliyeti sıfıra indirmek için hangi tek alışkanlık seni korur, niye?

<details><summary>Cevaplar</summary>

1. Çünkü bulutta maliyet **sen fark etmeden** birikir: unutulan bir disk, yük dengeleyici veya IP saat başına sayar. Alarm, faturayı ay sonunda değil ilk saatte görmeni sağlar. Yerel alternatifler + alarm kurulumu [`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md)'de.
2. En az yetki: bir kimliğe yalnız işini yapacak kadar izin ver, fazlasını değil. Root/admin anahtarı sızarsa saldırgan her şeyi yapar; dar bir rol sızsa bile hasar sınırlı kalır. Günlük iş için ayrı, kısıtlı bir kimlik kullan.
3. `destroy` (ya da lab kaynaklarını kapatma) alışkanlığı. Buluta açtığın her kaynağı iş bitince kapat — "sonra kapatırım" en pahalı cümledir.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Ay sonu beklenmedik fatura | Unutulan kaynak (yük dengeleyici, disk, IP) | Alarmı düşük eşiğe kur; `destroy` alışkanlığı; maliyet gezginini incele |
| Alarm hiç tetiklenmiyor | Bildirim kanalı doğrulanmamış | Alarmı elle düşük eşikle test et; e-posta/webhook aboneliğini onayla |
| `apply` "access denied" | IAM izni eksik | Gereken izni dar kapsamda ekle; admin anahtarı kullanma |
| Free tier sanılan servis ücretli | Egress / NAT / veri transferi gizli maliyet | Fiyatlandırmayı önceden oku; egress ve yönetilen servislere dikkat |

## 💼 Portfolyo çıktısı
Bütçe alarmı + `destroy`'lu disiplinli bir bulut kurulum notu.

## ⏭️ Sırada
Blok C bitti → **kapı projesi**: [`Capstone 1`](../capstones/CAP1-blok-c-sonu.md).
Sonra [`D1 — K8s Temel`](../block-d-orchestration/D1-k8s-temel.md).

---

> *"Bulutta unutulan bir kaynak, uyurken çalışan bir sayaçtır."*
