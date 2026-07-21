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
- [ ] commit → test → build → registry akışı yeşil geçiyor — pipeline logu gösterilebiliyor
- [ ] image registry'ye sürümlü etiketle (`:latest` değil; ör. commit SHA / semver) yayımlanıyor
- [ ] Kırık bir adımın hangi aşamada, niçin patladığını logdan okuyup düzeltebiliyorsun — yazılı teşhis notu
- [ ] "Pipeline yeşil ama neyi doğruladı" sorusunu kendi pipeline'ın için yazılı yanıtlayabiliyorsun

## 🧪 Kendini test et
1. Bir test yerelde geçip pipeline'da patlıyor. Bunun en yaygın iki sebebi ne?
2. `:latest` etiketi production'da niçin yasak? Bir image'ı sürümlemenin sağlam bir yolu ne?
3. Pipeline'ın 8 dakika sürüyor ve ekibi yavaşlatıyor. İlk optimizasyonun ne olurdu, niye?

<details><summary>Cevaplar</summary>

1. (a) Ortam farkı — yerelde farklı bir bağımlılık sürümü, farklı bir env değişkeni ya da yüklü bir araç var; (b) gizli yerel durum — yerelde var olan bir dosya/kimlik CI'ın temiz ortamında yok. Çözüm: sürümleri lock dosyasıyla sabitle, CI'ın kullandığı env'i logla.
2. `:latest` değişebilir bir referanstır: aynı etiket bugün ve yarın farklı bir image'ı gösterebilir → hangi sürümün çalıştığını bilemezsin, geri alamazsın. Değişmez bir kimlik kullan: commit SHA veya semver. Detay [`02-CI-CD/Pipeline-Patterns.md`](../../02-CI-CD/Pipeline-Patterns.md).
3. Cache. Bağımlılık ve Docker katman cache'i çoğu pipeline'da en büyük tekrarı yapan adımdır; bağımsız işleri paralelleştirmek ikinci adımdır. "Önce ölç, sonra optimize et" — hangi adımın uzun sürdüğünü logdan gör.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Yerelde geçen test CI'da patlıyor | Ortam farkı (bağımlılık sürümü, env) | Sürümleri lock'la; CI'ın env'ini logla; temiz ortamda tekrar üret |
| `docker push` reddediliyor | Registry kimlik doğrulaması eksik/yanlış | Registry credential'ını secret olarak ver; login adımını doğrula |
| Pipeline her commit'te sıfırdan kuruyor | Cache yok | Bağımlılık/katman cache ekle (`02-CI-CD/Caching-Strategies.md`) |
| Build yeşil ama image çalışmıyor | Pipeline image'ı gerçekten çalıştırmıyor | Bir "smoke test" adımı ekle: container'ı ayağa kaldır, sağlık kontrolü yap |

## 💼 Portfolyo çıktısı
Yeşil bir CI pipeline'ı ve registry'de sürümlü image'lar — CV'de somut bir satır.

## ⏭️ Sırada
[`C3 — Terraform`](C3-terraform.md)

---

> *"Pipeline yeşilse güvenirsin; ama neyi doğruladığını bilmiyorsan yeşil sadece bir renktir."*
