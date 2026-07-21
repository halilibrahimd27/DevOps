---
description: "İlk kırık lab: bilerek bozulmuş bir VM sisteminde arızayı log ve metrikle bulup kanıtlamak."
level: B
module: B3
estimated_hours: 12
prerequisites: [B1, B2]
tags: [Learning Path, Debugging]
---
# B3 — İlk Kırık Lab

> *"Tutorial 'şunu kur' der; kırık lab 'şunu tamir et' der. İkincisi mühendis yetiştirir."*

**Blok:** B — Görebilmek · **Süre:** ~12 saat · **Ön koşul:** [`B1`](B1-log-okuma.md), [`B2`](B2-metrik-prometheus.md)

## 🎯 Bu modülü bitirdiğinde
- Ne bozulduğu söylenmeden, yalnızca belirtiden yola çıkıp arızayı daraltırsın.
- Hipotezini log ve metrikle **kanıtlarsın**, tahmine dayanmazsın.
- Kök sebebe giden teşhis akışını yazılı olarak anlatabilirsin.

## 🧠 Niye bu, niye şimdi
Kırık lab, B3'ten itibaren patikanın omurgasıdır. Blok C'ye (karmaşıklık eklemek)
geçmeden önce, kurduğun sistemi görebildiğini ve bir arızayı kanıtlayabildiğini
göstermen gerekir. **Bu, B → C geçiş sinyalinin sınavıdır.**

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| Teşhis metodu: [`16-Cheatsheets/linux-troubleshooting.md`](../../16-Cheatsheets/linux-troubleshooting.md) | USE method burada devreye girer | ~25 dk |

## 💥 Kırık lab
👉 `labs/broken/K01-kirik-vm/` — Faz 5'te. Belirti: "Servis ayağa kalkmıyor / yanıt
vermiyor." (Gerçekçi sebep gizli: yanlış izin / port çakışması / disk dolu /
systemd unit hatası.) `README.md` **asla** ne bozulduğunu söylemez.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 2): `bash labs/broken/K01-kirik-vm/verify.sh` sıfır hatayla geçiyor
- [ ] TODO (Faz 2): kök sebebi log/metrik kanıtıyla gösteren yazılı teşhis akışı
- [ ] TODO (Faz 2): "dokümana bakmadan üç komutla nasıl daralttın" (yazılı — A→B sinyali)

## 🧪 Kendini test et
1. TODO (Faz 2)
2. TODO (Faz 2)
3. TODO (Faz 2)

<details><summary>Cevaplar</summary>TODO (Faz 2)</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| TODO | TODO | `hints/` klasörünü sırayla aç: hint-1 (yön) → hint-2 (daralt) → hint-3 |

## 💼 Portfolyo çıktısı
Yazdığın teşhis akışı — bir "arıza günlüğü"nün ilk sayfası. E3'te postmortem'e evrilir.

## ⏭️ Sırada
[`C0 — Ops için Python`](../block-c-reproducibility/C0-ops-python.md)

---

> *"Bir arızayı yardımsız daraltabilmek, bu patikanın öğrettiği asıl beceridir."*
