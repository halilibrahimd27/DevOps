---
description: "Prod ortamında alarmlara cevap vermek için runbook'un ne olduğunu, neden ve nasıl yazıldığını anlatan rehber; şablon, örnek ve anti-pattern'ler."
tags:
  - SRE
  - Incident Response
  - Template
  - Field Notes
---
# Runbook — Alarm Düştüğünde Ne Yap

> *"Gece 03:14, telefon çalıyor. Beynin %30 kapasitede. Runbook
> yoksa, **gözlerinin önünde bir labirent**. Runbook varsa,
> **adımları takip ediyorsun**."*

Bu rehber prod ortamında alarmlara cevap vermek için **runbook**'un
ne, neden, nasıl yazıldığını anlatır. Şablon + örnek + anti-pattern.

---

## 🎯 Runbook Nedir?

> **Runbook**: Belirli bir alarm/durum için **adım-adım**
> "kontrol et, dene, escalate et" rehberi. **Yorgun mühendis** için
> yazılır, expert için değil.

```
Alert: PostgresHighConnections
   │
   ▼
[Runbook linki]
   │
   ▼
1. Dashboard linki → connection sayısı kontrol
2. Hangi app conn açıyor? Top 5 query
3. Pool exhaustion mu, sızıntı mı?
4. Mitigation: pool_size up / app restart / kill query
5. Escalate: @postgres-team
6. Postmortem: bu pattern tekrar etti mi?
```

---

## 📐 Şablon — Bir Runbook Anatomi

```markdown
# Runbook: <ALERT_NAME>

**Severity:** SEV-1 / SEV-2 / SEV-3  
**Owner team:** @<TEAM>  
**Service:** <SERVICE>  
**Last updated:** YYYY-MM-DD  
**Related runbooks:** [list]

## TL;DR (30 saniye)
<Bir paragraf: ne, ne kadar acil, ilk yapılacak.>

## 1. Verify the alert
<Yanlış alarm mı? Doğrulama adımları.>
- Dashboard: <URL>
- Query: ```promql
  ...
  ```

## 2. Quick Mitigation (5-10 dakika)
<Hemen yapılacak — kanı durdurma. Kök neden değil.>
- [ ] Adım 1: ...
- [ ] Adım 2: ...

## 3. Investigation (15-30 dakika)
<Kök neden bulma adımları.>
- [ ] Log: <log query>
- [ ] Trace: <trace query>
- [ ] Metric trend: <dashboard>

## 4. Common Causes
| Sebep | Belirti | Çözüm |
|---|---|---|

## 5. Escalation
- 30 dakikadan uzun → @<ON_CALL_LEAD>
- 1 saatten uzun → @<MANAGER>
- Müşteri etkisi varsa → IC (incident commander)

## 6. Related links
- Dashboard: ...
- Architecture diagram: ...
- Postmortems with this pattern: ...
- Service runbook: ...

## 7. After the fix
- [ ] Postmortem? (SEV-1/2 yes)
- [ ] Update this runbook (gap çıktıysa)
- [ ] Permanent fix ticket: #...
```

---

## 📝 Örnek 1: PostgresHighConnections

```markdown
# Runbook: PostgresHighConnections

**Severity:** SEV-2  
**Owner team:** @platform  
**Service:** postgres-prod  
**Last updated:** 2026-04-15  

## TL;DR
Postgres connection sayısı %85+. PgBouncer pool tükenmiş veya
app sızıntısı olabilir. 30 dk içinde mitigate, 1 saatten uzunsa IC.

## 1. Verify the alert
- Dashboard: https://grafana.<DOMAIN>/d/pg-prod
- Query:
  ```promql
  pg_stat_activity_count / pg_settings_max_connections
  ```
  > 0.85 → alert; > 0.95 → SEV-1

## 2. Quick Mitigation (5 dk)
- [ ] Top connection acanları gör:
  ```sql
  SELECT application_name, state, COUNT(*)
  FROM pg_stat_activity
  GROUP BY 1, 2
  ORDER BY 3 DESC
  LIMIT 10;
  ```
- [ ] `idle in transaction` çoksa → bunlar sızıntı, kill et:
  ```sql
  SELECT pg_terminate_backend(pid)
  FROM pg_stat_activity
  WHERE state = 'idle in transaction'
    AND state_change < now() - interval '5 minutes';
  ```
- [ ] PgBouncer restart (last resort):
  ```bash
  kubectl rollout restart deploy/pgbouncer -n postgres
  ```

## 3. Investigation
- Hangi app conn açtı? `application_name` filter'la, owner team bul.
- App-side connection pool config: hot reload mu, hardcoded mu?
- Recent deploy var mı? → conn pool config değiştirildi mi?

## 4. Common Causes
| Sebep | Belirti | Çözüm |
|---|---|---|
| App pool size yanlış | Tek app %50+ conn | App config patch + redeploy |
| `idle in transaction` sızıntı | Eski state'te conn'lar | App-side: tx commit/rollback eksik |
| PgBouncer pool tükenmesi | client_active < 5%, db_used %100 | `default_pool_size` artır |
| Saldırı / DDoS | External IP'lerden conn | WAF rule + IP block |

## 5. Escalation
- 30 dk → @postgres-team Slack
- 1 saat → IC açma + müşteri etki kontrol
- Veri sızıntısı şüphesi → Security ekibi + KVKK 72h timer

## 6. Related links
- Dashboard: ...
- Architecture: ...
- Postmortems: INC-2026-02-08, INC-2026-04-12
- Service runbook: postgres-service.md

## 7. After the fix
- [ ] Postmortem SEV-2 kuralına göre
- [ ] Pool sizing review (eğer app-side fix gerekliyse)
- [ ] Bu runbook update — yeni sebep çıktıysa
```

