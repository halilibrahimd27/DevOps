---
description: "Reusable GitHub Actions workflow şablonları: cosign imzalı + SBOM'lu docker build/push, OIDC'li terraform plan ve release-please otomasyonu."
tags:
  - Template
  - CI/CD
  - GitHub Actions
  - Security
---
# GitHub Actions — Reusable Workflow Şablonları

> `workflow_call` ile çağrılan yeniden kullanılabilir workflow'lar. Caller
> tarafında `uses:` ile bağla, `with:` ile parametrele. Placeholder'lar
> `<UPPER_CASE>` ile. Bu sayfa komşu dosyaların gömülü halidir; kaynak dosyalar aynı klasörde.

## Dosyalar

| Dosya | Ne yapar | Öne çıkan |
|---|---|---|
| [`docker-build-push.yml`](docker-build-push.yml) | İmaj build + push | cosign keyless imza, SBOM attestation, Trivy scan |
| [`terraform-plan.yml`](terraform-plan.yml) | PR'da `terraform plan` | AWS OIDC, PR comment, `trivy config` misconfig scan |
| [`release-please.yml`](release-please.yml) | Otomatik release | Conventional Commits → changelog + tag |

### 1️⃣ `docker-build-push.yml` — imzalı, SBOM'lu build

Supply-chain'i CI'ın parçası yapar: build → scan → imzala → SBOM ekle. Tarama
adımı **mutable ref değil**, sürüm/SHA'ya pinli olmalı (aşağıda `<VERSION>`).

```yaml
# Reusable workflow — Docker imaj build & push (cosign imzalı, SBOM'lu, scan'li)
# Kullanım (caller workflow'da):
#
#   jobs:
#     build:
#       uses: <ORG>/<REPO>/.github/workflows/docker-build-push.yml@main
#       with:
#         image-name: my-app
#         registry: ghcr.io
#         dockerfile: Dockerfile
#       secrets: inherit
#       permissions:
#         contents: read
#         id-token: write       # cosign keyless OIDC için
#         packages: write       # ghcr.io push için

name: Docker Build & Push

on:
  workflow_call:
    inputs:
      image-name:
        description: "Image name (without registry prefix)"
        required: true
        type: string
      registry:
        description: "Container registry hostname"
        required: false
        type: string
        default: ghcr.io
      dockerfile:
        description: "Path to Dockerfile"
        required: false
        type: string
        default: Dockerfile
      context:
        description: "Build context"
        required: false
        type: string
        default: .
      platforms:
        description: "Target platforms"
        required: false
        type: string
        default: linux/amd64,linux/arm64
      push:
        description: "Push image to registry"
        required: false
        type: boolean
        default: true
    outputs:
      image-digest:
        description: "Pushed image digest"
        value: ${{ jobs.build.outputs.digest }}
      image-tag:
        description: "Pushed image tag"
        value: ${{ jobs.build.outputs.tag }}

permissions:
  contents: read
  id-token: write
  packages: write

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.build.outputs.digest }}
      tag: ${{ steps.meta.outputs.version }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to registry
        if: ${{ inputs.push }}
        uses: docker/login-action@v3
        with:
          registry: ${{ inputs.registry }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ inputs.registry }}/${{ github.repository_owner }}/${{ inputs.image-name }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,format=long,prefix=sha-
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push
        id: build
        uses: docker/build-push-action@v5
        with:
          context: ${{ inputs.context }}
          file: ${{ inputs.dockerfile }}
          platforms: ${{ inputs.platforms }}
          push: ${{ inputs.push }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          provenance: true
          sbom: true

      - name: Trivy vulnerability scan
        if: ${{ inputs.push }}
        # Mutable ref (@master) supply-chain riski — sürüme, ideal olarak commit SHA'sına pinle.
        uses: aquasecurity/trivy-action@<VERSION>  # ör. @<SHA>  # v0.x.x
        with:
          image-ref: ${{ inputs.registry }}/${{ github.repository_owner }}/${{ inputs.image-name }}@${{ steps.build.outputs.digest }}
          format: sarif
          output: trivy-results.sarif
          severity: CRITICAL,HIGH
          exit-code: 1
          ignore-unfixed: true

      - name: Upload Trivy SARIF
        if: ${{ inputs.push && always() }}
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-results.sarif

      - name: Install cosign
        if: ${{ inputs.push }}
        uses: sigstore/cosign-installer@v3

      - name: Sign image (keyless OIDC)
        if: ${{ inputs.push }}
        env:
          IMAGE: ${{ inputs.registry }}/${{ github.repository_owner }}/${{ inputs.image-name }}@${{ steps.build.outputs.digest }}
        run: |
          cosign sign --yes "${IMAGE}"

      - name: Generate SBOM
        if: ${{ inputs.push }}
        uses: anchore/sbom-action@v0
        with:
          image: ${{ inputs.registry }}/${{ github.repository_owner }}/${{ inputs.image-name }}@${{ steps.build.outputs.digest }}
          format: cyclonedx-json
          output-file: sbom.cyclonedx.json

      - name: Attach SBOM as attestation
        if: ${{ inputs.push }}
        env:
          IMAGE: ${{ inputs.registry }}/${{ github.repository_owner }}/${{ inputs.image-name }}@${{ steps.build.outputs.digest }}
        run: |
          cosign attest --yes \
            --predicate sbom.cyclonedx.json \
            --type cyclonedx \
            "${IMAGE}"
```

