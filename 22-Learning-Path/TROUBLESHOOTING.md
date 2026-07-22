---
description: "Yaygın hata → sebep → çözüm indeksi: patika boyunca en sık takılınan noktalar tek yerde."
tags: [Learning Path, Troubleshooting]
---
# 🆘 Sorun Giderme — Yaygın Hata → Sebep → Çözüm

> *"Aynı hataya ikinci kez takılmak öğrenme değil, kayıptır. Bu sayfa o kaybı önler."*

Her modülün kendi `🆘 Takıldıysan` tablosu vardır; bu sayfa **bloklar arası ortak**
takılma noktalarını tek yerde toplar. Belirtiyi bul, sebebi anla, çözümü uygula.
Her satır bir **belirti**yle başlar — çünkü sen sebebi değil, belirtiyi görürsün.
İlgili kırık lab'a link verildiği yerde, oradaki `solution.md` tam teşhis akışını anlatır.

> ⚠️ Aşağıdaki tüm komutlar örnektir; `<NAMESPACE>`, `<APP>`, `<POD>` gibi placeholder'ları
> kendi değerinle değiştir. Çıktı örnekleri kısaltılmıştır.

---

## 🐧 Blok A — Linux, ağ, git, elle deploy

| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `curl: (7) Connection refused` | Servis o portta hiç dinlemiyor (uygulama düşmüş ya da hiç başlamamış) | `systemctl status <SVC>` → başladı mı? `ss -tlnp \| grep :<PORT>` → dinleyen var mı? Zinciri **başlatma → bağlanma** sırasıyla yürü. Bkz. [`K00`](labs/broken/K00-systemd-ayaga-kalkmiyor/solution.md) |
| `systemctl start` sessizce başarısız, servis `activating`↔`failed` döngüsü | `ExecStart` hiç çalışmadı: kullanıcı/çalışma dizini/`EnvironmentFile` ön-hazırlığı patladı | `systemctl status <SVC>` üst satır + `journalctl -u <SVC> -e`. `status=219/…` → ortam hazırlığı hatası. Bkz. [`K00`](labs/broken/K00-systemd-ayaga-kalkmiyor/solution.md) |
| `Address already in use` / `EADDRINUSE` | Portu başka bir process tutuyor (eski process ölmedi ya da çakışan servis) | `ss -tlnp \| grep :<PORT>` veya `sudo lsof -i :<PORT>` → tutanı bul, gerekiyorsa durdur. Bkz. [`K01`](labs/broken/K01-kirik-vm/solution.md) |
| `Permission denied` bir dosyaya erişirken | Kullanıcı/grup sahipliği ya da mod (`rwx`) yanlış; servis kullanıcısı okuyamıyor | `ls -l <DOSYA>` → sahip + mod. `chown <USER>:<GROUP>` / `chmod` ile hizala. Servisler kendi kullanıcısıyla çalışır, senin değil |
| `sudo: command not found` / komut bulunamıyor | `PATH` içinde değil ya da paket kurulu değil | `which <KOMUT>` boşsa `type -a <KOMUT>`; kurulu değilse paket yöneticisiyle kur. `echo $PATH` ile ara yolu doğrula |
| Disk doldu: `No space left on device` | Log/geçici dosya/eski image disk'i doldurdu | `df -h` (hangi mount), `du -sh /*` ile daralt; log rotasyonu ya da `journalctl --vacuum-size=` |
| `git push` → `rejected (non-fast-forward)` | Uzak dal senin local'inden önde; birileri push etti | `git fetch` → `git rebase origin/<DAL>` (çakışma varsa çöz) → tekrar push. `--force` **kullanma** |
| `git` "detached HEAD" uyarısı | Bir dal yerine doğrudan bir commit'e checkout ettin | `git switch -c <YENİ_DAL>` ile çalışmanı kurtar ya da `git switch <DAL>` ile geri dön |
| Yanlış commit'i geri almak istiyorsun | `reset` mı `revert` mı karışıklığı | Paylaşılmadıysa `git reset`; paylaşıldıysa geçmişi bozmadan `git revert <SHA>`. Bkz. [`A4`](block-a-intuition/A4-git-temeli.md) |

