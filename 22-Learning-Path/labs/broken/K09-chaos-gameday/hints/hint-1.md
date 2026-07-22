# Hint 1 — yön

Önce **hipotezi yaz**, sonra enjekte et. Hipotez olmadan deney kurcalamadır: sapmayı
neyle karşılaştıracaksın?

> "3 replica çalışıyor; `rollout restart` sırasında `web` kesintisiz kalır."

Şimdi deneyi yürütürken **pod'lara ne olduğunu** izle:

```bash
kubectl -n chaos get pods -w      # bir terminalde açık kalsın
kubectl -n chaos rollout restart deploy/web   # başka terminalde
```

Sağlıklı bir HA dağıtımda pod'lar **kademeli** değişir (biri kalkarken diğerleri ayakta).
Eğer **üçü birden** `Terminating` olup sonra yeniden yaratılıyorsa, o restart penceresinde
servisin arkasında çalışan pod **kalmaz** — probe döngün başarısız istek sayar.

Bu davranışı ne belirler? Deployment'ın **güncelleme stratejisi**. Oraya bak.
