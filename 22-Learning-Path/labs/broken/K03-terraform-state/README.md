# K03 — Terraform: apply kilitli / beklenmedik sonuç

> Modül: [`C3`](../../../block-c-reproducibility/C3-terraform.md) · Tür: kırık lab · Süre: ~45–90 dk

## Belirti

Dün gece bir `terraform apply` yarıda kesildi (terminal kapandı). Bugün devam etmek
istiyorsun ama hiçbir komut çalışmıyor:

```bash
cd env && terraform plan
# Error: Error acquiring the state lock
# ... Lock Info: ID: <bir-uuid> ...
```

Terraform "state kilitli" diyor ve ilerlemiyor. **Sebebi kanıtla, körlemesine
dosya silme.** Kilidi kimin, niçin tuttuğunu anla; sonra doğru araçla aç.

## Gerekenler
- `terraform` (veya `tofu`). İlk `init` için internet (provider indirir).

## Kur

```bash
bash setup.sh
```

## Görevin

1. Kök sebebi **kanıtla** (belirti → daraltma → kök sebep → düzeltme → doğrulama).
2. Kilidi **doğru araçla** aç (rastgele dosya silmek son çare, ilk çözüm değil).
3. Doğrula:
   ```bash
   bash verify.sh    # sıfır çıkış = çözdün
   ```
4. Bir `teshis.md` yaz: kilit ID'sini nereden okudun, niçin `force-unlock` doğru araç.

## Kurallar

- **Önce kendin dene.** Takılırsan `hints/`'i sırayla aç; `solution.md` en son.
- Bir sonraki soruyu düşün: state **paylaşılan** bir yerde (S3+DynamoDB) olsaydı bu
  kilit ne işe yarardı? (İki kişi aynı anda apply ederse ne olur?)
