---
description: "Faz 11 (Gün 25-26): Dokümantasyon ve ekip süreçleri; mimari dokümantasyon, mermaid diyagramları ve GitHub'dan EKS'e uzanan CI/CD akışının kayda geçirilmesi."
tags:
  - Roadmap
  - Culture
  - Soft Skills
  - CI/CD
---
# 📚 **PHASE 11: DOCUMENTATION & TEAM PROCESSES** (Gün 25-26)

### 📖 **12.1 Comprehensive Documentation**

```bash
# 12.1.1 Architecture documentation
cat > ~/devops-infrastructure/docs/architecture-overview.md << 'EOF'
# DevOps Infrastructure Architecture

## Overview
Bu doküman şirketimizin Kubernetes-based DevOps altyapısının mimari yapısını detaylandırır.

## High-Level Architecture

```mermaid
graph TB
    Developer[Developer] --> GitHub[GitHub Repository]
    GitHub --> Jenkins[Jenkins CI/CD]
    Jenkins --> Registry[GitHub Container Registry]
    Jenkins --> ArgoCD[ArgoCD GitOps]
    
    ArgoCD --> EKS[Amazon EKS]
    EKS --> Apps[Applications]
    
    subgraph "AWS Infrastructure"
        VPC[VPC]
        EKS --> VPC
        RDS[RDS PostgreSQL]
        ElastiCache[ElastiCache Redis]
        S3[S3 Buckets]
        ALB[Application Load Balancer]
    end
    
    subgraph "Monitoring Stack"
        Prometheus[Prometheus]
        Grafana[Grafana]
        AlertManager[AlertManager]
        Jaeger[Jaeger Tracing]
    end
    
    subgraph "Logging Stack"
        FluentBit[Fluent Bit]
        OpenSearch[OpenSearch]
        OpenSearchDashboards[OpenSearch Dashboards]
    end
    
    subgraph "Security"
        Vault[HashiCorp Vault]
        Falco[Falco Runtime Security]
        OPA[OPA Gatekeeper]
    end
    
    Apps --> Monitoring Stack
    Apps --> Logging Stack
    Apps --> Security
