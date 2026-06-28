---
description: "Faz 7 (Gün 17-18): Secrets management ve güvenlik; HashiCorp Vault'un Helm ile kurulumu, TLS, injector yapılandırması ve kaynak limitlerinin ayarlanması."
tags:
  - Roadmap
  - Secrets
  - Security
  - Helm
  - Kubernetes
---
# 🔒 **PHASE 7: SECRETS MANAGEMENT & SECURITY** (Gün 17-18)

### 🔐 **8.1 HashiCorp Vault Setup**

```bash
# 8.1.1 Vault Helm kurulumu
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

cat > vault-values.yaml << 'EOF'
global:
  enabled: true
  tlsDisable: false

injector:
  enabled: true
  replicas: 1
  resources:
    requests:
      memory: 256Mi
      cpu: 250m
    limits:
      memory: 256Mi
      cpu: 250m

server:
  image:
    repository: "vault"
    tag: "1.15.0"

  resources:
    requests:
      memory: 256Mi
      cpu: 250m
    limits:
      memory: 256Mi
      cpu: 250m

  readinessProbe:
    enabled: true
    path: "/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"
  livenessProbe:
    enabled: true
    path: "/v1/sys/health?standbyok=true"
    initialDelaySeconds: 60

  extraEnvironmentVars:
    VAULT_CACERT: /vault/userconfig/vault-ha-tls/vault.ca
    VAULT_TLSCERT: /vault/userconfig/vault-ha-tls/vault.crt
    VAULT_TLSKEY: /vault/userconfig/vault-ha-tls/vault.key

  extraVolumes:
    - type: secret
      name: vault-ha-tls
      path: /vault/userconfig

  standalone:
    enabled: false

  ha:
    enabled: true
    replicas: 3
    raft:
      enabled: true
      setNodeId: true
      config: |
        ui = true
        
        listener "tcp" {
          tls_disable = 0
          address = "[::]:8200"
          cluster_address = "[::]:8201"
          tls_cert_file = "/vault/userconfig/vault-ha-tls/vault.crt"
          tls_key_file  = "/vault/userconfig/vault-ha-tls/vault.key"
          tls_client_ca_file = "/vault/userconfig/vault-ha-tls/vault.ca"
        }

        storage "raft" {
          path = "/vault/data"
          
          retry_join {
            leader_api_addr = "https://vault-0.vault-internal:8200"
            leader_ca_cert_file = "/vault/userconfig/vault-ha-tls/vault.ca"
            leader_client_cert_file = "/vault/userconfig/vault-ha-tls/vault.crt"
            leader_client_key_file = "/vault/userconfig/vault-ha-tls/vault.key"
          }
          
          retry_join {
            leader_api_addr = "https://vault-1.vault-internal:8200"
            leader_ca_cert_file = "/vault/userconfig/vault-ha-tls/vault.ca"
            leader_client_cert_file = "/vault/userconfig/vault-ha-tls/vault.crt"
            leader_client_key_file = "/vault/userconfig/vault-ha-tls/vault.key"
          }
          
          retry_join {
            leader_api_addr = "https://vault-2.vault-internal:8200"
            leader_ca_cert_file = "/vault/userconfig/vault-ha-tls/vault.ca"
            leader_client_cert_file = "/vault/userconfig/vault-ha-tls/vault.crt"
            leader_client_key_file = "/vault/userconfig/vault-ha-tls/vault.key"
          }
        }

        service_registration "kubernetes" {}

  service:
    enabled: true
    type: ClusterIP
    port: 8200
    targetPort: 8200

  dataStorage:
    enabled: true
    size: 10Gi
    storageClass: gp3

  auditStorage:
    enabled: true
    size: 10Gi
    storageClass: gp3

ui:
  enabled: true
  serviceType: ClusterIP
EOF

# 8.1.2 TLS sertifikaları oluştur
mkdir -p vault-tls
cd vault-tls

# CA private key
openssl genrsa -out vault-ca.key 2048

# CA certificate
openssl req -new -x509 -key vault-ca.key -out vault-ca.crt -days 365 \
  -subj "/C=US/ST=CA/L=San Francisco/O=HashiCorp/CN=Vault CA"

# Vault private key
openssl genrsa -out vault.key 2048

# Vault certificate signing request
cat > vault.conf << 'EOF'
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = CA
L = San Francisco
O = HashiCorp
CN = vault

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = vault
DNS.2 = vault.vault
DNS.3 = vault.vault.svc
DNS.4 = vault.vault.svc.cluster.local
DNS.5 = vault-0.vault-internal
DNS.6 = vault-1.vault-internal
DNS.7 = vault-2.vault-internal
DNS.8 = vault-0.vault-internal.vault.svc.cluster.local
DNS.9 = vault-1.vault-internal.vault.svc.cluster.local
DNS.10 = vault-2.vault-internal.vault.svc.cluster.local
DNS.11 = vault.yourdomain.com
IP.1 = 127.0.0.1
EOF

openssl req -new -key vault.key -out vault.csr -config vault.conf

# Vault certificate
openssl x509 -req -in vault.csr -CA vault-ca.crt -CAkey vault-ca.key \
  -CAcreateserial -out vault.crt -days 365 -extensions v3_req -extfile vault.conf

# 8.1.3 Vault namespace ve TLS secret oluştur
kubectl create namespace vault

kubectl create secret generic vault-ha-tls \
  --from-file=vault.key=vault.key \
  --from-file=vault.crt=vault.crt \
  --from-file=vault.ca=vault-ca.crt \
  --namespace vault

cd ..

# 8.1.4 Vault kurulumu
helm install vault hashicorp/vault \
  --namespace vault \
  --values vault-values.yaml

# 8.1.5 Vault'u initialize et ve unseal et
kubectl exec vault-0 -n vault -- vault operator init \
  -key-shares=5 \
  -key-threshold=3 \
  -format=json > cluster-keys.json

# Root token ve unseal key'leri çıkar
VAULT_UNSEAL_KEY_1=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[0]")
VAULT_UNSEAL_KEY_2=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[1]")
VAULT_UNSEAL_KEY_3=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[2]")
CLUSTER_ROOT_TOKEN=$(cat cluster-keys.json | jq -r ".root_token")

# Vault unseal
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_1
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_2
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_3

# Diğer node'ları join et
kubectl exec vault-1 -n vault -- vault operator raft join https://vault-0.vault-internal:8200
kubectl exec vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_1
kubectl exec vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_2
kubectl exec vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_3

kubectl exec vault-2 -n vault -- vault operator raft join https://vault-0.vault-internal:8200
kubectl exec vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_1
kubectl exec vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_2
kubectl exec vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_3

echo "Root Token: $CLUSTER_ROOT_TOKEN"
```

