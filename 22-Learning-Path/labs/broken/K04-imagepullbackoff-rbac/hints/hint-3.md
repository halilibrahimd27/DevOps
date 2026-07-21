# Hint 3 — neredeyse cevap

İki kök sebep:
1. **Image tag yok** → `ImagePullBackOff`. Düzelt: gerçek tag (`1.27-alpine`).
2. **default-deny var, izin yok** → Pod çalışsa da hiçbir gelen bağlantı kabul
   edilmiyor. NetworkPolicy toplamsaldır: reddettikten sonra **açman** gerekir.

İzin kuralını ekle (aynı namespace'ten gelen trafiğe izin):

```yaml
# env/allow.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: k04
spec:
  podSelector:
    matchLabels: { app: app }
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - podSelector: {}     # aynı namespace'teki Pod'lar
      ports:
        - protocol: TCP
          port: 8080
```
```bash
kubectl apply -f env/allow.yaml
kubectl -n k04 run probe --image=busybox:1.36 --restart=Never -it --rm -- \
  wget -qO- --timeout=3 http://app-svc     # artık yanıt var
```