```

## Component Details

### Infrastructure Layer

#### AWS Services
- **VPC**: Multi-AZ setup with public/private subnets
- **EKS**: Managed Kubernetes cluster (v1.28)
- **RDS**: PostgreSQL with Multi-AZ and read replicas
- **ElastiCache**: Redis for caching and session storage
- **ALB**: Application Load Balancer with SSL termination
- **S3**: Object storage for backups, logs, and artifacts

#### Kubernetes Components
- **Namespaces**: dev, staging, production, monitoring, logging, security
- **RBAC**: Role-based access control for different teams
- **Network Policies**: Micro-segmentation with Calico
- **Pod Security Standards**: Enforced security contexts
- **Storage Classes**: GP3, IO1 for different performance needs

### Application Layer

#### Deployment Strategy
- **GitOps**: ArgoCD-based continuous deployment
- **Progressive Delivery**: Canary and Blue-Green deployments
- **Auto-scaling**: HPA, VPA, and KEDA for event-driven scaling
- **Service Mesh**: Istio for traffic management (optional)

#### Security
- **Secrets Management**: HashiCorp Vault with External Secrets Operator
- **Runtime Security**: Falco for threat detection
- **Policy Enforcement**: OPA Gatekeeper for admission control
- **Image Security**: Trivy scanning in CI/CD pipeline

### Observability

#### Monitoring
- **Metrics**: Prometheus with custom and pre-built dashboards
- **Visualization**: Grafana with role-based dashboards
- **Alerting**: AlertManager with Slack/PagerDuty integration
- **Distributed Tracing**: Jaeger for request tracing

#### Logging
- **Collection**: Fluent Bit daemonset
- **Storage**: OpenSearch cluster
- **Analysis**: OpenSearch Dashboards
- **Retention**: 30-day retention with automated cleanup

## Security Architecture

### Access Control
1. **AWS IAM**: Service accounts with IRSA
2. **Kubernetes RBAC**: Namespace-level permissions
3. **Vault**: Centralized secrets management
4. **Network Policies**: Pod-to-pod communication rules

### Security Scanning
1. **Container Images**: Trivy in CI/CD
2. **Infrastructure**: Checkov for Terraform
3. **Runtime**: Falco for anomaly detection
4. **Policy**: OPA for compliance enforcement

## Disaster Recovery

### Backup Strategy
- **Kubernetes**: Velero daily/weekly backups
- **Database**: RDS automated backups + manual snapshots
- **Storage**: EBS snapshots
- **Cross-region**: S3 replication for critical data

### Recovery Objectives
- **RTO**: 4 hours for complete infrastructure
- **RPO**: 1 hour for data loss
- **Testing**: Monthly DR drills

## Cost Optimization

### Strategies
1. **Resource Right-sizing**: VPA recommendations
2. **Spot Instances**: Karpenter for non-critical workloads
3. **Storage Optimization**: GP3 for better price/performance
4. **Reserved Instances**: For predictable workloads

### Monitoring
- **Kubecost**: Kubernetes cost visibility
- **AWS Cost Explorer**: Infrastructure cost analysis
- **Automated Cleanup**: Unused resources identification

## Performance Optimization

### Auto-scaling
- **HPA**: CPU/Memory-based pod scaling
- **VPA**: Resource recommendation and adjustment
- **KEDA**: Event-driven scaling (queue length, metrics)
- **Cluster Autoscaler**: Node-level scaling

### Load Testing
- **K6**: Automated performance testing
- **Chaos Engineering**: Failure injection testing
- **SLI/SLO**: Service level monitoring

## Operational Procedures

### Deployment Process
1. Developer pushes code to GitHub
2. Jenkins builds and tests application
3. Jenkins pushes image to GHCR
4. Jenkins updates GitOps repository
5. ArgoCD syncs changes to Kubernetes
6. Progressive delivery monitors health

### Incident Response
1. **Detection**: Automated alerting via AlertManager
2. **Notification**: Slack/PagerDuty escalation
3. **Response**: Runbook-driven remediation
4. **Recovery**: Automated rollback if needed
5. **Post-mortem**: Root cause analysis

## Team Responsibilities

### DevOps Team
- Infrastructure maintenance
- CI/CD pipeline management
- Security compliance
- Performance optimization

### Development Teams
- Application deployment
- Resource requirements definition
- Application monitoring setup
- Performance testing

### Operations Team
- Incident response
- Backup verification
- Capacity planning
- Change management
EOF

# 12.1.2 Operational runbooks
cat > ~/devops-infrastructure/docs/operational-runbooks.md << 'EOF'
# Operational Runbooks

## Incident Response Procedures

### High CPU Usage Alert

#### Symptoms
- AlertManager fires "High CPU Usage" alert
- Application response times increase
- Users report slowness

#### Investigation Steps
```bash
# 1. Check current CPU usage
kubectl top pods -n <namespace> --sort-by=cpu

# 2. Check HPA status
kubectl get hpa -n <namespace>

# 3. Check pod resource limits
kubectl describe pod <pod-name> -n <namespace>

# 4. Review metrics in Grafana
# Go to CPU Usage dashboard: https://grafana.yourdomain.com/d/cpu-usage
```

#### Resolution Steps
```bash
# 1. Immediate: Scale up manually if HPA not working
kubectl scale deployment <deployment-name> --replicas=<new-count> -n <namespace>

# 2. Check for resource limits
kubectl patch deployment <deployment-name> -n <namespace> --patch '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "<container-name>",
            "resources": {
              "limits": {
                "cpu": "1000m",
                "memory": "1Gi"
              }
            }
          }
        ]
      }
    }
  }
}'

# 3. Restart problematic pods
kubectl rollout restart deployment <deployment-name> -n <namespace>
```

#### Prevention
- Implement proper resource requests/limits
- Set up HPA with appropriate thresholds
- Regular load testing

### Database Connection Issues

#### Symptoms
- Applications cannot connect to database
- Connection timeout errors
- Database-related alerts

#### Investigation Steps
```bash
# 1. Check database connectivity from pod
kubectl run db-test --rm -i --tty --image=postgres:15-alpine -- \
  psql -h <db-host> -U <username> -d <database> -c "SELECT 1;"

# 2. Check database secret
kubectl get secret database-secret -n <namespace> -o yaml

# 3. Check RDS status
aws rds describe-db-instances --db-instance-identifier <db-identifier>

# 4. Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

