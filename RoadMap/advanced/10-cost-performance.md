---
description: "Faz 10 (Gün 23-24): Maliyet optimizasyonu ve performans; AWS Cost and Usage Report kurulumu, S3 bucket ve maliyet raporları için bucket policy ayarları."
---
# 📈 **PHASE 10: COST OPTIMIZATION & PERFORMANCE** (Gün 23-24)

### 💰 **11.1 Cost Monitoring Setup**

```bash
# 11.1.1 AWS Cost and Usage Report setup
cat > ~/devops-infrastructure/scripts/setup-cost-monitoring.sh << 'EOF'
#!/bin/bash

# AWS Cost Monitoring Setup Script
set -e

BUCKET_NAME="mycompany-cost-reports-$(openssl rand -hex 4)"
REGION="eu-west-1"

# Create S3 bucket for cost reports
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Bucket policy for AWS Cost and Usage Reports
cat > cost-bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "billingreports.amazonaws.com"
            },
            "Action": [
                "s3:GetBucketAcl",
                "s3:GetBucketPolicy"
            ],
            "Resource": "arn:aws:s3:::$BUCKET_NAME"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "billingreports.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://cost-bucket-policy.json

echo "Cost monitoring S3 bucket created: $BUCKET_NAME"
echo "Configure Cost and Usage Report in AWS Console:"
echo "https://console.aws.amazon.com/billing/home#/reports"
rm cost-bucket-policy.json
EOF

chmod +x ~/devops-infrastructure/scripts/setup-cost-monitoring.sh
./~/devops-infrastructure/scripts/setup-cost-monitoring.sh

# 11.1.2 Kubecost kurulumu
helm repo add kubecost https://kubecost.github.io/cost-analyzer/
helm repo update

cat > kubecost-values.yaml << 'EOF'
global:
  prometheus:
    fqdn: http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090
    enabled: false
  grafana:
    fqdn: http://kube-prometheus-stack-grafana.monitoring.svc.cluster.local:80
    enabled: false

kubecostFrontend:
  image: "kubecost/frontend"
  resources:
    requests:
      cpu: "10m"
      memory: "55Mi"
    limits:
      cpu: "100m"
      memory: "256Mi"

kubecost:
  image: "kubecost/server"
  resources:
    requests:
      cpu: "100m"
      memory: "55Mi"
    limits:
      cpu: "200m"
      memory: "256Mi"

kubecostModel:
  image: "kubecost/cost-model"
  resources:
    requests:
      cpu: "200m"
      memory: "55Mi"
    limits:
      cpu: "800m"
      memory: "256Mi"

ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: kubecost.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: kubecost-tls
      hosts:
        - kubecost.yourdomain.com

persistentVolume:
  enabled: true
  storageClass: gp3
  size: 32Gi

nodeSelector: {}
tolerations: []
affinity: {}

service:
  type: ClusterIP
  port: 9090
  targetPort: 9090
EOF

kubectl create namespace kubecost
helm install kubecost kubecost/cost-analyzer \
  --namespace kubecost \
  --values kubecost-values.yaml

# 11.1.3 Resource recommendation script
cat > ~/devops-infrastructure/scripts/resource-recommendations.sh << 'EOF'
#!/bin/bash

# Resource Recommendations Script
set -e

echo "📊 Generating resource recommendations..."

# VPA recommendations
echo "=== VPA Recommendations ==="
kubectl get vpa --all-namespaces -o custom-columns=\
NAMESPACE:.metadata.namespace,\
NAME:.metadata.name,\
MODE:.spec.updatePolicy.updateMode,\
CPU_TARGET:.status.recommendation.containerRecommendations[0].target.cpu,\
MEMORY_TARGET:.status.recommendation.containerRecommendations[0].target.memory

# Top resource consuming pods
echo "=== Top CPU Consuming Pods ==="
kubectl top pods --all-namespaces --sort-by=cpu | head -10

echo "=== Top Memory Consuming Pods ==="
kubectl top pods --all-namespaces --sort-by=memory | head -10

# Unused resources
echo "=== Pods with Low Resource Utilization ==="
kubectl get pods --all-namespaces -o json | \
jq -r '.items[] | select(.status.phase=="Running") | 
    .metadata.namespace + "/" + .metadata.name + " - " + 
    (.spec.containers[0].resources.requests.cpu // "no-limit") + " CPU, " +
    (.spec.containers[0].resources.requests.memory // "no-limit") + " Memory"'

# HPA status
echo "=== HPA Status ==="
kubectl get hpa --all-namespaces

echo "📋 Recommendations:"
echo "1. Check VPA recommendations for right-sizing"
echo "2. Set resource requests/limits for pods without them"
echo "3. Consider HPA for variable workloads"
echo "4. Use VPA in recommendation mode first"
EOF

chmod +x ~/devops-infrastructure/scripts/resource-recommendations.sh
```

