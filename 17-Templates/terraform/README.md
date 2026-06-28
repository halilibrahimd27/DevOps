---
description: "Standart Terraform modül iskeleti: main.tf + variables.tf + outputs.tf; tip-güvenli, validation'lı, versiyon-pinli kopyala-yapıştır şablon."
tags:
  - Template
  - Terraform
  - IaC
---
# Terraform Module Skeleton

> Standart bir Terraform modülü iskeleti: `main.tf` + `variables.tf` + `outputs.tf`.
> Kopyala, kendi kaynağına göre doldur.

## Dosyalar

| Dosya | Amaç |
|---|---|
| [`main.tf`](main.tf) | Kaynak tanımları + `terraform`/`required_providers` bloğu |
| [`variables.tf`](variables.tf) | Tip-güvenli, açıklamalı, validation'lı girdi değişkenleri |
| [`outputs.tf`](outputs.tf) | Modülü tüketen kaynaklar için çıktılar |

## Kullanım

```bash
# Modülü kendi root config'inden çağır
module "<MODULE_NAME>" {
  source = "git::https://github.com/<ORG>/<REPO>.git//17-Templates/terraform?ref=<VERSION>"

  name        = "<NAME>"
  environment = "<ENV>"
  tags        = { team = "<TEAM>", owner = "<OWNER>" }
}
```

## Neden bu yapı

- **3 dosya ayrımı** standarttır: kaynaklar, girdiler, çıktılar ayrı okunur.
- **`variables.tf` validation'lı**: yanlış girdi `plan` aşamasında patlar, `apply`'da değil.
- **Versiyon pin'i** (`required_providers`): provider upgrade'i sürpriz drift yaratmasın.

> *"Modül, kopyalanan değil çağrılan koddur — girdi/çıktı sözleşmesi nettir."*
