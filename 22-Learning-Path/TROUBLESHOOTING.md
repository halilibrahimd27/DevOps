---
description: "Yaygın hata → sebep → çözüm indeksi: patika boyunca en sık takılınan noktalar tek yerde."
tags: [Learning Path, Troubleshooting]
---
# 🆘 Sorun Giderme — Yaygın Hata → Sebep → Çözüm

> *"Aynı hataya ikinci kez takılmak öğrenme değil, kayıptır. Bu sayfa o kaybı önler."*

Her modülün kendi `🆘 Takıldıysan` tablosu vardır; bu sayfa **bloklar arası ortak**
takılma noktalarını tek yerde toplar. Belirtiyi bul, sebebi anla, çözümü uygula.

> 🚧 **İskelet (Faz 1).** Tablolar Faz 9'un "yeni başlayan simülasyonu" denetiminde
> gerçek takılma noktalarıyla (40+ madde) doldurulacak. Aşağıdaki başlıklar kapsamı gösterir.

---

## 🐧 Blok A/B — Linux, ağ, log, metrik
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| TODO (Faz 9) | TODO | TODO |

## 📦 Blok C — Container, CI, Terraform, bulut
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `ImagePullBackOff` / tag bulunamıyor | TODO (Faz 9) | TODO |
| Terraform state lock | TODO (Faz 9) | TODO |

## ☸️ Blok D — Kubernetes, güvenlik, GitOps
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Pod `Pending` | TODO (Faz 9) | TODO |
| RBAC `forbidden` | TODO (Faz 9) | TODO |
| `OOMKilled` | TODO (Faz 9) | TODO |
| ArgoCD `OutOfSync` | TODO (Faz 9) | TODO |

## 🔭 Blok E — SLO, alerting, incident, restore
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Restore eksik/bozuk veri | TODO (Faz 9) | TODO |

---

## 📋 Takıldığında sıra
```
[ ] Modülün kendi 🆘 Takıldıysan tablosuna baktım
[ ] Belirtiyi bu sayfada aradım
[ ] Kırık lab'daysam hints/ klasörünü sırayla açtım (hint-1 → hint-2 → hint-3)
[ ] Hâlâ takılıysam: log + metrik ile hipotezimi kanıtlamayı denedim
```

---

> *"İyi bir sorun giderme sayfası cevap vermez, doğru soruyu sorduracak yeri gösterir."*
