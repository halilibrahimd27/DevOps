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
👉 [`labs/build/L19-alerting/`](../labs/build/L19-alerting/)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] SLO'ya bağlı, tetiklenip çözülen bir alarm kuralı yazıldı ve bir kez ateşlendi — Alertmanager/panel çıktısıyla kanıt
- [ ] En az bir "gürültü alarmı" örneği ve niçin sessize alındığı/kaldırıldığı yazıldı
- [ ] Her alarm "gece 3'te uyandırmalı mı?" testine göre sınıflandırıldı (page / ticket / log) — yazılı tablo
- [ ] Bir alarm çözülmezse kime, ne zaman yükseleceği (eskalasyon) yazılı tanımlandı

## 🧪 Kendini test et
1. "CPU %80" ve "hata oranı error budget'ı 1 saatte yakacak hızda" — hangisi page olmalı, niçin?
2. Alarm yorgunluğu neyi bozar ve nasıl ölçersin?
3. Bir alarm ateşliyor ama runbook'u yok. İlk düzeltme alarmı susturmak mı?

<details><summary>Cevaplar</summary>

1. İkincisi. CPU %80 bir belirti olabilir ama tek başına eylem gerektirmez (cause-based, sık gürültü); "bütçe şu hızda yanıyor" kullanıcı etkisine bağlıdır ve eyleme çağırır (symptom-based). Ayrım [`07-Observability/Alerting-Done-Right.md`](../../07-Observability/Alerting-Done-Right.md)'de.
2. Gerçek alarmın gürültü içinde kaçırılmasına yol açar — görevli artık bakmaz. Ölçüsü: alarm başına eyleme dönüşme oranı; "ack'lenip kapatılan" çok, "eyleme dönen" azsa alarm gürültüdür.
3. Hayır. Susturmak semptomu gizler. Önce eyleme çağırıp çağırmadığına bak: çağırmıyorsa kuralı düzelt/kaldır, çağırıyorsa runbook yaz. Susturma yalnızca bilinçli, süreli ve denetim kaydı bırakan bir işlemdir. Nöbet disiplini [`00-Culture/On-Call-Playbook.md`](../../00-Culture/On-Call-Playbook.md)'de.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Görevli her gece uyanıyor | Çok fazla page-seviyesi alarm | Yalnızca kullanıcı etkili/actionable olanı page yap, gerisini ticket'a düşür |
| Alarm ateşliyor, kimse ne yapacağını bilmiyor | Runbook/eylem yok | Her page alarmına tek bir "ilk adım" runbook'u bağla |
| Gerçek arıza kaçtı | Gürültü içinde boğuldu | Alarm audit yap; eylemsiz kuralları kaldır, eşiği SLO'ya bağla |
| Alarm çözülmeden unutuldu | Eskalasyon zinciri yok | Ack + süreli eskalasyon tanımla; sessize almayı denetim kaydına bağla |

## 💼 Portfolyo çıktısı
SLO'ya bağlı bir alarm kuralı seti + on-call notların.

## ⏭️ Sırada
[`E3 — Incident + Postmortem`](E3-incident-postmortem.md)

---

> *"İyi bir alarm bir soru sormaz, bir eylem söyler."*
