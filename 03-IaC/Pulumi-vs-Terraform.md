# Pulumi vs Terraform — General-Purpose Lang vs HCL

> *"Terraform: HCL, deklaratif, IaC için optimize. Pulumi: Python/Go/TS,
> mevcut programlama dili, **for-loop + library** kullanılabilir.
> Hangisi? **Ekibinin alışkanlığı** sorusu."*

Bu rehber Pulumi'nin Terraform/OpenTofu ile karşılaştırmasını,
hangi durumda hangisinin tercih edildiğini, ve geçiş stratejisini
anlatır.

---

## ⚖️ Tek Cümlede

| Tool | Felsefe |
|---|---|
| **Terraform/OpenTofu** | "HCL, deklaratif, IaC-purpose" |
| **Pulumi** | "Mevcut dil (Python/Go/TS/.NET) ile altyapı yaz" |

---

## 📊 Detaylı Karşılaştırma

| Boyut | **Terraform/OpenTofu** | **Pulumi** |
|---|---|---|
| **Dil** | HCL (DSL) | Python, TypeScript, Go, .NET, Java |
| **Paradigma** | Deklaratif | İmperative + deklaratif (mix) |
| **Loop / conditional** | `for_each`, `count`, `dynamic` | Native `for`, `if`, function |
| **Library** | Module | Pip / npm / Go modules |
| **Type safety** | HCL tip kontrolü orta | TypeScript / Go strong typing |
| **Test** | terratest, checkov | Native unit test (pytest, jest) |
| **State** | tfstate | Pulumi state (cloud / self-host) |
| **State encryption** | Backend bağımlı (S3 SSE) | Built-in (passphrase / KMS) |
| **Secret in state** | Plain (S3 SSE protect eder) | Encrypted (built-in) |
| **Plan + apply** | ✅ | ✅ |
| **Drift detection** | terraform plan | pulumi refresh |
| **Multi-cloud** | ✅ | ✅ |
| **Provider count** | ~3000+ | ~150+ (genişliyor) |
| **Topluluk** | Çok büyük | Büyüyen |
| **Maturity** | 10+ yıl | 7+ yıl |
| **Free tier** | OpenTofu free, Terraform BSL | Pulumi Cloud free 200 resource |
| **Ticari** | HashiCorp / Spacelift | Pulumi Inc |

---

## 🌳 Karar Ağacı

```
START
  │
  ├── Ekibin Python / TypeScript / Go biliyor mu (HCL bilmiyor)?
  │     │
  │     └── EVET → Pulumi (öğrenme zaman tasarrufu)
  │
  ├── Geniş ekosistem provider gerek?
  │     │
  │     └── EVET → Terraform/OpenTofu (3000+ provider)
  │
  ├── Type safety + advanced testing kritik mi?
  │     │
  │     └── EVET → Pulumi (strong-typed)
  │
  ├── Kompleks loop / conditional / abstraction çok?
  │     │
  │     └── EVET → Pulumi (native lang power)
  │
  ├── Multi-cloud + standard pattern?
  │     │
  │     └── Terraform/OpenTofu (köklü)
  │
  └── Default → Terraform/OpenTofu (köklü, geniş topluluk)
```

> 🎯 **2026 net pratik**: Çoğu ekip için **Terraform/OpenTofu**. Ekibin programlama gücüne dayanan custom abstraction istiyorsa **Pulumi**.

---

## 💻 Kod Karşılaştırması

### S3 bucket + IAM policy

#### Terraform/OpenTofu
```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "${var.app_name}-logs"
  tags   = var.tags
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureConnections"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = ["${aws_s3_bucket.logs.arn}/*"]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}
```

