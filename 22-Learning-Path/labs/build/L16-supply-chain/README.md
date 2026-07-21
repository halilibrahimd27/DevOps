# L16 — Supply chain: tarama kapısı + imzalama + SBOM (C2 pipeline üstüne)

> Modül: [`D4`](../../../block-d-orchestration/D4-supply-chain.md) · Süre: ~3 saat · Kırık lab: yok

Bu ayrı bir "güvenlik dersi" değil — L10'da kurduğun pipeline'ın **devamı**. Aynı
`test → build → push` akışına üç halka eklersin: image **taraması** (kritik açık
varsa pipeline durur), **SBOM** (içinde ne var), ve **imzalama** (`cosign` ile
imzala + doğrula). Böylece cluster'a giren her image "taranmış ve imzalı" olur.

## Gerekenler
- L10'un pipeline'ı + yerel registry (`registry:2`).
- `trivy`, `cosign`, `docker`, `git`.

## Görev

1. **Tarama kapısını ekle (SEN).** `starter/pipeline.sh.template`'i doldur: build'den
   sonra `trivy image` ile tara, **HIGH/CRITICAL** varsa `--exit-code 1` ile pipeline'ı
   **durdur**. Taranmamış image push edilmez.
   ```bash
   trivy image --exit-code 1 --severity HIGH,CRITICAL "$IMG"
   ```
2. **SBOM üret.** Image'ın içindeki bileşen listesini çıkar:
   ```bash
   trivy image --format cyclonedx -o sbom.json "$IMG"
   ```
   `sbom.json` hangi soruyu yanıtlar? (İpucu: "şu CVE bende var mı?" bir sonraki
   Log4Shell'de dakikalar meselesi olur.) `report.txt`'e yaz.
3. **İmzala + doğrula.** Anahtar çifti üret (anahtarı **commit'leme**), imzala, doğrula:
   ```bash
   cosign generate-key-pair            # cosign.key + cosign.pub (cosign.key'i .gitignore'a ekle)
   cosign sign   --key cosign.key "$IMG"
   cosign verify --key cosign.pub "$IMG"
   ```
4. **Eşiği kanıtla.** Bilerek eski/açıklı bir base image kullan (ör. eski bir etiket),
   taramanın pipeline'ı **kırdığını** gör. Sonra güncel image'a dön. Bu deneyimi yaz.
5. **Yazılı gerekçe.** `report.txt`'e: "imzasız/taranmamış image'ı cluster niçin
   reddetmeli" ve "SBOM ne olduğu + hangi soruyu yanıtladığı".

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `pipeline.sh` bir `trivy image` tarama kapısı içeriyor ve eşik aşılınca
      (`--exit-code 1 --severity HIGH,CRITICAL`) **duruyor**.
- [ ] `pipeline.sh` `cosign sign` + `cosign verify` adımlarını içeriyor.
- [ ] `report.txt` "imzasız/taranmamış image niçin reddedilmeli" gerekçesini içeriyor.
- [ ] `report.txt` SBOM'un ne olduğunu ve hangi soruyu yanıtladığını açıklıyor.

## İpucu (çözüm değil)
- Tarama kapısı build **ile** push arasına girer — açıklı image registry'ye hiç
  ulaşmamalı. `--exit-code 1` olmadan tarama sadece rapor üretir, **kapı olmaz**.
- İmza güveni: `cosign verify` başarısızsa image ya değiştirilmiş ya imzasızdır.
  Cluster tarafında bunu bir admission policy (Kyverno/Sigstore policy) zorunlu kılar.
- SBOM statiktir; asıl değeri **sonradan** çıkar: yeni bir CVE duyulunca "hangi
  image'larım etkilendi" sorusunu grep hızında yanıtlar.

Takılırsan `solution/`'a bak — ama **önce kendin dene**.
