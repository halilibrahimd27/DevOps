---
description: "Faz 6 (Gün 14-16): Observability stack; kube-prometheus-stack ile Prometheus ve Grafana kurulumu, gp3 storage, retention ve kaynak ayarlarının yapılandırması."
tags:
  - Roadmap
  - Observability
  - Monitoring
  - Prometheus
  - Kubernetes
---
# 📊 **PHASE 6: OBSERVABILITY STACK** (Gün 14-16)

### 📈 **7.1 Prometheus & Grafana Setup**

```bash
# 7.1.1 kube-prometheus-stack kurulumu
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Custom values.yaml oluştur
cat > monitoring-values.yaml << 'EOF'
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 20Gi
    retention: 15d
    resources:
      requests:
        memory: 2Gi
        cpu: 1000m
      limits:
        memory: 4Gi
        cpu: 2000m
    additionalScrapeConfigs: |
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
          action: keep
          regex: true
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)
        - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
          action: replace
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: $1:$2
          target_label: __address__

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 5Gi
    resources:
      requests:
        memory: 256Mi
        cpu: 100m
      limits:
        memory: 512Mi
        cpu: 200m
  config:
    global:
      slack_api_url: 'YOUR_SLACK_WEBHOOK_URL'
    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'web.hook'
      routes:
      - match:
          alertname: DeadMansSwitch
        receiver: 'null'
      - match_re:
          severity: critical|warning
        receiver: 'slack-notifications'
    receivers:
    - name: 'null'
    - name: 'web.hook'
      webhook_configs:
      - url: 'http://127.0.0.1:5001/'
    - name: 'slack-notifications'
      slack_configs:
      - channel: '#alerts'
        title: 'Cluster Alert - {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
        send_resolved: true

grafana:
  adminPassword: 'AdminPassword123!'
  persistence:
    enabled: true
    storageClassName: gp3
    size: 10Gi
  resources:
    requests:
      memory: 256Mi
      cpu: 100m
    limits:
      memory: 512Mi
      cpu: 200m
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default
  dashboards:
    default:
      kubernetes-cluster-overview:
        gnetId: 7249
        revision: 1
        datasource: Prometheus
      kubernetes-pod-overview:
        gnetId: 6417
        revision: 1
        datasource: Prometheus
      nginx-ingress-controller:
        gnetId: 9614
        revision: 1
        datasource: Prometheus
      node-exporter:
        gnetId: 1860
        revision: 31
        datasource: Prometheus

nodeExporter:
  enabled: true

kubeStateMetrics:
  enabled: true

defaultRules:
  create: true
  rules:
    alertmanager: true
    etcd: true
    configReloaders: true
    general: true
    k8s: true
    kubeApiserverAvailability: true
    kubeApiserverBurnrate: true
    kubeApiserverHistogram: true
    kubeApiserverSlos: true
    kubelet: true
    kubeProxy: true
    kubePrometheusGeneral: true
    kubePrometheusNodeRecording: true
    kubernetesApps: true
    kubernetesResources: true
    kubernetesStorage: true
    kubernetesSystem: true
    network: true
    node: true
    nodeExporterAlerting: true
    nodeExporterRecording: true
    prometheus: true
    prometheusOperator: true
EOF

# Monitoring namespace'i oluştur ve kube-prometheus-stack'i kur
kubectl create namespace monitoring
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring-values.yaml

# 7.1.2 Monitoring durumunu kontrol et
kubectl get pods -n monitoring
kubectl get svc -n monitoring

# 7.1.3 Grafana ingress
cat > grafana-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - grafana.yourdomain.com
    secretName: grafana-tls
  rules:
  - host: grafana.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kube-prometheus-stack-grafana
            port:
              number: 80
EOF

kubectl apply -f grafana-ingress.yaml
```

### 📝 **7.2 Centralized Logging Setup**

