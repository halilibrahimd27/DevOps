# I18N-COVERAGE — Çeviri Durumu ve Öncelik

**Son güncelleme:** 2026-07-24

Plugin: `mkdocs-static-i18n` · `docs_structure: suffix` (`X.<locale>.md`) ·
`fallback_to_default: true`.

**EN kapsama:** 138 site sayfası / 334 TR temel sayfası ≈ **%41.3** (Aşama B eşiği %60).
(P0: 3 sayfa + P1a rehber twin'leri: 9 sayfa + P1b Blok A+B: 12 sayfa + P1b Blok C+D:
12 sayfa + P1b Blok E+F: 11 sayfa + P2 21 klasör README'si: 21 sayfa + P3 slice-1: 5 deep-dive
+ P3 slice-2: 5 deep-dive + P3 slice-3: 5 deep-dive + P4 slice-1: 5 deep-dive
+ P4 slice-2: 5 deep-dive + P4 slice-3: 5 deep-dive + P4 slice-4: 5 deep-dive + P4 slice-5: 5 deep-dive + P4 slice-6: 5 deep-dive + P4 slice-7: 5 deep-dive + P4 slice-8: 5 deep-dive + P4 slice-9: 5 deep-dive + P4 slice-10: 5 deep-dive + P4 slice-11: 5 deep-dive = 138. Kök `README.en.md` GitHub-only, siteye stage edilmez → oran dışı.)

## Aşama

- **Aşama A (şimdi):** TR varsayılan (kök `X.md` = `X.tr.md` eşdeğeri), EN `/en/`
  altında **kısmi**. Çevirisi olmayan sayfa TR içeriğine fallback eder → iki-locale
  build fallback ile hatasız geçer.
- **Aşama B (sonra):** EN kapsama **≥ %60** olunca EN varsayılan yapılır
  (`default: true` en'e taşınır, TR `/tr/`'ye iner). **Şimdi yapma.**

## Kurallar

