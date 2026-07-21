---
description: "Bir uygulamayı elle ayağa kaldır: VM, nginx, bir DB, systemd unit ve log — container YOK. Patikanın çıpası."
level: A
module: A6
estimated_hours: 27
prerequisites: [A1, A2, A3, A4, A5]
tags: [Learning Path, Deployment]
---
# A6 — Bir Uygulamayı Elle Ayağa Kaldır (Container YOK)

> *"Sonraki her soyutlamanın neyi çözdüğünü, o soyutlamadan önceki acıyı yaşamış olan bilir. Bu modül o acıdır."*

**Blok:** A — Sezgi · **Süre:** ~27 saat · **Ön koşul:** [`A1`](A1-linux-temeli.md), [`A2`](A2-ag-tcp-ip.md), [`A3`](A3-ag-dns-http-tls.md), [`A4`](A4-git-temeli.md), [`A5`](A5-bash.md)

## 🎯 Bu modülü bitirdiğinde
- Bir VM üzerinde nginx + bir veritabanı + bir uygulamayı **elle** ayağa kaldırırsın.
- Uygulamayı bir `systemd` unit'i olarak tanımlar, yeniden başlatmada ayakta kalmasını sağlarsın.
- Servis loglarını bulur, okur ve bir arızayı bu bilgiyle daraltırsın.

## 🧠 Niye bu, niye şimdi
Bu modül kasıtlı olarak zahmetlidir. Deploy elle yapılır, bozulur, elle düzeltilir.
Container (C1), Terraform (C3) ve K8s (D1) sonradan geldiğinde, her birinin *tam
olarak hangi elle-işi* ortadan kaldırdığını buradan bileceksin. Bu modülü kolaylaştırma.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| (bu modülün gövdesi — Faz 2'de sıfırdan yazılacak) | elle deploy adımları | — |
| Kıvam referansı: [`21-Field-Notes/ansible/system-preparation.md`](../../21-Field-Notes/ansible/system-preparation.md) | gerçek kurulum notu | ~20 dk |

## 🔨 Lab
👉 `labs/build/L06-elle-deploy/` — Faz 5'te oluşturulacak.

## 💥 Kırık lab
👉 `labs/broken/K00-systemd-ayaga-kalkmiyor/` — Faz 5'te. Belirti: "systemd servisi
ayağa kalkmıyor." (Sebep gizli: port çakışması / yanlış path / izin.) K8s bilgisi
gerektirmez; debugging sezgisi tam burada başlar.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 2): uygulama bir `systemd` unit'i olarak çalışıyor ve `enable` edilmiş — komut + çıktı
- [ ] TODO (Faz 2): nginx uygulamanın önüne konulmuş, isteği geçiriyor — doğrulama
- [ ] TODO (Faz 2): K00 kırık lab'ı yardımsız (en fazla hint-1/2) çözüldü
- [ ] TODO (Faz 2): "hangi adımlar en çok zaman aldı, container bunu nasıl değiştirir" (yazılı)

## 🧪 Kendini test et
1. TODO (Faz 2)
2. TODO (Faz 2) — senaryo: "servis boot'ta gelmiyor, ilk üç kontrolün?"
3. TODO (Faz 2)

<details><summary>Cevaplar</summary>TODO (Faz 2)</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| TODO | TODO | TODO |

## 💼 Portfolyo çıktısı
Elle deploy edilmiş, systemd ile yönetilen çalışan bir servis + kurulum notların.
Bu, C3'te Terraform'a ve D1'de K8s'e dönüştüreceğin temeldir.

## ⏭️ Sırada
[`B1 — Log Okuma`](../block-b-visibility/B1-log-okuma.md)

---

> *"Kolaylaştırılmış bir A6, bütün patikanın altını oyar. Zahmet burada bilerek bırakılmıştır."*