---

## 📝 Örnek 2: PodOOMKilled

```markdown
# Runbook: PodOOMKilled

**Severity:** SEV-3 (tek pod) / SEV-2 (multi-pod)

## TL;DR
Pod OOMKilled (memory limit aştı). Memory leak ya da yetersiz limit.

## 1. Verify
- ```bash
  kubectl get events -n <NS> | grep OOMKilled
  kubectl describe pod <POD> -n <NS> | grep -A 5 "Last State"
  ```
- Grafana: container_memory_usage trend

## 2. Quick Mitigation
- [ ] Memory limit artır (geçici):
  ```bash
  kubectl set resources deployment/<APP> -n <NS> \
    --limits=memory=2Gi
  ```
- [ ] Replicas artır (load split):
  ```bash
  kubectl scale deployment/<APP> -n <NS> --replicas=5
  ```

## 3. Investigation
- Memory leak mi? → trend artıyor mu zaman içinde?
- Spike mi? → deploy ile mi tetiklendi?
- Heap dump al (Java/Go pprof):
  ```bash
  kubectl exec <POD> -- jmap -dump:format=b,file=/tmp/heap.hprof <PID>
  kubectl cp <POD>:/tmp/heap.hprof ./heap.hprof
  ```

## 4. Common Causes
| Sebep | Belirti | Çözüm |
|---|---|---|
| Memory leak | Trend zamanla artıyor | Code fix |
| Cache size yanlış | Belirli traffic'te spike | Cache tune |
| GC pressure | CPU yüksek + memory artıyor | GC tuning veya rewrite |
| Limit yetersiz | Trafik beklenenden çok | Limit artır + HPA |
```

---

## 🔗 Runbook'u Alert'e Bağla

### Prometheus alert
```yaml
groups:
  - name: postgres
    rules:
      - alert: PostgresHighConnections
        expr: pg_stat_activity_count / pg_settings_max_connections > 0.85
        for: 5m
        labels:
          severity: page
          team: platform
        annotations:
          summary: "Postgres conn %85+: {{ $value | humanizePercentage }}"
          runbook_url: "https://runbooks.<DOMAIN>/postgres-high-connections"
          dashboard_url: "https://grafana.<DOMAIN>/d/pg-prod"
```

PagerDuty alert payload'da `runbook_url` görünür → mühendis bir tıkla açar.

---

## 🛠️ Runbook'u Nerede Tutmalı?

| Yer | Pro | Con |
|---|---|---|
| **Repo (Git)** | Versioned, PR review | Slack'ten erişim için ekstra tıklama |
| **Backstage TechDocs** | Search'lenebilir, embed | Setup |
| **Confluence / Notion** | Yaygın | Kod ile senkron yok, eskir |
| **Repo + alert annotation** | ✅ İdeal kombinasyon | — |

> 🔑 **Önerilen**: Markdown repo'da + alert'e link. Update PR review'dan
> geçer. 6 ayda bir review.

---

## 📊 Runbook Olgunluk Modeli

