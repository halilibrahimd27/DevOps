# I18N-COVERAGE — Çeviri Durumu ve Öncelik

**Son güncelleme:** 2026-07-24

Plugin: `mkdocs-static-i18n` · `docs_structure: suffix` (`X.<locale>.md`) ·
`fallback_to_default: true`.

**EN kapsama:** 158 site sayfası / 334 TR temel sayfası ≈ **%47.3** (Aşama B eşiği %60).
(P0: 3 sayfa + P1a rehber twin'leri: 9 sayfa + P1b Blok A+B: 12 sayfa + P1b Blok C+D:
12 sayfa + P1b Blok E+F: 11 sayfa + P2 21 klasör README'si: 21 sayfa + P3 slice-1: 5 deep-dive
+ P3 slice-2: 5 deep-dive + P3 slice-3: 5 deep-dive + P4 slice-1: 5 deep-dive
+ P4 slice-2: 5 deep-dive + P4 slice-3: 5 deep-dive + P4 slice-4: 5 deep-dive + P4 slice-5: 5 deep-dive + P4 slice-6: 5 deep-dive + P4 slice-7: 5 deep-dive + P4 slice-8: 5 deep-dive + P4 slice-9: 5 deep-dive + P4 slice-10: 5 deep-dive + P4 slice-11: 5 deep-dive + P4 slice-12: 5 deep-dive + P4 slice-13: 5 deep-dive + P4 slice-14: 5 deep-dive + P4 slice-15: 5 deep-dive = 158. Kök `README.en.md` GitHub-only, siteye stage edilmez → oran dışı.)

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
| **P4** | Kalan içerik | 🟡 **slice-15 hazır** (2026-07-24) — 5 `.en.md`: `10-Databases-Production/HA-Patroni-Stolon` (#71), `10-Databases-Production/Monitoring-Postgres` (#72), `10-Databases-Production/Operator-Patterns` (#73), `10-Databases-Production/Postgres-Production-Guide` (#74), `10-Databases-Production/StatefulSet-vs-Operator` (#75 → `10-Databases-Production` **tam twin 9/9**) — hepsi kalan 00-21 deep-dive'ları **klasör sırasıyla** (`10-Databases-Production` kalan 5 → **tam twin 9/9** kapandı; README[P2]+Backup-Restore-Patterns/Zero-Downtime-Migrations[P3]+Connection-Pooling[s14] zaten twin). Hiçbirinde anchor-linkli iç ToC yok (`](#`=0, `{ #`=0). 5 paralel çeviri subagent (dosya başına bir, sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`10-Databases-Production/{README,Backup-Restore-Patterns,Zero-Downtime-Migrations,Connection-Pooling}.en.md`) → remediation gerekmedi, ilk çeviride doğru. Bağımsız orchestrator paritesi: başlık 5/5 (40/27/25/61/22), tablo 5/5 (29/21/37/35/27), fence 5/5 (30/30/22/50/18, twin==source), satır deltası **0/0/0/0/0** (tam byte-parite; blank-line 79/79·65/65·56/56·103/103·45/45 de tam parite), gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; render `<article>` body-TR=0, 2/5 python HTML ayrıştırması [Postgres-Production-Guide + Operator-Patterns]), link locale-eksiz (0 sızıntı), positioning/pazarlama (TR+EN) **0 hit**. Verbatim korundu: Patroni/Stolon HA (`patronictl`/`pg_rewind`/`synchronous_mode`/etcd/HAProxy/watchdog/`kind: Cluster`); Monitoring (`pg_stat_statements`/`pg_stat_activity`/`postgres_exporter`/`pg_stat_user_tables`/`n_dead_tup` + PromQL alert); Operator (CloudNativePG/Crunchy PGO/Zalando + `kind: Cluster|postgresql|PostgresCluster`/pgBackRest); Production-Guide (`postgresql.conf`/`pg_hba.conf` + `shared_buffers`/`work_mem`/`wal_level`/`effective_cache_size` + SQL); StatefulSet-vs-Operator (`kind: StatefulSet`/`volumeClaimTemplates`/PVC). Plain-blok prose çevrildi (checklist `[ ]` etiketi / ASCII diyagram etiketi box-char sabit `sync veya async`→`sync or async`/`StatefulSet oluşturur`→`Creates StatefulSet` / kod-yorumu `# standby yoksa write reddedilir`→`# write is rejected if there's no standby` / alert `summary:` string `SPLIT BRAIN: birden fazla primary`→`SPLIT BRAIN: multiple primaries` / anti-pattern tablo başlığı `Niye kötü`→`Why it's bad`). Epigraf figürleri kaynak-sadık (HA "6 ay/6 hafta" downtime — TR kaynakta zaten var, sadık çeviri; yeni iddia değil). qa exit 0 (1 uyarı = önceki `docs/index.en.md` locale-twin FP; yeni kırık link 0), iki-locale build hatasız, 5 sayfa İngilizce render (`site/en/10-Databases-Production/…`, body-TR=0), TR root default korundu, `_planning` sızmadı. EN kapsama %45.8 → %47.3 (158/334). **`10-Databases-Production` artık tam twin (9/9).** **Kalan P4 çok turlu** — sıra slice-16 (`11-SRE/*` klasör sırasıyla → sonra `13-*` … `16-Cheatsheets/` → `17-Templates/` → en son `21-Field-Notes/`). <details><summary>slice-14 (#66–70)</summary>🟡 **slice-14 hazır** (2026-07-24) — 5 `.en.md`: `09-Networking/Ingress-and-Gateway-API` (#66), `09-Networking/Ingress-NGINX-Patterns` (#67), `09-Networking/Network-Troubleshooting` (#68), `09-Networking/Service-Mesh-Comparison` (#69 → `09-Networking` **tam twin 8/8**), `10-Databases-Production/Connection-Pooling` (#70) — hepsi kalan 00-21 deep-dive'ları **klasör sırasıyla** (`09-Networking` kalan 4 → **tam twin 8/8** kapandı; sonra `10-Databases-Production` klasör sırasında `.en.md`'siz ilk 1: Connection-Pooling; README[P2]+Backup-Restore-Patterns[P3]+Zero-Downtime-Migrations[P3] zaten twin). Hiçbirinde anchor-linkli iç ToC yok (`](#`=0, `{ #`=0). 5 paralel çeviri subagent (dosya başına bir, sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`09-Networking/{README,Cilium-eBPF-Intro,DNS-Strategies,Gateway-API-Migration}.en.md`, `10-Databases-Production/{README,Backup-Restore-Patterns,Zero-Downtime-Migrations}.en.md`) → remediation gerekmedi, ilk çeviride doğru. Bağımsız orchestrator paritesi: başlık 5/5 (17/36/73/39/55), tablo 5/5 (17/15/27/55/36), fence 5/5 (10/46/34/24/36, twin==source), satır deltası **0/0/+3/0/+3** (Network-Troubleshooting + Connection-Pooling epigraf/intro prose-wrap; blank-line 86/86·85/85 + list-item 21/21 + H/T/F tam parite → yapı eklenmedi, saf reflow), gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz — Service-Mesh'teki tek `-w` eşleşmesi `could've` içindeki `ve`, İngilizce kasılma FP; render `<article>` body-TR=0, 5/5 python HTML ayrıştırması), link locale-eksiz (0 sızıntı), positioning/pazarlama (TR+EN) **0 hit**. Verbatim korundu: ingress-nginx (`kind: Ingress|IngressClass`/tüm `nginx.ingress.kubernetes.io/*` annotation: `ssl-redirect`/`limit-rps`/`limit-rpm`/`canary`/`canary-by-header`/`rewrite-target`); Gateway API (`kind: HTTPRoute|Gateway|GatewayClass`/`parentRefs`/`backendRefs`); troubleshooting komutları (`kubectl`/`dig`/`nslookup`/`curl`/`tcpdump`/`ss`/`conntrack`/`nsenter` + hata string `NXDOMAIN`/`connection refused`); Service Mesh (Istio/Linkerd/Cilium/Envoy/Ambient + `kind: VirtualService|DestinationRule|PeerAuthentication`/mTLS/`istioctl`); pooler (`PgBouncer`/`pgcat`/`Odyssey`/`pool_mode = transaction`/`max_client_conn`/`default_pool_size`/`SHOW POOLS`/`max_prepared_statements` + Postgres param). Plain-blok prose çevrildi (checklist `[ ]` etiketi / ASCII diyagram etiketi box-char sabit `eski-app`→`old-app` / kod-yorumu `# 10 req/sec/IP` / anti-pattern tablo başlığı). Epigraf istatistikleri kaynak-sadık (Network-Troubleshooting "30% … network-related", Connection-Pooling "40% … pool exhaustion" — TR kaynakta zaten var, sadık çeviri; yeni iddia değil). qa exit 0 (1 uyarı = önceki `docs/index.en.md` locale-twin FP; yeni kırık link 0), iki-locale build hatasız, 5 sayfa İngilizce render (`site/en/…`, body-TR=0), TR root default korundu, `_planning` sızmadı. EN kapsama %44.3 → %45.8 (153/334). **`09-Networking` tam twin (8/8); `10-Databases-Production` 4/9** (README[P2] + Backup-Restore-Patterns[P3] + Zero-Downtime-Migrations[P3] + bu tur Connection-Pooling; kalan `HA-Patroni-Stolon`+`Monitoring-Postgres`+`Operator-Patterns`+`Postgres-Production-Guide`+`StatefulSet-vs-Operator` → slice-15). **Kalan P4 çok turlu** — sıra slice-15 (`10-Databases-Production/*` kalan 5 → `11-SRE/*` klasör sırasıyla). <details><summary>slice-13 (#61–65)</summary>🟡 **slice-13 hazır** (2026-07-24) — 5 `.en.md`: `08-Security/SLSA-and-SBOM` (#61 → `08-Security` **tam twin 10/10**), `08-Security/Zero-Trust-Networking` (#62), `09-Networking/Cilium-eBPF-Intro` (#63), `09-Networking/DNS-Strategies` (#64), `09-Networking/Gateway-API-Migration` (#65) — hepsi kalan 00-21 deep-dive'ları **klasör sırasıyla** (`08-Security` kalan 2 → **tam twin 10/10** kapandı; sonra `09-Networking` klasör sırasında `.en.md`'siz ilk 3; README[P2] zaten twin). Hiçbirinde anchor-linkli iç ToC yok (`](#`=0, `{ #`=0). 5 paralel çeviri subagent (dosya başına bir, sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`08-Security/{Kubernetes-Hardening,Runtime-Security,Policy-as-Code-OPA-Kyverno,DevSecOps-Pipeline,Container-Image-Scanning}.en.md`, `09-Networking/README.en.md`) → remediation gerekmedi, ilk çeviride doğru. Bağımsız orchestrator paritesi: başlık 5/5 (37/41/47/41/32), tablo 5/5 (37/50/24/23/49), fence 5/5 (26/36/32/36/28, twin==source), satır deltası **0/0/0/0/0** (tam byte-parite), gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; render `<article>` body-TR=0, 5/5 python HTML ayrıştırması), link locale-eksiz (0 sızıntı), positioning/pazarlama (TR+EN) **0 hit**. Verbatim korundu: SLSA/SBOM/Sigstore (`cosign sign`/`syft`/`grype`/`slsa-verifier`/in-toto/provenance/SPDX/CycloneDX/Rekor/Fulcio); Zero-Trust (`kind: NetworkPolicy`/`podSelector`/`ingress`/`egress`/mTLS/SPIFFE/SPIRE/Cilium/Istio/Linkerd); Cilium/eBPF (`cilium status`/`hubble observe`/`CiliumNetworkPolicy`/XDP/Tetragon/kube-proxy); DNS (`dig`/`nslookup`/A/AAAA/CNAME/SRV/CoreDNS/`Corefile`/ndots/`/etc/resolv.conf`); Gateway API (`kind: HTTPRoute|Gateway|GatewayClass`/`gateway.networking.k8s.io`/`parentRefs`/`backendRefs`). Plain-blok prose çevrildi (checklist `[ ]` etiketi / ASCII diyagram etiketi box-char sabit / kod-yorumu `# …`). Epigraf tarihleri kaynak-sadık (Zero-Trust "SolarWinds'ten beri … 2026" kaynakta öyle yazılı, sadık çeviri). qa exit 0 (1 uyarı = önceki `docs/index.en.md` locale-twin FP; yeni kırık link 0), iki-locale build hatasız, 5 sayfa İngilizce render (`site/en/…`, body-TR=0), TR root default korundu, `_planning` sızmadı. EN kapsama %42.8 → %44.3 (148/334). **`08-Security` tam twin (10/10); `09-Networking` 4/8** (README[P2] + bu tur 3; kalan `Ingress-and-Gateway-API`+`Ingress-NGINX-Patterns`+`Network-Troubleshooting`+`Service-Mesh-Comparison` → slice-14). **Kalan P4 çok turlu** — sıra slice-14 (`09-Networking/*` kalan 4 → `10-Databases-Production/*` klasör sırasıyla). <details><summary>slice-12 (#56–60)</summary>🟡 **slice-12 hazır** (2026-07-24) — 5 `.en.md`: `07-Observability/Prometheus-Grafana-K8s-Setup` (#56 → `07-Observability` **tam twin 9/9**), `07-Observability/Tracing-with-Tempo` (#57), `08-Security/Container-Image-Scanning` (#58), `08-Security/Policy-as-Code-OPA-Kyverno` (#59), `08-Security/Runtime-Security` (#60) — hepsi kalan 00-21 deep-dive'ları **klasör sırasıyla** (`07-Observability` kalan 2 → 9/9 kapandı; sonra `08-Security` klasör sırasında `.en.md`'siz ilk 3: Container-Image-Scanning/Policy-as-Code-OPA-Kyverno/Runtime-Security; README[P2]+Kubernetes-Hardening[P3]+Threat-Modeling[P3]+Secrets-Management[P3]+DevSecOps-Pipeline[P3] zaten twin'liydi). **Prometheus-Grafana-K8s-Setup anchor-linkli 8-girdi iç ToC içerir** → başlıklar çevrildikten sonra ToC anchor'ları GitHub-slug ile yeniden üretildi (8/8 çözülüyor: `#system-requirements`…`#useful-commands`); diğer 4'te anchor-ToC yok. 5 paralel çeviri subagent, dosya başına bir (sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard referans (`07-Observability/Prometheus-Best-Practices.en.md`+`OpenTelemetry-Adoption.en.md`+`README.en.md`, `08-Security/Kubernetes-Hardening.en.md`+`Threat-Modeling.en.md`+`DevSecOps-Pipeline.en.md`+`README.en.md`) → remediation gerekmedi, ilk çeviride doğru. Plain/untagged blok prose çevrildi (Falco `desc:`/`output:` prose string; Kyverno/Rego `msg`/`message:` string; ASCII admission-flow + shift-left diyagram etiketleri box-char sabit; kod-yorumu `# Sadece CRITICAL/HIGH`→`# Only CRITICAL/HIGH`; anti-pattern tablo başlığı `Niye kötü`→`Why it's bad`/`Doğru`→`Correct`; `%X`→`X%`, `dk`→`min`; Grafana patch fake-value `"yeni-sifre"`→`"new-password"`, `admin123!` anti-pattern örneği verbatim). Verbatim korundu: Trivy/Grype/Snyk (`trivy image`/`--severity CRITICAL,HIGH`/`--ignore-unfixed`/`--format sarif`) + SBOM/Cosign; OPA/Rego (`package …`/`violation[{"msg": msg}]`/`input.review.object…`/`sprintf`) + Kyverno (`kind: ClusterPolicy`/`validationFailureAction: Enforce|Audit`) + Gatekeeper/ConstraintTemplate; Falco/Tetragon (`condition:`/`proc.name`/`evt.type`/`priority:`/seccomp/AppArmor/eBPF/syscall); Tempo/OTel (`OTLP`/`OTLPSpanExporter`/`receivers:`/`exporters:`/`trace_id`/`traceparent`/Jaeger/Zipkin); Prometheus/Grafana/Helm (`helm install/repo/upgrade`/`kube-prometheus-stack`/`kubectl patch`/NodePort/PVC); placeholder EN-kanonik (`<REGISTRY>`/`<APP>`/`<TAG>`/`<IMAGE>`/`<NAMESPACE>`/`<GRAFANA_ADMIN_PASSWORD>`/`<NS>`/`<WAZUH_MANAGER>`/`<TETRAGON_POD>`); link-target locale-eksiz (`Kubernetes-Hardening.md`, `SLSA-and-SBOM.md`, `OpenTelemetry-Adoption.md`, `Logs-Loki-vs-ELK.md`, `../17-Templates/kyverno-policies/`). Bağımsız orchestrator paritesi: başlık 5/5 (103/34/48/49/41), tablo 5/5 (12/12/39/36/59), fence 5/5 (46/30/36/40/32, twin==source), satır deltası **0/0/0/0/0** (tam byte-parite), gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime temiz, 5/5; render `<article>` body-TR=0, 5/5 python HTML ayrıştırması), link locale-eksiz (0 sızıntı), positioning/pazarlama (TR+EN) **0 hit**. qa exit 0 (1 uyarı = önceki `docs/index.en.md` locale-twin FP; yeni kırık link 0), iki-locale build hatasız, 5 sayfa İngilizce render (`site/en/…`, body-TR=0), TR root default korundu, `_planning` sızmadı. EN kapsama %41.3 → %42.8 (143/334). **`07-Observability` tam twin (9/9); `08-Security` 8/10** (README+4 P3 + bu tur 3 = 8; kalan `SLSA-and-SBOM` + `Zero-Trust-Networking` → slice-13). **Slice-1..11 önceki turlar.** **Kalan P4 çok turlu** — sıra slice-13 (`08-Security/*` kalan 2 → `09-Networking/*` klasör sırasıyla). </details></details></details> |

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
| 56 | `07-Observability/Prometheus-Grafana-K8s-Setup.md` (anchor-ToC 8/8 regen; → `07-Observability` tam twin 9/9) | **12 ✅** |
| 57 | `07-Observability/Tracing-with-Tempo.md` | **12 ✅** |
| 58 | `08-Security/Container-Image-Scanning.md` | **12 ✅** |
| 59 | `08-Security/Policy-as-Code-OPA-Kyverno.md` | **12 ✅** |
| 60 | `08-Security/Runtime-Security.md` | **12 ✅** (08-Security'de README[P2]+Kubernetes-Hardening[P3]+Threat-Modeling[P3]+Secrets-Management[P3]+DevSecOps-Pipeline[P3] zaten twin; kalan `SLSA-and-SBOM`+`Zero-Trust-Networking` → slice-13) |
| 61 | `08-Security/SLSA-and-SBOM.md` (→ `08-Security` **tam twin 10/10**) | **13 ✅** |
| 62 | `08-Security/Zero-Trust-Networking.md` | **13 ✅** |
| 63 | `09-Networking/Cilium-eBPF-Intro.md` | **13 ✅** |
| 64 | `09-Networking/DNS-Strategies.md` | **13 ✅** |
| 65 | `09-Networking/Gateway-API-Migration.md` | **13 ✅** (09-Networking'de README[P2] zaten twin; kalan `Ingress-and-Gateway-API`+`Ingress-NGINX-Patterns`+`Network-Troubleshooting`+`Service-Mesh-Comparison` → slice-14) |
| 66 | `09-Networking/Ingress-and-Gateway-API.md` | **14 ✅** |
| 67 | `09-Networking/Ingress-NGINX-Patterns.md` | **14 ✅** |
| 68 | `09-Networking/Network-Troubleshooting.md` | **14 ✅** |
| 69 | `09-Networking/Service-Mesh-Comparison.md` (→ `09-Networking` **tam twin 8/8**) | **14 ✅** |
| 70 | `10-Databases-Production/Connection-Pooling.md` | **14 ✅** (10-Databases-Production'da README[P2]+Backup-Restore-Patterns[P3]+Zero-Downtime-Migrations[P3] zaten twin; kalan `HA-Patroni-Stolon`+`Monitoring-Postgres`+`Operator-Patterns`+`Postgres-Production-Guide`+`StatefulSet-vs-Operator` → slice-15) |
| 71 | `10-Databases-Production/HA-Patroni-Stolon.md` | **15 ✅** |
| 72 | `10-Databases-Production/Monitoring-Postgres.md` | **15 ✅** |
| 73 | `10-Databases-Production/Operator-Patterns.md` | **15 ✅** |
| 74 | `10-Databases-Production/Postgres-Production-Guide.md` | **15 ✅** |
| 75 | `10-Databases-Production/StatefulSet-vs-Operator.md` | **15 ✅** (→ `10-Databases-Production` **tam twin 9/9**) |
| 76+ | sonra kalan 00-21 deep-dive'ları klasör sırasıyla (`11-SRE/*`, `12-FinOps` tam, `13-*`, …) → `16-Cheatsheets/` (kalan 8) → `17-Templates/` index'leri → en son `21-Field-Notes/` | 16+ |

## Notlar

- KVKK/BDDK/TR dokümanları EN versiyonda da **kalır** — global okur için "AB dışı
  bir veri koruma rejimi mühendislik kontrolüne nasıl çevrilir" örneği.
- EN kapsama oranı = (EN `.en.md` sayfa sayısı) / (toplam TR sayfa sayısı). Aşama B
  eşiği %60. Bu oran her i18n artışında burada güncellenir.

> *Çeviri zemin kuruldu; içerik çevirileri P0'dan başlayarak artımlı gelir.*