- İç linkler locale eki OLMADAN yazılır: `[x](Kubernetes-Hardening.md)` ✅ /
  `Kubernetes-Hardening.tr.md` ❌ (plugin locale'i kendi ekler).
- Yeni yazılan patika içeriği baştan **iki dilli** üretilir (`X.md` + `X.en.md`
  ya da `X.tr.md` + `X.en.md`).

## Öncelik ve durum

| Öncelik | Kapsam | Durum |
|---|---|---|
| **P0** | `README`, `docs/index`, `docs/about`, `Glossary` | ✅ **EN twin hazır** (2026-07-23) — `README.en.md`, `docs/index.en.md`, `docs/about.en.md`, `Glossary.en.md`. build-docs.sh 3 site sayfasını stage ediyor; iki-locale build hatasız. |
| **P1a** | Patika omurgası — **9 rehber dosyası** (`22-Learning-Path/` README, CURRICULUM, NOT-YET, PLACEMENT, PROGRESS-TEMPLATE, STUDY-METHOD, COST-GUARDRAILS, TROUBLESHOOTING, PORTFOLIO) | ✅ **EN twin hazır** (2026-07-23) — 9 `.en.md` üretildi (9 paralel çeviri subagent, dosya başına bir, sıkı ruleset). Başlık paritesi 9/9, link locale-eksiz, positioning temiz, mermaid/tablo yapısı korundu. build-docs.sh `2[0-9]-*` `cp -r` ile hepsini özyineli stage ediyor; iki-locale build hatasız, `/en/…/CURRICULUM/` İngilizce render. |
| **P1b** | Patika omurgası — **30 modül** + **5 STAGE-EXAM** twin'i `block-*/<ID>-*.en.md` (A0…F5) | ✅ **EN twin hazır — tüm bloklar (A0…F5 + A–E STAGE-EXAM)** (2026-07-23). Bu tur 11 twin: E1–E5 + Blok E STAGE-EXAM (6) · F1–F5 (5, **Blok F'de STAGE-EXAM yok**). Önceki turlar: A+B (12) · C+D (12). Toplam 35 dosya (30 modül + 5 STAGE-EXAM). Her dilim: 12/11 paralel çeviri subagent, dosya başına bir, sıkı ruleset. Bu tur başlık paritesi 11/11, link locale-eksiz (0 sızıntı), positioning/pazarlama (TR+EN) temiz, kod-yorumu çevrildi/komut+YAML+SQL verbatim; F-blok ortak `## 🔨 Deliverable exercise` başlığı 5/5 tutarlı; güvenlik ipliği (E4 backup at-rest/erişim, F2 KVKK→GDPR→SOC 2 kontrol zinciri) korundu; `/en/…/E1-sli-slo-error-budget/` + `/en/…/F2-tehdit-uyum/` İngilizce render, qa exit 0. `qa.py` locale-farkındalığı (`LOCALE_RE`) modül twin'lerini bütünlük denetiminden muaf tutuyor. |
| **P2** | 21 klasör README'si | ✅ **EN twin hazır** (2026-07-23) — 21 `.en.md` (`00-Culture` … `20-Soft-Skills`). 11'i (00–10) önceki kesintili turdan **untracked** geldi (structure-preserving; başlık/tablo paritesi + link-leak + positioning doğrulandı → benimsendi); 10'u (11–20) bu tur 10 paralel çeviri subagent (sonnet), dosya başına bir, sıkı ruleset ile üretildi. Başlık/tablo paritesi 21/21, link locale-eksiz (0 sızıntı), positioning/pazarlama (TR+EN) temiz, KVKK 19-Compliance'ta global-okur çerçevesiyle reframe. build-docs.sh `0[0-9]-*/1[0-9]-*` `cp -r` ile özyineli stage (ek satır gerekmedi); `/en/19-Compliance/` + `/en/11-SRE/` İngilizce render, qa exit 0. |
| **P3** | En güçlü 15 deep-dive | ✅ **EN twin hazır — 15/15 tamam** (2026-07-23) — slice-3 = deep-dive 11–15 (count-4 DevSecOps güvenlik+güvenilirlik çekirdeği): `08-Security/Secrets-Management.en.md`, `08-Security/DevSecOps-Pipeline.en.md`, `11-SRE/Incident-Response.en.md`, `10-Databases-Production/Backup-Restore-Patterns.en.md`, `11-SRE/Chaos-Engineering.en.md`. 5 paralel çeviri subagent, dosya başına bir, **düzeltilmiş genişletilmiş ruleset** (slice-2 dersini baştan uyguladı): plain/untagged fenced blok içindeki prose (checklist `[ ]` etiketi, ASCII decision-tree/flow-diagram etiketi `EVET`→`YES`/`HAYIR`→`NO`, kod yorumu `# tek seferlik`→`# one-shot`, template örnek satırı, Kyverno `message:`) İngilizce'ye çevrildi; yalnız gerçek verbatim-artifact (komut, YAML key + `kind: PodChaos`/`NetworkChaos`, metric/PromQL `http_5xx_rate > 0.05`, path, link target, SHA-pin action ref) korundu. Bağımsız orchestrator doğrulaması: başlık paritesi 5/5 (63/33/30/50/28), tablo 5/5 (45/21/43/42/60), fence 5/5 (50/28/12/32/20), gerçek Türkçe kalıntısı **0** (excl `/var/`+VERBİS), link locale-eksiz (0 sızıntı), positioning/pazarlama (TR+EN) temiz (yalnız Chaos "ROI report" = kaynakta zaten var, sadık çeviri + qa scope dışı FP). Satır deltası 0/0/-1/-1/+1 (prose-wrap + Incident 1 satır "no Turkish translation" reframe). build-docs.sh dokunulmadı (`0[0-9]-*/1[0-9]-*` `cp -r` otomatik stage); 5 sayfa `/en/…/` İngilizce render (EN-marker 176/80/90/135/100), iki-locale build hatasız, qa exit 0. slice-1 (K8s-Hardening, Threat-Modeling, SLI-SLO, Pipeline-Patterns, KVKK) + slice-2 (Documentation, linux-troubleshooting, Prometheus-Best-Practices, Alerting-Done-Right, Blameless-Postmortem) önceki turlar. **P3 kapandı → sıra P4 (kalan içerik).** |
| **P4** | Kalan içerik | 🟡 **slice-11 hazır** (2026-07-24) — 5 `.en.md`: `03-IaC/Pulumi-vs-Terraform` (#51), `03-IaC/Terraform-Module-Layout` (#52 → `03-IaC` **tam twin 7/7**), `07-Observability/Logs-Loki-vs-ELK` (#53), `07-Observability/OpenTelemetry-Adoption` (#54), `07-Observability/Profiling-with-Pyroscope` (#55) — hepsi kalan 00-21 deep-dive'ları **klasör sırasıyla** (`03-IaC` kalan 2 → `03-IaC` 7/7 kapandı; sonra `07-Observability` klasör sırasında `.en.md`'siz ilk 3: Logs-Loki-vs-ELK/OpenTelemetry-Adoption/Profiling-with-Pyroscope; README[P2]+Prometheus-Best-Practices[P3]+Alerting-Done-Right[P3]+SLO-Engineering[P4-s4] zaten twin'liydi). Hiçbirinde anchor-linkli iç ToC yok (`](#`=0, `{ #`=0). 5 paralel çeviri subagent, dosya başına bir (sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard referans (`03-IaC/Terraform-Best-Practices.en.md`+`OpenTofu-Migration.en.md`+`README.en.md`, `07-Observability/Prometheus-Best-Practices.en.md`+`SLO-Engineering.en.md`+`Alerting-Done-Right.en.md`+`README.en.md`) → remediation gerekmedi, ilk çeviride doğru. Plain/untagged blok prose çevrildi (Pulumi decision-tree etiketleri + Mocha test string'i `"S3 bucket adı doğru"`→`"S3 bucket name is correct"`; OTel mimari/trace-propagation ASCII diyagram etiketleri box-char sabit; kod-yorumu `# Tüm log`→`# All logs`/`# %1 sample DEBUG, %100 ERROR`→`# 1% sample DEBUG, 100% ERROR`; anti-pattern tablo başlığı `Niye kötü`→`Why it's bad`/`Doğru`→`Correct approach`; `%X`→`X%`, `dk`→`min`, `7/24`→`24/7`). Verbatim korundu: HCL/Terraform (`resource`/`module`/`variable`/`output`/`for_each`/`backend`/`terraform init/plan/apply`, dizin-ağacı `main.tf`/`variables.tf`/`outputs.tf`/`modules/`/`environments/`); Pulumi (`pulumi up/preview`/`Pulumi.yaml`/`@pulumi/aws`/ComponentResource/StackReference); LogQL (`{app="…"}`/`|=`/`|~`/`rate()`/`count_over_time`) + Loki/Grafana/Elasticsearch/Logstash/Kibana/Fluentd/Promtail/Vector; OTel (`OTEL_*` env, `OTLP`/Collector/`receivers:`/`processors:`/`exporters:`/`pipelines:`/`service.name`/semantic conventions, Jaeger/Tempo/Zipkin); Pyroscope/pprof/flame-graph/eBPF/Parca + profil türleri (CPU/heap/goroutine/mutex/block); placeholder EN-kanonik (`<VERSION>`/`<REGION>`/`<NAMESPACE>`/`<SERVICE>`/`<ENDPOINT>`); link-target locale-eksiz (`Terraform-Best-Practices.md`, `OpenTofu-Migration.md`, `Crossplane-Intro.md`, `../22-Learning-Path/block-c-reproducibility/C3-terraform.md`, `OpenTelemetry-Adoption.md`, `Tracing-with-Tempo.md`, `Prometheus-Best-Practices.md`, `../19-Compliance/Audit-Evidence-Automation.md`). Bağımsız orchestrator paritesi: başlık 5/5 (25/40/36/37/29), tablo 5/5 (34/20/30/33/18), fence 5/5 (18/40/26/22/28, twin==source), satır deltası **0/0/0/0/0** (tam byte-parite), gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime temiz, 5/5; render `<article>` body-TR=0), link locale-eksiz (0 sızıntı), positioning/pazarlama (TR+EN) **0 hit**. qa exit 0 (1 uyarı = önceki `docs/index.en.md` locale-twin FP; yeni kırık link 0), iki-locale build hatasız, 5 sayfa İngilizce render (`site/en/…`, body-TR=0), TR root default korundu, `_planning` sızmadı. EN kapsama %39.8 → %41.3 (138/334). **`03-IaC` tam twin (7/7); `07-Observability` 7/9** (README+Prometheus-Best-Practices+Alerting-Done-Right+SLO-Engineering önceki turlar + bu tur 3 = 7; kalan `Prometheus-Grafana-K8s-Setup` + `Tracing-with-Tempo` → slice-12). **Slice-1..10 önceki turlar.** **Kalan P4 çok turlu** — sıra slice-12 (`07-Observability/*` kalan 2 → `08-Security/*` klasör sırasıyla). |

### P3 — 15 deep-dive listesi ve seçim kuralı

**Objektif kural:** patika modüllerinin `## 📖 Önce oku` (+ diğer) tablolarındaki `../../NN-*` link
sayısı sayılır (`grep -rho '\](\.\./\.\./[0-9][0-9]-[^)]*\.md)' block-*/ | sort | uniq -c | sort -rn`).
**Sıra:** (1) count-6 olan 7 doküman → (2) CLAUDE.md "İyi doküman" 5 örneğinin count-6 dışında
kalanı (K8s-Hardening, SLI-SLO, Pipeline-Patterns) → (3) kalan 5 slot count-4'ten DevSecOps
güvenlik+güvenilirlik çekirdeğiyle doldurulur. (count-4 tier'ı 27 dokümanla eşit; tiebreak =
CLAUDE.md örnekleri + güvenlik ipliği.)

| # | Deep-dive | count | Slice |
|---|---|---|---|
| 1 | `08-Security/Kubernetes-Hardening.md` | 4 (exemplar) | **1 ✅** |
| 2 | `08-Security/Threat-Modeling.md` | 6 (exemplar) | **1 ✅** |
| 3 | `11-SRE/SLI-SLO-Error-Budget.md` | 4 (exemplar) | **1 ✅** |
| 4 | `02-CI-CD/Pipeline-Patterns.md` | 4 (exemplar) | **1 ✅** |
| 5 | `19-Compliance/KVKK-Practical.md` | 6 (exemplar) | **1 ✅** |
| 6 | `20-Soft-Skills/Documentation-as-Communication.md` | 6 | **2 ✅** |
| 7 | `16-Cheatsheets/linux-troubleshooting.md` | 6 | **2 ✅** |
| 8 | `07-Observability/Prometheus-Best-Practices.md` | 6 | **2 ✅** |
| 9 | `07-Observability/Alerting-Done-Right.md` | 6 | **2 ✅** |
| 10 | `00-Culture/Blameless-Postmortem-Template.md` | 6 | **2 ✅** |
| 11 | `08-Security/Secrets-Management.md` | 4 | **3 ✅** |
| 12 | `08-Security/DevSecOps-Pipeline.md` | 4 | **3 ✅** |
| 13 | `11-SRE/Incident-Response.md` | 4 | **3 ✅** |
| 14 | `10-Databases-Production/Backup-Restore-Patterns.md` | 4 | **3 ✅** |
| 15 | `11-SRE/Chaos-Engineering.md` | 4 | **3 ✅** |

> **Yakın-kaçıran (bilinçli P4):** `20-Soft-Skills/{Vendor,Stakeholder,Saying-No}`, `13-Platform-Engineering/*`,
> `12-FinOps/*`, `10-Databases-Production/Zero-Downtime-Migrations.md`, `07-Observability/SLO-Engineering.md`,
> `06-GitOps/*`, `05-Kubernetes/*`, `04-Containers/*`, `03-IaC/Terraform-Best-Practices.md` — hepsi count-4,
> 15'in dışında kaldı; P4'te gelir.

### P4 — dilim planı (deterministik, 5 dosya/dilim, güçten zayıfa)

Önce "yakın-kaçıran" listesi (count-4, sıra yukarıdaki gibi) → sonra kalan 00-21 deep-dive'ları klasör
sırasıyla → `16-Cheatsheets/` → `17-Templates/` index'leri → en son `21-Field-Notes/`.

| # | Dosya | Dilim |
|---|---|---|
| 1 | `20-Soft-Skills/Vendor-Management.md` | **1 ✅** |
| 2 | `20-Soft-Skills/Stakeholder-Management.md` | **1 ✅** |
| 3 | `20-Soft-Skills/Saying-No.md` | **1 ✅** |
| 4 | `13-Platform-Engineering/Backstage-Setup.md` | **1 ✅** |
| 5 | `13-Platform-Engineering/Golden-Paths.md` | **1 ✅** |
| 6 | `13-Platform-Engineering/Internal-Developer-Platform.md` | **2 ✅** |
| 7 | `13-Platform-Engineering/Platform-as-Product.md` | **2 ✅** |
| 8 | `13-Platform-Engineering/Service-Catalog.md` | **2 ✅** |
| 9 | `12-FinOps/Cloud-Cost-Allocation.md` | **2 ✅** |
| 10 | `12-FinOps/Egress-Cost-Reduction.md` | **2 ✅** |
| 11 | `12-FinOps/Kubecost-Setup.md` | **3 ✅** |
| 12 | `12-FinOps/PR-Cost-Diff.md` | **3 ✅** |
| 13 | `12-FinOps/Reserved-and-Savings-Plans.md` | **3 ✅** |
| 14 | `12-FinOps/Right-Sizing.md` | **3 ✅** |
| 15 | `12-FinOps/Spot-Instance-Strategy.md` | **3 ✅** |
| 16 | `12-FinOps/Storage-Cost-Optimization.md` | **4 ✅** |
| 17 | `10-Databases-Production/Zero-Downtime-Migrations.md` | **4 ✅** |
| 18 | `07-Observability/SLO-Engineering.md` | **4 ✅** |
| 19 | `06-GitOps/App-of-Apps-Pattern.md` | **4 ✅** |
| 20 | `06-GitOps/ApplicationSet-Patterns.md` | **4 ✅** |
| 21 | `06-GitOps/ArgoCD-Setup.md` | **5 ✅** |
| 22 | `06-GitOps/Flux-vs-ArgoCD.md` | **5 ✅** |
| 23 | `06-GitOps/Helm-vs-Kustomize-vs-Raw.md` | **5 ✅** |
| 24 | `06-GitOps/Secrets-in-GitOps.md` | **5 ✅** |
| 25 | `05-Kubernetes/Debugging-Pods.md` | **5 ✅** |
| 26 | `05-Kubernetes/HPA-VPA-KEDA.md` | **6 ✅** |
| 27 | `05-Kubernetes/Multi-Tenancy-Patterns.md` | **6 ✅** |
| 28 | `05-Kubernetes/Production-Checklist.md` | **6 ✅** |
| 29 | `05-Kubernetes/Resource-Limits-Guide.md` | **6 ✅** |
| 30 | `05-Kubernetes/Upgrade-Strategy.md` | **6 ✅** (→ `05-Kubernetes` tam twin 7/7) |
| 31 | `04-Containers/BuildKit-Tips.md` | **7 ✅** |
| 32 | `04-Containers/Container-vs-WASM.md` | **7 ✅** |
| 33 | `04-Containers/Distroless-and-Chainguard.md` | **7 ✅** |
| 34 | `04-Containers/Dockerfile-Best-Practices.md` | **7 ✅** |
| 35 | `04-Containers/Image-Signing-Cosign.md` | **7 ✅** (→ `04-Containers` 6/7; README twin'liydi) |
| 36 | `04-Containers/Multi-Stage-Builds.md` (→ `04-Containers` tam twin 7/7) | **8 ✅** |
| 37 | `03-IaC/Terraform-Best-Practices.md` | **8 ✅** |
| 38 | `00-Culture/Documentation-Culture.md` | **8 ✅** |
| 39 | `00-Culture/DORA-SPACE-Metrics.md` | **8 ✅** |
| 40 | `00-Culture/On-Call-Playbook.md` | **8 ✅** |
| 41 | `00-Culture/Team-Topologies.md` (→ `00-Culture` tam twin 8/8) | **9 ✅** |
| 42 | `02-CI-CD/Caching-Strategies.md` | **9 ✅** |
| 43 | `02-CI-CD/GitHub-Actions-Recipes.md` | **9 ✅** |
| 44 | `02-CI-CD/GitLab-CI-Recipes.md` | **9 ✅** |
| 45 | `02-CI-CD/Mobile-CICD-Flutter.md` | **9 ✅** (→ `02-CI-CD` 6/8; Pipeline-Patterns[P3]+README[P2] twin'liydi) |
| 46 | `02-CI-CD/Pipeline-Performance.md` | **10 ✅** |
| 47 | `02-CI-CD/Reusable-Workflows.md` (→ `02-CI-CD` tam twin 8/8) | **10 ✅** |
| 48 | `03-IaC/Crossplane-Intro.md` | **10 ✅** |
| 49 | `03-IaC/Drift-Detection.md` | **10 ✅** |
| 50 | `03-IaC/OpenTofu-Migration.md` | **10 ✅** |
| 51 | `03-IaC/Pulumi-vs-Terraform.md` | **11 ✅** |
| 52 | `03-IaC/Terraform-Module-Layout.md` (→ `03-IaC` tam twin 7/7) | **11 ✅** |
| 53 | `07-Observability/Logs-Loki-vs-ELK.md` | **11 ✅** |
| 54 | `07-Observability/OpenTelemetry-Adoption.md` | **11 ✅** |
| 55 | `07-Observability/Profiling-with-Pyroscope.md` | **11 ✅** (07-Observability'de README[P2]+Prometheus-Best-Practices[P3]+Alerting-Done-Right[P3]+SLO-Engineering[P4-s4] zaten twin; kalan `Prometheus-Grafana-K8s-Setup`+`Tracing-with-Tempo` → slice-12) |
| 56+ | sonra kalan 00-21 deep-dive'ları klasör sırasıyla (`07-Observability` kalan 2: `Prometheus-Grafana-K8s-Setup`+`Tracing-with-Tempo`, sonra `08-Security/*`, `09-Networking/*`, …) → `16-Cheatsheets/` (kalan 8) → `17-Templates/` index'leri → en son `21-Field-Notes/` | 12+ |

## Notlar

- KVKK/BDDK/TR dokümanları EN versiyonda da **kalır** — global okur için "AB dışı
  bir veri koruma rejimi mühendislik kontrolüne nasıl çevrilir" örneği.
- EN kapsama oranı = (EN `.en.md` sayfa sayısı) / (toplam TR sayfa sayısı). Aşama B
  eşiği %60. Bu oran her i18n artışında burada güncellenir.

> *Çeviri zemin kuruldu; içerik çevirileri P0'dan başlayarak artımlı gelir.*
