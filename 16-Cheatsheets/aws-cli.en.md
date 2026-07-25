---
description: "AWS CLI practical command notes: profile and SSO auth, sts assume-role, EC2/S3/IAM operations, query filtering, and caller-identity verification examples."
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

# SSO (modern, more secure)
aws configure sso
aws sso login --profile prod
aws sso logout

# Use profile
export AWS_PROFILE=prod
aws s3 ls --profile prod
aws sts get-caller-identity --profile prod        # who am I?

# Assume role
aws sts assume-role \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/<ROLE> \
  --role-session-name my-session

# OIDC token (for CI/CD)
aws sts assume-role-with-web-identity \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/gh-actions-role \
  --role-session-name gh-action \
  --web-identity-token $GITHUB_OIDC_TOKEN
```

## 🌐 General Pattern

```bash
# Output filtering with JMESPath
aws ec2 describe-instances \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name]' \
  --output table

# Output formats
--output json | text | table | yaml

# Pagination
aws s3api list-objects-v2 --bucket <BUCKET> --max-items 100 --starting-token <TOKEN>

# Region override
aws ec2 describe-instances --region eu-west-1
export AWS_DEFAULT_REGION=eu-west-1
```

## 💻 EC2

```bash
# List (table)
aws ec2 describe-instances \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name,InstanceType,PrivateIpAddress]' \
  --output table

# Get only the running ones
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId'

# Filter by tag
aws ec2 describe-instances --filters "Name=tag:Environment,Values=prod"

# Start / stop / terminate
aws ec2 start-instances --instance-ids i-1234567890abcdef0
aws ec2 stop-instances --instance-ids i-1234567890abcdef0
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0

# Console screenshot (debug stuck instance)
aws ec2 get-console-screenshot --instance-id i-1234567890abcdef0
aws ec2 get-console-output --instance-id i-1234567890abcdef0 --output text

# AMI list
aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-*x86_64*" \
  --query 'sort_by(Images, &CreationDate)[-5:].[ImageId,Name,CreationDate]'

# Volume
aws ec2 describe-volumes --filters Name=status,Values=available    # idle ones
aws ec2 describe-snapshots --owner-ids self --query 'sort_by(Snapshots, &StartTime)[].[SnapshotId,StartTime,VolumeSize,Description]'
```

## 🗄️ S3

```bash
# Bucket list
aws s3 ls
aws s3api list-buckets --query 'Buckets[].Name'

# List contents
aws s3 ls s3://<BUCKET>/path/
aws s3 ls s3://<BUCKET>/path/ --recursive --human-readable --summarize

# Copy / sync
aws s3 cp file.txt s3://<BUCKET>/path/
aws s3 cp s3://<BUCKET>/path/file.txt .
aws s3 cp ./dir s3://<BUCKET>/path/ --recursive
aws s3 sync ./dist s3://<BUCKET>/path/ --delete   # delete = remove what's in the target but not in the source

# Storage class
aws s3 cp big.tar.gz s3://<BUCKET>/archive/ --storage-class GLACIER_IR

# Pre-signed URL
aws s3 presign s3://<BUCKET>/path/file.txt --expires-in 3600

# Bucket policy
aws s3api get-bucket-policy --bucket <BUCKET> | jq -r '.Policy' | jq

# Block public access (already default on new buckets)
aws s3api put-public-access-block --bucket <BUCKET> --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Encryption (SSE-S3 default)
aws s3api put-bucket-encryption --bucket <BUCKET> --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Lifecycle (IA after 30 days, Glacier after 90 days, delete after 365 days)
aws s3api put-bucket-lifecycle-configuration --bucket <BUCKET> --lifecycle-configuration file://lifecycle.json
```

## 👤 IAM

```bash
# User list
aws iam list-users

# A user's policies
aws iam list-attached-user-policies --user-name <USER>
aws iam list-user-policies --user-name <USER>          # inline

# Roles
aws iam list-roles --query 'Roles[].RoleName'
aws iam get-role --role-name <ROLE>
aws iam list-attached-role-policies --role-name <ROLE>
aws iam list-role-policies --role-name <ROLE>

# Read policy
aws iam get-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
aws iam get-policy-version \
  --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/<POLICY> \
  --version-id v1

# Credential report (gold for audits)
aws iam generate-credential-report
aws iam get-credential-report --query 'Content' --output text | base64 -d > report.csv

