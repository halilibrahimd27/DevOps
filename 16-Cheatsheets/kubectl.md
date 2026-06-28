---
description: "kubectl pratik komut notlari: cluster inspection, etiket filtreleme, JSONPath ile alan secimi, pod debug, rollout, port-forward ve sirali cikti ornekleri."
tags:
  - Cheatsheet
  - Kubernetes
  - Containers
---
# kubectl Cheatsheet

## 🔍 Inspection

```bash
# Tek satırda tüm cluster özeti
kubectl get all -A
kubectl get nodes -o wide

# Etiketle filtreleme
kubectl get pods -l app=payments,env=prod -A

# JSONPath ile alan seçimi (en güçlü silahlardan biri)
kubectl get pods -o jsonpath='{.items[*].spec.nodeName}'
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'

# Sorted output
kubectl get pods --sort-by=.status.startTime
kubectl get pods --sort-by=.metadata.creationTimestamp

# Container imajları (drift kontrolü)
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}' | sort -u

# Pending pod'ların eventleri
kubectl get events -A --field-selector type=Warning --sort-by='.lastTimestamp'

# CrashLoopBackOff'taki pod'lar
kubectl get pods -A | grep -E 'CrashLoop|Error|Pending'
```

## 🐛 Debug

```bash
# Pod loglarına bak
kubectl logs <POD> -c <CONTAINER>           # tek container
kubectl logs <POD> --all-containers --previous   # çökmüş pod'un önceki run'ı
kubectl logs <POD> -f --tail=100 --since=10m

# Pod içine gir (image'da shell varsa)
kubectl exec -it <POD> -- /bin/sh

# Image'da shell yoksa: ephemeral debug container
kubectl debug -it <POD> --image=busybox --target=<CONTAINER>
kubectl debug -it <POD> --image=nicolaka/netshoot --target=<CONTAINER>

# Bir pod kopyası ile debug (init container patlamış olsun)
kubectl debug <POD> -it --copy-to=debug-pod --container=<CONTAINER> -- /bin/sh

# Node'a debug container at (host network görmek için)
kubectl debug node/<NODE> -it --image=ubuntu

# Resource describe (event'leri yakalamak için en hızlı)
kubectl describe pod <POD>
kubectl describe node <NODE>
```

## 🚀 Apply / Edit / Delete

```bash
# Apply (declarative)
kubectl apply -f manifest.yaml
kubectl apply -k overlays/prod          # kustomize
kubectl apply -f https://raw.githubusercontent.com/.../yaml

# Patch (imperative ama scriptable)
kubectl patch deployment <NAME> -p '{"spec":{"replicas":3}}'
kubectl patch deployment <NAME> --type=json -p='[{"op":"replace","path":"/spec/replicas","value":3}]'

# Edit (last resort — drift yaratır, GitOps'ta yapma)
kubectl edit deployment <NAME>

# Delete
kubectl delete -f manifest.yaml
kubectl delete pod <POD> --grace-period=0 --force   # stuck pod
kubectl delete ns <NS> --grace-period=0 --force     # stuck namespace
```

## 🔄 Rollout

```bash
# Status izle
kubectl rollout status deployment/<NAME>
kubectl rollout history deployment/<NAME>
kubectl rollout history deployment/<NAME> --revision=3

# Geri al
kubectl rollout undo deployment/<NAME>
kubectl rollout undo deployment/<NAME> --to-revision=3

# Yeniden başlat (config drift düzeltme)
kubectl rollout restart deployment/<NAME>

# Pause / resume (canary için)
kubectl rollout pause deployment/<NAME>
kubectl rollout resume deployment/<NAME>
```

## 📦 Scale

```bash
kubectl scale deployment/<NAME> --replicas=5
kubectl scale deployment/<NAME> --current-replicas=2 --replicas=5

# HPA inspect
kubectl get hpa
kubectl describe hpa <NAME>
```

## 🌐 Networking

```bash
# Port-forward (lokal'den cluster'a)
kubectl port-forward pod/<POD> 8080:80
kubectl port-forward svc/<SVC> 8080:80
kubectl port-forward deployment/<NAME> 8080:8080

# Service erişimi test
kubectl run -it --rm debug --image=busybox -- sh
# içeride: wget -qO- http://<SVC>.<NS>.svc.cluster.local

# DNS test
kubectl run -it --rm dns-test --image=busybox -- nslookup <SVC>.<NS>

# NetworkPolicy debug
kubectl run -it --rm netshoot --image=nicolaka/netshoot -- bash
# içeride: ping, dig, curl, traceroute, mtr hepsi var
```

