---
description: "Kubernetes logging namespace'inde ElasticSearch deployment kurulumu: kubectl apply manifesti, nodeSelector, toleration ve elasticsearch 8.5.1 imajı."
---
# kubectl — Logging (ElasticSearch)

## ElasticSearch

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      tolerations:
      - key: workload
        operator: Equal
        value: elk
        effect: NoSchedule
      nodeSelector:
        workload-type: elk
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:8.5.1
        ports:
        - containerPort: 9200
        - containerPort: 9300
        env:
        - name: discovery.type
          value: single-node
        - name: ES_JAVA_OPTS
          value: "-Xms512m -Xmx1g"
        - name: xpack.security.enabled
          value: "false"
        - name: xpack.security.http.ssl.enabled
          value: "false"
        - name: xpack.security.transport.ssl.enabled
          value: "false"
        resources:
          requests:
            memory: 1Gi
            cpu: 500m
          limits:
            memory: 2Gi
            cpu: 1000m
        volumeMounts:
        - name: elasticsearch-data
          mountPath: /usr/share/elasticsearch/data
      volumes:
      - name: elasticsearch-data
        persistentVolumeClaim:
          claimName: elasticsearch-master-elasticsearch-master-0
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: logging
spec:
  selector:
    app: elasticsearch
  ports:
  - port: 9200
    targetPort: 9200
    name: http
  - port: 9300
    targetPort: 9300
    name: transport
EOF


## Kibana

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      tolerations:
      - key: workload
        operator: Equal
        value: elk
        effect: NoSchedule
      nodeSelector:
        workload-type: elk
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:8.5.1
        ports:
        - containerPort: 5601
        env:
        - name: ELASTICSEARCH_HOSTS
          value: "http://elasticsearch:9200"
        - name: xpack.security.enabled
          value: "false"
        resources:
          requests:
            memory: 512Mi
            cpu: 200m
          limits:
            memory: 1Gi
            cpu: 500m
---
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: logging
spec:
  selector:
    app: kibana
  ports:
  - port: 5601
    targetPort: 5601
    name: http
EOF



## Logstash

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logstash
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: logstash
  template:
    metadata:
      labels:
        app: logstash
    spec:
      tolerations:
      - key: workload
        operator: Equal
        value: elk
        effect: NoSchedule
      nodeSelector:
        workload-type: elk
      containers:
      - name: logstash
        image: docker.elastic.co/logstash/logstash:8.5.1
        ports:
        - containerPort: 5044
        - containerPort: 9600
        env:
        - name: LS_JAVA_OPTS
          value: "-Xms256m -Xmx512m"
        resources:
          requests:
            memory: 512Mi
            cpu: 200m
          limits:
            memory: 1Gi
            cpu: 500m
        volumeMounts:
        - name: logstash-config
          mountPath: /usr/share/logstash/pipeline/logstash.conf
          subPath: logstash.conf
      volumes:
      - name: logstash-config
        configMap:
          name: logstash-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: logstash-config
  namespace: logging
data:
  logstash.conf: |
    input {
      beats {
        port => 5044
      }
    }
    filter {
      if [fields][log_type] == "syslog" {
        grok {
          match => { "message" => "%{SYSLOGTIMESTAMP:timestamp} %{IPORHOST:host} %{DATA:program}: %{GREEDYDATA:message}" }
        }
      }
    }
    output {
      elasticsearch {
        hosts => ["elasticsearch:9200"]
        index => "logstash-%{+YYYY.MM.dd}"
      }
    }
---
apiVersion: v1
kind: Service
metadata:
  name: logstash
  namespace: logging
spec:
  selector:
    app: logstash
  ports:
  - port: 5044
    targetPort: 5044
    name: beats
  - port: 9600
    targetPort: 9600
    name: http
EOF


## Filebeat

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: filebeat
  namespace: logging
spec:
  selector:
    matchLabels:
      app: filebeat
  template:
    metadata:
      labels:
        app: filebeat
    spec:
      serviceAccountName: filebeat
      terminationGracePeriodSeconds: 30
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      containers:
      - name: filebeat
        image: docker.elastic.co/beats/filebeat:8.5.1
        args: [
          "-c", "/etc/filebeat.yml",
          "-e",
        ]
        env:
        - name: ELASTICSEARCH_HOST
          value: elasticsearch
        - name: ELASTICSEARCH_PORT
          value: "9200"
        - name: LOGSTASH_HOST
          value: logstash
        - name: LOGSTASH_PORT
          value: "5044"
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        securityContext:
          runAsUser: 0
        resources:
          requests:
            memory: 100Mi
            cpu: 100m
          limits:
            memory: 200Mi
            cpu: 200m
        volumeMounts:
        - name: config
          mountPath: /etc/filebeat.yml
          readOnly: true
          subPath: filebeat.yml
        - name: data
          mountPath: /usr/share/filebeat/data
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: varlog
          mountPath: /var/log
          readOnly: true
      volumes:
      - name: config
        configMap:
          defaultMode: 0600
          name: filebeat-config
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: varlog
        hostPath:
          path: /var/log
      - name: data
        hostPath:
          path: /var/lib/filebeat-data
          type: DirectoryOrCreate
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
  namespace: logging
data:
  filebeat.yml: |-
    filebeat.inputs:
    - type: container
      paths:
        - /var/log/containers/*.log
      processors:
        - add_kubernetes_metadata:
            host: \${NODE_NAME}
            matchers:
            - logs_path:
                logs_path: "/var/log/containers/"
    
    output.logstash:
      hosts: ["logstash:5044"]
    
    processors:
      - add_host_metadata: ~
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: filebeat
  namespace: logging
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: filebeat
rules:
- apiGroups: [""]
  resources:
  - nodes
  - namespaces
  - events
  - pods
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: filebeat
subjects:
- kind: ServiceAccount
  name: filebeat
  namespace: logging
roleRef:
  kind: ClusterRole
  name: filebeat
  apiGroup: rbac.authorization.k8s.io
EOF