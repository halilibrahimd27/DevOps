# Hint 1 — yön

Önce şunu ayır: servis **hiç başlamadı** mı, **başlayıp öldü** mü?

```bash
systemctl status k01-app --no-pager
```

`active (running)` mi, yoksa `activating`/`failed` döngüsünde mi? `Restart=on-failure`
varsa sürekli yeniden deneyip başarısız oluyor olabilir. Bir sonraki durak: neden
öldüğünü öğrenmek.
