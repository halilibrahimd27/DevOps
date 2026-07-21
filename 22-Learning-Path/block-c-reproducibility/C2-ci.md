---
description: "CI: test → build → artifact → registry — her commit'te aynı adımların otomatik ve kanıtlı çalışması."
level: C
module: C2
estimated_hours: 16
prerequisites: [A4, C0, C1]
tags: [Learning Path, CI-CD]
---
# C2 — CI: test → build → artifact → registry

> *"CI, 'her seferinde elle yaptığım adımları' bir makinenin her commit'te yapması ve kanıtlamasıdır."*

**Blok:** C — Tekrarlanabilirlik · **Süre:** ~16 saat · **Ön koşul:** [`A4`](../block-a-intuition/A4-git-temeli.md), [`C0`](C0-ops-python.md), [`C1`](C1-container.md)

## 🎯 Bu modülü bitirdiğinde
- Bir commit'te test → build → image → registry adımlarını otomatik çalıştıran bir pipeline kurarsın.
- Build çıktısını (artifact/image) bir registry'ye sürümlü olarak yayımlarsın.
- Bir pipeline hatasının hangi adımda ve niçin patladığını okuyup düzeltirsin.

## 🧠 Niye bu, niye şimdi
C1'de image'ı elle ürettin; her değişiklikte bunu elle yapmak sürdürülemez. CI bu
adımları her commit'e bağlar. D4 (supply chain: tarama + imzalama) **bu pipeline'ın
devamıdır**, ayrı bir ders değil.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`02-CI-CD/Pipeline-Patterns.md`](../../02-CI-CD/Pipeline-Patterns.md) | pipeline anatomisi | ~30 dk |
| [`02-CI-CD/GitHub-Actions-Recipes.md`](../../02-CI-CD/GitHub-Actions-Recipes.md) | çalışır örnekler | ~30 dk |

## 🔨 Lab
👉 `labs/build/L10-ci/` — Faz 5'te oluşturulacak.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 3): commit → test → build → registry akışı yeşil geçiyor — pipeline logu
- [ ] TODO (Faz 3): image registry'de sürümlü etiketle yayımlanıyor (`:latest` değil)
- [ ] TODO (Faz 3): "kırık bir adımı nasıl teşhis ettin" (yazılı)

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
Yeşil bir CI pipeline'ı ve registry'de sürümlü image'lar — CV'de somut bir satır.

## ⏭️ Sırada
[`C3 — Terraform`](C3-terraform.md)

---

> *"Pipeline yeşilse güvenirsin; ama neyi doğruladığını bilmiyorsan yeşil sadece bir renktir."*
