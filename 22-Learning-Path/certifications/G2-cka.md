---
description: "G2 — Blok D kapısı: CKA. Performansa dayalı, canlı cluster'da 2 saat iş. Hangi modüller karşılıyor, storage/etcd boşlukları, sınav günü mekaniği."
tags:
  - Learning Path
  - Sertifika
---
# G2 — Blok D Kapısı: CKA

> *"Bu sınav çoktan seçmeli değil. Canlı bir cluster açılır ve 'şunu yap' der. Tıklamak yok, iş var."*

> ⏳ **Sürüm uyarısı:** Sınav müfredatı ve tool sürümleri değişir. Bu sayfa 2026-07-22
> itibarıyla doğrudur; resmi kaynakla çeliştiğinde **resmi kaynak doğrudur**.

**Kapı:** Blok D sonu · **Sertifika:** Certified Kubernetes Administrator · **Ön koşul:** D1–D5 kabul kriterleri

CKA, bu patikanın ilk **performans** sınavıdır. İki saat boyunca gerçek cluster'larda
görev çözersin — YAML yazarsın, bozuk bir node'u ayağa kaldırırsın, RBAC kurarsın. Blok D
tam olarak bunu inşa etti; bu kapı onu dışarıya kanıtlar.

---

## 1. Bu kapıya hazır mısın?

Şu kriterleri **canlı bir cluster'da** (kind yeter) geçmiş olmalısın:

- [ ] [`D1`](../block-d-orchestration/D1-k8s-temel.md) — Deployment+Service+Ingress kurdun; **en-az-yetki RBAC + default-deny NetworkPolicy** ilk günden içindeydi
- [ ] [`D2`](../block-d-orchestration/D2-k8s-production.md) — request/limit, readiness/liveness probe, PDB, HPA yapılandırdın
- [ ] [`D3`](../block-d-orchestration/D3-secret-yonetimi.md) — Secret oluşturup `secretKeyRef` ile bağladın; base64 ≠ şifreleme olduğunu kanıtladın
- [ ] [`D4`](../block-d-orchestration/D4-supply-chain.md) — image tarama kapısı + imzalama CI'ın parçası
- [ ] [`D5`](../block-d-orchestration/D5-gitops-argocd.md) — tek uygulamayı ArgoCD ile GitOps'ladın
- [ ] Kırık lab'ları çözdün: [`K04`](../labs/broken/K04-imagepullbackoff-rbac/README.md), [`K05`](../labs/broken/K05-oomkilled-probe/README.md), [`K06`](../labs/broken/K06-argocd-out-of-sync/README.md)
- [ ] Blok D [`STAGE-EXAM`](../block-d-orchestration/STAGE-EXAM.md)'ini geçtin

Bir Pod'un neden `Pending`/`CrashLoopBackOff`/`ImagePullBackOff` olduğunu **dokümana
bakmadan** üç komutla daraltamıyorsan, henüz hazır değilsin. CKA'nın en büyük alanı budur.

---

## 2. Ne ölçer, ne ölçmez

