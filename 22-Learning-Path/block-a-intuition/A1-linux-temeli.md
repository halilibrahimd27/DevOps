---
description: "Linux temeli: process, filesystem, izin ve kullanıcı/grup — her şeyin üstünde durduğu zemin."
level: A
module: A1
estimated_hours: 16
prerequisites: []
tags: [Learning Path, Linux]
---
# A1 — Linux Temeli: Process, Filesystem, İzin, Kullanıcı/Grup

> *"Bir mühendisin altındaki her soyutlama eninde sonunda bir Linux process'ine iner."*

**Blok:** A — Sezgi · **Süre:** ~16 saat · **Ön koşul:** yok (patikanın giriş noktası)

## 🎯 Bu modülü bitirdiğinde
- Çalışan bir process'i bulur, kaynağını (CPU/bellek/açık dosya) inceler ve durdurabilirsin.
- Bir dosyanın izin/sahiplik dizisini okur, `chmod`/`chown` ile güvenli biçimde düzeltirsin.
- Kullanıcı, grup ve `sudo` arasındaki sınırı bir güvenlik sınırı olarak açıklayabilirsin.

## 🧠 Niye bu, niye şimdi
Sonraki her modül (ağ, deploy, container, K8s) bir Linux kutusunun içinde çalışır.
Process, dosya ve izin modelini görmeden hiçbir arızayı okuyamazsın. Bu yüzden
patika buradan başlar ve hiçbir ön bilgi varsaymaz.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| (bu modülün gövdesi — Faz 2'de sıfırdan yazılacak) | temel kavramlar | — |
| İleri (sonraya): [`16-Cheatsheets/linux-troubleshooting.md`](../../16-Cheatsheets/linux-troubleshooting.md) | USE method — B3'ten sonra | ~20 dk |

## 🔨 Lab
👉 `labs/build/L01-linux-temeli/` — Faz 5'te oluşturulacak.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 2): belirli bir process'i PID ile bulup kaynağını gösteren komut + çıktı
- [ ] TODO (Faz 2): bir dosyanın iznini `640`'a çeken ve doğrulayan komut dizisi
- [ ] TODO (Faz 2): "kullanıcı vs grup vs sudo sınırını kendi cümlelerinle açıkla" (yazılı)

## 🧪 Kendini test et
1. TODO (Faz 2) — kavramsal soru
2. TODO (Faz 2) — senaryo: "process yanıt vermiyor, ilk üç kontrolün?"
3. TODO (Faz 2) — tasarım sorusu

<details><summary>Cevaplar</summary>TODO (Faz 2)</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| TODO | TODO | TODO |

## 💼 Portfolyo çıktısı
Doğrudan portfolyo çıktısı yok; temel yetkinlik. Kanıt, sonraki blokların çıktılarında görünür.

## ⏭️ Sırada
[`A2 — Ağ I`](A2-ag-tcp-ip.md)

---

> *"Linux'u bilmek araç ezberlemek değil; sistemin sana ne söylediğini duyabilmektir."*