### 🔧 **8.2 External Secrets Operator**

```bash
# 8.2.1 External Secrets Operator kurulumu
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace

# 8.2.2 Vault'ta Kubernetes auth method aktifleştir
kubectl exec vault-0 -n vault -- env VAULT_TOKEN=$CLUSTER_ROOT_TOKEN vault auth enable kubernetes

# Service account token path'ini al
TOKEN_REVIEW_JWT=$(kubectl get secret \
  $(kubectl get serviceaccount vault -n vault -o jsonpath='{.secrets[0].name}') \
  -n vault -o jsonpath='{.data.token}' | base64 --decode)

KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)

KUBE_HOST=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.server}')

# Kubernetes auth method konfigüre et
kubectl exec vault-0 -n vault -- env VAULT_TOKEN=$CLUSTER_ROOT_TOKEN vault write auth/kubernetes/config \
  token_reviewer_jwt="$TOKEN_REVIEW_JWT" \
  kubernetes_host="$KUBE_HOST" \
  kubernetes_ca_cert="$KUBE_CA_CERT"

# 8.2.3 Vault policy ve role oluştur
kubectl exec vault-0 -n vault -- env VAULT_TOKEN=$CLUSTER_ROOT_TOKEN vault policy write mycompany-dev - <<EOF
path "secret/data/dev/*" {
  capabilities = ["read"]
}
EOF

kubectl exec vault-0 -n vault -- env VAULT_TOKEN=$CLUSTER_ROOT_TOKEN vault write auth/kubernetes/role/mycompany-dev \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=dev \
  policies=mycompany-dev \
  ttl=24h

# 8.2.4 Vault'ta secret engine aktifleştir
kubectl exec vault-0 -n vault -- env VAULT_TOKEN=$CLUSTER_ROOT_TOKEN vault secrets enable -path=secret kv-v2

# Test secrets ekle
kubectl exec vault-0 -n vault -- env VAULT_TOKEN=$CLUSTER_ROOT_TOKEN vault kv put secret/dev/database \
  username=myapp \
  password=SuperSecretPassword123!

kubectl exec vault-0 -n vault -- env VAULT_TOKEN=$CLUSTER_ROOT_TOKEN vault kv put secret/dev/api-keys \
  github-token=ghp_xxxxxxxxxxxx \
  slack-webhook=https://hooks.slack.com/services/xxx

# 8.2.5 SecretStore oluştur
cat > vault-secret-store.yaml << 'EOF'
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: dev
spec:
  provider:
    vault:
      server: "https://vault.vault.svc.cluster.local:8200"
      path: "secret"
      version: "v2"
      caBundle: "LS0tLS1CRUdJTi..."  # Base64 encoded CA cert
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "mycompany-dev"
          serviceAccountRef:
            name: "external-secrets"
EOF

# CA cert'i base64 encode et
CA_BUNDLE=$(cat vault-tls/vault-ca.crt | base64 -w 0)
sed -i "s/LS0tLS1CRUdJTi.../$CA_BUNDLE/g" vault-secret-store.yaml

kubectl apply -f vault-secret-store.yaml

# 8.2.6 ExternalSecret oluştur
cat > external-secret-database.yaml << 'EOF'
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: dev
spec:
  refreshInterval: 1m
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: database-secret
    creationPolicy: Owner
  data:
  - secretKey: username
    remoteRef:
      key: secret/dev/database
      property: username
  - secretKey: password
    remoteRef:
      key: secret/dev/database
      property: password
EOF

kubectl apply -f external-secret-database.yaml

# Secret'in oluştuğunu kontrol et
kubectl get secrets -n dev
kubectl describe externalsecret database-credentials -n dev
```

