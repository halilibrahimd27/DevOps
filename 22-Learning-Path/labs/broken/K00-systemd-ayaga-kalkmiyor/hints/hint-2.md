# Hint 2 — daralt

Hata bir **dosyayla** ilgili. Unit'in tam olarak hangi dosyaları okumaya
çalıştığına bak:

```bash
systemctl cat k00-app
```

`ExecStart`, `EnvironmentFile` gibi satırlarda geçen **her yolun gerçekten var
olup olmadığını** tek tek kontrol et:

```bash
ls -l /opt/k00-app/app.py
ls -l /etc/k00-app/app.env
```

İkisinden biri yok. Hangisi?
