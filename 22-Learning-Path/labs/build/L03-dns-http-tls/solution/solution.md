# L03 — Referans çözüm

> **Önce kendin dene.** "Site açılmıyor"ın kökünü bulmak, zinciri katman katman
> yürümekten geçer.

## 1. Servisi başlat
```bash
bash starter/gen-cert-and-serve.sh &
```

## 2. DNS katmanı — isim → IP
Gerçek DNS yerine eşlemeyi elle veriyoruz:
```bash
curl --resolve lab.example:8443:127.0.0.1 -kIs https://lab.example:8443/ | head -n1
# HTTP/1.0 200 ok
```
Olmayan bir isim:
```bash
dig +short olmayan-isim.example      # boş / NXDOMAIN — çözme aşamasında ölür
```
DNS başarısızsa istek **hiç** HTTP/TLS'e ulaşmaz. `curl: (6) Could not resolve host`.

## 3. HTTP katmanı — istek/yanıt
```bash
curl --resolve lab.example:8443:127.0.0.1 -kIsv https://lab.example:8443/ 2>&1 | grep -E '^< HTTP|^< '
# Yanıt satırı + başlıklar. Durum kodu: 200.
```

## 4. TLS katmanı — kimlik ve süre
```bash
openssl x509 -in tls/lab.crt -noout -subject -enddate
# subject=CN=lab.example
# notAfter=<tarih>   ← sertifikanın son geçerlilik günü
```
Canlı el sıkışma:
```bash
openssl s_client -connect 127.0.0.1:8443 -servername lab.example </dev/null 2>/dev/null \
  | grep -E 'subject=|Verify return'
```

## 5. İki halka, iki ayrı hata

| Katman | Nasıl bozarsın | Hata | Neyi söyler |
|---|---|---|---|
| **DNS** | Yanlış/olmayan isim | `Could not resolve host` / `NXDOMAIN` | İstek daha başlamadı; isim→IP çözülemedi |
| **TLS** | `-k` olmadan self-signed / yanlış CN / süresi geçmiş | `certificate verify failed` | İsim çözüldü, bağlanıldı, ama **kimlik** doğrulanamadı |

> Aynı "açılmıyor" belirtisi. Biri **çözme** aşamasında, diğeri **kimlik doğrulama**
> aşamasında. Hangi komutun hangi katmanda öldüğünü bilmek, aramayı 3 kat daraltır.
