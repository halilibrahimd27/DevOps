---
description: "Faz 12 (Gün 27-28): Final kurulum ve doğrulama; tüm sistemin uçtan uca test scriptiyle validasyonu, başarı sayacı ve test kontrollerinin çalıştırılması."
---
# 🎉 **FINAL SETUP AND VALIDATION** (Gün 27-28)

### ✅ **13.1 End-to-End Testing**

```bash
# 13.1.1 Complete system validation script
cat > ~/devops-infrastructure/scripts/system-validation.sh << 'EOF'
#!/bin/bash

# Complete System Validation Script
set -e

echo "🧪 Starting End-to-End System Validation..."
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SUCCESS_COUNT=0
TOTAL_TESTS=0

check_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "Testing $test_name... "
    
    if eval "$test_command" &>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        return 1
    fi
}

echo "🔧 Infrastructure Tests"
echo "----------------------"

# AWS connectivity
check_test "AWS CLI access" "aws sts get-caller-identity"

# Terraform state
check_test "Terraform state accessible" "terraform show -json > /dev/null" || true

# EKS cluster
check_test "EKS cluster connectivity" "kubectl get nodes"

# Core system pods
check_test "CoreDNS running" "kubectl get pods -n kube-system -l k8s-app=kube-dns | grep Running"
check_test "AWS Load Balancer Controller" "kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller | grep Running"

echo ""
echo "📊 Monitoring Stack Tests"
echo "-------------------------"

# Prometheus
check_test "Prometheus accessible" "kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus | grep Running"

# Grafana
check_test "Grafana accessible" "kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana | grep Running"

# AlertManager
check_test "AlertManager accessible" "kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager | grep Running"

echo ""
echo "📝 Logging Stack Tests"
echo "----------------------"

# Fluent Bit
check_test "Fluent Bit running" "kubectl get pods -n logging -l app.kubernetes.io/name=fluent-bit | grep Running"

# OpenSearch
check_test "OpenSearch cluster healthy" "kubectl get pods -n logging -l app=opensearch | grep Running"

echo ""
echo "🔒 Security Tests"
echo "----------------"

# Vault
check_test "Vault cluster running" "kubectl get pods -n vault -l app.kubernetes.io/name=vault | grep Running"

# External Secrets Operator
check_test "External Secrets Operator" "kubectl get pods -n external-secrets | grep Running"

# Falco
check_test "Falco security monitoring" "kubectl get pods -n falco -l app.kubernetes.io/name=falco | grep Running"

echo ""
echo "🔄 GitOps Tests"
echo "---------------"

# ArgoCD
check_test "ArgoCD server running" "kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server | grep Running"

# ArgoCD applications
check_test "ArgoCD applications synced" "argocd app list | grep -E 'Synced.*Healthy'"

echo ""
echo "💾 Backup Tests"
echo "---------------"

# Velero
check_test "Velero backup controller" "kubectl get pods -n velero -l app.kubernetes.io/name=velero | grep Running"

# Recent backup
check_test "Recent backup exists" "velero backup get | grep Completed | head -1"

echo ""
echo "🚀 Application Tests"
echo "--------------------"

# Sample application
check_test "Sample application running" "kubectl get pods -n dev -l app=sample-app | grep Running" || true

# Ingress connectivity
check_test "Ingress controller responsive" "kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx | grep Running"

echo ""
echo "📈 Performance Tests"
echo "-------------------"

# HPA
check_test "HPA controllers active" "kubectl get hpa --all-namespaces | grep -v TARGETS" || true

# VPA
check_test "VPA recommendations available" "kubectl get vpa --all-namespaces" || true

# Resource usage
check_test "Node resource usage healthy" "kubectl top nodes --no-headers | awk '\$3+0 < 90 && \$5+0 < 90' | wc -l | grep -v '^0-vpa
  namespace: monitoring
spec:
  targetRef:
    apiVersion: apps/v1
    kind: StatefulSet"

echo ""
echo "🌐 Network Tests"
echo "---------------"

# CoreDNS resolution
check_test "DNS resolution working" "kubectl exec -n kube-system deployments/coredns -- nslookup kubernetes.default.svc.cluster.local"

# Pod-to-pod communication
check_test "Inter-pod communication" "kubectl run network-test --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default" || true

echo ""
echo "🔐 Certificate Tests"
echo "-------------------"

# Cert-manager
check_test "Cert-manager running" "kubectl get pods -n cert-manager | grep Running"

# Certificate issuers
check_test "Certificate issuers ready" "kubectl get clusterissuers | grep True"

# Valid certificates
check_test "TLS certificates valid" "kubectl get certificates --all-namespaces | grep True" || true

echo ""
echo "📊 Cost Monitoring Tests"
echo "------------------------"

# Kubecost
check_test "Kubecost running" "kubectl get pods -n kubecost | grep Running" || true

echo ""
echo "🔍 Observability Tests"
echo "----------------------"

# Jaeger
check_test "Jaeger tracing available" "kubectl get pods -n observability -l app.kubernetes.io/name=jaeger | grep Running" || true

# OpenTelemetry
check_test "OpenTelemetry collector" "kubectl get pods -n observability -l app.kubernetes.io/name=opentelemetry-collector | grep Running" || true

echo ""
echo "================================================"
echo "🎯 VALIDATION SUMMARY"
echo "================================================"
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $SUCCESS_COUNT"
echo "Failed: $((TOTAL_TESTS - SUCCESS_COUNT))"

if [ $SUCCESS_COUNT -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! System is fully operational.${NC}"
    exit 0
elif [ $SUCCESS_COUNT -gt $((TOTAL_TESTS * 80 / 100)) ]; then
    echo -e "${YELLOW}⚠️  Most tests passed. Minor issues detected.${NC}"
    exit 0
else
    echo -e "${RED}❌ Critical issues detected. System requires attention.${NC}"
    exit 1
fi
EOF

chmod +x ~/devops-infrastructure/scripts/system-validation.sh

# 13.1.2 Automated testing pipeline
cat > ~/devops-infrastructure/jenkins/system-validation-pipeline.groovy << 'EOF'
pipeline {
    agent {
        kubernetes {
            yaml """
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: kubectl
                image: bitnami/kubectl:latest
                command:
                - cat
                tty: true
              - name: argocd
                image: argoproj/argocd:latest
                command:
                - cat
                tty: true
              - name: velero
                image: velero/velero:latest
                command:
                - cat
                tty: true
            """
        }
    }
    
    triggers {
        cron('0 6 * * *') // Daily at 6 AM
    }
    
    stages {
        stage('System Validation') {
            steps {
                container('kubectl') {
                    script {
                        sh '''
                            # Copy validation script
                            curl -fsSL https://raw.githubusercontent.com/yourusername/devops-infrastructure/main/scripts/system-validation.sh -o validation.sh
                            chmod +x validation.sh
                            
                            # Run validation
                            ./validation.sh
                        '''
                    }
                }
            }
        }
        
        stage('Generate Report') {
            steps {
                container('kubectl') {
                    sh '''
                        # Generate detailed report
                        echo "# System Health Report - $(date)" > system-report.md
                        echo "" >> system-report.md
                        
                        echo "## Cluster Overview" >> system-report.md
                        echo "\`\`\`" >> system-report.md
                        kubectl get nodes -o wide >> system-report.md
                        echo "\`\`\`" >> system-report.md
                        
                        echo "## Pod Status" >> system-report.md
                        echo "\`\`\`" >> system-report.md
                        kubectl get pods --all-namespaces | grep -v Running | head -20 >> system-report.md
                        echo "\`\`\`" >> system-report.md
                        
                        echo "## Resource Usage" >> system-report.md
                        echo "\`\`\`" >> system-report.md
                        kubectl top nodes >> system-report.md
                        echo "\`\`\`" >> system-report.md
                        
                        # Archive report
                        cat system-report.md
                    '''
                }
            }
        }
    }
    
    post {
        success {
            slackSend(
                channel: '#infrastructure',
                color: 'good',
                message: "✅ Daily system validation completed successfully"
            )
        }
        failure {
            slackSend(
                channel: '#infrastructure',
                color: 'danger',
                message: "❌ Daily system validation failed. Immediate attention required!"
            )
        }
        always {
            archiveArtifacts artifacts: '*.md', allowEmptyArchive: true
        }
    }
}
EOF

# 13.1.3 Çalıştır
~/devops-infrastructure/scripts/system-validation.sh
```