| Level | Durum |
|---|---|
| **L0** | Hiç runbook yok, "@oncall ne yapıyorsa o yapar" |
| **L1** | Bazı kritik servisler için Confluence sayfası, eski |
| **L2** | Tüm SEV-1 alert için runbook, repo'da |
| **L3** | Tüm alert (SEV-1 ile SEV-3) runbook'lu, alert annotation ile linkli |
| **L4** | Auto-remediation: bazı runbook adımları kod ile otomatik |

> 🎯 **2026 hedefi:** L3. Yeni alert yarat **runbook olmadan PR merge edilmez**.

---

## 🤖 Auto-Remediation (L4)

Runbook adımları otomatize edilebilir:

```yaml
# Argo Events / Kubernetes operator
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: pod-restart-on-oom
spec:
  triggers:
    - template:
        name: restart-deployment
        k8s:
          operation: patch
          source:
            resource:
              apiVersion: apps/v1
              kind: Deployment
              metadata:
                name: "{{ .body.deployment }}"
                namespace: "{{ .body.namespace }}"
              spec:
                template:
                  metadata:
                    annotations:
                      kubectl.kubernetes.io/restartedAt: "{{ time }}"
```

Veya Python webhook responder (Falco gibi alarmlardan):
```python
async def auto_remediate(alert):
    if alert.name == "DiskUsageHigh" and alert.severity == "WARN":
        # Auto-cleanup eski log
        await k8s.exec_pod(alert.pod, "logrotate -f /etc/logrotate.conf")
        notify_slack(f"Auto-cleaned logs on {alert.pod}")
    elif alert.name == "PodCrashLoop" and alert.crash_count > 5:
        # Auto-rollback
        await argocd.rollback(alert.app, "previous")
```

> 🔑 **Auto-remediation aşamalı:** önce alert, sonra "soft action" (label),
> sonra aggressive (restart). False positive prod'u kapatmasın.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Runbook yok, "expertise" üzerine | Bus factor 1 | Yazılı runbook her alert için |
| Runbook 6 ay eski | Adımlar değişmiş, çalışmıyor | Quarterly review, drill |
| Runbook çok genel ("logları kontrol et") | Yorgun mühendis ne arasın? | Spesifik query + dashboard URL |
| Runbook 50 sayfa | Gece kimse okumaz | Kısa, adımlı, link'lerle bezenmiş |
| Runbook Confluence'ta, alert'te yok | Mühendis aramaktan vazgeçer | Alert annotation `runbook_url` |
| Yazılan runbook test edilmemiş | Drill'de fark edilir | Game day senaryolarında dene |
| Runbook English-only | Türk ekip yorgunken, dil engeli | TR (en azından örnekler) |
| Auto-remediation aggressive ilk gün | False positive prod'u kapatır | Aşamalı: alert → label → action |
| Postmortem'de runbook gap'i kaydedilmez | Aynı sürpriz tekrar olur | Postmortem action: runbook update |
| Runbook owner yok | Eskirken kimse fark etmez | CODEOWNERS ile takım atanır |

---

## 📋 Runbook Disiplin Checklist

```
[ ] Tüm SEV-1 alert için runbook var
[ ] SEV-2 alert'lerin %80+ runbook'lu
[ ] Alert annotation'da `runbook_url`
[ ] Runbook Markdown, Git'te (PR review)
[ ] Şablona uyuyor (TL;DR + Verify + Mitigate + Investigate + Escalate)
[ ] Spesifik komut + dashboard URL
[ ] Tek paragraf TL;DR (30 saniyede özet)
[ ] CODEOWNERS: ekip sahibi belirli
[ ] Quarterly review (eski adım var mı?)
[ ] Game day'de test edilmiş
[ ] Postmortem'de gap'ler runbook'a geri besler
[ ] Auto-remediation map (hangileri otomatize edilebilir?)
[ ] Yeni servis on-boarding: runbook eklendi mi gate
```

---

## 📚 Referanslar

- **Google SRE Workbook** — Bölüm 12: Practical Alerting
- **PagerDuty Runbook Best Practices**
- **AWS Well-Architected: Operational Excellence**
- [`Incident-Response.md`](Incident-Response.md)
- [`Postmortem-Practice.md`](Postmortem-Practice.md)
- [`17-Templates/runbooks/runbook-template.md`](../17-Templates/runbooks/runbook-template.md)
- [`20-Soft-Skills/Oncall-Sustainability.md`](../20-Soft-Skills/Oncall-Sustainability.md)

---

> *"İyi runbook 'her şeyi anlatan' değil, **doğru adımları doğru
> sırada veren**. Gece 03:14'te yorgun bir mühendisin tıkladığı
> link, **işin değerini** belirler."*
