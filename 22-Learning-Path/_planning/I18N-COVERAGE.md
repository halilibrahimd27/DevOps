# I18N-COVERAGE — Çeviri Durumu ve Öncelik

**Son güncelleme:** 2026-07-23

Plugin: `mkdocs-static-i18n` · `docs_structure: suffix` (`X.<locale>.md`) ·
`fallback_to_default: true`.

**EN kapsama:** 73 site sayfası / 334 TR temel sayfası ≈ **%21.9** (Aşama B eşiği %60).
(P0: 3 sayfa + P1a rehber twin'leri: 9 sayfa + P1b Blok A+B: 12 sayfa + P1b Blok C+D:
12 sayfa + P1b Blok E+F: 11 sayfa + P2 21 klasör README'si: 21 sayfa + P3 slice-1: 5 deep-dive
= 73. Kök `README.en.md` GitHub-only, siteye stage edilmez → oran dışı.)

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
| **P1a** | Patika omurgası — **9 rehber dosyası** (`22-Learning-Path/` README, CURRICULUM, NOT-YET, PLACEMENT, PROGRESS-TEMPLATE, STUDY-METHOD, COST-GUARDRAILS, TROUBLESHOOTING, PORTFOLIO) | ✅ **EN twin hazır** (2026-07-23) — 9 `.en.md` üretildi (9 paralel çeviri subagent, dosya başına bir, sıkı ruleset). Başlık paritesi 9/9, link locale-eksiz, positioning temiz, mermaid/tablo yapısı korundu. build-docs.sh `2[0-9]-*` `cp -r` ile hepsini özyineli stage ediyor; iki-locale build hatasız, `/en/…/CURRICULUM/` İngilizce render. |
| **P1b** | Patika omurgası — **30 modül** + **5 STAGE-EXAM** twin'i `block-*/<ID>-*.en.md` (A0…F5) | ✅ **EN twin hazır — tüm bloklar (A0…F5 + A–E STAGE-EXAM)** (2026-07-23). Bu tur 11 twin: E1–E5 + Blok E STAGE-EXAM (6) · F1–F5 (5, **Blok F'de STAGE-EXAM yok**). Önceki turlar: A+B (12) · C+D (12). Toplam 35 dosya (30 modül + 5 STAGE-EXAM). Her dilim: 12/11 paralel çeviri subagent, dosya başına bir, sıkı ruleset. Bu tur başlık paritesi 11/11, link locale-eksiz (0 sızıntı), positioning/pazarlama (TR+EN) temiz, kod-yorumu çevrildi/komut+YAML+SQL verbatim; F-blok ortak `## 🔨 Deliverable exercise` başlığı 5/5 tutarlı; güvenlik ipliği (E4 backup at-rest/erişim, F2 KVKK→GDPR→SOC 2 kontrol zinciri) korundu; `/en/…/E1-sli-slo-error-budget/` + `/en/…/F2-tehdit-uyum/` İngilizce render, qa exit 0. `qa.py` locale-farkındalığı (`LOCALE_RE`) modül twin'lerini bütünlük denetiminden muaf tutuyor. |
| **P2** | 21 klasör README'si | ✅ **EN twin hazır** (2026-07-23) — 21 `.en.md` (`00-Culture` … `20-Soft-Skills`). 11'i (00–10) önceki kesintili turdan **untracked** geldi (structure-preserving; başlık/tablo paritesi + link-leak + positioning doğrulandı → benimsendi); 10'u (11–20) bu tur 10 paralel çeviri subagent (sonnet), dosya başına bir, sıkı ruleset ile üretildi. Başlık/tablo paritesi 21/21, link locale-eksiz (0 sızıntı), positioning/pazarlama (TR+EN) temiz, KVKK 19-Compliance'ta global-okur çerçevesiyle reframe. build-docs.sh `0[0-9]-*/1[0-9]-*` `cp -r` ile özyineli stage (ek satır gerekmedi); `/en/19-Compliance/` + `/en/11-SRE/` İngilizce render, qa exit 0. |
| **P3** | En güçlü 15 deep-dive | 🟡 **slice-1 hazır (5/15)** (2026-07-23) — 5 CLAUDE.md "İyi doküman" örneği twin'lendi: `08-Security/Kubernetes-Hardening.en.md`, `08-Security/Threat-Modeling.en.md`, `11-SRE/SLI-SLO-Error-Budget.en.md`, `02-CI-CD/Pipeline-Patterns.en.md`, `19-Compliance/KVKK-Practical.en.md`. 5 paralel çeviri subagent (dosya başına bir), sıkı ruleset. Başlık/tablo paritesi 5/5, link locale-eksiz (0 sızıntı), positioning/pazarlama (TR+EN) temiz, KVKK global-okur reframe, kod/formül verbatim. build-docs.sh `0[0-9]-*/1[0-9]-*/2[0-9]-*` `cp -r` ile otomatik stage; `/en/…/Kubernetes-Hardening/` + `/en/…/SLI-SLO-Error-Budget/` İngilizce render, qa exit 0. **Kalan 10/15: slice-2 → slice-3.** |
| **P4** | Kalan içerik | ⬜ |

