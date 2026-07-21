---
description: "Bash — iş görecek kadar kabuk: değişken, döngü, koşul, pipe ve güvenli script yazımı."
level: A
module: A5
estimated_hours: 12
prerequisites: [A1, A4]
tags: [Learning Path, Bash]
---
# A5 — Bash: İş Görecek Kadar Kabuk

> *"Bash'i dil olarak öğrenmiyorsun; günlük işi otomatikleştirecek kadar öğreniyorsun."*

**Blok:** A — Sezgi · **Süre:** ~12 saat · **Ön koşul:** [`A1`](A1-linux-temeli.md), [`A4`](A4-git-temeli.md)

## 🎯 Bu modülü bitirdiğinde
- Değişken, koşul ve döngü içeren, hata durumunda duran (`set -euo pipefail`) bir script yazarsın.
- Komutları pipe ile zincirler, çıktıyı filtreleyip işleyebilirsin.
- Bir script'in nerede ve niçin patladığını okuyup düzeltirsin.

## 🧠 Niye bu, niye şimdi
Lab'ların çoğu `verify.sh`/`setup.sh` gibi kabuk scriptleriyle çalışır; A6'da
servisleri elle ayağa kaldırırken tekrar eden işi Bash'e devredersin. Otomasyonun
en ilkel ve en her yerde bulunan biçimi budur.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| (bu modülün gövdesi — Faz 2'de sıfırdan yazılacak) | Bash temeli + güvenli script | — |

## 🔨 Lab
👉 `labs/build/L05-bash/` — Faz 5'te oluşturulacak.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 2): argüman alan, hata durumunda duran ve `bash -n`'den geçen bir script
- [ ] TODO (Faz 2): bir log dosyasını pipe zinciriyle özetleyen tek satır
- [ ] TODO (Faz 2): "niçin `set -euo pipefail`" (yazılı gerekçe)

## 🧪 Kendini test et
1. TODO (Faz 2)
2. TODO (Faz 2)
3. TODO (Faz 2)

<details><summary>Cevaplar</summary>TODO (Faz 2)</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| TODO | TODO | TODO |

## 💼 Portfolyo çıktısı
Yeniden kullanılabilir birkaç yardımcı script — A6 ve sonrası için altyapı.

## ⏭️ Sırada
[`A6 — Elle Deploy`](A6-elle-deploy.md)

---

> *"Bir işi ikinci kez elle yapıyorsan, üçüncüsü için onu bir script'e koy."*
