# Hint 1 — yön

Önce container **gerçekten** ayakta mı, yoksa sürekli yeniden mi başlıyor?

```bash
cd env && docker compose ps
docker compose logs app
```

Log'da `listening on 0.0.0.0:XXXX` satırına dikkat et. Uygulama **hangi portu**
dinlediğini söylüyor. Şimdi soru şu: dışarıdan istediğin port ile uygulamanın
dinlediği port aynı mı?
