# Hint 2 — daralt

Ölme sebebini oku:

```bash
journalctl -u k01-app -p err -e
```

Muhtemelen `Address already in use` / `errno 98` görürsün. Uygulama **portu
alamıyor** çünkü başkası orada. Kim?

```bash
ss -tlnp | grep ':8080'
# veya
sudo lsof -i :8080
```

Çıktı, 8080'i hangi process'in (ve hangi servisin) tuttuğunu gösterir. O senin
uygulaman **değil**.
