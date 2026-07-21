---
description: "Henüz değil listesi: patikaya bilerek erken konmayan konular ve niçin ertelendikleri."
tags: [Learning Path]
---
# ⏳ Henüz Değil

> *"Bir yol haritasının asıl zararı eksik bıraktıkları değil, erken koyduklarıdır."*

Aşağıdaki konular güçlü ve gerçektir — ama **yanlış zamanda öğrenilirse zarar
verir.** Her biri, ancak onu gerektiren somut acıyı yaşadıktan sonra anlamlıdır.
Merakın varsa dokun; ama patikanın omurgası olarak **şimdi değil.**

| Konu | Ne zaman | Niçin şimdi değil |
|---|---|---|
| Service mesh (Istio/Linkerd) | Tek cluster'da somut bir sorun yaşamadan hayır | Çözdüğü sorunu (mTLS, retry, trafik bölme) yaşamadan eklenen mesh, sadece operasyonel yük ve sihirli kutu olur. |
| Multi-cluster / multi-cloud | Tek cluster sağlam çalışmadan hayır | Tek cluster'ı güvenilir işletemeyen biri için ikincisi hata yüzeyini ikiye katlar, dayanıklılık getirmez. |
| eBPF / Cilium derinliği | Blok F, merak seviyesinde | Güçlü ama düşük seviye; temel ağ ve gözlemlenebilirlik oturmadan somutlaşmaz. |
| ApplicationSet / App-of-Apps | Tek ArgoCD app'ini GitOps'la yönetmeden hayır | Tek uygulamayı GitOps döngüsüyle yönetemeden çok-app soyutlaması sadece karmaşıklık ekler. |
| Platform Engineering / IDP | Developer acısını yaşamadan platform tasarlanmaz | Kimin hangi acıyı çektiğini bilmeden kurulan platform, kimsenin istemediği bir ürün olur. |
| Kafka / event-driven mimari | Bu yolun parçası değil, ayrı uzmanlık | DevSecOps patikasının hedefi değil; ihtiyaç doğduğunda ayrı bir öğrenme yolu gerektirir. |
| Sertifika koleksiyonu | 3 kapı, 10 sertifika değil | Sertifika patikayı bitirdiğinin dış doğrulamasıdır, yerine geçmez. Bkz. `certifications/README.md` (Faz 6.5). |

---

## 🧭 Kural

Bir konu bu listedeyse, onu erken eklemek **ilerleme değil, dikkat dağıtmadır.**
Patikayı takip et; sıraları geldiğinde ya bir modülde ya da bir sonraki öğrenme
yolunda karşına çıkacaklar.

---

> *"Ne öğrenmeyeceğini bilmek, ne öğreneceğini bilmek kadar mühendisliktir."*
