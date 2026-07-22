---
description: "Container: image, katman, multi-stage build ve docker compose — A6'daki elle deploy'u tekrarlanabilir kılmak."
level: C
module: C1
estimated_hours: 14
prerequisites: [A6, B3]
tags: [Learning Path, Containers]
---
# C1 — Container: Image, Katman, Multi-Stage, Compose

> *"Container 'benim makinemde çalışıyordu'yu çözer — ama önce o acıyı A6'da yaşamış olman gerekir."*

**Blok:** C — Tekrarlanabilirlik · **Süre:** ~14 saat · **Ön koşul:** [`A6`](../block-a-intuition/A6-elle-deploy.md), [`B3`](../block-b-visibility/B3-ilk-kirik-lab.md)

## 🎯 Bu modülü bitirdiğinde
- A6'daki uygulamayı bir image'a alır, katman ve boyut kararlarını gerekçelendirirsin.
- Multi-stage build ile küçük, üretime uygun bir image üretirsin.
- `docker compose` ile uygulama + veritabanını birlikte ayağa kaldırırsın.

## 🧠 Niye bu, niye şimdi
A6'da servisi elle kurdun; her yeni makinede aynı adımları tekrarlamak zorundaydın.
Container bu tekrarı bir image'a hapseder. C2 (CI) bu image'ı otomatik üretecek,
D1 (K8s) bu image'ı çalıştıracak.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`04-Containers/Dockerfile-Best-Practices.md`](../../04-Containers/Dockerfile-Best-Practices.md) | Dockerfile + katman kararları | ~30 dk |
| [`04-Containers/Multi-Stage-Builds.md`](../../04-Containers/Multi-Stage-Builds.md) | küçük image | ~20 dk |

## 🔨 Lab
👉 [`labs/build/L09-container/`](../labs/build/L09-container/)

## 💥 Kırık lab
👉 [`labs/broken/K02-container-hatasi/`](../labs/broken/K02-container-hatasi/) — Belirti: "Container çalışmıyor /
bağlanılamıyor." (Gerçekçi sebep gizli: yanlış image tag / port eşlemesi / eksik
env.) Container hataları yeni başlayanın en sık takıldığı yerdir — bu yüzden zorunlu.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] A6 uygulaması bir image olarak çalışıyor; `docker compose up` ile uygulama + DB birlikte ayağa kalkıyor
- [ ] Multi-stage ile image küçüldü — `docker images` çıktısında önce/sonra boyut farkı gösterilebiliyor
- [ ] `bash labs/broken/K02-container-hatasi/verify.sh` yardımsız çözümden sonra sıfır hatayla geçiyor
- [ ] Bir katmanın niçin cache'lendiğini/geçersizleştiğini kendi cümlelerinle **yazdın** (L09 `report.txt`)

## 🧪 Kendini test et
1. Bir image katmanı nedir? Dockerfile'da bağımlılık kurulumunu kaynak kodu kopyalamadan **önce** koymak build süresini niçin kısaltır?
2. `docker run` sonrası container anında `Exited (0)` oluyor. Dokümana bakmadan ilk üç kontrolün ne?
3. 1.2 GB'lik bir uygulama image'ını küçültmen gerekiyor. Multi-stage ile `slim`/distroless taban arasında hangisini seçerdin, hangi kısıt altında?

<details><summary>Cevaplar</summary>

1. Katman, Dockerfile'daki bir talimatın ürettiği salt-okunur değişiklik kümesidir; image bu katmanların üst üste binmesidir. Bağımlılıklar kaynak koddan önce kurulursa, yalnız kod değiştiğinde bağımlılık katmanı cache'ten gelir, yeniden kurulmaz. Detay: [`04-Containers/Dockerfile-Best-Practices.md`](../../04-Containers/Dockerfile-Best-Practices.md).
2. (a) `docker logs <id>` — süreç bir hatayla mı çıktı; (b) `CMD`/`ENTRYPOINT` uzun süren bir süreç mi yoksa hemen biten bir komut mu; (c) uygulama foreground'da mı kalıyor yoksa arka plana mı düşüyor — container ana süreç bitince kapanır.
3. Multi-stage her durumda kazandırır (build araçları son image'a girmez). Taban kısıta bağlı: hızlı hata ayıklama/shell gerekiyorsa `slim`; en küçük yüzey ve en az açık isteniyorsa distroless — ama distroless'ta shell yoktur, teşhis zorlaşır. Ödünleşim [`04-Containers/Multi-Stage-Builds.md`](../../04-Containers/Multi-Stage-Builds.md)'de.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `docker build` her seferinde bağımlılıkları yeniden kuruyor | `COPY . .` bağımlılık kurulumundan önce | Önce sadece bağımlılık manifestini kopyala + kur, sonra kaynağı kopyala |
| Container `Exited (0)` ile hemen kapanıyor | Ana süreç foreground değil / komut bitiyor | `docker logs`; `CMD`'nin uzun süren bir süreç olduğunu doğrula |
| `compose`'ta uygulama DB'ye bağlanamıyor | Adres olarak `localhost` yazılmış | DB'ye compose **servis adıyla** bağlan; aynı ağda olduklarını doğrula |
| Image beklenenden çok büyük | Tek-stage; build araçları image'da | Multi-stage'e geç; son stage'e yalnız çalışma zamanı gereksinimleri |

## 💼 Portfolyo çıktısı
A6 uygulamasının container'lı, `compose` ile ayağa kalkan hâli — repoda gösterilebilir.

## ⏭️ Sırada
[`C2 — CI`](C2-ci.md)

---

> *"Image bir kez doğru kurulursa, 'çalışan makine' diye bir efsane kalmaz."*
