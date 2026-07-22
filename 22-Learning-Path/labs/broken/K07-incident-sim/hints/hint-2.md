# Hint 2 — daralt

Endpoint boş. İki katmanı **ayrı ayrı** doğrula.

**(a) Pod'lar çalışıyor mu?**
```bash
kubectl -n inc get pods
kubectl -n inc describe pod -l app=api-server | sed -n '/Events/,$p'
```
`Running` değil de `CreateContainerConfigError`/`CrashLoopBackOff` görüyorsan, pod
hiç başlamıyordur. `describe`'daki Events kısmı niçin başlamadığını söyler — bir
env kaynağı (ConfigMap/Secret) çözülemiyor olabilir.

**(b) Service pod'ları etiketten bulabiliyor mu?**
```bash
kubectl -n inc get svc api -o jsonpath='{.spec.selector}'; echo
kubectl -n inc get pods --show-labels
```
Service'in `selector`'ı ile pod'ların etiketleri **birebir** uyuşmuyorsa, pod'lar
çalışsa bile endpoint boş kalır.

İki bulgunu da timeline'a yaz. Sadece birini düzeltmek belirtiyi tam geçirmez.
