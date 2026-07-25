---
description: "G1 — Blok C kapısı: KCNA veya Terraform Associate. İlk dış doğrulama; ucuz, çoktan seçmeli. Hangi modüller karşılıyor, ne ölçer, hazır olduğunu nereden anlarsın."
tags:
  - Learning Path
  - Sertifika
---
# G1 — Blok C Kapısı: KCNA *veya* Terraform Associate

> *"İlk kapı ucuzdur ve çoktan seçmelidir. Amacı seni doğrulamak değil, dışarıya ilk kez kanıt üretmek."*

> ⏳ **Sürüm uyarısı:** Sınav müfredatı ve tool sürümleri değişir. Bu sayfa 2026-07-22
> itibarıyla doğrudur; resmi kaynakla çeliştiğinde **resmi kaynak doğrudur**.

**Kapı:** Blok C sonu · **Seçim:** iki sınavdan biri · **Ön koşul:** C1–C4 kabul kriterleri

Blok C'yi bitirdin: container'ladın, CI kurdun, Terraform'la altyapıyı kod yaptın, bütçe
alarmı koydun. Bu kapı bunun **ilk dış doğrulamasıdır**. İkisi de çoktan seçmeli, ikisi de
görece ucuz. Hangisini seçeceğin, hangi yetkinliği kanıtlamak istediğine bağlı.

---

## 🎯 İki seçenek, tek net tavsiye

| | KCNA | Terraform Associate |
|---|---|---|
| Ölçtüğü | Cloud-native + Kubernetes **kavramları** (geniş, sığ) | IaC + Terraform iş akışı (dar, uygulanabilir) |
| Format | Çoktan seçmeli, ~90 dk, hands-on yok | Çoktan seçmeli, ~1 saat, hands-on yok |
| Blok C'ye oturması | **Kısmen** — en büyük alanı (K8s temeli) Blok D'de gelir | **Tam** — C3 doğrudan Terraform |

> 🔑 **Net tavsiye:** Blok C sonunda **Terraform Associate** daha temiz oturur — C3 ve
> `L11` tam da bunu öğretti. KCNA'yı istiyorsan bekle: en ağır alanı (aşağıda) D1'de
> açılıyor. KCNA'yı ya D1'e göz attıktan sonra al, ya da "kavram düzeyinde genişlik
> testi" olarak kabul edip eksik alanı sınav öncesi kendin çalış. İkisi de geçerli;
> ama neyi kanıtladığın konusunda kendini kandırma.

---

## 1. Bu kapıya hazır mısın?

Şu kabul kriterlerini **komut çıktısıyla** (kendi beyanınla değil) geçmiş olmalısın:

- [ ] [`C1`](../block-c-reproducibility/C1-container.md) — multi-stage, non-root image build edip çalıştırdın; `docker compose` ile app+DB ayağa kaldırdın
- [ ] [`C2`](../block-c-reproducibility/C2-ci.md) — test → build → artifact → registry pipeline'ın yeşil
- [ ] [`C3`](../block-c-reproducibility/C3-terraform.md) — `terraform apply`/`destroy`/tekrar-`apply` idempotent; state'in ne olduğunu anlatabiliyorsun *(Terraform Associate için zorunlu)*
- [ ] [`C4`](../block-c-reproducibility/C4-bulut-butce-alarmi.md) — bütçe alarmını `plan`/`validate` ile yerelde doğruladın
- [ ] Blok C [`STAGE-EXAM`](../block-c-reproducibility/STAGE-EXAM.md)'ini geçtin

KCNA seçtiysen ek olarak: [`D1`](../block-d-orchestration/D1-k8s-temel.md)'in "Pod, Deployment,
Service, Ingress" kısmına en azından göz atmış olman gerekir — yoksa sınavın ~%46'sı yabancı gelir.

---

## 2. Ne ölçer, ne ölçmez

