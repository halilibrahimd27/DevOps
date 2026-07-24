---
description: "Org-wide CI/CD standardization with GitHub Actions reusable workflows and composite actions: abstraction practices at the step, job and workflow levels."
tags:
  - CI/CD
  - Git
  - Template
  - Platform Engineering
---
# Reusable Workflows — Org-Wide Template

> *"50 repos, 50 different CI workflow YAMLs. Fix a bug in 1 place → 50 repos
> manually updated. **Reusable workflow** = 1 template repo, 50 repos
> import → fix in 1 place."*

This guide covers the practices of org-wide CI/CD standardization with
GitHub Actions reusable workflows + composite actions.

---

## 🎯 3 Levels of Abstraction

| Level | Tool | Niche |
|---|---|---|
| **Step level** | Composite action | Micro-helper like "Setup project" |
| **Job level** | Reusable workflow | Standardize a single job (build + test) |
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

### Caller (each repo)
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

> 🔑 **`@<SHA>` pin** — supply chain risk. Auto-update with Renovate.

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

### Structure
```
.github/                           # special repo: <ORG>/.github
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
├── workflow-templates/            # appears in the template UI
│   ├── ci-node.yml
│   ├── ci-go.yml
│   └── properties/
│       ├── ci-node.properties.json
│       └── ci-go.properties.json
└── README.md
```

### Workflow template (appears in the UI when opening a new repo)
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

→ A dev opening a new repo sees this template in the "Set up workflows" UI.

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

→ Reusable workflow updates ship as automatic PR + merge via Renovate.

### Versioning convention
- `main` → unstable, bleeding edge
- `v1`, `v2` → stable major
- `@v1.2.3` semver pin (recommended)
- `@<SHA>` reproducible pin (safest)

### Breaking change workflow
1. New reusable: `_reusable-build-test-v2.yml`
2. Deprecate the old one: README + `@deprecated` comment
3. Migrate callers gradually
4. Delete the old one after 6 months

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Copy the same workflow into every repo | Fix in 50 places | Reusable + 1 place |
| `@main` ref | Mutable, supply chain | SHA pin + Renovate |
| Reusable has no input/output docs | People ask "how do I use it" | README per workflow |
| Broad permissions (`write-all`) | Compromise blast radius | Least privilege per job |
| Unconditional secret pass | Leaks to the caller | Specific instead of `secrets: inherit` |
| Reusable workflow breaks lab/dev | All repos down | Versioning + deprecation |
| Composite vs reusable mixed up | Wrong abstraction | Step → composite, job → reusable |
| No workflow template | New repos hand-written | `.github` repo + template UI |
| Multi-line script inline | No tests | Extract as composite action + test |
| Reusable workflow > 200 lines | Unmanageable | Modular — each stage separate |

---

## 📋 Reusable Workflow Adoption Checklist

```
[ ] `<ORG>/.github` special repo created
[ ] _reusable-build-test.yml (CI standard)
[ ] _reusable-release.yml (image build + sign + scan)
[ ] _reusable-deploy.yml (ArgoCD sync trigger)
[ ] _reusable-security-scan.yml (SAST + SCA + secret)
[ ] Composite action: setup, deploy
[ ] Workflow templates (suggested to new repos in the UI)
[ ] SHA pin + Renovate auto-update
[ ] Per-workflow README (input + output)
[ ] Permissions least privilege per job
[ ] Versioning: v1, v2 (semver) + SHA pin
[ ] Breaking change: 6-month deprecation
[ ] Adoption metric: how many repos use reusable
[ ] Quarterly: workflow effectiveness review
```

---

## 📚 References

- **GitHub Reusable Workflows** — docs.github.com/actions/using-workflows/reusing-workflows
- **GitHub Composite Actions** — docs.github.com/actions/creating-actions/creating-a-composite-action
- **GitHub Workflow Templates** — docs.github.com/actions/using-workflows/creating-starter-workflows-for-your-organization
- [`GitHub-Actions-Recipes.md`](GitHub-Actions-Recipes.md)
- [`Pipeline-Patterns.md`](Pipeline-Patterns.md)
- [`Pipeline-Performance.md`](Pipeline-Performance.md)
- [`Caching-Strategies.md`](Caching-Strategies.md)

---

> *"A reusable workflow isn't a 'fancy GitHub feature' — it's the key to
> **org-wide standardization**. If you're fixing a CI bug across 50 repos,
> you've lost your **engineering leverage**."*