### ⚡ **11.2 Performance Optimization**

```bash
# 11.2.1 Vertical Pod Autoscaler setup
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler/
./hack/vpa-install.sh
cd ~/devops-infrastructure

# 11.2.2 VPA example configurations
cat > vpa-examples.yaml << 'EOF'
# VPA for sample app (recommendation mode)
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: sample-app-vpa
  namespace: dev
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample-app
  updatePolicy:
    updateMode: "Off"  # Recommendation only
  resourcePolicy:
    containerPolicies:
    - containerName: app
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 1000m
        memory: 1Gi
      controlledResources: ["cpu", "memory"]
---
# VPA for monitoring stack (auto mode)
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
      name: kube-prometheus-stack-prometheus
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: prometheus
      minAllowed:
        cpu: 500m
        memory: 1Gi
      maxAllowed:
        cpu: 4000m
        memory: 8Gi
      controlledResources: ["cpu", "memory"]
EOF

kubectl apply -f vpa-examples.yaml

# 11.2.3 KEDA (Event-driven autoscaling) setup
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

helm install keda kedacore/keda \
  --namespace keda \
  --create-namespace

# 11.2.4 KEDA ScaledObject example (Redis queue)
cat > keda-redis-scaler.yaml << 'EOF'
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: redis-scaledobject
  namespace: dev
spec:
  scaleTargetRef:
    name: worker-deployment
  minReplicaCount: 1
  maxReplicaCount: 10
  triggers:
  - type: redis
    metadata:
      address: redis.dev.svc.cluster.local:6379
      listName: job_queue
      listLength: '5'
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: prometheus-scaledobject
  namespace: dev
spec:
  scaleTargetRef:
    name: sample-app
  minReplicaCount: 2
  maxReplicaCount: 20
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090
      metricName: http_requests_per_second
      threshold: '100'
      query: sum(rate(http_requests_total{job="sample-app"}[1m]))
EOF

kubectl apply -f keda-redis-scaler.yaml

# 11.2.5 Performance monitoring dashboard
cat > performance-monitoring.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: performance-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  performance-dashboard.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Application Performance Monitoring",
        "tags": ["performance", "apm"],
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Request Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "sum(rate(http_requests_total[5m])) by (service)",
                "legendFormat": "{{service}}"
              }
            ]
          },
          {
            "id": 2,
            "title": "Response Time",
            "type": "graph",
            "targets": [
              {
                "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))",
                "legendFormat": "95th percentile - {{service}}"
              }
            ]
          },
          {
            "id": 3,
            "title": "Error Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "sum(rate(http_requests_total{status=~'5..'}[5m])) by (service) / sum(rate(http_requests_total[5m])) by (service)",
                "legendFormat": "Error rate - {{service}}"
              }
            ]
          }
        ],
        "time": {
          "from": "now-1h",
          "to": "now"
        },
        "refresh": "30s"
      }
    }
EOF

kubectl apply -f performance-monitoring.yaml
```

