---
description: "Terraform'dan OpenTofu'ya geçiş rehberi: HashiCorp BSL license sorunu, MPL 2.0 forku, uyumluluk farkları ve 2026'da neye geçilmeli sorusunun pratik cevabı."
---
# OpenTofu Migration — Terraform'dan Bağımsız Olmak

> *"HashiCorp 2023 Ağustos'ta Terraform license'ını BSL'e değiştirdi.
> Topluluk forklayıp **OpenTofu** açtı. 2026'da Terraform vs OpenTofu
> seçimi 'kararı verdin mi?' sorusuna dönüştü."*

Bu rehber Terraform → OpenTofu migration'ı, BSL license sorununu, ve
2026'da neye geçilmeli sorusunun pratik cevabını verir.

---

## 🎯 Özet: Niye OpenTofu?

| Boyut | Terraform (BSL) | OpenTofu (MPL) |
|---|---|---|
| **License** | Business Source License | Mozilla Public License 2.0 |
| **Source available** | ✅ ama kullanım kısıtlı | ✅ Tam open source |
| **Vendor lock-in** | HashiCorp | CNCF (Linux Foundation) |
| **Free for all** | Çoğu için ama "competitive" use yasak | Tüm kullanımlara açık |
| **Topluluk** | HashiCorp + ekosistem | CNCF + Spacelift, env0, Gruntwork, IBM |
| **Provider compatibility** | Native | Aynı (registry uyumlu) |
| **Module compatibility** | Native | %95+ uyumlu |
| **Velocity** | HashiCorp roadmap | Topluluk PR'ları (daha hızlı) |
| **Ticari destek** | HashiCorp Enterprise | Spacelift / env0 / Scalr |

> 🔑 **2026 önerisi**: Yeni proje **OpenTofu**. Mevcut Terraform stack — migrate veya kal.

---

## 📚 Hikâye

