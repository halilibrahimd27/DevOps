---
description: "Veritabanı production — özellikle restore: test edilmemiş backup, backup değildir."
level: E
module: E4
estimated_hours: 14
prerequisites: [A6, D2]
tags: [Learning Path, Databases]
---
# E4 — Veritabanı Production: Özellikle Restore

> *"Test edilmemiş bir backup, backup değildir — sadece bir umuttur."*

**Blok:** E — Sahiplik · **Süre:** ~14 saat · **Ön koşul:** [`A6`](../block-a-intuition/A6-elle-deploy.md), [`D2`](../block-d-orchestration/D2-k8s-production.md)

## 🎯 Bu modülü bitirdiğinde
- Bir veritabanının backup'ını alır ve **restore'unu gerçekten test edersin.**
- Restore süresini (RTO) ve veri kaybı penceresini (RPO) ölçüp raporlarsın.
- Sıfır kesintili bir şema değişikliğinin niçin dikkatli sıralama gerektirdiğini açıklarsın.

## 🧠 Niye bu, niye şimdi
A6'da bir DB kurdun; D2'de production ayarlarını gördün. Ama asıl sahiplik testi
şudur: **veri gittiğinde geri getirebiliyor musun?** Bu, D → E geçiş sinyaliyle
(kendi kurduğun bir şey bozuldu ve sen geri getirdin) doğrudan bağlıdır.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`10-Databases-Production/Backup-Restore-Patterns.md`](../../10-Databases-Production/Backup-Restore-Patterns.md) | backup/restore desenleri | ~30 dk |
| [`10-Databases-Production/Zero-Downtime-Migrations.md`](../../10-Databases-Production/Zero-Downtime-Migrations.md) | şema değişimi | ~25 dk |

## 🔨 Lab
👉 `labs/build/L20-veritabani-restore/` — Faz 5'te.

## 💥 Kırık lab
👉 `labs/broken/K08-restore-basarisiz/` — Faz 5'te. Belirti: "Restore çalışmıyor /
eksik veri geliyor." (Gerçekçi sebep gizli: bozuk/eksik backup / yanlış sıra / sürüm uyumsuzluğu.)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 4): backup alınıp **restore edildi ve doğrulandı** — veri bütünlüğü kanıtı
- [ ] TODO (Faz 4): RTO/RPO ölçüldü ve yazıldı
- [ ] TODO (Faz 4): K08 kırık lab'ı çözüldü, `verify.sh` geçiyor

## 🧪 Kendini test et
1. TODO (Faz 4)
2. TODO (Faz 4)
3. TODO (Faz 4)

<details><summary>Cevaplar</summary>TODO (Faz 4)</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| TODO | TODO | TODO |

## 💼 Portfolyo çıktısı
Test edilmiş bir restore prosedürü + RTO/RPO raporu — nadir ve değerli bir kanıt.

## ⏭️ Sırada
[`E5 — İleri Kırık Lab / Chaos`](E5-chaos.md)

---

> *"Backup'ını en kötü anda değil, sakin bir salı öğleden sonra test et."*
