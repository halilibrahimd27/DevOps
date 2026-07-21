---
description: "Yerel-önce ilkesi ve bulut bütçe alarmı: her lab önce ücretsiz/yerel ortamda çalışır, bulut zorunlu alarmla başlar."
tags: [Learning Path, FinOps]
---
# 💸 Maliyet Korkulukları

> *"Bulut faturası, öğrenirken alınabilecek en pahalı ve en gereksiz derstir. Her lab önce yerelde çalışır."*

Bu patikanın kuralı **yerel-önce'dir.** Blok C'nin sonuna kadar hiçbir lab para
gerektirmez. Bulut yalnızca C4'te ve **zorunlu bir bütçe alarmı lab'ıyla** başlar.
Bu sayfa, hangi aracın yerel karşılığının ne olduğunu ve buluta geçtiğinde kendini
nasıl koruyacağını gösterir.

---

## 🖥️ Yerel karşılıklar — buluta hiç dokunmadan

| İhtiyaç | Bulut (pahalı) | Yerel karşılık (ücretsiz) |
|---|---|---|
| VM / sunucu (A6, C3) | EC2 / Compute Engine | VirtualBox / Multipass / Proxmox / bir eski laptop |
| Container çalıştırma (C1) | ECS / Cloud Run | Docker / Podman — kendi makinen |
| Kubernetes (D1–D5) | EKS / GKE / AKS | `kind` veya `k3s` — tek makinede cluster |
| Registry (C2, D4) | ECR / Artifact Registry | yerel `registry` container ya da GHCR (ücretsiz kota) |
| CI (C2) | (çoğu bulut CI ücretli dakika) | GitHub Actions ücretsiz kotası / yerel `act` |
| Bulut API (C4) | gerçek AWS/GCP | **LocalStack** — çoğu servisi yerelde taklit eder |
| Obje depolama | S3 / GCS | MinIO (yerel S3-uyumlu) |

> Kubernetes'i öğrenmek için yönetilen cluster (EKS/GKE) **gerekmez.** `kind`
> tek bir Docker container içinde tam bir cluster verir — RBAC, NetworkPolicy,
> Ingress dahil. D bloğunun tamamı yerelde çalışır.

---

## ☁️ Buluta geçtiğinde — C4'ün ilk işi bütçe alarmı

C4 (bulut temelleri) buluta ilk dokunuşundur ve **ilk lab'ı bir bütçe alarmı
kurmaktır** — başka hiçbir şey yapmadan önce. Sıra kasıtlıdır: harcamayı görecek
mekanizma, harcamaya başlamadan önce kurulur.

```
[ ] Bulut hesabında faturalama alarmı kuruldu (örn. aylık düşük bir eşik)
[ ] Alarm bir bildirime bağlı (e-posta/SMS) ve test edildi
[ ] "Free tier" sınırları not edildi — hangi servis ücretsiz, hangisi değil
[ ] Kullanılmayan kaynağı kapatma alışkanlığı: her lab sonunda `destroy`
```

> ⚠️ **En sık ve en pahalı hata:** bir lab için açılan kaynağı (yük dengeleyici,
> NAT gateway, çalışan bir cluster) kapatmayı unutmak. Bunlar sen uyurken saat
> başı ücretlenir. Her bulut lab'ı `terraform destroy` / kaynak silme adımıyla biter.

---

## 🧯 Anti-pattern'ler

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| K8s öğrenmek için yönetilen cluster açmak | Saatlik ücret + öğrenme için gereksiz | `kind`/`k3s` ile yerelde |
| Bütçe alarmı olmadan bulut kullanmak | Faturayı ay sonu görürsün, geç | C4'ün ilk lab'ı alarm |
| Lab kaynağını açık bırakmak | Uyurken ücretlenir | Her lab sonunda `destroy` |
| Kredi kartını "sonra bakarım" diye bağlamak | Sürpriz fatura riski | Free tier sınırlarını önce oku |

---

## 📋 Checklist — buluta ilk kez geçmeden önce

```
[ ] C4'e kadar her şeyi yerelde (kind/LocalStack/Docker) yaptım
[ ] Bütçe alarmı kuruldu ve tetiklendiğini test ettim
[ ] Free tier sınırlarını biliyorum
[ ] Her bulut lab'ı için bir "destroy/temizlik" adımım var
```

---

> *"Yerelde bozulan bir cluster bedavadır; bulutta unutulan bir cluster faturadır. Önce bedava olanı boz."*