### 📚 **13.2 Final Documentation**

```bash
# 13.2.1 Complete setup summary
cat > ~/devops-infrastructure/README.md << 'EOF'
# DevOps Infrastructure - Complete Setup

🎉 **Congratulations!** You have successfully deployed a production-ready DevOps infrastructure.

## 🏗️ What We've Built

### Infrastructure Components
- ✅ **AWS EKS Cluster** - Managed Kubernetes with auto-scaling
- ✅ **VPC & Networking** - Multi-AZ setup with security groups
- ✅ **RDS PostgreSQL** - Managed database with backups
- ✅ **ElastiCache Redis** - In-memory caching
- ✅ **Application Load Balancer** - SSL termination and routing

### CI/CD Pipeline
- ✅ **Jenkins** - Automated build and deployment
- ✅ **ArgoCD** - GitOps continuous deployment
- ✅ **GitHub Container Registry** - Container image storage
- ✅ **Progressive Delivery** - Canary and blue-green deployments

### Monitoring & Observability
- ✅ **Prometheus** - Metrics collection and storage
- ✅ **Grafana** - Visualization and dashboards
- ✅ **AlertManager** - Intelligent alerting
- ✅ **Jaeger** - Distributed tracing
- ✅ **OpenSearch** - Log aggregation and search
- ✅ **Fluent Bit** - Log collection

### Security
- ✅ **HashiCorp Vault** - Secrets management
- ✅ **External Secrets Operator** - Kubernetes-Vault integration
- ✅ **Falco** - Runtime security monitoring
- ✅ **OPA Gatekeeper** - Policy enforcement
- ✅ **Network Policies** - Micro-segmentation
- ✅ **Pod Security Standards** - Container security

### Backup & DR
- ✅ **Velero** - Kubernetes backup and restore
- ✅ **RDS Automated Backups** - Database recovery
- ✅ **Cross-region Replication** - Disaster recovery
- ✅ **Automated Testing** - DR drill automation

### Cost Optimization
- ✅ **Kubecost** - Kubernetes cost visibility
- ✅ **VPA/HPA** - Resource optimization
- ✅ **Spot Instances** - Cost-effective compute
- ✅ **Resource Quotas** - Spend control

## 🚀 Access URLs

| Service | URL | Purpose |
|---------|-----|---------|
| ArgoCD | https://argocd.yourdomain.com | GitOps Management |
| Grafana | https://grafana.yourdomain.com | Monitoring Dashboards |
| Jaeger | https://jaeger.yourdomain.com | Distributed Tracing |
| OpenSearch | https://logs.yourdomain.com | Log Analysis |
| Vault | https://vault.yourdomain.com | Secrets Management |
| Jenkins | https://jenkins.yourdomain.com | CI/CD Pipelines |
| Kubecost | https://kubecost.yourdomain.com | Cost Analytics |

## 🔑 Default Credentials

```bash
# ArgoCD
Username: admin
Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Grafana
Username: admin
Password: AdminPassword123!

