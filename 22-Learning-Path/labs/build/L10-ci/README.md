# L10 — CI: test → build → artifact → registry

> Modül: [`C2`](../../../block-c-reproducibility/C2-ci.md) · Süre: ~3 saat · Kırık lab: yok

L09'da image'ı elle build ettin. Bu lab o adımı bir **pipeline**'a çevirir:
her commit'te otomatik `test → build → tag → push`. Önce **yerel** bir registry'ye
(hiç bulut, hiç para), sonra aynı akışı GitHub Actions olarak yazarsın. Kilit ders:
image **sürümlü** etiketlenir — `:latest` değil, commit SHA veya semver.

## Gerekenler
- `docker`, `git`, `python3` + `pytest` (`pip install pytest`).
- Yerel registry: `docker run -d -p 5000:5000 --name lab-registry registry:2`.
- (Opsiyonel) GitHub deposu — `ci.yml`'i orada da çalıştırmak istersen.

## Görev

1. **Yerel registry'yi başlat.**
   ```bash
   docker run -d -p 5000:5000 --name lab-registry registry:2
   ```
2. **Testi çalıştır.** `starter/app.py` + `starter/test_app.py` verildi. `pytest`
   yeşil mi? Pipeline'ın ilk kapısı budur — test kırmızıysa build **çalışmaz**.
   ```bash
   cd starter && pytest -q
   ```
3. **Pipeline'ı yaz.** `starter/pipeline.sh.template`'i `pipeline.sh` olarak doldur:
   sırayla `pytest` → `docker build` → **SHA ile etiketle** → `docker push`. Herhangi
   bir adım patlarsa pipeline **durmalı** (`set -e`).
   ```bash
   bash pipeline.sh          # yeşil geçmeli
   docker pull localhost:5000/lab-app:"$(git rev-parse --short HEAD)"
   ```
4. **Kırık adımı gör.** `test_app.py`'de bir assert'i bilerek boz, `pipeline.sh`'i
   tekrar çalıştır. Hangi aşamada, hangi satırda patladı? Düzelt. Bu deneyimi
   `report.txt`'e yaz.
5. **"Yeşil ama neyi doğruladı?"** Pipeline'ın yeşil olması *neyi kanıtlar, neyi
   kanıtlamaz*? (İpucu: test kapsamadığı bir bug hâlâ geçer.) `report.txt`'e yaz.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `pipeline.sh` sırasıyla test, build, push adımlarını içeriyor ve `set -e` ile
      ilk hatada duruyor.
- [ ] Image etiketi **`:latest` değil** — commit SHA veya semver.
- [ ] `report.txt` kırık adımın hangi aşamada patladığını (yazılı teşhis) içeriyor.
- [ ] `report.txt` "yeşil pipeline neyi doğrular, neyi doğrulamaz" sorusunu yanıtlıyor.

## İpucu (çözüm değil)
- Sıra önemli: **test önce**. Kırık kodu build edip push etmek zaman + registry çöpü.
- SHA etiketi: `TAG=$(git rev-parse --short HEAD)`. Böylece her image hangi commit'ten
  geldiğini taşır — `:latest` bunu **gizler** (P0 anti-pattern).
- `set -euo pipefail` → bir adım fail edince sonrakiler çalışmaz, "yeşil yalanı" olmaz.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
