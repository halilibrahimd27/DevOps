---
description: "G3 — Blok E kapısı: dal seçimi CKS (K8s güvenlik derinliği, CKA şart) veya AWS SAA (bulut mimari genişliği). Hangi modüller karşılıyor, boşluklar, F2 bağımlılığı."
tags:
  - Learning Path
  - Sertifika
---
# G3 — Blok E Kapısı: CKS *veya* AWS SAA (dal seçimi)

> *"Son kapı bir çatal: aynı sistemlere ya güvenlik derinliğiyle ya bulut genişliğiyle bak. İkisi de geçerli; ama bu bir seçim, koleksiyon değil."*

> ⏳ **Sürüm uyarısı:** Sınav müfredatı ve tool sürümleri değişir. Bu sayfa 2026-07-22
> itibarıyla doğrudur; resmi kaynakla çeliştiğinde **resmi kaynak doğrudur**.

**Kapı:** Blok E sonu · **Seçim:** CKS *veya* AWS SAA · **Ön koşul:** E1–E5 kabul kriterleri (CKS için ayrıca geçerli CKA)

Blok E'yi bitirdin: SLO koydun, alert kurdun, incident'i postmortem'ledin, veritabanını
restore ettin, chaos yaşadın. Bu kapı bir **dal** açar. İkisini birden alma — bu, reponun
eleştirdiği sertifika koleksiyonudur. Birini seç, gerçekten derinleş.

---

## 🎯 Dalı nasıl seçersin

| | CKS | AWS SAA |
|---|---|---|
| Yön | Kubernetes **güvenlik derinliği** (DevSecOps) | **Bulut mimari genişliği** (AWS) |
| Format | Performansa dayalı, canlı cluster, 2 saat | Çoktan seçmeli/çoklu-yanıt, ~130 dk |
| Ön koşul | **Geçerli CKA zorunlu** | Yok (ama bulut temeli gerekir) |
| Kime | K8s'i derinleştirip güvenlik iplığini kalınlaştıracaksan | Bulut mimarisine genişleyeceksen |
| Patika örtüşmesi | Yüksek (güvenlik iplik boyunca içindeydi) | **Düşük** (patika bulut-hafif ilerledi) |

> 🔑 **Dürüst yönlendirme:** Patika D bloğunda güvenliği iplik olarak taşıdı (RBAC,
> NetworkPolicy, secret, supply-chain), o yüzden **CKS bu gövdenin doğal devamıdır.**
> AWS SAA geniş bir AWS servis yüzeyi ister; patika bunu bilerek yerel-önce (LocalStack,
> bütçe alarmı) geçti — yani AWS SAA seçersen **büyük bir kısmını sıfırdan** çalışırsın.
> İkisi de meşru; hangisini seçtiysen boşluk sütununu ciddiye al.

---

## ⚠️ CKS için F2 bağımlılığı — sırayı atlama

CKS'in "Minimize Microservice Vulnerabilities" ve "Supply Chain Security" alanları, bir
**tehdit modeli** gözüyle en iyi oturur: neyi, kimden, niye koruyorsun. Bu bakış Blok F'te
[`F2 — tehdit modelleme + uyum`](../block-f-judgment/F2-tehdit-uyum.md) modülünde açılıyor.

> 🧵 CKS'e **Blok E sonunda hemen değil**, [`F2`](../block-f-judgment/F2-tehdit-uyum.md)'yi
> okuduktan sonra gir. Teknik kontrolleri (Falco, seccomp, NetworkPolicy) D bloğundan
> biliyorsun; F2 sana *hangi kontrolü niye* koyduğunu verir. Sertifikayı geçmek için
> teknik yeter ama iplik bütünlüğü için F2 önce gelir. (AWS SAA dalını seçtiysen bu not seni bağlamaz.)

---

## 1. Bu kapıya hazır mısın?

- [ ] [`E1`](../block-e-ownership/E1-sli-slo-error-budget.md)–[`E5`](../block-e-ownership/E5-chaos.md) kabul kriterlerini geçtin
- [ ] Kırık lab'ları çözdün: [`K08`](../labs/broken/K08-restore-basarisiz/) (restore), [`K09`](../labs/broken/K09-chaos-gameday/) (chaos)
- [ ] Blok E [`STAGE-EXAM`](../block-e-ownership/STAGE-EXAM.md)'ini geçtin
- [ ] **CKS için:** geçerli bir CKA'n var ([`G2`](G2-cka.md))
- [ ] **AWS SAA için:** [`C4`](../block-c-reproducibility/C4-bulut-butce-alarmi.md)'teki bulut temellerini (VPC/IAM/compute) rahat anlatıyorsun

---

## 2. Ne ölçer, ne ölçmez

| | Ölçer | Ölçmez |
|---|---|---|
| **CKS** | Cluster/sistem sertleştirme, runtime güvenlik (Falco), supply-chain, seccomp/AppArmor | Uygulama kodu güvenliği, bulut-spesifik güvenlik |
| **AWS SAA** | AWS servisleriyle güvenli/dayanıklı/performanslı/maliyet-optimal mimari **tasarımı** | Canlı işletim, derin güvenlik, kod |

