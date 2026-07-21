# Hint 3 — neredeyse cevap

Kök sebep: `compose.yaml`'daki port eşlemesi `"8080:80"`. Container tarafı (80)
uygulamanın dinlediği port (5000) ile eşleşmiyor.

Düzelt: container tarafını uygulamanın portuna çevir.

```yaml
# env/compose.yaml
    ports:
      - "8080:5000"     # host 8080 -> container 5000 (app burada)
```

Sonra yeniden oluştur ve doğrula:

```bash
cd env && docker compose up -d
curl -s http://127.0.0.1:8080/health    # ok
```
