# L09 — Container: image, katman, multi-stage, compose

> Modül: [`C1`](../../../block-c-reproducibility/C1-container.md) · Süre: ~3 saat · Kırık lab: [`K02`](../../broken/K02-container-hatasi/)

A6'da uygulamayı **elle** kurdun: VM, systemd, nginx, PostgreSQL. Bu lab aynı
uygulamayı bir **image**'a paketler ve `docker compose` ile app + DB'yi tek komutla
ayağa kaldırır. Sonra aynı Dockerfile'ı **multi-stage** yaparak image'ı küçültür,
önce/sonra boyut farkını gözünle görürsün.

## Gerekenler
- `docker` + `docker compose` (yerel; K8s **gerekmez**).
- `curl`. İnternet (base image çekmek için).

## Görev

1. **Naive image'ı derle (önce).** `starter/Dockerfile.naive` tek stage'dir ve
   build araçlarını (build-essential) final image'a taşır — bilerek şişkin.
   ```bash
   cd starter
   docker build -f Dockerfile.naive -t lab-app:naive .
   docker images lab-app:naive          # boyutu not al
   ```
2. **Multi-stage image'ı yaz (sonra).** `Dockerfile` iskeletini doldur: bir `build`
   stage bağımlılıkları kurar, `runtime` stage yalnız gerekli olanı kopyalar.
   ```bash
   docker build -t lab-app:slim .
   docker images lab-app:slim           # naive'den küçük olmalı
   ```
3. **Compose ile app + DB.** `compose.yaml` iskeletini doldur: `app` servisi image'ı
   build eder, `db` servisi PostgreSQL çalıştırır, app `DB_HOST=db` ile bağlanır.
   ```bash
   export DB_PASSWORD='<kendi-secimin>'   # asla repoya yazma
   docker compose up -d --build
   curl -s http://127.0.0.1:8000/health   # {"db": true}
   ```
4. **Katman cache'ini gözlemle.** `app.py`'de küçük bir değişiklik yap, tekrar build et.
   Hangi katmanlar `CACHED`, hangileri yeniden çalıştı? Neden? `report.txt`'e yaz.
5. **Raporla.** `report.txt`'e şunları yaz: naive boyutu, slim boyutu, fark, ve
   "katman cache niçin sırayla bozulur" açıklaması (kendi cümlelerinle).

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `Dockerfile` multi-stage: en az iki `FROM` ve bir `COPY --from=`.
- [ ] `compose.yaml` `app` + `db` servisi içeriyor; hiçbir image `:latest` değil.
- [ ] `report.txt` naive ve slim boyutlarını **rakamla** ve farkı içeriyor.
- [ ] `report.txt` katman cache'inin niçin bozulduğunu kendi cümlelerinle anlatıyor.

## İpucu (çözüm değil)
- Multi-stage'in kazancı: build araçları (derleyici, pip cache, `.git`) final image'a
  **girmez**. `COPY --from=build /install /usr/local` yalnız kurulmuş paketi taşır.
- Katman cache: Docker her `COPY`/`RUN` satırını bir katman olarak cache'ler. Bir
  satır değişirse **o satır ve sonrası** yeniden çalışır. Bu yüzden `COPY requirements.txt`
  + `pip install` satırlarını `COPY . .`'dan **önce** koy — kod değişince bağımlılıklar
  yeniden kurulmaz.
- Non-root çalıştır: `USER 10001` (numeric UID, imajda kullanıcı yaratmaya gerek yok).

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