#### Pulumi (TypeScript)
```typescript
import * as aws from "@pulumi/aws";
import * as pulumi from "@pulumi/pulumi";

const config = new pulumi.Config();
const appName = config.require("appName");

const logsBucket = new aws.s3.Bucket("logs", {
  bucket: `${appName}-logs`,
  tags: { Environment: "prod" },
});

const policy = new aws.s3.BucketPolicy("logs-policy", {
  bucket: logsBucket.id,
  policy: logsBucket.arn.apply(arn => JSON.stringify({
    Version: "2012-10-17",
    Statement: [{
      Sid: "DenyInsecureConnections",
      Effect: "Deny",
      Principal: "*",
      Action: "s3:*",
      Resource: [`${arn}/*`],
      Condition: {
        Bool: { "aws:SecureTransport": "false" }
      }
    }]
  })),
});
```

### Loop ile çoklu region

#### Terraform
```hcl
locals {
  regions = ["eu-west-1", "us-east-1", "ap-southeast-1"]
}

resource "aws_s3_bucket" "regional" {
  for_each = toset(local.regions)
  provider = aws[each.key]
  bucket   = "${var.app}-${each.key}"
}
```

#### Pulumi (TypeScript)
```typescript
const regions = ["eu-west-1", "us-east-1", "ap-southeast-1"];

const buckets = regions.map(region => {
  const provider = new aws.Provider(region, { region });
  return new aws.s3.Bucket(`${appName}-${region}`, {
    bucket: `${appName}-${region}`,
  }, { provider });
});
```

> 🔑 **Pulumi**: standart programlama. **Terraform**: HCL syntax öğren.

---

## 🧪 Testing Karşılaştırması

### Terraform — terratest
```go
// test/main_test.go
package test

import (
  "testing"
  "github.com/gruntwork-io/terratest/modules/terraform"
)

func TestS3Bucket(t *testing.T) {
  opts := &terraform.Options{
    TerraformDir: "../",
    Vars: map[string]interface{}{
      "app_name": "test-app",
    },
  }
  defer terraform.Destroy(t, opts)
  terraform.InitAndApply(t, opts)
  // assert: bucket exists
}
```

### Pulumi — native test (Mocha)
```typescript
import * as pulumi from "@pulumi/pulumi";
import { describe, it } from "mocha";

pulumi.runtime.setMocks({
  newResource: (args) => ({
    id: `${args.name}-id`,
    state: args.inputs,
  }),
  call: (args) => args.inputs,
});

describe("Infrastructure", () => {
  let infra: typeof import("./index");

  before(async () => {
    infra = await import("./index");
  });

  it("S3 bucket adı doğru", (done) => {
    pulumi.all([infra.logsBucket.bucket]).apply(([name]) => {
      if (name !== "test-app-logs") {
        done(new Error(`Beklenen test-app-logs, gelen ${name}`));
      } else {
        done();
      }
    });
  });
});
```

→ Pulumi **mock-based unit test** native; Terraform için terratest gibi extra tool.

---

## 🔄 Migration: Terraform → Pulumi (veya tersi)

### Pulumi `tf2pulumi` tool
```bash
pip install pulumi-tf2pulumi
tf2pulumi --target-language typescript -o pulumi-project/
```

→ Mevcut HCL → Pulumi TS otomatik çevrilir. Manuel review + test gerekli.

### Aşamalı: paralel migration
1. Yeni resource'lar Pulumi'de
2. Mevcut Terraform'da kalır
3. Yavaş yavaş import (her resource için)
4. 6-12 ayda full migration

> ⚠️ **State migration karmaşık**. Pratik: yeni greenfield'da Pulumi, mevcut Terraform'da kal.

---

## 🚧 Trade-off'lar

### Pulumi Pro
- ✅ Mevcut programlama dili
- ✅ Strong typing
- ✅ Native testing
- ✅ Library ecosystem (pip, npm)
- ✅ Loop / conditional native

### Pulumi Con
- ❌ Daha az provider (~150 vs 3000)
- ❌ Daha yeni topluluk
- ❌ "Programmer's IaC" → DevOps non-dev için zor
- ❌ State management Pulumi Cloud (veya self-host setup)
- ❌ Imperative mix → unintended side-effect riski

### Terraform Pro
- ✅ Köklü, devasa ekosistem
- ✅ Deklaratif (mental model basit)
- ✅ Provider çeşitliliği
- ✅ HashiCorp ekosistem (Vault, Consul, Nomad)

### Terraform Con
- ❌ HCL DSL (yeni dil öğren)
- ❌ Loop / conditional çirkin (`for_each`, `dynamic`)
- ❌ Test framework eksik (terratest external)
- ❌ BSL license (Terraform 1.6+) → OpenTofu fork

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Pulumi'i "her şey için" hipnoz | Pulumi state karmaşık | Use case + ekip yetkinliği |
| Terraform'u "modern değil" diye reddet | Köklü + olgun | Trade-off değerlendir |
| Mixed Terraform + Pulumi aynı resource | State çakışması | Net sınır |
| Pulumi imperative side-effect | Reproducibility yok | Pure functions, side-effect izole |
| HCL `dynamic` aşırı kullanım | Okunmaz | Module + spesifik resource |
| Pulumi Cloud free tier prod | 200 resource limit | Self-host backend (S3) |
| Test yok | "Çalışıyor sanırım" | Native unit test (Pulumi) veya terratest (TF) |
| Provider version pin yok | Drift, surprise | Pin version |
| Pulumi secret state'te plain | Compromise = total | KMS encryption (Pulumi config) |

---

## 📋 IaC Tool Adoption Checklist

```
[ ] Tool seçimi karar belgelenmiş (RFC)
[ ] Ekip yetkinliği (HCL vs Python/TS) değerlendirildi
[ ] State backend: S3 + versioning + encryption
[ ] Secret yönetimi: Pulumi config / Vault / SOPS
[ ] Provider version pin
[ ] Module / library yapı (Pulumi npm package vs TF module)
[ ] Test stratejisi (Pulumi mocha / terratest)
[ ] CI/CD: plan + apply pipeline
[ ] Drift detection (refresh / plan periodic)
[ ] Rollback prosedürü (state kopyaları)
[ ] Migration plan (gerekirse)
[ ] Documentation: yeni mühendis nasıl başlar
```

---

## 📚 Referanslar

- **Terraform** — terraform.io
- **OpenTofu** — opentofu.org
- **Pulumi** — pulumi.com
- **Pulumi Examples** — github.com/pulumi/examples
- **tf2pulumi** — github.com/pulumi/pulumi-converter-terraform
- **Terratest** — terratest.gruntwork.io
- [`Terraform-Best-Practices.md`](Terraform-Best-Practices.md)
- [`OpenTofu-Migration.md`](OpenTofu-Migration.md)
- [`Crossplane-Intro.md`](Crossplane-Intro.md)
- [`Terraform-Module-Layout.md`](Terraform-Module-Layout.md)

---

> *"Pulumi vs Terraform 'doğru cevap' değil, **doğru ekibe doğru
> tool**. HCL'i 2 günde öğren, Python'ı zaten biliyorsan Pulumi
> hız kazandırır; HashiCorp ekosistem bağımlısı isen Terraform/OpenTofu
> kal."*