```bash
# 7.2.1 OpenSearch (Elasticsearch alternative) kurulumu
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update

cat > opensearch-values.yaml << 'EOF'
clusterName: "opensearch-cluster"
nodeGroup: "master"

roles:
  - master
  - ingest
  - data

replicas: 3

opensearchJavaOpts: "-Xmx1g -Xms1g"

resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "1000m"
    memory: "2Gi"

persistence:
  enabled: true
  size: 30Gi
  storageClass: gp3

config:
  opensearch.yml: |
    cluster.name: opensearch-cluster
    network.host: 0.0.0.0
    plugins:
      security:
        ssl:
          transport:
            pemcert_filepath: esnode.pem
            pemkey_filepath: esnode-key.pem
            pemtrustedcas_filepath: root-ca.pem
            enforce_hostname_verification: false
          http:
            enabled: false
        allow_unsafe_democertificates: true
        allow_default_init_securityindex: true
        authcz:
          admin_dn:
            - CN=kirk,OU=client,O=client,L=test,C=de
        audit.type: internal_opensearch
        enable_snapshot_restore_privilege: true
        check_snapshot_restore_write_privileges: true
        restapi:
          roles_enabled: ["all_access", "security_rest_api_access"]
        system_indices:
          enabled: true
          indices:
            [
              ".opendistro-alerting-config",
              ".opendistro-alerting-alert*",
              ".opendistro-anomaly-results*",
              ".opendistro-anomaly-detector*",
              ".opendistro-anomaly-checkpoints",
              ".opendistro-anomaly-detection-state",
              ".opendistro-reports-*",
              ".opendistro-notifications-*",
              ".opendistro-notebooks",
              ".opendistro-asynchronous-search-response*",
            ]
EOF

kubectl create namespace logging
helm install opensearch opensearch/opensearch \
  --namespace logging \
  --values opensearch-values.yaml

# 7.2.2 OpenSearch Dashboards kurulumu
cat > opensearch-dashboards-values.yaml << 'EOF'
replicaCount: 1

opensearchHosts: "https://opensearch-cluster-master:9200"

resources:
  requests:
    cpu: "250m"
    memory: "512Mi"
  limits:
    cpu: "500m"
    memory: "1Gi"

config:
  opensearch_dashboards.yml: |
    server.name: opensearch-dashboards
    server.host: 0.0.0.0
    opensearch.hosts: [https://opensearch-cluster-master:9200]
    opensearch.ssl.verificationMode: none
    opensearch.username: admin
    opensearch.password: admin
    opensearch.requestHeadersAllowlist: [authorization, securitytenant]
    opensearch_security.multitenancy.enabled: true
    opensearch_security.multitenancy.tenants.preferred: [Private, Global]
    opensearch_security.readonly_mode.roles: [kibana_read_only]
    opensearch_security.cookie.secure: false
EOF

helm install opensearch-dashboards opensearch/opensearch-dashboards \
  --namespace logging \
  --values opensearch-dashboards-values.yaml

# 7.2.3 Fluent Bit kurulumu
cat > fluent-bit-values.yaml << 'EOF'
daemonSetVolumes:
  - name: varlog
    hostPath:
      path: /var/log
  - name: varlibdockercontainers
    hostPath:
      path: /var/lib/docker/containers
  - name: etcmachineid
    hostPath:
      path: /etc/machine-id
      type: File

daemonSetVolumeMounts:
  - name: varlog
    mountPath: /var/log
    readOnly: true
  - name: varlibdockercontainers
    mountPath: /var/lib/docker/containers
    readOnly: true
  - name: etcmachineid
    mountPath: /etc/machine-id
    readOnly: true

config:
  service: |
    [SERVICE]
        Daemon Off
        Flush {{ .Values.flush }}
        Log_Level {{ .Values.logLevel }}
        Parsers_File parsers.conf
        Parsers_File custom_parsers.conf
        HTTP_Server On
        HTTP_Listen 0.0.0.0
        HTTP_Port {{ .Values.metricsPort }}
        Health_Check On

  inputs: |
    [INPUT]
        Name tail
        Path /var/log/containers/*.log
        multiline.parser docker, cri
        Tag kube.*
        Mem_Buf_Limit 50MB
        Skip_Long_Lines On

    [INPUT]
        Name systemd
        Tag host.*
        Systemd_Filter _SYSTEMD_UNIT=kubelet.service
        Read_From_Tail On

  filters: |
    [FILTER]
        Name kubernetes
        Match kube.*
        Kube_URL https://kubernetes.default.svc:443
        Kube_CA_File /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File /var/run/secrets/kubernetes.io/serviceaccount/token
        Kube_Tag_Prefix kube.var.log.containers.
        Merge_Log On
        Keep_Log Off
        K8S-Logging.Parser On
        K8S-Logging.Exclude On
        Annotations Off
        Labels On

    [FILTER]
        Name nest
        Match kube.*
        Operation lift
        Nested_under kubernetes
        Add_prefix kubernetes_

    [FILTER]
        Name modify
        Match kube.*
        Remove kubernetes_pod_id
        Remove kubernetes_docker_id
        Remove kubernetes_container_hash

  outputs: |
    [OUTPUT]
        Name opensearch
        Match kube.*
        Host opensearch-cluster-master.logging.svc.cluster.local
        Port 9200
        Index fluentbit
        Type _doc
        HTTP_User admin
        HTTP_Passwd admin
        tls On
        tls.verify Off
        Suppress_Type_Name On
        Replace_Dots On

    [OUTPUT]
        Name opensearch
        Match host.*
        Host opensearch-cluster-master.logging.svc.cluster.local
        Port 9200
        Index fluentbit-systemd
        Type _doc
        HTTP_User admin
        HTTP_Passwd admin
        tls On
        tls.verify Off
        Suppress_Type_Name On
        Replace_Dots On
EOF

helm repo add fluent https://fluent.github.io/helm-charts
helm install fluent-bit fluent/fluent-bit \
  --namespace logging \
  --values fluent-bit-values.yaml

# 7.2.4 OpenSearch Dashboards ingress
cat > opensearch-dashboards-ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: opensearch-dashboards
  namespace: logging
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - logs.yourdomain.com
    secretName: opensearch-dashboards-tls
  rules:
  - host: logs.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: opensearch-dashboards
            port:
              number: 5601
EOF

kubectl apply -f opensearch-dashboards-ingress.yaml
```