# Vault Root Token
Token: $(cat cluster-keys.json | jq -r ".root_token")
```

## 📊 System Overview

```bash
# Check overall system health
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running

# Monitor resource usage
kubectl top nodes
kubectl top pods --all-namespaces --sort-by=cpu

# Check applications
argocd app list
helm list --all-namespaces
```

## 🛠️ Common Operations

### Deploy New Application
```bash
# 1. Add application manifests to GitOps repo
cd gitops-config/applications/dev
# Create your application YAML files

# 2. Commit and push
git add .
git commit -m "Add new application"
git push origin main

# 3. ArgoCD will automatically sync
argocd app sync <app-name>
```

### Scale Applications
```bash
# Manual scaling
kubectl scale deployment <app-name> --replicas=5 -n <namespace>

# Auto-scaling with HPA
kubectl autoscale deployment <app-name> --cpu-percent=70 --min=2 --max=10 -n <namespace>
```

### Check Logs
```bash
# Pod logs
kubectl logs <pod-name> -n <namespace> --tail=100

# Application logs in OpenSearch
# Visit: https://logs.yourdomain.com
# Query: kubernetes.namespace_name:"dev" AND kubernetes.labels.app:"your-app"
```

### Monitor Performance
```bash
# Real-time metrics
kubectl top pods -n <namespace>

