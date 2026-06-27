---
description: "Stack başına kopyala-yapıştır .gitignore örnekleri (Terraform, Node, Python, Java) + secret-leak önleme anti-pattern tablosu."
---
# .gitignore Örnekleri — Stack Başına

> Kopyala-yapıştır `.gitignore` blokları. Çoğu sızıntı, ignore edilmeyen
> `.env` / state / credential dosyasından gelir — önce bunları kapat.

## 🔴 Her repoda (ortak)

```gitignore
# OS
.DS_Store
Thumbs.db

# Editor
.idea/
.vscode/
*.swp

# Secrets — ASLA commit'leme
.env
.env.*
!.env.example
*.pem
*.key
credentials.json
```

## Terraform

```gitignore
# State + plan (secret + büyük)
*.tfstate
*.tfstate.*
*.tfplan
crash.log

# Provider/modül indirmeleri
.terraform/
.terraform.lock.hcl   # ekip kararına göre: lock'u commit etmek genelde DOĞRU

# Değişken dosyaları (gizli değer içerir)
*.tfvars
!example.tfvars
```

## Node.js

```gitignore
node_modules/
dist/
build/
coverage/
npm-debug.log*
.pnpm-debug.log*
.env*.local
```

## Python

```gitignore
__pycache__/
*.py[cod]
.venv/
venv/
.pytest_cache/
.mypy_cache/
*.egg-info/
.coverage
```

## Java / Gradle

```gitignore
.gradle/
build/
*.class
*.jar
!gradle/wrapper/gradle-wrapper.jar
.settings/
bin/
```

---

## 🚫 Anti-Pattern

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| `.env`'i ignore etmeyi unutmak | Credential repo geçmişine girer; rotate etmeden temizlenmez | İlk commit'ten önce `.env` ignore + `.env.example` ekle |
| State dosyasını commit'lemek | `*.tfstate` plaintext secret içerir | Remote backend (S3/GCS) + `*.tfstate` ignore |
| Sızan secret'ı sadece silmek | Git geçmişinde kalır | `git filter-repo` ile geçmişten temizle + secret'ı rotate et |
| `node_modules/` commit'lemek | Repo şişer, platform-spesifik binary'ler | `node_modules/` ignore, `package-lock.json` commit |

> *"`.gitignore` güvenlik kontrolüdür: en ucuz secret-leak önlemi commit'ten önce gelir."*
