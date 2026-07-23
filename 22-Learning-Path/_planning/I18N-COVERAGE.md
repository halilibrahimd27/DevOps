# I18N-COVERAGE — Çeviri Durumu ve Öncelik

**Son güncelleme:** 2026-07-23

Plugin: `mkdocs-static-i18n` · `docs_structure: suffix` (`X.<locale>.md`) ·
`fallback_to_default: true`.

**EN kapsama:** 3 site sayfası / 334 TR temel sayfası ≈ **%0.9** (Aşama B eşiği %60).
(`README.en.md` GitHub-only, siteye stage edilmez → oran dışı.)

## Aşama

- **Aşama A (şimdi):** TR varsayılan (kök `X.md` = `X.tr.md` eşdeğeri), EN `/en/`
  altında **kısmi**. Çevirisi olmayan sayfa TR içeriğine fallback eder → iki-locale
  build fallback ile hatasız geçer.
- **Aşama B (sonra):** EN kapsama **≥ %60** olunca EN varsayılan yapılır
  (`default: true` en'e taşınır, TR `/tr/`'ye iner). **Şimdi yapma.**

## Kurallar

- İç linkler locale eki OLMADAN yazılır: `[x](Kubernetes-Hardening.md)` ✅ /
  `Kubernetes-Hardening.tr.md` ❌ (plugin locale'i kendi ekler).
- Yeni yazılan patika içeriği baştan **iki dilli** üretilir (`X.md` + `X.en.md`
  ya da `X.tr.md` + `X.en.md`).

## Öncelik ve durum

| Öncelik | Kapsam | Durum |
|---|---|---|
| **P0** | `README`, `docs/index`, `docs/about`, `Glossary` | ✅ **EN twin hazır** (2026-07-23) — `README.en.md`, `docs/index.en.md`, `docs/about.en.md`, `Glossary.en.md`. build-docs.sh 3 site sayfasını stage ediyor; iki-locale build hatasız. |
| **P1** | Patika omurgası (`22-Learning-Path/` README, CURRICULUM, NOT-YET, PLACEMENT, PROGRESS-TEMPLATE, STUDY-METHOD, COST-GUARDRAILS, TROUBLESHOOTING, PORTFOLIO + A0…F5 modülleri) | ⬜ **Sıradaki** — `qa.py` locale-farkındalığı geldi (`LOCALE_RE`, `check_modules`/`check_curriculum` `.en.md`'yi ayırıyor) → EN twin artık BLOKE değil. Modül `.en.md` twin'leri modül-bütünlük denetiminden muaf. |
| **P2** | 21 klasör README'si | ⬜ |
| **P3** | En güçlü 15 deep-dive | ⬜ |
| **P4** | Kalan içerik | ⬜ |

## Notlar

- KVKK/BDDK/TR dokümanları EN versiyonda da **kalır** — global okur için "AB dışı
  bir veri koruma rejimi mühendislik kontrolüne nasıl çevrilir" örneği.
- EN kapsama oranı = (EN `.en.md` sayfa sayısı) / (toplam TR sayfa sayısı). Aşama B
  eşiği %60. Bu oran her i18n artışında burada güncellenir.

> *Çeviri zemin kuruldu; içerik çevirileri P0'dan başlayarak artımlı gelir.*