CKS "cluster'ı sertleştirebiliyorum" der; AWS SAA "AWS servislerini doğru seçip
birleştirebiliyorum" der. İkisi de production sahipliğinin yerine geçmez.

---

## 3. Hangi modüller müfredatı karşılıyor

### CKS (alan ağırlıkları resmi müfredattan; kendin doğrula)

| Alan | ~Ağırlık | Karşılayan modül | Boşluk (kendin çalış) |
|---|---|---|---|
| Supply Chain Security | ~%20 | [`D4`](../block-d-orchestration/D4-supply-chain.md) + [`L16`](../labs/build/L16-supply-chain/) | image imza politikası zorlaması (admission) |
| Minimize Microservice Vuln. | ~%20 | [`D1`](../block-d-orchestration/D1-k8s-temel.md) (NetworkPolicy), [`D3`](../block-d-orchestration/D3-secret-yonetimi.md), [`F2`](../block-f-judgment/F2-tehdit-uyum.md) | securityContext, PSS/PSA, mTLS ayrıntısı |
| Cluster Hardening | ~%15 | [`D1`](../block-d-orchestration/D1-k8s-temel.md) (RBAC), [`08-Security/Kubernetes-Hardening`](../../08-Security/Kubernetes-Hardening.md) | API server bayrakları, admission controller zinciri |
| Monitoring, Logging & Runtime | ~%20 | [`B1`](../block-b-visibility/B1-log-okuma.md), [`B2`](../block-b-visibility/B2-metrik-prometheus.md) | **Falco kural yazımı, audit log yapılandırma** — kendin çalış |
| System Hardening | ~%15 | [`A1`](../block-a-intuition/A1-linux-temeli.md) (Linux temeli) | **seccomp/AppArmor profilleri, gVisor** — kendin çalış |
| Cluster Setup | ~%10 | [`D1`](../block-d-orchestration/D1-k8s-temel.md) | **kube-bench/CIS, TLS/Ingress sertleştirme** — kendin çalış |

> 🕳️ **CKS'in en büyük boşluğu:** *runtime güvenlik araçları* — Falco, seccomp/AppArmor,
> gVisor, kube-bench. Patika iplik olarak güvenliği taşıdı ama bu spesifik araçları ayrı
> öğretmedi. Tehdit çerçevesi için [`F2`](../block-f-judgment/F2-tehdit-uyum.md) ve
> [`08-Security/Threat-Modeling`](../../08-Security/Threat-Modeling.md).

### AWS SAA (SAA-C03; ağırlıkları resmi kılavuzdan doğrula)

| Alan | ~Ağırlık | Karşılayan modül | Boşluk (kendin çalış) |
|---|---|---|---|
| Design Secure Architectures | ~%30 | [`C4`](../block-c-reproducibility/C4-bulut-butce-alarmi.md) (IAM/VPC), [`D3`](../block-d-orchestration/D3-secret-yonetimi.md) | **IAM politika derinliği, KMS, güvenlik grupları** — büyük boşluk |
| Design Resilient Architectures | ~%26 | [`E1`](../block-e-ownership/E1-sli-slo-error-budget.md), [`E4`](../block-e-ownership/E4-veritabani-restore.md), [`C3`](../block-c-reproducibility/C3-terraform.md) | Multi-AZ, ELB, Auto Scaling, Route53 failover |
| Design High-Performing Arch. | ~%24 | — | **Caching, CloudFront, servis seçimi** — neredeyse tamamı boşluk |
| Design Cost-Optimized Arch. | ~%20 | [`C4`](../block-c-reproducibility/C4-bulut-butce-alarmi.md), [`F1`](../block-f-judgment/F1-maliyet-finops.md) | Reserved/Spot, S3 katmanları, sağ boyutlama |

> 🕳️ **AWS SAA dürüst uyarı:** patika bulut-hafif ilerledi. AWS SAA'nın çoğu AWS'e özgü
> **servis bilgisi** ister (S3, EC2, RDS, VPC, ELB, Route53, CloudFront, Lambda…). Patika
> sana *kavramları* (IaC, dayanıklılık, güvenlik, maliyet) verdi; **servis yüzeyini sıfırdan
> çalışacaksın.** Bunu küçümseme.

---

## 4. Resmi müfredat nerede