#### Resolution Steps
```bash
# 1. Restart application pods
kubectl rollout restart deployment -n <namespace>

# 2. Check and update database credentials
kubectl patch secret database-secret -n <namespace> --patch '
{
  "data": {
    "password": "<base64-encoded-new-password>"
  }
}'

# 3. If RDS issue, check AWS console and restart if needed
aws rds reboot-db-instance --db-instance-identifier <db-identifier>
```

### Pod Stuck in Pending State

#### Investigation Steps
```bash
# 1. Describe the pod
kubectl describe pod <pod-name> -n <namespace>

# 2. Check node resources
kubectl describe nodes

# 3. Check PVC status if using persistent storage
kubectl get pvc -n <namespace>

# 4. Check for resource quotas
kubectl describe quota -n <namespace>
```

#### Resolution Steps
```bash
# 1. If insufficient resources, scale cluster
aws eks update-nodegroup-config \
  --cluster-name <cluster-name> \
  --nodegroup-name <nodegroup-name> \
  --scaling-config minSize=<min>,maxSize=<max>,desiredSize=<desired>

# 2. If PVC issue, check storage class
kubectl get storageclass

# 3. If quota exceeded, increase or clean up resources
kubectl delete deployment <unused-deployment> -n <namespace>
```

## Maintenance Procedures

### Kubernetes Cluster Upgrade

#### Pre-upgrade Checklist
- [ ] Backup cluster state with Velero
- [ ] Review breaking changes in new version
- [ ] Test upgrade in staging environment
- [ ] Notify team about maintenance window
- [ ] Prepare rollback plan

#### Upgrade Steps
```bash
# 1. Update control plane
aws eks update-cluster-version \
  --name <cluster-name> \
  --version <new-version>

# 2. Wait for update completion
aws eks wait cluster-active --name <cluster-name>

# 3. Update node groups
aws eks update-nodegroup-version \
  --cluster-name <cluster-name> \
  --nodegroup-name <nodegroup-name> \
  --version <new-version>

# 4. Update addons
aws eks update-addon \
  --cluster-name <cluster-name> \
  --addon-name vpc-cni \
  --addon-version <new-version>

# 5. Verify cluster health
kubectl get nodes
kubectl get pods --all-namespaces
```

### Database Maintenance

#### Monthly Tasks
```bash
# 1. Review database performance
aws rds describe-db-instances \
  --db-instance-identifier <db-identifier> \
  --query 'DBInstances[0].PerformanceInsights'

# 2. Cleanup old snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier <db-identifier> \
  --snapshot-type manual \
  --query 'DBSnapshots[30:].[DBSnapshotIdentifier]' \
  --output text | \
  xargs -I {} aws rds delete-db-snapshot --db-snapshot-identifier {}

# 3. Analyze slow queries
# Access RDS Performance Insights dashboard
```

### Certificate Renewal

#### Let's Encrypt Certificates
```bash
# 1. Check certificate expiry
kubectl get certificates -A

# 2. Force renewal if needed
kubectl annotate certificate <cert-name> -n <namespace> \
  cert-manager.io/issue-temporary-certificate="true"

# 3. Verify renewal
kubectl describe certificate <cert-name> -n <namespace>
```

## Monitoring and Alerting

### Key Metrics to Monitor

#### Infrastructure
- Node CPU/Memory usage > 80%
- Disk usage > 85%
- Network connectivity issues
- Pod restart frequency

#### Application
- Response time > 2s (95th percentile)
- Error rate > 5%
- Request rate anomalies
- Database connection pool exhaustion

#### Security
- Failed authentication attempts
- Privilege escalation attempts
- Unusual network traffic
- Policy violations

### Alert Escalation

#### Severity Levels
1. **P1 (Critical)**: Immediate response (5 min)
   - Production down
   - Data breach
   - Security incident

2. **P2 (High)**: 30 min response
   - Performance degradation
   - Service partially down
   - High error rates

3. **P3 (Medium)**: 2 hour response
   - Non-critical service issues
   - Capacity warnings
   - Configuration issues

4. **P4 (Low)**: Next business day
   - Informational alerts
   - Optimization opportunities
   - Compliance warnings

## Change Management

### Deployment Approval Process

#### Development Environment
- Automatic deployment on merge to `develop` branch
- No approval required
- Immediate rollback available

#### Staging Environment
- Automatic deployment on merge to `main` branch
- Automated testing required
- Manual approval for production promotion

#### Production Environment
- Manual approval required
- Deployment during maintenance window
- Canary deployment strategy
- Automated rollback on failure

