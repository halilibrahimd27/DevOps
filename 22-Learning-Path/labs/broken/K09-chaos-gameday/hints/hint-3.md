# Hint 3 — neredeyse cevap

`env/deployment.yaml`'ı şu üç değişiklikle düzelt, yeniden uygula, deneyi tekrarla.

```yaml
spec:
  strategy:
    type: RollingUpdate          # Recreate DEĞİL
    rollingUpdate:
      maxUnavailable: 0          # hiçbir an hazır replica sayısı düşmesin
      maxSurge: 1
  # ...
      containers:
        - name: web
          image: nginxinc/nginx-unprivileged:1.27-alpine
          ports:
            - containerPort: 8080
          readinessProbe:        # trafik yalnız gerçekten hazır pod'a gitsin
            httpGet: { path: /, port: 8080 }
            initialDelaySeconds: 2
            periodSeconds: 5
```

Ayrıca bir PDB ekle (gönüllü kesintide blast radius'u sınırlar):

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web
  namespace: chaos
spec:
  minAvailable: 2
  selector:
    matchLabels: { app: web }
```

Uygula ve deneyi tekrar yürüt:
```bash
kubectl apply -f env/deployment.yaml
kubectl apply -f env/pdb.yaml
kubectl -n chaos rollout restart deploy/web    # artık başarısız istek ~0 olmalı
```

`gameday.md`'ye hipotez → deney → sonuç → bulunan zafiyet → eylem maddesini yaz.
Tam teşhis akışı: `solution.md`.
