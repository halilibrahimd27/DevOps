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
👉 [`labs/build/L11-terraform/`](../labs/build/L11-terraform/) — yerel: LocalStack.

## 💥 Kırık lab
👉 [`labs/broken/K03-terraform-state/`](../labs/broken/K03-terraform-state/) — Belirti: "apply beklenmedik
sonuç veriyor / kilitli." (Gerçekçi sebep gizli: state lock / drift.) Blok C'nin
zorunlu kırık lab'ıdır.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] A6 ortamı Terraform ile sıfırdan `terraform apply` ile kuruluyor (yerelde, LocalStack)
- [ ] `terraform destroy` sonrası tekrar `apply` aynı sonucu üretiyor — tekrarlanabilirlik kanıtı
- [ ] `bash labs/broken/K03-terraform-state/verify.sh` çözümden sonra sıfır hatayla geçiyor
- [ ] State'in ne olduğunu ve niçin paylaşılan/kilitlenen bir yerde durması gerektiğini yazılı anlatabiliyorsun

## 🧪 Kendini test et
1. Terraform state nedir? Niçin "gerçek dünyanın fotoğrafı" değil, "Terraform'un ne yaptığının kaydı"dır?
2. İki kişi aynı anda `apply` çalıştırırsa ne olur, bunu ne engeller?
3. Biri konsoldan elle bir kaynağı değiştirdi. Sonraki `plan` ne gösterir, buna ne denir, nasıl düzeltirsin?

<details><summary>Cevaplar</summary>

1. State, Terraform'un yönettiği kaynakların bir eşlemesidir: hangi kaynağı hangi gerçek nesneyle ilişkilendirdiğini tutar. Gerçek dünya bundan bağımsız değişebilir (elle müdahale); Terraform yalnız kendi kaydını bilir, farkı `plan`'da yüzeye çıkarır. Detay [`03-IaC/Terraform-Best-Practices.md`](../../03-IaC/Terraform-Best-Practices.md).
2. İki eşzamanlı `apply` state'i bozabilir. Bunu **state lock** engeller: ilk işlem kilidi alır, ikincisi bekler. Bu yüzden state uzak ve kilitlenebilir bir arka uçta durmalı (yerel dosya değil).
3. `plan` beklenmedik bir fark gösterir — buna **drift** denir. Ya elle değişikliği geri alıp `apply` ile koda hizala, ya değişikliği kalıcıysa koda yansıt. `ignore_changes` yalnız son çaredir.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `apply` "state locked" diyor | Önceki işlem kilidi bırakmış / eşzamanlı çalışma | Çalışan işlem yoksa `force-unlock` (dikkatle); state'i ekiple uzak arka uçta paylaş |
| `plan` her seferinde değişiklik gösteriyor | Drift veya provider'ın normalize etmediği alan | Elle değişikliği geri al ya da koda yansıt; `ignore_changes` son çare |
| `destroy` bazı kaynakları bırakıyor | Bağımlılık / `prevent_destroy` koruması | Bağımlılık sırasını çöz; koruma bayrağını gözden geçir |
| Yerelde gerçek buluta gidiyor | Provider endpoint'i LocalStack'e yönlendirilmemiş | Endpoint'i yerel öykünücüye çevir; gerçek bulut C4'e kadar yok |

## 💼 Portfolyo çıktısı
A6 altyapısının kod hâli (Terraform modülü) — sıfırdan kurulabilir, gösterilebilir.

## ⏭️ Sırada
[`C4 — Bulut Temelleri + Bütçe Alarmı`](C4-bulut-butce-alarmi.md)

---

> *"Elle kurulan altyapı bir anıdır; kod olan altyapı bir gerçektir — tekrar edilebilir olan."*