### 2️⃣ `terraform-plan.yml` — OIDC + PR comment

Uzun ömürlü AWS key yerine OIDC ile role assume eder, `plan` çıktısını PR'a comment'ler.

> ℹ️ **tfsec → Trivy:** tfsec 2023'te Trivy'ye konsolide edildi (yeni check gelmiyor).
> Bu şablon IaC misconfig taraması için `trivy config` kullanır.

```yaml
# Reusable workflow — Terraform plan (PR'da otomatik, comment'lar)
# Kullanım:
#   jobs:
#     plan:
#       uses: <ORG>/<REPO>/.github/workflows/terraform-plan.yml@main
#       with:
#         working-directory: terraform/environments/prod
#         tf-version: "1.9.0"
#       secrets: inherit
#       permissions:
#         contents: read
#         id-token: write     # AWS OIDC için
#         pull-requests: write
#
# Önkoşullar:
#   - AWS_ROLE_ARN secret'ı (OIDC ile assume edilir)
#   - Backend S3 bucket'ı + DynamoDB lock tablosu hazır

name: Terraform Plan

on:
  workflow_call:
    inputs:
      working-directory:
        required: true
        type: string
      tf-version:
        required: false
        type: string
        default: "1.9.0"
      aws-region:
        required: false
        type: string
        default: us-east-1

permissions:
  contents: read
  id-token: write
  pull-requests: write

jobs:
  plan:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ inputs.working-directory }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ inputs.aws-region }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ inputs.tf-version }}

      - name: terraform fmt
        id: fmt
        run: terraform fmt -check -recursive
        continue-on-error: true

      - name: terraform init
        id: init
        run: terraform init -input=false

      - name: terraform validate
        id: validate
        run: terraform validate -no-color

      - name: tflint
        uses: terraform-linters/setup-tflint@v4
        with:
          tflint_version: v0.50.0
      - run: |
          tflint --init
          tflint --format compact

      # tfsec 2023'te Trivy'ye konsolide edildi (yeni check gelmiyor) → trivy config.
      # Mutable ref yerine sürüme/SHA'ya pinle.
      - name: Trivy IaC config scan
        uses: aquasecurity/trivy-action@<VERSION>  # ör. @<SHA>  # v0.x.x
        with:
          scan-type: config
          scan-ref: ${{ inputs.working-directory }}
          severity: CRITICAL,HIGH
          exit-code: 1

      - name: terraform plan
        id: plan
        run: |
          terraform plan -no-color -input=false -out=tfplan 2>&1 | tee plan-output.txt
          echo "exitcode=${PIPESTATUS[0]}" >> $GITHUB_OUTPUT
        continue-on-error: true

      - name: Comment plan on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        env:
          PLAN: ${{ steps.plan.outputs.stdout }}
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const fs = require('fs');
            const plan = fs.readFileSync('${{ inputs.working-directory }}/plan-output.txt', 'utf8');
            const truncated = plan.length > 65000 ? plan.substring(0, 65000) + '\n... (truncated)' : plan;
            const body = `### 📋 Terraform Plan — \`${{ inputs.working-directory }}\`

            * **fmt:**      \`${{ steps.fmt.outcome }}\`
            * **init:**     \`${{ steps.init.outcome }}\`
            * **validate:** \`${{ steps.validate.outcome }}\`
            * **plan:**     \`${{ steps.plan.outcome }}\`

            <details><summary>📜 Plan output</summary>

            \`\`\`hcl
            ${truncated}
            \`\`\`

            </details>

            *Triggered by @${{ github.actor }} on commit ${{ github.sha }}*
            `;

            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body
            });

      - name: Plan exit code
        if: steps.plan.outputs.exitcode != '0' && steps.plan.outputs.exitcode != '2'
        run: exit 1
