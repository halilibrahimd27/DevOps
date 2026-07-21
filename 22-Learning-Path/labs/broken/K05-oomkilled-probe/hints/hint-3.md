# Hint 3 — neredeyse cevap

İki kök sebep:
1. **Memory limit çok düşük** (`32Mi`, uygulama ~40MB istiyor) → OOMKilled. Düzelt: `128Mi`.
2. **readinessProbe yanlış porta bakıyor** (`9999`) — uygulama `8080` dinliyor.
   Probe hep başarısız → Pod hiç `Ready` olmaz → Service `Endpoints` boş → trafik yok.

Düzelt:

```yaml
# env/deployment.yaml
          resources:
            limits: { cpu: "200m", memory: "128Mi" }   # OOM biter
          readinessProbe:
            httpGet: { path: /health, port: 8080 }      # doğru port
```
```bash
kubectl apply -f env/deployment.yaml
kubectl -n k05 get pods            # 1/1 Ready
kubectl -n k05 get endpoints app-svc   # bir IP görünmeli
```
