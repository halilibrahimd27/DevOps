---
description: "Junior'dan Staff seviyeye 60+ DevOps mülakat sorusu: container, Kubernetes, Git, CI/CD ve daha fazlası için her soruda ne göstermeli ipuçları ve trade-off odağı."
tags:
  - Career
  - Kubernetes
  - CI/CD
  - Containers
  - Git
---
# DevOps Interview Questions — 60+ soru ile hazırlık

> Mülakatçılar farklı tarzda soruyor: "tanım ezberle" değil **deneyim
> + trade-off** önemli. Bu sayfa "doğru cevap" sunmuyor; her soru için
> "ne göstermeli" ipuçlarını veriyor.

---

## 🟢 Junior (0-2 yıl) — Temel kavramlar

### 1. Container ve VM arasındaki fark nedir?

**Ne göstermeli:**
- VM: hypervisor + guest OS (kernel dahil) → izolasyon güçlü, boot yavaş
- Container: process group + namespace/cgroup → kernel paylaşır, hızlı, hafif
- "Hangi durumda hangisi" trade-off'u (örn: farklı kernel gerekiyorsa VM)

### 2. Docker imajı ile Docker container arasındaki fark?

**Ne göstermeli:**
- Image = template (immutable, layer'lı)
- Container = image'ın çalışan instance'ı
- Image registry, layer caching kavramı

### 3. `Dockerfile`'da `CMD` vs `ENTRYPOINT` farkı?

**Ne göstermeli:**
- `ENTRYPOINT` = sabit komut, override zor (`--entrypoint` ile)
- `CMD` = default args, runtime'da `docker run image arg` ile değiştirilebilir
- Birlikte: `ENTRYPOINT ["python"]` + `CMD ["app.py"]` → `python app.py` ama args değişebilir

### 4. Kubernetes Pod, Deployment, Service nedir?

**Ne göstermeli:**
- Pod = bir veya birden fazla container, paylaşılan network/storage
- Deployment = stateless workload manager (replica + rolling update)
- Service = pod'lara stable network endpoint
- "Niye Pod doğrudan deploy etmiyorum?" → self-healing yok, replica yok

### 5. Git rebase ile merge arasındaki fark?

**Ne göstermeli:**
- Merge: history'i koruyor, merge commit ekler
- Rebase: linear history, ama paylaşılmış branch'te tehlikeli
- "Force-push --force-with-lease" niye `--force`'tan iyi

### 6. Linux'ta CPU, memory, disk kullanımını nasıl bakarsın?

**Ne göstermeli:**
- `top`, `htop`, `vmstat 1` — CPU
- `free -h` — memory
- `df -h`, `du -sh` — disk
- `iostat -xz 1` — I/O
- USE method (Utilization, Saturation, Errors)

### 7. SSH key authentication nasıl çalışır?

**Ne göstermeli:**
- Public/private key pair
- Public key sunucuda `~/.ssh/authorized_keys`
- Client private key ile imzalar; server public key ile doğrular
- Pasphrase önerilir; agent forwarding tehlikesi

### 8. CI/CD ile Continuous Integration ve Continuous Delivery farkı?

**Ne göstermeli:**
- CI: her commit build + test
- CD (Delivery): release'e hazır artifact'a kadar otomatik
- CD (Deployment): production'a tam otomatik (insanın izni olmadan)
- Trunk-based + feature flag bağı

### 9. `kubectl get pods -o wide` çıktısında hangi kolonlar var?

**Ne göstermeli:**
- NAME, READY, STATUS, RESTARTS, AGE
- IP (pod IP), NODE (hangi node'da çalışıyor), NOMINATED NODE, READINESS GATES

### 10. `terraform plan` ile `terraform apply` arasındaki fark?

**Ne göstermeli:**
- Plan: dry run, ne değişeceğini söyler
- Apply: gerçek değişiklik
- `apply -auto-approve` tehlikesi
- `terraform plan -out=tfplan` + `apply tfplan` pattern (CI'da güvenli)

---

## 🟡 Mid-level (2-5 yıl) — Production deneyimi

### 11. Pod'lar `Pending` durumunda kalıyor — nasıl debug edersin?

**Ne göstermeli:**
- `kubectl describe pod` → events
- Yeterli node resource? `kubectl get nodes`, `top`
- PVC mount edilebiliyor mu? StorageClass var mı?
- Taint/toleration uyumsuzluğu? nodeSelector yanlış?
- Image pull problem mi? (ImagePullBackOff'tan farklı)

### 12. Production'da `kubectl edit deployment` yapılır mı?

**Ne göstermeli:**
- Hayır — drift yaratır, GitOps'ta kayıp
- Acil durumda hot-fix için ama sonra Git'e geri yansıt
- `kubectl apply` üzerinden, manifest değişikliği commit'le

### 13. Bir servisin SLO'sunu nasıl tasarlarsın?

**Ne göstermeli:**
- Önce SLI seç (kullanıcı perspektifinden, %success / latency p99)
- Mevcut performansı ölç
- Hedef = mevcut + biraz iyileştirme
- Multi-window multi-burn-rate alert
- Error budget policy

> 📚 [`11-SRE/SLI-SLO-Error-Budget.md`](../11-SRE/SLI-SLO-Error-Budget.md)

### 14. Zero-downtime deploy nasıl yaparsın?

**Ne göstermeli:**
- Rolling update + readiness probe + maxUnavailable: 0
- preStop hook (graceful shutdown 15s)
- Connection draining
- DB migration: expand/contract pattern (asla `DROP COLUMN` deploy ortasında)
- Canary / blue-green stratejileri

### 15. Terraform state'i nasıl yönetirsin?

**Ne göstermeli:**
- Remote backend (S3 + DynamoDB lock, GCS, Terraform Cloud)
- State bucket: encryption + versioning + access log
- State Git'te asla
- Multi-env layout (workspace vs directory-per-env trade-off)
- `terraform import` mevcut resource'lar için
- `terraform state mv` ve `state rm` ne zaman

### 16. Container imajını küçültmek için ne yaparsın?

**Ne göstermeli:**
- Multi-stage build (build deps runtime'da yok)
- Distroless / Alpine / Chainguard base
- `.dockerignore`
- `RUN` komutlarını birleştir, `apt-get clean` + `rm -rf /var/lib/apt/lists/*`
- `dive` ile layer analizi

### 17. CI pipeline 30 dakikada koşuyor — nasıl hızlandırırsın?

**Ne göstermeli:**
- Profile et — hangi adım yavaş?
- Paralelize (job'lar bağımsızsa)
- Cache (npm, pip, BuildKit registry)
- Test sharding (4 parça paralel)
- Selective test (monorepo'da affected)
- Self-hosted runner (büyük makine)
- Sequential vs DAG pipeline

### 18. Production DB'ye schema migration nasıl?

**Ne göstermeli:**
- Backward-compatible (add column nullable, default değer)
- Backfill ayrı job
- Yeni kod hem eski hem yeni şemayı okur (gerekirse)
- Sonra eski kolon drop (separate deploy)
- Online schema change tools (gh-ost, pt-osc) büyük tablolar için
- Read-heavy: migration sırasında replica drift'i

### 19. Bir endpoint p99 latency 500ms'den 3s'e fırladı. İlk 5 dakikada ne kontrol edersin?

**Ne göstermeli:**
- Recent deploy var mı? (rollback hazır)
- Downstream service latency? (DB, external API)
- DB connection pool exhaust?
- N+1 query (yeni endpoint'te)
- Memory pressure / GC pause
- CPU throttling (limit'e değdi mi?)
- Network: packet loss, DNS slow

### 20. Helm vs Kustomize trade-off?

**Ne göstermeli:**
- Helm: templating güçlü, ama logic dağınık olabilir; chart paketleme avantajı
- Kustomize: pure overlay, kubectl native, daha basit
- Production'da: 3rd-party app için Helm (chart hazır), kendi app için Kustomize
- Sub-chart cehennemi (Helm anti-pattern)

### 21. PostgreSQL prod'da yedek nasıl?

**Ne göstermeli:**
- `pg_dump` küçük DB için OK ama transaction tutarlılığı yok büyük DB'de
- WAL-G / pgBackRest physical + WAL streaming → PITR
- Streaming replica + snapshot
- Restore'u **test et** — hiç restore edilmemiş backup yoktur
- 3-2-1 kuralı (3 kopya, 2 farklı medium, 1 offsite)

### 22. NetworkPolicy nasıl tasarlarsın?

**Ne göstermeli:**
- Default-deny + explicit allow
- DNS allow (kube-system'e UDP/TCP 53)
- Namespace-level + pod-level
- Egress unutulan kısım
- CNI desteği gerekiyor (Cilium, Calico)

### 23. Secret'ları nasıl yönetirsin (Vault yok diyelim)?

**Ne göstermeli:**
- AWS Secrets Manager / GCP Secret Manager / Azure KV (managed)
- External Secrets Operator (ESO) ile K8s'a sync
- Sealed Secrets (Bitnami) — Git'te şifreli
- SOPS (age/PGP)
- ❌ K8s `Secret` plain (etcd'de base64, encrypted-at-rest gerekli)

### 24. Imaj imzalamak niye önemli, nasıl?

**Ne göstermeli:**
- Supply chain saldırısı (registry compromise)
- Cosign keyless OIDC (GitHub Actions identity)
- Cluster'da Kyverno verifyImages
- Sigstore / Rekor transparency log

### 25. Linux'ta bir process %200 CPU yiyor (multi-thread). Kim?

**Ne göstermeli:**
- `top` → process bul
- `pidstat -t -p <PID>` → thread breakdown
- `perf top -p <PID>` → hangi fonksiyon
- eBPF tools (profile-bpfcc)
- Java için `jstack`, `async-profiler`

---

## 🔵 Senior (5-8 yıl) — Cross-cutting tasarım

### 26. Multi-region active-active K8s cluster nasıl tasarlarsın?

**Ne göstermeli:**
- DNS-based failover (Route 53 health check, latency-based routing)
- State problemi: DB multi-region (Aurora Global, Spanner, Cassandra)
- Asenkron data replication trade-off (RPO/RTO)
- Service mesh multi-cluster (Istio mesh, Cilium Cluster Mesh)
- ArgoCD multi-cluster (ApplicationSet)
- Cost ve karmaşıklık artışı — **gerçekten gerek var mı?**

### 27. 100 mikro-servisli organizasyonda standardizasyon nasıl?

**Ne göstermeli:**
- Platform team + golden path templates
- Backstage / IDP
- Service catalog
- Org-wide policy: image signing, NetworkPolicy, observability standartları
- Reusable workflow / chart library
- Runbook standardı

### 28. "Cluster autoscaler vs Karpenter" — hangisi daha iyi?

**Ne göstermeli:**
- Cluster Autoscaler: ASG-based, slow (instance type fixed)
- Karpenter: just-in-time, mixed instance types, faster scale-up
- Karpenter spot strateji daha iyi
- Cluster Autoscaler maturity, ekosistem
- 2026'da Karpenter genelde tercih ediliyor (AWS, ama community port'ları var)

### 29. Production'da incident var, post-mortem'e ne yazarsın?

**Ne göstermeli:**
- Blameless tone (kişi değil sistem)
- Quantified impact
- Timeline UTC dakika hassasiyetinde
- Root cause + niye yakalanmadı (multi-layer)
- Action item'lar measurable, owned, due-date'li

> 📚 [`00-Culture/Blameless-Postmortem-Template.md`](../00-Culture/Blameless-Postmortem-Template.md)

### 30. CI'da "image vulnerability scan HIGH bulgu" → ne yaparsın?

**Ne göstermeli:**
- Vulnerability'i değerlendir: exploitable mı? (sadece sürüm match değil)
- Patch var mı? Base image upgrade
- Yoksa: temporary suppress + ticket + due date
- Asla "ignore" etme — process gerekli
- Trivy `--ignore-unfixed` opsiyonu

### 31. K8s upgrade stratejisi (minor version)?

**Ne göstermeli:**
- Release notes oku, deprecated API'leri grep'le (`kubent`, `pluto`)
- Staging'de test
- Control plane → node pool sırası
- Surge/maxUnavailable ile node rolling
- PDB tespit + öneri
- Add-on'lar (Cilium, ArgoCD) compatibility tablosu
- Rollback stratejisi (managed cluster'da çoğu zaman tek-yön)

### 32. "On-call ekibim alert fatigue yaşıyor" — ne yaparsın?

**Ne göstermeli:**
- Alert audit: hangileri actionable, hangileri "noise"
- Symptom-based vs cause-based ayrımı
- SLO-based alert (sadece error budget burning)
- Severity tier (page vs ticket vs log)
- Escalation policy
- Alert grouping (alertmanager)
- Postmortem'de "alert helpful miydi?" sorusu

### 33. "Pipeline tüm ekipler için aynı olsun" — push-back?

**Ne göstermeli:**
- Stream-aligned vs platform team trade-off
- Reusable workflow + parametrize, ama **enforce** ile esneklik kaybı
- "Golden path" optional, opt-out documented
- Org-wide compliance (image sign) hard, customization soft
- Geliştirici NPS ölç

### 34. "Cloud bill her ay %20 büyüyor, kontrol edemiyoruz"

**Ne göstermeli:**
- Tagging policy enforce (önce burası)
- Showback dashboard her ekibe
- Anomaly detection (Cost Explorer + Slack)
- Quick wins (idle EC2/EIP, gp2→gp3, snapshot purge)
- Spot strategy (Karpenter + on-demand baseline)
- Reserved/Savings Plan (commit cliff plan)
- PR-time Infracost diff
- FinOps Champion her ekipte

> 📚 [`12-FinOps/Cloud-Cost-Allocation.md`](../12-FinOps/Cloud-Cost-Allocation.md)

### 35. "Platform team mi DevOps team mi?"

**Ne göstermeli:**
- Platform team: developer = customer; ürün gibi yönet
- DevOps team (silo) anti-pattern
- Team Topologies: stream-aligned, enabling, complicated subsystem, platform
- "You build it, you run it" — operasyonel sorumluluk dağıtımı

---

## 🟣 Staff+ (8+ yıl) — Strateji + organizasyon

### 36. Şirket monolit'ten K8s'e geçiyor — 3 yıllık plan?

**Ne göstermeli:**
- "Strangler fig" pattern — bir bir parça taşı, monolit'le paralel
- Önce DevSecOps standardı (image, IaC, observability)
- Sonra ilk pilot servis (low-risk)
- Platform yatırımı (Backstage, ArgoCD, golden path)
- Org change management (ekip yapısı, training, hiring)
- Trade-off: hızlı POC vs sürdürülebilir foundation
- Anti-pattern: "tüm her şeyi 6 ayda K8s'e atalım"

### 37. SRE ekibi nasıl kurarsın?

**Ne göstermeli:**
- "Embedded" vs "centralized" trade-off
- Toil budget %50 — üstüne çıkıyorsa platform yatırımı
- Error budget policy + enforcement
- On-call rotation, fair distribution
- Postmortem ritüeli
- SRE'nin görevi feature deploy etmek değil, **yapılabilir kılmak**

### 38. "5 cluster yönetiyoruz, drift yaşıyoruz" — çözüm?

**Ne göstermeli:**
- GitOps (ArgoCD ApplicationSet ile multi-cluster)
- Single-source-of-truth Git repo
- Manuel `kubectl` yasaklanır (RBAC ile read-only)
- Kyverno ile policy enforcement her cluster'da
- Periodic drift report

### 39. "AI/LLM uygulamaları production'a alıyoruz" — sorumluluk?

**Ne göstermeli:**
- Token cost tracking (per-tenant)
- Prompt versiyonlama + eval harness
- Safety: PII, prompt injection
- Latency profile (TTFT, streaming)
- Model fallback chain
- Trace ID + Langfuse benzeri observability

> 📚 [`15-AI-LLMOps/LLM-in-Production.md`](../15-AI-LLMOps/LLM-in-Production.md)

### 40. "Yıllık DevOps stratejimiz ne olmalı?"

**Ne göstermeli:**
- Mevcut DORA seviyesi → hedef seviye
- Top 3 risk
- Platform yatırımı (Backstage, golden path)
- Security maturity (SLSA, supply chain)
- FinOps maturity (allocation → optimization)
- Sustainability hedefleri (carbon SCI)
- Hiring + skill development plan

---

## 💼 Behavioral (her seviyede sorulur)

### 41. "En zor incident'iniz neydi?"

**Ne göstermeli:**
- STAR (Situation, Task, Action, Result)
- Sayı ver: kaç dakika, kaç user, $$ impact
- Senin rolün net
- Ne öğrendin / değiştirdin (sistemik)
- Blameless tone (başka birini suçlamadan)

### 42. "Bir karar aldın ve yanlış çıktı — örnek?"

**Ne göstermeli:**
- Gerçek bir hata seç (kaçma)
- Karar veriş context'i (nelere baktın)
- Sonuç ne oldu, ne öğrendin
- Aynı duruma şimdi nasıl yaklaşırsın

### 43. "Ekibinde anlaşmazlık olduğunda?"

**Ne göstermeli:**
- "Disagree and commit" prensibi
- Veriye dayalı argüman
- Trade-off dokümante et (ADR)
- Final karar verici net
- Kişiselleşmeden yürütme

### 44. "Niye bu şirket?"

**Ne göstermeli:**
- Şirket araştırması belli olmalı (ürün, son haberler, engineering blog)
- Senin hedeflerinle örtüşmesi
- Spesifik (genel "büyük şirket cool" yetmez)

### 45. "5 yıl sonra nerede görüyorsun?"

**Ne göstermeli:**
- Net yön (staff, principal, manager?)
- Şirket ile yolun örtüşmesi
- "Bilmiyorum" demek de OK ama plan tarafı olmalı

---

## 🧠 Lab / Hands-on tarzı sorular

### 46. "Bir broken cluster veriyorum, fix et"

**Ne yapacak:**
- `kubectl get nodes` → unhealthy node?
- `kubectl get pods -A` → CrashLoopBackOff?
- `kubectl describe` → events
- `kubectl logs --previous`
- Sistematic — random kurcalama yok

### 47. "Bu Dockerfile'da ne yanlış?"

Genelde:
- Root user
- `latest` tag
- `apt-get install` cache temizlenmemiş
- Layer sırası optimize değil
- Healthcheck yok
- Secret build arg'ında

### 48. "Bu YAML'da NetworkPolicy doğru mu?"

Hata türleri:
- Default-deny yok
- DNS unutulmuş (egress)
- Selector eşleşmiyor
- Namespace yanlış

### 49. "Bu Terraform module'da güvenlik problemi?"

- Sensitive output marked değil
- IAM policy `*:*`
- Public access yok-engelleyici
- Encryption disabled
- Logging disabled

### 50. "Bu pipeline'ı nasıl güvenliştirirsin?"

- OIDC yerine static credential
- Secret echo'lanıyor
- Permission scoping yok
- Image signing yok
- Vulnerability scan yok

---

## 🎯 Pratik yaparken

- **Production-like lab kur** — kindcluster, minikube, civo, k3d
- Her hafta bir şey kasten kır (chaos engineering)
- Postmortem yazma alıştırması yap (sahte incident bile olsa)
- GitHub'da bir DevOps repo'su ile portföy göster
- Conferences: KubeCon, DevOpsDays, SREcon konuşmalarını dinle

---

## 🚫 Anti-Pattern

Mülakatta sık görülen tuzaklar — bunlardan kaçın.

| Anti-pattern | Niye kötü | Doğru |
|--------------|-----------|-------|
| Tanım ezberleyip okumak | Mülakatçı deneyim arıyor, Wikipedia değil; takip sorusunda çökersin | Kavramı kendi yaşadığın bir olayla, trade-off vererek anlat |
| "Her zaman X kullanılır" demek | Mutlak ifade tecrübesizlik sinyali; gerçek hayatta her şey bağlama bağlı | "Şu durumda X, şu durumda Y; çünkü..." diye koşula bağla |
| Bilmediğin konuda uydurmak | Yanlış cevap, dürüst "bilmiyorum"dan çok daha kötü; güveni yıkar | "Bunu kullanmadım ama şöyle yaklaşırdım / nasıl öğrenirim" de |
| Problemi netleştirmeden çözüme dalmak | Yanlış soruyu çözersin; sistem tasarımında ölümcül | Önce varsayımları/kısıtları sor, scope'u netleştir, sonra çöz |
| Debug sorusunda rastgele komut denemek | Sistematiksizlik panik gösterir; gerçek incident'te de tehlikeli | Hipotez → ölç → daralt; `describe`/`logs`/`events` sırayla |
| Behavioral'da "biz" diye anlatmak | Senin katkın görünmez; rolün belirsiz kalır | STAR ile **senin** aksiyonunu net ver, sayı ile destekle |
| Eski incident'te başkasını suçlamak | Blameless kültür yoksunluğu; takım oyuncusu değilsin sinyali | Sistemik kök neden + "niye yakalanmadı" + ne değiştirdin |
| Trade-off söylemeden tek doğru sunmak | Senior+ sinyali trade-off farkındalığıdır; tek-boyutlu cevap junior gösterir | Her kararın maliyetini/karmaşıklığını da söyle |
| Soru sormadan teklifi kabul etmek | İlgisizlik/araştırmasızlık sinyali; karşılıklı uyum kaçar | Ürün, ekip yapısı, on-call, teknik borç hakkında hazır soru getir |
| Abartılı/yalan deneyim anlatmak | Derinleşen soruda ortaya çıkar; tüm güveni sıfırlar | Gerçek deneyim + dürüstçe sınırını belirt |

---

## 📋 Checklist

Mülakata girmeden önce hazır olduğunu doğrula.

- [ ] Her seviye için en az 2 gerçek hikaye hazır (STAR formatında, sayısal impact ile)
- [ ] "En zor incident" hikayesi prova edildi — timeline, rolün, öğrenilen ders net
- [ ] "Yanlış çıkan kararım" örneği dürüst ve sistemik dersle hazır
- [ ] Container/K8s/CI-CD/Terraform temel kavramları trade-off ile anlatılabiliyor
- [ ] Debug yaklaşımı sistematik prova edildi (hipotez → ölç → daralt)
- [ ] Sistem tasarımında önce scope/kısıt sorma refleksi yerleşik
- [ ] Whiteboard/ekran paylaşımı ile düşünerek konuşma (think-aloud) çalışıldı
- [ ] Başvurulan şirket araştırıldı: ürün, engineering blog, son haberler, tech stack
- [ ] Mülakatçıya sorulacak en az 5 anlamlı soru hazır (on-call, teknik borç, ekip yapısı)
- [ ] CV'deki her satırı derinleşen takip sorusuna karşı savunabiliyorsun
- [ ] Production-like lab (kind/k3d/minikube) ile pratik yapıldı, eller kirlendi
- [ ] Maaş/seviye beklentisi ve müzakere aralığı önceden belirlendi
- [ ] Teknik ortam test edildi (kamera, mikrofon, IDE/terminal paylaşımı) — remote mülakat için
- [ ] "Bilmiyorum"u dürüstçe söyleyip nasıl öğrenirim ekleme refleksi prova edildi

---

## 📚 Hazırlık kaynakları

- [System Design Interview — Alex Xu]
- [Designing Data-Intensive Applications — Martin Kleppmann]
- [The Phoenix Project — Gene Kim] (DevOps roman, manaj sorusunda söz konusu olur)
- [The DevOps Handbook]
- [Site Reliability Engineering — Google] (ücretsiz online)
- KodeKloud, A Cloud Guru, Linux Foundation kursları

---

> *"Mülakat tanım ezberini değil, trade-off'u kendi yaşadığın incident üzerinden savunabilmeni ölçer; bilmediğini saklamak yerine nasıl öğreneceğini göster."*
