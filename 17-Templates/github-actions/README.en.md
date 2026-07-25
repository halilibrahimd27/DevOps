---
description: "Reusable GitHub Actions workflow templates: docker build/push with cosign signing + SBOM, terraform plan with OIDC, and release-please automation."
tags:
  - Template
  - CI/CD
  - GitHub Actions
  - Security
---
# GitHub Actions — Reusable Workflow Templates

> Reusable workflows invoked via `workflow_call`. Bind them on the caller
> side with `uses:`, parametrize with `with:`. Placeholders use
> `<UPPER_CASE>`. This page embeds the neighboring files; source files are in the same folder.

## Files

| File | What it does | Highlights |
|---|---|---|
| [`docker-build-push.yml`](docker-build-push.yml) | Image build + push | cosign keyless signing, SBOM attestation, Trivy scan |
| [`terraform-plan.yml`](terraform-plan.yml) | `terraform plan` on PR | AWS OIDC, PR comment, `trivy config` misconfig scan |
| [`release-please.yml`](release-please.yml) | Automated release | Conventional Commits → changelog + tag |

### 1️⃣ `docker-build-push.yml` — signed, SBOM-attested build

Makes supply-chain part of CI: build → scan → sign → attach SBOM. The scan
step must be pinned to a version/SHA, **not a mutable ref** (below: `<VERSION>`).

```yaml
# Reusable workflow — Docker image build & push (cosign signed, SBOM-attested, scanned)
# Usage (in caller workflow):
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
#         id-token: write       # for cosign keyless OIDC
#         packages: write       # for ghcr.io push

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
        # Mutable ref (@master) is a supply-chain risk — pin to a version, ideally a commit SHA.
        uses: aquasecurity/trivy-action@<VERSION>  # e.g. @<SHA>  # v0.x.x
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

Assumes a role via OIDC instead of long-lived AWS keys, and comments the `plan` output on the PR.

> ℹ️ **tfsec → Trivy:** tfsec was consolidated into Trivy in 2023 (no new checks are coming).
> This template uses `trivy config` for IaC misconfig scanning.

```yaml
# Reusable workflow — Terraform plan (automatic on PR, comments)
# Usage:
#   jobs:
#     plan:
#       uses: <ORG>/<REPO>/.github/workflows/terraform-plan.yml@main
#       with:
#         working-directory: terraform/environments/prod
#         tf-version: "1.9.0"
#       secrets: inherit
#       permissions:
#         contents: read
#         id-token: write     # for AWS OIDC
#         pull-requests: write
#
# Prerequisites:
#   - AWS_ROLE_ARN secret (assumed via OIDC)
#   - Backend S3 bucket + DynamoDB lock table ready

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

      # tfsec was consolidated into Trivy in 2023 (no new checks are coming) → trivy config.
      # Pin to a version/SHA instead of a mutable ref.
      - name: Trivy IaC config scan
        uses: aquasecurity/trivy-action@<VERSION>  # e.g. @<SHA>  # v0.x.x
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

Generates an automated changelog, tag, and GitHub Release from `feat:`/`fix:` commits.

```yaml
# release-please automation: Conventional Commits → automatic changelog + GitHub Release + tag
# Usage:
#   Copy into .github/workflows/release.yml
#   release-please-config.json must be at the repo root (example below)

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

      # Release-specific publish steps go here:
      # - npm publish
      # - docker build & push (with the release tag)
      # - terraform module registry push
      # - etc.

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
# release-please-config.json (at the repo root):
#
# {
#   "release-type": "node",                    // or: simple, python, go, rust, ...
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
# .release-please-manifest.json (at the repo root):
#
# { ".": "0.1.0" }
```

---

## 🚫 Anti-Pattern

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Pin an action with `@master`/`@main` | Mutable ref; an upstream compromise hits you too | Version tag, ideally a commit SHA (`@<SHA>`) |
| Long-lived cloud key in CI | If the secret leaks, permanent access | Short-lived role assume via OIDC |
| Push an unsigned/SBOM-less image | You can't prove what's running | cosign signature + SBOM attestation |
| Auto `terraform apply` on PR | Prod change without review | Only `plan` on PR; `apply` gated after merge |

> *"A reusable workflow is a contract: its inputs/outputs are clear, and every repo gets the same security steps for free."*
