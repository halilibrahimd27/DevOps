# L12 — Bulut temelleri + bütçe alarmı (İLK ADIM: alarm)

> Modül: [`C4`](../../../block-c-reproducibility/C4-bulut-butce-alarmi.md) · Süre: ~3 saat · Kırık lab: yok

Bu, patikanın **gerçek bulut kullanan ilk** lab'ı. Kural tek: hiçbir kaynak
açmadan **önce** bütçe alarmı kurulur. Sıra tersine dönerse — önce kaynak, sonra
alarm — unutulan bir kaynak ay sonunda fatura olarak geri gelir. Bu lab'ın
**birinci adımı** budur, süsü değil.

> ⚠️ Bu lab bir noktada gerçek bir bulut hesabı gerektirir (bütçe API'si LocalStack
> tarafından tam taklit edilmez). Bütçe tanımını **koda** yaz, `terraform validate`
> ile doğrula; gerçek hesabında `apply` et. Küçük kaynak açma/kapama kısmını yine
> **LocalStack**'te ücretsiz yaparsın.

## Gerekenler
- `terraform`, `docker`, `curl`.
- LocalStack (kaynak açma/kapama için): `docker run -d -p 4566:4566 --name localstack localstack/localstack`.
- (Gerçek alarm için) bir bulut hesabı — bütçeyi düşük tut (`5 USD` gibi).

## Görev — sıra bağlayıcı

1. **ÖNCE: bütçe alarmını koda yaz.** `starter/budget.tf.template`'i `budget.tf`
   olarak doldur: aylık bir `aws_budgets_budget`, eşiği %80'e gelince bir e-postaya
   bildirim. E-posta yerine **`<YOUR_EMAIL>`** placeholder — gerçek adresi repoya yazma.
   ```bash
   terraform init
   terraform validate          # yapı doğru mu
   terraform plan              # ne oluşacak
   ```
   Gerçek hesabında `terraform apply` + konsoldan bir test bildirimi tetikle.
2. **SONRA: küçük bir kaynak aç (LocalStack).** `resource.tf`'te bir `aws_s3_bucket`
   aç, `terraform apply`, sonra `terraform destroy`. Açık kaynak kalmadığını doğrula:
   ```bash
   terraform destroy -auto-approve
   terraform state list        # boş olmalı
   ```
3. **Free tier'ı yaz.** `report.txt`'e hangi servislerin free tier kapsamında,
   hangilerinin saat/GB başına ücretli olduğunu **listele** (en az 4 servis).
4. **Kavramları tanımla.** `report.txt`'e `VPC`, `IAM`, `compute` kavramlarını kendi
   cümlelerinle tanımla — bir cümle yeter, ama doğru olsun.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `budget.tf` bir `aws_budgets_budget` + eşik (`threshold`) + bir bildirim kanalı
      (`subscriber_email_addresses`) içeriyor.
- [ ] `report.txt` en az dört servisi free/ücretli olarak listeliyor.
- [ ] `report.txt` VPC, IAM ve compute'u kendi cümlelerinle tanımlıyor.
- [ ] `report.txt` bütçe alarmının **tetiklenerek** test edildiğini (veya gerçek
      hesapta nasıl test edileceğini) yazıyor.

## İpucu (çözüm değil)
- Alarm önce gelir çünkü koruma, koruyacağı şeyden **önce** kurulmalı. Yangın alarmını
  eve taşındıktan sonra takmazsın.
- `ACTUAL` bildirim gerçekleşen harcamada, `FORECASTED` tahmini harcamada tetiklenir.
  İkisini birlikte kurmak erken uyarı verir.
- Free tier "ücretsiz" değil "belli bir eşiğe kadar ücretsiz" demektir — eşiği aşınca
  saat/GB başına ücret başlar. Alarm tam da bunu yakalar.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