### Emergency Change Process
1. Incident commander approval
2. Minimal viable fix
3. Fast-track testing
4. Immediate deployment
5. Post-incident review
EOF

# 12.1.3 Team onboarding guide
cat > ~/devops-infrastructure/docs/team-onboarding.md << 'EOF'
# Team Onboarding Guide

## Prerequisites

### Required Tools
1. **kubectl** - Kubernetes CLI
2. **helm** - Kubernetes package manager
3. **terraform** - Infrastructure as Code
4. **docker** - Container runtime
5. **aws-cli** - AWS command line interface
6. **argocd** - GitOps CLI
7. **git** - Version control

### Installation Script
```bash
# Run the automated setup script
curl -fsSL https://raw.githubusercontent.com/yourusername/devops-infrastructure/main/scripts/setup-dev-environment.sh | bash
```

## Access Setup

### 1. AWS Access
```bash
# Configure AWS CLI
aws configure
# Use provided access key and secret key

# Test access
aws sts get-caller-identity
```

### 2. Kubernetes Access
```bash
# Configure kubectl
aws eks update-kubeconfig --region eu-west-1 --name mycompany-dev-eks

# Test cluster access
kubectl get nodes
```

### 3. ArgoCD Access
```bash
# Login to ArgoCD
argocd login argocd.yourdomain.com

# List applications
argocd app list
```

### 4. Vault Access
```bash
# Set Vault address
export VAULT_ADDR="https://vault.yourdomain.com"

# Login with provided token
vault auth -method=userpass username=<your-username>
```

## Development Workflow

### 1. Application Development
```bash
# 1. Clone application repository
git clone https://github.com/yourusername/sample-app.git
cd sample-app

# 2. Create feature branch
git checkout -b feature/new-feature

# 3. Make changes and test locally
docker build -t sample-app:local .
docker run -p 8080:8080 sample-app:local

# 4. Commit and push
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature

# 5. Create pull request
# Pipeline will automatically build and deploy to dev environment
```

### 2. Infrastructure Changes
```bash
# 1. Clone infrastructure repository
git clone https://github.com/yourusername/devops-infrastructure.git
cd devops-infrastructure

# 2. Make changes to Terraform
cd terraform/environments/dev
terraform plan

# 3. Apply changes
terraform apply

# 4. Update GitOps repository if needed
cd ../../..
git clone https://github.com/yourusername/gitops-config.git
# Make necessary Kubernetes manifest changes
```

## Common Tasks

### Deploy New Application

#### 1. Create Kubernetes Manifests
```yaml
# applications/dev/new-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-app
  namespace: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: new-app
  template:
    metadata:
      labels:
        app: new-app
    spec:
      containers:
      - name: app
        image: ghcr.io/yourusername/new-app:v1.0.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
```

#### 2. Create Service and Ingress
```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: new-app
  namespace: dev
spec:
  selector:
    app: new-app
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: new-app
  namespace: dev
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: new-app-dev.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: new-app
            port:
              number: 80
```

### Debug Application Issues

#### 1. Check Pod Status
```bash
# List pods
kubectl get pods -n dev

# Describe problematic pod
kubectl describe pod <pod-name> -n dev

# Check logs
kubectl logs <pod-name> -n dev --tail=100
```

#### 2. Access Pod for Debugging
```bash
# Execute commands in pod
kubectl exec -it <pod-name> -n dev -- /bin/bash

# Port forward for local access
kubectl port-forward <pod-name> 8080:8080 -n dev
```

#### 3. Check Resource Usage
```bash
# Top pods by resource usage
kubectl top pods -n dev

# Check HPA status
kubectl get hpa -n dev
```

### Scale Applications

#### Manual Scaling
```bash
# Scale deployment
kubectl scale deployment <app-name> --replicas=5 -n dev

# Check scaling status
kubectl get deployment <app-name> -n dev
```

#### Configure Auto-scaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
  namespace: dev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app-name
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Monitoring and Troubleshooting

### Access Monitoring Tools

#### Grafana Dashboards
- **URL**: https://grafana.yourdomain.com
- **Default Dashboards**:
  - Kubernetes Cluster Overview
  - Application Performance
  - Infrastructure Metrics
  - Cost Analysis

