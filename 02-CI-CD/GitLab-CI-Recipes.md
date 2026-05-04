# GitLab CI Recipes — DAG, Dynamic Child, Multi-Project

> *"GitLab CI 'GitHub Actions klonu' değil — **DAG-native** + **monorepo
> friendly**. Doğru kullanılırsa 50 servisli monorepo'yu **dakikalarda**
> işler."*

Bu rehber GitLab CI/CD'nin pratik tariflerini — DAG pipeline, dynamic
child, multi-project trigger, OIDC AWS auth — anlatır.

---

## 📐 GitLab CI Anatomi

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - scan
  - deploy

variables:
  DOCKER_BUILDKIT: 1

default:
  image: <REGISTRY>/<CI_BASE>:latest
  before_script:
    - echo "starting"

# Job tanımı
build-app:
  stage: build
  script:
    - make build
  artifacts:
    paths: [dist/]
    expire_in: 1 week
```

---

## 🌐 Recipe 1: DAG Pipeline (needs)

> **DAG**: Stage'leri sıralı değil, **dependency graph** ile çalıştır.

```yaml
build-backend:
  stage: build
  script: make backend

build-frontend:
  stage: build
  script: make frontend

test-backend:
  stage: test
  needs: [build-backend]    # frontend bekleme
  script: make test-backend

test-frontend:
  stage: test
  needs: [build-frontend]
  script: make test-frontend

scan-backend:
  stage: scan
  needs: [build-backend]
  script: trivy image <BACKEND>

deploy:
  stage: deploy
  needs: [test-backend, test-frontend, scan-backend]
  script: make deploy
```

→ Backend'i bekleyenler frontend'in bitmesini beklemiyor; **paralel**.

---

## 🧬 Recipe 2: Dynamic Child Pipeline

> **Senaryo**: Monorepo'da 50 servis. Sadece değişen servisin pipeline'ını çalıştır.

```yaml
# .gitlab-ci.yml (parent)
generate-pipeline:
  stage: build
  image: alpine:latest
  script:
    - apk add --no-cache git python3
    # Detect changed services
    - python3 scripts/generate-child.py > generated.yml
  artifacts:
    paths: [generated.yml]

trigger-children:
  stage: test
  needs: [generate-pipeline]
  trigger:
    include:
      - artifact: generated.yml
        job: generate-pipeline
    strategy: depend
```

```python
# scripts/generate-child.py
import os, yaml
from subprocess import check_output

# Son commit'te değişen path'ler
changed = check_output(["git", "diff", "--name-only", "HEAD~1"]).decode().splitlines()

services = set()
for f in changed:
    if f.startswith("services/"):
        services.add(f.split("/")[1])

config = {"stages": ["test"]}
for svc in services:
    config[f"test-{svc}"] = {
        "stage": "test",
        "script": f"cd services/{svc} && make test"
    }

print(yaml.dump(config))
```

> 🔑 **50 servis × 5 dk = 250 dk**. Dynamic child + selective testing → 5-10 dk.

---

## 🔁 Recipe 3: Multi-Project Pipeline Trigger

```yaml
# Repo A (orchestrator)
deploy-downstream:
  stage: deploy
  trigger:
    project: <ORG>/<DOWNSTREAM_REPO>
    branch: main
    strategy: depend     # downstream sonucunu bekle
  variables:
    UPSTREAM_VERSION: $CI_COMMIT_TAG
```

```yaml
# Repo B (downstream)
deploy:
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline"
  script:
    - echo "Triggered by upstream version $UPSTREAM_VERSION"
    - ./deploy.sh
```

---

## 🔐 Recipe 4: OIDC ile AWS

```yaml
deploy:
  id_tokens:
    AWS_TOKEN:
      aud: https://gitlab.example.com
  variables:
    AWS_ROLE_ARN: arn:aws:iam::<ACCOUNT>:role/gitlab-deploy
  script:
    - >
      export AWS_CREDS=$(aws sts assume-role-with-web-identity
        --role-arn $AWS_ROLE_ARN
        --role-session-name gitlab-${CI_JOB_ID}
        --web-identity-token $AWS_TOKEN
        --duration-seconds 3600)
    - export AWS_ACCESS_KEY_ID=$(echo $AWS_CREDS | jq -r .Credentials.AccessKeyId)
    - export AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDS | jq -r .Credentials.SecretAccessKey)
    - export AWS_SESSION_TOKEN=$(echo $AWS_CREDS | jq -r .Credentials.SessionToken)
    - aws s3 ls
```

---

## 🚀 Recipe 5: Docker Build + Sign + Push (Kaniko)

```yaml
build:
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  script:
    - >
      /kaniko/executor
      --context $CI_PROJECT_DIR
      --dockerfile Dockerfile
      --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      --cache=true
      --cache-repo=$CI_REGISTRY_IMAGE/cache