## 🔐 Secrets / ConfigMap

```bash
# Secret oluştur (literal)
kubectl create secret generic db-creds \
  --from-literal=user=appuser \
  --from-literal=password='<PASSWORD>'

# Secret oluştur (file'dan)
kubectl create secret generic tls --from-file=tls.crt --from-file=tls.key

# Secret değerini decode et
kubectl get secret <NAME> -o jsonpath='{.data.password}' | base64 -d

# ConfigMap from file
kubectl create configmap app-config --from-file=app.conf
kubectl create configmap app-config --from-env-file=.env
```

## 🎯 Context / Namespace

```bash
# Aktif context
kubectl config current-context
kubectl config get-contexts
kubectl config use-context <CTX>

# Aktif namespace
kubectl config set-context --current --namespace=<NS>

# kubectx / kubens (kurun: brew install kubectx)
kubectx                    # context listesi
kubectx <CTX>             # değiştir
kubectx -                  # önceki
kubens                     # namespace listesi
kubens <NS>               # değiştir
```

## 📊 Resource usage

```bash
# Top (metrics-server gerekir)
kubectl top nodes
kubectl top pods -A --sort-by=memory
kubectl top pods -A --sort-by=cpu --containers

# Cluster kapasitesi
kubectl describe nodes | grep -A 5 "Allocated resources"
```

## 🧰 Tools

```bash
# Auto-completion
source <(kubectl completion bash)
echo "alias k=kubectl" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc

# Diff before apply (her zaman önce diff!)
kubectl diff -f manifest.yaml

# Dry run (manifest doğrulama)
kubectl apply -f manifest.yaml --dry-run=client -o yaml
kubectl apply -f manifest.yaml --dry-run=server   # admission controller'lar dahil

# Explain (CRD'ler için altın)
kubectl explain pod.spec.containers
kubectl explain pod.spec.containers --recursive

# Resource API listesi
kubectl api-resources
kubectl api-resources --namespaced=true
kubectl api-resources --verbs=list -o name
```

## ⚡ Faydalı one-liner'lar

```bash
# Tüm namespace'lerin pod sayısı
kubectl get pods -A --no-headers | awk '{print $1}' | sort | uniq -c | sort -rn

# Bir node'da çalışan pod'lar
kubectl get pods -A -o wide --field-selector spec.nodeName=<NODE>

# Container restart sayısı (en çok restart eden ilk)
kubectl get pods -A --sort-by='.status.containerStatuses[0].restartCount' \
  -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\t"}{.metadata.namespace}{"/"}{.metadata.name}{"\n"}{end}' | sort -rn | head

# Image pull policy "Always" olanları bul (waste)
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].imagePullPolicy}{"\n"}{end}' | grep Always

# Bütün cluster'da resource limits eksik olan pod'lar
kubectl get pods -A -o json | jq '.items[] | select(.spec.containers[].resources.limits == null) | "\(.metadata.namespace)/\(.metadata.name)"'

# Bir namespace'te tüm her şeyi kullan-bir-defalık şekilde sil
kubectl delete all,cm,secret,ingress,pvc --all -n <NS>
```

## 🆘 "Acil" senaryolar

| Sorun | Bak |
|---|---|
| Pod Pending | `kubectl describe pod` → events; `kubectl get nodes` → resource? `kubectl get pvc` |
| ImagePullBackOff | imageName, secret, registry erişim, `kubectl describe pod` |
| CrashLoopBackOff | `kubectl logs <POD> --previous`; readiness/liveness probe |
| OOMKilled | `kubectl describe pod` → Last State; `resources.limits.memory` artır |
| Service erişilmez | endpoint var mı? `kubectl get endpoints <SVC>`; selector eşleşiyor mu? |
| Ingress 503 | upstream service ayakta mı? backend protocol; ingress class doğru mu? |
| Pod stuck "Terminating" | finalizer var; `kubectl patch pod <POD> -p '{"metadata":{"finalizers":null}}'` (dikkatli) |
