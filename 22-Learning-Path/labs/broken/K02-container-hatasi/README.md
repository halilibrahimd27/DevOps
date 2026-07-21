# K02 — Container çalışıyor ama bağlanılamıyor

> Modül: [`C1`](../../../block-c-reproducibility/C1-container.md) · Tür: kırık lab · Süre: ~45–90 dk

## Belirti

Yığını `docker compose up -d` ile başlattın. `docker compose ps` container'ı
`Up` gösteriyor. Ama uygulamaya erişemiyorsun:

```bash
curl -s http://127.0.0.1:8080/health
# boş yanıt / connection reset — beklediğin 'ok' gelmiyor
```

Container ayakta, log'da hata yok, ama port yanıt vermiyor. **Sebebi kanıtla,
tahmin etme.** Bu README ne bozulduğunu söylemez.

## Gerekenler
- `docker` + `docker compose`, `curl`.

## Kur

```bash
bash setup.sh
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
- "Container Up" ≠ "uygulama erişilebilir". İkisini ayrı ayrı kanıtla.
