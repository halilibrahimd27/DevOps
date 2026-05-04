# Reusable Workflows — Org-Wide Template

> *"50 repo, 50 farklı CI workflow YAML. Bug 1 yerde fix → 50 repo
> manuel update. **Reusable workflow** = 1 repo template, 50 repo
> import → fix 1 yerde."*

Bu rehber GitHub Actions reusable workflow + composite action'lar
ile org-wide CI/CD standardizasyonunun pratiklerini anlatır.

---

## 🎯 3 Soyutlama Seviyesi

| Seviye | Tool | Niche |
|---|---|---|
| **Step level** | Composite action | "Setup project" gibi micro-helper |
| **Job level** | Reusable workflow | Tek job standardize (build + test) |
| **Workflow level** | Reusable workflow + matrix | Full pipeline (CI / release) |

---

## 🧱 Composite Action

`.github/actions/setup-node-app/action.yml`:
```yaml
name: 'Setup Node App'
description: 'Checkout + Node + npm ci'

inputs:
  node-version:
    required: false
    default: '22'
  registry-url:
    required: false
    default: 'https://registry.npmjs.org'

runs:
  using: 'composite'
  steps:
    - uses: actions/checkout@<VERSION>

    - uses: actions/setup-node@<VERSION>
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'
        registry-url: ${{ inputs.registry-url }}

    - name: Install deps
      shell: bash
      run: npm ci

    - name: Validate package.json
      shell: bash
      run: jq '.name and .version' package.json
```

### Caller
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: ./.github/actions/setup-node-app
        with:
          node-version: '22'

      - run: npm run build
      - run: npm test
```

---

## 🔁 Reusable Workflow

### Repo: `<ORG>/.github/.github/workflows/_reusable-build-test.yml`
```yaml
on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: '22'
      run-coverage:
        type: boolean
        default: false
      runs-on:
        type: string
        default: ubuntu-latest
    secrets:
      NPM_TOKEN:
        required: false
    outputs:
      build-id:
        value: ${{ jobs.build.outputs.build-id }}

jobs:
  build:
    runs-on: ${{ inputs.runs-on }}
    permissions:
      contents: read
    outputs:
      build-id: ${{ steps.id.outputs.build-id }}
    steps:
      - uses: actions/checkout@<VERSION>

      - uses: actions/setup-node@<VERSION>
        with:
          node-version: ${{ inputs.node-version }}
          cache: 'npm'

      - run: npm ci
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}

      - run: npm test

      - if: ${{ inputs.run-coverage }}
        run: npm run coverage

      - id: id
        run: echo "build-id=$(uuidgen)" >> $GITHUB_OUTPUT
```

### Caller (her repo)
```yaml
# .github/workflows/ci.yml
on: [push, pull_request]

jobs:
  test:
    uses: <ORG>/.github/.github/workflows/_reusable-build-test.yml@<SHA>
    with:
      node-version: '22'
      run-coverage: true
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

> 🔑 **`@<SHA>` pin** — supply chain risk. Renovate ile auto-update.

---

## 🌐 Multi-Stage Reusable Pipeline

### `<ORG>/.github/.github/workflows/_release.yml`
```yaml
on:
  workflow_call:
    inputs:
      registry:
        type: string
        default: ghcr.io
      image-name:
        type: string
        required: true
    secrets:
      GH_TOKEN:
        required: true

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write
    outputs:
      digest: ${{ steps.build.outputs.digest }}
    steps:
      - uses: actions/checkout@<VERSION>
      - uses: docker/setup-buildx-action@<VERSION>
      - uses: docker/login-action@<VERSION>
        with:
          registry: ${{ inputs.registry }}
          username: ${{ github.actor }}
          password: ${{ secrets.GH_TOKEN }}
      - uses: docker/build-push-action@<VERSION>
        id: build
        with:
          push: true
          tags: ${{ inputs.registry }}/${{ inputs.image-name }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  sign:
    needs: build
    runs-on: ubuntu-latest
    permissions:
      packages: write
      id-token: write
    steps:
      - uses: sigstore/cosign-installer@<VERSION>
      - run: |
          cosign sign --yes \
            ${{ inputs.registry }}/${{ inputs.image-name }}@${{ needs.build.outputs.digest }}

  scan:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: aquasecurity/trivy-action@<VERSION>
        with:
          image-ref: ${{ inputs.registry }}/${{ inputs.image-name }}@${{ needs.build.outputs.digest }}
          severity: CRITICAL,HIGH
          exit-code: 1
          ignore-unfixed: true
```

