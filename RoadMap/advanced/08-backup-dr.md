---
description: "Faz 8 (Gün 19-20): Backup ve felaket kurtarma; Velero ile Kubernetes yedekleme, S3 bucket oluşturma ve IAM rolüne dayalı bucket policy yapılandırması."
---
# 🗄️ **PHASE 8: BACKUP & DISASTER RECOVERY** (Gün 19-20)

### 💾 **9.1 Velero Backup Setup**

```bash
# 9.1.1 AWS S3 bucket oluştur
BACKUP_BUCKET="mycompany-k8s-backups-$(openssl rand -hex 4)"
aws s3 mb s3://$BACKUP_BUCKET --region eu-west-1

# S3 bucket policy
cat > backup-bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VeleroBackupAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/velero-role"
            },
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": "arn:aws:s3:::$BACKUP_BUCKET/*"
        },
        {
            "Sid": "VeleroBackupList",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/velero-role"
            },
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::$BACKUP_BUCKET"
        }
    ]
}
EOF

# IAM policy için Velero permissions
cat > velero-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::BUCKET-NAME/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::BUCKET-NAME"
            ]
        }
    ]
}
EOF

sed -i "s/BUCKET-NAME/$BACKUP_BUCKET/g" velero-policy.json

# IAM policy oluştur
aws iam create-policy \
    --policy-name VeleroBackupPolicy \
    --policy-document file://velero-policy.json

# Service account için trust policy
cat > velero-trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::ACCOUNT-ID:oidc-provider/OIDC-URL"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "OIDC-URL:sub": "system:serviceaccount:velero:velero",
                    "OIDC-URL:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
EOF

# OIDC provider URL'ini al
OIDC_URL=$(aws eks describe-cluster --name mycompany-dev-eks --query "cluster.identity.oidc.issuer" --output text | sed 's|https://||')
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

sed -i "s/ACCOUNT-ID/$ACCOUNT_ID/g" velero-trust-policy.json
sed -i "s/OIDC-URL/$OIDC_URL/g" velero-trust-policy.json

# IAM role oluştur
aws iam create-role \
    --role-name velero-role \
    --assume-role-policy-document file://velero-trust-policy.json

# Policy'yi role'e attach et
aws iam attach-role-policy \
    --role-arn arn:aws:iam::$ACCOUNT_ID:role/velero-role \
    --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/VeleroBackupPolicy

# 9.1.2 Velero CLI kurulumu
wget https://github.com/vmware-tanzu/velero/releases/download/v1.12.0/velero-v1.12.0-linux-amd64.tar.gz
tar -xzf velero-v1.12.0-linux-amd64.tar.gz
sudo mv velero-v1.12.0-linux-amd64/velero /usr/local/bin/
rm -rf velero-v1.12.0-linux-amd64*

# 9.1.3 Velero kurulumu
cat > velero-values.yaml << EOF
configuration:
  backupStorageLocation:
  - name: aws
    provider: aws
    bucket: $BACKUP_BUCKET
    config:
      region: eu-west-1
  volumeSnapshotLocation:
  - name: aws
    provider: aws
    config:
      region: eu-west-1

credentials:
  useSecret: false

serviceAccount:
  server:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::$ACCOUNT_ID:role/velero-role

initContainers:
- name: velero-plugin-for-aws
  image: velero/velero-plugin-for-aws:v1.8.0
  volumeMounts:
  - mountPath: /target
    name: plugins

resources:
  requests:
    cpu: 500m
    memory: 128Mi
  limits:
    cpu: 1000m
    memory: 512Mi

nodeAgent:
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1024Mi

schedules:
  daily-backup:
    disabled: false
    schedule: "0 2 * * *"
    template:
      includedNamespaces:
      - dev
      - staging
      - production
      - monitoring
      - vault
      excludedResources:
      - events
      - events.events.k8s.io
      storageLocation: aws
      ttl: 720h0m0s
      snapshotVolumes: true

  weekly-backup:
    disabled: false
    schedule: "0 3 * * 0"
    template:
      includedNamespaces:
      - dev
      - staging
      - production
      - monitoring
      - vault
      excludedResources:
      - events
      - events.events.k8s.io
      storageLocation: aws
      ttl: 2160h0m0s
      snapshotVolumes: true
EOF

helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update

kubectl create namespace velero
helm install velero vmware-tanzu/velero \
  --namespace velero \
  --values velero-values.yaml

# 9.1.4 Manual backup test
velero backup create test-backup --include-namespaces dev
velero backup describe test-backup
velero backup logs test-backup

echo "Backup bucket: $BACKUP_BUCKET"
```