### 🧪 **11.3 Load Testing & Performance Validation**

```bash
# 11.3.1 K6 load testing setup
cat > load-testing/k6-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: k6-scripts
  namespace: dev
data:
  load-test.js: |
    import http from 'k6/http';
    import { check, sleep } from 'k6';
    import { Rate } from 'k6/metrics';

    export let errorRate = new Rate('errors');

    export let options = {
      stages: [
        { duration: '2m', target: 10 }, // Ramp up
        { duration: '5m', target: 100 }, // Stay at 100 users
        { duration: '2m', target: 200 }, // Ramp up to 200 users
        { duration: '5m', target: 200 }, // Stay at 200 users
        { duration: '2m', target: 0 }, // Ramp down
      ],
      thresholds: {
        http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
        http_req_failed: ['rate<0.05'], // Error rate under 5%
        errors: ['rate<0.1'], // Custom error rate under 10%
      },
    };

    export default function() {
      let response = http.get('https://app-dev.yourdomain.com/api/health');
      
      check(response, {
        'status is 200': (r) => r.status === 200,
        'response time < 500ms': (r) => r.timings.duration < 500,
      }) || errorRate.add(1);
      
      sleep(1);
    }

  stress-test.js: |
    import http from 'k6/http';
    import { check } from 'k6';

    export let options = {
      stages: [
        { duration: '1m', target: 50 },
        { duration: '1m', target: 100 },
        { duration: '1m', target: 200 },
        { duration: '1m', target: 500 },
        { duration: '2m', target: 1000 }, // Stress level
        { duration: '2m', target: 0 },
      ],
    };

    export default function() {
      let response = http.get('https://app-dev.yourdomain.com/api/users');
      check(response, {
        'status is 200': (r) => r.status === 200,
      });
    }
EOF

kubectl apply -f load-testing/

# 11.3.2 K6 operator kurulumu
kubectl apply -f https://github.com/grafana/k6-operator/releases/latest/download/bundle.yaml

# 11.3.3 Load test job
cat > load-test-job.yaml << 'EOF'
apiVersion: k6.io/v1alpha1
kind: K6
metadata:
  name: load-test
  namespace: dev
spec:
  parallelism: 4
  script:
    configMap:
      name: k6-scripts
      file: load-test.js
  separate: true
  runner:
    image: grafana/k6:latest
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 256Mi
    env:
    - name: K6_PROMETHEUS_RW_SERVER_URL
      value: http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090/api/v1/write
    - name: K6_PROMETHEUS_RW_TREND_AS_NATIVE_HISTOGRAM
      value: "true"
EOF

# Load test çalıştır
kubectl apply -f load-test-job.yaml
kubectl logs -f job/load-test-1 -n dev

# 11.3.4 Automated performance test pipeline
cat > ~/devops-infrastructure/jenkins/performance-test-pipeline.groovy << 'EOF'
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
              - name: k6
                image: grafana/k6:latest
                command:
                - cat
                tty: true
            """
        }
    }
    
    parameters {
        choice(
            name: 'TEST_TYPE',
            choices: ['load-test', 'stress-test', 'spike-test'],
            description: 'Type of performance test to run'
        )
        string(
            name: 'TARGET_URL',
            defaultValue: 'https://app-staging.yourdomain.com',
            description: 'Target URL for testing'
        )
        string(
            name: 'DURATION',
            defaultValue: '5m',
            description: 'Test duration'
        )
    }
    
    stages {
        stage('Deploy Test Config') {
            steps {
                container('kubectl') {
                    sh '''
                        cat > k6-test-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: k6-test-config-${BUILD_NUMBER}
  namespace: dev
data:
  test.js: |
    import http from 'k6/http';
    import { check, sleep } from 'k6';
    
    export let options = {
      duration: '${DURATION}',
      vus: 50,
      thresholds: {
        http_req_duration: ['p(95)<1000'],
        http_req_failed: ['rate<0.05'],
      },
    };
    
    export default function() {
      let response = http.get('${TARGET_URL}/health');
      check(response, {
        'status is 200': (r) => r.status === 200,
      });
      sleep(1);
    }
EOF
                        kubectl apply -f k6-test-config.yaml
                    '''
                }
            }
        }
        
        stage('Run Performance Test') {
            steps {
                container('kubectl') {
                    sh '''
                        cat > k6-job.yaml << EOF
apiVersion: k6.io/v1alpha1
kind: K6
metadata:
  name: perf-test-${BUILD_NUMBER}
  namespace: dev
spec:
  parallelism: 2
  script:
    configMap:
      name: k6-test-config-${BUILD_NUMBER}
      file: test.js
  separate: true
EOF
                        kubectl apply -f k6-job.yaml
                        
                        # Wait for test completion
                        kubectl wait --for=condition=complete job/perf-test-${BUILD_NUMBER}-1 -n dev --timeout=600s
                        
                        # Get test results
                        kubectl logs job/perf-test-${BUILD_NUMBER}-1 -n dev
                    '''
                }
            }
        }
        
        stage('Analyze Results') {
            steps {
                container('kubectl') {
                    sh '''
                        # Extract test metrics and validate against thresholds
                        TEST_RESULTS=$(kubectl logs job/perf-test-${BUILD_NUMBER}-1 -n dev | grep -E "(http_req_duration|http_req_failed)")
                        echo "Test Results: $TEST_RESULTS"
                        
                        # Check if test passed thresholds
                        if kubectl logs job/perf-test-${BUILD_NUMBER}-1 -n dev | grep -q "✓"; then
                            echo "Performance test PASSED"
                        else
                            echo "Performance test FAILED"
                            exit 1
                        fi
                    '''
                }
            }
        }
    }
    
    post {
        always {
            container('kubectl') {
                sh '''
                    # Cleanup test resources
                    kubectl delete configmap k6-test-config-${BUILD_NUMBER} -n dev || true
                    kubectl delete k6 perf-test-${BUILD_NUMBER} -n dev || true
                '''
            }
        }
        success {
            slackSend(
                channel: '#performance',
                color: 'good',
                message: "✅ Performance test passed for ${params.TARGET_URL}"
            )
        }
        failure {
            slackSend(
                channel: '#performance',
                color: 'danger',
                message: "❌ Performance test failed for ${params.TARGET_URL}"
            )
        }
    }
}
EOF
```