#### Log Analysis
- **URL**: https://logs.yourdomain.com
- **Common Queries**:
  ```
  # Application logs
  kubernetes.namespace_name:"dev" AND kubernetes.labels.app:"sample-app"
  
  # Error logs
  level:"error" AND kubernetes.namespace_name:"dev"
  
  # Specific time range
  @timestamp:[now-1h TO now] AND kubernetes.pod_name:"pod-name"
  ```

#### Distributed Tracing
- **URL**: https://jaeger.yourdomain.com
- **Usage**: Search by service name, operation, or trace ID

### Performance Testing

#### Run Load Test
```bash
# Apply load test configuration
kubectl apply -f - <<EOF
apiVersion: k6.io/v1alpha1
kind: K6
metadata:
  name: load-test
  namespace: dev
spec:
  parallelism: 2
  script:
    configMap:
      name: k6-scripts
      file: load-test.js
EOF

# Monitor test progress
kubectl logs -f job/load-test-1 -n dev
```

## Security Best Practices

### Container Security
1. **Use minimal base images** (distroless, alpine)
2. **Run as non-root user**
3. **Set resource limits**
4. **Scan images for vulnerabilities**

### Kubernetes Security
1. **Use namespaces for isolation**
2. **Implement RBAC properly**
3. **Set Pod Security Standards**
4. **Use Network Policies**

### Secrets Management
```bash
# Create secret in Vault
vault kv put secret/dev/app-config \
  database_password="super-secret" \
  api_key="api-key-value"

# Create ExternalSecret to sync
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-config
  namespace: dev
spec:
  refreshInterval: 1m
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: app-config-secret
  data:
  - secretKey: database_password
    remoteRef:
      key: secret/dev/app-config
      property: database_password
EOF
```

## Getting Help

### Internal Resources
- **DevOps Team Slack**: #devops-team
- **Documentation**: https://docs.company.com/devops
- **Runbooks**: ~/devops-infrastructure/docs/
- **Architecture Diagrams**: ~/devops-infrastructure/docs/architecture/

### Emergency Contacts
- **On-call Engineer**: +90-XXX-XXX-XXXX
- **DevOps Team Lead**: +90-XXX-XXX-XXXX
- **Security Team**: security@company.com

### External Resources
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **AWS EKS Guide**: https://docs.aws.amazon.com/eks/
- **ArgoCD Documentation**: https://argo-cd.readthedocs.io/
- **Prometheus Documentation**: https://prometheus.io/docs/
EOF
```

### 📊 **12.2 Automated Reporting**

```bash
# 12.2.1 Infrastructure health report script
cat > ~/devops-infrastructure/scripts/health-report.sh << 'EOF'
#!/bin/bash

# Infrastructure Health Report Generator
set -e

REPORT_DATE=$(date +"%Y-%m-%d")
REPORT_FILE="/tmp/infrastructure-health-report-$REPORT_DATE.md"

cat > $REPORT_FILE << EOF
# Infrastructure Health Report - $REPORT_DATE

## Executive Summary
Generated at: $(date)
Report Period: Last 24 hours

## Cluster Health