### 🔄 **9.2 Database Backup Strategy**

```bash
# 9.2.1 RDS automated backup script
cat > ~/devops-infrastructure/scripts/rds-backup.sh << 'EOF'
#!/bin/bash

# RDS Backup Script
set -e

DB_IDENTIFIER="mycompany-dev-db"
BACKUP_PREFIX="manual-backup"
REGION="eu-west-1"

# Create manual snapshot
SNAPSHOT_ID="${BACKUP_PREFIX}-$(date +%Y%m%d%H%M%S)"

echo "Creating RDS snapshot: $SNAPSHOT_ID"
aws rds create-db-snapshot \
    --db-instance-identifier $DB_IDENTIFIER \
    --db-snapshot-identifier $SNAPSHOT_ID \
    --region $REGION

# Wait for snapshot completion
echo "Waiting for snapshot completion..."
aws rds wait db-snapshot-completed \
    --db-snapshot-identifier $SNAPSHOT_ID \
    --region $REGION

echo "Snapshot created successfully: $SNAPSHOT_ID"

# List recent snapshots
echo "Recent snapshots:"
aws rds describe-db-snapshots \
    --db-instance-identifier $DB_IDENTIFIER \
    --snapshot-type manual \
    --region $REGION \
    --query 'DBSnapshots[0:5].[DBSnapshotIdentifier,Status,SnapshotCreateTime]' \
    --output table

# Cleanup old manual snapshots (keep last 7)
OLD_SNAPSHOTS=$(aws rds describe-db-snapshots \
    --db-instance-identifier $DB_IDENTIFIER \
    --snapshot-type manual \
    --region $REGION \
    --query 'DBSnapshots[7:].DBSnapshotIdentifier' \
    --output text)

if [ ! -z "$OLD_SNAPSHOTS" ]; then
    echo "Cleaning up old snapshots..."
    for snapshot in $OLD_SNAPSHOTS; do
        echo "Deleting snapshot: $snapshot"
        aws rds delete-db-snapshot \
            --db-snapshot-identifier $snapshot \
            --region $REGION
    done
fi

echo "Backup completed successfully!"
EOF

chmod +x ~/devops-infrastructure/scripts/rds-backup.sh

# 9.2.2 PostgreSQL logical backup (for application data)
cat > ~/devops-infrastructure/scripts/postgres-logical-backup.sh << 'EOF'
#!/bin/bash

# PostgreSQL Logical Backup Script
set -e

# Configuration
DB_HOST="your-rds-endpoint"
DB_NAME="mycompanydb"
DB_USER="admin"
BACKUP_DIR="/tmp/pg-backups"
S3_BUCKET="mycompany-db-logical-backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Get password from Kubernetes secret
DB_PASSWORD=$(kubectl get secret database-secret -n dev -o jsonpath='{.data.password}' | base64 -d)

export PGPASSWORD=$DB_PASSWORD

# Create backup
echo "Creating logical backup..."
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME \
    --verbose \
    --no-password \
    --format=custom \
    --compress=9 \
    --file=$BACKUP_DIR/logical-backup-$DATE.dump

# Upload to S3
echo "Uploading to S3..."
aws s3 cp $BACKUP_DIR/logical-backup-$DATE.dump \
    s3://$S3_BUCKET/logical-backups/logical-backup-$DATE.dump

# Cleanup local file
rm $BACKUP_DIR/logical-backup-$DATE.dump

# Cleanup old S3 backups (keep last 30 days)
echo "Cleaning up old backups..."
aws s3 ls s3://$S3_BUCKET/logical-backups/ \
    --recursive \
    --query "Contents[?LastModified<='$(date -d '30 days ago' --iso-8601)'].Key" \
    --output text | \
    xargs -I {} aws s3 rm s3://$S3_BUCKET/{}

echo "Logical backup completed successfully!"
EOF

chmod +x ~/devops-infrastructure/scripts/postgres-logical-backup.sh

# 9.2.3 CronJob for automated database backups
cat > database-backup-cronjob.yaml << 'EOF'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-logical-backup
  namespace: dev
spec:
  schedule: "0 1 * * *"  # Daily at 1 AM
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: backup-sa
          containers:
          - name: backup
            image: postgres:15-alpine
            env:
            - name: DB_HOST
              value: "your-rds-endpoint"
            - name: DB_NAME
              value: "mycompanydb"
            - name: DB_USER
              value: "admin"
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: database-secret
                  key: password
            - name: S3_BUCKET
              value: "mycompany-db-logical-backups"
            command:
            - /bin/bash
            - -c
            - |
              set -e
              apk add --no-cache aws-cli
              
              DATE=$(date +%Y%m%d_%H%M%S)
              BACKUP_FILE="/tmp/logical-backup-$DATE.dump"
              
              export PGPASSWORD=$DB_PASSWORD
              
              echo "Creating logical backup..."
              pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME \
                  --verbose \
                  --no-password \
                  --format=custom \
                  --compress=9 \
                  --file=$BACKUP_FILE
              
              echo "Uploading to S3..."
              aws s3 cp $BACKUP_FILE s3://$S3_BUCKET/logical-backups/
              
              echo "Backup completed successfully!"
            resources:
              requests:
                memory: "256Mi"
                cpu: "100m"
              limits:
                memory: "512Mi"
                cpu: "200m"
          restartPolicy: OnFailure
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backup-sa
  namespace: dev
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/backup-role
EOF

kubectl apply -f database-backup-cronjob.yaml
```

