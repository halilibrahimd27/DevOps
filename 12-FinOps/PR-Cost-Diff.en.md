---
description: "Computing a PR's cost impact in CI and posting it to the PR comment: pre-merge cost review with Infracost and Kubecost, a conscious decision instead of a surprise bill."
tags:
  - FinOps
  - Cost Optimization
  - CI/CD
  - Terraform
  - Cost
---
# PR Cost Diff — "How much will this PR cost?"

> *"A developer opens a PR: replica 3 → 10, instance type m5.large → r5.4xlarge.
> Cost impact unknown → merge → month-end bill +$5K. **PR-time cost
> visibility** = preventive."*

This guide covers the practice of computing a PR's cost impact in CI and
posting it to the PR comment, along with Kubecost / Infracost tooling.

---

## 🎯 Why PR Cost Diff?

### Scenario (bad)
```
Dev: "Bumping memory 1Gi → 4Gi" (PR)
Reviewer: "LGTM" (no cost info)
Merge → 30 days later:
  AWS bill +$2K, month-end surprise
  Finance: "Where's this increase from?"
  Engineer: "From that PR..."
```

### Solution (good)
```
Dev: "Bumping memory 1Gi → 4Gi" (PR)
CI bot: 💰 +$1.5K/mo
Reviewer: "Hmm, is it needed? What does VPA suggest?"
Dev: genuinely needed, justified
Merge → conscious decision
```

> 🔑 **PR-time visibility** = conscious decision.

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
    CPU: +400m → +$30/mo
    Memory: +2Gi → +$8/mo
    Total: +$38/mo (+2.1%)
```

### 3. **Custom (manual script)**
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
          fetch-depth: 0   # needs base + head

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
# If there's a +10%+ increase, add a label
- name: Check threshold
  run: |
    DIFF=$(jq '.totalMonthlyCost' /tmp/infracost-diff.json)
    BASE=$(jq '.totalMonthlyCost' /tmp/infracost-base.json)
    PERCENT=$(echo "scale=2; $DIFF / $BASE * 100" | bc)

    if (( $(echo "$PERCENT > 10" | bc -l) )); then
      gh pr edit --add-label "cost-impact-high"
      gh pr comment --body "⚠️ $PERCENT% cost increase. Manager review needed."
    fi
```

---

## 🌳 Decision Flow

```
[PR opened]
   │
   ▼
[CI: cost diff calculate]
   │
   ├── < 5% increase → auto-merge OK
   │
   ├── 5-15% → reviewer attention (dashboard visible)
   │
   └── > 15% → manager approval required
```

---

## 🌍 Multi-Cloud Cost Compare

### Scenario
```
PR: "Migrate from AWS Frankfurt to AWS Stockholm"

Cost diff:
  Before: eu-central-1 → $5,000/mo
  After:  eu-north-1   → $3,800/mo
  Saving: -$1,200/mo (-24%)
  Bonus: -80% carbon emission
```

→ Region migration + cost + carbon shown together.

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Do this instead |
|---|---|---|
| No cost diff | Month-end surprise | PR-time check |
| No threshold | Every PR needs approval | 5%/15% tiered |
| Terraform-only / K8s-only | No cross-stack visibility | Infracost + Kubecost combo |
| Cost data not written into the PR | Reviewer doesn't see it | Automatic comment |
| Negative cost (saving) not shown | Optimization goes unrecognized | Mark with "+/-/=" |
| No carbon impact | Green software skipped | Kubecost carbon module |
| No cost label | Tracking impossible | Automatic high-cost label |
| No periodic cost retrospective | No pattern discovery | Monthly cost change report |

---

## 📋 PR Cost Diff Adoption Checklist

```
[ ] Tool choice: Infracost (TF) + Kubecost (K8s)
[ ] CI workflow: calculate cost diff on the PR
[ ] PR comment automation
[ ] Threshold: 5% normal, 15% manager approval
[ ] Label: cost-impact-low/medium/high
[ ] Carbon impact (sustainability integration)
[ ] Multi-cloud compare (for region migration)
[ ] Monthly retrospective: top cost-impacting PRs
[ ] Documentation: a cost-aware PR-writing guide for devs
[ ] FinOps + Engineering shared dashboard
```

---

## 📚 References

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

> *"PR-time cost diff = **preventive FinOps**. No month-end bill
> surprise; every merge a **conscious decision**. A 5-min
> integration into CI, lasting discipline."*
