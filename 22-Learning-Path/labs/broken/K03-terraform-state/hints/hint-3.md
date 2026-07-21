# Hint 3 — neredeyse cevap

Kök sebep: yarıda kesilen apply, `.terraform.tfstate.lock.info` dosyasını geride
bıraktı. Terraform yeni bir işlem başlatınca bu kilidi görüp "başkası çalışıyor"
sanıyor.

Doğru araç `force-unlock` — ID'yi hata mesajından al:

```bash
cd env
terraform force-unlock a1b2c3d4-0000-4000-8000-000000000000
terraform plan     # artık kilit yok
```

> Elle `rm .terraform.tfstate.lock.info` de kilidi kaldırır ama `force-unlock`
> doğru araçtır: ID'yi doğrular, yanlış kilidi kaldırmanı zorlaştırır. Paylaşılan
> backend'de (S3+DynamoDB) elle silmek mümkün bile olmaz.
