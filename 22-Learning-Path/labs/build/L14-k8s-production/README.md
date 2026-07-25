# L14 — K8s production: request/limit, probe, PDB, HPA

> Modül: [`D2`](../../../block-d-orchestration/D2-k8s-production.md) · Süre: ~4 saat · Kırık lab: [`K05`](../../broken/K05-oomkilled-probe/README.md)

D1'de Pod ayağa kalktı. Bu lab onu **production'a hazır** yapar: doğru request/limit,
`readiness`/`liveness` probe, kesinti bütçesi (PDB) ve yük altında ölçeklenme (HPA).
Bu ayarlar olmadan Pod "çalışıyor" görünür ama ilk yük dalgasında ya OOMKilled olur
ya trafik alır almaz düşer — bunu K05'te bizzat yaşayacaksın.

## Gerekenler
- D1'deki kind cluster (`kind create cluster --name lab-d1`), `kubectl`.
- Yük üretmek için `kubectl run` + basit bir istek döngüsü (veya `hey`).

### metrics-server'ı kind'a kur (HPA bunu ister)
kind'ın kubelet sertifikası self-signed olduğu için `--kubelet-insecure-tls` gerekir:
```bash
# <VERSION> yerine resmi release sürümünü yaz (:latest kullanma)
kubectl apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/download/<VERSION>/components.yaml"
kubectl -n kube-system patch deploy metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl -n kube-system rollout status deploy/metrics-server
kubectl top nodes        # değer dönüyorsa metrics-server çalışıyor
```

## Görev

1. **request/limit ekle (SEN).** `starter/deployment.yaml`'daki TODO'ları doldur:
   `requests` planlama için, `limits` üst sınır için. Bellek limitini **gerçekçi**
   ver — çok düşükse OOMKilled (K05), çok yüksekse düğüm israfı.
2. **Probe ekle (SEN).** `readinessProbe` (trafiğe hazır mı) ve `livenessProbe`
   (kilitlendi mi) — ikisi de `/` yolu, port 8080. Farkı bil: readiness başarısızsa
   Pod **trafik almaz**; liveness başarısızsa Pod **yeniden başlatılır**.
   ```bash
   kubectl apply -f starter/deployment.yaml
   kubectl -n lab describe pod -l app=lab-app | grep -A2 -i readiness
   ```
3. **PDB ekle (SEN).** `starter/pdb.yaml`: node drain sırasında en az 1 replika ayakta
   kalsın. Kanıt:
   ```bash
   kubectl -n lab get pdb
   ```
4. **HPA + yük.** `starter/hpa.yaml`: CPU %50 hedef, min 2 max 5. Yük bas, replika
   sayısının arttığını gör:
   ```bash
   kubectl apply -f starter/hpa.yaml
   kubectl -n lab run load --image=busybox:1.36 --restart=Never -it --rm -- \
     sh -c 'while true; do wget -qO- http://lab-svc >/dev/null; done'
   kubectl -n lab get hpa -w        # REPLICAS artmalı
   ```
5. **Raporla.** `report.txt`'e: `describe` çıktısından probe/limit satırları, `get hpa`
   yük öncesi/sonrası replika sayısı, ve "request ile limit farkı + OOMKilled niçin
   olur" açıklaması.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] Deployment `requests` + `limits` + `readinessProbe` + `livenessProbe` içeriyor.
- [ ] Manifestler bir `HorizontalPodAutoscaler` ve bir `PodDisruptionBudget` içeriyor.
- [ ] `report.txt` HPA'nın yük altında replika artırdığını (öncesi/sonrası sayı) gösteriyor.
- [ ] `report.txt` request↔limit farkını ve OOMKilled'ı kendi cümlelerinle anlatıyor.

## İpucu (çözüm değil)
- `requests` = Pod'un **garanti** aldığı; scheduler buna göre yerleştirir.
  `limits` = aşamayacağı tavan; bellekte aşılırsa **OOMKilled**, CPU'da throttle.
- Probe için doğru portu ver. Yanlış port → readiness hep fail → Pod hiç `Ready` olmaz
  → Service `Endpoints` boş → "trafik almıyor" (K05'in ikinci yüzü).
- HPA `metrics-server` olmadan `<unknown>` gösterir. Önce metrics-server'ın çalıştığını
  doğrula (`kubectl top pods`).

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