### Node Status
\`\`\`
$(kubectl get nodes -o wide)
\`\`\`

### Resource Utilization
\`\`\`
$(kubectl top nodes)
\`\`\`

### Pod Status Summary
\`\`\`
$(kubectl get pods --all-namespaces | grep -E "(Running|Pending|Failed|Error)" | awk '{print $4}' | sort | uniq -c)
\`\`\`

## Application Health

### Deployment Status
\`\`\`
$(kubectl get deployments --all-namespaces)
\`\`\`

### Failed Pods (if any)
\`\`\`
$(kubectl get pods --all-namespaces --field-selector=status.phase=Failed)
\`\`\`

### HPA Status
\`\`\`
$(kubectl get hpa --all-namespaces)
\`\`\`

## Security Status

### Pod Security Policy Violations
\`\`\`
$(kubectl get events --all-namespaces | grep -i "security\|policy" | head -10)
\`\`\`

### Certificate Status
\`\`\`
$(kubectl get certificates --all-namespaces)
\`\`\`

## Cost Summary

### Resource Requests vs Limits
\`\`\`
$(kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.status.phase=="Running") | "\(.metadata.namespace)/\(.metadata.name): CPU Req: \(.spec.containers[0].resources.requests.cpu // "none"), Mem Req: \(.spec.containers[0].resources.requests.memory // "none")"')
\`\`\`

## Backup Status

### Velero Backup Status
\`\`\`
$(velero backup get | head -10)
\`\`\`

### Latest Backup Results
\`\`\`
$(velero backup describe $(velero backup get -o name | head -1 | cut -d'/' -f2) | grep -E "(Status|Started|Completed)")
\`\`\`

## Alerts Summary

### Active Alerts (Last 24h)
\`\`\`
$(curl -s "http://kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local:9093/api/v1/alerts" | jq -r '.data[] | select(.status.state=="firing") | "\(.labels.alertname): \(.labels.severity)"' | sort | uniq -c)
\`\`\`

## Performance Metrics

### Top Resource Consuming Pods
\`\`\`
$(kubectl top pods --all-namespaces --sort-by=cpu | head -10)
\`\`\`

## Recommendations

EOF

# Add recommendations based on findings
echo "### Current Issues" >> $REPORT_FILE

# Check for pods without resource limits
NO_LIMITS=$(kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.status.phase=="Running") | select(.spec.containers[0].resources.limits == null) | "\(.metadata.namespace)/\(.metadata.name)"' | wc -l)
if [ $NO_LIMITS -gt 0 ]; then
    echo "- $NO_LIMITS pods running without resource limits" >> $REPORT_FILE
fi

# Check for high CPU usage
HIGH_CPU_NODES=$(kubectl top nodes --no-headers | awk '$3 > 80 {count++} END {print count+0}')
if [ $HIGH_CPU_NODES -gt 0 ]; then
    echo "- $HIGH_CPU_NODES nodes with high CPU usage (>80%)" >> $REPORT_FILE
fi

# Check for failed pods
FAILED_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase=Failed --no-headers | wc -l)
if [ $FAILED_PODS -gt 0 ]; then
    echo "- $FAILED_PODS failed pods need investigation" >> $REPORT_FILE
fi

echo "" >> $REPORT_FILE
echo "### Optimization Opportunities" >> $REPORT_FILE
echo "- Review VPA recommendations for resource optimization" >> $REPORT_FILE
echo "- Consider implementing HPA for variable workloads" >> $REPORT_FILE
echo "- Evaluate spot instance usage for cost savings" >> $REPORT_FILE

echo "Report generated: $REPORT_FILE"

# Send to Slack if webhook configured
if [ ! -z "$SLACK_WEBHOOK_URL" ]; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"📊 Daily Infrastructure Health Report generated for $REPORT_DATE\"}" \
        $SLACK_WEBHOOK_URL
fi
EOF

chmod +x ~/devops-infrastructure/scripts/health-report.sh

# 12.2.2 Automated health report CronJob
cat > health-report-cronjob.yaml << 'EOF'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: infrastructure-health-report
  namespace: monitoring
spec:
  schedule: "0 8 * * *"  # Daily at 8 AM
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: health-reporter
          containers:
          - name: reporter
            image: bitnami/kubectl:latest
            command:
            - /bin/bash
            - -c
            - |
              # Install required tools
              apt-get update && apt-get install -y curl jq
              
              # Generate report
              /scripts/health-report.sh
              
              # Upload to S3 if configured
              if [ ! -z "$S3_BUCKET" ]; then
                  aws s3 cp /tmp/infrastructure-health-report-*.md s3://$S3_BUCKET/reports/
              fi
            env:
            - name: S3_BUCKET
              value: "mycompany-reports"
            - name: SLACK_WEBHOOK_URL
              valueFrom:
                secretKeyRef:
                  name: slack-webhook
                  key: url
            volumeMounts:
            - name: scripts
              mountPath: /scripts
            resources:
              requests:
                memory: "128Mi"
                cpu: "100m"
              limits:
                memory: "256Mi"
                cpu: "200m"
          volumes:
          - name: scripts
            configMap:
              name: health-report-scripts
              defaultMode: 0755
          restartPolicy: OnFailure
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: health-reporter
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/health-reporter-role
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: health-reporter
rules:
- apiGroups: [""]
  resources: ["nodes", "pods", "services", "events"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list"]
- apiGroups: ["autoscaling"]
  resources: ["horizontalpodautoscalers"]
  verbs: ["get", "list"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["nodes", "pods"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: health-reporter
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: health-reporter
subjects:
- kind: ServiceAccount
  name: health-reporter
  namespace: monitoring
EOF

# ConfigMap for scripts
kubectl create configmap health-report-scripts \
  --from-file=health-report.sh=~/devops-infrastructure/scripts/health-report.sh \
  -n monitoring

kubectl apply -f health-report-cronjob.yaml
```

