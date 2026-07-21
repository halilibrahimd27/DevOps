---
description: "Capstone 1 (Blok C sonu): A6 uygulamasını container + CI + Terraform ile sıfırdan tekrarlanabilir hâle getir."
level: C
tags: [Learning Path, Capstone]
---
# 🏁 Capstone 1 — Blok C Sonu: Tekrarlanabilir Sistem

> *"C → D geçiş sinyali: sistemini sıfırdan, elle hiçbir şeye dokunmadan yeniden kurabiliyor musun? Bu capstone o sorunun kanıtıdır."*

**Kapı:** Blok C sonu · **Süre:** ~20 saat · **Ön koşul:** Blok C tamamlandı ([`C1`](../block-c-reproducibility/C1-container.md)–[`C4`](../block-c-reproducibility/C4-bulut-butce-alarmi.md))

## 🎯 Bu capstone'da
A6'da elle kurduğun uygulamayı uçtan uca **tekrarlanabilir** hâle getirirsin:
container'a alınmış (C1), CI ile otomatik build/registry (C2), Terraform ile
altyapı (C3), bütçe alarmı ve `destroy` disiplini (C4).

## 📦 Şartname (Faz 6'da netleşir)
- Uygulama bir image olarak build ediliyor ve registry'ye sürümlü yayımlanıyor.
- Altyapı Terraform ile sıfırdan kurulup yıkılabiliyor (yerel: LocalStack).
- CI pipeline'ı yeşil; `:latest` kullanılmıyor.
- Bütçe alarmı kurulu ve test edilmiş.

## ✅ Kabul kriterleri
- [ ] TODO (Faz 6): `terraform apply` ile ortam sıfırdan kuruluyor, `destroy` ile temizleniyor
- [ ] TODO (Faz 6): bir commit → CI → registry akışı yeşil, image sürümlü
- [ ] TODO (Faz 6): "elle hiçbir şeye dokunmadan yeniden kurdum" — komut/çıktı kanıtı

## 📊 Rubrik
TODO (Faz 6): tekrarlanabilirlik, temizlik, güvenli varsayılanlar, dokümantasyon eksenlerinde puanlama.

## 💼 Portfolyo README şablonu
TODO (Faz 6): projeyi CV'de ve repoda nasıl sunacağına dair şablon → `PORTFOLIO.md` (Faz 7'de eklenecek).

## ⏭️ Sırada
[`D1 — K8s Temel`](../block-d-orchestration/D1-k8s-temel.md)

---

> *"Tekrarlanabilirlik bir özellik değil, bir kanıttır: aynı girdiyle aynı sistemi ikinci kez kurabilmek."*