# Grafana dashboards
# Visit: https://grafana.yourdomain.com
# Check: Kubernetes Cluster Overview dashboard
```

### Backup and Restore
```bash
# Create backup
velero backup create <backup-name> --include-namespaces <namespace>

# Restore from backup
velero restore create <restore-name> --from-backup <backup-name>

# Check backup status
velero backup describe <backup-name>
```

## 🚨 Troubleshooting

### Pod Issues
```bash
# Pod not starting
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>

# Resource issues
kubectl top pods -n <namespace>
kubectl describe node <node-name>
```

### Network Issues
```bash
# DNS resolution
kubectl exec -it <pod-name> -n <namespace> -- nslookup kubernetes.default

# Service connectivity
kubectl exec -it <pod-name> -n <namespace> -- curl <service-name>.<namespace>.svc.cluster.local
```

### Storage Issues
```bash
# PVC status
kubectl get pvc -n <namespace>
kubectl describe pvc <pvc-name> -n <namespace>

# Storage classes
kubectl get storageclass
```

## 📈 Performance Optimization

### Resource Right-sizing
```bash
# Check VPA recommendations
kubectl get vpa --all-namespaces

# Apply VPA recommendations
kubectl patch deployment <app-name> -n <namespace> --patch '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "<container-name>",
            "resources": {
              "requests": {
                "cpu": "<recommended-cpu>",
                "memory": "<recommended-memory>"
              }
            }
          }
        ]
      }
    }
  }
}'
```

### Cost Optimization
```bash
# Check cost recommendations
# Visit: https://kubecost.yourdomain.com

# Use spot instances for development
kubectl taint node <node-name> spot=true:NoSchedule

# Implement resource quotas
kubectl apply -f resource-quotas.yaml
```

## 🔒 Security Best Practices

### Regular Security Tasks
```bash
# Update base images regularly
docker pull nginx:alpine
docker tag nginx:alpine ghcr.io/yourusername/nginx:latest
docker push ghcr.io/yourusername/nginx:latest

# Scan for vulnerabilities
trivy image <image-name>

# Check for policy violations
kubectl get events --all-namespaces | grep -i policy

# Review Falco alerts
kubectl logs -l app.kubernetes.io/name=falco -n falco
```

### Certificate Management
```bash
# Check certificate status
kubectl get certificates --all-namespaces

# Force certificate renewal
kubectl annotate certificate <cert-name> -n <namespace> \
  cert-manager.io/issue-temporary-certificate="true"
```

## 📚 Additional Resources

### Documentation
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

### Monitoring
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [SRE Workbook](https://sre.google/workbook/table-of-contents/)

### Security
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [OWASP Container Security](https://owasp.org/www-project-container-security/)

## 🆘 Support and Contacts

### Internal Support
- **DevOps Team**: #devops-team (Slack)
- **On-call Engineer**: +90-XXX-XXX-XXXX
- **Documentation**: `~/devops-infrastructure/docs/`

### Emergency Procedures
1. **Production Down**: Follow incident response runbook
2. **Security Incident**: Contact security team immediately
3. **Data Loss**: Initiate disaster recovery procedures

---

## 🎉 Congratulations!

You now have a **production-ready, enterprise-grade DevOps infrastructure** that includes:

✅ **Automated Infrastructure** - Everything as code  
✅ **Continuous Deployment** - GitOps workflow  
✅ **Comprehensive Monitoring** - Full observability stack  
✅ **Enterprise Security** - Multi-layer security controls  
✅ **Disaster Recovery** - Automated backup and restore  
✅ **Cost Optimization** - Resource efficiency and cost visibility  
✅ **Performance Management** - Auto-scaling and optimization  
✅ **Team Processes** - Documentation and runbooks  

**Your infrastructure is ready to support modern application development and deployment at scale!** 🚀

---

*Generated on: $(date)*  
*Infrastructure Version: v1.0.0*  
*Last Updated: $(date '+%Y-%m-%d %H:%M:%S')*
EOF

# 13.2.2 Quick start guide
cat > ~/devops-infrastructure/QUICKSTART.md << 'EOF'
# 🚀 Quick Start Guide
