---
description: "External access solutions for Kubernetes services: binding kubectl port-forward to 0.0.0.0, NodePort services, and permanent external access methods; bash examples."
tags:
  - Field Notes
  - Kubernetes
  - Networking
  - Cheatsheet
---
# External Access Solutions

> 🗒️ **Field note** — raw command/config dump. Preserved as-is; adapt to your own environment.

```bash
# 🌐 SOLUTIONS FOR EXTERNAL ACCESS

# ══════════════════════════════════════════════════════════════
# 🚀 SOLUTION 1: EXTERNAL ACCESS VIA PORT-FORWARD (Quick)
# ══════════════════════════════════════════════════════════════

echo "🛑 Stop existing port-forwards first:"
pkill -f "kubectl port-forward"

echo "🌐 Start port-forward with external IP:"

# Bind to all interfaces using the --address 0.0.0.0 parameter
kubectl port-forward --address 0.0.0.0 service/user-frontend-service 8080:80 -n development &
kubectl port-forward --address 0.0.0.0 service/admin-frontend-service 8081:80 -n development &
kubectl port-forward --address 0.0.0.0 service/backend-service 8082:80 -n development &

echo "✅ External access port-forwards started!"
echo ""
echo "🌐 EXTERNAL ACCESS URLS:"
echo "http://<K8S_MASTER_IP>:8080 - User Frontend"
echo "http://<K8S_MASTER_IP>:8081 - Admin Frontend"  
echo "http://<K8S_MASTER_IP>:8082 - Backend API"

# ══════════════════════════════════════════════════════════════
# 🚀 SOLUTION 2: NODEPORT SERVICE (Permanent Solution)
# ══════════════════════════════════════════════════════════════

echo ""
echo "🔧 PERMANENT SOLUTION: NodePort Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Convert the User Frontend to NodePort
kubectl patch service user-frontend-service -n development -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":80,"nodePort":30080}]}}'

# Convert the Admin Frontend to NodePort  
kubectl patch service admin-frontend-service -n development -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":80,"nodePort":30081}]}}'

# Convert the Backend to NodePort
kubectl patch service backend-service -n development -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":80,"nodePort":30082}]}}'

echo "✅ NodePort services configured!"
echo ""
echo "🌐 NODEPORT ACCESS URLS (NO PORT-FORWARD NEEDED):"
echo "http://<K8S_MASTER_IP>:30080 - User Frontend"
echo "http://<K8S_MASTER_IP>:30081 - Admin Frontend"
echo "http://<K8S_MASTER_IP>:30082 - Backend API"

# ══════════════════════════════════════════════════════════════
# 🚀 SOLUTION 3: LOAD BALANCER (Production Ready)
# ══════════════════════════════════════════════════════════════

echo ""
echo "🏢 PRODUCTION SOLUTION: LoadBalancer Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# LoadBalancer services (cloud provider required)
cat << 'EOF' > loadbalancer-services.yaml
apiVersion: v1
kind: Service
metadata:
  name: user-frontend-lb
  namespace: development
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: user-frontend
---
apiVersion: v1
kind: Service  
metadata:
  name: admin-frontend-lb
  namespace: development
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: admin-frontend
---
apiVersion: v1
kind: Service
metadata:
  name: backend-lb
  namespace: development
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: backend
EOF

echo "📝 LoadBalancer services created in loadbalancer-services.yaml"
echo "Apply with: kubectl apply -f loadbalancer-services.yaml"

# ══════════════════════════════════════════════════════════════
# 🚀 SOLUTION 4: INGRESS CONTROLLER (Most Professional)
# ══════════════════════════════════════════════════════════════

echo ""
echo "🌟 PROFESSIONAL SOLUTION: Ingress Controller"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Install Nginx Ingress Controller
cat << 'EOF' > install-ingress.sh
#!/bin/bash
echo "🚀 Installing Nginx Ingress Controller..."

# Install Nginx Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml

# Expose as NodePort (for bare metal)
kubectl patch service ingress-nginx-controller -n ingress-nginx -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":80,"nodePort":30080,"name":"http"},{"port":443,"targetPort":443,"nodePort":30443,"name":"https"}]}}'

echo "✅ Ingress Controller installed!"
echo "HTTP: http://<K8S_MASTER_IP>:30080"
echo "HTTPS: https://<K8S_MASTER_IP>:30443"
EOF

chmod +x install-ingress.sh

# Create Ingress manifests
cat << 'EOF' > ingress-manifests.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ikpanel-ingress
  namespace: development
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: user.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: user-frontend-service
            port:
              number: 80
  - host: admin.local  
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-frontend-service
            port:
              number: 80
  - host: api.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
---
# Path-based routing alternative
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ikpanel-path-ingress
  namespace: development
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
  - host: ikpanel.local
    http:
      paths:
      - path: /user(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: user-frontend-service
            port:
              number: 80
      - path: /admin(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: admin-frontend-service
            port:
              number: 80
      - path: /api(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
EOF

echo "📝 Ingress manifests created in ingress-manifests.yaml"

# ══════════════════════════════════════════════════════════════
# 🛠️ FIREWALL AND NETWORK SETTINGS
# ══════════════════════════════════════════════════════════════

echo ""
echo "🛡️ FIREWALL CONFIGURATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# UFW firewall rules (Ubuntu/Debian)
cat << 'EOF' > firewall-setup.sh
#!/bin/bash
echo "🛡️ Configuring firewall for Kubernetes access..."

# Open firewall for the NodePort range
sudo ufw allow 30080:30090/tcp comment "Kubernetes NodePort Services"

# Specific ports
sudo ufw allow 8080/tcp comment "User Frontend Port Forward"
sudo ufw allow 8081/tcp comment "Admin Frontend Port Forward"  
sudo ufw allow 8082/tcp comment "Backend Port Forward"

# Kubernetes cluster communication
sudo ufw allow 6443/tcp comment "Kubernetes API Server"
sudo ufw allow 10250/tcp comment "Kubelet API"

echo "✅ Firewall rules added"
sudo ufw status numbered
EOF

chmod +x firewall-setup.sh

# iptables rules (Alternative)
cat << 'EOF' > iptables-setup.sh
#!/bin/bash
echo "🛡️ Configuring iptables for Kubernetes access..."

# iptables rules for port-forward traffic
sudo iptables -A INPUT -p tcp --dport 8080:8082 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 30080:30090 -j ACCEPT

# To make it persistent
sudo iptables-save > /etc/iptables/rules.v4

echo "✅ iptables rules configured"
EOF

chmod +x iptables-setup.sh

# ══════════════════════════════════════════════════════════════
# 📊 STATUS CHECK SCRIPT
# ══════════════════════════════════════════════════════════════

cat << 'EOF' > check-access.sh
#!/bin/bash
echo "🔍 KUBERNETES ACCESS STATUS CHECK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SERVER_IP="<K8S_MASTER_IP>"

echo "1️⃣ Port Forward Status:"
ps aux | grep "kubectl port-forward" | grep -v grep || echo "No active port forwards"

echo -e "\n2️⃣ NodePort Services:"
kubectl get services -n development -o wide | grep NodePort

echo -e "\n3️⃣ Port Connectivity Test:"
# Test port-forward ports
for port in 8080 8081 8082; do
    if netstat -tuln | grep -q ":$port "; then
        echo "✅ Port $port is open"
        # Test HTTP response
        response=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP:$port --connect-timeout 5)
        echo "   HTTP Response: $response"
    else
        echo "❌ Port $port is not open"
    fi
done

echo -e "\n4️⃣ NodePort Connectivity Test:"
# Test NodePort ports  
for port in 30080 30081 30082; do
    if netstat -tuln | grep -q ":$port "; then
        echo "✅ NodePort $port is open"
        response=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP:$port --connect-timeout 5)
        echo "   HTTP Response: $response"
    else
        echo "❌ NodePort $port is not available"
    fi
done

echo -e "\n5️⃣ Pod Status:"
kubectl get pods -n development -o wide

echo -e "\n6️⃣ Service Endpoints:"
kubectl get endpoints -n development

echo -e "\n📋 RECOMMENDED ACCESS METHODS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Port Forward (if active):"
echo "   http://$SERVER_IP:8080 - User Frontend"
echo "   http://$SERVER_IP:8081 - Admin Frontend"
echo "   http://$SERVER_IP:8082 - Backend API"
echo ""
echo "🏗️ NodePort (permanent):"
echo "   http://$SERVER_IP:30080 - User Frontend"
echo "   http://$SERVER_IP:30081 - Admin Frontend"
echo "   http://$SERVER_IP:30082 - Backend API"
EOF

chmod +x check-access.sh

echo ""
echo "🎯 INSTANT FIX - Run this command:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "pkill -f 'kubectl port-forward' && sleep 2"
echo "kubectl port-forward --address 0.0.0.0 service/user-frontend-service 8080:80 -n development &"
echo "kubectl port-forward --address 0.0.0.0 service/admin-frontend-service 8081:80 -n development &"
echo "kubectl port-forward --address 0.0.0.0 service/backend-service 8082:80 -n development &"
echo ""
echo "✅ Then access: http://<K8S_MASTER_IP>:8080"
```
