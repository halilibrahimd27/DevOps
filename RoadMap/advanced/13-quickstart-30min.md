---
description: "28 günlük planı okumadan çalışan bir iskeleti 30 dakikada ayağa kaldırma rehberi: ön koşul checklist, ilk kurulum ve hızlı altyapı deployment adımları."
---
# ⚡ 30 Dakikalık Hızlı Kurulum

> Tüm 28 günlük planı okumadan, çalışan bir iskeleti hızlıca ayağa kaldırmak için.

## Ön Koşul Checklist

- [ ] AWS Account with administrative access
- [ ] Domain name for services (yourdomain.com)
- [ ] GitHub account for repositories
- [ ] Slack workspace for notifications
- [ ] Local development environment setup

## 30-Minute Setup

### Step 1: Initial Setup (5 minutes)
```bash
# Clone repository
git clone https://github.com/yourusername/devops-infrastructure.git
cd devops-infrastructure

# Run automated setup
./scripts/quick-setup.sh
```

### Step 2: Infrastructure Deployment (15 minutes)
```bash
# Deploy AWS infrastructure
cd terraform/environments/dev
terraform init -backend-config=backend.conf
terraform plan
terraform apply -auto-approve

# Configure kubectl
aws eks update-kubeconfig --region eu-west-1 --name mycompany-dev-eks
```

### Step 3: Application Deployment (10 minutes)
```bash
# Deploy monitoring stack
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace --values monitoring-values.yaml

# Deploy ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Deploy root application
kubectl apply -f bootstrap/root-app.yaml
```

## Verification

```bash
# Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Access services
echo "ArgoCD: https://argocd.yourdomain.com"
echo "Grafana: https://grafana.yourdomain.com"
echo "Applications ready! 🎉"
```

## Next Steps

1. **Configure DNS** - Point your domain to the load balancer
2. **Setup Certificates** - Configure SSL/TLS certificates
3. **Deploy Applications** - Add your applications to GitOps
4. **Configure Monitoring** - Set up dashboards and alerts
5. **Train Team** - Share access and documentation

## Need Help?

- 📖 **Tam rehber**: [advanced-roadmap.md](../advanced-roadmap.md) (28 günlük detaylı plan)
- 🔧 **Troubleshooting**: kurulum tamamlanınca kendi platformunda `docs/troubleshooting.md` oluştur
- 💬 **Support**: Contact DevOps team

**Happy deploying!** 🚀🚀🚀


```bash
echo ""
echo "🎉 ============================================"
echo "🎉  DEVOPS INFRASTRUCTURE SETUP COMPLETE!"
echo "🎉 ============================================"
echo ""
echo "📊 Summary:"
echo "✅ Infrastructure as Code (Terraform)"
echo "✅ Kubernetes Cluster (EKS)"
echo "✅ CI/CD Pipeline (Jenkins + ArgoCD)"
echo "✅ Monitoring Stack (Prometheus + Grafana)"
echo "✅ Logging Stack (OpenSearch + Fluent Bit)"
echo "✅ Security Layer (Vault + Falco + OPA)"
echo "✅ Backup & DR (Velero + RDS Backups)"
echo "✅ Cost Optimization (Kubecost + VPA/HPA)"
echo "✅ Documentation & Runbooks"
echo ""
echo "🔗 Access URLs:"
echo "• ArgoCD: https://argocd.yourdomain.com"
echo "• Grafana: https://grafana.yourdomain.com"
echo "• Jenkins: https://jenkins.yourdomain.com"
echo "• Vault: https://vault.yourdomain.com"
echo ""
echo "📚 Next Steps:"
echo "1. Run system validation: ./scripts/system-validation.sh"
echo "2. Configure your domain DNS"
echo "3. Deploy your first application"
echo "4. Train your team with provided documentation"
echo ""
echo "🎯 Your enterprise-grade DevOps infrastructure is ready!"
echo "   Happy DevOps! 🚀🚀🚀"
```

Bu kapsamlı implementation guide ile sıfırdan başlayarak **28 gün içinde** tam işlevsel, production-ready bir DevOps altyapısı kurabilirsiniz. Her adım detaylı komutlar, konfigürasyonlar ve best practice'ler içerir.
