# K04 — Çözüm

> **Önce kendin dene.** Çok-arızalı lab: iki ayrı kök sebep. Önce **teşhis akışı**.

## Teşhis akışı — katman katman

### Katman 1: Pod ayağa kalkmıyor
```bash
kubectl -n k04 describe pod -l app=app | tail -20
# Events: Failed to pull image "...:0.0-does-not-exist": ... not found
```
`ImagePullBackOff`'un sebebi net: image tag'i yok. Bu bir cluster/ağ sorunu değil,
bir **manifest** hatası — yanlış tag.

### Katman 2: Pod Running ama servise erişilemiyor
Image'ı düzeltip Pod `Running` olduktan sonra:
```bash
kubectl -n k04 get networkpolicy
kubectl -n k04 describe networkpolicy default-deny-ingress   # ingress kuralı: yok
```
`default-deny-ingress` tüm gelen trafiği kesiyor ve onu dengeleyen bir **izin**
kuralı yok. NetworkPolicy toplamsaldır: reddettikten sonra izin eklemezsen bağlantı
kurulamaz.

> Not — üçüncü bir klasik: bazı senaryolarda uygulama K8s API'ye erişmeye çalışır ve
> ServiceAccount'un yetkisi yoktur → `Error ... is forbidden` (RBAC). Bu lab'da app
> API çağırmıyor; ama bir Pod "forbidden" logluyorsa refleksin
> `kubectl auth can-i ... --as=system:serviceaccount:...` olmalı.

## Kök sebepler
1. **Yanlış image tag** (`0.0-does-not-exist`) → kubelet image'ı çekemiyor.
2. **İzin kuralsız default-deny NetworkPolicy** → Pod sağlıklı ama ağ katmanında izole.

## Düzeltme
```bash
# 1) env/deployment.yaml → image: nginxinc/nginx-unprivileged:1.27-alpine
kubectl apply -f env/deployment.yaml
# 2) izin kuralı ekle (hint-3'teki allow-same-namespace)
kubectl apply -f env/allow.yaml
```

## Belirtilerin gittiğini kanıtla
```bash
kubectl -n k04 get pods                     # Running 1/1
kubectl -n k04 run probe --image=busybox:1.36 --restart=Never -it --rm -- \
  wget -qO- --timeout=3 http://app-svc       # nginx yanıtı
```

## Niye böyle oluyor
K8s'te "çalışmıyor" tek bir katman değil: **planlama** (scheduler), **image**
(kubelet pull), **çalışma** (container), **ağ** (Service/NetworkPolicy), **yetki**
(RBAC) ayrı katmanlardır. Bir katmanı düzeltmek diğerini düzeltmez. Bu yüzden
belirtiyi katmana bağlamak (`describe` → `events` → `get networkpolicy`) tahminden
hızlıdır.

## Ders
Çok-arızalı sistemde "düzelttim ama hâlâ bozuk" normaldir — ikinci arıza vardır.
Tek seferde tek katman kanıtla; her düzeltmeden sonra belirtinin **hangi kısmının**
gittiğini ölç.
