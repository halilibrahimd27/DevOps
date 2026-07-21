# L01 — Linux temeli: process, izin, kullanıcı

> Modül: [`A1`](../../../block-a-intuition/A1-linux-temeli.md) · Süre: ~1 saat · Kırık lab: yok

Bu lab'da bir process'i bulup incelersin, bir dizin ağacının izinlerini
düzene çekersin ve bir servis kullanıcısı yaratırsın. Üçü de bir sunucuda
her gün yaptığın işlerdir.

## Gerekenler
- Linux (veya WSL2 / Linux VM). macOS'ta `chmod`/`stat` sözdizimi farklı — Linux kullan.
- `bash`, `pgrep`, `stat`, `chmod`, `chown`. Kullanıcı yaratmak için `sudo`.

## Görev

1. **Playground'u kur.** `starter/setup-playground.sh`'i çalıştır. Bu script
   `./playground/` altında yanlış izinli bir dizin ağacı yaratır ve arka planda
   `l01-daemon` adlı bir process başlatır.
   ```bash
   bash starter/setup-playground.sh
   ```
2. **Process'i bul ve incele.** `l01-daemon` process'inin PID'ini, çalışma
   dizinini ve açık dosyalarını bul. Çıktıyı `report.txt`'e yaz.
3. **İzinleri düzelt.** `playground/` altındaki **tüm dizinleri** `750`,
   **tüm dosyaları** `640` yap. `playground/gizli.txt` şu an herkese açık (`0666`) —
   bu bir güvenlik açığıdır, kapat.
4. **Servis kullanıcısı yarat.** Login yapamayan (`--shell /usr/sbin/nologin`),
   home'u olmayan bir `l01svc` sistem kullanıcısı yarat. Niçin login'siz olduğunu
   `report.txt`'e bir cümleyle yaz.
5. **Kanıtı yaz.** `report.txt` şunları içermeli: process PID satırı,
   `df -h` vs `df -i` farkının bir cümlelik açıklaması, kullanıcı≠grup≠sudo sınırı.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `playground/` içindeki her dizin `750`, her dosya `640`.
- [ ] `report.txt` process PID'ini ve `df -h`/`df -i` farkını içeriyor.
- [ ] `l01svc` kullanıcısı var ve login shell'i `nologin`.

## İpucu (çözüm değil)
- Process bulma: bir isimle PID → `pgrep`. PID'in ayrıntısı → `/proc/<PID>/` altındaki
  `cwd` ve `fd/` sembolik linkleri, veya `lsof -p <PID>`.
- Toplu izin: dizinlere ve dosyalara **ayrı** `find ... -type d/-type f -exec chmod` ile
  farklı mod ver. Dizine `640` verirsen içine `cd` edemezsin — dizin `x` bitine ihtiyaç duyar.
- Sistem kullanıcısı: `useradd --system --no-create-home --shell <nologin-path>`.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
