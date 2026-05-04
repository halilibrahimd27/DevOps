# SLSA & SBOM — Supply Chain Integrity

> *"Kodun senden, dependency'lerin başkalarından, build'in CI'dan, runtime'ın
> cluster'dan. Aralarında biri bozulsa, **kim suçlu**? Cevabın yoksa,
> supply chain'in yok demektir."*

SolarWinds (2020), Codecov (2021), Log4Shell (2021), xz-utils (2024) —
saldırılar artık **kaynak koduna** değil, **tedarik zincirine**. Bu
rehber SLSA ve SBOM ile bunu nasıl savunduğunu anlatır.

---

## 🎯 Temel Kavramlar

| Terim | Anlam | Niye önemli |
|---|---|---|
| **Supply chain** | Source → Build → Package → Deploy → Run zinciri | Her halka saldırı vektörü |
| **SBOM** (Software Bill of Materials) | "Bu artifact'in içinde ne var" listesi | Yeni CVE çıktığında etkileneni 5 dakikada bul |
| **SLSA** (Supply-chain Levels for Software Artifacts) | Build pipeline güvenlik seviyeleri (L1-L4) | Tutarlı, denetlenebilir build |
| **Provenance** | "Bu artifact'i kim, ne zaman, hangi commit'ten, hangi build'de üretti" | Forgery'yi imkansızlaştırır |
| **Attestation** | İmzalanmış metadata claim'i | Provenance + scan + license bilgisi |
| **in-toto** | Attestation framework standardı | SLSA'nın altında çalışan format |
| **Sigstore** | Açık kaynak signing infrastructure | cosign, Rekor, Fulcio |
| **Cosign** | Container/artifact signing aracı | Keyless OIDC ile gerçek "imza" |
| **Rekor** | Transparent log (immutable) | İmzalı her şeyin denetim defteri |
| **Fulcio** | Short-lived cert authority | OIDC → kısa ömürlü cert |

---

## 🪜 SLSA Seviyeleri

| Seviye | Hedef | Kontroller |
|---|---|---|
| **L0** | Hiçbir garanti yok | — |
| **L1** | Build prosedürü dokümante | CI script Git'te, manuel ya da otomatik |
| **L2** | Hosted build platform + version control + signed provenance | GitHub Actions / GitLab CI + ephemeral runner |
| **L3** | Hardened build, izole, source-to-build doğrulanır | Reusable workflow + non-falsifiable provenance |
| **L4** *(deprecated v1.0'da, v1.1'de planlanan)* | İki bağımsız reviewer + hermetic build | Bazel-style hermetic build |

> 🔑 **Pratik hedef (2026):** Çoğu kurum için **SLSA L2-L3** ulaşılabilir
> ve faydalı. L4 hermetic build çok ekstrem.

---

## 📦 SBOM — "Yazılım Malzeme Listesi"

### Formatlar

| Format | Sponsor | Kullanım |
|---|---|---|
| **CycloneDX** | OWASP | Endüstri standardı, Trivy default |
| **SPDX** | Linux Foundation | Compliance, lisans odaklı |
| **SWID Tags** | NIST | Zayıf adoption |

> **Pratik:** İkisini de üret. Trivy `--format cyclonedx` ve `--format spdx-json` destekler.

### Niye lazım?
1. **CVE response time:** Log4Shell tarzı bir CVE çıktığında "etkilenen 47 servisim var" demek 30 dakika alır → SBOM'la 30 saniye.
2. **Compliance:** US Executive Order 14028 (federal yazılım), EU Cyber Resilience Act (2024) — SBOM zorunlu.
3. **License audit:** GPL bulaşması, ticari ihlal.
4. **Vendor management:** Tedarikçi yazılımının ne içerdiğini bilmek.

### SBOM üretimi
```bash
# Syft (Anchore)
syft <REGISTRY>/<APP>:<TAG> -o cyclonedx-json > sbom.json
syft dir:. -o spdx-json > sbom-spdx.json

# Trivy
trivy image --format cyclonedx -o sbom.json <IMAGE>
trivy image --format spdx-json -o sbom-spdx.json <IMAGE>

# Docker built-in (Buildx)
docker buildx build --sbom=true --provenance=true -t <APP> .
```

### SBOM nereye konur?
- ✅ **Container registry'de attached attestation** (cosign attest)
- ✅ Release artifact (GitHub Releases attachment)
- ✅ Internal SBOM database (Dependency-Track, OWASP)
- ❌ Sadece CI artifact'i — 90 gün sonra silinir, lazım olduğunda yok

### SBOM diff: dependency'lerin ne değişti?
```bash
# Aynı imajın iki versiyonu arasında fark
sbom-diff sbom-v1.json sbom-v2.json

# CycloneDX CLI
cyclonedx diff sbom-v1.json sbom-v2.json
```

PR'da SBOM diff yorumla → "şu yeni dep eklendi, niye?" otomatik review.

---

## ✍️ Cosign ile İmzalama

### Keyless signing (önerilen, 2026 standart)
Geleneksel: kalıcı private key bir yerde (riskli). **Keyless**: GitHub OIDC ile **anlık** cert al, imzala, cert atılır → Rekor'a log.