sign:
  image: gcr.io/projectsigstore/cosign:latest
  needs: [build]
  variables:
    COSIGN_EXPERIMENTAL: "true"
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  script:
    - cosign sign --yes $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

> ⚠️ **Docker-in-Docker (DinD)** kullanma — security risk. **Kaniko** veya **Buildah** tercih.

---

## 💾 Recipe 6: Cache Strategies

```yaml
default:
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/
      - .npm/

# Veya per-branch
cache:
  key: $CI_COMMIT_REF_SLUG
  paths: [.cache/]

# Dotenv artifact (env var pass between jobs)
build:
  script:
    - echo "BUILD_VERSION=$(git rev-parse --short HEAD)" > build.env
  artifacts:
    reports:
      dotenv: build.env

deploy:
  needs: [build]
  script:
    - echo "Deploying $BUILD_VERSION"   # auto-loaded
```

---

## 🌍 Recipe 7: Environment + Manual Gate

```yaml
deploy-staging:
  stage: deploy
  environment:
    name: staging
    url: https://staging.<DOMAIN>
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  script: ./deploy-staging.sh

deploy-prod:
  stage: deploy
  environment:
    name: production
    url: https://prod.<DOMAIN>
    deployment_tier: production
  rules:
    - if: $CI_COMMIT_TAG
      when: manual    # manuel onay
      allow_failure: false
  needs: [deploy-staging]
  script: ./deploy-prod.sh
```

UI: Operate → Environments → Production → Required approvals.

---

## 🔄 Recipe 8: Rules + Conditional Workflows

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_COMMIT_TAG

test:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - "src/**"
    - if: $CI_COMMIT_BRANCH == "main"
  script: make test
```

---

## 🧪 Recipe 9: Test Reports

```yaml
test:
  script:
    - npm test -- --reporter junit --output-file junit.xml
  artifacts:
    when: always
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
```

→ MR'da test sonucu, coverage diff otomatik gösterilir.

---

## 🛡️ Recipe 10: SAST + DAST + Container Scan (Built-in)

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/DAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml

variables:
  DAST_WEBSITE: https://staging.<DOMAIN>
```

→ Built-in scanner'lar, MR widget'ında bulgular görünür.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Stage'leri sıralı (`needs` yok) | Paralelleşmiyor | DAG ile `needs` |
| 50 servis tek pipeline | Yavaş | Dynamic child |
| `image: docker:latest` (DinD) | Privileged, security risk | Kaniko / Buildah |
| Long-lived AWS key | Compromise | OIDC |
| Manuel deploy gate yok prod'da | Direct deploy bug | Manual + protected env |
| Cache key static | İnvalidasyon yok | `files: hash` |
| Workflow rules yok | Her event pipeline tetikler | `workflow.rules` |
| Built-in security scan kapalı | CVE birikiyor | Include security templates |
| Artifact uzun retention | Storage maliyet | `expire_in: 1 week` |
| Self-hosted runner persistent | Side-channel | Ephemeral runner |
| Variable scope yanlış | Secret leak | Protected variable + masked |

---

## 📋 GitLab CI Production Checklist

```
[ ] DAG ile `needs` (paralel pipeline)
[ ] Cache: per-branch + lockfile hash
[ ] OIDC (id_tokens) cloud auth
[ ] Kaniko / Buildah (DinD yerine)
[ ] cosign sign + Sigstore OIDC
[ ] Dynamic child (monorepo'da)
[ ] Workflow rules (gereksiz pipeline yok)
[ ] Path filter (`changes:`)
[ ] Environment protection: prod manual
[ ] Built-in security templates
[ ] Test reports (junit, coverage)
[ ] Slack notification on failure
[ ] Artifact expire_in
[ ] Protected variables (prod secrets)
[ ] Self-hosted runner ephemeral
```

---

## 📚 Referanslar

- **GitLab CI Reference** — docs.gitlab.com/ee/ci/yaml
- **GitLab Auto DevOps** — docs.gitlab.com/ee/topics/autodevops
- **Kaniko** — github.com/GoogleContainerTools/kaniko
- [`Pipeline-Patterns.md`](Pipeline-Patterns.md)
- [`Pipeline-Performance.md`](Pipeline-Performance.md)
- [`GitHub-Actions-Recipes.md`](GitHub-Actions-Recipes.md)

---

> *"GitLab CI'ı 'YAML jungle' yapan **stage sıralı** kafayla
> kullanmaktır. **DAG + dynamic child** ile aynı YAML, **3x daha
> hızlı** monorepo işler."*
