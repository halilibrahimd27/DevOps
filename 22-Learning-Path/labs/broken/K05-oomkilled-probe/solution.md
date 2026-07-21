# K05 — Çözüm

> **Önce kendin dene.** İki katman: OOMKilled + yanlış probe. Önce **teşhis akışı**.

## Teşhis akışı

### Katman 1: neden sürekli restart?
```bash
kubectl -n k05 describe pod -l app=app | grep -A6 'Last State'
# Last State: Terminated   Reason: OOMKilled   Exit Code: 137
```
`OOMKilled` = container bellek **limitini** aştı, çekirdek öldürdü. Limit `32Mi`,
uygulama başlangıçta ~40MB ayırıyor → 40 > 32 → ölüm. Bu bir kod hatası değil,
yanlış **kapasite** ayarı.

### Katman 2: restart durdu ama neden Ready değil?
```bash
kubectl -n k05 describe pod -l app=app | grep -A3 -i readiness
# Readiness probe failed: ... connection refused (port 9999)
kubectl -n k05 get endpoints app-svc      # boş → Service trafik göndermez
```
readinessProbe `9999`'a bakıyor ama uygulama `8080` dinliyor. Probe hep fail →
Pod `Ready` olmaz → Service `Endpoints`'e eklenmez → "trafik almıyor".

## Kök sebepler
1. **`limits.memory: 32Mi` çok düşük** → OOMKilled (Exit 137).
2. **readinessProbe yanlış port (9999)** → Pod hiç Ready olmaz.

## Düzeltme
```yaml
resources:
  limits: { cpu: "200m", memory: "128Mi" }   # uygulamanın gerçek ihtiyacına göre
readinessProbe:
  httpGet: { path: /health, port: 8080 }      # uygulamanın dinlediği port
```
```bash
kubectl apply -f env/deployment.yaml
```

## Belirtilerin gittiğini kanıtla
```bash
kubectl -n k05 get pods                    # 1/1 Running, RESTARTS artmıyor
kubectl -n k05 get endpoints app-svc       # bir Pod IP:8080 listeleniyor
```

## Niye böyle oluyor
- `requests` planlama için "garanti", `limits` "tavan". Bellekte tavan aşılırsa
  container **öldürülür** (OOMKilled, 137) — CPU'da ise sadece throttle edilir.
- `readinessProbe` "trafiğe hazır mıyım" sorusudur; başarısızsa Pod Service
  rotasyonundan çıkarılır. Yanlış port/patikaya bakan bir probe, sağlıklı Pod'u da
  "hazır değil" yapar.

## Ders
İki ayrı belirti (restart + trafik yok) iki ayrı katman. `describe` → `Last State`
restart sebebini, `describe` → `Readiness` + `get endpoints` erişim sebebini verir.
"RESTARTS: 12" bir açıklama değil; açıklama `Last State`'te.
