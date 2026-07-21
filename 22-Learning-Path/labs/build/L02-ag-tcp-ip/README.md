# L02 — Ağ I: port, dinleme, "refused" vs "timeout"

> Modül: [`A2`](../../../block-a-intuition/A2-ag-tcp-ip.md) · Süre: ~1 saat · Kırık lab: yok

Bir servisi farklı arayüz ve portlara bağlar, dinleneni `ss`/`nc` ile doğrular,
sonra iki temel ağ hatasını — **connection refused** ve **timeout** — bilerek
üretip ayırt edersin. Bu ikisini karıştıran mühendis yanlış yerde saatlerce arar.

## Gerekenler
- Linux/WSL2/VM. `python3`, `ss` (veya `netstat`), `nc` (netcat), `curl`.

## Görev

1. **Sadece localhost'a bağla.** Bir HTTP servisini **yalnız** `127.0.0.1:8080`'de
   dinlet (dış arayüzde değil). `starter/serve-localhost.sh` başlatır.
   ```bash
   bash starter/serve-localhost.sh    # 127.0.0.1:8080 dinler
   ```
2. **Dinleneni kanıtla.** `ss -tlnp` ile bu servisin `127.0.0.1:8080`'de `LISTEN`
   olduğunu gör. Çıktı satırını `report.txt`'e yapıştır.
3. **"Refused" üret.** Kapalı bir porta (örn. `127.0.0.1:9999`) bağlanmayı dene.
   Neden **anında** reddedildi? `report.txt`'e yaz.
4. **"Timeout" üret.** Yönlendirilemeyen bir adrese (örn. `10.255.255.1`, yerelde
   route'u yok) bağlanmayı dene. Neden **asıldı kaldı** (hemen reddedilmedi)?
   `report.txt`'e yaz.
5. **Farkı yaz.** `report.txt` sonunda: "refused = ...; timeout = ...; hata mesajı
   bana ilk olarak neyi söyler?" — kendi cümlelerinle.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `report.txt` `127.0.0.1:8080` ve `LISTEN` içeren bir `ss` satırı barındırıyor.
- [ ] `report.txt` "refused" ve "timeout" ayrımını sebepleriyle açıklıyor.

## İpucu (çözüm değil)
- **Refused**: hedef makine ulaşılabilir ama o portta dinleyen yok → TCP `RST` gelir,
  **anında** cevap. Yanlış port / servis çökmüş demektir.
- **Timeout**: paket hedefe hiç varamıyor (route yok, firewall paketi *sessizce*
  düşürüyor) → cevap gelmez, istemci bekler. Ağ/firewall/route sorunudur.
- `nc -z -w3 <host> <port>` bağlantıyı test eder; çıkış kodu ve süresi ipucudur.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
