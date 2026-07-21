# Hint 3 — neredeyse cevap

Port 8080'i `k01-decoy` adlı gereksiz bir servis tutuyor. Uygulama aynı porta
bağlanamadığı için sürekli çöküyor.

İki geçerli düzeltme var — kök sebebe göre seç:

**(a) Çakışan servisi kaldır** (port gerçekten uygulamanın olmalıysa — burada öyle):
```bash
sudo systemctl disable --now k01-decoy
sudo systemctl restart k01-app
```

**(b) Uygulamayı başka porta taşı** (iki servis de gerekliyse) — ama burada decoy
gereksiz, doğrusu (a).

Doğrula:
```bash
ss -tlnp | grep ':8080'                 # artık k01-app dinliyor
curl -s http://127.0.0.1:8080/health    # ok
```
