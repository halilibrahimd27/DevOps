# Hint 1 — yön

İki ayrı sorun var; birer birer. **Önce Pod niçin ayağa kalkmıyor?**

```bash
kubectl -n k04 describe pod -l app=app | tail -20
kubectl -n k04 get events --sort-by=.lastTimestamp | tail
```

`describe` çıktısının `Events` bölümü sana **kelimesi kelimesine** sebebi söyler:
`Failed to pull image ... not found`. Container ayağa kalkamıyorsa image katmanına bak
— image adı/tag'i gerçekten var mı?