```yaml
# .github/workflows/release.yml
permissions:
  id-token: write     # OIDC için
  contents: read
  packages: write

jobs:
  build-sign:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<VERSION>

      - uses: docker/login-action@<VERSION>
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/build-push-action@<VERSION>
        id: build
        with:
          tags: ghcr.io/<ORG>/<APP>:${{ github.sha }}
          push: true

      - name: Install cosign
        uses: sigstore/cosign-installer@<VERSION>

      - name: Sign image (keyless)
        env:
          COSIGN_EXPERIMENTAL: "true"
        run: |
          cosign sign --yes \
            ghcr.io/<ORG>/<APP>@${{ steps.build.outputs.digest }}

      - name: Generate + sign SBOM attestation
        run: |
          syft ghcr.io/<ORG>/<APP>@${{ steps.build.outputs.digest }} \
            -o cyclonedx-json > sbom.json
          cosign attest --yes \
            --predicate sbom.json \
            --type cyclonedx \
            ghcr.io/<ORG>/<APP>@${{ steps.build.outputs.digest }}

      - name: Generate + sign SLSA provenance
        uses: slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@<VERSION>
        with:
          image: ghcr.io/<ORG>/<APP>
          digest: ${{ steps.build.outputs.digest }}
```

### Verify
```bash
# Public verify (Sigstore Rekor'da arar)
COSIGN_EXPERIMENTAL=1 cosign verify \
  --certificate-identity-regexp="https://github.com/<ORG>/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/<ORG>/<APP>:<TAG>

# SBOM attestation
COSIGN_EXPERIMENTAL=1 cosign verify-attestation \
  --type cyclonedx \
  --certificate-identity-regexp="https://github.com/<ORG>/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/<ORG>/<APP>@<DIGEST>
```

### Key-based signing (multi-cloud, IdP yok)
```bash
cosign generate-key-pair          # cosign.key + cosign.pub
cosign sign --key cosign.key <IMAGE>
cosign verify --key cosign.pub <IMAGE>
```

> ⚠️ Key-based: private key güvenli yerde dur (Vault, KMS). Keyless tercih edilir.

---

## 🛂 SLSA L3 Provenance — Non-Falsifiable Build

SLSA L3 demek: "Bu artifact'i hangi commit'ten, hangi runner'da, hangi flag ile build ettiğin **falsifiable değil**." Yani saldırgan provenance'i taklit edemez.

### slsa-github-generator
```yaml
# Reusable workflow ile container build
jobs:
  provenance:
    permissions:
      id-token: write
      contents: read
      actions: read
      packages: write
    uses: slsa-framework/slsa-github-generator/.github/workflows/builder_container_slsa3.yml@<VERSION>
    with:
      image: ghcr.io/<ORG>/<APP>
      registry-username: ${{ github.actor }}
    secrets:
      registry-password: ${{ secrets.GITHUB_TOKEN }}
```

Çıktı: cosign attestation olarak attached SLSA provenance:
```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "predicateType": "https://slsa.dev/provenance/v1",
  "subject": [{"name": "ghcr.io/<ORG>/<APP>", "digest": {"sha256": "..."}}],
  "predicate": {
    "buildDefinition": {
      "buildType": "https://slsa.dev/container-based-build/v0.1?draft",
      "externalParameters": {
        "source": {"uri": "git+https://github.com/<ORG>/<REPO>@refs/tags/v1.2.3"},
        "configPath": ".github/workflows/release.yml"
      }
    },
    "runDetails": {
      "builder": {"id": "https://github.com/slsa-framework/slsa-github-generator/.github/workflows/..."},
      "metadata": {"invocationId": "...", "startedOn": "2026-05-04T15:42:00Z"}
    }
  }
}
```

---

## 🚧 Admission: İmzalı + SLSA Provenance Olmayan İmaj Reddedilsin

### Kyverno: signed + provenance verify
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-slsa-provenance
spec:
  validationFailureAction: Enforce
  webhookTimeoutSeconds: 30
  rules:
    - name: verify-cosign-and-slsa
      match:
        any:
          - resources:
              kinds: [Pod]
      verifyImages:
        - imageReferences:
            - "ghcr.io/<ORG>/*"
          attestors:
            - entries:
                - keyless:
                    subject: "https://github.com/<ORG>/*"
                    issuer: "https://token.actions.githubusercontent.com"
          attestations:
            - predicateType: https://slsa.dev/provenance/v1
              attestors:
                - entries:
                    - keyless:
                        subject: "https://github.com/slsa-framework/*"
                        issuer: "https://token.actions.githubusercontent.com"
```

---

## 🧬 Dependency Graph + Vulnerability Tracking

### OWASP Dependency-Track
Self-hosted SBOM repository + CVE tracking. Yeni CVE açıklandığında etkilenen tüm servisleri otomatik bildirir.

```bash
# docker-compose ile minimal kurulum
docker run -d --name dtrack-apiserver \
  -p 8080:8080 \
  dependencytrack/apiserver

docker run -d --name dtrack-frontend \
  -p 8081:8080 \
  dependencytrack/frontend
