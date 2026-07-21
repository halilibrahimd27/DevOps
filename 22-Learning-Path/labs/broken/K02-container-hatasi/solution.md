# K02 — Çözüm

> **Önce kendin dene.** Aşağıda önce **teşhis akışı**, sonra kök sebep.

## Teşhis akışı (üç komutla daralt)

1. **Container çalışıyor mu, çöküyor mu?**
   ```bash
   cd env && docker compose ps
   ```
   `Up` görüyorsun — uygulama çökmüyor. Demek sorun app'in *çalışmasında* değil,
   ona **ulaşmakta**.

2. **App hangi portu dinliyor?**
   ```bash
   docker compose logs app | grep listening
   # listening on 0.0.0.0:5000
   ```
   Uygulama container içinde **5000**'i dinliyor.

3. **Eşleme neyi neye bağlıyor?**
   ```bash
   grep -A1 ports compose.yaml
   #   - "8080:80"
   ```
   Host 8080 → container **80**. Ama app 80'i değil 5000'i dinliyor. Container'ın
   80 portunda dinleyen yok → `curl :8080` boş yanıt alıyor.

Bu üç komut belirtiyi (bağlanılamıyor) kök sebebe (yanlış port eşlemesi) **kanıtla**
bağladı.

## Kök sebep

`ports: "8080:80"` eşlemesinin **container tarafı** (80) uygulamanın gerçek portu
(5000) ile uyuşmuyor. Docker paketi 8080'den container'ın 80'ine yönlendiriyor,
orada dinleyen olmadığı için bağlantı boşa düşüyor.

## Düzeltme

```yaml
# compose.yaml
    ports:
      - "8080:5000"
```
```bash
docker compose up -d
```

## Belirtinin gittiğini kanıtla

```bash
curl -s http://127.0.0.1:8080/health    # ok
```

## Niye böyle oluyor

`"HOST:CONTAINER"` eşlemesinde sol taraf makinende açılan port, sağ taraf
container **içinde** trafiğin gittiği port. Sağ taraf uygulamanın `listen` ettiği
portla aynı olmalı. Bu, yeni başlayanın en sık takıldığı container hatasıdır:
container "Up" olduğu için "çalışıyor" sanılır, oysa erişim yolu kopuktur.

## Ders

"Container Up" ile "uygulama erişilebilir" iki ayrı iddiadır; her birini ayrı bir
komutla kanıtla. `ps` (ayakta mı) → `logs` (hangi port) → eşleme (doğru mu) üçlüsü
port sorunlarını dakikada daraltır.