### P3 — 15 deep-dive listesi ve seçim kuralı

**Objektif kural:** patika modüllerinin `## 📖 Önce oku` (+ diğer) tablolarındaki `../../NN-*` link
sayısı sayılır (`grep -rho '\](\.\./\.\./[0-9][0-9]-[^)]*\.md)' block-*/ | sort | uniq -c | sort -rn`).
**Sıra:** (1) count-6 olan 7 doküman → (2) CLAUDE.md "İyi doküman" 5 örneğinin count-6 dışında
kalanı (K8s-Hardening, SLI-SLO, Pipeline-Patterns) → (3) kalan 5 slot count-4'ten DevSecOps
güvenlik+güvenilirlik çekirdeğiyle doldurulur. (count-4 tier'ı 27 dokümanla eşit; tiebreak =
CLAUDE.md örnekleri + güvenlik ipliği.)

| # | Deep-dive | count | Slice |
|---|---|---|---|
| 1 | `08-Security/Kubernetes-Hardening.md` | 4 (exemplar) | **1 ✅** |
| 2 | `08-Security/Threat-Modeling.md` | 6 (exemplar) | **1 ✅** |
| 3 | `11-SRE/SLI-SLO-Error-Budget.md` | 4 (exemplar) | **1 ✅** |
| 4 | `02-CI-CD/Pipeline-Patterns.md` | 4 (exemplar) | **1 ✅** |
| 5 | `19-Compliance/KVKK-Practical.md` | 6 (exemplar) | **1 ✅** |
| 6 | `20-Soft-Skills/Documentation-as-Communication.md` | 6 | 2 |
| 7 | `16-Cheatsheets/linux-troubleshooting.md` | 6 | 2 |
| 8 | `07-Observability/Prometheus-Best-Practices.md` | 6 | 2 |
| 9 | `07-Observability/Alerting-Done-Right.md` | 6 | 2 |
| 10 | `00-Culture/Blameless-Postmortem-Template.md` | 6 | 2 |
| 11 | `08-Security/Secrets-Management.md` | 4 | 3 |
| 12 | `08-Security/DevSecOps-Pipeline.md` | 4 | 3 |
| 13 | `11-SRE/Incident-Response.md` | 4 | 3 |
| 14 | `10-Databases-Production/Backup-Restore-Patterns.md` | 4 | 3 |
| 15 | `11-SRE/Chaos-Engineering.md` | 4 | 3 |

> **Yakın-kaçıran (bilinçli P4):** `20-Soft-Skills/{Vendor,Stakeholder,Saying-No}`, `13-Platform-Engineering/*`,
> `12-FinOps/*`, `10-Databases-Production/Zero-Downtime-Migrations.md`, `07-Observability/SLO-Engineering.md`,
> `06-GitOps/*`, `05-Kubernetes/*`, `04-Containers/*`, `03-IaC/Terraform-Best-Practices.md` — hepsi count-4,
> 15'in dışında kaldı; P4'te gelir.

## Notlar

- KVKK/BDDK/TR dokümanları EN versiyonda da **kalır** — global okur için "AB dışı
  bir veri koruma rejimi mühendislik kontrolüne nasıl çevrilir" örneği.
- EN kapsama oranı = (EN `.en.md` sayfa sayısı) / (toplam TR sayfa sayısı). Aşama B
  eşiği %60. Bu oran her i18n artışında burada güncellenir.

> *Çeviri zemin kuruldu; içerik çevirileri P0'dan başlayarak artımlı gelir.*
