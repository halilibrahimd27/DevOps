---
description: "Infrastructure as Code bölüm indeksi: Terraform best practices, module layout, OpenTofu migration, Pulumi, Crossplane, drift detection ve IaC karar ağacı."
---
# 03 · Infrastructure as Code

> *"Console'dan tıklayarak kurduğun bir kaynak, bir gün biri tarafından
> tıklayarak silinir — kim, ne zaman, niye? bilemezsin."*

IaC her şeyi Git'te kod olarak tutar: provision, değişiklik, silme — hepsi
PR review'dan geçer.

## İçindekiler

| Dosya | Konu |
|---|---|
| [`Terraform-Best-Practices.md`](Terraform-Best-Practices.md) | Module layout, remote state, workspace, lifecycle hooks, drift handling |
| [`Terraform-Module-Layout.md`](Terraform-Module-Layout.md) | Standart `vpc/eks/rds` modül iskeleti, `terraform-docs` |
| [`OpenTofu-Migration.md`](OpenTofu-Migration.md) | HashiCorp BSL → OpenTofu Apache geçişi, ne değişir/değişmez |
| [`Pulumi-vs-Terraform.md`](Pulumi-vs-Terraform.md) | TypeScript/Python ile IaC: ne zaman tercih edilir |
| [`Crossplane-Intro.md`](Crossplane-Intro.md) | Kubernetes-native cloud control plane: niçin, nasıl |
| [`Drift-Detection.md`](Drift-Detection.md) | `terraform plan`'i CI'da otomatik koşturma; manuel değişiklikleri yakalama |

## Karar ağacı: hangi IaC?

```
Tek cloud + Terraform/HCL bilgisi var?
└─ EVET → Terraform / OpenTofu (en yaygın, en çok hiring havuzu)
└─ HAYIR
   ├─ Multi-cloud, Kubernetes-merkezli?
   │   └─ Crossplane (her şey K8s API üzerinden)
   ├─ Programlama dilleri ile yazmak istiyorum?
   │   └─ Pulumi (TS/Python/Go/.NET)
   └─ AWS-only, JSII'a aşinayım?
       └─ AWS CDK / CDK8s
```

## Terraform modül hiyerarşisi (önerilen)

```
infra/
├── modules/                    ← reusable, versiyonlu
│   ├── vpc/
│   ├── eks/
│   ├── rds/
│   └── observability/
├── environments/               ← composition layer
│   ├── prod/
│   │   ├── main.tf            ← module'leri çağırır
│   │   ├── variables.tf
│   │   └── backend.tf
│   ├── staging/
│   └── dev/
└── stacks/                     ← cross-environment shared
    ├── networking/
    └── identity/
```

## Anti-pattern'ler

- ❌ State'i Git'e commitlemek (`*.tfstate` `.gitignore`'da olmalı)
- ❌ Module versiyonlamak yerine `path = "../modules/x"` (drift garantisi)
- ❌ `count` kullanmak (resource silindi, indeksler kaydı, plan büyük diff verir) — `for_each` kullan
- ❌ `terraform apply -auto-approve` PR review olmadan
- ❌ Bir devasa monolitik state (apply 1 saat sürer, blast radius büyük)
- ❌ Console'da değişiklik + sonra `terraform import` (uzaklaşırsan drift)
