---
description: "Capstone 1 (Blok C sonu): A6 uygulamasını container + CI + Terraform ile sıfırdan tekrarlanabilir hâle getir."
level: C
tags: [Learning Path, Capstone]
---
# 🏁 Capstone 1 — Blok C Sonu: Tekrarlanabilir Sistem

> *"C → D geçiş sinyali: sistemini sıfırdan, elle hiçbir şeye dokunmadan yeniden kurabiliyor musun? Bu capstone o sorunun kanıtıdır."*

**Kapı:** Blok C sonu · **Süre:** ~20 saat · **Ön koşul:** Blok C tamamlandı ([`C1`](../block-c-reproducibility/C1-container.md)–[`C4`](../block-c-reproducibility/C4-bulut-butce-alarmi.md)) + [`Blok C sınavı`](../block-c-reproducibility/STAGE-EXAM.md) geçildi

## 🎯 Bu capstone'da
A6'da elle kurduğun uygulamayı uçtan uca **tekrarlanabilir** hâle getirirsin:
container'a alınmış (C1), CI ile otomatik build/registry (C2), Terraform ile
altyapı (C3), bütçe alarmı ve `destroy` disiplini (C4). Sınav bilgiyi ölçtü; bu
capstone tek bir **teslim edilebilir sistem** üretir.

## 📦 Şartname
Tek bir git reposu teslim edersin. İçinde:

- **Uygulama + Dockerfile:** A6 uygulaması multi-stage, non-root bir image olarak
  build ediliyor. `docker compose up` ile uygulama + DB birlikte ayağa kalkıyor.
- **CI pipeline'ı (`.github/workflows/…`):** `test → build → (SHA/semver) tag → registry`.
  `:latest` yok. Pipeline yeşil.
- **Terraform (`infra/`):** Altyapı (yerelde LocalStack) `apply` ile sıfırdan kuruluyor,
  `destroy` ile temizleniyor. State'in nerede/nasıl tutulduğu README'de yazılı.
- **Bütçe alarmı:** `aws_budgets_budget` (veya eşdeğeri) tanımlı, bir bildirim kanalına
  bağlı, eşiği düşürülerek **tetiklenmiş** olduğu kanıtlı.
- **`RECREATE.md`:** Sistemi sıfırdan kuran komut dizisi — makinede hiçbir şey yokken
  bu dosyayı takip eden biri sistemi ayağa kaldırabilmeli.

> 🔒 **Placeholder güvenliği:** Repoda gerçek IP/domain/credential yok. `<REGISTRY>`,
> `<YOUR_EMAIL>`, LocalStack sahte kimlikleri (`test`/`test`). Sır varsa referansla
> geçir, repoya düz metin yazma (C→D köprüsü: D3 secret yönetimi).

## ✅ Kabul kriterleri
Hepsi doğrulanmadan capstone tamamlanmadı:
- [ ] Temiz bir dizinde `RECREATE.md`'yi izleyerek sistem sıfırdan kuruldu — komut/çıktı kanıtı
- [ ] `terraform apply` → `destroy` → `apply` **aynı** sonucu üretiyor (idempotency kanıtı)
- [ ] Bir commit → CI → registry akışı yeşil; image sürümlü etiketle yayımlanıyor (`grep -r ":latest"` boş)
- [ ] `docker compose up` sonrası uygulama sağlık ucu `200` döndürüyor
- [ ] Bütçe alarmı eşiği düşürülüp **tetiklendi**; bildirim kanıtı ekte
- [ ] `terraform destroy` sonrası açık kaynak kalmadığı doğrulandı (maliyet tuzağı kapalı)

## 📊 Rubrik
Her eksen 0–2 (0 = yok, 1 = kısmen, 2 = tam). **Geçme ≥ 8/10 ve hiçbir eksen 0 değil.**

| Eksen | 0 | 1 | 2 |
|---|---|---|---|
| Tekrarlanabilirlik | Elle adım gerekiyor | Çoğu otomatik, birkaç elle düzeltme | `RECREATE.md` + `apply` tek seferde kurar |
| Temizlik (`destroy`) | Açık kaynak kalıyor | `destroy` var, doğrulanmamış | `destroy` sonrası sıfır kaynak kanıtlı |
| Güvenli varsayılan | Root image, `:latest`, düz metin sır | Biri düzeltilmiş | Non-root + pinli tag + referanslı sır |
| Bütçe disiplini | Alarm yok | Alarm kurulu, test edilmemiş | Alarm **tetiklenerek** test edilmiş |
| Dokümantasyon | README yok/eksik | Kurar ama boşluk var | `RECREATE.md` yabancı biri için yeterli |

## 💼 Portfolyo çıktısı
Bu capstone bir **portfolyo projesidir** — CV'de "tekrarlanabilir altyapı" satırının
kanıtıdır. Repo README'sinde şu şablonu kullan (Faz 7'de `PORTFOLIO.md` modül↔CV
satırı eşlemesini ekleyecek):

```markdown
# <PROJE_ADI> — Tekrarlanabilir Deploy

**Ne:** Bir web uygulamasını container + CI + Terraform ile sıfırdan
tekrarlanabilir şekilde kurar. (DevSecOps Handbook · Capstone 1)

## Mimari
- Uygulama: <DİL/ÇATI>, multi-stage Docker image (non-root)
- CI: test → build → SHA-tag → <REGISTRY> (`:latest` yok)
- Altyapı: Terraform (yerelde LocalStack), `apply`/`destroy` idempotent
- Maliyet koruması: bütçe alarmı (tetiklenerek test edildi)

## Sıfırdan kurulum
`RECREATE.md`'ye bak — tek komut dizisiyle ayağa kalkar.

## Ne öğrendim / hangi kararı niçin verdim
- <örn. multi-stage niçin, state niçin uzakta, `:latest` niçin yasak>
```

## ⏭️ Sırada
[`D1 — K8s Temel`](../block-d-orchestration/D1-k8s-temel.md)

---

> *"Tekrarlanabilirlik bir özellik değil, bir kanıttır: aynı girdiyle aynı sistemi ikinci kez kurabilmek."*
