---
description: "K8s production: request/limit, probe, PDB ve HPA — bir cluster'ı 'çalışıyor'dan 'güvenilir'e taşıyan ayarlar."
level: D
module: D2
estimated_hours: 16
prerequisites: [D1]
tags: [Learning Path, Kubernetes]
---
# D2 — K8s Production: request/limit, probe, PDB, HPA

> *"'Çalışıyor' ile 'production'da güvenilir' arasındaki fark, birkaç YAML alanı ve onların niçinidir."*

**Blok:** D — Orkestrasyon · **Süre:** ~16 saat · **Ön koşul:** [`D1`](D1-k8s-temel.md)

## 🎯 Bu modülü bitirdiğinde
- Doğru request/limit belirler, OOMKilled ve kaynak açlığını önlersin.
- liveness/readiness probe'ları ile bir Pod'un ne zaman trafik alacağını kontrol edersin.
- PDB ve HPA ile kesintiye ve yüke karşı davranışı tanımlarsın.

## 🧠 Niye bu, niye şimdi
D1'de uygulamayı çalıştırdın; ama gerçek yük ve arıza altında ayakta kalması için
production ayarları gerekir. E bloğundaki SLO (E1) ve chaos (E5) bu ayarların
üstüne kurulur.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`05-Kubernetes/Production-Checklist.md`](../../05-Kubernetes/Production-Checklist.md) | production kontrol listesi | ~30 dk |
| [`05-Kubernetes/Resource-Limits-Guide.md`](../../05-Kubernetes/Resource-Limits-Guide.md) | request/limit | ~25 dk |

## 🔨 Lab
👉 [`labs/build/L14-k8s-production/`](../labs/build/L14-k8s-production/)

## 💥 Kırık lab
👉 [`labs/broken/K05-oomkilled-probe/`](../labs/broken/K05-oomkilled-probe/) — Belirti: "Pod sürekli yeniden
başlıyor / trafik almıyor." (Gerçekçi sebep gizli: OOMKilled / yanlış probe / eksik limit.)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] Uygun request/limit + readiness/liveness probe uygulanmış; `kubectl describe`/metrikle doğrulanıyor
- [ ] HPA yük altında replica sayısını artırıyor — `kubectl get hpa` / metrik kanıtı (HPA metrics-server ister; kind kurulumu L14 README'de)
- [ ] Bir **PodDisruptionBudget** uygulandı (`kubectl get pdb`); gönüllü kesintide (drain) en az bir replica ayakta kalıyor — kanıt
- [ ] `bash labs/broken/K05-oomkilled-probe/verify.sh` çözümden sonra sıfır hatayla geçiyor
- [ ] request ile limit farkını ve bir Pod'un niçin OOMKilled olduğunu yazılı anlatabiliyorsun

## 🧪 Kendini test et
1. request ile limit arasındaki fark ne? İkisini eşit vermek ne zaman iyi, ne zaman israf?
2. liveness ve readiness probe'u birbirine karıştırırsan ne olur?
3. Bir Pod `OOMKilled` oluyor. Limiti artırmadan önce hangi soruyu sorarsın?

<details><summary>Cevaplar</summary>

1. request, scheduler'ın Pod'a **garanti ettiği** taban; limit, aşamayacağı tavan. Eşit vermek belleği öngörülebilir yapar (QoS `Guaranteed`) ama esnek olmayan yükte kaynağı boşa ayırabilir. Ayrım [`05-Kubernetes/Resource-Limits-Guide.md`](../../05-Kubernetes/Resource-Limits-Guide.md)'de.
2. Yanlış/agresif **liveness** sağlıklı bir Pod'u sürekli öldürür (restart döngüsü). Eksik **readiness** ise Pod hazır olmadan Service'e sokar → kullanıcı 502/503 alır. Liveness "canlı mı?", readiness "trafik alabilir mi?" sorusudur.
3. "Uygulama gerçekten bu kadar bellek mi istiyor, yoksa sızıntı mı ve limitim gerçeğe göre mi ölçüldü?" Önce ölç; limiti körlemesine artırmak sızıntıyı gizler.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Pod `OOMKilled` | Bellek limiti gerçek kullanımın altında / sızıntı | Kullanımı ölç, limiti gerçeğe göre ayarla; sızıntıyı ele al |
| Pod restart döngüsünde | liveness probe çok agresif / yanlış yol | Eşiği/gecikmeyi gevşet; probe endpoint'ini doğrula |
| Deploy sonrası 502/503 | readiness yok, Pod hazır olmadan trafik aldı | readiness ekle; hazır olana kadar Service'ten çıkar |
| HPA ölçeklemiyor | metrics-server yok / request tanımsız | metrics-server kur; HPA CPU request'e göre çalışır — request ver |

## 💼 Portfolyo çıktısı
Production-ayarlı bir Deployment (probe + limit + HPA + PDB) manifest seti.

## ⏭️ Sırada
[`D3 — Secret Yönetimi`](D3-secret-yonetimi.md)

---

> *"Bir readiness probe eksikliği, kullanıcıya 502 olarak geri döner."*
