---
description: "Copy-paste .gitignore examples per stack (Terraform, Node, Python, Java) + a secret-leak prevention anti-pattern table."
tags:
  - Template
  - Git
  - Security
  - Secrets
---
# .gitignore Examples — Per Stack

> Copy-paste `.gitignore` blocks. Most leaks come from an un-ignored
> `.env` / state / credential file — close these first.

## 🔴 Every repo (common)

```gitignore
# OS
.DS_Store
Thumbs.db

# Editor
.idea/
.vscode/
*.swp

# Secrets — NEVER commit
.env
.env.*
!.env.example
*.pem
*.key
credentials.json
```

## Terraform

```gitignore
# State + plan (secret + large)
*.tfstate
*.tfstate.*
*.tfplan
crash.log

# Provider/module downloads
.terraform/
.terraform.lock.hcl   # depending on team decision: committing the lock is usually CORRECT

# Variable files (contain secret values)
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

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Forgetting to ignore `.env` | Credentials enter repo history; they aren't cleaned up without rotation | Add `.env` ignore + `.env.example` before the first commit |
| Committing the state file | `*.tfstate` contains plaintext secrets | Remote backend (S3/GCS) + `*.tfstate` ignore |
| Only deleting a leaked secret | It stays in Git history | Clean it from history with `git filter-repo` + rotate the secret |
| Committing `node_modules/` | Repo bloats, platform-specific binaries | Ignore `node_modules/`, commit `package-lock.json` |

> *"`.gitignore` is a security control: the cheapest secret-leak prevention comes before the commit."*
