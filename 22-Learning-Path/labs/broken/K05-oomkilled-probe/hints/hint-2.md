# Hint 2 — daralt

Uygulama başlangıçta ~40MB ayırıyor ama `limits.memory: 32Mi`. 40 > 32 → OOMKilled.
Limiti gerçekçi bir değere çıkar (ör. `128Mi`), yeniden uygula:

```bash
# env/deployment.yaml → limits.memory: 128Mi
kubectl apply -f env/deployment.yaml
kubectl -n k05 get pods -w         # restart durmalı
```

Restart durdu ama Pod hâlâ `0/1` (Ready değil). İkinci katman: readiness probe.

```bash
kubectl -n k05 describe pod -l app=app | grep -A3 -i readiness
```

Probe hangi porta bakıyor? Uygulama hangi portu dinliyor? Uyuşuyorlar mı?
