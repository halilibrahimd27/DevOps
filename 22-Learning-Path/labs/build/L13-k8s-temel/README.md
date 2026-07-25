# L13 — K8s temel: Deployment/Service/Ingress + RBAC + NetworkPolicy

> Modül: [`D1`](../../../block-d-orchestration/D1-k8s-temel.md) · Süre: ~4 saat · Kırık lab: [`K04`](../../broken/K04-imagepullbackoff-rbac/README.md)

Uygulamayı yerel bir **kind** cluster'ında Deployment olarak çalıştırır, Service +
Ingress ile dışarıdan erişir. Ama K8s'i **güvenlik iplikten ayrı** öğrenmek bu
repoda yasak: aynı gün en az yetkili bir **RBAC** Role/RoleBinding ve bir
**NetworkPolicy** yazar, yetkisiz erişimin reddedildiğini gösterirsin. Güvenlik
sonradan eklenen bir bölüm değil — D1'in içinde.

## Gerekenler
- `docker`, `kind`, `kubectl`.
- kind cluster (ingress ile):
  ```bash
  kind create cluster --name lab-d1
  # ingress-nginx (kind örneği): controller manifesti uygula ve hazır olmasını bekle
  ```
- İmaj: `nginxinc/nginx-unprivileged:1.27-alpine` (non-root, 8080 dinler).

## Görev

1. **Namespace + Deployment.** `starter/deployment.yaml` hazır (non-root, resources,
   `serviceAccountName`). Uygula ve Pod'un `Running` olduğunu gör.
   ```bash
   kubectl apply -f starter/namespace.yaml
   kubectl apply -f starter/deployment.yaml
   kubectl -n lab get pods -w
   ```
2. **Service + Ingress (SEN yaz).** `starter/service.yaml` ve `starter/ingress.yaml`
   iskeletlerini doldur: Service ClusterIP 80 → hedef 8080, Ingress host `lab.example`.
   Erişimi doğrula:
   ```bash
   curl -H 'Host: lab.example' http://127.0.0.1/    # nginx karşılama sayfası
   ```
3. **RBAC — en az yetki (SEN yaz).** `starter/rbac.yaml`: yalnız `get/list/watch pods`
   yetkisi olan bir Role + onu Deployment'ın ServiceAccount'una bağlayan RoleBinding.
   Yetkisiz işlemin reddedildiğini **kanıtla**:
   ```bash
   kubectl auth can-i list pods   -n lab --as=system:serviceaccount:lab:lab-sa   # yes
   kubectl auth can-i delete pods -n lab --as=system:serviceaccount:lab:lab-sa   # no
   ```
4. **NetworkPolicy — varsayılan reddet (SEN yaz).** `starter/networkpolicy.yaml`:
   önce namespace'e **default-deny ingress**, sonra yalnız ingress-controller'dan
   gelen trafiğe izin. İzinsiz bir Pod'dan erişimin **kesildiğini** göster:
   ```bash
   kubectl -n lab run probe --image=busybox:1.36 --restart=Never -it --rm -- \
     wget -qO- --timeout=3 http://lab-svc || echo "engellendi (beklenen)"
   ```
5. **Raporla.** `report.txt`'e: `kubectl get` çıktısı, `auth can-i` sonuçları ve
   NetworkPolicy'nin izinsiz erişimi nasıl kestiğini yaz.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] Manifestler Deployment + Service + Ingress + Role/RoleBinding + NetworkPolicy içeriyor.
- [ ] `report.txt` `auth can-i delete pods … → no` sonucunu (yetkisiz erişim reddi) içeriyor.
- [ ] `report.txt` NetworkPolicy'nin izinsiz Pod erişimini kestiğini gösteriyor.
- [ ] Bir Pod'un neden `Pending`/`CrashLoopBackOff` olduğunu üç komutla daraltabildiğini
      `report.txt`'te bir örnekle anlatıyorsun.

## İpucu (çözüm değil)
- Service selector'ı Deployment `labels`'ıyla **birebir** eşleşmeli — eşleşmezse
  Service boş `Endpoints` gösterir, "çalışıyor ama erişilemiyor" (K04'ün senaryosu).
- RBAC "en az yetki": Role sadece işe yarayanı verir. `resources: ["pods"]`,
  `verbs: ["get","list","watch"]` — `delete` **yok**.
- NetworkPolicy toplamsaldır: default-deny koyduktan sonra izin kuralı **eklemezsen**
  hiçbir şey bağlanamaz. Önce reddet, sonra tek tek aç.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
