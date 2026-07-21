---
description: "Alerting + on-call disiplini: neyin alarm olduğu, neyin gürültü olduğu ve sürdürülebilir nöbet."
level: E
module: E2
estimated_hours: 12
prerequisites: [E1, B1]
tags: [Learning Path, SRE]
---
# E2 — Alerting + On-Call Disiplini

> *"Her şeye alarm koymak, hiçbir şeye alarm koymamaktır — ikisi de aynı gece uyandırır ya da uyandırmaz."*

**Blok:** E — Sahiplik · **Süre:** ~12 saat · **Ön koşul:** [`E1`](E1-sli-slo-error-budget.md), [`B1`](../block-b-visibility/B1-log-okuma.md)

## 🎯 Bu modülü bitirdiğinde
- SLO'ya bağlı, eyleme çağıran (actionable) bir alarm kurarsın.
- Gürültü alarmı ile gerçek alarmı ayırır, alarm yorgunluğunu azaltırsın.
- Sürdürülebilir bir on-call rotasyonunun neye benzediğini açıklarsın.

## 🧠 Niye bu, niye şimdi
E1'de "yeterince iyi"yi tanımladın; E2 o eşik aşıldığında **kimin, ne zaman**
haberdar olacağını kurar. E3'teki incident response bu alarmlarla tetiklenir.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`07-Observability/Alerting-Done-Right.md`](../../07-Observability/Alerting-Done-Right.md) | actionable alarm | ~30 dk |
| [`00-Culture/On-Call-Playbook.md`](../../00-Culture/On-Call-Playbook.md) | nöbet disiplini | ~25 dk |

## 🔨 Lab
👉 `labs/build/L19-alerting/` — Faz 5'te.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 4): SLO'ya bağlı, tetiklenip çözülen bir alarm — kanıt
- [ ] TODO (Faz 4): bir "gürültü alarmı" örneği ve niçin kaldırıldığı — yazılı
- [ ] TODO (Faz 4): "bu alarm gece 3'te seni uyandırmalı mı" testine göre sınıflandırma

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
SLO'ya bağlı bir alarm kuralı seti + on-call notların.

## ⏭️ Sırada
[`E3 — Incident + Postmortem`](E3-incident-postmortem.md)

---

> *"İyi bir alarm bir soru sormaz, bir eylem söyler."*
