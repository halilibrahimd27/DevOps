---
description: "Supply chain: image tarama + imzalama — C2 pipeline'ının devamı olarak, ayrı bir güvenlik dersi değil."
level: D
module: D4
estimated_hours: 14
prerequisites: [C2, D1]
tags: [Learning Path, Security, Supply-Chain]
---
# D4 — Supply Chain: Image Tarama + İmzalama

> *"Bu ayrı bir güvenlik dersi değil; C2'de kurduğun pipeline'ın bir sonraki adımıdır."*

**Blok:** D — Orkestrasyon · **Süre:** ~14 saat · **Ön koşul:** [`C2`](../block-c-reproducibility/C2-ci.md), [`D1`](D1-k8s-temel.md)

## 🎯 Bu modülü bitirdiğinde
- C2 pipeline'ına image açık taraması (vuln scan) ekler, kırılma eşiğini belirlersin.
- Image'ı imzalar (`cosign`) ve imzayı doğrularsın; **imzasız/taranmamış image'ı cluster'ın niçin ve nerede (admission aşamasında) reddetmesi gerektiğini** açıklarsın.
- Bir SBOM'un ne işe yaradığını ve tedarik zinciri riskini nasıl azalttığını açıklarsın.

## 🧠 Niye bu, niye şimdi
C2'de image üretip yayımladın; ama neyi yayımladığını doğrulamadın. D4 o
pipeline'a güvenlik iplik olarak eklenir — tarama ve imzalama build adımının
parçası olur, sonradan yapılan ayrı bir iş değil.

> 🚪 **İmza pipeline'da üretilir, cluster'da zorlanır.** Bu modülün lab'ı (L16) imzayı
> **üretir ve doğrular** — `cosign sign`/`verify`. "Cluster yalnızca imzalı image
> kabul etsin" kuralını fiilen **zorlayan** yer ise farklı bir katman: bir *admission
> controller* (Kyverno / Sigstore policy) her image'ı API'ye kabul edilmeden önce
> denetler. Bu modülde admission'ı **kavram olarak** öğrenirsin (nerede devreye girer,
> niçin gerekir); politikayı elle kurmak policy-as-code konusudur — "Önce oku"daki
> Kyverno dokümanı başlangıç noktan.

## 📖 Önce oku
| Kaynak | Ne için | Süre |
|---|---|---|
| [`08-Security/Container-Image-Scanning.md`](../../08-Security/Container-Image-Scanning.md) | tarama (Trivy) | ~30 dk |
| [`04-Containers/Image-Signing-Cosign.md`](../../04-Containers/Image-Signing-Cosign.md) | imzalama (cosign) | ~25 dk |
| [`08-Security/DevSecOps-Pipeline.md`](../../08-Security/DevSecOps-Pipeline.md) | pipeline'a yerleştirme | ~25 dk |
| [`08-Security/Policy-as-Code-OPA-Kyverno.md`](../../08-Security/Policy-as-Code-OPA-Kyverno.md) | admission ile imza zorlama — nerede devreye girer | ~20 dk |

## 🔨 Lab
👉 [`labs/build/L16-supply-chain/`](../labs/build/L16-supply-chain/README.md) — C2 pipeline'ının üstüne.

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] C2 pipeline'ına image taraması eklendi; tanımlı eşik (ör. HIGH/CRITICAL) aşılınca pipeline **kırılıyor** — kanıt
- [ ] image imzalanıyor ve `cosign verify` ile doğrulanıyor — çıktı
- [ ] "imzasız / taranmamış image'ı cluster niçin reddetmeli" — yazılı gerekçe
- [ ] Bir SBOM'un ne olduğunu ve hangi soruyu (hangi bileşen, hangi sürüm) yanıtladığını anlatabiliyorsun

## 🧪 Kendini test et
1. Image taramasını build'i **kırmayan** bir rapor adımı olarak koymak niçin çoğu zaman işe yaramaz?
2. Bir image imzalamak neyi kanıtlar, neyi kanıtlamaz?
3. Kritik bir açık bulundu ama henüz düzeltmesi yok. Pipeline'ı kırmak mı, istisna açmak mı? Kararı nasıl verirsin?

<details><summary>Cevaplar</summary>

1. Kırmayan bir tarama sadece bir uyarı üretir; kimse okumaz ve açık image'la birlikte production'a gider. Kontrol ancak **kırıyorsa** kontroldür. Pipeline'a yerleştirme [`08-Security/DevSecOps-Pipeline.md`](../../08-Security/DevSecOps-Pipeline.md)'de.
2. İmza, image'ın **kim tarafından üretildiğini ve o günden beri değişmediğini** kanıtlar (bütünlük + köken). İçindeki açıkların olmadığını **kanıtlamaz** — imzalı bir image de savunmasız olabilir. Bu yüzden tarama + imzalama birlikte gerekir.
3. İkili değil: **düzeltmesi olan** HIGH/CRITICAL'da kır; düzeltmesi yoksa süreli, gerekçeli, sahibi belli bir istisna aç ve düzeltme çıkınca kapat. Kör "hepsini kır" ekibi kontrolü baypas etmeye iter.
</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Tarama hep yeşil ama açık var | Eşik gevşek / açık DB'si güncel değil | Eşiği HIGH/CRITICAL kıracak şekilde ayarla; tarayıcı DB'sini güncelle |
| Pipeline her açıkta kırılıyor, ekip bıktı | Gürültü yönetimi yok | Sadece düzeltmesi olan HIGH+ kır; istisnaları süreli ve gerekçeli tut |
| `cosign verify` başarısız | İmzalayan kimlik / anahtar uyuşmuyor | İmzalayan kimliği ve doğrulama anahtarını eşleştir |
| Cluster imzasız image'ı kabul ediyor | Admission policy yok | Kyverno/Gatekeeper ile imza doğrulamayı zorunlu kıl |

## 💼 Portfolyo çıktısı
Tarama + imzalama adımları olan bir CI pipeline'ı — DevSecOps'un somut kanıtı.

## ⏭️ Sırada
[`D5 — GitOps (ArgoCD)`](D5-gitops-argocd.md)

---

> *"İmzasız bir image, kimin yazdığı bilinmeyen bir sözleşmeyi imzalamaktır."*
