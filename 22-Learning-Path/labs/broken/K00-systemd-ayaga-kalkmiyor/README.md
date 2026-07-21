# K00 — systemd servisi ayağa kalkmıyor

> Modül: [`A6`](../../../block-a-intuition/A6-elle-deploy.md) · Tür: kırık lab · Süre: ~30–60 dk

## Belirti

`k00-app` servisini kurdun ama ayağa kalkmıyor.

```bash
sudo systemctl start k00-app
# başarısız
curl -s http://127.0.0.1:8080/health
# curl: (7) Failed to connect to 127.0.0.1 port 8080: Connection refused
```

Servis `active` olmuyor. **Sebebi bul ve düzelt.** Bu README sana ne bozulduğunu
söylemez — teşhis senin işin.

## Gerekenler
- systemd olan bir Linux (VM). `sudo`, `systemctl`, `journalctl`.

## Kur

```bash
sudo bash setup.sh
```

Bu, `k00-app` servisini **bilerek bozuk** kurar ve başlatmayı dener.

## Görevin

1. Servisin neden başlamadığını bul (dokümana değil, sisteme sor).
2. Kök sebebi düzelt.
3. Doğrula:
   ```bash
   bash verify.sh    # sıfır çıkış = çözdün
   ```

## Kurallar

- **Önce kendin dene.** Takılırsan `hints/hint-1.md`'den başla, sırayla ilerle.
- `solution.md`'yi ancak `hint-3` de yetmezse aç — orada önce **teşhis akışı**,
  sonra kök sebep var.
- Çözünce: kök sebebi ve onu **hangi komutla** bulduğunu bir cümleyle yaz.
