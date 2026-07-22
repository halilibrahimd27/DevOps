---
description: "Capstone 3 (Blok E sonu): sistemine SLO, alerting, incident yönetimi, test edilmiş restore ve bir game day ekle."
level: E
tags: [Learning Path, Capstone]
---
# 🏁 Capstone 3 — Blok E Sonu: Sahiplenilen Sistem

> *"D → E geçiş sinyali: kendi kurduğun bir şey senin hatanla bozuldu ve sen geri getirdin mi? Bu capstone o sahipliğin kanıtıdır."*

**Kapı:** Blok E sonu · **Süre:** ~20 saat · **Ön koşul:** Blok E tamamlandı ([`E1`](../block-e-ownership/E1-sli-slo-error-budget.md)–[`E5`](../block-e-ownership/E5-chaos.md)) + [`Blok E sınavı`](../block-e-ownership/STAGE-EXAM.md) geçildi

## 🎯 Bu capstone'da
Capstone 2'deki sistemi **sahiplenirsin**: SLO tanımlı, SLO'ya bağlı alarmlar,
yürütülmüş bir incident + postmortem, test edilmiş bir restore ve bir game day.
Bu, patikanın kendi kendine geçilebilen **son** kapısıdır.

## 📦 Şartname
Capstone 2 reposuna bir `ownership/` (veya `runbook/`) klasörü eklersin:

- **SLO tanımı (`slo.md` + kural):** servis için bir SLI Prometheus'ta ölçülüyor;
  bir SLO (ör. 30 gün) + error budget (dk/ay) yazılı hesaplanmış.
- **Alerting (`alerts.yaml`):** SLO'ya bağlı, **actionable** alarm kuralları; her alarm
  page/ticket/log olarak sınıflandırılmış; gürültü ayıklanmış; eskalasyon tanımlı.
- **Incident + postmortem (`postmortem-<id>.md`):** en az bir incident simülasyonu
  (K07 tabanlı) UTC dakika hassasiyetli timeline'la yürütülmüş; blameless postmortem
  yazılmış; en az bir izlenebilir eylem maddesi (sahip + son tarih).
- **Restore raporu (`restore.md`):** backup temiz bir ortama restore edilmiş; bütünlük
  bir sorguyla doğrulanmış; RTO/RPO ölçülü; backup erişim + at-rest şifreleme kontrolü yazılı.
- **Game day (`gameday.md`):** sınırlı blast radius'lu bir deney — hipotez → deney →
  sonuç; bulunan zayıflık bir eylem maddesine (ve gerekirse yeni bir alarma) çevrilmiş.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan capstone tamamlanmadı:
- [ ] Bir SLI ölçülüyor + SLO + error budget yazılı hesaplandı — sorgu/panel kanıtı
- [ ] SLO'ya bağlı bir alarm **bir kez ateşlendi** ve çözüldü — Alertmanager/panel kanıtı
- [ ] Her alarm page/ticket/log sınıflandırılmış + eskalasyon yazılı
- [ ] Bir incident yürütüldü + blameless postmortem (sayısal etki + kök sebep + eylem maddesi)
- [ ] Backup **temiz ortama** restore edildi; bütünlük sorguyla doğrulandı; RTO/RPO ölçüldü
- [ ] Backup erişim + at-rest şifreleme kontrolü yazıldı (güvenlik ipliği)
- [ ] Sınırlı blast radius'lu bir game day raporu var; en az bir zayıflık eylem maddesine çevrildi

## 📊 Rubrik
Her eksen 0–2. **Geçme ≥ 10/12 ve restore ekseni 2 (test edilmemiş backup geçmez).**

| Eksen | 0 | 1 | 2 |
|---|---|---|---|
| Ölçülebilirlik (SLO) | SLI yok | SLI var, SLO/budget yazılı değil | SLI + SLO + error budget hesaplı |
| Alarm kalitesi | Alarm yok / hepsi page | Var, sınıflandırılmamış | SLO'ya bağlı + sınıflandırılmış + eskalasyon |
| Incident disiplini | Timeline/postmortem yok | Var, blameless değil / eylemsiz | Blameless + eylem maddesi (sahip+tarih) |
| Restore güvenilirliği | Restore test edilmemiş | Restore var, doğrulanmamış | Temiz ortamda + bütünlük + RTO/RPO |
| Backup güvenliği | Kontrol yok | Erişim **veya** at-rest | Erişim **ve** at-rest yazılı |
| Öğrenme (game day) | Yok | Deney var, eylemsiz | Hipotez→deney→sonuç + eylem maddesi |

## 💼 Portfolyo çıktısı
CV'de "sistem sahipliği / SRE" satırının kanıtı. `postmortem-<id>.md` ve `restore.md`,
mülakatta "bir incident'i nasıl yönettin / backup'ı gerçekten test ettin mi?"
sorularının somut cevabıdır. Repo README şablonu; CV satırına eşlemesi
[`PORTFOLIO.md`](../PORTFOLIO.md)'de:

```markdown
# <PROJE_ADI> — Sahiplenilen Servis

**Ne:** Bir servise SLO, actionable alerting, incident yönetimi,
test edilmiş restore ve bir game day ekler. (DevSecOps Handbook · Capstone 3)

## Sahiplik kanıtları
- SLI/SLO + error budget (ölçülü)
- SLO'ya bağlı alarmlar (page/ticket/log sınıflı, eskalasyonlu)
- Blameless postmortem + izlenebilir eylem maddesi
- Temiz ortama test edilmiş restore (RTO/RPO ölçülü, at-rest şifreli)
- Sınırlı blast radius'lu game day raporu

## Hangi kararı niçin verdim
- <örn. bu SLI niçin, budget tükenince ne değişir, restore niçin ayrı ortamda test edilir>
```

> 🧗 **Dürüst tavan:** Bu capstone sahipliğin *mekaniğini* kanıtlar. Gerçek sahiplik
> —seçmediğin bir arıza, sahibi olduğun bir sistem, gerçek kullanıcı— üretim
> ortamında öğrenilir. Bkz. [`README.md`](../README.md) → Dürüst tavan.

## ⏭️ Sırada
[`F1 — Maliyet (FinOps)`](../block-f-judgment/F1-maliyet-finops.md) · Ayrıca
[`README.md`](../README.md) → Dürüst tavan: buradan sonrası üretim ortamıdır.

---

> *"Sahiplik, bir sistemi kurmak değil; o bozulduğunda çağrılan ve geri getiren kişi olmaktır."*
