# K06 — Çözüm

> **Önce kendin dene.** Önce **teşhis akışı**, sonra kök sebep.

## Teşhis akışı

1. **Fark ne?**
   ```bash
   kubectl -n argocd get application lab-app          # OutOfSync
   kubectl -n lab get deploy lab-app -o jsonpath='{.spec.replicas}'; echo   # 5
   # Git manifesti: replicas: 2
   ```
   Cluster (5) ile Git (2) ayrışmış — tanım gereği drift.

2. **ArgoCD niçin düzeltmiyor?**
   ```bash
   kubectl -n argocd get application lab-app -o jsonpath='{.spec.syncPolicy}'; echo
   # (boş)
   ```
   `automated` politika yok. ArgoCD driftı **görüyor** (`OutOfSync`) ama otomatik
   **çekmiyor**. Sorun ne cluster'da ne Git'te; **reconciliation politikasında**.

## Kök sebep

`spec.syncPolicy.automated` kaldırılmış (manuel mod). Bu modda ArgoCD yalnız fark
raporlar; geri çekme için elle `sync` gerekir. Elle yapılan `kubectl scale` de
bu yüzden kalıcı görünüyor.

## Düzeltme

Otomatik sync + self-heal'i geri aç (hem eşitler hem kalıcıdır):

```bash
kubectl -n argocd patch application lab-app --type merge -p '{
  "spec": { "syncPolicy": { "automated": { "selfHeal": true, "prune": true } } }
}'
```

## Belirtinin gittiğini kanıtla

```bash
kubectl -n argocd get application lab-app                              # Synced
kubectl -n lab get deploy lab-app -o jsonpath='{.spec.replicas}'; echo # 2
```

## Niye böyle oluyor

GitOps'ta Git **tek gerçek kaynaktır**; cluster ona yakınsamaya çalışır. `automated`
politika bu yakınsamayı sürekli yapar (`selfHeal`). Kapatılırsa ArgoCD gözlemci olur:
farkı söyler ama uygulamaz. Elle `kubectl edit/scale` bu yüzden anti-pattern'dir —
self-heal açıkken zaten geri alınır, kapalıyken de "gizli drift" biriktirir.

## Ders

`OutOfSync` panik değil, teşhis: cluster ≠ Git. Önce **farkı** ölç (replicas 5 vs 2),
sonra **niçin düzelmediğini** (`syncPolicy`). Kalıcı çözüm tek seferlik sync değil,
otomatik reconciliation'ı geri açmaktır — yoksa drift geri gelir.