### 📋 **9.3 Disaster Recovery Runbook**

```bash
# 9.3.1 DR runbook oluştur
cat > ~/devops-infrastructure/docs/disaster-recovery-runbook.md << 'EOF'
# Disaster Recovery Runbook

## Overview
Bu doküman Kubernetes cluster ve RDS veritabanı için disaster recovery prosedürlerini içerir.

## RTO/RPO Targets
- **RTO (Recovery Time Objective)**: 4 saat
- **RPO (Recovery Point Objective)**: 1 saat

## Disaster Scenarios

### 1. Complete Cluster Loss

#### Assessment
```bash
# Cluster durumunu kontrol et
kubectl get nodes
kubectl get pods --all-namespaces

# AWS EKS cluster durumu
aws eks describe-cluster --name mycompany-dev-eks
```

#### Recovery Steps

1. **Yeni cluster oluştur**
```bash
cd ~/devops-infrastructure/terraform/environments/dev
terraform plan -target=module.eks
terraform apply -target=module.eks
```

2. **Velero restore**
```bash
# En son backup'ı listele
velero backup get

# Restore işlemi
velero restore create restore-$(date +%Y%m%d) \
    --from-backup daily-backup-YYYYMMDD
```

3. **Database connectivity kontrol**
```bash
kubectl get secrets database-secret -n dev
kubectl run test-db-connection --rm -i --tty \
    --image=postgres:15-alpine -- \
    psql -h RDS_ENDPOINT -U admin -d mycompanydb
```

### 2. Database Disaster

#### Assessment
```bash
# RDS status kontrol
aws rds describe-db-instances \
    --db-instance-identifier mycompany-dev-db

# Connection test
kubectl run db-test --rm -i --tty \
    --image=postgres:15-alpine -- \
    psql -h RDS_ENDPOINT -U admin -d mycompanydb -c "SELECT 1;"
```

#### Recovery Steps

1. **Point-in-time recovery**
```bash
# Son valid backup time'ı bul
aws rds describe-db-instances \
    --db-instance-identifier mycompany-dev-db \
    --query 'DBInstances[0].LatestRestorableTime'