## 🌐 Blok A — Ağ, DNS, HTTP, TLS

| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `curl: (6) Could not resolve host` | DNS çözümlemesi başarısız (yanlış isim, `/etc/resolv.conf`, resolver erişilemez) | `dig <DOMAIN>` / `nslookup <DOMAIN>` → cevap dönüyor mu? `cat /etc/resolv.conf` → resolver doğru mu? IP ile `curl` çalışıyorsa sorun DNS'te. Bkz. [`K01`](labs/broken/K01-kirik-vm/solution.md) |
| Ping çalışıyor ama uygulama bağlanmıyor | L3 (IP) sağlam, L4/L7 kopuk: port kapalı, firewall, uygulama down | Katmanı ayır: `ping` (L3) → `nc -vz <HOST> <PORT>` (L4) → `curl` (L7). İlk kırılan katman sebeptir. Bkz. [`A2`](block-a-intuition/A2-ag-tcp-ip.md) |
| `curl: (60) SSL certificate problem` | Sertifika zinciri eksik, isim uyuşmuyor ya da süresi doldu | `openssl s_client -connect <HOST>:443 -servername <HOST>` → zincir + `notAfter`. İsim CN/SAN ile eşleşiyor mu? Bkz. [`A3`](block-a-intuition/A3-ag-dns-http-tls.md) |
| `curl` çok yavaş, sonra takılıyor | DNS zaman aşımı ya da yanlış routing (yanlış gateway) | `curl -w "dns:%{time_namelookup} conn:%{time_connect}\n"` ile nerede beklediğini ölç; `ip route` ile gateway'i doğrula |
| HTTP `301/302` döngüsü | http↔https ya da www yönlendirmesi kendine dönüyor | `curl -IL <URL>` ile `Location` zincirini izle; döngüyü kıran doğru şemayı kullan |
| HTTP `403 Forbidden` (uygulama seviyesi) | Yetki/dosya izni ya da reverse-proxy kuralı | Sunucu logunu oku (`journalctl` / access log); statik dosyada izin, API'de kimlik/rol |

## 🔭 Blok B — Log ve metrik

| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `journalctl` boş / "No journal files" | Persistent journal kapalı ya da yanlış unit adı | `journalctl -u <SVC>` (doğru unit), `-b` (bu boot), `-b -1` (önceki boot). Kalıcı journal için `/var/log/journal` |
| Log "hiçbir şey söylemiyor" | Uygulama structured değil, seviye çok yüksek ya da stdout'a değil dosyaya yazıyor | Log seviyesini düşür; nereye yazdığını bul (`systemd` → journald; container → stdout). Ne loglanır/loglanmaz için bkz. [`B1`](block-b-visibility/B1-log-okuma.md) |
| Prometheus target `DOWN` | Scrape adresi yanlış, `/metrics` yok ya da ağ kapalı | Prometheus UI → Status → Targets → hata sütunu. `curl <TARGET>/metrics` elle çalışıyor mu? Bkz. [`B2`](block-b-visibility/B2-metrik-prometheus.md) |
| PromQL sorgusu boş dönüyor | Metrik adı/label yanlış ya da henüz scrape edilmedi | Metrik adını autocomplete'ten doğrula; label'ları `{job="..."}` ile daralt; scrape aralığı kadar bekle |
| Metrik cardinality patlaması, Prometheus yavaş/OOM | Label'a yüksek-kardinalite değer konmuş (user id, request id) | Label'ları say; kimlik/serbest-metin label'ı kaldır. Bkz. [`B2`](block-b-visibility/B2-metrik-prometheus.md) |
| "Bir şey bozuk ama nerede bilmiyorum" | Belirtiyi kanıta bağlamadan tahmin yürütüyorsun | `status → journalctl → ss/curl` üçlüsüyle **daralt**; hipotezini log/metrikle **kanıtla**. Bkz. [`K01`](labs/broken/K01-kirik-vm/solution.md) |

## 📦 Blok C — Container, CI, Terraform, bulut

| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Container `Up` ama `curl` boş yanıt | Port eşlemesinin **container tarafı** uygulamanın dinlediği portla uyuşmuyor | `docker compose logs <SVC> \| grep listen` → gerçek port; `ports: "HOST:CONTAINER"` sağ tarafı bununla aynı olmalı. Bkz. [`K02`](labs/broken/K02-container-hatasi/solution.md) |
| `docker build` katmanları hep baştan | Cache'i bozan sıra: `COPY . .` bağımlılık kurulumundan önce | Önce `COPY` bağımlılık manifesti + kur, **sonra** kaynağı kopyala. Multi-stage için bkz. [`C1`](block-c-reproducibility/C1-container.md) |
| Image gereğinden çok büyük | Tek-stage build, build araçları imajda kaldı | Multi-stage: derle bir stage'de, yalnız artefaktı kopyala; slim/distroless taban |
| `docker run` → `exec format error` | Image mimarisi (arm64/amd64) makineyle uyuşmuyor | `docker inspect` ile mimariyi gör; `--platform` ile doğru mimariyi çek/derle |
| `:latest` çektin, davranış değişti | Mutable tag; altındaki image sessizce değişti | Sürüm tag'i ya da digest (`@sha256:...`) pin'le. `:latest` üretimde yasak. Bkz. [`C1`](block-c-reproducibility/C1-container.md) |
| CI'da `docker push` → `denied` / `unauthorized` | Registry kimliği yok/yanlış ya da repo yolu hatalı | Registry login adımını doğrula; `<REGISTRY>/<APP>` yolu ve token yetkisi. Bkz. [`C2`](block-c-reproducibility/C2-ci.md) |
| CI "makinemde çalışıyordu" ama pipeline'da patlıyor | Gizli yerel bağımlılık; runner temiz ortam | Bağımlılıkları kilit dosyasıyla pin'le; testi temiz konteynerde çalıştır |
| `Error acquiring the state lock` | Yarıda kalan `apply` `.terraform.tfstate.lock.info`'yu temizlemeden öldü (bayat kilit) | `ps aux \| grep [t]erraform` → canlı işlem yoksa `terraform force-unlock <ID>` (ID hata mesajında). Bkz. [`K03`](labs/broken/K03-terraform-state/solution.md) |
| `terraform plan` her seferinde değişiklik gösteriyor | Drift ya da provider'ın normalize etmediği alan | `terraform plan` diff'ini oku; elle yapılan değişikliği geri al ya da koda taşı |
| `terraform apply` state'i bozdu / yanlış kaynağı sildi | Elle değişiklik + state uyuşmazlığı | Panik yok: `terraform state list/show`; gerekiyorsa `import` ile gerçeği state'e bağla. Bkz. [`C3`](block-c-reproducibility/C3-terraform.md) |
| LocalStack'e bağlanılmıyor | Endpoint/region/sahte kimlik ayarı eksik | `--endpoint-url http://127.0.0.1:4566`, sahte `test`/`test` kimlik, region set. Bkz. [`C4`](block-c-reproducibility/C4-bulut-butce-alarmi.md) |
| Bulutta beklenmedik ücret | Bütçe alarmı yok; kaynak açık unutuldu | Önce **bütçe alarmı** (ilk kural), sonra kaynak. Yerelde `validate/plan` ile doğrula. Bkz. [`C4`](block-c-reproducibility/C4-bulut-butce-alarmi.md) |

## ☸️ Blok D — Kubernetes, güvenlik, GitOps

| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Pod `Pending` | Scheduler yerleştiremiyor: kaynak yok, node selector/taint, PVC bağlanmadı | `kubectl describe pod <POD>` → Events son satır sebebi söyler (Insufficient cpu/memory, unbound PVC, taint) |
| `ImagePullBackOff` / `ErrImagePull` | Image tag yok, registry private (secret yok) ya da isim yanlış | `kubectl describe pod <POD>` → Events: tam image adı + hata. Tag/isim düzelt ya da `imagePullSecrets`. Bkz. [`K04`](labs/broken/K04-imagepullbackoff-rbac/solution.md) |
| `CreateContainerConfigError` | `configMapKeyRef`/`secretKeyRef` var olmayan key/kaynağı istiyor | `describe` Events key adını söyler; ConfigMap/Secret'taki gerçek key'le hizala. Bkz. [`K07`](labs/broken/K07-incident-sim/solution.md) |
| `CrashLoopBackOff` | Container başlıyor ama hemen ölüyor (config, bağımlılık, kod) | `kubectl logs <POD> --previous` → ölen instance'ın logu; `describe` → Last State/Exit Code |
| `OOMKilled` (Exit Code 137) | Container bellek **limitini** aştı, çekirdek öldürdü | `describe` → Last State: OOMKilled. `limits.memory`'yi gerçek ihtiyaca çıkar. Bkz. [`K05`](labs/broken/K05-oomkilled-probe/solution.md) |
| Pod `Running` ama `0/1 Ready`, Service trafik yollamıyor | readinessProbe fail (yanlış port/patika); Pod `Endpoints`'e girmiyor | `describe` → Readiness satırı; `kubectl get endpoints <SVC>` boşsa probe portu uygulamanınkiyle aynı mı? Bkz. [`K05`](labs/broken/K05-oomkilled-probe/solution.md) |
| Service'e erişilmiyor, `endpoints` boş | `Service.selector` Pod etiketiyle eşleşmiyor | `kubectl get svc <SVC> -o jsonpath='{.spec.selector}'` ↔ `kubectl get pods --show-labels`. Selector'ı etikete hizala. Bkz. [`K07`](labs/broken/K07-incident-sim/solution.md) |
| Pod sağlıklı ama ağ üzerinden erişilemiyor | İzin kuralsız `default-deny` NetworkPolicy tüm trafiği kesiyor | `kubectl get networkpolicy -n <NS>`; reddin dengesi olan **allow** kuralı ekle (NetworkPolicy toplamsaldır). Bkz. [`K04`](labs/broken/K04-imagepullbackoff-rbac/solution.md) |
| `Error ... is forbidden` (RBAC) | ServiceAccount'un istenen fiil/kaynak için Role/Binding'i yok | `kubectl auth can-i <FIIL> <KAYNAK> --as=system:serviceaccount:<NS>:<SA>`; eksik izni Role+RoleBinding ile ver, gereğinden fazlasını değil. Bkz. [`D1`](block-d-orchestration/D1-k8s-temel.md) |
| PVC `Pending` | StorageClass yok/yanlış ya da uygun PV yok | `kubectl describe pvc <PVC>` → Events; StorageClass adı ve provisioner'ı doğrula |
| Secret'ı env olarak koydun, log'a sızdı | Secret düz-metin env; uygulama başlangıçta env'i logluyor | Secret'ı dosya olarak mount et ya da env logunu kapat; kaynakta düz-metin secret tutma. Bkz. [`D3`](block-d-orchestration/D3-secret-yonetimi.md) |
| CI imaj tarama adımı "geçiyor" ama imza yok | Supply chain ayrı ders sanıldı; imzalama pipeline'a bağlanmadı | Tarama **ve** imzalama C2 pipeline'ının parçası olmalı, sonradan eklenen ayrı iş değil. Bkz. [`D4`](block-d-orchestration/D4-supply-chain.md) |
| ArgoCD `OutOfSync`, otomatik düzeltmiyor | `syncPolicy.automated` yok (manuel mod); cluster elle değiştirilmiş (drift) | `kubectl -n argocd get app <APP> -o jsonpath='{.spec.syncPolicy}'`; `automated` (+`selfHeal`) aç ya da elle `sync`. Bkz. [`K06`](labs/broken/K06-argocd-out-of-sync/solution.md) |
| `kubectl` → `Unable to connect / context` | Yanlış kubeconfig/context ya da cluster kapalı | `kubectl config current-context`; kind için `kind get clusters`; context'i doğru cluster'a çevir |

## 🔭 Blok E — SLO, alerting, incident, restore

| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| Restore "başarılı döndü" ama hedef boş | Backup schema-only ya da veri gelmedi; çıkış kodu boş backup'ı ele vermez | Çıkış koduna değil `SELECT count(*)`'a bak; dosyada `grep -c '^COPY '`. Bkz. [`K08`](labs/broken/K08-restore-basarisiz/solution.md) |
| Restore `unterminated COPY` / `missing data` | Dump kesik alındı (yarıda kalmış `pg_dump`) | Dosya sonunu kontrol et (`tail`); backup'ın **tam** alındığını her seferinde doğrula. Bkz. [`K08`](labs/broken/K08-restore-basarisiz/solution.md) |
| Backup dosyası `Permission denied` | İzin `000`/yanlış sahip — erişilemeyen backup incident anında yok demektir | `ls -l`; `chmod u+r`; backup erişimini düzenli test et. Bkz. [`E4`](block-e-ownership/E4-veritabani-restore.md) |
| "3 replica var, HA'yız" ama restart'ta kesinti | `strategy: Recreate` tüm pod'ları birden indiriyor; readinessProbe yok | `RollingUpdate` + küçük `maxUnavailable`; readinessProbe ekle; `PodDisruptionBudget`. Bkz. [`K09`](labs/broken/K09-chaos-gameday/solution.md) |
| Alarmlar sürekli çalıyor, kimse bakmıyor (alert fatigue) | Belirti değil sebep-olmayan metriğe alarm; eşik yanlış | Kullanıcı-etkili SLI'a alarm bağla (symptom-based); gürültülü alarmı sustur/sil. Bkz. [`E2`](block-e-ownership/E2-alerting-oncall.md) |
| Error budget bitti ama yeni özellik akıyor | SLO politikası uygulanmıyor; budget sadece rapor | Budget tükendiğinde ne durur yazılı olmalı; SLO'yu karara bağla. Bkz. [`E1`](block-e-ownership/E1-sli-slo-error-budget.md) |
| Incident'te herkes farklı şey biliyor | Timeline tutulmuyor; tek koordinatör yok | Olay anında UTC timeline yaz; rolleri ayır (koordinatör/iletişim). Bkz. [`E3`](block-e-ownership/E3-incident-postmortem.md) |
| Postmortem "kim hata yaptı"ya dönüyor | Blame kültürü; sistem değil kişi sorgulanıyor | Dili sisteme çevir: "sistem bunun canlıya geçmesine izin verdi"; eylem maddesi sahip+tarihli. Bkz. [`E3`](block-e-ownership/E3-incident-postmortem.md) |

---

## 🚫 Teşhis anti-pattern'leri

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| Belirtiyi görünce kök sebebi tahmin edip "düzeltmeye" başlamak | Yanlış katmanı düzeltirsin, ikinci arızayı kaçırırsın | Belirtiyi bir komutla kök sebebe **bağla**, sonra düzelt |
| "Container Up" / "servis active" görünce çalışıyor saymak | Ayakta olmak erişilebilir olmak değildir | Ayrı bir komutla erişimi kanıtla (`curl`/`endpoints`) |
| Çok-arızalı sistemde ilk düzeltmeden sonra durmak | İkinci kök sebep belirtiyi sürdürür, "düzeltemedim" sanırsın | Her düzeltmeden sonra belirtinin **hangi kısmı** gitti ölç |
| `RESTARTS: 12` sayısına bakıp açıklama aramak | Sayı açıklama değil; sebep başka yerde | `describe` → `Last State`/Events sebebi verir |
| İlk hatada `solution.md`'yi açmak | Teşhis kasını hiç çalıştırmazsın | Önce `hint-1` → kendi hipotezini kur |
| Restore'u çıkış koduyla "başarılı" saymak | Boş/kesik backup 0 hatayla döner | `count(*)` ile veri geldi mi kanıtla |
| Panikle `terraform` kilit dosyasını elle silmek | Paylaşılan backend'de yanlış alışkanlık | Önce canlı/bayat ayır, sonra `force-unlock <ID>` |

---

## 📋 Takıldığında sıra

```
[ ] Modülün kendi 🆘 Takıldıysan tablosuna baktım
[ ] Belirtiyi bu sayfada aradım
[ ] Belirtiyi bir komutla kök sebebe bağladım (tahmin etmedim)
[ ] Kırık lab'daysam hints/ klasörünü sırayla açtım (hint-1 → hint-2 → hint-3)
[ ] Çok-arızalı olabilir: ilk düzeltmeden sonra belirtinin kalanını ölçtüm
[ ] Hâlâ takılıysam: log + metrik ile hipotezimi kanıtlamayı denedim
```

---

> *"İyi bir sorun giderme sayfası cevap vermez, doğru soruyu sorduracak yeri gösterir."*
