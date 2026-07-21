# I18N-COVERAGE — Çeviri Durumu ve Öncelik

**Son güncelleme:** 2026-07-21

Plugin: `mkdocs-static-i18n` · `docs_structure: suffix` (`X.<locale>.md`) ·
`fallback_to_default: true`.

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
| **P0** | `README`, `docs/index`, `docs/about`, `Glossary` | ⬜ EN çevirisi yok (fallback TR) |
| **P1** | Patika omurgası (`22-Learning-Path/` README, CURRICULUM, modüller, …) | 🟡 TR yazılıyor (Faz 2: A1–A4 hazır). **EN twin BLOKE** — `qa.py` `^[A-F]\d+-` dosyalarda TR bölüm başlığı zorunlu tutuyor; `.en.md` twin QA'yı kırar. Önce `qa.py` locale-farkındalığı gerekir (bkz. STATE Açık kararlar). |
| **P2** | 21 klasör README'si | ⬜ |
| **P3** | En güçlü 15 deep-dive | ⬜ |
| **P4** | Kalan içerik | ⬜ |

## Notlar

- KVKK/BDDK/TR dokümanları EN versiyonda da **kalır** — global okur için "AB dışı
  bir veri koruma rejimi mühendislik kontrolüne nasıl çevrilir" örneği.
- EN kapsama oranı = (EN `.en.md` sayfa sayısı) / (toplam TR sayfa sayısı). Aşama B
  eşiği %60. Bu oran her i18n artışında burada güncellenir.

> *Çeviri zemin kuruldu; içerik çevirileri P0'dan başlayarak artımlı gelir.*