### Caller
```yaml
on:
  push:
    tags: ['v*']

jobs:
  release:
    uses: <ORG>/.github/.github/workflows/_release.yml@<SHA>
    with:
      image-name: ${{ github.repository }}
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 🏛️ Org-Wide Discovery (.github repo)

### Yapı
```
.github/                           # özel repo: <ORG>/.github
├── .github/
│   └── workflows/
│       ├── _reusable-build-test.yml
│       ├── _reusable-release.yml
│       ├── _reusable-deploy.yml
│       └── _reusable-security-scan.yml
├── actions/
│   ├── setup-node-app/
│   │   └── action.yml
│   ├── setup-go-app/
│   │   └── action.yml
│   └── deploy-to-k8s/
│       └── action.yml
├── workflow-templates/            # template UI'da görünür
│   ├── ci-node.yml
│   ├── ci-go.yml
│   └── properties/
│       ├── ci-node.properties.json
│       └── ci-go.properties.json
└── README.md
```

### Workflow template (yeni repo açarken UI'da görünür)
`.github/workflow-templates/ci-node.yml`:
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    uses: <ORG>/.github/.github/workflows/_reusable-build-test.yml@main
    with:
      node-version: '22'
```

`.github/workflow-templates/properties/ci-node.properties.json`:
```json
{
  "name": "CI for Node.js",
  "description": "Standard CI for Node.js services",
  "iconName": "node",
  "categories": ["JavaScript", "Node.js"]
}
```

→ Yeni repo açan dev "Set up workflows" UI'da bu template'i görür.

---

## 🛡️ Versioning & Update Strategy

### SHA pin + Renovate
```yaml
# Caller
uses: <ORG>/.github/.github/workflows/_reusable-build-test.yml@a1b2c3d4
```

`.github/renovate.json`:
```json
{
  "extends": ["config:recommended"],
  "packageRules": [
    {
      "matchManagers": ["github-actions"],
      "matchPackagePatterns": ["<ORG>/.github"],
      "automerge": true,
      "automergeType": "pr"
    }
  ]
}
```

→ Reusable workflow update Renovate ile otomatik PR + merge.

### Versioning convention
- `main` → unstable, bleeding edge
- `v1`, `v2` → stable major
- `@v1.2.3` semver pin (önerilen)
- `@<SHA>` reproducible pin (en güvenli)

### Breaking change workflow
1. Yeni reusable: `_reusable-build-test-v2.yml`
2. Eski'yi deprecate: README + `@deprecated` comment
3. Caller'ları yavaşça migrate et
4. 6 ay sonra eski'yi sil

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Her repo aynı workflow kopyala | 50 yer fix | Reusable + 1 yer |
| `@main` ref | Mutable, supply chain | SHA pin + Renovate |
| Reusable'ın input/output dokümanı yok | "Nasıl kullanılır" sorulur | README per workflow |
| Permissions geniş (`write-all`) | Compromise blast radius | Least privilege per job |
| Secret unconditional pass | Caller'a leak | `secrets: inherit` yerine specific |
| Reusable workflow lab/dev'i breaking | Tüm repo down | Versiyonlama + deprecation |
| Composite vs reusable karışık | Yanlış soyutlama | Step → composite, job → reusable |
| Workflow template yok | Yeni repo elden yazar | `.github` repo + template UI |
| Multi-line script inline | Test yok | Composite action olarak çıkar + test |
| Reusable workflow > 200 satır | Yönetilmez | Modüler — her aşama ayrı |

---

## 📋 Reusable Workflow Adoption Checklist

```
[ ] `<ORG>/.github` özel repo açıldı
[ ] _reusable-build-test.yml (CI standard)
[ ] _reusable-release.yml (image build + sign + scan)
[ ] _reusable-deploy.yml (ArgoCD sync trigger)
[ ] _reusable-security-scan.yml (SAST + SCA + secret)
[ ] Composite action: setup, deploy
[ ] Workflow templates (UI'da yeni repo'ya öneriliyor)
[ ] SHA pin + Renovate auto-update
[ ] Per-workflow README (input + output)
[ ] Permissions least privilege per job
[ ] Versioning: v1, v2 (semver) + SHA pin
[ ] Breaking change: deprecation 6 ay
[ ] Adoption metric: kaç repo reusable kullanıyor
[ ] Quarterly: workflow effectiveness review
```

---

## 📚 Referanslar

- **GitHub Reusable Workflows** — docs.github.com/actions/using-workflows/reusing-workflows
- **GitHub Composite Actions** — docs.github.com/actions/creating-actions/creating-a-composite-action
- **GitHub Workflow Templates** — docs.github.com/actions/using-workflows/creating-starter-workflows-for-your-organization
- [`GitHub-Actions-Recipes.md`](GitHub-Actions-Recipes.md)
- [`Pipeline-Patterns.md`](Pipeline-Patterns.md)
- [`Pipeline-Performance.md`](Pipeline-Performance.md)
- [`Caching-Strategies.md`](Caching-Strategies.md)

---

> *"Reusable workflow 'fancy GitHub feature' değil — **org-wide
> standardizasyonun** anahtarı. 50 repo'da CI bug fix yapıyorsan,
> **mühendislik leverage**'ı kaybetmişsin."*
