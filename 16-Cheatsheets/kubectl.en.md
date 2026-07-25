---
description: "kubectl practical command notes: cluster inspection, label filtering, field selection with JSONPath, pod debug, rollout, port-forward and sorted output examples."
tags:
  - Cheatsheet
  - Kubernetes
  - Containers
---
# kubectl Cheatsheet

## 🔍 Inspection

```bash
# Full cluster summary in one line
kubectl get all -A
kubectl get nodes -o wide

# Filter by label
kubectl get pods -l app=payments,env=prod -A

# Field selection with JSONPath (one of the most powerful weapons)
kubectl get pods -o jsonpath='{.items[*].spec.nodeName}'
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'

# Sorted output
kubectl get pods --sort-by=.status.startTime
kubectl get pods --sort-by=.metadata.creationTimestamp

# Container images (drift check)
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}' | sort -u

# Events for pending pods
kubectl get events -A --field-selector type=Warning --sort-by='.lastTimestamp'

# Pods in CrashLoopBackOff
kubectl get pods -A | grep -E 'CrashLoop|Error|Pending'
```

## 🐛 Debug

```bash
# Check pod logs
kubectl logs <POD> -c <CONTAINER>           # single container
kubectl logs <POD> --all-containers --previous   # previous run of a crashed pod
kubectl logs <POD> -f --tail=100 --since=10m

# Get into the pod (if the image has a shell)
kubectl exec -it <POD> -- /bin/sh

# If the image has no shell: ephemeral debug container
kubectl debug -it <POD> --image=busybox --target=<CONTAINER>
kubectl debug -it <POD> --image=nicolaka/netshoot --target=<CONTAINER>

# Debug with a copy of the pod (say the init container crashed)
kubectl debug <POD> -it --copy-to=debug-pod --container=<CONTAINER> -- /bin/sh

# Attach a debug container to the node (to see the host network)
kubectl debug node/<NODE> -it --image=ubuntu

# Resource describe (fastest way to catch events)
kubectl describe pod <POD>
kubectl describe node <NODE>
```

## 🚀 Apply / Edit / Delete

```bash
# Apply (declarative)
kubectl apply -f manifest.yaml
kubectl apply -k overlays/prod          # kustomize
kubectl apply -f https://raw.githubusercontent.com/.../yaml

# Patch (imperative but scriptable)
kubectl patch deployment <NAME> -p '{"spec":{"replicas":3}}'
kubectl patch deployment <NAME> --type=json -p='[{"op":"replace","path":"/spec/replicas","value":3}]'

# Edit (last resort — creates drift, don't do it under GitOps)
kubectl edit deployment <NAME>

# Delete
kubectl delete -f manifest.yaml
kubectl delete pod <POD> --grace-period=0 --force   # stuck pod
kubectl delete ns <NS> --grace-period=0 --force     # stuck namespace
```

## 🔄 Rollout

```bash
# Watch status
kubectl rollout status deployment/<NAME>
kubectl rollout history deployment/<NAME>
kubectl rollout history deployment/<NAME> --revision=3

# Roll back
kubectl rollout undo deployment/<NAME>
kubectl rollout undo deployment/<NAME> --to-revision=3

# Restart (fix config drift)
kubectl rollout restart deployment/<NAME>

# Pause / resume (for canary)
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
# Port-forward (from local to cluster)
kubectl port-forward pod/<POD> 8080:80
kubectl port-forward svc/<SVC> 8080:80
kubectl port-forward deployment/<NAME> 8080:8080

# Test service access
kubectl run -it --rm debug --image=busybox -- sh
# inside: wget -qO- http://<SVC>.<NS>.svc.cluster.local

# DNS test
kubectl run -it --rm dns-test --image=busybox -- nslookup <SVC>.<NS>

# NetworkPolicy debug
kubectl run -it --rm netshoot --image=nicolaka/netshoot -- bash
# inside: ping, dig, curl, traceroute, mtr are all there
```

## 🔐 Secrets / ConfigMap

```bash
# Create a secret (literal)
kubectl create secret generic db-creds \
  --from-literal=user=appuser \
  --from-literal=password='<PASSWORD>'

# Create a secret (from a file)
kubectl create secret generic tls --from-file=tls.crt --from-file=tls.key

# Decode a secret value
kubectl get secret <NAME> -o jsonpath='{.data.password}' | base64 -d

# ConfigMap from file
kubectl create configmap app-config --from-file=app.conf
kubectl create configmap app-config --from-env-file=.env
```

## 🎯 Context / Namespace

```bash
# Active context
kubectl config current-context
kubectl config get-contexts
kubectl config use-context <CTX>

# Active namespace
kubectl config set-context --current --namespace=<NS>

# kubectx / kubens (install: brew install kubectx)
kubectx                    # context list
kubectx <CTX>             # switch
kubectx -                  # previous
kubens                     # namespace list
kubens <NS>               # switch
```

## 📊 Resource usage

```bash
# Top (requires metrics-server)
kubectl top nodes
kubectl top pods -A --sort-by=memory
kubectl top pods -A --sort-by=cpu --containers

# Cluster capacity
kubectl describe nodes | grep -A 5 "Allocated resources"
```

## 🧰 Tools

```bash
# Auto-completion
source <(kubectl completion bash)
echo "alias k=kubectl" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc

# Diff before apply (always diff first!)
kubectl diff -f manifest.yaml

# Dry run (manifest validation)
kubectl apply -f manifest.yaml --dry-run=client -o yaml
kubectl apply -f manifest.yaml --dry-run=server   # includes admission controllers

# Explain (gold for CRDs)
kubectl explain pod.spec.containers
kubectl explain pod.spec.containers --recursive

# Resource API list
kubectl api-resources
kubectl api-resources --namespaced=true
kubectl api-resources --verbs=list -o name
```

## ⚡ Useful one-liners

```bash
# Pod count per namespace
kubectl get pods -A --no-headers | awk '{print $1}' | sort | uniq -c | sort -rn

# Pods running on a node
kubectl get pods -A -o wide --field-selector spec.nodeName=<NODE>

# Container restart count (most restarts first)
kubectl get pods -A --sort-by='.status.containerStatuses[0].restartCount' \
  -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\t"}{.metadata.namespace}{"/"}{.metadata.name}{"\n"}{end}' | sort -rn | head

# Find pods with image pull policy "Always" (waste)
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].imagePullPolicy}{"\n"}{end}' | grep Always

# Pods missing resource limits across the whole cluster
kubectl get pods -A -o json | jq '.items[] | select(.spec.containers[].resources.limits == null) | "\(.metadata.namespace)/\(.metadata.name)"'

# Delete everything in a namespace, use-once style
kubectl delete all,cm,secret,ingress,pvc --all -n <NS>
```

## 🆘 "Emergency" scenarios

| Issue | Check |
|---|---|
| Pod Pending | `kubectl describe pod` → events; `kubectl get nodes` → resource? `kubectl get pvc` |
| ImagePullBackOff | imageName, secret, registry access, `kubectl describe pod` |
| CrashLoopBackOff | `kubectl logs <POD> --previous`; readiness/liveness probe |
| OOMKilled | `kubectl describe pod` → Last State; increase `resources.limits.memory` |
| Service unreachable | is there an endpoint? `kubectl get endpoints <SVC>`; does the selector match? |
| Ingress 503 | is the upstream service up? backend protocol; is the ingress class correct? |
| Pod stuck "Terminating" | there's a finalizer; `kubectl patch pod <POD> -p '{"metadata":{"finalizers":null}}'` (careful) |