```

CI'da SBOM upload:
```bash
curl -X POST "https://<DTRACK>/api/v1/bom" \
  -H "X-API-Key: <KEY>" \
  -H "Content-Type: application/json" \
  -d "{
    \"projectName\": \"<APP>\",
    \"projectVersion\": \"<VERSION>\",
    \"bom\": \"$(base64 -w0 sbom.json)\"
  }"
```

### GitHub Dependency Graph
Native, ücretsiz, public/private repo'lara açık. Dependabot ile entegre.

---

## 🔬 Bonus: Reproducible Builds

> "Aynı kaynak kodundan, aynı build environment'la, **bit-bit aynı** binary."

Bu en katı supply chain güveni. Saldırgan build sırasında bir şey enjekte etse, ikinci build farklı çıkar → tespit edilir.

### Container için
- **Buildkit**: `--build-arg SOURCE_DATE_EPOCH` ile timestamp normalize
- **Bazel**: hermetic build native
- **Nix**: tam reproducible

```dockerfile
# SOURCE_DATE_EPOCH ile timestamp deterministic
ARG SOURCE_DATE_EPOCH
ENV SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH}
```

```bash
# Aynı SHA, iki farklı runner, aynı output digest
SOURCE_DATE_EPOCH=$(git log -1 --pretty=%ct) docker buildx build ...
```

> Çoğu kurum için reproducible build "nice-to-have". L3 yeterli; L4 hedefse evet.

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| SBOM yok | Yeni CVE'de "etkilendik mi?" cevap yok | Her build'de SBOM, registry'de attach |
| SBOM CI artifact'i, 90 gün TTL | Lazım olduğunda silinmiş | Cosign attest, registry'de kalıcı |
| Image sign yok | Saldırgan registry'ye fake image push | cosign sign + admission verify |
| Key-based signing, key tek bir yerde | Compromise → tüm imzalar sahte | Keyless OIDC, ephemeral cert |
| Provenance yok, "ben build ettim" | Falsifiable | slsa-github-generator |
| Dependabot/Renovate yok | Eski dep → CVE birikiyor | Otomatik PR + auto-merge minor |
| `npm install` registry'i mirror'lanmamış | Upstream takedown → build kırılır | Internal artifact mirror (Artifactory, Nexus, GHA cache) |
| Build runner self-hosted **paylaşımlı** | Side-channel attack | Ephemeral runner, her job için fresh VM |
| `curl | bash` install | Compromise → herkese RCE | Pinned version + checksum |
| `RUN apt-get update` cache cooked | Reproducibility yok | Hermetic build veya `apt-mark hold` |
| GHA `@main` veya `@v1` | Tag mutable, taşınabilir | SHA pin: `@a1b2c3d4...` |

---

## 📋 Supply Chain Hijyen Checklist

```
[ ] Build sadece reusable workflow'lar üzerinden (PR ile değil)
[ ] GHA action'lar SHA pin (Renovate / dependabot ile güncel tutulur)
[ ] Build runner ephemeral (fresh VM her job)
[ ] Source: protected branch + signed commits + 2-reviewer
[ ] Dependency: Renovate / Dependabot, CVE auto-PR
[ ] Lock file (package-lock.json, go.sum, Pipfile.lock) commit'li
[ ] CI'da: SAST (Semgrep/CodeQL), SCA (Trivy/OSV-Scanner)
[ ] Container build: Buildkit, multi-stage, distroless/Chainguard
[ ] SBOM: CycloneDX + SPDX, cosign attest registry'ye
[ ] Image sign: cosign keyless (GitHub OIDC)
[ ] SLSA provenance: slsa-github-generator
[ ] Admission: Kyverno verifyImages + verify provenance
[ ] SBOM repository: Dependency-Track (veya equivalent)
[ ] CVE alerting: yeni CVE → etkilenen servis listesi otomatik
[ ] Internal mirror: package registry, container registry (cache'li)
[ ] Quarterly: supply chain review, attack surface map güncellenir
[ ] Tatbikat: "fake dep" inject edip pipeline yakalıyor mu?
```

---

## 📚 Referanslar

- **SLSA Spec** — slsa.dev
- **Sigstore Docs** — docs.sigstore.dev
- **CycloneDX** — cyclonedx.org
- **SPDX** — spdx.dev
- **OWASP Dependency-Track** — dependencytrack.org
- **NIST SSDF** (Secure Software Development Framework)
- **EU Cyber Resilience Act** — 2024 yürürlük, 2027 tam uygulama
- **Executive Order 14028** — US federal yazılım SBOM zorunluluğu
- [`Container-Image-Scanning.md`](Container-Image-Scanning.md)
- [`Kubernetes-Hardening.md`](Kubernetes-Hardening.md) — admission gating
- [`19-Compliance/`](../19-Compliance/) (Faz 4) — yasal çerçeve

---

> *"Sen kodu yazıyorsun, ama imaj 50 milyon satır başkasının kodu.
> SBOM, supply chain'in **görünürlüğü**; SLSA, **bütünlüğü**;
> ikisi olmadan modern üretim 'biz nasıl güveniyoruz' sorusuna cevap veremez."*
