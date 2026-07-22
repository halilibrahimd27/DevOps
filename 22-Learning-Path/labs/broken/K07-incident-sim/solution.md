# K07 — Çözüm

> **Önce kendin dene.** Önce **teşhis akışı**, sonra kök sebep. Bu lab'da asıl ölçülen
> şey tek komut değil, çok-arızalı bir olayı **yönetme** disiplinin.

## Teşhis akışı

1. **Service erişilemiyor → endpoint'e bak (tahmin etme).**
   ```bash
   kubectl -n inc get endpoints api      # boş
   ```
   Boş endpoint = Service arkasında çalışan pod yok. İki bağımsız neden olabilir.

2. **Katman A — pod'lar çalışıyor mu?**
   ```bash
   kubectl -n inc get pods                                   # CreateContainerConfigError
   kubectl -n inc describe pod -l app=api-server | grep -A3 Events
   # Error: couldn't find key app_mode in ConfigMap inc/api-config
   ```
   Pod hiç başlamıyor: `configMapKeyRef` var olmayan bir key (`app_mode`) istiyor.

3. **Katman B — selector eşleşiyor mu?**
   ```bash
   kubectl -n inc get svc api -o jsonpath='{.spec.selector}'; echo   # {"app":"api"}
   kubectl -n inc get pods --show-labels                             # app=api-server
   ```
   Pod'lar başlasa bile Service onları etiketten bulamaz: `api` ≠ `api-server`.

## Kök sebep (iki bağımsız arıza)

| # | Arıza | Etki |
|---|---|---|
| 1 | `configMapKeyRef.key: app_mode`, ama ConfigMap'te key `mode` | Pod'lar `CreateContainerConfigError` — hiç Running olmaz |
| 2 | `Service.selector: app=api`, ama pod etiketi `app=api-server` | Endpoint boş — pod çalışsa da erişilemez |

Tek katmanı düzeltmek belirtiyi geçirmez: config'i düzeltirsen pod'lar Running olur
ama endpoint yine boştur (selector); selector'ı düzeltirsen endpoint yine boştur (pod
yok). **İkisi birlikte** çözülmeli.

## Düzeltme

```bash
# Arıza 1: key adını kaynakta tutarlı yap
kubectl -n inc patch deploy api --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/env/0/valueFrom/configMapKeyRef/key","value":"mode"}]'

# Arıza 2: selector'ı pod etiketine hizala
kubectl -n inc patch svc api --type=merge -p '{"spec":{"selector":{"app":"api-server"}}}'
```

## Belirtinin gittiğini kanıtla

```bash
kubectl -n inc get pods                # Running
kubectl -n inc get endpoints api       # IP'ler dolu
kubectl -n inc run t --rm -it --image=busybox:1.36 --restart=Never -- wget -qO- --timeout=3 http://api  # 200
```

## Incident çerçevesi (asıl teslimat)

- **timeline.md:** olayı UTC dakika hassasiyetle yaz — `uyarı geldi → endpoints boş →
  pod'lar ConfigError → selector uyuşmazlığı → iki patch → 200`. Timeline sonradan
  hatırlanarak değil, olay anında tutulur.
- **postmortem.md (blameless):**
  - **Etki:** `api` X dk erişilemedi (test isteği bağlanmadı).
  - **Kök sebep:** iki ayrı yanlış konfig (config key + selector) aynı anda canlıydı.
  - **Niçin daha erken yakalanmadı:** endpoint/hazırlık üzerine bir alarm yoktu; manifest
    değişikliği selector↔etiket uyumunu doğrulayan bir kontrolden geçmedi.
  - **Eylem maddesi (sahip + son tarih):** ör. "api için endpoint-boş alarmı ekle —
    sahip: <AD>, son tarih: <TARİH>."

Dili sisteme çevir: "biri yanlış yazdı" değil, **"sistem bu uyuşmazlığın canlıya
geçmesine izin verdi"**.

## Ders

Erişim arızasında panik teşhisi değil, **katman katman** ilerleme kazandırır: endpoint
→ pod durumu → selector. Çok-arızalı olaylarda ilk düzelttiğin şey belirtiyi tamamen
geçirmezse, bu bir başarısızlık değil bir **ipucu**dur: ikinci bir kök sebep vardır.