- **CKS:** [CNCF CKS Curriculum](https://github.com/cncf/curriculum) · [Linux Foundation — CKS](https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/)
- **AWS SAA:** [AWS — Solutions Architect Associate](https://aws.amazon.com/certification/certified-solutions-architect-associate/) → resmi Exam Guide (domain ağırlıkları) tek gerçek kaynak.

Ağırlıklar sürüme göre değişir; **girmeden önce resmi kılavuzla karşılaştır.**

---

## 5. Hazırlık planı

1. Blok E'yi ve K08/K09'u bitir.
2. **CKS:** önce [`F2`](../block-f-judgment/F2-tehdit-uyum.md) (tehdit çerçevesi), sonra
   runtime araç boşlukları (Falco, seccomp/AppArmor, kube-bench, gVisor) — her biri için
   yerel `kind` cluster'da küçük bir deneme.
3. **AWS SAA:** resmi Exam Guide'ı boşluk haritası olarak kullan; AWS'in ücretsiz dijital
   eğitimlerinden servis-servis ilerle. Free-tier'da küçük mimariler kur (bütçe alarmı açık).
4. Pratik sınav çöz; yanlışlarını **kavram düzeyinde** çöz.
5. Sınav-alma disiplini → [`HOW-TO-CERTIFY.md`](HOW-TO-CERTIFY.md).

---

## 6. Pratik ortamı (yerel-önce)

- **CKS:** tamamen yerel — `kind`/`k3s` + Falco + Trivy + kube-bench. Para gerekmez.
- **AWS SAA:** kavram pratiği [`L11`](../labs/build/L11-terraform/) (LocalStack) ve
  [`L12`](../labs/build/L12-bulut-butce-alarmi/) ile bulutsuz başlar. Servis davranışını
  görmek için AWS **free-tier** yeter — ama **her zaman bütçe alarmı açık**, kaynağı
  bırakma. Maliyet disiplini için [`COST-GUARDRAILS.md`](../COST-GUARDRAILS.md).

---

## 7. Sınav günü mekaniği

- **CKS:** 2 saat, performansa dayalı, canlı cluster; `kubernetes.io` + belirli araç
  dokümanları açık (resmi handbook'ta hangileri yazar). Görevler ağırlıklı; bağlam
  değişimini (`kubectl config use-context`) her görevde yap.
- **AWS SAA:** ~130 dk, 65 soru, çoktan seçmeli/çoklu-yanıt. "En **maliyet-optimal**",
  "en az yönetim" gibi niteleyicilere dikkat — iki cevap doğru görünür, biri niteleyiciye uyar.
- Geçme eşikleri resmi sayfada; **doğrula** (tarihsel: AWS SAA 1000 üzerinden ~720).

---

## 8. Hazır olduğunu nereden anlarsın

- [ ] **CKS:** simülatörde süre içinde bitiriyorsun; Falco kuralı yazıp tetikletebiliyorsun; bir Pod'a seccomp/AppArmor profili bakmadan uygulayabiliyorsun
- [ ] **CKS:** [`F2`](../block-f-judgment/F2-tehdit-uyum.md)'yi okudun; bir kontrolü "hangi tehdide karşı" diye gerekçelendirebiliyorsun
- [ ] **AWS SAA:** boşluk sütunundaki her servisi bir cümleyle "ne zaman kullanılır" diye anlatabiliyorsun
- [ ] **AWS SAA:** pratik sınavda eşiği istikrarlı aşıyorsun

---

## 9. Geçemezsen

- Bunlar patikanın en zor kapıları; ilk seferde geçememek olağan. Utanç yok.
- Zayıf alanı al (CKS'te kendi hissin, SAA'da skor raporu domain kırılımı) ve **yalnız onu** yeniden çalış.
- CKS için kayıt genelde bir tekrar içerir; AWS SAA'nın kendi tekrar politikası ve bekleme süresi var — resmi sayfadan bak.
- Bu kapı geçilmese bile Blok E bitti — sertifika blok değil, blok'un dış imzasıdır.

---

## 📋 Checklist — G3'e girmeden

```
[ ] E1–E5 kabul kriterleri geçildi, K08 + K09 çözüldü, STAGE-EXAM geçildi
[ ] Dal seçildi: CKS (güvenlik derinliği) veya AWS SAA (bulut genişliği)
[ ] CKS ise: geçerli CKA var + F2 okundu + runtime araç boşlukları kapatıldı
[ ] AWS SAA ise: resmi Exam Guide boşluk haritası çıkarıldı, servis yüzeyi çalışıldı
[ ] Pratik sınav/simülatör eşiği istikrarlı aşıldı
[ ] (AWS SAA) tüm free-tier kaynakları için bütçe alarmı açık
```

---

## 📚 Referanslar
- [CNCF Curriculum (CKS)](https://github.com/cncf/curriculum) · [Linux Foundation — CKS](https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/)
- [AWS — Solutions Architect Associate](https://aws.amazon.com/certification/certified-solutions-architect-associate/)
- Repo içi: [`08-Security/Kubernetes-Hardening`](../../08-Security/Kubernetes-Hardening.md) · [`08-Security/Threat-Modeling`](../../08-Security/Threat-Modeling.md) · [`19-Compliance/SOC2-Type2-Prep`](../../19-Compliance/SOC2-Type2-Prep.md) · [`F2`](../block-f-judgment/F2-tehdit-uyum.md)
- Repo içi: [`README.md`](README.md) · önceki kapı [`G2-cka.md`](G2-cka.md) · [`HOW-TO-CERTIFY.md`](HOW-TO-CERTIFY.md)

---

> *"Son kapı bir seçim çünkü artık genişlemenin yönünü sen belirliyorsun. Sertifika burada
> bitiyor; sahiplik — seçmediğin bir arıza, senin sistemin, gerçek kullanıcı — işte başlıyor."*
