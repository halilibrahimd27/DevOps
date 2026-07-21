# L03 — DNS → HTTP → TLS: zinciri gör, her halkayı ayrı boz

> Modül: [`A3`](../../../block-a-intuition/A3-ag-dns-http-tls.md) · Süre: ~1 saat · Kırık lab: yok

Bir tarayıcının `https://` yazınca yaptığı üç işi tek tek elle yaparsın:
**isim çözme (DNS) → istek/yanıt (HTTP) → şifreli kanal ve kimlik (TLS)**.
Sonra DNS'i ve TLS'i **ayrı ayrı** bozup her birini bağımsız teşhis edersin —
çünkü "site açılmıyor"ın en az üç farklı kökü vardır.

## Gerekenler
- Linux/WSL2/VM. `openssl`, `curl`, `dig` (veya `getent`).
- İnternet gerekmez — her şey `127.0.0.1` üzerinde, `lab.example` sahte ismiyle.

## Görev

1. **Yerel TLS servisi başlat.** `starter/gen-cert-and-serve.sh` kendinden imzalı
   sertifika üretir ve `127.0.0.1:8443`'te HTTPS sunar.
   ```bash
   bash starter/gen-cert-and-serve.sh    # cert üretir + s_server başlatır
   ```
2. **İsmi elle çöz (DNS katmanı).** Gerçek DNS yerine `curl --resolve` ile
   `lab.example:8443` → `127.0.0.1` eşlemesini kendin ver. Bir de olmayan bir
   isim çözmeyi dene (`dig +short olmayan-isim.example`) — cevap `NXDOMAIN`.
3. **HTTP başlıklarını oku.** `curl -kIsv` ile yanıt satırını (`HTTP/...`) ve
   başlıkları gör. Durum kodunu `report.txt`'e yaz.
4. **Sertifikayı doğrula (TLS katmanı).** Sertifikanın **son geçerlilik tarihini**
   ve **sahibini (subject/CN)** `openssl` ile çıkar, `report.txt`'e yaz.
5. **İki halkayı ayrı boz:**
   - DNS bozuk: yanlış/olmayan isim → istek TLS'e bile ulaşmaz.
   - TLS bozuk: doğru isme ama yanlış CN'li / süresi geçmiş cert → `certificate verify failed`.
   Her iki hatanın **farklı katmanda** olduğunu `report.txt`'e yaz.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `report.txt` sertifikanın son geçerlilik tarihini (`notAfter`) ve subject/CN'ini içeriyor.
- [ ] `report.txt` `NXDOMAIN` (DNS katmanı) ile TLS doğrulama hatasını ayrı sebepler olarak açıklıyor.

## İpucu (çözüm değil)
- İsim eşleme: `curl --resolve lab.example:8443:127.0.0.1 https://lab.example:8443/`.
- Cert alanları: `openssl x509 -in <cert> -noout -subject -enddate`.
- Canlı el sıkışmayı görmek: `openssl s_client -connect 127.0.0.1:8443 -servername lab.example`.
- DNS hatası **çözme** aşamasında, TLS hatası **kimlik doğrulama** aşamasında olur — farklı komut, farklı katman.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