### 🎓 **12.3 Training and Knowledge Transfer**

```bash
# 12.3.1 Training curriculum
cat > ~/devops-infrastructure/docs/training-curriculum.md << 'EOF'
# DevOps Team Training Curriculum

## Week 1: Fundamentals

### Day 1-2: Kubernetes Basics
- **Topics**: Pods, Services, Deployments, ConfigMaps, Secrets
- **Hands-on**: Deploy sample application
- **Assessment**: Create multi-tier application deployment

### Day 3-4: Infrastructure as Code
- **Topics**: Terraform basics, AWS resources, State management
- **Hands-on**: Create VPC and EKS cluster
- **Assessment**: Deploy complete infrastructure

### Day 5: CI/CD Fundamentals
- **Topics**: Jenkins, Pipeline as Code, Docker
- **Hands-on**: Create build pipeline
- **Assessment**: End-to-end deployment pipeline

## Week 2: Advanced Topics

### Day 1-2: GitOps and Progressive Delivery
- **Topics**: ArgoCD, Argo Rollouts, Canary deployments
- **Hands-on**: Setup GitOps workflow
- **Assessment**: Implement progressive delivery

### Day 3: Monitoring and Observability
- **Topics**: Prometheus, Grafana, Jaeger, Log analysis
- **Hands-on**: Create custom dashboards
- **Assessment**: End-to-end observability setup

### Day 4: Security Best Practices
- **Topics**: Vault, RBAC, Network Policies, Image scanning
- **Hands-on**: Implement security controls
- **Assessment**: Security audit and remediation

### Day 5: Troubleshooting and Operations
- **Topics**: Debugging techniques, Performance tuning, Incident response
- **Hands-on**: Simulate and resolve incidents
- **Assessment**: Handle real-world scenarios

## Ongoing Learning

### Monthly Topics
- **Month 1**: Cost optimization and resource management
- **Month 2**: Advanced networking and service mesh
- **Month 3**: Disaster recovery and backup strategies
- **Month 4**: Chaos engineering and reliability
- **Month 5**: Multi-cluster and multi-cloud strategies
- **Month 6**: Advanced security and compliance

### Certification Paths
1. **AWS Certified DevOps Engineer**
2. **Certified Kubernetes Administrator (CKA)**
3. **Certified Kubernetes Security Specialist (CKS)**
4. **HashiCorp Certified: Terraform Associate**

## Lab Exercises

### Exercise 1: Application Deployment
```bash
# Deploy sample application with monitoring
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: training-app
  namespace: training
spec:
  replicas: 3
  selector:
    matchLabels:
      app: training-app
  template:
    metadata:
      labels:
        app: training-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
EOF
```

### Exercise 2: Troubleshooting Scenarios
1. **Pod CrashLoopBackOff**
2. **Service discovery issues**
3. **Resource exhaustion**
4. **Network connectivity problems**
5. **Storage mounting failures**

### Exercise 3: Performance Testing
```bash
# Setup load testing
kubectl apply -f - <<EOF
apiVersion: k6.io/v1alpha1
kind: K6
metadata:
  name: training-load-test
  namespace: training
spec:
  parallelism: 2
  script:
    configMap:
      name: training-scripts
      file: basic-test.js
