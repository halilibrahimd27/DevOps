# Hint 1 — yön

`OutOfSync` cluster ile Git'in ayrıştığını söyler. İki soru: (1) fark ne? (2) ArgoCD
niçin kapatmıyor?

```bash
kubectl -n argocd get application lab-app
kubectl -n lab get deploy lab-app -o jsonpath='{.spec.replicas}'; echo    # cluster: 5
# Git'teki manifest: replicas: 2
```

Fark net (5 vs 2). Şimdi asıl soru: ArgoCD normalde bunu geri çeker. Neden bu sefer
çekmiyor? Cevabı Application'ın **politikasında** ara.