| Ölçer | Ölçmez |
|---|---|
| Canlı cluster'da `kubectl`/YAML ile görev çözme | Uygulama tasarımı, kod yazma |
| Cluster kurulum/yükseltme (kubeadm), etcd yedek/geri-yükleme | Bulut-spesifik managed K8s (EKS/GKE) ayrıntısı |
| Scheduling, networking, storage, sorun giderme | Güvenlik derinliği (o G3/CKS'in işi) |
| Hız + doğruluk (2 saat, ağırlıklı görevler) | Ezber; sınavda `kubernetes.io` açık |

Geçme, "bir cluster'da iş yapabiliyorum" der. Production sahipliği değil — onu Blok E ve
gerçek on-call öğretir.

---

## 3. Hangi modüller müfredatı karşılıyor

Alan ağırlıkları resmi müfredattan; **kendin doğrula**:

| Alan | ~Ağırlık | Karşılayan modül | Boşluk (kendin çalış) |
|---|---|---|---|
| Troubleshooting | ~%30 | [`D1`](../block-d-orchestration/D1-k8s-temel.md), [`D2`](../block-d-orchestration/D2-k8s-production.md), [`K04`](../labs/broken/K04-imagepullbackoff-rbac/README.md), [`K05`](../labs/broken/K05-oomkilled-probe/README.md), [`B1`](../block-b-visibility/B1-log-okuma.md) | Node NotReady, kubelet/certificate sorunları |
| Cluster Architecture, Install & Config | ~%25 | [`D1`](../block-d-orchestration/D1-k8s-temel.md) (RBAC), [`D3`](../block-d-orchestration/D3-secret-yonetimi.md) | **kubeadm ile kurulum/yükseltme, etcd yedek/geri-yükleme** — patika `kind` kullanır, bunları kendin çalış |
| Services & Networking | ~%20 | [`D1`](../block-d-orchestration/D1-k8s-temel.md) (Service, Ingress, NetworkPolicy) | CoreDNS yapılandırma, Gateway API, CNI ayrıntısı |
| Workloads & Scheduling | ~%15 | [`D1`](../block-d-orchestration/D1-k8s-temel.md), [`D2`](../block-d-orchestration/D2-k8s-production.md) | DaemonSet, static pod, taint/toleration, affinity |
| Storage | ~%10 | [`D2`](../block-d-orchestration/D2-k8s-production.md) (kısmi) | **PV/PVC/StorageClass yaşam döngüsü** — patikada zayıf, kendin çalış |

> 🕳️ **En büyük iki boşluk dürüstçe:** (1) *kubeadm kurulum/yükseltme + etcd yedek-geri
> yükleme* ve (2) *storage (PV/PVC/StorageClass)*. Patika bilerek `kind` üstünde ilerledi
> (yerel-önce), o yüzden bu iki alan sende eksik. CKA'ya girmeden bunları **ayrıca** çalış.

---

## 4. Resmi müfredat nerede

Tek gerçek kaynak resmi müfredat ve sınav kılavuzu — bu sayfa değil:

- [CNCF CKA Curriculum (GitHub)](https://github.com/cncf/curriculum) → güncel domain listesi ve ağırlıklar
- [Linux Foundation — CKA](https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/) → kayıt, kurallar, sınav ortamı
- Sınavda **yalnız** `kubernetes.io` (ve alt alan adları) açıktır — hangi sayfalar açık, resmi handbook'ta yazar.

---

## 5. Hazırlık planı

1. Blok D'yi ve üç kırık lab'ı bitir (yukarıdaki checklist).
2. İki büyük boşluğu kapat: kubeadm kurulum/yükseltme + etcd yedek/geri-yükleme; storage.
3. **Hız çalış.** CKA'da bilmek yetmez, 2 saatte bitirmek gerekir. `kubectl` kısayollarını,
   imperative komutları (`kubectl create ... --dry-run=client -o yaml`) ezberle.
4. `alias k=kubectl`, `kubectl explain`, `--dry-run` ile YAML üretmeyi refleks yap.
5. Resmi sınav simülatörü (kayıtla gelir) → gerçek zaman baskısı altında dene.
6. Sınav-alma disiplini → [`HOW-TO-CERTIFY.md`](HOW-TO-CERTIFY.md).

---

## 6. Pratik ortamı (yerel-önce)

- **kind** veya **k3s** ile çok-node'lu bir cluster kur; para gerekmez.
- [`L13`](../labs/build/L13-k8s-temel/README.md) ve [`L14`](../labs/build/L14-k8s-production/README.md) zaten kind üstünde.
- Boşluk alanları için: `kubeadm` ile 2 VM'de (veya `kind`'ın dışında Vagrant/Multipass ile) bir
  cluster kurup **etcd snapshot al/geri yükle** pratiği yap — bu sınavın klasik görevidir.
- Storage için: yerel `StorageClass` + `PVC` + Pod bağlama döngüsünü tekrarla.

---

## 7. Sınav günü mekaniği

- **2 saat, performansa dayalı**, uzaktan gözetimli. Gerçek cluster'lara SSH/terminal.
- Görevler **ağırlıklıdır**; her göreve yüzde değeri yazar. Yüksek puanlıları önce çöz.
- Bağlam değişimi (`kubectl config use-context`) her görevin başında **zorunlu** — atlarsan yanlış cluster'da çalışırsın.
- `kubernetes.io` açık ama arama yavaştır; bilgiyi orada aramak değil, **hızlı bulmak** için önceden alıştır.
- Emin olmadığın görevi işaretle, geç, dönebilirsen dön. Kısmi puan vardır — görevi tamamen boş bırakma.
- Geçme eşiği resmi handbook'ta yazar (tarihsel olarak ~%66); **resmi sayfayı doğrula.**

---

## 8. Hazır olduğunu nereden anlarsın

- [ ] Simülatörde (Killer.sh vb.) zaman dolmadan **tüm** görevleri bitiriyorsun
- [ ] `ImagePullBackOff`/`CrashLoopBackOff`/`Pending`/`NotReady` için ilk üç teşhis komutun refleks
- [ ] etcd snapshot alıp geri yükleyebiliyorsun (bakmadan)
- [ ] Imperative komutla 30 saniyede Deployment+Service+expose yapabiliyorsun
- [ ] RBAC Role/Binding'i `kubectl create role/rolebinding` ile bakmadan kurabiliyorsun

---

## 9. Geçemezsen

- Bu sınavı ilk seferde geçememek yaygındır — zaman baskısı gerçek. Utanç yok.
- Kayıt genelde **bir ücretsiz tekrar** içerir (resmi sayfadan doğrula) — ikinci şansı planla.
- Skor, alan bazında zayıflığını göstermez; kendi hissine göre en yavaş kaldığın alana dön.
- Neredeyse her zaman sorun bilgi değil **hız**dır → simülatörde tempo çalış, sonra tekrar gir.

---

## 📋 Checklist — G2'ye girmeden

```
[ ] D1–D5 kabul kriterleri canlı cluster'da geçildi
[ ] K04 + K05 + K06 kırık lab'ları çözüldü
[ ] Blok D STAGE-EXAM geçildi
[ ] Boşluklar kapatıldı: kubeadm kurulum/yükseltme + etcd yedek/geri-yükleme + storage
[ ] Simülatörde tüm görevler süre içinde bitiriliyor
[ ] Imperative kubectl + --dry-run refleks
```

---

## 📚 Referanslar
- [CNCF Curriculum (CKA)](https://github.com/cncf/curriculum)
- [Linux Foundation — CKA](https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/)
- [Kubernetes resmi dokümantasyon](https://kubernetes.io/docs/) — sınavda açık olan kaynak
- Repo içi: [`README.md`](README.md) · önceki kapı [`G1-kcna-terraform.md`](G1-kcna-terraform.md) · sonraki kapı [`G3-cks-aws-saa.md`](G3-cks-aws-saa.md) · [`HOW-TO-CERTIFY.md`](HOW-TO-CERTIFY.md)

---

> *"CKA seni cluster'ın karşısına oturttu ama hep 'nasıl çalışır' sorusuyla. Bir sonraki
> kapı ya 'nasıl saldırıya uğrar' (CKS) ya da 'nasıl mimarilenir' (AWS SAA) diye sorar."*