### 🛡️ **8.3 Pod Security Standards**

```bash
# 8.3.1 Pod Security Standards uygula
kubectl label --overwrite namespace dev pod-security.kubernetes.io/enforce=restricted
kubectl label --overwrite namespace dev pod-security.kubernetes.io/audit=restricted
kubectl label --overwrite namespace dev pod-security.kubernetes.io/warn=restricted

kubectl label --overwrite namespace staging pod-security.kubernetes.io/enforce=restricted
kubectl label --overwrite namespace staging pod-security.kubernetes.io/audit=restricted
kubectl label --overwrite namespace staging pod-security.kubernetes.io/warn=restricted

kubectl label --overwrite namespace production pod-security.kubernetes.io/enforce=restricted
kubectl label --overwrite namespace production pod-security.kubernetes.io/audit=restricted
kubectl label --overwrite namespace production pod-security.kubernetes.io/warn=restricted

# 8.3.2 Security context template
cat > security-context-template.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        fsGroup: 10001
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 8080
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 10001
          runAsGroup: 10001
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: var-cache-nginx
          mountPath: /var/cache/nginx
        - name: var-run
          mountPath: /var/run
      volumes:
      - name: tmp
        emptyDir: {}
      - name: var-cache-nginx
        emptyDir: {}
      - name: var-run
        emptyDir: {}
EOF
```

### 🔍 **8.4 Falco Runtime Security**

```bash
# 8.4.1 Falco kurulumu
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

cat > falco-values.yaml << 'EOF'
falco:
  rules_file:
    - /etc/falco/falco_rules.yaml
    - /etc/falco/falco_rules.local.yaml
    - /etc/falco/k8s_audit_rules.yaml
    - /etc/falco/rules.d
  
  time_format_iso_8601: true
  json_output: true
  json_include_output_property: true
  json_include_tags_property: true
  
  log_stderr: true
  log_syslog: true
  log_level: info
  
  priority: debug
  
  buffered_outputs: false
  
  syscall_event_drops:
    actions:
      - log
      - alert
    rate: 0.03333
    max_burst: 1000

  outputs:
    rate: 1
    max_burst: 1000

  syslog_output:
    enabled: true

  file_output:
    enabled: false

  stdout_output:
    enabled: true

  webserver:
    enabled: true
    listen_port: 8765
    k8s_healthz_endpoint: /healthz
    ssl_enabled: false
    ssl_certificate: /etc/ssl/falco/falco.pem

  grpc:
    enabled: false

  grpc_output:
    enabled: false

customRules:
  custom-rules.yaml: |-
    - rule: Unexpected outbound connection destination
      desc: Detect outbound connections to unexpected destinations
      condition: >
        outbound and not
        (fd.sip in (internal_networks))
      output: Outbound connection to unexpected destination (command=%proc.cmdline dest=%fd.rip)
      priority: WARNING
      tags: [network, mitre_exfiltration]
    
    - rule: Suspicious process in container
      desc: Detect suspicious processes running in containers
      condition: >
        spawned_process and container and
        (proc.name in (nc, ncat, netcat, nmap, dig, nslookup, tcpdump))
      output: Suspicious process in container (command=%proc.cmdline container=%container.name)
      priority: WARNING
      tags: [process, container]

driver:
  enabled: true
  kind: ebpf

collectors:
  enabled: true
  docker:
    enabled: true
  containerd:
    enabled: true
  crio:
    enabled: false

resources:
  requests:
    cpu: 100m
    memory: 512Mi
  limits:
    cpu: 200m
    memory: 1024Mi

tolerations:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
  - effect: NoSchedule
    key: node-role.kubernetes.io/control-plane

falcosidekick:
  enabled: true
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
  
  config:
    slack:
      webhookurl: "YOUR_SLACK_WEBHOOK_URL"
      channel: "#security-alerts"
      username: "Falco"
      minimumpriority: "warning"
      messageformat: "long"
    
    alertmanager:
      hostport: "http://kube-prometheus-stack-alertmanager.monitoring.svc.cluster.local:9093"
      minimumpriority: "warning"
EOF

kubectl create namespace falco
helm install falco falcosecurity/falco \
  --namespace falco \
  --values falco-values.yaml

# 8.4.2 Falco durumunu kontrol et
kubectl get pods -n falco
kubectl logs -l app.kubernetes.io/name=falco -n falco
```

---
