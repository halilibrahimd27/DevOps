# Hint 3 — neredeyse cevap

İki bağımsız arıza var; **ikisini de** düzeltmeden test isteği 200 dönmez.

**Arıza 1 — config key uyuşmazlığı (pod'lar başlamıyor).**
Deployment şu env'i istiyor:
```yaml
configMapKeyRef: { name: api-config, key: app_mode }
```
Ama `api-config` ConfigMap'inde key `mode`, `app_mode` **değil** → kubelet container'ı
oluşturamaz (`CreateContainerConfigError`). Düzelt: ya Deployment'taki key'i `mode` yap,
ya ConfigMap'e `app_mode` ekle. (Kaynağı düzeltmek doğrusudur — key adını tutarlı yap.)

**Arıza 2 — Service selector uyuşmazlığı (endpoint boş).**
```yaml
Service.spec.selector: { app: api }      # pod'lar app=api-server
```
Selector pod etiketini bulamıyor. Düzelt: selector'ı `app: api-server` yap.

Her iki düzeltmeden sonra:
```bash
kubectl -n inc get pods            # Running
kubectl -n inc get endpoints api   # IP dolu
kubectl -n inc run t --rm -it --image=busybox:1.36 --restart=Never -- wget -qO- --timeout=3 http://api
```
Tam cevap ve teşhis akışı: `solution.md`.
