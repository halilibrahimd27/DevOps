# L15 — Secret yönetimi: sırrı image/repo dışında tut

> Modül: [`D3`](../../../block-d-orchestration/D3-secret-yonetimi.md) · Süre: ~3 saat · Kırık lab: yok

D1/D2'de uygulamayı çalıştırdın — ama parolayı nereye koydun? Bu lab sırrı
image'a **gömmeden** ve repoya **düz metin yazmadan** Pod'a ulaştırır. İki gerçeği
gözünle görürsün: (1) K8s `Secret` varsayılan olarak yalnız **base64**'tür, şifreleme
değil; (2) bir sızıntı taraması repoya kaçmış sırrı yakalar.

## Gerekenler
- D1'deki kind cluster, `kubectl`, `base64`.
- Bir sızıntı tarayıcı: `gitleaks` **veya** `trivy fs`.

## Görev

1. **Sırrı repo dışında oluştur.** Değeri **kabuktan** ver, dosyaya yazma:
   ```bash
   read -rs DB_PASSWORD          # ekranda görünmez
   kubectl -n lab create secret generic app-db \
     --from-literal=password="$DB_PASSWORD"
   unset DB_PASSWORD
   ```
2. **Deployment'ı Secret'a bağla (SEN).** `starter/deployment.yaml`'daki düz metin
   `DB_PASSWORD` TODO'sunu `secretKeyRef` ile değiştir — değer manifestte **görünmez**.
   ```bash
   kubectl apply -f starter/deployment.yaml
   kubectl -n lab exec deploy/lab-app -- printenv DB_PASSWORD   # Pod içinde var
   ```
3. **base64 ≠ şifreleme'yi kanıtla.**
   ```bash
   kubectl -n lab get secret app-db -o jsonpath='{.data.password}' | base64 -d; echo
   ```
   Sır düz metin çıkıyor. Demek ki etcd'ye erişen herkes okuyabilir → `report.txt`'e yaz.
4. **Sızıntı taramasını çalıştır.** Repoda düz metin sır **olmadığını** göster:
   ```bash
   gitleaks detect --no-banner    # veya:  trivy fs --scanners secret .
   ```
   Temiz çıktıyı `report.txt`'e ekle. (İstersen geçici bir sahte sır ekleyip
   taramanın onu **yakaladığını** gör, sonra sil — ama repoya commit'leme.)
5. **GitOps'a sır taşıma (yazılı).** Bir sırrı Git'e düz metin koymadan taşımanın
   **en az bir yolunu** yaz (SealedSecrets / SOPS / External Secrets Operator) ve
   nasıl çalıştığını bir cümleyle açıkla.

## Kabul kriterleri
- [ ] `bash verify.sh` sıfır hatayla geçiyor.
- [ ] `deployment.yaml` sırrı `secretKeyRef` ile alıyor — manifestte düz metin parola yok.
- [ ] `report.txt` "K8s Secret niçin tek başına yetmez (base64, şifreleme değil)"
      açıklamasını içeriyor.
- [ ] `report.txt` bir sızıntı taraması çıktısı (temiz) içeriyor.
- [ ] `report.txt` sırrı GitOps'a düz metin koymadan taşımanın bir yolunu anlatıyor.

## İpucu (çözüm değil)
- `secretKeyRef` sırrı **referansla** getirir; değer manifeste, dolayısıyla Git'e girmez.
- base64 geri çevrilebilir (`base64 -d`) — bu koruma değil, taşıma biçimidir. Gerçek
  koruma: etcd encryption-at-rest + RBAC + harici bir sır deposu.
- GitOps'ta sır: değeri **şifreli** commit'lersin (SealedSecrets/SOPS) ya da cluster'daki
  bir operatör sırrı harici store'dan (Vault, cloud secret manager) çeker.

Takılırsan solution manifestine bak — ama **önce kendin dene**.