| | Ölçer | Ölçmez |
|---|---|---|
| **KCNA** | K8s nesneleri (kavramsal), cloud-native mimari sözlüğü, temel observability/delivery | Canlı cluster'da iş yapma, hata ayıklama, YAML yazma |
| **Terraform Associate** | IaC kavramları, `plan/apply` akışı, state, değişken/çıktı, modül kullanımı | Karmaşık modül tasarımı, çoklu-ortam mimarisi, üretim state stratejisi derinliği |

İkisi de **laboratuvar bilgisini** ölçer, production'ı değil. Geçmek "bu kavramları
tanıyorum" der; "bunu canlıda işlettim" demez.

---

## 3. Hangi modüller müfredatı karşılıyor

### KCNA (alan ağırlıkları resmi müfredattan; kendin doğrula)

| Alan | ~Ağırlık | Karşılayan modül | Boşluk (kendin çalış) |
|---|---|---|---|
| Kubernetes Fundamentals | ~%46 | [`D1`](../block-d-orchestration/D1-k8s-temel.md) | **Blok D'de gelir — G1'de erken.** kubectl temel nesneleri |
| Container Orchestration | ~%22 | [`C1`](../block-c-reproducibility/C1-container.md), [`D2`](../block-d-orchestration/D2-k8s-production.md) | Scheduling/autoscaling ayrıntısı D2'de |
| Cloud Native Architecture | ~%16 | [`C1`](../block-c-reproducibility/C1-container.md), [`C2`](../block-c-reproducibility/C2-ci.md) | Serverless, açık standartlar/OCI, CNCF persona/landscape |
| Cloud Native Observability | ~%8 | [`B1`](../block-b-visibility/B1-log-okuma.md), [`B2`](../block-b-visibility/B2-metrik-prometheus.md) | OpenTelemetry sözlüğü |
| Cloud Native App Delivery | ~%8 | [`C2`](../block-c-reproducibility/C2-ci.md), [`D5`](../block-d-orchestration/D5-gitops-argocd.md) | GitOps terminoloji derinliği |

### Terraform Associate

| Amaç | Karşılayan modül | Boşluk (kendin çalış) |
|---|---|---|
| IaC kavramları + Terraform'un amacı | [`C3`](../block-c-reproducibility/C3-terraform.md) | Diğer IaC araçlarıyla karşılaştırma jargonu |
| Temel akış: `init/plan/apply` | [`C3`](../block-c-reproducibility/C3-terraform.md) + [`L11`](../labs/build/L11-terraform/README.md) | — |
| State: backend, kilit, remote | [`C3`](../block-c-reproducibility/C3-terraform.md) + [`K03`](../labs/broken/K03-terraform-state/README.md) | Remote backend çeşitleri (S3/HCP) ayrıntısı |
| Değişken, çıktı, fonksiyon | [`C3`](../block-c-reproducibility/C3-terraform.md) | `for_each`/`dynamic` blok, karmaşık ifadeler |
| Modül kullanımı | [`C3`](../block-c-reproducibility/C3-terraform.md) | Registry modülleri, sürümleme |
| HCP Terraform yetenekleri | — | **Boşluk — tamamen kendin çalış** (resmi doküman) |

> `K03` (bayat state kilidi) tam da sınavın "state" alanının canlı halidir — o kırık lab'ı
> çözdüysen bu alanı ezberden değil, deneyimle biliyorsun.

---

## 4. Resmi müfredat nerede

Sınav içeriğinin **tek gerçek kaynağı** resmi müfredattır — bu sayfa değil, hiçbir üçüncü
parti kurs değil:

- **KCNA:** [CNCF KCNA Curriculum](https://github.com/cncf/curriculum) → resmi domain listesi ve ağırlıklar
- **Terraform Associate:** [HashiCorp — Terraform Associate exam objectives](https://developer.hashicorp.com/terraform/tutorials/certification-003)

Yukarıdaki ağırlıklar sınav sürümüne göre değişir. **Sınava girmeden önce resmi listeyle karşılaştır.**

---

## 5. Hazırlık planı

1. Bloğu bitir. Kapı, blok bitişinin doğrulamasıdır — blok yerine geçmez.
2. Resmi müfredatı aç, yukarıdaki **boşluk** sütununu kendi eksiklerinle güncelle.
3. Boşlukları kapat: her boşluk maddesi için resmi doküman + küçük bir yerel deneme.
4. 1–2 resmi/örnek pratik sınav çöz; yanlışlarını **kavram düzeyinde** çöz, soruyu ezberleme.
5. Detay: sınav-alma becerisinin kendisi → [`HOW-TO-CERTIFY.md`](HOW-TO-CERTIFY.md).

---

## 6. Pratik ortamı (yerel-önce)

Para harcamadan:

- **Terraform Associate:** [`L11`](../labs/build/L11-terraform/README.md) zaten **LocalStack** üstünde
  çalışıyor — gerçek bulut hesabı gerekmez. `init/plan/apply/destroy` döngüsünü burada tekrarla.
- **KCNA:** `kind` ile yerel bir cluster kur; `kubectl get/describe` ile nesneleri gez.
  Sınav hands-on değil ama nesneleri gerçekten görmek kavramı ezberden ayırır.

---

## 7. Sınav günü mekaniği

- Her iki sınav da **online proctored** (uzaktan gözetimli), çoktan seçmeli.
- Kimlik + temiz masa + tek ekran kuralları vardır; gözetmen ortamı kontrol eder.
- Süre bol; asıl risk zaman değil, dikkatsiz okuma. "Hangisi **doğru değildir**" kalıbına dikkat.
- İşaretle-geç: emin olmadığını işaretle, sona bırak.

---

## 8. Hazır olduğunu nereden anlarsın

Objektif sinyal, "hazır hissediyorum" değil:

- [ ] Resmi/örnek pratik sınavında **istikrarlı** geçme eşiğinin üstündesin (tek seferlik şans değil)
- [ ] Boşluk sütunundaki her maddeyi bir cümleyle **kendi kelimelerinle** anlatabiliyorsun
- [ ] (Terraform) `plan` çıktısındaki `+/-/~` işaretlerini bakmadan yorumlayabiliyorsun
- [ ] (KCNA) Pod ≠ Deployment ≠ Service ayrımını örnekle açıklayabiliyorsun

---

## 9. Geçemezsen

Utanılacak bir şey yok — sınav bir ölçüm, kimlik değil.

- Skor raporundaki **zayıf alanı** al; bu senin gerçek boşluğun.
- O alanın modülüne geri dön, kabul kriterini tekrar geç, boşluğu kapat.
- Çoğu sınavın bir bekleme süresi ve (bazılarında) ücretsiz/indirimli tekrar hakkı vardır — resmi sayfadan kontrol et.
- İkinci girişte tüm sınavı değil, **yalnız zayıf alanı** yeniden çalış.

---

## 📋 Checklist — G1'e girmeden

```
[ ] C1–C4 kabul kriterleri komut çıktısıyla geçildi
[ ] Blok C STAGE-EXAM geçildi
[ ] Seçim yapıldı: Terraform Associate (temiz oturur) veya KCNA (D1'e göz atıldıysa)
[ ] Resmi müfredatla boşluk sütunu güncellendi
[ ] Pratik sınavda eşik istikrarlı aşıldı
[ ] Sınav ücreti + indirim takvimi resmi sayfadan bakıldı
```

---

## 📚 Referanslar
- [CNCF Curriculum (KCNA)](https://github.com/cncf/curriculum)
- [HashiCorp — Terraform Associate (003)](https://developer.hashicorp.com/terraform/tutorials/certification-003)
- [Linux Foundation Training](https://training.linuxfoundation.org/certification-catalog/)
- Repo içi: [`README.md`](README.md) · [`HOW-TO-CERTIFY.md`](HOW-TO-CERTIFY.md) · sonraki kapı [`G2-cka.md`](G2-cka.md)

---

> *"Bu kapı çoktan seçmeli çünkü henüz canlı bir sistemin sahibi değilsin. Bir sonraki
> kapı (CKA) seni bir cluster'ın karşısına oturtacak — orada tıklamak değil, iş yapmak var."*
