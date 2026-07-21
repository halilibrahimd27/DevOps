---
description: "Terraform: A6'da elle kurduğun altyapıyı kod olarak tanımlamak — soyutlanan acıyı yaşamış olana öğretilir."
level: C
module: C3
estimated_hours: 16
prerequisites: [A6, C1]
tags: [Learning Path, IaC]
---
# C3 — Terraform: A6'yı Otomatikleştir

> *"Terraform bir soyutlamadır; soyutladığı acıyı yaşamamış birine öğretmek boşadır. A6'yı hatırla."*

**Blok:** C — Tekrarlanabilirlik · **Süre:** ~16 saat · **Ön koşul:** [`A6`](../block-a-intuition/A6-elle-deploy.md), [`C1`](C1-container.md)

## 🎯 Bu modülü bitirdiğinde
- A6'da elle kurduğun altyapıyı Terraform ile kod olarak tanımlarsın.
- `plan`/`apply`/`destroy` döngüsünü ve state'in ne olduğunu açıklarsın.
- Aynı ortamı sıfırdan, elle hiçbir şeye dokunmadan yeniden kurabilirsin.

## 🧠 Niye bu, niye şimdi
A6'da her şeyi elle yaptın ve her tekrar hataya açıktı. C3 o elle-işi kod hâline
getirir; bu, **C → D geçiş sinyalinin** ta kendisidir: "sistemini sıfırdan, elle
dokunmadan yeniden kurabiliyor musun?"

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`03-IaC/Terraform-Best-Practices.md`](../../03-IaC/Terraform-Best-Practices.md) | state, yapı, pratikler | ~30 dk |
| [`03-IaC/Terraform-Module-Layout.md`](../../03-IaC/Terraform-Module-Layout.md) | modül düzeni | ~20 dk |

## 🔨 Lab
👉 `labs/build/L11-terraform/` — Faz 5'te oluşturulacak (yerel: LocalStack).

## 💥 Kırık lab
👉 `labs/broken/K03-terraform-state/` — Faz 5'te. Belirti: "apply beklenmedik
sonuç veriyor / kilitli." (Gerçekçi sebep gizli: state lock / drift.) Blok C'nin
zorunlu kırık lab'ıdır.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 3): A6 ortamı Terraform ile sıfırdan `apply` ile kuruluyor (yerelde)
- [ ] TODO (Faz 3): `destroy` sonrası tekrar `apply` ile aynı sonuç — tekrarlanabilirlik kanıtı
- [ ] TODO (Faz 3): K03 kırık lab'ı çözüldü, `verify.sh` geçiyor

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
A6 altyapısının kod hâli (Terraform modülü) — sıfırdan kurulabilir, gösterilebilir.

## ⏭️ Sırada
[`C4 — Bulut Temelleri + Bütçe Alarmı`](C4-bulut-butce-alarmi.md)

---

> *"Elle kurulan altyapı bir anıdır; kod olan altyapı bir gerçektir — tekrar edilebilir olan."*
