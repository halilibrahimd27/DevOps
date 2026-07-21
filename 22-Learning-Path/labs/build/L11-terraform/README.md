# L11 — Terraform: elle kurduğunu koda çevir (yerel: LocalStack)

> Modül: [`C3`](../../../block-c-reproducibility/C3-terraform.md) · Süre: ~3 saat · Kırık lab: [`K03`](../../broken/K03-terraform-state/)

A6'da altyapıyı elle kurdun; komutları hatırlaman, tekrar kurman gerekti. Bu lab
aynı işi **kod** yapar: `terraform apply` sıfırdan kaynak açar, `destroy` kapatır,
tekrar `apply` **aynı** sonucu üretir. Hiç bulut, hiç para — her şey **LocalStack**
(AWS'i yerelde taklit eden bir container) üstünde.

## Gerekenler
- `terraform` (veya `tofu`), `docker`, `curl`.
- LocalStack: `docker run -d -p 4566:4566 --name localstack localstack/localstack`.
- (Opsiyonel) `awslocal`/`aws` CLI — kaynakları dışarıdan doğrulamak için.

## Görev

1. **LocalStack'i başlat.**
   ```bash
   docker run -d -p 4566:4566 --name localstack localstack/localstack
   curl -s http://127.0.0.1:4566/_localstack/health   # servisler "available"
   ```
2. **Provider'ı incele.** `starter/providers.tf` AWS provider'ı LocalStack'e
   (`http://localhost:4566`) yönlendirir; sahte `test`/`test` kimlik LocalStack'te
   yeterli. **Bu bir gerçek credential değil** — LocalStack onu görmezden gelir.
3. **Kaynağı yaz.** `starter/main.tf.template`'i `main.tf` olarak doldur: uygulamanın
   artefaktları için bir `aws_s3_bucket`, config için bir `aws_ssm_parameter`.
   ```bash
   cd starter
   terraform init
   terraform apply -auto-approve
   ```
4. **Tekrarlanabilirliği kanıtla.**
   ```bash
   terraform destroy -auto-approve
   terraform apply -auto-approve      # AYNI sonuç, elle hiçbir şey yapmadan
   ```
   İki `apply` çıktısını karşılaştır — kaynak sayısı ve isimler aynı olmalı.
5. **State'i anla.** `terraform.tfstate` dosyasına bak (JSON). Terraform "ne kurduğunu"
   nereden biliyor? Bu dosya silinirse ne olur? `report.txt`'e yaz — ayrıca state'in
   niçin **paylaşılan ve kilitlenen** bir yerde (S3+DynamoDB / TF Cloud) durması
   gerektiğini açıkla (bunu K03 kırık lab'ında yaşayacaksın).

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `main.tf` en az bir `resource` (ör. `aws_s3_bucket`) tanımlıyor.
- [ ] `providers.tf` LocalStack endpoint'ine (`4566`) yönlendiriyor.
- [ ] `report.txt` state'in ne olduğunu ve niçin kilitlenen bir yerde durması
      gerektiğini kendi cümlelerinle anlatıyor.

## İpucu (çözüm değil)
- LocalStack S3 için `s3_use_path_style = true` ve `skip_credentials_validation = true`
  gerekir — `providers.tf` bunları içerir.
- Idempotency: ikinci `apply` "No changes" demeli. Diyorsa Terraform'un dünya
  görüşü (state) ile gerçeklik uyuşuyor demektir. Uyuşmazsa buna **drift** denir (K03).
- State içinde hassas değer (parola) düz metin durabilir — bu yüzden state herkese
  açık repoda **tutulmaz**.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
