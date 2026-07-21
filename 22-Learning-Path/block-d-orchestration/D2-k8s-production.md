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
👉 `labs/build/L14-k8s-production/` — Faz 5'te.

## 💥 Kırık lab
👉 `labs/broken/K05-oomkilled-probe/` — Faz 5'te. Belirti: "Pod sürekli yeniden
başlıyor / trafik almıyor." (Gerçekçi sebep gizli: OOMKilled / yanlış probe / eksik limit.)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] TODO (Faz 3): uygun request/limit + readiness/liveness probe uygulanmış — doğrulama
- [ ] TODO (Faz 3): HPA yük altında ölçekleniyor — kanıt (metrik)
- [ ] TODO (Faz 3): K05 kırık lab'ı çözüldü, `verify.sh` geçiyor

## 🧪 Kendini test et
1. TODO (Faz 3)
2. TODO (Faz 3)
3. TODO (Faz 3)

<details><summary>Cevaplar</summary>TODO (Faz 3)</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| TODO | TODO | TODO |

## 💼 Portfolyo çıktısı
Production-ayarlı bir Deployment (probe + limit + HPA + PDB) manifest seti.

## ⏭️ Sırada
[`D3 — Secret Yönetimi`](D3-secret-yonetimi.md)

---

> *"Bir readiness probe eksikliği, kullanıcıya 502 olarak geri döner."*
