# K03 — Çözüm

> **Önce kendin dene.** Aşağıda önce **teşhis akışı**, sonra kök sebep.

## Teşhis akışı

1. **Hatayı tam oku.**
   ```bash
   cd env && terraform plan
   # Error: Error acquiring the state lock
   # Lock Info:
   #   ID:        a1b2c3d4-0000-4000-8000-000000000000
   #   Created:   2024-01-01 ...
   ```
   Terraform kilidi kimin tuttuğunu söylüyor. `Created` çok eski, `Operation` bir
   apply.

2. **Kilit canlı mı, bayat mı?**
   ```bash
   ps aux | grep -i '[t]erraform'      # çalışan terraform var mı?
   cat .terraform.tfstate.lock.info    # kilit bilgisi dosyada
   ```
   Çalışan terraform **yok**. Demek kilit, ölmüş bir işlemden kalan **bayat** kilit.

3. **Kilit ID'sini al.** Hata mesajındaki (veya dosyadaki) `ID` alanını kopyala.

## Kök sebep

Yarıda kesilen bir `apply`, `.terraform.tfstate.lock.info` dosyasını temizlemeden
öldü. Local backend her işlemin başında bu dosyayı `O_EXCL` ile yaratmaya çalışır;
dosya zaten varsa "kilit alınamıyor" hatası verir. Kilit, iki işlemin state'i aynı
anda bozmasını engellemek içindir — ama sahibi ölünce geride kalır.

## Düzeltme

```bash
terraform force-unlock a1b2c3d4-0000-4000-8000-000000000000
terraform plan     # kilit yok, çalışıyor
```

`force-unlock` doğru araçtır çünkü ID'yi doğrular ve paylaşılan backend'lerde
(S3+DynamoDB) de çalışır — orada dosyayı elle silemezsin.

## Belirtinin gittiğini kanıtla

```bash
terraform plan     # 'acquiring the state lock' hatası YOK
test ! -f .terraform.tfstate.lock.info && echo "kilit temiz"
```

## Niye böyle oluyor

State kilidi eşzamanlı yazımları önler: iki mühendis aynı anda apply ederse
biri diğerinin değişikliğini ezip state'i bozabilir. Kilit bunu engeller — bedeli,
bir işlem çökerse kilidin geride kalabilmesidir. Bu yüzden `force-unlock` vardır.

## Ders

"Kilitli" hatası panik sebebi değil; Terraform sana çözümü mesajın içinde veriyor.
Önce kilidin **canlı mı bayat mı** olduğunu doğrula (çalışan süreç var mı), sonra
`force-unlock`. Körlemesine dosya silmek local'de işe yarar ama paylaşılan
backend'de yanlış alışkanlıktır.
