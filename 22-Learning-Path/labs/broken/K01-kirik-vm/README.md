# K01 — Servis ayağa kalkmıyor / yanıt vermiyor

> Modül: [`B3`](../../../block-b-visibility/B3-ilk-kirik-lab.md) · Tür: kırık lab · Süre: ~45–90 dk

## Belirti

`k01-app` servisini başlattın ama uygulama yanıt vermiyor.

```bash
sudo systemctl start k01-app
curl -s http://127.0.0.1:8080/health
# beklediğin 'ok' gelmiyor
```

Servis kalıcı olarak `active` kalmıyor ya da 8080'de beklediğin uygulama yok.
**Sebebi log ve metrikle bul, tahmin etme.** Bu README ne bozulduğunu söylemez.

## Gerekenler
- systemd olan bir Linux VM. `sudo`, `systemctl`, `journalctl`, `ss` (veya `lsof`).

## Kur

```bash
sudo bash setup.sh
```

## Görevin

1. Kök sebebi **kanıtla** (belirti → daraltma → kök sebep → düzeltme → doğrulama).
2. Düzelt.
3. Doğrula:
   ```bash
   bash verify.sh    # sıfır çıkış = çözdün
   ```
4. Bir `teshis.md` yaz: hangi **üç komutla** daralttın ve her birinin niçin.

## Kurallar

- **Önce kendin dene.** Takılırsan `hints/`'i sırayla aç; `solution.md` en son.
- Düzelttikten sonra belirtinin **gittiğini** ayrı bir komutla kanıtla —
  "düzelttim" demek yetmez.