# Point-in-time restore
aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier mycompany-dev-db \
    --target-db-instance-identifier mycompany-dev-db-recovered \
    --restore-time 2024-XX-XXTXX:XX:XX.000Z
```

2. **Manual snapshot restore**
```bash
# Available snapshots
aws rds describe-db-snapshots \
    --db-instance-identifier mycompany-dev-db

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier mycompany-dev-db-recovered \
    --db-snapshot-identifier manual-backup-YYYYMMDDHHMMSS
```

3. **Application reconnection**
```bash
# Update database endpoint in secrets
kubectl patch secret database-secret -n dev \
    --type='json' \
    -p='[{"op": "replace", "path": "/data/host", "value":"'$(echo NEW_RDS_ENDPOINT | base64 -w 0)'"}]'

# Restart applications
kubectl rollout restart deployment -n dev
```

### 3. Data Corruption

#### Assessment
```bash
# Check for data inconsistencies
kubectl exec -it deployment/backend -n dev -- \
    python manage.py check_data_integrity

# Check database logs
aws rds describe-db-log-files \
    --db-instance-identifier mycompany-dev-db
```

#### Recovery Steps

1. **Identify corruption scope**
```bash
# Analyze affected data
kubectl exec -it deployment/backend -n dev -- \
    python manage.py analyze_corruption
```

2. **Restore from logical backup**
```bash
# Download latest logical backup
aws s3 cp s3://mycompany-db-logical-backups/logical-backups/latest.dump /tmp/

# Restore specific tables
pg_restore -h RDS_ENDPOINT -U admin -d mycompanydb \
    --table=affected_table \
    --clean \
    /tmp/latest.dump
```

## Testing Procedures

### Monthly DR Drill
1. Create test restore in separate namespace
2. Verify data integrity
3. Test application functionality
4. Document lessons learned

### Quarterly Full DR Test
1. Complete environment recreation
2. Full data restore
3. End-to-end testing
4. Performance validation

## Emergency Contacts

- **DevOps Team**: +90-XXX-XXX-XXXX
- **Database Team**: +90-XXX-XXX-XXXX
- **On-call Engineer**: +90-XXX-XXX-XXXX

## Post-Incident Actions

1. **Root Cause Analysis**
   - Document incident timeline
   - Identify failure points
   - Implement preventive measures

2. **Update Procedures**
   - Update runbooks
   - Improve monitoring
   - Enhance alerting

3. **Team Communication**
   - Share lessons learned
   - Update training materials
   - Schedule review meeting
EOF

# 9.3.2 DR test script
cat > ~/devops-infrastructure/scripts/dr-test.sh << 'EOF'
#!/bin/bash

# Disaster Recovery Test Script
set -e

NAMESPACE="dr-test"
BACKUP_NAME="$1"

if [ -z "$BACKUP_NAME" ]; then
    echo "Usage: $0 <backup-name>"
    echo "Available backups:"
    velero backup get
    exit 1
fi

echo "Starting DR test with backup: $BACKUP_NAME"

# Create test namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Restore from backup to test namespace
velero restore create dr-test-$(date +%Y%m%d%H%M%S) \
    --from-backup $BACKUP_NAME \
    --namespace-mappings dev:$NAMESPACE,staging:$NAMESPACE

# Wait for restore completion
echo "Waiting for restore completion..."
sleep 60

# Check restored resources
echo "Checking restored resources..."
kubectl get all -n $NAMESPACE

# Test database connectivity
echo "Testing database connectivity..."
kubectl run db-test -n $NAMESPACE --rm -i --tty \
    --image=postgres:15-alpine -- \
    psql -h $(kubectl get secret database-secret -n $NAMESPACE -o jsonpath='{.data.host}' | base64 -d) \
    -U $(kubectl get secret database-secret -n $NAMESPACE -o jsonpath='{.data.username}' | base64 -d) \
    -d mycompanydb \
    -c "SELECT COUNT(*) FROM information_schema.tables;"

echo "DR test completed successfully!"
echo "Cleanup: kubectl delete namespace $NAMESPACE"
EOF

chmod +x ~/devops-infrastructure/scripts/dr-test.sh
```

---