EOF
```

## Knowledge Check Questions

### Kubernetes
1. Explain the difference between Deployment and StatefulSet
2. How do you troubleshoot a pod stuck in Pending state?
3. What are the different types of Services in Kubernetes?
4. How do resource requests and limits work?

### Infrastructure
1. Explain Terraform state management
2. How do you handle secrets in infrastructure code?
3. What are the best practices for AWS resource tagging?
4. How do you implement blue-green deployments?

### Monitoring
1. What are the four golden signals of monitoring?
2. How do you set up custom metrics in Prometheus?
3. Explain the difference between metrics, logs, and traces
4. How do you create effective alerting rules?

### Security
1. What is the principle of least privilege?
2. How do you implement network segmentation in Kubernetes?
3. Explain the role of service accounts and RBAC
4. What are the security best practices for container images?

## Practical Assessments

### Assessment 1: Deploy Production-Ready Application
- Set up complete infrastructure with Terraform
- Deploy application with proper security context
- Implement monitoring and alerting
- Set up automated backups
- Document deployment process

### Assessment 2: Incident Response Simulation
- Scenario: Database connectivity issues
- Task: Diagnose and resolve the problem
- Evaluation: Time to resolution, troubleshooting approach
- Documentation: Post-incident report

### Assessment 3: Performance Optimization
- Given: Application with performance issues
- Task: Identify bottlenecks and optimize
- Tools: Use monitoring data and profiling
- Deliverable: Performance improvement plan

## Resources

### Documentation
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)

### Training Platforms
- [A Cloud Guru](https://acloud.guru/)
- [Linux Academy](https://linuxacademy.com/)
- [Katacoda](https://katacoda.com/)
- [Play with Kubernetes](https://labs.play-with-k8s.com/)

### Books
- "Kubernetes in Action" by Marko Lukša
- "Terraform: Up & Running" by Yevgeniy Brikman
- "Site Reliability Engineering" by Google
- "The DevOps Handbook" by Gene Kim
EOF

# 12.3.2 Knowledge base setup
cat > ~/devops-infrastructure/scripts/setup-knowledge-base.sh << 'EOF'
#!/bin/bash

# Knowledge Base Setup Script
set -e

echo "📚 Setting up team knowledge base..."

# Create knowledge base structure
mkdir -p ~/devops-infrastructure/docs/{architecture,runbooks,tutorials,troubleshooting,best-practices}

# Architecture documentation
echo "Creating architecture documentation..."
cat > ~/devops-infrastructure/docs/architecture/README.md << 'ARCH_EOF'
# Architecture Documentation

## Overview
This directory contains all architecture-related documentation.

## Contents
- `system-overview.md` - High-level system architecture
- `data-flow.md` - Data flow diagrams and explanations
- `security-architecture.md` - Security design and controls
- `networking.md` - Network architecture and routing
- `disaster-recovery.md` - DR architecture and procedures

## Diagrams
All diagrams are created using Mermaid and can be viewed in GitHub or VS Code with the Mermaid extension.
ARCH_EOF

# Runbooks directory
echo "Creating runbooks..."
cat > ~/devops-infrastructure/docs/runbooks/README.md << 'RUN_EOF'
# Operational Runbooks

## Purpose
Step-by-step procedures for common operational tasks and incident response.

## Runbook Categories
- `incident-response/` - Emergency response procedures
- `maintenance/` - Scheduled maintenance procedures
- `deployment/` - Deployment and rollback procedures
- `monitoring/` - Monitoring and alerting procedures

## Runbook Template
Each runbook should include:
1. Purpose and scope
2. Prerequisites
3. Step-by-step procedures
4. Verification steps
5. Rollback procedures
6. Post-completion tasks
RUN_EOF

# Create searchable index
echo "Creating searchable documentation index..."
cat > ~/devops-infrastructure/scripts/generate-docs-index.sh << 'INDEX_EOF'
#!/bin/bash

# Generate searchable documentation index
echo "# Documentation Index" > ~/devops-infrastructure/docs/INDEX.md
echo "Generated on: $(date)" >> ~/devops-infrastructure/docs/INDEX.md
echo "" >> ~/devops-infrastructure/docs/INDEX.md

find ~/devops-infrastructure/docs -name "*.md" -not -name "INDEX.md" | while read file; do
    echo "## $(basename "$file" .md)" >> ~/devops-infrastructure/docs/INDEX.md
    echo "**Path:** $file" >> ~/devops-infrastructure/docs/INDEX.md
    echo "" >> ~/devops-infrastructure/docs/INDEX.md
    # Extract first paragraph as summary
    head -10 "$file" | grep -E "^[A-Za-z]" | head -1 >> ~/devops-infrastructure/docs/INDEX.md
    echo "" >> ~/devops-infrastructure/docs/INDEX.md
done

echo "Documentation index generated!"
INDEX_EOF

chmod +x ~/devops-infrastructure/scripts/generate-docs-index.sh

echo "✅ Knowledge base structure created!"
echo "Run ~/devops-infrastructure/scripts/generate-docs-index.sh to create searchable index"
EOF

chmod +x ~/devops-infrastructure/scripts/setup-knowledge-base.sh
./~/devops-infrastructure/scripts/setup-knowledge-base.sh
```

---
