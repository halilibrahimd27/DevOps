---
description: "AWS CLI pratik komut notları: profil ve SSO auth, sts assume-role, EC2/S3/IAM işlemleri, query filtreleme ve caller-identity doğrulama örnekleri."
tags:
  - Cheatsheet
  - AWS
  - Security
---
# AWS CLI Cheatsheet

## 🔐 Auth & Profile

```bash
# Configure
aws configure                                      # default profile
aws configure --profile prod
aws configure list
aws configure list-profiles

# SSO (modern, daha güvenli)
aws configure sso
aws sso login --profile prod
aws sso logout

# Profile kullan
export AWS_PROFILE=prod
aws s3 ls --profile prod
aws sts get-caller-identity --profile prod        # ben kimim?

# Assume role
aws sts assume-role \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/<ROLE> \
  --role-session-name my-session

# OIDC token (CI/CD için)
aws sts assume-role-with-web-identity \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/gh-actions-role \
  --role-session-name gh-action \
  --web-identity-token $GITHUB_OIDC_TOKEN
```

## 🌐 Genel Pattern

```bash
# JMESPath ile çıktı filtreleme
aws ec2 describe-instances \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name]' \
  --output table

# Output formatları
--output json | text | table | yaml

# Pagination
aws s3api list-objects-v2 --bucket <BUCKET> --max-items 100 --starting-token <TOKEN>

# Region override
aws ec2 describe-instances --region eu-west-1
export AWS_DEFAULT_REGION=eu-west-1
```

## 💻 EC2

```bash
# Listele (tablo)
aws ec2 describe-instances \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name,InstanceType,PrivateIpAddress]' \
  --output table

# Sadece running'leri al
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId'

# Tag ile filtrele
aws ec2 describe-instances --filters "Name=tag:Environment,Values=prod"

# Start / stop / terminate
aws ec2 start-instances --instance-ids i-1234567890abcdef0
aws ec2 stop-instances --instance-ids i-1234567890abcdef0
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0

# Console screenshot (debug stuck instance)
aws ec2 get-console-screenshot --instance-id i-1234567890abcdef0
aws ec2 get-console-output --instance-id i-1234567890abcdef0 --output text

# AMI listesi
aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-*x86_64*" \
  --query 'sort_by(Images, &CreationDate)[-5:].[ImageId,Name,CreationDate]'

# Volume
aws ec2 describe-volumes --filters Name=status,Values=available    # boşta duranlar
aws ec2 describe-snapshots --owner-ids self --query 'sort_by(Snapshots, &StartTime)[].[SnapshotId,StartTime,VolumeSize,Description]'
```

## 🗄️ S3

```bash
# Bucket listesi
aws s3 ls
aws s3api list-buckets --query 'Buckets[].Name'

# İçerik listele
aws s3 ls s3://<BUCKET>/path/
aws s3 ls s3://<BUCKET>/path/ --recursive --human-readable --summarize

# Copy / sync
aws s3 cp file.txt s3://<BUCKET>/path/
aws s3 cp s3://<BUCKET>/path/file.txt .
aws s3 cp ./dir s3://<BUCKET>/path/ --recursive
aws s3 sync ./dist s3://<BUCKET>/path/ --delete   # delete = hedef'te olup kaynakta olmayanı sil

# Storage class
aws s3 cp big.tar.gz s3://<BUCKET>/archive/ --storage-class GLACIER_IR

# Pre-signed URL
aws s3 presign s3://<BUCKET>/path/file.txt --expires-in 3600

# Bucket policy
aws s3api get-bucket-policy --bucket <BUCKET> | jq -r '.Policy' | jq

# Public erişimi engelle (yeni bucket'larda zaten default)
aws s3api put-public-access-block --bucket <BUCKET> --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Encryption (SSE-S3 default)
aws s3api put-bucket-encryption --bucket <BUCKET> --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Lifecycle (30 gün sonra IA, 90 gün sonra Glacier, 365 gün sonra sil)
aws s3api put-bucket-lifecycle-configuration --bucket <BUCKET> --lifecycle-configuration file://lifecycle.json
```

## 👤 IAM

```bash
# User listesi
aws iam list-users

# Bir kullanıcının policy'leri
aws iam list-attached-user-policies --user-name <USER>
aws iam list-user-policies --user-name <USER>          # inline

# Role'ler
aws iam list-roles --query 'Roles[].RoleName'
aws iam get-role --role-name <ROLE>
aws iam list-attached-role-policies --role-name <ROLE>
aws iam list-role-policies --role-name <ROLE>

# Policy oku
aws iam get-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
aws iam get-policy-version \
  --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/<POLICY> \
  --version-id v1

# Credential report (audit için altın)
aws iam generate-credential-report
aws iam get-credential-report --query 'Content' --output text | base64 -d > report.csv

# Access analyzer (over-permissive policy'leri bul)
aws accessanalyzer list-analyzers
aws accessanalyzer list-findings --analyzer-arn <ARN>
```

## 🔐 Secrets Manager

```bash
# Secret listesi
aws secretsmanager list-secrets --query 'SecretList[].Name'

# Secret oku
aws secretsmanager get-secret-value --secret-id <NAME> --query SecretString --output text
aws secretsmanager get-secret-value --secret-id <NAME> | jq -r '.SecretString' | jq

# Yarat / güncelle
aws secretsmanager create-secret --name <NAME> --secret-string '<VALUE>'
aws secretsmanager update-secret --secret-id <NAME> --secret-string '<VALUE>'
aws secretsmanager put-secret-value --secret-id <NAME> --secret-string file://creds.json

# Rotate
aws secretsmanager rotate-secret --secret-id <NAME>
```

