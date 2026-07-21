---
description: "Ağ II: DNS → HTTP → TLS/sertifika — bir isim nasıl bir güvenli bağlantıya dönüşür, bu sırayla."
level: A
module: A3
estimated_hours: 16
prerequisites: [A2]
tags: [Learning Path, Networking]
---
# A3 — Ağ II: DNS → HTTP → TLS/Sertifika

> *"Bir adresi tarayıcıya yazdığın andan şifreli bağlantıya kadar geçen yolu bilen, yarısı DNS olan üretim arızalarının yarısını çözer."*

**Blok:** A — Sezgi · **Süre:** ~16 saat · **Ön koşul:** [`A2`](A2-ag-tcp-ip.md)

## 🎯 Bu modülü bitirdiğinde
- Bir isim çözümlemesini (DNS) adım adım izler, nerede yanlış cevap geldiğini gösterirsin.
- Bir HTTP isteğinin/yanıtının anatomisini (metod, durum kodu, başlık) okuyabilirsin.
- Bir TLS sertifikasının kimin için, kim tarafından, ne zamana kadar geçerli olduğunu doğrularsın.

## 🧠 Niye bu, niye şimdi
Bu sıra kasıtlıdır: TLS'i anlamak için HTTP'yi, HTTP'yi anlamak için DNS'i bilmen
gerekir. A6'da kuracağın gerçek servis bir isimle çağrılacak ve bir sertifika
sunacak — o zinciri buradan tanırsın. Atlamadan, bu sırayla.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| (bu modülün gövdesi — Faz 2'de sıfırdan yazılacak) | DNS → HTTP → TLS zinciri | — |

## 🔨 Lab
👉 `labs/build/L03-dns-http-tls/` — Faz 5'te oluşturulacak.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 2): bir alan adını çözüp cevabı doğrulayan komut + çıktı
- [ ] TODO (Faz 2): bir HTTP yanıtının başlıklarını okuyup durum kodunu yorumlama
- [ ] TODO (Faz 2): bir TLS sertifikasının geçerliliğini/sahibini doğrulayan komut

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
Doğrudan çıktı yok; A6'da servis + sertifika kurulumunda kullanılır.

## ⏭️ Sırada
[`A4 — Git Temeli`](A4-git-temeli.md)

---

> *"Sertifika hatası bir güvenlik değil, çoğu zaman bir zaman/isim/zincir hatasıdır — hangisi olduğunu görebilmek beceridir."*
