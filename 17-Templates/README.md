# 17 · Templates

> Copy-paste-değiştir-kullan. Tüm placeholder'lar `<UPPER_CASE>` ile.

## İçindekiler

| Klasör | İçerik |
|---|---|
| [`github-actions/`](github-actions/) | Reusable workflow'lar: docker build/push, terraform plan, release-please |
| [`kubernetes/`](kubernetes/) | Production-grade Deployment, Service, HPA, NetworkPolicy, PDB |
| [`dockerfiles/`](dockerfiles/) | Multi-stage Dockerfile'lar: Go, Node.js, Python |
| [`terraform/`](terraform/) | Module skeleton + standard variable yapısı |
| [`kyverno-policies/`](kyverno-policies/) | Imza doğrulama, label enforcement, image source kısıtlama |
| [`runbooks/`](runbooks/) | Runbook ve postmortem template |
| [`prometheus-rules/`](prometheus-rules/) | SLO recording + alerting rule template'leri |
| [`gitignore/`](gitignore/) | Stack başına `.gitignore` örnekleri |

## Genel kural

- ✅ Hiçbir template'te gerçek IP/domain/credential **yoktur**
- ✅ Yorum satırları placeholder'ları açıklar
- ✅ Her template `kubectl apply` veya `terraform plan` ile **valid**
- ✅ "Bunu değiştir" yorumları belirgin