## 🪣 Parameter Store (SSM)

```bash
# Yarat
aws ssm put-parameter --name "/app/db/host" --value "<HOST>" --type String
aws ssm put-parameter --name "/app/db/password" --value "<PWD>" --type SecureString --key-id alias/aws/ssm

# Oku
aws ssm get-parameter --name "/app/db/host" --query 'Parameter.Value' --output text
aws ssm get-parameter --name "/app/db/password" --with-decryption --query 'Parameter.Value' --output text

# Path altındaki tümü
aws ssm get-parameters-by-path --path "/app/" --recursive --with-decryption \
  --query 'Parameters[].[Name,Value]' --output text
```

## 🚪 SSM Session Manager (SSH'siz EC2 erişimi)

```bash
# Plugin kurulumu (bir defa)
# https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# Connect
aws ssm start-session --target i-1234567890abcdef0

# Port forward (DB'ye bastion üzerinden)
aws ssm start-session --target i-1234567890abcdef0 \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<DB_HOST>"],"portNumber":["5432"],"localPortNumber":["5432"]}'

# Komut çalıştır (sshsuz uzaktan)
aws ssm send-command \
  --instance-ids i-1234567890abcdef0 \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["uname -a", "df -h"]' \
  --output json
```

## 🌐 Route 53

```bash
# Hosted zone listesi
aws route53 list-hosted-zones

# Record'ları gör
aws route53 list-resource-record-sets --hosted-zone-id <ZONE_ID>

# Record ekle/güncelle (json ile)
aws route53 change-resource-record-sets --hosted-zone-id <ZONE_ID> --change-batch file://record.json

# DNS propagasyonu doğrula
aws route53 get-change --id <CHANGE_ID>
```

## 📊 CloudWatch

```bash
# Log groups
aws logs describe-log-groups --query 'logGroups[].logGroupName'

# Tail (real-time)
aws logs tail /aws/lambda/my-fn --follow
aws logs tail /aws/lambda/my-fn --since 10m --filter-pattern "ERROR"

# Metric query
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --start-time $(date -u -d '1 hour ago' +%FT%TZ) \
  --end-time $(date -u +%FT%TZ) \
  --period 300 \
  --statistics Average
```

## 💸 Cost Explorer

```bash
# Bu ay
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '1 month ago' +%F),End=$(date +%F) \
  --granularity DAILY \
  --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[].Total.UnblendedCost.Amount' --output text

# Top 10 service
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%F),End=$(date +%F) \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[0].Groups[?Metrics.UnblendedCost.Amount>`100`].[Keys[0],Metrics.UnblendedCost.Amount]' \
  --output table
```

## 🔧 EKS

```bash
# Cluster listesi
aws eks list-clusters

# kubeconfig al
aws eks update-kubeconfig --name <CLUSTER> --region <REGION>
aws eks update-kubeconfig --name <CLUSTER> --alias <SHORT_NAME>

# Versiyon ve update
aws eks describe-cluster --name <CLUSTER> --query 'cluster.version'
aws eks update-cluster-version --name <CLUSTER> --version 1.30
```

## ⚡ Faydalı one-liner'lar

```bash
# Hangi role'le çalışıyorum?
aws sts get-caller-identity

# Tüm region'ları listele
aws ec2 describe-regions --query 'Regions[].RegionName' --output text

# Bütün region'lardaki running EC2'ler
for r in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  echo "=== $r ==="
  aws ec2 describe-instances --region $r \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].[InstanceId,InstanceType]' \
    --output table
done

# Tüm açık (untagged) EBS volume'ları
aws ec2 describe-volumes --filters Name=status,Values=available \
  --query 'Volumes[].[VolumeId,Size,CreateTime]' --output table

# Boşta duran Elastic IP'ler ($$$)
aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].[PublicIp,AllocationId]' --output table

# Tüm cleanup'ı script'le
aws ec2 describe-snapshots --owner-ids self \
  --query "Snapshots[?StartTime<='$(date -d '90 days ago' +%F)'].SnapshotId" \
  --output text | xargs -n1 aws ec2 delete-snapshot --snapshot-id
```

## 🆘 Acil senaryolar

| Sorun | Çözüm |
|---|---|
| `Unable to locate credentials` | `aws configure list`; `AWS_PROFILE` set; `aws sso login` |
| `AccessDenied` ama IAM doğru | Trust policy, MFA, session length, condition keys kontrol |
| Yüksek fatura ay sonu | Cost Explorer + Anomaly Detector + tagging audit |
| EC2 SSH erişimi yok | SSM Session Manager kullan (instance role gerekli) |
| S3 bucket yanlışlıkla public | `aws s3api put-public-access-block` ile kapat |
| Region farkı yüzünden resource görmüyor | `--region` ekle veya `AWS_DEFAULT_REGION` set et |

---

> 🎓 **Öğrenme Patikası:** Bu doküman [`C4`](../22-Learning-Path/block-c-reproducibility/C4-bulut-butce-alarmi.md) modülünde "Önce oku" kaynağı olarak kullanılıyor.
