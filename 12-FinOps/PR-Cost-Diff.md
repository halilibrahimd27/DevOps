---
description: "CI'da PR'in cost impact'ini hesaplama ve PR yorumuna ekleme: Infracost ve Kubecost ile pre-merge maliyet review, sürpriz bill yerine bilincli karar."
tags:
  - FinOps
  - Cost Optimization
  - CI/CD
  - Terraform
  - Cost
---
# PR Cost Diff — "Bu PR ne kadara mal olacak?"

> *"Developer PR açıyor: replica 3 → 10, instance type m5.large → r5.4xlarge.
> Cost impact bilinmiyor → merge → ay sonu bill +$5K. **PR-time cost
> visibility** = preventive."*

Bu rehber CI'da PR'ın cost impact'ini hesaplama ve PR yorumuna ekleme
pratiğini, Kubecost / Infracost tooling'ini anlatır.

---

## 🎯 Niye PR Cost Diff?

### Senaryo (kötü)
```
Dev: "Memory artırıyorum 1Gi → 4Gi" (PR)
Reviewer: "LGTM" (cost bilgisi yok)
Merge → 30 gün sonra:
  AWS bill +$2K, ay sonu sürpriz
  Finance: "Bu artış nereden?"
  Mühendis: "Şu PR'dan..."
```

### Çözüm (iyi)
```
Dev: "Memory artırıyorum 1Gi → 4Gi" (PR)
CI bot: 💰 +$1.5K/ay
Reviewer: "Hmm, gerek var mı? VPA ne öneriyor?"
Dev: gerçekten gerekli, justified
Merge → bilinçli karar
```

> 🔑 **PR-time visibility** = bilinçli karar.

---

## 🛠️ Tooling

### 1. **Infracost** (Terraform)
```bash
# CI integration
- uses: infracost/actions/setup@<VERSION>
- run: |
    infracost breakdown --path . > infra.json
- uses: infracost/actions/comment@<VERSION>
  with:
    path: infra.json
```

→ PR comment:
```
💰 Infracost
  Monthly cost change: +$320/mo

  - aws_instance.web (3x → 10x): +$245
  - aws_rds_instance.db (db.t3 → db.r5): +$75
```

### 2. **Kubecost** (K8s)
```yaml
- uses: kubecost/kubecost-cost-action@<VERSION>
  with:
    api-key: ${{ secrets.KUBECOST_API_KEY }}
    cluster: prod
```

→ PR comment:
```
💰 Kubecost Impact
  Resource changes:
    payments-api: replica 3 → 5
    Memory request: 1Gi → 2Gi

  Estimated impact:
    CPU: +400m → +$30/ay
    Memory: +2Gi → +$8/ay
    Total: +$38/ay (+%2.1)
```

### 3. **Custom (manuel script)**
```python
# scripts/cost-diff.py
import yaml
from cost_calculator import calculate

def diff(before_yaml, after_yaml):
    before = yaml.safe_load(before_yaml)
    after = yaml.safe_load(after_yaml)
    
    cost_before = calculate(before)
    cost_after = calculate(after)
    
    return {
        "before": cost_before,
        "after": cost_after,
        "diff": cost_after - cost_before,
        "percent": (cost_after - cost_before) / cost_before * 100
    }
```

---

## 🔧 Setup: Infracost

### Install + config
```bash
brew install infracost
infracost auth login   # API key (free tier)
```

### CI workflow
```yaml
# .github/workflows/cost-diff.yml
name: PR Cost Diff

on:
  pull_request:
    paths: ['terraform/**']

jobs:
  cost:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>
        with:
          fetch-depth: 0   # base + head ihtiyacı

      - uses: infracost/actions/setup@<VERSION>
        with:
          api-key: ${{ secrets.INFRACOST_API_KEY }}

      - name: Generate base
        run: |
          git checkout ${{ github.event.pull_request.base.sha }}
          infracost breakdown --path terraform/ \
            --format json --out-file /tmp/infracost-base.json

      - name: Generate head
        run: |
          git checkout ${{ github.event.pull_request.head.sha }}
          infracost diff --path terraform/ \
            --compare-to /tmp/infracost-base.json \
            --format json --out-file /tmp/infracost-diff.json

      - uses: infracost/actions/comment@<VERSION>
        with:
          path: /tmp/infracost-diff.json
          behavior: update
```