### 📊 **11.4 Cost Optimization Scripts**

```bash
# 11.4.1 Resource rightsizing script
cat > ~/devops-infrastructure/scripts/cost-optimization.sh << 'EOF'
#!/bin/bash

# Cost Optimization Analysis Script
set -e

echo "💰 AWS Cost Optimization Analysis"
echo "=================================="

# 1. Unused EBS volumes
echo "🔍 Checking for unused EBS volumes..."
aws ec2 describe-volumes \
    --filters Name=status,Values=available \
    --query 'Volumes[*].[VolumeId,Size,VolumeType,CreateTime]' \
    --output table

# 2. Unattached Elastic IPs
echo "🔍 Checking for unattached Elastic IPs..."
aws ec2 describe-addresses \
    --query 'Addresses[?AssociationId==null].[PublicIp,AllocationId]' \
    --output table

# 3. Old snapshots (older than 30 days)
echo "🔍 Checking for old snapshots..."
CUTOFF_DATE=$(date -d '30 days ago' --iso-8601)
aws ec2 describe-snapshots \
    --owner-ids self \
    --query "Snapshots[?StartTime<='$CUTOFF_DATE'].[SnapshotId,StartTime,VolumeSize]" \
    --output table

# 4. Right-sizing recommendations
echo "🔍 Generating right-sizing recommendations..."
aws ce get-rightsizing-recommendation \
    --service "EC2-Instance" \
    --query 'RightsizingRecommendations[*].[CurrentInstance.InstanceName,CurrentInstance.InstanceType,RightsizingType,TargetInstances[0].EstimatedMonthlySavings.Amount]' \
    --output table

# 5. Reserved Instance recommendations
echo "🔍 Checking Reserved Instance opportunities..."
aws ce get-reservation-purchase-recommendation \
    --service "EC2-Instance" \
    --query 'Recommendations[*].[InstanceDetails.EC2InstanceDetails.InstanceType,InstanceDetails.EC2InstanceDetails.Region,RecommendationDetails.EstimatedMonthlySavingsAmount]' \
    --output table

echo "💡 Cost Optimization Recommendations:"
echo "1. Delete unused EBS volumes"
echo "2. Release unattached Elastic IPs"
echo "3. Delete old snapshots"
echo "4. Implement right-sizing recommendations"
echo "5. Consider Reserved Instances for stable workloads"
EOF

chmod +x ~/devops-infrastructure/scripts/cost-optimization.sh

# 11.4.2 Spot instance integration
cat > spot-instances.yaml << 'EOF'
# Karpenter for spot instances
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: spot-provisioner
spec:
  # Requirements that constrain which nodes will be created
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["spot"]
    - key: kubernetes.io/arch
      operator: In
      values: ["amd64"]
    - key: node.kubernetes.io/instance-type
      operator: In
      values: ["t3.medium", "t3.large", "m5.large", "m5.xlarge"]
  
  # Provisioned nodes will have these taints
  taints:
    - key: spot
      value: "true"
      effect: NoSchedule
  
  # Resource limits constrain the total size of the cluster
  limits:
    resources:
      cpu: 1000
      memory: 1000Gi
  
  # Deprovisioning configuration
  ttlSecondsAfterEmpty: 30
  
  # Provider-specific configuration
  providerRef:
    name: spot-nodepool
---
apiVersion: karpenter.k8s.aws/v1alpha1
kind: AWSNodePool
metadata:
  name: spot-nodepool
spec:
  amiFamily: AL2
  subnetSelector:
    karpenter.sh/discovery: "mycompany-dev-eks"
  securityGroupSelector:
    karpenter.sh/discovery: "mycompany-dev-eks"
  instanceProfile: "KarpenterNodeInstanceProfile"
  
  # Spot instance configuration
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["spot"]
    - key: node.kubernetes.io/instance-type
      operator: In
      values: ["t3.medium", "t3.large", "m5.large"]
  
  userData: |
    #!/bin/bash
    /etc/eks/bootstrap.sh mycompany-dev-eks
    echo "spot=true" >> /etc/kubernetes/kubelet/kubelet-config.json
EOF

# 11.4.3 Resource quota ve limits
cat > resource-quotas.yaml << 'EOF'
# Development namespace quotas
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    persistentvolumeclaims: "10"
    pods: "20"
    services: "10"
    secrets: "20"
    configmaps: "20"
---
# Staging namespace quotas
apiVersion: v1
kind: ResourceQuota
metadata:
  name: staging-quota
  namespace: staging
spec:
  hard:
    requests.cpu: "8"
    requests.memory: 16Gi
    limits.cpu: "16"
    limits.memory: 32Gi
    persistentvolumeclaims: "15"
    pods: "30"
    services: "15"
---
# Production namespace quotas
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: production
spec:
  hard:
    requests.cpu: "20"
    requests.memory: 40Gi
    limits.cpu: "40"
    limits.memory: 80Gi
    persistentvolumeclaims: "25"
    pods: "50"
    services: "25"
---
# Limit ranges for all namespaces
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: dev
spec:
  limits:
  - default:
      cpu: "200m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    type: Container
  - max:
      cpu: "2"
      memory: "4Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
    type: Container
EOF

kubectl apply -f resource-quotas.yaml
```

---
