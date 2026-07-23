# GLOSSARY-COVERAGE — Faz 9 Çıktı Kapısı (terim envanteri)

> BUILD-PROMPT §10 Faz 9 çıktı kapısı: *"terim envanteri çıkarıldı ve her teknik
> terim ya bir modülde tanımlı ya `Glossary.md`'de var."*

**Yöntem.** Terimler iki kaynaktan toplandı:
1. **Yeni başlayan simülasyonu** (A1→F5 sırayla okuma) — bir terim, sıfır ön bilgili
   okuyucunun ilk karşılaştığı yerde tanımsızsa bulgu açıldı. Bu bulgular
   `REVIEW-FINDINGS.md`'de kategori `a` (tanımsız terim) olarak izlendi.
2. **Blok-içi ilk-kullanım taraması** — her bloğun ilk geçen akronim/jargon terimleri
   tek tek denetlendi.

**Kapsam kuralı.** Bir terim "kapsanmış" sayılır ancak: (a) ilk geçtiği modülde inline
bir cümleyle glose edilmişse **ve/veya** (b) `Glossary.md`'de satırı varsa. İkisi birden
en güçlüsü; öğretici modüllerde inline + Glossary hedeflendi.

**Durum:** ✅ kapsanmış · ⬜ boşluk (kalmadı).

---

## Faz 9'da tespit edilip kapatılan terimler

Bunlar yeni-başlayan denetçisinin "burada tanımsız" dediği ve bu fazda kapatılan terimler.

| Terim | İlk geçtiği modül | İnline gloss | `Glossary.md` | Durum |
|---|---|---|---|---|
| ICMP | A2 | ✅ (A2) | ✅ | ✅ |
| semver | C2 | ✅ (C2 kabul kriteri) | ✅ | ✅ |
| LocalStack | C3 | ✅ (C3 Lab) | ✅ | ✅ |
| Free tier | C4 | ✅ (C4 kabul kriteri) | ✅ | ✅ |
| NAT | C4 | ✅ (C4 Takıldıysan) | ✅ | ✅ |
| egress | C4 / F1 | ✅ (C4 + F1) | ✅ | ✅ |
| kind | D1 | ✅ (D1 "Niye bu") | ✅ | ✅ |
| k3s | D5 | — (D1 kind tanımından türetilir) | ✅ | ✅ |
| Taint / Toleration | D1 | ✅ (D1 Pending satırı) | ✅ | ✅ |
| burn rate | E1 / E2 | ✅ (E1 "Niye bu") | ✅ | ✅ |
| Alertmanager | E2 | ✅ (E2 kabul kriteri) | ✅ | ✅ |
| ack | E2 | ✅ (E2 Cevaplar) | ✅ | ✅ |
| ADR | F4 | ✅ (F4 açılım) | ✅ | ✅ |
| Right-sizing | F1 | — (F1 kullanır) | ✅ | ✅ |
| Reserved Instance | F1 | — (F1 kullanır) | ✅ | ✅ |
| Cognitive load (bilişsel yük) | F3 | — (Team-Topologies linki) | ✅ | ✅ |

> Bu turda `Glossary.md`'ye eklenen 6 satır: `ack`, `ADR`, `Alertmanager`,
> `Cognitive load`, `Reserved Instance (RI)`, `Right-sizing`. Önceki Faz 9 turlarında
> eklenenler: `ICMP` (Blok A), `semver`/`LocalStack`/`NAT`/`egress`/`Free tier` (Blok C),
> `kind`/`k3s`/`Taint / Toleration` (Blok D). `burn rate` zaten vardı.

---

## Blok-içi ilk-kullanım — zaten kapsanmış çekirdek terimler

Aşağıdakiler denetimde tanımlı bulundu (bulgu açılmadı); envanter bütünlüğü için listeli.

| Blok | Terim | Nerede |
|---|---|---|
| A | PATH, stdio/redirect, subnet, DNS, TLS, TCP/IP | A1–A3 inline (öğretici gövde) |
| A | systemd unit, `journalctl` | A6/B1 inline |
| B | Prometheus, node_exporter, cardinality, scrape | B2 inline + `Glossary.md` |
| C | image / layer / multi-stage, registry | C1 inline + `Glossary.md` (Registry) |
| C | CI, artifact, VPC, IAM | C2/C4 inline + `Glossary.md` |
| D | Pod, Deployment, Service, Ingress | D1 🌉 Köprü inline |
| D | RBAC, NetworkPolicy | D1 🌉 Köprü inline + `Glossary.md` (RBAC) |
| D | request/limit, probe, PDB, HPA | D2 inline |
| D | Admission Controller, cosign/imza | D4 inline + `Glossary.md` |
| D | ArgoCD, reconciliation, drift | D5 inline + `Glossary.md` |
| E | SLI/SLO/error budget | E1 inline (öğretici gövde) |
| E | RTO / RPO | E4 inline + `Glossary.md` (RPO / RTO) |
| E | blast radius, game day, chaos | E5 inline + `Glossary.md` |
| F | STRIDE, KVKK/SOC 2 | F2 inline + `19-Compliance/` link |
| F | Team Topologies, golden path, IDP | F3 inline + `Glossary.md` (Backstage/IDP) |
| F | RFC, postmortem | F4 inline + `Glossary.md` |

---

## Sonuç

**Açık terim boşluğu: 0.** Faz 9 yeni-başlayan simülasyonunda tanımsız bulunan her teknik
terim ya ilk geçtiği modülde inline glose edildi ya `Glossary.md`'ye eklendi (çoğu ikisi
birden). Kategori `a` (tanımsız terim) bulgularının tamamı `REVIEW-FINDINGS.md`'de `✅`.

> Bu envanter statik değildir: yeni modül/terim eklendiğinde aynı iki-kaynak kuralı
> (inline gloss **ve/veya** Glossary) uygulanır.