# Access analyzer (find over-permissive policies)
aws accessanalyzer list-analyzers
aws accessanalyzer list-findings --analyzer-arn <ARN>
```

## 🔐 Secrets Manager

```bash
# Secret list
aws secretsmanager list-secrets --query 'SecretList[].Name'

# Read secret
aws secretsmanager get-secret-value --secret-id <NAME> --query SecretString --output text
aws secretsmanager get-secret-value --secret-id <NAME> | jq -r '.SecretString' | jq

# Create / update
aws secretsmanager create-secret --name <NAME> --secret-string '<VALUE>'
aws secretsmanager update-secret --secret-id <NAME> --secret-string '<VALUE>'
aws secretsmanager put-secret-value --secret-id <NAME> --secret-string file://creds.json

# Rotate
aws secretsmanager rotate-secret --secret-id <NAME>
```

## 🪣 Parameter Store (SSM)

```bash
# Create
aws ssm put-parameter --name "/app/db/host" --value "<HOST>" --type String
aws ssm put-parameter --name "/app/db/password" --value "<PWD>" --type SecureString --key-id alias/aws/ssm

# Read
aws ssm get-parameter --name "/app/db/host" --query 'Parameter.Value' --output text
aws ssm get-parameter --name "/app/db/password" --with-decryption --query 'Parameter.Value' --output text

# All under a path
aws ssm get-parameters-by-path --path "/app/" --recursive --with-decryption \
  --query 'Parameters[].[Name,Value]' --output text
```

## 🚪 SSM Session Manager (EC2 access without SSH)

```bash
# Plugin installation (one time)
# https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# Connect
aws ssm start-session --target i-1234567890abcdef0

# Port forward (to DB via bastion)
aws ssm start-session --target i-1234567890abcdef0 \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<DB_HOST>"],"portNumber":["5432"],"localPortNumber":["5432"]}'

# Run command (remotely without ssh)
aws ssm send-command \
  --instance-ids i-1234567890abcdef0 \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["uname -a", "df -h"]' \
  --output json
```

## 🌐 Route 53

```bash
# Hosted zone list
aws route53 list-hosted-zones

# See records
aws route53 list-resource-record-sets --hosted-zone-id <ZONE_ID>

# Add/update record (with json)
aws route53 change-resource-record-sets --hosted-zone-id <ZONE_ID> --change-batch file://record.json

# Verify DNS propagation
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
# This month
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
# Cluster list
aws eks list-clusters

# Get kubeconfig
aws eks update-kubeconfig --name <CLUSTER> --region <REGION>
aws eks update-kubeconfig --name <CLUSTER> --alias <SHORT_NAME>

# Version and update
aws eks describe-cluster --name <CLUSTER> --query 'cluster.version'
aws eks update-cluster-version --name <CLUSTER> --version 1.30
```

## ⚡ Useful one-liners

```bash
# Which role am I running as?
aws sts get-caller-identity

# List all regions
aws ec2 describe-regions --query 'Regions[].RegionName' --output text

# Running EC2s across all regions
for r in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  echo "=== $r ==="
  aws ec2 describe-instances --region $r \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].[InstanceId,InstanceType]' \
    --output table
done

# All available (untagged) EBS volumes
aws ec2 describe-volumes --filters Name=status,Values=available \
  --query 'Volumes[].[VolumeId,Size,CreateTime]' --output table

# Idle Elastic IPs ($$$)
aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].[PublicIp,AllocationId]' --output table

# Script the whole cleanup
aws ec2 describe-snapshots --owner-ids self \
  --query "Snapshots[?StartTime<='$(date -d '90 days ago' +%F)'].SnapshotId" \
  --output text | xargs -n1 aws ec2 delete-snapshot --snapshot-id
```

## 🆘 Emergency scenarios

| Issue | Solution |
|---|---|
| `Unable to locate credentials` | `aws configure list`; `AWS_PROFILE` set; `aws sso login` |
| `AccessDenied` but IAM is correct | Check trust policy, MFA, session length, condition keys |
| High bill at month's end | Cost Explorer + Anomaly Detector + tagging audit |
| No EC2 SSH access | Use SSM Session Manager (instance role required) |
| S3 bucket accidentally public | Close with `aws s3api put-public-access-block` |
| Not seeing resources due to region mismatch | Add `--region` or set `AWS_DEFAULT_REGION` |

---

> 🎓 **Learning Path:** This document is used as the "Read first" resource in the [`C4`](../22-Learning-Path/block-c-reproducibility/C4-bulut-butce-alarmi.md) module.
