---
description: "Kopyalayıp kendi ilerlemeni işaretleyeceğin şablon: her modül, lab ve blok geçiş sinyali için kutu."
tags: [Learning Path]
---
# ✅ İlerleme Şablonu

> *"İşaretlenen kutu bir beyan değil, bir kanıttır. Kabul kriterini geçmeden kutuyu doldurma."*

Bu dosyayı **kendine kopyala** (örn. `PROGRESS.md`) ve ilerledikçe işaretle. Bir
modülü ancak tüm kabul kriterlerini komut/çıktı ile geçtikten sonra `[x]` yap.
Blok geçiş sinyalini geçemiyorsan, o bloktan çıkmadın.

**Başladığım tarih:** `____` · **Rampam:** `A1 / A6 / B1` ([`PLACEMENT.md`](PLACEMENT.md))

---

## Blok A — Sezgi
```
[ ] A1  Linux temeli
[ ] A2  Ağ I — TCP/IP, port, routing
[ ] A3  Ağ II — DNS → HTTP → TLS
[ ] A4  Git temeli
[ ] A5  Bash
[ ] A6  Bir uygulamayı elle ayağa kaldır (+ kırık lab)
```
**Geçiş sinyali (A → B):** Bir servisin neden ayağa kalkmadığını, dokümana
bakmadan üç komutla daraltabiliyorum. `[ ]`

## Blok B — Görebilmek
```
[ ] B1  Log okuma
[ ] B2  Metrik — Prometheus temeli
[ ] B3  İlk kırık lab
```
**Geçiş sinyali (B → C):** Bir arızayı log ve metrikle **kanıtladım**, tahmin
etmedim. `[ ]`
> 🔒 Bu kutu dolmadan Blok C'ye geçme — patikanın en katı kuralı.

## Blok C — Tekrarlanabilirlik
```
[ ] C0  Ops için Python
[ ] C1  Container (+ kırık lab)
[ ] C2  CI
[ ] C3  Terraform (+ kırık lab)
[ ] C4  Bulut temelleri + bütçe alarmı
[ ] Capstone 1 (Blok C sonu)
```
**Geçiş sinyali (C → D):** Sistemimi sıfırdan, elle hiçbir şeye dokunmadan yeniden
kurabiliyorum. `[ ]`

## Blok D — Orkestrasyon (güvenlik iplik olarak içinde)
```
[ ] D1  K8s temel — RBAC + NetworkPolicy ilk günden (+ kırık lab)
[ ] D2  K8s production (+ kırık lab)
[ ] D3  Secret yönetimi
[ ] D4  Supply chain — C2 pipeline'ının devamı
[ ] D5  GitOps / ArgoCD (+ kırık lab)
[ ] Capstone 2 (Blok D sonu)
```
**Geçiş sinyali (D → E):** Kendi kurduğum bir şey benim hatamla bozuldu ve ben
geri getirdim. `[ ]`

## Blok E — Sahiplik (L1 kapısı)
```
[ ] E1  SLI / SLO / error budget
[ ] E2  Alerting + on-call
[ ] E3  Incident + blameless postmortem (+ kırık lab)
[ ] E4  Veritabanı production — restore (+ kırık lab)
[ ] E5  İleri kırık lab / chaos
[ ] Capstone 3 (Blok E sonu)
```
**Geçiş sinyali (E → F):** Bir şeye "hayır" dedim ve gerekçemi yazılı savundum. `[ ]`

## Blok F — Karar (L1 → L2)
```
[ ] F1  Maliyet ve trade-off (FinOps)
[ ] F2  Tehdit modelleme + uyum
[ ] F3  Platform, IDP, Team Topologies
[ ] F4  Yazma — ADR, RFC, postmortem
[ ] F5  Stakeholder, "hayır" demek, vendor
```

---

## 🧗 Dürüst tavan hatırlatması

E ve F kapıları kendi kendine geçilemez: seçmediğin bir arıza, sahibi olduğun bir
sistem ve gerçek kullanıcı gerekir. Buraya geldiysen sıradaki adım daha çok okumak
değil — üretim ortamına girmek. Bkz. [`README.md`](README.md) → Dürüst tavan.

---

> *"İlerleme takvimle değil, geçtiğin kapılarla ölçülür."*