### 2023 Ağustos
- HashiCorp Terraform license'ı **BSL** (Business Source License)'a değiştirdi
- "Competitive use" yasak (örn: Terraform-as-a-Service vendor'ları)
- Topluluk şok

### 2023 Eylül
- Linux Foundation altında **OpenTF Foundation** kuruldu
- Spacelift, env0, Gruntwork, Cloudify ana sponsor

### 2024 Ocak
- **OpenTofu 1.6** → ilk stable
- Terraform 1.5'in fork'u, BSL öncesi kod tabanı

### 2024-2025
- OpenTofu CNCF Sandbox → Incubating
- Terraform 1.9, 1.10 yayınlandı (BSL altında)
- OpenTofu 1.7, 1.8 → state encryption, OCI registry, daha fazla

### 2026
- İki proje paralel yaşıyor
- **Topluluk dynamism OpenTofu'da**

---

## 🚀 Migration Adımları

### Adım 1: Backup
```bash
# State backup
terraform state pull > terraform.tfstate.backup-$(date +%F)

# tfstate'in S3 / GCS bucket'ında versionlama açık olduğunu kontrol et
```

### Adım 2: OpenTofu install
```bash
# macOS
brew install opentofu

# Linux
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | sh

# Verify
tofu version
```

### Adım 3: Working directory'i hazırla
```bash
# Hâlâ Terraform aktif
terraform plan
terraform apply
# Tüm değişiklikleri commit et

# Lock file rename
mv .terraform.lock.hcl .opentofu.lock.hcl   # opsiyonel; tofu .terraform.lock.hcl da okur
```

### Adım 4: Provider compatibility check
```bash
# Provider listesi
tofu init   # OpenTofu provider'ları indirir

# Providers
tofu providers
```

> 🔑 **Çoğu provider** (AWS, GCP, Azure, K8s) registry'de hem Terraform hem OpenTofu'ya uyumlu.

### Adım 5: Plan + Apply (no-op olmalı)
```bash
tofu init -upgrade
tofu plan
# Çıktı: "No changes" — başarılı

tofu apply
```

### Adım 6: CI/CD update
```yaml
# Eski
- run: terraform plan

# Yeni
- uses: opentofu/setup-opentofu@<VERSION>
- run: tofu plan
```

### Adım 7: Module updates
```hcl
# Eski (Terraform Cloud only)
terraform {
  cloud {
    organization = "<ORG>"
    workspaces { name = "prod" }
  }
}

# OpenTofu uyumlu
terraform {
  backend "s3" {
    bucket = "<TFSTATE_BUCKET>"
    key    = "prod/terraform.tfstate"
    region = "<REGION>"
  }
}
```

> ⚠️ **Terraform Cloud / HCP** OpenTofu'ya uyumlu değil. Spacelift, env0 alternatif.

---

## 🎁 OpenTofu-Specific Features

### State Encryption (1.7+)
```hcl
terraform {
  encryption {
    key_provider "aws_kms" "key" {
      kms_key_id = "<KMS_KEY_ID>"
      region     = "<REGION>"
    }

    method "aes_gcm" "state" {
      keys = key_provider.aws_kms.key
    }

    state {
      method = method.aes_gcm.state
    }
  }
}
```

→ State dosyası AES-GCM ile şifreli (S3 SSE'nin üstüne ek katman).

### OCI Registry (1.8+)
```hcl
module "vpc" {
  source = "oci://<REGISTRY>/modules/vpc:1.0.0"
}
```

→ Helm chart gibi Module'leri OCI registry'de yönet.

### Module + Provider for_each (1.7+)
```hcl
module "regions" {
  for_each = toset(["eu-west-1", "us-east-1", "ap-southeast-1"])
  source   = "./modules/region"
  region   = each.key
}
```

---

## 🛠️ Hibrit / Çift Yönlü Çalışma

Bazı ekipler ikisini paralel kullanıyor:

```bash
# Terraform CLI hâlâ kurulu
terraform plan   # eski
tofu plan         # yeni
```

> ⚠️ State paylaşımı: aynı state dosyasını ikisi de kullanabilir, ama **versiyon sürpriz** çıkabilir. Tutarlı tutmak için tek tool kullan.

---

## 🚧 Migration Riskleri

### 1. Provider divergence
- Provider yazarları HashiCorp'a / OpenTofu'ya farklı versiyon yayınlayabilir
- Çözüm: Provider version pinning + test

### 2. Terraform Cloud lock-in
- HCP Terraform OpenTofu desteklemez
- Çözüm: Spacelift / env0 / Scalr

### 3. Sentinel policies
- HashiCorp özel
- Çözüm: OpenTofu policy ile uyumlu (Rego/OPA, Conftest)

### 4. Module registry
- registry.terraform.io ↔ OpenTofu Registry
- Çoğu module ikisinde de yayınlanmıştır

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| BSL kabul ettim, sonra düşünürüm | License risk birikir | Aktif değerlendir |
| Migration big-bang | State corruption | Aşamalı: dev → staging → prod |
| State backup yok migration'da | Recovery imkansız | S3 versioning + manual snapshot |
| Provider version pin yok | Sürpriz drift | `version = "~> 5.0"` |
| Test ortamı yok | Production'da öğrenirsin | Lab cluster önce |
| HashiCorp CDK / Sentinel kullanımı yoğun | OpenTofu uyumsuz | Migration plan + alternative |
| Terraform Cloud lock | OpenTofu'ya geçilmez | Spacelift / env0 göç |
| Mixed Terraform + OpenTofu state | Versiyon sürprizi | Tek tool, tutarlı |

---

## 📋 Migration Checklist

```
[ ] License risk değerlendirmesi (BSL vs MPL)
[ ] Mevcut Terraform versiyonu (1.5 öncesi mi?)
[ ] State backend (S3 + versioning)
[ ] State backup (manual snapshot)
[ ] OpenTofu install + verify
[ ] Provider compatibility check
[ ] Module compatibility (custom module varsa)
[ ] CI/CD pipeline update (terraform → tofu)
[ ] Lab cluster'da test (plan no-op olmalı)
[ ] Aşamalı migration: dev → staging → prod
[ ] Rollback planı (terraform geri dön)
[ ] Documentation update (runbook, README)
[ ] Tooling: tflint, terragrunt OpenTofu uyumlu
[ ] Ticari destek (gerekirse): Spacelift / env0
[ ] Quarterly: OpenTofu version upgrade
```

---

## 📚 Referanslar

- **OpenTofu** — opentofu.org
- **OpenTofu Migration Guide** — opentofu.org/docs/intro/migration/
- **Linux Foundation Press Release** — Sep 2023
- **HashiCorp BSL Announcement** — hashicorp.com/blog/hashicorp-adopts-business-source-license
- **Spacelift** — spacelift.io
- **env0** — env0.com
- **Scalr** — scalr.com
- [`Terraform-Best-Practices.md`](Terraform-Best-Practices.md)
- [`Pulumi-vs-Terraform.md`](Pulumi-vs-Terraform.md)
- [`Crossplane-Intro.md`](Crossplane-Intro.md)
- [`Terraform-Module-Layout.md`](Terraform-Module-Layout.md)

---

> *"BSL license HashiCorp'un kararı, ama topluluğun **forku**. 2026'da
> 'OpenTofu mu Terraform mu' sorusu, 'GitLab mı GitHub mı' sorusu
> kadar pragmatik. Yeni proje → OpenTofu, güçlü argüman olmadan."*
