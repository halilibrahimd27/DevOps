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
- [ ] TODO (Faz 3): faturalama alarmı kuruldu, bir bildirime bağlı ve **test edildi** — kanıt
- [ ] TODO (Faz 3): küçük bir kaynak Terraform ile açılıp `destroy` ile kapatıldı
- [ ] TODO (Faz 3): "hangi servisler free tier, hangileri değil" (yazılı not)

## 🧪 Kendini test et
1. TODO (Faz 3)
2. TODO (Faz 3)
3. TODO (Faz 3)

<details><summary>Cevaplar</summary>TODO (Faz 3)</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| TODO | TODO | TODO |

## 💼 Portfolyo çıktısı
Bütçe alarmı + `destroy`'lu disiplinli bir bulut kurulum notu.

## ⏭️ Sırada
Blok C bitti → **kapı projesi**: [`Capstone 1`](../capstones/CAP1-blok-c-sonu.md).
Sonra [`D1 — K8s Temel`](../block-d-orchestration/D1-k8s-temel.md).

---

> *"Bulutta unutulan bir kaynak, uyurken çalışan bir sayaçtır."*