---

## 📊 Cost Threshold Alarm

```yaml
# Eğer +%10+ artış varsa label ekle
- name: Check threshold
  run: |
    DIFF=$(jq '.totalMonthlyCost' /tmp/infracost-diff.json)
    BASE=$(jq '.totalMonthlyCost' /tmp/infracost-base.json)
    PERCENT=$(echo "scale=2; $DIFF / $BASE * 100" | bc)

    if (( $(echo "$PERCENT > 10" | bc -l) )); then
      gh pr edit --add-label "cost-impact-high"
      gh pr comment --body "⚠️ %$PERCENT cost increase. Manager review needed."
    fi
```

---

## 🌳 Karar Akışı

```
[PR açıldı]
   │
   ▼
[CI: cost diff calculate]
   │
   ├── < %5 increase → auto-merge OK
   │
   ├── %5-15 → reviewer dikkat (dashboard görünür)
   │
   └── > %15 → manager approval gerekli
```

---

## 🌍 Multi-Cloud Cost Compare

### Senaryo
```
PR: "AWS Frankfurt'tan AWS Stockholm'e migrate"

Cost diff:
  Before: eu-central-1 → $5,000/ay
  After:  eu-north-1   → $3,800/ay
  Saving: -$1,200/ay (-%24)
  Bonus: -%80 carbon emission
```

→ Region migration + cost + carbon birlikte gösterilir.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Cost diff yok | Ay sonu sürpriz | PR-time check |
| Threshold yok | Tüm PR'lar approval | %5/%15 tiered |
| Sadece Terraform / sadece K8s | Cross-stack visibility yok | Infracost + Kubecost combo |
| Cost data PR'a yazılı değil | Reviewer görmez | Otomatik comment |
| Negative cost (saving) görünmez | Optimizasyon takdir edilmez | "+/-/=" işaretle |
| Carbon impact yok | Yeşil yazılım atlanır | Kubecost carbon module |
| Cost label yok | Tracking imkansız | High-cost label otomatik |
| Periodic cost retrospective yok | Pattern keşfi yok | Monthly cost change report |

---

## 📋 PR Cost Diff Adoption Checklist

```
[ ] Tool seçimi: Infracost (TF) + Kubecost (K8s)
[ ] CI workflow: PR'da cost diff calculate
[ ] PR comment otomasyon
[ ] Threshold: %5 normal, %15 manager approval
[ ] Label: cost-impact-low/medium/high
[ ] Carbon impact (sustainability integration)
[ ] Multi-cloud compare (region migration için)
[ ] Monthly retrospective: top cost-impacting PR'lar
[ ] Documentation: dev'lere cost-aware PR yazma rehberi
[ ] FinOps + Engineering shared dashboard
```

---

## 📚 Referanslar

- **Infracost** — infracost.io
- **Kubecost PR Comment** — docs.kubecost.com
- **OpenCost (CNCF)** — opencost.io
- **AWS Cost Explorer API** — docs.aws.amazon.com/aws-cost-management/
- [`Cloud-Cost-Allocation.md`](Cloud-Cost-Allocation.md)
- [`Right-Sizing.md`](Right-Sizing.md)
- [`Kubecost-Setup.md`](Kubecost-Setup.md)
- [`Spot-Instance-Strategy.md`](Spot-Instance-Strategy.md)
- [`14-Sustainability/Measuring-Software-Carbon.md`](../14-Sustainability/Measuring-Software-Carbon.md)

---

> *"PR-time cost diff = **preventive FinOps**. Ay sonu bill
> sürpriz olmaz; her merge **bilinçli karar**. CI'a 5 dk
> entegrasyon, kalıcı disiplin."*
