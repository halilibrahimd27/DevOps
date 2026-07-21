# Hint 2 — daralt

Port eşlemesi iki parçalıdır: `"HOST:CONTAINER"`. `curl` HOST tarafına gider,
container içindeki uygulama CONTAINER tarafını dinler.

```bash
grep ports -A1 env/compose.yaml       # "8080:80"
docker compose logs app | grep listening   # listening on 0.0.0.0:5000
```

`8080:80` demek: host 8080 → container **80**. Ama uygulama container içinde **5000**
dinliyor. Yani container'ın 80 portunda **kimse yok**. Eşlemenin sağ tarafı yanlış.
