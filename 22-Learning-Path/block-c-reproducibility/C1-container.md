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
👉 `labs/build/L09-container/` — Faz 5'te oluşturulacak.

## 💥 Kırık lab
👉 `labs/broken/K02-container-hatasi/` — Faz 5'te. Belirti: "Container çalışmıyor /
bağlanılamıyor." (Gerçekçi sebep gizli: yanlış image tag / port eşlemesi / eksik
env.) Container hataları yeni başlayanın en sık takıldığı yerdir — bu yüzden zorunlu.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 3): A6 uygulaması bir image olarak çalışıyor, `compose up` ile DB'yle birlikte
- [ ] TODO (Faz 3): multi-stage ile image boyutu belirgin küçüldü — önce/sonra kanıtı
- [ ] TODO (Faz 3): K02 kırık lab'ı yardımsız çözüldü, `verify.sh` geçiyor

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
A6 uygulamasının container'lı, `compose` ile ayağa kalkan hâli — repoda gösterilebilir.

## ⏭️ Sırada
[`C2 — CI`](C2-ci.md)

---

> *"Image bir kez doğru kurulursa, 'çalışan makine' diye bir efsane kalmaz."*
