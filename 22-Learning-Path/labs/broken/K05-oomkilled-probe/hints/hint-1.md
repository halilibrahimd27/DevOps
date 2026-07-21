# Hint 1 — yön

`RESTARTS` bir sayaç; asıl bilgi container'ın **bir önceki ölümünde**:

```bash
kubectl -n k05 describe pod -l app=app | grep -A6 'Last State'
```

`Last State: Terminated`, `Reason: OOMKilled`, `Exit Code: 137` görürsen container
**bellek limitini aştığı için** çekirdek tarafından öldürülmüş demektir. Sonraki
soru: limit ne, uygulama ne kadar istiyor?