```

### 3️⃣ `release-please.yml` — Conventional Commits → release

`feat:`/`fix:` commit'lerinden otomatik changelog, tag ve GitHub Release üretir.

```yaml
# release-please otomasyonu: Conventional Commits → otomatik changelog + GitHub Release + tag
# Kullanım:
#   .github/workflows/release.yml içine kopyala
#   release-please-config.json dosyası repo root'unda olmalı (örnek aşağıda)

name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write
  issues: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
    steps:
      - name: Run release-please
        id: release
        uses: googleapis/release-please-action@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json

  publish:
    needs: release-please
    if: needs.release-please.outputs.release_created == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ needs.release-please.outputs.tag_name }}

      # Buraya release-spesifik publish adımları:
      # - npm publish
      # - docker build & push (release tag ile)
      # - terraform module registry push
      # - vs.

      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "🚀 Released ${{ needs.release-please.outputs.tag_name }}: ${{ github.server_url }}/${{ github.repository }}/releases/tag/${{ needs.release-please.outputs.tag_name }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_RELEASE_WEBHOOK }}
          SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK

# ────────────────────────────────────────────────────────────────────────────
# release-please-config.json (repo root'unda):
#
# {
#   "release-type": "node",                    // veya: simple, python, go, rust, ...
#   "packages": {
#     ".": {
#       "package-name": "<APP_NAME>",
#       "changelog-sections": [
#         { "type": "feat",     "section": "🚀 Features" },
#         { "type": "fix",      "section": "🐛 Bug Fixes" },
#         { "type": "perf",     "section": "⚡ Performance" },
#         { "type": "refactor", "section": "♻️ Refactoring" },
#         { "type": "docs",     "section": "📚 Documentation" },
#         { "type": "chore",    "section": "🔧 Chores", "hidden": true },
#         { "type": "ci",       "section": "🤖 CI",     "hidden": true }
#       ]
#     }
#   }
# }
#
# .release-please-manifest.json (repo root'unda):
#
# { ".": "0.1.0" }
```

---

## 🚫 Anti-Pattern

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Action'ı `@master`/`@main` ile pin | Mutable ref; upstream compromise seni de vurur | Sürüm tag, ideal commit SHA (`@<SHA>`) |
| CI'da uzun ömürlü cloud key | Secret sızarsa kalıcı erişim | OIDC ile kısa ömürlü role assume |
| İmaj imzasız/SBOM'suz push | Ne çalıştığını kanıtlayamazsın | cosign imza + SBOM attestation |
| `terraform apply`'ı PR'da otomatik | Review'suz prod değişikliği | Sadece `plan` PR'da; `apply` merge sonrası gate'li |

> *"Reusable workflow bir sözleşmedir: girdi/çıktısı net, her repo aynı güvenlik adımlarını bedavaya alır."*
