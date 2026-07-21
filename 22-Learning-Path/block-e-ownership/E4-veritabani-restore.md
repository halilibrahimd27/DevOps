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
- [ ] Bir backup alındı ve **temiz bir ortama restore edildi**; veri bütünlüğü bir sorguyla (satır sayısı/checksum) doğrulandı
- [ ] RTO (restore süresi) ve RPO (veri kaybı penceresi) ölçülüp yazıldı
- [ ] Backup'ın erişim + at-rest şifreleme kontrolü yazıldı (kim erişebilir, şifreli mi)
- [ ] `bash labs/broken/K08-restore-basarisiz/verify.sh` çözümden sonra sıfır hatayla geçiyor

## 🧪 Kendini test et
1. "Backup her gece alınıyor" cümlesi niçin tek başına güvence vermez?
2. RTO ile RPO farkı ne; hangisini sıfıra yaklaştırmak genelde daha pahalıdır?
3. Backup dosyaları herkese açık bir bucket'ta duruyor. Sorun ne?

<details><summary>Cevaplar</summary>

1. Çünkü alınması restore edilebildiğini kanıtlamaz. Bozuk, eksik veya yanlış sürümle alınmış bir backup ancak restore denendiğinde ortaya çıkar — test edilmemiş backup yalnızca bir umuttur. Desenler [`10-Databases-Production/Backup-Restore-Patterns.md`](../../10-Databases-Production/Backup-Restore-Patterns.md)'de.
2. RTO = geri gelme süresi (kesinti hedefi); RPO = kabul edilen veri kaybı penceresi. RPO'yu sıfıra yaklaştırmak (senkron replikasyon / sürekli WAL) genelde daha pahalıdır, çünkü her yazımı anında ikinci bir yere de yazman gerekir.
3. Backup veritabanının tamamıdır — açık bucket, tüm veriyi ve genelde en zayıf erişim kontrollü kopyayı sızdırır. Backup en az canlı DB kadar korunmalı: erişim kısıtı + at-rest şifreleme. Şema değişim tarafı [`10-Databases-Production/Zero-Downtime-Migrations.md`](../../10-Databases-Production/Zero-Downtime-Migrations.md)'de.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Restore çalışıyor ama veri eksik | Yanlış sıra / kısmi backup / farklı sürüm | Sıralı bağımlılıkları ve sürüm uyumunu doğrula; tam yedeği kullan |
| Restore çok uzun sürüyor (RTO aşıldı) | Yöntem yanlış (logical dump, büyük DB) | Fiziksel backup + PITR'e geç; restore süresini önceden ölç |
| Backup alınıyor ama kimse test etmemiş | Restore prosedürü yazılı değil | Sakin bir günde tam restore provası yap, adımları yaz |
| Backup'a erişim denetlenmemiş | Şifreleme/erişim kontrolü yok | Erişimi kısıtla, at-rest şifrele, erişimi denetim kaydına bağla |

## 💼 Portfolyo çıktısı
Test edilmiş bir restore prosedürü + RTO/RPO raporu — nadir ve değerli bir kanıt.

## ⏭️ Sırada
[`E5 — İleri Kırık Lab / Chaos`](E5-chaos.md)

---

> *"Backup'ını en kötü anda değil, sakin bir salı öğleden sonra test et."*
