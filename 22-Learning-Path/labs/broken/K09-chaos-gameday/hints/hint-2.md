# Hint 2 — daralt

İki ayrı zafiyet var; ikisini de görmen gerekir.

**(a) Güncelleme stratejisi — kesintinin ana sebebi.**
```bash
kubectl -n chaos get deploy web -o jsonpath='{.spec.strategy.type}'; echo
# Recreate
```
`Recreate` = önce **tüm** eski pod'ları indir, **sonra** yenilerini kur. Aradaki
pencerede sıfır replica → tam kesinti. HA istiyorsan `RollingUpdate` gerekir
(`maxUnavailable: 0`, `maxSurge: 1` → hep en az 3 hazır pod kalır).

**(b) Hazırlık kontrolü — kesintiyi uzatan sebep.**
```bash
kubectl -n chaos get deploy web -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}'; echo
# boş
```
`readinessProbe` yoksa Kubernetes pod'u ayağa kalkar kalkmaz "hazır" sayar ve Service
ona trafik yollar — oysa nginx henüz dinlemiyor olabilir. `RollingUpdate`'e geçsen bile,
readiness olmadan yeni pod'lar erken trafik alıp hata döndürür.

Üçüncü bir eksik: **PodDisruptionBudget yok** → `drain`/gönüllü kesinti üç replica'yı
birden alabilir. Game day'de bunu da not et.
