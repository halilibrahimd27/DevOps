# Hint 3 — neredeyse cevap

Kök sebep: `spec.syncPolicy.automated` kaldırılmış. ArgoCD driftı görüyor ama
otomatik geri çekmiyor (manuel mod).

Otomatik sync + self-heal'i geri aç — bu hem şu anki driftı eşitler hem de kalıcı
çözümdür:

```bash
kubectl -n argocd patch application lab-app --type merge -p '{
  "spec": { "syncPolicy": { "automated": { "selfHeal": true, "prune": true } } }
}'
```

ArgoCD birkaç saniye içinde `replicas`'ı Git'teki değere (2) geri çeker.

```bash
kubectl -n argocd get application lab-app          # Synced
kubectl -n lab get deploy lab-app -o jsonpath='{.spec.replicas}'; echo    # 2
```

> Alternatif (tek seferlik): `argocd app sync lab-app` — ama self-heal açılmazsa
> drift **tekrar** gelir. Kalıcı çözüm otomatik politikadır.