### 🔍 **7.3 Distributed Tracing with Jaeger**

```bash
# 7.3.1 Jaeger Operator kurulumu
kubectl create namespace observability
kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.47.0/jaeger-operator.yaml -n observability

# 7.3.2 Jaeger instance
cat > jaeger.yaml << 'EOF'
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
  namespace: observability
spec:
  strategy: production
  storage:
    type: opensearch
    opensearch:
      serverUrls: https://opensearch-cluster-master.logging.svc.cluster.local:9200
      username: admin
      password: admin
      tls:
        insecureSkipVerify: true
  collector:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
  query:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
    ingress:
      enabled: true
      annotations:
        kubernetes.io/ingress.class: nginx
        nginx.ingress.kubernetes.io/ssl-redirect: "true"
        cert-manager.io/cluster-issuer: "letsencrypt-prod"
      hosts:
        - jaeger.yourdomain.com
      tls:
        - secretName: jaeger-tls
          hosts:
            - jaeger.yourdomain.com
EOF

kubectl apply -f jaeger.yaml

# 7.3.3 OpenTelemetry Collector kurulumu
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

cat > otel-collector-values.yaml << 'EOF'
mode: daemonset

presets:
  logsCollection:
    enabled: true
  hostMetrics:
    enabled: true
  kubernetesAttributes:
    enabled: true

config:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318
    jaeger:
      protocols:
        grpc:
          endpoint: 0.0.0.0:14250
        thrift_http:
          endpoint: 0.0.0.0:14268
        thrift_compact:
          endpoint: 0.0.0.0:6831
    zipkin:
      endpoint: 0.0.0.0:9411

  processors:
    batch: {}
    memory_limiter:
      limit_mib: 400
    resource:
      attributes:
        - key: cluster.name
          value: mycompany-dev-eks
          action: insert

  exporters:
    jaeger:
      endpoint: jaeger-collector.observability.svc.cluster.local:14250
      tls:
        insecure: true
    prometheus:
      endpoint: "0.0.0.0:8889"
      const_labels:
        cluster: mycompany-dev-eks

  service:
    pipelines:
      traces:
        receivers: [otlp, jaeger, zipkin]
        processors: [memory_limiter, resource, batch]
        exporters: [jaeger]
      metrics:
        receivers: [otlp]
        processors: [memory_limiter, resource, batch]
        exporters: [prometheus]
      logs:
        receivers: [otlp]
        processors: [memory_limiter, resource, batch]
        exporters: []

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 256m
    memory: 512Mi
EOF

helm install opentelemetry-collector open-telemetry/opentelemetry-collector \
  --namespace observability \
  --values otel-collector-values.yaml
```

---
