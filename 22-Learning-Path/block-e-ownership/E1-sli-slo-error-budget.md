---
description: "SLI / SLO / error budget: bir sistemin 'yeterince iyi'sini sayıyla tanımlamak — sahiplik buradan başlar."
level: E
module: E1
estimated_hours: 12
prerequisites: [B2, D2]
tags: [Learning Path, SRE]
---
# E1 — SLI / SLO / Error Budget

> *"'Sistem sağlıklı mı?' sorusunun mühendislik cevabı bir histen değil, bir sayıdan gelir."*

**Blok:** E — Sahiplik · **Süre:** ~12 saat · **Ön koşul:** [`B2`](../block-b-visibility/B2-metrik-prometheus.md), [`D2`](../block-d-orchestration/D2-k8s-production.md)

## 🎯 Bu modülü bitirdiğinde
- Bir servis için anlamlı bir SLI (gösterge) seçer ve niçin onu seçtiğini savunursun.
- Bir SLO (hedef) belirler ve error budget'ı hesaplarsın.
- Error budget tükendiğinde ne değişmesi gerektiğini (yayın durur mu) açıklarsın.

## 🧠 Niye bu, niye şimdi
B2'de metrikleri, D2'de production ayarlarını kurdun. E1 bu metrikleri bir
**sahiplik sözleşmesine** çevirir: neyin "yeterince iyi" olduğunu sen tanımlarsın.
E2'deki alerting bu SLO'ların üstüne kurulur.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`11-SRE/SLI-SLO-Error-Budget.md`](../../11-SRE/SLI-SLO-Error-Budget.md) | kavram + matematik | ~35 dk |
| [`07-Observability/SLO-Engineering.md`](../../07-Observability/SLO-Engineering.md) | pratiğe dökme | ~25 dk |

## 🔨 Lab
👉 `labs/build/L18-sli-slo/` — Faz 5'te.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 4): bir servis için SLI + SLO tanımlandı ve metrikle ölçülüyor — kanıt
- [ ] TODO (Faz 4): error budget hesabı ve tükenme senaryosu yazılı
- [ ] TODO (Faz 4): "niçin bu SLI, kullanıcı deneyimiyle bağı ne" (yazılı)

## 🧪 Kendini test et
1. TODO (Faz 4)
2. TODO (Faz 4)
3. TODO (Faz 4)

<details><summary>Cevaplar</summary>TODO (Faz 4)</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| TODO | TODO | TODO |

## 💼 Portfolyo çıktısı
Bir servis için yazılı SLI/SLO tanımı + error budget hesabı.

## ⏭️ Sırada
[`E2 — Alerting + On-Call`](E2-alerting-oncall.md)

---

> *"%100 uptime bir hedef değil, bir yanılsamadır; error budget o yanılsamayı bir bütçeye çevirir."*
