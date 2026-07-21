# Hint 2 — daralt

Image tag'i mevcut olmayan bir sürüme işaret ediyor (`0.0-does-not-exist`). Gerçek
bir tag'e çevir (`1.27-alpine`), yeniden uygula:

```bash
# env/deployment.yaml içindeki image tag'ini düzelt, sonra:
kubectl apply -f env/deployment.yaml
kubectl -n k04 get pods -w        # Running olmalı
```

Pod `Running` oldu ama servise **hâlâ** ulaşamıyorsun. Bu **ikinci** sorun. Ağ
katmanına bak:

```bash
kubectl -n k04 get networkpolicy
kubectl -n k04 describe networkpolicy default-deny-ingress
```

Bir `default-deny` var. Peki gelen trafiğe **izin** veren bir kural var mı?
