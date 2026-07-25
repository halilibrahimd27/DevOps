# STATE — Öğrenme Patikası İnşası

**Son güncelleme:** 2026-07-25 · **Son commit:** (bu tur) ⏸️🔴 **TIKANMA / PAUSE (§14.2(b)) — Aşama B (EN varsayılan flip) dokümante edilen yöntemle İMKÂNSIZ.** Tur başı working-tree TEMİZ, son commit `8800b69` (slice-26, P4 KAPALI) — kesintili-tur DEĞİL, PAUSE yoktu, önceki QA exit 0. Bu tur (P4 twin işi bitmiş, tek açık kalem = Aşama B flip) flip'i yürütmeyi denedim; **empirik kanıt:** `mkdocs.yml` i18n `default: tr→en` → `bash scripts/build-docs.sh` (544 md) + `python3 -m mkdocs build --clean` → **build kırıldı** `Exception: Conflicting files for the default language 'en': choose either 'index.md' or 'index.md' but not both`. **Kök sebep** (plugin kaynağı okundu, `mkdocs_static_i18n/{suffix,reconfigure}.py` v1.3.1): suffix şeması **eksiz** `X.md`'yi **default** locale'e bağlar; bizde 334 eksiz `X.md`=**TR içerik** (Kısıt #2/§14.4 korumalı, `.tr.md`'ye rename edilemez) + 210'unun `.en.md` ikizi var → `default: en`'de ikisi de `en` iddia eder → conflict; ikizsiz 124 sayfa da EN sayılıp TR içerikle sunulur. Tek gerçek çözüm = korunan `00-21/X.md`'leri `.tr.md`'ye rename = **Kırmızı çizgi ihlali**. Dışa-dönük konumlandırma kararı → **kullanıcıya bırakıldı** (§14.2(b)): `.local/PAUSE` yazıldı, `Açık kararlar` en üstte 3 seçenek + öneri (Seçenek 1 = Aşama A'da kal). **Deney geri alındı** → baseline yeşil: `git diff mkdocs.yml` boş, `python3 -m mkdocs build --clean` exit 0, `python3 .local/qa.py` exit 0 (yalnız kalıcı `docs/index.en.md` FP uyarısı), iki-locale render (TR kök + EN `/en/`), `_planning` sızmadı. §14.4: `00-21` altı hiçbir dosyaya dokunulmadı; hiçbir kaynak dosya değiştirilmedi/silinmedi/rename edilmedi; `git push --force`/`reset --hard` yok; `main`'e commit yok (feat/learning-path). İçerik işi %100 tamam (tüm 00-21 tam twin, site EN %62.9). Commit: **2 dosya** = STATE + I18N-COVERAGE (tek tek `git add`; `.local/PAUSE` gitignore'da, commit'e girmez). Ayrıntı → `Açık kararlar` + `Sıradaki adım`.

<details><summary>Önceki tur başlığı — P4 slice-26 (SON dilim · #124–127)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-26 (SON dilim · #124–127)** — `21-Field-Notes/system/{kubernetes-cluster-installation, production-ready-repo-layout}` + `21-Field-Notes/terraform/{modules-create-vm, proxmox-configuration}` (→ 21-Field-Notes **14/14 TAM TWIN**; `system/` kapandı 6/6 + `terraform/` kapandı 2/2 → **tüm 00-21 tam twin, P4 KAPANDI**). Tur başı working-tree TEMİZ, son commit `990c185` (slice-25, conventional) — kesintili-tur DEĞİL, normal devam; PAUSE yok; önceki QA raporu exit 0 (yalnız kalıcı `docs/index.en.md` FP uyarısı) → §15.2 öncelikli remediation gerekmedi. Slice-26 = I18N-COVERAGE "P4 — dilim planı" #124–127 ile birebir: `21-Field-Notes/` kalan **son 4** dosya (`find 21-Field-Notes -name '*.md' !-en`=14 + `-name '*.en.md'`=10 ile teyit: README+ansible/2+kubectl/2 [slice-24] + network/1+system/4 [slice-25] zaten twin → kalan yalnız system/2 + terraform/2), klasör sırası (system → terraform) korunarak **4-dosya SON dilim** = 21-Field-Notes 14/14 kapanır. **4 paralel çeviri subagent (general-purpose, dosya başına bir)**, saha-notu ruleset (yapı byte-korunur; komut/YAML/HCL/kubectl/Dockerfile/nginx/echo-command verbatim; yalnız `description`+başlıklar+prose+`Saha notu`→`Field note` callout+`#` yorum+kullanıcı-yüzü echo string + ASCII-tree parantez-açıklaması çevrilir) + gold-standard `21-Field-Notes/README.en.md` + slice-25 twin'leri → remediation gerekmedi, ilk çeviride doğru. **Bağımsız doğruladım (§14.4, subagent raporuna körü körüne DEĞİL):** satır paritesi **tam 4/4** (651/1497/172/682 kaynak==twin, delta 0); **fence paritesi 4/4** (42/36/2/2 kaynak==twin, leading-ws dahil); **in-fence non-comment kod byte-identik 4/4** (awk fence-toggle ile in-fence non-`#` satırlar çıkarılıp `diff` = boş 4/4 → tüm komut/YAML/HCL/Dockerfile/nginx token'ı dokunulmadı; değişen tek şey out-of-fence prose/başlık/description + in-fence `#` yorum); **IP çoklu-kümesi kaynak==twin 4/4** (`diff <(grep IP src) <(grep IP twin)` boş: k8s-install `192.168.1.10/11/12` RFC1918 + `10.244.0.0/16` pod-CIDR + `127.0.0.1` + `0.0.0.0`; production-ready `127.0.0.1`; modules-create-vm `8.8.8.8`; proxmox `192.168.1.1` GW + `192.168.1.100` + `8.8.8.8`/`8.8.4.4` well-known resolver — hepsi doküman-örneği/RFC1918/well-known, **public dış IP 0, yeni IP eklenmedi**); **frontmatter diff = yalnız `description` 4/4** (frontmatter blok `diff` = yalnız satır-2; tags/anahtarlar verbatim); **gerçek Türkçe kalıntısı 0** (`[ışğİŞĞçöüÇÖÜ]`=0 4/4 + diakritiksiz-TR fonksiyon-kelime word-boundary [`icin/degil/kurulum/gerekir/olarak/kullan/ornek/dosya/...`]=0 4/4); **link locale-leak 0/4** (4 dosyada iç `.md` link YOK → `.en.md`/`.tr.md`-in-link 0); **positioning/pazarlama grep 0 hit** (`senior/mid olur`/`maaş`/`salary`/`ROI`/`en kapsamlı`/`garanti`/`guarantee`/`%N artış`/`türkçe kaynak`). Not: production-ready-repo-layout zaten neredeyse tümüyle İngilizce saha notuydu (Dockerfile/nginx/config + EN yorum) → yalnız `description` çevrildi (diff=1 satır); k8s-install prose-yoğun → 154 satır-çifti (başlık+prose+`#` yorum), kod 0 değişti. §14.3 özdenetim: (1) tekrar — saha notu ham komut/config dökümleri, mevcut deep-dive'ın yeniden anlatımı DEĞİL (kaynak zaten repoda; yalnız EN twin üretildi); (2) pazarlama grep 0; (3) süre — saha notları modül değil, `estimated_hours` yok → süre denetimi N/A. QA exit 0 (1 uyarı: önceki turlardan kalan `docs/index.en.md` locale-twin FP; bu 4 twin'den yeni kırık link 0). İki-locale build (build-docs.sh **544** md stage [+4] + python3 -m mkdocs build --clean) exit 0, **4 sayfa İngilizce render** (`site/en/21-Field-Notes/{system/kubernetes-cluster-installation, system/production-ready-repo-layout, terraform/modules-create-vm, terraform/proxmox-configuration}/index.html`, EN-H1 doğrulandı + body-TR-diakritik=0 4/4 python `<article>` ayrıştırması), TR root default korundu (`site/21-Field-Notes/.../index.html` mevcut), `_planning` sızmadı (find site _planning = 0). EN kapsama **%61.7 → %62.9 (206→210/334)**. Working-tree TEMİZ girdi → commit: **6 dosya** = 4 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **`21-Field-Notes` 14/14 → tüm 00-21 TAM TWIN, P4 BİTTİ.** **Sıra: Aşama B (EN varsayılan flip) — KENDİ TURUNDA.** Ön koşullar artık sağlandı (eşik %60 aşıldı → %62.9 + tüm 00-21 tam twin); flip ayrı bir operasyon (mkdocs i18n `default: true` en'e taşı + TR `/tr/`'ye + kök nav + ~924 iç link locale-eksiz teyidi + rozet/`site_url` + iki-locale re-test) → bir-slice/tur sözleşmesi gereği ayrı tur. Detay/adımlar `Açık kararlar` + I18N-COVERAGE "Aşama" bölümünde. **[GÜNCELLEME: bu "ayrı tur"da flip yöntemi imkânsız çıktı — bkz. en üst PAUSE.]**

</details>

<details><summary>Önceki tur başlığı — P4 slice-25 (#119–123)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-25 (#119–123)** — `network/network-segmentation-wazuh-siem` + `system/{devops-certification-roadmap, external-access-solutions, github-actions-pipeline-setup, inventory-management-example}` (→ 21-Field-Notes **10/14**; `network/` kapandı [1/1] + `system/` 4/6). Tur başı working-tree TEMİZ, son commit `f0acc33` (slice-24, conventional) — kesintili-tur DEĞİL, normal devam. Slice-25 = I18N-COVERAGE "P4 — dilim planı" #119–123: `21-Field-Notes/` kalan 9 (network/1 + system/6 + terraform/2); klasör sırası (network → system → terraform) korunarak **iki-dilim dengesi** için **5-dosya dilim** seçildi = network/1 + system alfabetik ilk 4 (`devops-certification-roadmap` 22-satır yönlendirme stub'ı + `external-access-solutions`/`github-actions-pipeline-setup`/`inventory-management-example`). Prose-yoğunluk analizi (fenced-verbatim çıkarılıp): network-segmentation 1256 satır (~222 prose + kod yorumu) + inventory-management ~244 prose = ağır; system'in iki devi `kubernetes-cluster-installation` (651, ~188 prose) + `production-ready-repo-layout` (1497, ~140 prose, config-yoğun) → **slice-26**'ya, orada `terraform/` 2 [854 satır, ~30 prose] ile = **4-dosya son dilim**, 21-Field-Notes 14/14 kapanır. **5 paralel çeviri subagent (sonnet, dosya başına bir)**, saha-notu ruleset (yapı byte-korunur; komut/YAML/HCL/kubectl/echo-command verbatim; yalnız `description`+başlıklar+prose+`Saha notu`/`Placeholder notu` callout+`#` yorum+kullanıcı-yüzü echo string çevrilir) + gold-standard `21-Field-Notes/README.en.md` + slice-24 twin'leri → remediation gerekmedi, ilk çeviride doğru. **Bağımsız doğruladım (§14.4, subagent raporuna körü körüne DEĞİL):** satır paritesi **tam 5/5** (1256/22/342/638/258 kaynak==twin, delta 0); **IP çoklu-kümesi kaynak==twin 5/5** (network `192.168.x.x` RFC1918 24 adres + inventory `10.0.x.x` RFC1918 + external-access `0.0.0.0` bind-all; devops-cert/gh-actions dotted-quad yok — **public IP 0**, yeni IP eklenmedi); **çalıştırılabilir kod verbatim** (fenced-blok içi non-comment satırlar byte-identik awk-diff; değişen tek in-fence satırlar = `echo "…"` kullanıcı-yüzü string + satır-sonu/inline `#` yorum + ASCII-tree `(örnek uygulama)`→`(sample application)` parantezi — kod token'ı [`echo`/`image:`/`- host:`/`ghcr.io/USERNAME/devops-app:latest`/`devops-app.local`] dokunulmadı, strip-diff ile kanıtlandı); **link locale-leak 0/5** (devops-cert 5 iç link `../../22-Learning-Path/certifications/{README,G1-kcna-terraform,G2-cka,G3-cks-aws-saa,HOW-TO-CERTIFY}.md` locale-eksiz korundu; diğer 4'te iç link yok); **frontmatter diff = yalnız `description` 5/5** (tags/anahtarlar verbatim; `- Sertifika` tag'i taksonomi kuralı gereği çevrilmedi); **gerçek Türkçe kalıntısı 0** (`[ışğİŞĞ]`=0 + `[çöüÇÖÜ]`=0 + diakritiksiz-TR-kelime word-boundary=0 5/5; tek eşleşme `- Sertifika` = tags değeri, kural gereği verbatim, residue DEĞİL); **positioning/pazarlama grep 0 hit** (`senior/mid olur`/`maaş`/`salary`/`ROI`/`en kapsamlı`/`garanti`/`guarantee`/`%N artış`/`türkçe kaynak`). §14.3 özdenetim: (1) tekrar — saha notu ham komut/config dökümleri, mevcut deep-dive'ın yeniden anlatımı DEĞİL (kaynak zaten repoda; yalnız EN twin üretildi); (2) pazarlama grep 0; (3) süre — saha notları modül değil, `estimated_hours` yok → süre denetimi N/A. QA exit 0 (1 uyarı: önceki turlardan kalan `docs/index.en.md` locale-twin FP; bu 5 twin'den yeni kırık link 0). İki-locale build (build-docs.sh **540** md stage [+5] + python3 -m mkdocs build --clean) exit 0, **5 sayfa İngilizce render** (`site/en/21-Field-Notes/{network/network-segmentation-wazuh-siem, system/devops-certification-roadmap, system/external-access-solutions, system/github-actions-pipeline-setup, system/inventory-management-example}/index.html`, body-TR=0 5/5 python `<article>` ayrıştırması), TR root default korundu, `_planning` sızmadı (find site _planning = 0). EN kapsama **%60.2 → %61.7 (201→206/334)**. Working-tree TEMİZ girdi → commit: **7 dosya** = 5 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **`21-Field-Notes` 10/14.** **Sıra: P4 slice-26 (SON dilim — `21-Field-Notes/` kalan 4: `system/kubernetes-cluster-installation`, `system/production-ready-repo-layout`, `terraform/modules-create-vm`, `terraform/proxmox-configuration` → 21-Field-Notes 14/14 tam twin; `terraform/`'daki `8.8.8.8`/`8.8.4.4` = Google well-known resolver doküman-örneği, yeni IP DEĞİL; sonraki tur `find 21-Field-Notes -name '*.en.md'` ile 10 twin teyit + I18N dilim tablosu #124+ ile teyit et). 21-Field-Notes kapanınca (slice-26 sonu) → tüm 00-21 tam twin + P4 biter → Aşama B (EN varsayılan flip, %60 zaten AŞILDI) KENDİ TURUNDA değerlendir/yürüt — koşul/gerekçe `Açık kararlar`da.**

</details>

<details><summary>Önceki tur başlığı — P4 slice-24 (#114–118)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-24 (#114–118)** — `21-Field-Notes/{README, ansible/ssh-connectivity-test, ansible/system-preparation, kubectl/cluster-passwords, kubectl/logging-elasticsearch}` (→ 21-Field-Notes **5/14**; README + ansible/2 + kubectl/2 = 3 alt-klasör kapandı). Tur başı working-tree TEMİZ, son commit `a180f57` (slice-23, conventional) — kesintili-tur DEĞİL, normal devam. Slice-24 = I18N-COVERAGE "P4 — dilim planı" #114–118 ile birebir: kalan 00-21 içeriğinin **son klasörü** `21-Field-Notes/` (`find 21-Field-Notes -name '*.md'`=14 + `-name '*.en.md'`=0 ile teyit: 00-17 tam twin, 18-20 rehber/patika P1/P2'de kapsandı → kalan yalnız `21-Field-Notes/`), klasör/alfabetik sırayla README + `ansible/` (2) + `kubectl/` (2) → **5-dosya dilim**, 3 alt-klasör kapanış sınırı; kalan `network/`(1)+`system/`(6)+`terraform/`(2)=9 → slice-25/26. 🎯 **Bu slice ile EN kapsama %58.7→%60.2 (196→201/334): Aşama B eşiği %60 AŞILDI** — ama **Aşama B (EN varsayılan flip) bu turda YAPILMADI** (otonom bir-slice/tur sözleşmesi §14.1.2 + BUILD-PROMPT §Faz-1(c) "şimdi yapma"; flip ayrı bir operasyon: mkdocs i18n `default` taşı + kök nav + ~924 iç link + iki-locale re-test; ayrıca `21-Field-Notes` henüz 5/14 → önce tam twin sonra flip daha temiz) → `Açık kararlar`a + I18N-COVERAGE Aşama bölümüne yazıldı. **Çeviri bu dilimde doğrudan orchestrator tarafından yapıldı** (5 küçük+verbatim-ağırlıklı dosya, 35–407 satır; `cp` kaynak→twin sonra yalnız çevrilebilir satırları Edit — subagent overhead yerine tam-kontrol, slice-23 emsali), oturmuş genişletilmiş ruleset. **Bağımsız doğruladım (§14.4):** satır deltası **0/0/0/0/0 (tam parite 5/5)**; **tam kaynak↔twin `diff` = yalnız istenen satırlar değişti** — README (prose+5 tablo tam twin; iç link'ler `ansible/…md`/`kubectl/…md`/`system/…md`/`terraform/…md`/`network/…md` locale-eksiz korundu), system-preparation (yalnız `description`+H1+`Saha notu`→`Field note` callout+3 bash `#` yorum [`# System preparation playbook oluştur`→`# Create the system preparation playbook` vb.]; 401 satır Ansible inventory/playbook YAML byte-identik — `ansible_host: <K8S_*_IP>`/`node_labels`/`node_taints`/HAProxy cfg/containerd/kubeadm verbatim), logging-elasticsearch (yalnız `description`; 372 satır kubectl/YAML byte-identik — ES/Kibana/Logstash/Filebeat `kind:`/`image: docker.elastic.co/*:8.5.1`/RBAC verbatim; NOT: kaynak YAML fenced DEĞİL → twin de değil, fence 0/0), ssh-connectivity-test (`description`+H1+callout+1 `#` yorum `# SSH bağlantısını test et`→`# Test SSH connectivity`; `# Master/Worker/Storage nodes` zaten EN), cluster-passwords (`description`+H1+callout+echo-string prose `Kullanıcı`→`User`/`Parola`→`Password`/`Bulunamadı`→`Not found`/`PAROLALARİ`→`PASSWORDS`/`SERVİS ERİŞİM BİLGİLERİ`→`SERVICE ACCESS INFORMATION`; `kubectl get secret … -o jsonpath`/namespace/`base64 --decode`/`Security disabled` verbatim). Gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl proper-noun = 0 satır 5/5; diakritiksiz TR-fonksiyon-kelime word-boundary 0 satır 5/5; render `<article>` body-TR=0 3/3 python HTML ayrıştırması [README+cluster-passwords+system-preparation], içerik EN). Link locale-eksiz (5/5 `.en.md`/`.tr.md`-in-link = 0). Frontmatter 5/5 diff = yalnız `description` çevrildi (tags/anahtarlar verbatim). **Positioning/pazarlama grep:** 5 twin'de ünvan/maaş ban'i (`senior olur`/`mid olur`/`maaş`/`salary`/`ROI`/`en kapsamlı`/`garanti`/`guarantee`/`%N artış`) **0 hit**. **IP taraması:** 5 twin'de public/dotted-quad IP yok (yalnız `<K8S_*_IP>`/`<K8S_LB_VIP>`/`<INGRESS-IP>` placeholder + RFC1918 pod/service CIDR `10.244.0.0/16`/`10.96.0.0/12` kaynaktan verbatim; `21-*` kaynağı değiştirilmedi Kısıt #2; kalan `terraform/`'daki `8.8.8.8`/`8.8.4.4` = Google well-known resolver, doküman-örneği — slice-25 kapsamında). **İçerik kaliteli → benimsedim.** §14.3 özdenetim: (1) tekrar — saha notu ham komut/config dökümleri, mevcut deep-dive'ın yeniden anlatımı değil (kaynak zaten repoda; yalnız EN twin üretildi); (2) ünvan/pazarlama grep 0 hit; (3) süre — saha notları modül değil, `estimated_hours` frontmatter'ı yok → süre denetimi N/A. QA exit 0 (1 uyarı: önceki turlardan kalan qa.py `docs/index.en.md` locale-twin FP; bu 5 twin'den yeni kırık link 0). İki-locale build (build-docs.sh **535** md stage [+5] + python3 -m mkdocs --clean) exit 0, 5 sayfa İngilizce render (`site/en/21-Field-Notes/{index, ansible/ssh-connectivity-test, ansible/system-preparation, kubectl/cluster-passwords, kubectl/logging-elasticsearch}/index.html`, body-TR=0), TR root default korundu, `_planning` sızmadı (find site _planning = 0). EN kapsama %58.7 → %60.2 (201/334). Working-tree TEMİZ girdi → commit: **7 dosya** = 5 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **`21-Field-Notes` 5/14.** **Sıra: P4 slice-25 (`21-Field-Notes/` kalan 9, klasör sırasıyla: `network/network-segmentation-wazuh-siem` [1256 satır — tek başına dilim olabilir] → `system/` 6 [`devops-certification-roadmap`=22-satır yönlendirme stub'ı dahil] → `terraform/` 2 [`8.8.8.8`/`8.8.4.4` well-known resolver, doküman-örneği]; sonraki tur `find 21-Field-Notes -name '*.en.md'` ile 5 twin teyit + kalan 9 için dilim seç + I18N dilim tablosu #119+ ile teyit et). `21-Field-Notes` kapanınca (slice-25/26 sonu) Aşama B'yi kendi turunda değerlendir/yürüt.**

</details>

<details><summary>Önceki tur başlığı — P4 slice-23 (#110–113)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-23 (#110–113)** — `17-Templates/{prometheus-rules/README, terraform/README, runbooks/postmortem-template, runbooks/runbook-template}` (→ 17-Templates **tam twin 10/10**). Tur başı working-tree TEMİZ, son commit `74d01bf` (slice-22, conventional) — kesintili-tur DEĞİL, normal devam. Slice-23 = I18N-COVERAGE "P4 — dilim planı" #110–113 ile birebir: kalan 00-21 içeriğini **klasör sırasıyla** → `17-Templates/` kalan 4 (`find 17-Templates -name '*.md'` + `-name '*.en.md'` ile teyit: kök `README`[P2] + 5 alt-klasör index [slice-22] zaten twin; bu 4 kapanınca **10/10 tam twin** — 17-Templates'te twin'siz `.md` kalmadı). **4-dosya dilim** (klasör kapanış sınırı: sonraki `21-Field-Notes/` farklı kategori, ayrı dilime). Hiçbirinde anchor-linkli iç ToC yok (4 dosyada `](#`=0, `{ #`=0). **Çeviri bu dilimde doğrudan orchestrator tarafından yapıldı** (4 küçük dosya, 40–164 satır; subagent overhead'i yerine tam-kontrol — deliverable aynı: yapı-korur EN twin), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`17-Templates/README.en.md`). **Bağımsız doğruladım (§14.4):** satır deltası **0/0/0/0 (tam parite 4/4)** — başlık 8/5/12/19, tablo-satırı 9/5/28/6, fence 2/2/0/10 (twin==source), blank-line 23/9/33/39 hepsi tam parite → hiçbir dosyada yapı satırı EKLENMEDİ, saf çeviri. Gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl footer/proper-noun = 0 satır 4/4; diakritiksiz TR-fonksiyon-kelime word-boundary 0 satır 4/4; render `<article>` body-TR=0 4/4 python HTML ayrıştırması, içerik EN). Link locale-eksiz (4/4 `.en.md`/`.tr.md`-in-link = 0). Frontmatter 4/4 diff = yalnız `description` çevrildi (tags/anahtarlar verbatim). **Positioning/pazarlama grep:** 4 twin'de ünvan/maaş ban'i (`senior olur`/`mid olur`/`maaş`/`salary`/`ROI`/`en kapsamlı`/`garanti`/`guarantee`/`%N artış`) **0 hit**. runbook-template'te `Even someone who isn't a senior DevOps` = TR kaynak `Senior DevOps olmayan biri de takip edip` sadık çevirisi = runbook'u izleyebilecek **beceri seviyesi** tanımı (runbook junior tarafından da takip edilebilmeli), ünvan/kariyer iddiası DEĞİL; `17-*` kaynağı değiştirilmedi (Kısıt #2), ban kapsamı `22-Learning-Path/`. **IP taraması:** 4 twin'de dotted-quad IP **yok** (yalnız `example.com`/`status.example.com`/`grafana.example.com` placeholder host'lar — gerçek IP/credential yok; kaynakta zaten örnek host'lar). **Verbatim korundu + non-comment fence-line diff bağımsız çalıştırıldı:** prometheus-rules YAML — `kind: PrometheusRule` + 6 `record: sli:<APP_NAME>:availability:{5m,1h,6h,1d,3d}`/`slo:<APP_NAME>:target expr: vector(0.999)` + multi-window multi-burn alert (`14.4*(1-0.999)`/`6*(1-0.999)` eşikleri) + `histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket{app="<APP_NAME>"}[5m]))) > 0.5` PromQL + `runbook_url`/`dashboard_url` placeholder URL — non-comment fence-line diff = **yalnız** annotation `summary:`/`description:` insan-yüzü alert prose'u Türkçe→İngilizce (kod/PromQL/key/expr byte-identik); `#` YAML yorumları çevrildi (`# 5 dakikalık availability oranı`→`# 5-minute availability ratio`, `# → 30 günlük budget'ı 2 saatte yakar`→`# → burns the 30-day budget in 2 hours`). terraform HCL `source = "git::https://…//17-Templates/terraform?ref=<VERSION>"` + `main.tf`/`variables.tf`/`outputs.tf` blok referansı verbatim, bash `#` yorum + prose çevrildi (`# Modülü kendi root config'inden çağır`→`# Call the module from your own root config`). postmortem markdown template — SEV/`@alice`/`@bob`/`INC-12345`/PR `#4521`/`<COMMIT_SHA>`/UTC timeline (`14:00..15:00`)/`kubectl rollout undo`/2026 tarihler/EUR figürler + `@handle`'lar verbatim; prose + tablo başlıkları (`Metrik`→`Metric`/`Zaman`→`Time`/`Aksiyon`→`Action`) çevrildi; `3.200`→`3,200` (TR binlik `.` → EN `,`). runbook markdown template — bash (`kubectl get/top/logs pods -n <NS> -l app=<APP>` + jsonpath `{range .items[*]}…{end}` + `grep -i 'error\|fatal\|panic'` + `kubectl rollout undo/status deployment/<APP> -n <NS>`) verbatim; `#` yorum + prose + eskalasyon/iletişim/geçmiş-incident tabloları + kapanış checklist çevrildi + placeholder-içi TR açıklama çevrildi (`<spesifik komut>`→`<specific command>`, `<her şey OK mi?>`→`<is everything OK?>`, `<DNS / Load balancer komut>`→`<DNS / Load balancer command>`). **İçerik kaliteli → benimsedim.** §14.3 özdenetim: (1) tekrar — template/index README'leri, mevcut deep-dive'ın yeniden anlatımı değil (kaynak zaten repoda; yalnız EN twin üretildi); (2) ünvan/pazarlama grep 0 hit; (3) süre — template'ler modül değil, `estimated_hours` frontmatter'ı yok → süre denetimi N/A. QA exit 0 (1 uyarı: önceki turlardan kalan qa.py `docs/index.en.md` locale-twin FP; bu 4 twin'den yeni kırık link 0). İki-locale build (build-docs.sh **530** md stage [+4] + python3 -m mkdocs --clean) exit 0, 4 sayfa İngilizce render (`site/en/17-Templates/{prometheus-rules,terraform,runbooks/postmortem-template,runbooks/runbook-template}/index.html`, body-TR=0 4/4), TR root default korundu, `_planning` sızmadı (find site _planning = 0). EN kapsama %57.5 → %58.7 (196/334) — **Aşama B eşiği %60'a 4 site sayfası kaldı**. Working-tree TEMİZ girdi → commit: **6 dosya** = 4 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **`17-Templates` artık tam twin (10/10).** **Sıra: P4 slice-24 (en son P4 klasörü `21-Field-Notes/` — 00-17 tam twin; sonraki tur `find 21-Field-Notes -name '*.md'` + `find 21-Field-Notes -name '*.en.md'` + I18N dilim tablosu #114+ ile teyit et; P4'ün son klasörü, kapanınca Aşama B %60 eşiği değerlendirilir).**

</details>

<details><summary>Önceki tur başlığı — P4 slice-22 (#105–109)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-22 (#105–109)** — `17-Templates/{dockerfiles, github-actions, gitignore, kubernetes, kyverno-policies}/README` (alt-klasör index README'leri, alfabetik ilk 5). Tur başı working-tree TEMİZ, son commit `7de3d42` (slice-21, conventional) — kesintili-tur DEĞİL, normal devam. Slice-22 = I18N-COVERAGE "P4 — dilim planı" #105–109 ile birebir: kalan 00-21 içeriğini **klasör sırasıyla** → `17-Templates/` alt-klasör index README'lerinden alfabetik ilk 5 (`find 17-Templates -name '*.md'` + `-name '*.en.md'` ile teyit: kök `17-Templates/README`[P2] zaten twin; kalan `prometheus-rules/README`+`terraform/README`+`runbooks/{postmortem-template,runbook-template}` → slice-23). **5-dosya dilim** (klasör sınırı: runbook template'leri deep-dive değil, ayrı dilime bırakıldı). Hiçbirinde anchor-linkli iç ToC yok (5 dosyada `](#`=0, `{ #`=0). 5 paralel çeviri subagent (dosya başına bir, general-purpose), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`17-Templates/README.en.md`) → remediation gerekmedi, ilk çeviride doğru. **Bağımsız doğruladım (subagent raporlarına körü körüne değil, §14.4):** satır deltası **0/0/0/0/0 (tam parite 5/5)** — başlık 62/61/13/31/20, tablo-satırı 11/11/6/17/11, fence 6/6/10/16/6 (twin==source), blank-line 61/62/19/41/21 hepsi tam parite → hiçbir dosyada yapı satırı EKLENMEDİ, saf çeviri. Gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl footer/proper-noun = 0 satır 5/5; diakritiksiz TR-fonksiyon-kelime word-boundary 0 satır 5/5 — `kubernetes.en.md`'deki 2 eşleşme = İngilizce `once` kelimesi, Türkçe DEĞİL, FP; render `<article>` body-TR=0 5/5 python HTML ayrıştırması, içerik EN). Link locale-eksiz (5/5 `.en.md`-in-link = 0). Frontmatter 5/5 diff = yalnız `description` çevrildi (tags/anahtarlar verbatim). **Positioning/pazarlama grep:** 5 twin'de ünvan/maaş ban'i (`senior olur`/`mid olur`/`maaş`/`salary`/`ROI`/`en kapsamlı`) **0 hit**; `kubernetes.en.md`'de 2 `guarantee` hit doğrulandı → **TR kaynakta `garanti` verbatim mevcut** (`# PodDisruptionBudget — … garantisi` satır 433 kod-yorumu + anti-pattern hücresi `minAvailable ile taban garanti` satır 506, aynı hücreler) = PodDisruptionBudget minimum-pod garantisi, mühendislik terimi, ünvan/pazarlama iddiası DEĞİL (slice-17 "Burnout guaranteed" + slice-13 "No guarantees at all" emsali); `17-*` kaynağı değiştirilmedi (Kısıt #2); ban kapsamı `22-Learning-Path/`. **IP taraması:** 5 twin'deki tüm IP'ler (`0.0.0.0/0` bind-all + RFC1918 `10.0.0.0/8`/`172.16.0.0/12`/`192.168.0.0/16` NetworkPolicy egress `except:` örneği) TR kaynakta verbatim mevcut, doküman-örneği, **yeni IP eklenmedi** — gerçek IP/credential yok. Spot-read: dockerfiles multi-stage Go/Node/Python + `HEALTHCHECK 0.0.0.0`/`ENTRYPOINT` + placeholder (`<REGISTRY>`/`<IMAGE>`/`<TAG>`/`<APP_NAME>`) verbatim, `#` yorum çevrildi; github-actions reusable workflow YAML (`uses:`/`with:`/`run:` + `aquasecurity/trivy-action@<VERSION>` SHA-pin ref) verbatim, prose+yorum çevrildi; gitignore pattern'leri (`*.tfstate`/`node_modules/`/`.env`/`!.env.example`) verbatim, `#` yorum + anti-pattern tablosu çevrildi; kubernetes manifest (`kind: Deployment|Service|HPA|NetworkPolicy|PodDisruptionBudget` + `securityContext`/probe/`minAvailable`/`ipBlock cidr: 0.0.0.0/0 except: 10.0.0.0/8`) verbatim, PDB 2-satır kod-yorumu clause-sırası EN-okunur dağıtıldı (iki anlam da korundu, satır sayısı sabit); kyverno-policies policy (`kind: ClusterPolicy`/`validationFailureAction: Enforce`/`verifyImages`/attestor) verbatim, `message:` prose + `#` yorum çevrildi. **İçerik kaliteli → benimsedim.** §14.3 özdenetim: (1) tekrar — template index README'leri, mevcut deep-dive'ın yeniden anlatımı değil (kaynak zaten repoda, yalnız EN twin üretildi); (2) ünvan/pazarlama grep 0 hit; (3) süre — index README'ler modül değil, `estimated_hours` frontmatter'ı yok → süre denetimi N/A. QA exit 0 (1 uyarı: önceki turlardan kalan qa.py `docs/index.en.md` locale-twin FP; bu 5 twin'den yeni kırık link 0). İki-locale build (build-docs.sh 526 md stage + python3 -m mkdocs --clean) exit 0, 5 sayfa İngilizce render (`site/en/17-Templates/{dockerfiles,github-actions,gitignore,kubernetes,kyverno-policies}/index.html`, body-TR=0), TR root default korundu, `_planning` sızmadı (find site _planning = 0). EN kapsama %56.0 → %57.5 (192/334). Working-tree TEMİZ girdi → commit: **7 dosya** = 5 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **Sıra: P4 slice-23 (`17-Templates/` kalan 4: `prometheus-rules/README`, `terraform/README`, `runbooks/postmortem-template`, `runbooks/runbook-template`; sonra en son `21-Field-Notes/`; sonraki tur `find 17-Templates -name '*.md'` + `find 17-Templates -name '*.en.md'` + I18N dilim tablosu #110+ ile teyit et).**

</details>

<details><summary>Önceki tur başlığı — P4 slice-21 (#101–104)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-21 (#101–104)** — `16-Cheatsheets/{kubectl, networking-tools, terraform, vim-survival}` (→ 16-Cheatsheets **tam twin 10/10**). Tur başı working-tree TEMİZ, son commit `161ab8a` (slice-20, conventional) — kesintili-tur DEĞİL, normal devam. Slice-21 = I18N-COVERAGE "P4 — dilim planı" #101–104 ile birebir: kalan 00-21 deep-dive'ları **klasör sırasıyla** → `16-Cheatsheets` kalan 4 `.en.md`'siz cheatsheet (`ls 16-Cheatsheets/*.md` + `*.en.md` ile teyit: README[P2]+linux-troubleshooting[P3-s2]+aws-cli/docker/git/helm[s20] zaten twin; bu 4 kapanınca **10/10 tam twin**). **4-dosya dilim** (5 değil) çünkü klasör kapanış sınırı temiz — sonraki `17-Templates/` index README'leri farklı kategori (deep-dive değil, index), ayrı dilime bırakıldı. Hiçbirinde anchor-linkli iç ToC yok (4 dosyada `](#`=0, `{ #`=0). 4 paralel çeviri subagent (dosya başına bir, sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`16-Cheatsheets/{git,aws-cli,docker,helm,linux-troubleshooting}.en.md`) → remediation gerekmedi, ilk çeviride doğru. **Bağımsız doğruladım (subagent raporlarına körü körüne değil, §14.4):** satır deltası **0/0/0/0 (tam parite 4/4)** — başlık 61/82/53/22, tablo 9/10/0/20, fence 22/22/30/30 (twin==source), blank-line 60/72/66/49 hepsi tam parite → hiçbir dosyada yapı satırı EKLENMEDİ, saf çeviri. Gerçek Türkçe kalıntısı **0** (`[ışğİŞĞ]` excl description/footer = 0 satır 4/4; diakritiksiz TR-fonksiyon-kelime word-boundary 0 satır 4/4 — `terraform.en.md`'deki 10 eşleşme = Terraform `-var`/`var.`/`-var-file` HCL keyword'ü, Türkçe "var" DEĞİL, FP; render `<article>` body-TR=0, terraform.en.md python HTML ayrıştırması, içerik EN). Link locale-eksiz (4/4 `.en.md`-in-link = 0). Frontmatter 4/4 diff = yalnız `description` çevrildi (tags/anahtarlar verbatim; diakritiksiz-TR kaynak description'lar 4/4 doğal EN'e çevrildi). **Positioning/pazarlama grep:** 4 twin'de ünvan/maaş/pazarlama ban'i (`senior olur`/`mid olur`/`maaş`/`salary`/`ROI`/`en kapsamlı`/`garanti`/`guarantee`) **0 hit**; `16-*` kaynağı değiştirilmedi (Kısıt #2); ban kapsamı `22-Learning-Path/`. **IP taraması:** 4 twin'deki tüm IP'ler (`8.8.8.8`/`1.1.1.1` well-known public resolver + `10.0.0.5`/`10.0.0.0/8`/`10.0.0.0/16`/`192.168.1.0/24` RFC1918 private) TR kaynakta verbatim mevcut, doküman-örneği, **yeni IP eklenmedi** — gerçek IP/credential yok. Spot-read: kubectl JSONPath (`{range .items[*]}{.metadata.name}…{end}`) + `jq` filtreleri + acil-senaryo tablosu (ImagePullBackOff/CrashLoopBackOff/OOMKilled teşhis satırları) çevrildi, komut verbatim; networking-tools epigraf (`"Ping ran, came back; curl worked; but the app returns 503."`) + curl timing-breakdown template + `openssl s_client`/`tcpdump`/`ssh -L/-R/-D` verbatim, kod-yorumu çevrildi; terraform HCL içi TR string `error_message`→`"Region must start with us- or eu-."` + `"ç ek"` typo→`(pull from vault)` niyet-sadık + tfsec→Trivy 2023 konsolidasyon notu korundu + best-practices ✅/❌ bullet çevrildi, `terraform`/HCL syntax verbatim; vim-survival kolon-hizalı komut referansı (`w        next word`/`dd       delete line`) hizalama korundu + TR açıklama çevrildi + ASCII mod/hareket diyagramı + `.vimrc` `set`/`cmap` verbatim + TR yorum çevrildi + acil-senaryo tablosu (`"How do I get out of Vim?"` — `:q!`). **İçerik kaliteli → benimsedim.** §14.3 özdenetim: (1) tekrar — cheatsheet komut referansı, mevcut deep-dive'ın yeniden anlatımı değil (kaynak zaten repoda, yalnız EN twin üretildi); (2) ünvan/pazarlama grep 0 hit; (3) süre — cheatsheet'ler modül değil, `estimated_hours` frontmatter'ı yok → süre denetimi N/A. QA exit 0 (1 uyarı: önceki turlardan kalan qa.py `docs/index.en.md` locale-twin FP; bu 4 twin'den yeni kırık link 0). İki-locale build (build-docs.sh 521 md stage + python3 -m mkdocs --clean) exit 0, 4 sayfa İngilizce render (`site/en/16-Cheatsheets/{kubectl,networking-tools,terraform,vim-survival}`, body-TR=0), TR root default korundu, `_planning` sızmadı (find site _planning = 0). EN kapsama %54.8 → %56.0 (187/334). **`16-Cheatsheets` artık tam twin (10/10).** Working-tree TEMİZ girdi → commit: **6 dosya** = 4 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **Sıra: P4 slice-22 (`17-Templates/` alt-klasör index README'leri, klasör/alfabetik sırayla ilk 5: `dockerfiles/README`, `github-actions/README`, `gitignore/README`, `kubernetes/README`, `kyverno-policies/README`; 17-Templates kök `README`[P2] zaten twin; kalan `prometheus-rules/README`+`terraform/README`+`runbooks/{postmortem-template,runbook-template}` → slice-23; sonra en son `21-Field-Notes/`; sonraki tur `find 17-Templates -name '*.md'` + `find 17-Templates -name '*.en.md'` + I18N dilim tablosu #105+ ile teyit et).**

</details>

<details><summary>Önceki tur başlığı — P4 slice-20 (#96–100)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-20 (#96–100)** — `15-AI-LLMOps/Self-Hosted-LLM` (→ 15-AI-LLMOps **tam twin 8/8**) + `16-Cheatsheets/{aws-cli, docker, git, helm}` (→ 16-Cheatsheets **6/10**). ⚠️ **KESİNTİLİ TUR TOPARLAMASI:** slice-20'nin 5 `.en.md`'si önceki turda ÜRETİLDİ (mtime 07-24 20:14–20:15, slice-19 commit `ec8934c`@20:07'den hemen sonra) ama **commit edilmeden** öldü (bu tur başı `git status`: 5 `??` = `15-AI-LLMOps/Self-Hosted-LLM.en.md` + `16-Cheatsheets/{aws-cli,docker,git,helm}.en.md`; son commit `ec8934c`=slice-19; working-tree'de başka kirlilik yok). Körlemesine commit etmedim → **bağımsız yeniden doğruladım** (§14.4 + slice-16/slice-13 kesintili-tur emsali). Slice-20 = I18N-COVERAGE "P4 — dilim planı" #96–100 ile birebir: kalan 00-21 deep-dive'ları **klasör sırasıyla** → `15-AI-LLMOps` kalan 1 (`ls 15-AI-LLMOps/*.md` + `*.en.md` ile teyit: README[P2]+AI-Augmented-Operations[s18]+5[s19] zaten twin; Self-Hosted-LLM kapanınca **8/8 tam twin**), sonra `16-Cheatsheets` klasör sırasında `.en.md`'siz ilk 4 (aws-cli/docker/git/helm; README[P2]+linux-troubleshooting[P3-s2] zaten twin; kalan kubectl+networking-tools+terraform+vim-survival → slice-21). Hiçbirinde anchor-linkli iç ToC yok (5 dosyada `](#`=0, `{ #`=0). **Bağımsız doğruladım (üretim önceki turda; ben orchestrator olarak dosyaları doğrudan denetledim, subagent raporu yok, §14.4):** satır deltası **0/0/0/0/0 (tam parite 5/5)** — başlık 29/76/72/65/69, tablo 51/8/9/11/8, fence 18/26/22/24/30 (twin==source), blank-line 58/77/71/68/57 hepsi tam parite → hiçbir dosyada yapı satırı EKLENMEDİ, saf çeviri. Gerçek Türkçe kalıntısı **0** (`[ışğİŞĞ]` excl footer proper-noun = 0 satır 5/5; diakritiksiz TR-fonksiyon-kelime word-boundary 0 satır 5/5; render `<article>` body-TR=0, Self-Hosted-LLM + aws-cli + git python HTML ayrıştırması, footer proper-noun `Halil İbrahim Dürmüş` site-chrome FP hariç, içerik body EN). Link locale-eksiz (5/5 `.en.md`-in-link = 0). Frontmatter 5/5 diff = yalnız `description` çevrildi (tags/anahtarlar verbatim; diakritiksiz-TR kaynak description'lar [docker/git/aws-cli/Self-Hosted-LLM] doğal EN'e çevrildi). **Positioning/pazarlama grep:** 5 twin'de ünvan/maaş ban'i (`senior olur`/`mid olur`/`maaş`/`en kapsamlı`/`garanti`) **0 hit**; `git.en.md` description'daki `Tips senior devs use daily` = TR kaynak `Senior dev'lerin gunluk kullandigi ipuclari` sadık çevirisi = içerik/kitle tanımı, ünvan iddiası DEĞİL; `16-*` kaynağı değiştirilmedi (Kısıt #2); ban kapsamı `22-Learning-Path/` (slice-16 `maaş`/`garanti` emsali). Spot-read: Self-Hosted-LLM vLLM/Ollama/Llama Stack + model adları (Llama 3.3 8B/70B, Mistral Large, Qwen 2.5, DeepSeek R1, Phi-3.5, Gemma 2) + GPU specs (A100/H100/A10/RTX 4090) + `$5K/month`/`$10K-100K` CapEx figürleri (TR kaynakta verbatim, kaynak-sadık) + epigraf çevrildi; git.en.md komutları (`git log -L`/`git bisect`/`git worktree`/`git reflog`) satır satır verbatim, yalnız kod-yorumu (`# short branch info`/`# history of a function`/`# follow renames`) İngilizce'ye çevrildi + placeholder `<COMMIT>` korundu + epigraf `"You're not using Git — Git is using you."` çevrildi; aws-cli/docker/helm CLI komutları (`aws sts assume-role`/`docker buildx`/`helm template`) verbatim, kod-yorumu çevrildi, placeholder `<REGISTRY>` vb. korundu. Placeholder gerçek IP/credential yok. **İçerik kaliteli → benimsedim.** QA exit 0 (1 uyarı: önceki turlardan kalan qa.py docs/index.en.md locale-twin FP; bu 5 twin'den yeni kırık link 0). İki-locale build (build-docs.sh 517 md stage + python3 -m mkdocs --clean) exit 0, 5 sayfa İngilizce render (`site/en/15-AI-LLMOps/Self-Hosted-LLM` + `site/en/16-Cheatsheets/{aws-cli,docker,git,helm}`, body-TR=chrome-FP only), TR root default korundu, `_planning` sızmadı (find site _planning = 0). EN kapsama %53.3 → %54.8 (183/334). **`15-AI-LLMOps` artık tam twin (8/8); `16-Cheatsheets` 6/10** (README[P2]+linux-troubleshooting[P3] + bu tur 4; kalan kubectl+networking-tools+terraform+vim-survival → slice-21). Working-tree'deki 5 orphan `.en.md` girdi → commit: **7 dosya** = 5 kurtarılan `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **Sıra: P4 slice-21 (`16-Cheatsheets/*` kalan 4: `kubectl`, `networking-tools`, `terraform`, `vim-survival` → 16-Cheatsheets 10/10 tamamlar; sonra `17-Templates/` index'leri → en son `21-Field-Notes/`; sonraki tur `ls 16-Cheatsheets/*.md` + `ls 16-Cheatsheets/*.en.md` + I18N dilim tablosu #101+ ile teyit et).**

</details>

<details><summary>Önceki tur başlığı — P4 slice-19 (#91–95)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-19 (#91–95)** — `15-AI-LLMOps/{LLM-in-Production, Model-Cost-Optimization, Prompt-Engineering-for-Ops, RAG-Architecture, Safety-and-Guardrails}` (→ 15-AI-LLMOps **7/8**, kalan yalnız Self-Hosted-LLM). Tur başı working-tree TEMİZ, son commit `b5152b8` (slice-18, conventional) — kesintili-tur DEĞİL, normal devam. Slice-19 = I18N-COVERAGE "P4 — dilim planı" #91–95 ile birebir: kalan 00-21 deep-dive'ları **klasör sırasıyla** → `15-AI-LLMOps` kalan 6'nın ilk 5 (`ls 15-AI-LLMOps/*.md` + `ls 15-AI-LLMOps/*.en.md` ile teyit: README[P2]+AI-Augmented-Operations[s18] zaten twin; 11-SRE/12-FinOps/13-Platform-Engineering/14-Sustainability zaten tam twin → atlandı; 6.'sı Self-Hosted-LLM → slice-20). Hiçbirinde anchor-linkli iç ToC yok (5 dosyada `](#`=0, `{ #`=0). 5 paralel çeviri subagent (dosya başına bir, sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`15-AI-LLMOps/{AI-Augmented-Operations,README}.en.md`) → remediation gerekmedi, ilk çeviride doğru. **Bağımsız doğruladım (subagent raporlarına körü körüne değil, §14.4):** satır deltası **0/0/0/0/0 (tam parite 5/5)** — başlık 47/28/37/34/40, tablo 23/20/13/31/24, fence 30/26/42/32/38 (twin==source), blank-line 94/71/87/79/73 hepsi tam parite → hiçbir dosyada yapı satırı EKLENMEDİ, saf çeviri. Gerçek Türkçe kalıntısı **0** (`[ışğİŞĞ]` excl path/proper-noun = 0 satır 5/5; diakritiksiz TR-fonksiyon-kelime word-boundary 0 satır 5/5; render `<article>` body-TR = yalnız footer proper-noun `Halil İbrahim Dürmüş` `İ`/`ü` site-chrome FP=2/sayfa 5/5 [slice-16 emsali], içerik body EN). Link locale-eksiz (5/5 `.en.md`-in-link = 0). Frontmatter 5/5 diff = yalnız `description` çevrildi (tags/anahtarlar verbatim; diakritiksiz-TR kaynak description'lar doğal EN'e çevrildi). **Positioning/pazarlama grep:** 4 twin'de 0 hit; `Model-Cost-Optimization.en.md`'de 6 `ROI` hit doğrulandı → **hepsi TR kaynakta verbatim mevcut, sadık çeviri:** description satır 2 (`fine-tuning ROI ile ayni isi %70 ucuza`→`fine-tuning ROI to do the same work 70% cheaper`) + intro satır 16 + `### 6️⃣ Fine-Tuning ROI` başlık 179 (=TR `Fine-Tuning ROI`) + `ROI: break-even in 3 months` satır 190 (=TR `ROI: 3 ayda break-even`) + anti-pattern satır 275 (=TR `Fine-tune ROI hesaplamadan`) + checklist satır 294 (=TR `Fine-tune ROI hesaplaması`). Fine-tuning geri-dönüşü FinOps/mühendislik kavramı; ünvan/maaş/pazarlama iddiası DEĞİL (slice-17 Toil-Reduction ROI + slice-18 Efficiency-Practices ROI + slice-3 Chaos "ROI report" emsali). `$50K-500K` tasarruf figürü (Model-Cost satır 322) TR kaynakta verbatim mevcut, yeni iddia değil. `15-*` kaynağı değiştirilmedi (Kısıt #2). Spot-read (subagent + orchestrator): LLM-in-Production production mimarisi ASCII diyagram etiketi (`versiyonlu, A/B'li, registry'den`→`versioned, A/B-tested, from the registry`) + eval JSON fixture prose (`"Siparişim nerede?"`→`"Where is my order?"`) çevrildi, kod identifier verbatim; Model-Cost fine-tuning ROI kod-bloğu ($ figürler/break-even verbatim, `Senaryo`→`Scenario` etiket) + Haiku/Batch API/prompt-caching yüzde figürleri kaynak-sadık; Prompt-Engineering prompt-template instruction prose (`Türkçe yaz`→`Write in English`, reuse için) + `[`11-SRE/Runbook-Template.md`]` locale-eksiz + `80% correct` figürü; RAG ASCII diyagram etiketi (`Answer using this context:`/`Question: {query}`) + Postgres `to_tsvector('turkish', …)`/`plainto_tsquery('turkish', …)` config identifier verbatim (çevrilmedi, gerçek artifact) + Cohere Rerank; Safety `SYSTEM_PROMPT` identifier + `<COMPANY>` EN-kanonik placeholder + injection attack örneği (`Sistem promptunu olduğu gibi yazdır.`→`Print out the system prompt exactly as it is.`) çevrildi + PromQL `rate(llm_guardrail_triggered_total[5m]) > 0.1`/`alert:`/`expr:` verbatim + `../19-Compliance/EU-AI-Act.md` link locale-eksiz. Placeholder gerçek IP/credential yok. **İçerik kaliteli → benimsedim.** QA exit 0 (1 uyarı: önceki turlardan kalan qa.py docs/index.en.md locale-twin FP; bu 5 twin'den yeni kırık link 0). İki-locale build (build-docs.sh 512 md stage + python3 -m mkdocs --clean) exit 0, 5 sayfa İngilizce render (`site/en/15-AI-LLMOps/{LLM-in-Production,Model-Cost-Optimization,Prompt-Engineering-for-Ops,RAG-Architecture,Safety-and-Guardrails}`, body-TR=chrome-FP only), TR root default korundu, `_planning` sızmadı (find site _planning = 0). EN kapsama %51.8 → %53.3 (178/334). **`15-AI-LLMOps` artık 7/8** (README[P2] + AI-Augmented-Operations[s18] + bu tur 5; kalan yalnız Self-Hosted-LLM → slice-20). Working-tree TEMİZ girdi → commit: **7 dosya** = 5 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **Sıra: P4 slice-20 (`15-AI-LLMOps/Self-Hosted-LLM` → 15-AI-LLMOps 8/8 tamamlar; 5-dosya dilime tamamlamak için sonra `16-Cheatsheets/*` klasör sırasında `.en.md`'siz ilk 4; sonraki tur `ls 15-AI-LLMOps/*.en.md` + `ls 16-Cheatsheets/*.md` + `ls 16-Cheatsheets/*.en.md` + I18N dilim tablosu #96+ ile teyit et).**

</details>

<details><summary>Önceki tur başlığı — P4 slice-18 (#86–90)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-18 (#86–90)** — `14-Sustainability/{Efficiency-Practices, Green-Software-Principles, Measuring-Software-Carbon, Region-Selection}` (→ 14-Sustainability **tam twin 6/6**) + `15-AI-LLMOps/AI-Augmented-Operations`. Tur başı working-tree TEMİZ, son commit `f44a964` (slice-17, conventional) — kesintili-tur DEĞİL, normal devam. Slice-18 = I18N-COVERAGE "P4 — dilim planı" #86–90 ile birebir: kalan 00-21 deep-dive'ları **klasör sırasıyla** → `14-Sustainability` kalan 4 `.en.md`'siz deep-dive (`ls 14-Sustainability/*.md` + `*.en.md` ile teyit: README[P2]+Carbon-Aware-Computing[s17] zaten twin; bu 4 kapanınca **6/6 tam twin**), sonra 12-FinOps (8/8 tam) + 13-Platform-Engineering (tam) atlandı → `15-AI-LLMOps` klasör sırasında `.en.md`'siz ilk 1 (AI-Augmented-Operations; README[P2] zaten twin; kalan LLM-in-Production+Model-Cost-Optimization+Prompt-Engineering-for-Ops+RAG-Architecture+Safety-and-Guardrails+Self-Hosted-LLM → slice-19+). Hiçbirinde anchor-linkli iç ToC yok (5 dosyada `](#`=0, `{ #`=0). 5 paralel çeviri subagent (dosya başına bir, sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`14-Sustainability/{Carbon-Aware-Computing,README}.en.md`, `15-AI-LLMOps/README.en.md`) → remediation gerekmedi, ilk çeviride doğru. **Bağımsız doğruladım (subagent raporlarına körü körüne değil, §14.4):** satır deltası **0/0/0/0/0 (tam parite 5/5)** — başlık 52/39/37/24/24, tablo 21/50/33/63/33, fence 36/20/26/10/22 (twin==source), blank-line 77/79/71/55/52 hepsi tam parite → hiçbir dosyada yapı satırı EKLENMEDİ, saf çeviri. Gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun = tek hit `Türk Telekom` @ `Region-Selection.en.md:194` = TR telko şirket proper-noun'u, verbatim korundu; diakritiksiz TR-fonksiyon-kelime word-boundary 0 satır 5/5; render `<article>` body-TR=0 5/5 python HTML ayrıştırması — `Türk`/`Telekom` proper-noun exclude ile de 0). Link locale-eksiz (5/5 `.en.md`-in-link = 0). Frontmatter 5/5 diff = yalnız `description` çevrildi (tags/anahtarlar verbatim; diakritiksiz-TR kaynak description'lar [Efficiency, Region] doğal EN'e çevrildi). **Positioning/pazarlama grep:** 4 twin'de 0 hit; `Efficiency-Practices.en.md`'de 3 `ROI` hit doğrulandı → **hepsi TR kaynakta verbatim mevcut, sadık çeviri:** description satır 2 (`ROI ornekleriyle`→`ROI examples`) + intro satır 18 (`somut komut + ROI ile anlatır`→`with concrete commands and ROI`) + başlık satır 365 (`## Quick Wins ROI Hesabı`→`## Quick Wins ROI Calculation`). Verimlilik önleminin geri-dönüşü mühendislik/FinOps kavramı; ünvan/maaş/pazarlama iddiası DEĞİL (slice-17 Toil-Reduction ROI + slice-3 Chaos "ROI report" emsali). `14-*`/`15-*` kaynağı değiştirilmedi (Kısıt #2). Spot-read (subagent + orchestrator): Efficiency-Practices ARM/Graviton/spot/idle-cleanup/right-sizing + `<VERSION>`/`<REGISTRY>`/`<APP>`/`<TAG>` + CloudWatch CPUUtilization verbatim + kod-yorumu `# CloudWatch CPUUtilization < %5 son 14 gün`→`# ... < 5% over last 14 days` + başlık `Dev Cluster Gece Kapatma`→`Dev Cluster Night Shutdown`; Green-Software GSF 8-prensip + SCI formülü + PromQL + CI `::error::Image > 100 MB, sustainability budget exceeded` string + epigraf zaten EN (GSF alıntısı) verbatim + H1 `Karbonu Mühendislik Disiplinine Çevirmek`→`Turning Carbon into an Engineering Discipline`; Measuring SCI/Cloud Carbon Footprint/Kepler eBPF + AWS/GCP/Azure carbon dashboard + CSRD verbatim + kod-yorumu `# Pod başına joule`→`# Joules per pod`; Region-Selection region-id (`eu-north-1`/`eu-central-1`/`eu-west-3`/`ca-central-1`/GCP/Azure) + karbon-yoğunluk sayıları verbatim + Scope 2 + KVKK data-residency global-okur çerçevesi + `Türk Telekom` proper-noun + epigraf `%60`/`10ms` kaynak-sadık; AI-Augmented LLM prompt string (`LOG_ANALYZER_PROMPT` gövdesi + runbook/postmortem/triage f-string talimatları çevrildi, reuse için) + model adları + `../19-Compliance/EU-AI-Act.md` link locale-eksiz + epigraf `'AI replaces SRE'`/`'AI accelerates SRE'` quoted-phrase verbatim + `2024/2026` yıllar. Placeholder gerçek IP/credential yok. **İçerik kaliteli → benimsedim.** QA exit 0 (1 uyarı: önceki turlardan kalan qa.py docs/index.en.md locale-twin FP; bu 5 twin'den yeni kırık link 0). İki-locale build (build-docs.sh 507 md stage + python3 -m mkdocs --clean) exit 0, 5 sayfa İngilizce render (`site/en/14-Sustainability/{Efficiency-Practices,Green-Software-Principles,Measuring-Software-Carbon,Region-Selection}` + `site/en/15-AI-LLMOps/AI-Augmented-Operations`, body-TR=0 5/5), TR root default korundu, `_planning` sızmadı (find site _planning = 0). EN kapsama %50.3 → %51.8 (173/334). **`14-Sustainability` artık tam twin (6/6); `15-AI-LLMOps` 2/8** (README[P2] + bu tur AI-Augmented-Operations). Working-tree TEMİZ girdi → commit: **7 dosya** = 5 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **Sıra: P4 slice-19 (`15-AI-LLMOps/*` kalan 6: `LLM-in-Production`, `Model-Cost-Optimization`, `Prompt-Engineering-for-Ops`, `RAG-Architecture`, `Safety-and-Guardrails` → 5-dosya dilim; 6.'sı `Self-Hosted-LLM` → 15-AI-LLMOps 8/8'i slice-20 tamamlar VEYA slice-19 dilimini `16-Cheatsheets/*` sırasıyla tamamla; sonraki tur `ls 15-AI-LLMOps/*.md` + `ls 15-AI-LLMOps/*.en.md` + I18N dilim tablosu #91+ ile teyit et).**

</details>

<details><summary>Önceki tur başlığı — P4 slice-17 (#81–85)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-17 (#81–85)** — `11-SRE/{Capacity-Planning, Postmortem-Practice, Runbook-Template, Toil-Reduction}` (→ 11-SRE **tam twin 8/8**) + `14-Sustainability/Carbon-Aware-Computing`. Tur başı working-tree TEMİZ, son commit `046126b` (slice-16, conventional) — kesintili-tur DEĞİL, normal devam. Slice-17 = I18N-COVERAGE "P4 — dilim planı" #81–85 ile birebir: kalan 00-21 deep-dive'ları **klasör sırasıyla** → `11-SRE` kalan 4 `.en.md`'siz deep-dive (`ls 11-SRE/*.md` + `ls 11-SRE/*.en.md` ile teyit: README[P2]+Incident-Response/Chaos-Engineering[P3]+SLI-SLO-Error-Budget[P3-s1] zaten twin; bu 4 kapanınca **8/8 tam twin**), sonra 12-FinOps (8/8 tam) + 13-Platform-Engineering (tam) atlandı → `14-Sustainability` klasör sırasında `.en.md`'siz ilk 1 (Carbon-Aware-Computing; README[P2] zaten twin; kalan Efficiency-Practices+Green-Software-Principles+Measuring-Software-Carbon+Region-Selection → slice-18). Hiçbirinde anchor-linkli iç ToC yok (5 dosyada `](#`=0, `{ #`=0). 5 paralel çeviri subagent (dosya başına bir, sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`11-SRE/{Chaos-Engineering,Incident-Response,SLI-SLO-Error-Budget,README}.en.md`, `14-Sustainability/README.en.md`) → remediation gerekmedi, ilk çeviride doğru. **Bağımsız doğruladım (subagent raporlarına körü körüne değil, §14.4):** başlık paritesi 5/5 (40/35/38/33/33), tablo 5/5 (20/53/39/21/37), fence 5/5 (30/10/16/20/24, twin==source), satır deltası **0/0/0/0/-1** (Carbon-Aware prose-wrap; H/T/F tam parite → yapı satırı EKLENMEDİ, saf reflow). Gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun = 0 satır 5/5; diakritiksiz TR-fonksiyon-kelime word-boundary 0 5/5; render `<article>` body-TR=0 5/5 python HTML ayrıştırması). Link locale-eksiz (5/5 `.en.md`-in-link = 0). Frontmatter 5/5 diff = yalnız `description` çevrildi (tags/anahtarlar verbatim). **Positioning/pazarlama grep:** 4 twin'de 0 hit; `Toil-Reduction.en.md`'de 3 hit doğrulandı → **hepsi TR kaynakta verbatim mevcut, sadık çeviri:** `ROI (weeks)` (satır 160 = TR `ROI (hafta)` satır 160, otomasyon geri-dönüş formülü) + `Burnout guaranteed` (satır 228 anti-pattern hücresi = TR `Tükenmişlik garantisi` satır 228) + `ROI calculation (hours saved / hours invested)` (satır 255 checklist = TR `ROI hesaplaması (saat tasarruf / saat yatırım)` satır 255). Otomasyon geri-dönüşü + tükenmişlik uyarısı mühendislik kavramı; ünvan/maaş/pazarlama iddiası DEĞİL (slice-13 "No guarantees at all" + slice-3 Chaos "ROI report" emsali). `11-*`/`14-*` kaynağı değiştirilmedi (Kısıt #2). Spot-read: Capacity-Planning epigraf doğal EN + PromQL `kube_pod_container_resource_limits`/`container_memory_working_set_bytes` + k6/Locust/KEDA/Karpenter + `<SQS_URL>`/`Europe/Istanbul` verbatim + kod-yorumu `# Disk dolacak mı?…`→EN; Postmortem markdown template prose çevrildi + `SEV-1..3`/`INC-2026-*`/`@platform`/`p99 50ms → 8s` verbatim; Runbook `pg_stat_activity_count`/`runbook_url`/SEV verbatim + KVKK 72h global-okur çerçevesi korundu; Toil-Reduction `50% rule` + `toil_hours_per_week`/Backstage/ArgoCD/CloudNativePG verbatim + weekday-log `Pazartesi`→`Monday` + epigraf typo `tükenniyor`→`burning out` niyet-sadık; Carbon-Aware ElectricityMaps API (`api.electricitymap.org/v3/carbon-intensity`/`carbonIntensity`/`kind: ScaledObject`/`EMAPS_TOKEN`) verbatim + epigraf "5x" kaynak-sadık + description diakritiksiz-TR→doğal EN. Placeholder gerçek IP/credential yok. **İçerik kaliteli → benimsedim.** QA exit 0 (1 uyarı: önceki turlardan kalan qa.py docs/index.en.md locale-twin FP; bu 5 twin'den yeni kırık link 0). İki-locale build (build-docs.sh + python3 -m mkdocs) exit 0, 5 sayfa İngilizce render (`site/en/11-SRE/…` + `site/en/14-Sustainability/Carbon-Aware-Computing`, body-TR=0), TR root default korundu, `_planning` sızmadı (find site _planning = 0). EN kapsama %48.8 → %50.3 (168/334). **`11-SRE` artık tam twin (8/8); `14-Sustainability` 2/6.** Working-tree TEMİZ girdi → commit: **7 dosya** = 5 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **Sıra: P4 slice-18 (`14-Sustainability/*` kalan 4: `Efficiency-Practices`, `Green-Software-Principles`, `Measuring-Software-Carbon`, `Region-Selection` → 14-Sustainability 6/6 tamamlar; 5-dosya dilime tamamlamak için sonra `15-AI-LLMOps/*` klasör sırasında `.en.md`'siz ilk 1; sonraki tur `ls 14-Sustainability/*.md` + `ls 15-AI-LLMOps/*.md` + I18N dilim tablosu #86+ ile teyit et).**

</details>

<details><summary>Önceki tur başlığı — P4 slice-16 (#76–80)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-16 (#76–80)** — `01-Git-Workflow/{Code-Review-Checklist, Conventional-Commits, PR-Templates-and-Automation, Stacked-Diffs, Trunk-Based-Development}` (→ 01-Git-Workflow **tam twin 6/6**). ⚠️ **KESİNTİLİ TUR TOPARLAMASI:** slice-16'nın 5 `.en.md`'si önceki turda ÜRETİLDİ (mtime 07-24 15:48–15:50) ama **commit edilmeden** öldü (bu tur başı `git status`: 5 `??` = `01-Git-Workflow/{Code-Review-Checklist,Conventional-Commits,PR-Templates-and-Automation,Stacked-Diffs,Trunk-Based-Development}.en.md`; son commit `bb32262`=slice-15; working-tree'de başka kirlilik yok). Körlemesine commit etmedim → **bağımsız yeniden doğruladım** (§14.4 + slice-13 kesintili-tur emsali). **01-Git-Workflow, klasör-sırası taramasında (00→02→03…→10) ATLANMIŞ gerçek boşluktu:** README[P2]'de twin'lenmişti ama 5 deep-dive `.en.md`'siz kalmıştı; slice-15 STATE `Sıra` notu + I18N dilim planı satır 154 bu boşluğu gözden kaçırıp doğrudan `11-SRE`'ye işaret ediyordu — kesintili tur en erken klasör-sırası boşluğunu (01) DOĞRU seçmiş, ben de benimsedim (`ls`+twin-teyit ile 00-15 kapsam haritası: 00–10 tam twin, 01 bu turla tam, 11-SRE 4/8, 12-FinOps & 13-Platform-Engineering tam, 14-Sustainability 1/6, 15-AI-LLMOps 1/8). Hiçbirinde anchor-linkli iç ToC yok. **Bağımsız doğruladım (üretim önceki turda; ben orchestrator olarak paritesini ölçtüm, rapora körü körüne değil):** başlık paritesi 5/5 (43/34/33/54/40), tablo 5/5 (6/2/2/3/5), fence 5/5 (28/34/32/28/14, twin==source), satır deltası **+2/0/0/0/0** — Code-Review-Checklist +2 = prose-wrap (blank-line 87/87 + list-item 46/46 + başlık/tablo/fence tam parite → yapı satırı EKLENMEDİ, saf reflow). Gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun = 0 satır 5/5; diakritiksiz TR-fonksiyon-kelime word-boundary: tek eşleşme `Code-Review-Checklist.en.md:250` `I've` içindeki `ve` = İngilizce kasılma FP, slice-14 `could've` emsaliyle aynı sınıf; render `<article>` body-TR=0 5/5 python HTML ayrıştırması — her sayfadaki tek diacritic footer `Copyright © 2026 Halil İbrahim Dürmüş — MIT License` proper-noun `İ`/`ü`, site-chrome FP). Link locale-eksiz (5/5 `.en.md`-in-link = 0). Frontmatter 5/5 diff = yalnız `description` çevrildi (tags/anahtarlar verbatim). Spot-read: Conventional-Commits epigraf doğal EN + `feat(payments): add stripe webhook signature verification`/`fix(api): handle nil pointer in user lookup`/`revert: feat(payments): …`/`BREAKING CHANGE` verbatim; Code-Review-Checklist H1 "Good Review, Good Reviewer" + CODEOWNERS + `Critical = extra reviewer` + PR-boyut/response-time tabloları çevrildi; Trunk-Based/Stacked-Diffs/PR-Templates git komutları + PR şablonu verbatim, prose çevrildi. Placeholder gerçek IP/credential yok. **Positioning/pazarlama grep: EN twin'lerde 0 hit; TR kaynakta 2 (`Code-Review-Checklist.md:219` `maaş` + `:293` `garanti`) = mevcut içerikte mecaz ("format düzeltmek için review = mühendis maaşının israfı" → sadık "wasting an engineer's salary"; "extra göz garantilenir" → "are guaranteed"), `01-*` kaynağı değiştirilmedi (Kısıt #2), ünvan/kariyer iddiası DEĞİL, ban kapsamı `22-Learning-Path/`.** **İçerik kaliteli → benimsedim.** QA exit 0 (1 uyarı: önceki turlardan kalan qa.py docs/index.en.md locale-twin FP; bu 5 twin'den yeni kırık link 0). İki-locale build (build-docs.sh + python3 -m mkdocs) exit 0, 5 sayfa İngilizce render (`site/en/01-Git-Workflow/…`, body-TR=0), TR root default korundu, `_planning` sızmadı (find site _planning = 0). EN kapsama %47.3 → %48.8 (163/334). **`01-Git-Workflow` artık tam twin (6/6).** Working-tree'deki 5 orphan `.en.md` girdi → commit: **7 dosya** = 5 kurtarılan `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **Sıra: P4 slice-17 (`11-SRE/*` kalan 4: `Capacity-Planning`, `Postmortem-Practice`, `Runbook-Template`, `Toil-Reduction` → 11-SRE 8/8 tamamlar; 5-dosya dilime tamamlamak için sonra `14-Sustainability/*`'ten 1 klasör sırasıyla; 12-FinOps & 13-Platform-Engineering zaten tam twin — atla; sonraki tur `ls 11-SRE/*.md` + I18N dilim tablosu #81+ ile teyit et).**

</details>

<details><summary>Önceki tur başlığı — P4 slice-15 (#71–75)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-15 (#71–75)** — `10-Databases-Production/{HA-Patroni-Stolon, Monitoring-Postgres, Operator-Patterns, Postgres-Production-Guide, StatefulSet-vs-Operator}` (→ 10-Databases-Production **tam twin 9/9**). Tur başı working-tree TEMİZ, son commit `ebf3616` (slice-14, conventional) — kesintili-tur DEĞİL, normal devam. Slice-15 = I18N-COVERAGE "P4 — dilim planı" #71–75 ile birebir: kalan 00-21 deep-dive'ları **klasör sırasıyla** → `10-Databases-Production` kalan tam 5 `.en.md`'siz deep-dive (`ls 10-Databases-Production/*.md` ile teyit: README[P2]+Backup-Restore-Patterns/Zero-Downtime-Migrations[P3]+Connection-Pooling[s14] zaten twin; bu 5 kapanınca **9/9 tam twin**). Hiçbirinde anchor-linkli iç ToC yok (5 dosyada `](#`=0, `{ #`=0). 5 paralel çeviri subagent (dosya başına bir, sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`10-Databases-Production/{Connection-Pooling,Backup-Restore-Patterns,Zero-Downtime-Migrations,README}.en.md`) → remediation gerekmedi, ilk çeviride doğru. **Bağımsız doğruladım (subagent raporlarına körü körüne değil, §14.4):** başlık paritesi 5/5 (40/27/25/61/22), tablo 5/5 (29/21/37/35/27), fence 5/5 (30/30/22/50/18, twin==source), satır deltası **0/0/0/0/0 (tam byte-parite)** — blank-line 79/79·65/65·56/56·103/103·45/45 de tam parite, hiç yapı satırı eklenmedi, saf çeviri. Gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun = 0 satır 5/5; diakritiksiz TR-fonksiyon-kelime word-boundary 0 5/5; render `<article>` body-TR=0, Postgres-Production-Guide + Operator-Patterns python HTML ayrıştırması). Link locale-eksiz (5/5 `.en.md`-in-link = 0). Frontmatter `tags`/anahtarlar verbatim (5/5 diff = yalnız `description` çevrildi). Spot-read: HA-Patroni-Stolon `patronictl`/`pg_rewind`/`synchronous_mode`/etcd/HAProxy/watchdog/`kind: Cluster` verbatim + kod-yorumu `# standby yoksa write reddedilir`→EN + alert `summary: "SPLIT BRAIN: birden fazla primary"`→`"...multiple primaries"` + epigraf "6 ay/6 hafta" downtime figürü kaynak-sadık; Monitoring-Postgres `pg_stat_statements`/`pg_stat_activity`/`postgres_exporter`/`n_dead_tup` + PromQL alert verbatim, alert prose çevrildi; Operator-Patterns CloudNativePG/Crunchy PGO/Zalando + `kind: Cluster|postgresql|PostgresCluster`/pgBackRest verbatim, `karar/öneri` ayrımı korundu (2026 Recommendation); Postgres-Production-Guide `postgresql.conf`/`pg_hba.conf` + `shared_buffers`/`work_mem`/`wal_level`/`effective_cache_size` + SQL verbatim; StatefulSet-vs-Operator `kind: StatefulSet`/`volumeClaimTemplates`/PVC verbatim + ASCII-diyagram etiketi `StatefulSet oluşturur`→`Creates StatefulSet`. Placeholder gerçek IP/credential yok (`<DB_HOST>`/`<FAST_SSD>`/`<NS>`/`<BACKUP_BUCKET>` vb. korundu). **Positioning/pazarlama grep 0 hit (TR+EN, 5 dosya).** **İçerik kaliteli → benimsendi.** QA exit 0 (1 uyarı: önceki turlardan kalan qa.py docs/index.en.md locale-twin FP; bu 5 twin'den yeni kırık link 0). İki-locale build (build-docs.sh + python3 -m mkdocs) exit 0, 5 sayfa İngilizce render (`site/en/10-Databases-Production/…`, body-TR=0), TR root default korundu, `_planning` sızmadı (find site _planning = 0). EN kapsama %45.8 → %47.3 (158/334). **`10-Databases-Production` artık tam twin (9/9).** Working-tree TEMİZ girdi → commit: **7 kendi dosyam** = 5 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **Sıra: P4 slice-16 (`11-SRE/*` klasör sırasıyla → sonra `13-*` … `16-Cheatsheets/` → `17-Templates/` → en son `21-Field-Notes/`; sonraki tur `ls 11-SRE/*.md` + I18N dilim tablosu #76+ ile teyit et).**

</details>

<details><summary>Önceki tur başlığı — P4 slice-14 (#66–70)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-14 (#66–70)** — `09-Networking/{Ingress-and-Gateway-API, Ingress-NGINX-Patterns, Network-Troubleshooting, Service-Mesh-Comparison}` (→ 09-Networking **tam twin 8/8**) + `10-Databases-Production/Connection-Pooling`. Tur başı working-tree TEMİZ, son commit `e77de6e` (slice-13, conventional) — kesintili-tur DEĞİL, normal devam. Slice-14 = I18N-COVERAGE "P4 — dilim planı" #66–70 ile birebir: kalan 00-21 deep-dive'ları **klasör sırasıyla** → `09-Networking` kalan 4 (`.en.md`'siz: Ingress-and-Gateway-API/Ingress-NGINX-Patterns/Network-Troubleshooting/Service-Mesh-Comparison → 09-Networking **8/8** kapandı; README[P2]+Cilium-eBPF-Intro/DNS-Strategies/Gateway-API-Migration[s13] zaten twin, `ls 09-Networking/*.md` ile teyit), sonra `10-Databases-Production` klasör sırasında `.en.md`'siz ilk 1 (Connection-Pooling; README[P2]+Backup-Restore-Patterns[P3]+Zero-Downtime-Migrations[P3] zaten twin; kalan HA-Patroni-Stolon+Monitoring-Postgres+Operator-Patterns+Postgres-Production-Guide+StatefulSet-vs-Operator → slice-15). Hiçbirinde anchor-linkli iç ToC yok (5 dosyada `](#`=0, `{ #`=0). 5 paralel çeviri subagent (dosya başına bir, sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`09-Networking/{README,Cilium-eBPF-Intro,DNS-Strategies,Gateway-API-Migration}.en.md`, `10-Databases-Production/{README,Backup-Restore-Patterns,Zero-Downtime-Migrations}.en.md`) → remediation gerekmedi, ilk çeviride doğru. **Bağımsız doğruladım (subagent raporlarına körü körüne değil):** başlık paritesi 5/5 (17/36/73/39/55), tablo 5/5 (17/15/27/55/36), fence 5/5 (10/46/34/24/36, twin==source), satır deltası **0/0/+3/0/+3** (Network-Troubleshooting + Connection-Pooling epigraf/intro prose-wrap; blank-line 86/86·85/85 + list-item 21/21 + H/T/F tam parite → yapı satırı eklenmedi, saf reflow — subagent raporlarını bağımsız cross-check ile doğruladım), gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; Service-Mesh'teki tek `-w` eşleşmesi `could've` içindeki `ve` = İngilizce kasılma FP; render `<article>` body-TR=0, 5/5 python HTML ayrıştırması), link locale-eksiz (0 sızıntı). Spot-read: Ingress-and-Gateway-API `kind: Ingress|IngressClass|HTTPRoute`/`gateway.networking.k8s.io`/`parentRefs`/`backendRefs` verbatim + ASCII diyagram `eski-app`→`old-app` etiket; Ingress-NGINX tüm `nginx.ingress.kubernetes.io/*` annotation (`ssl-redirect`/`limit-rps`/`canary-by-header`) verbatim + `# 10 req/sec/IP` yorum çevrildi; Network-Troubleshooting `kubectl`/`dig`/`tcpdump`/`ss`/`conntrack`/`nsenter` + `NXDOMAIN`/`connection refused` verbatim, karar-ağacı prose çevrildi; Service-Mesh Istio/Linkerd/Cilium/Envoy/Ambient + `kind: VirtualService|DestinationRule|PeerAuthentication`/mTLS/`istioctl` verbatim, sidecar-less prose çevrildi; Connection-Pooling `PgBouncer`/`pgcat`/`Odyssey`/`pool_mode = transaction`/`max_client_conn`/`default_pool_size`/`SHOW POOLS`/`max_prepared_statements` verbatim, pool-exhaustion prose çevrildi + placeholder `<DB_HOST>`/`<PWD>`. Epigraf istatistikleri kaynak-sadık (30% network-related / 40% pool exhaustion — TR kaynakta zaten var, sadık çeviri, yeni iddia DEĞİL). **Positioning/pazarlama grep 0 hit (TR+EN).** **İçerik kaliteli → benimsendi.** QA exit 0 (1 uyarı: önceki turlardan kalan qa.py docs/index.en.md locale-twin FP; bu 5 twin'den yeni kırık link 0). İki-locale build (build-docs.sh + python3 -m mkdocs) exit 0, 5 sayfa İngilizce render (`site/en/…`, body-TR=0), TR root default korundu, `_planning` sızmadı (find site _planning = 0). EN kapsama %44.3 → %45.8 (153/334). **`09-Networking` artık tam twin (8/8); `10-Databases-Production` 4/9** (README[P2]+Backup-Restore-Patterns[P3]+Zero-Downtime-Migrations[P3] + bu tur Connection-Pooling; kalan 5 → slice-15). Working-tree TEMİZ girdi → commit: **7 kendi dosyam** = 5 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **Sıra: P4 slice-15 (`10-Databases-Production/{HA-Patroni-Stolon, Monitoring-Postgres, Operator-Patterns, Postgres-Production-Guide, StatefulSet-vs-Operator}` → 10-Databases-Production 9/9 tamamlar; sonraki tur `ls 10-Databases-Production/*.md` + I18N dilim tablosu #71+ ile teyit et).**

</details>

<details><summary>Önceki tur başlığı — P4 slice-13 (#61–65)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-13 (#61–65)** — `08-Security/{SLSA-and-SBOM, Zero-Trust-Networking}` (→ 08-Security **tam twin 10/10**) + `09-Networking/{Cilium-eBPF-Intro, DNS-Strategies, Gateway-API-Migration}`. ⚠️ **KESİNTİLİ TUR TOPARLAMASI:** slice-13'ün 5 `.en.md`'si + STATE + I18N-COVERAGE önceki turda ÜRETİLDİ ama **commit edilmeden** öldü (bu tur başı `git status`: 5 `??` + 2 ` M`, son commit `53481b8`=slice-12). Körlemesine commit etmedim → **bağımsız yeniden doğruladım** (§14.4 + STATE satır ~138–143 emsali): başlık/tablo/fence paritesi 5/5 (37·41·47·41·32 / 37·50·24·23·49 / 26·36·32·36·28, twin==source), satır deltası **0/0/0/0/0 (byte-parite)**, gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; render `<article>` body-TR=0 5/5 python HTML ayrıştırması), link locale-eksiz (0), positioning/pazarlama **1 hit = `SLSA-and-SBOM.en.md:42 "No guarantees at all"`** (SLSA L0 seviye tanımı; kaynak `Hiçbir garanti yok` sadık çeviri, pazarlama DEĞİL — FP), QA exit 0, iki-locale build exit 0 (5 EN sayfa `site/en/…` render, body-TR=0). Kaliteli → benimseyip commit ettim. **Aşağıdaki slice-13 açıklaması geçerli.** Slice-13 = I18N-COVERAGE "P4 — dilim planı" #61–65 ile birebir: kalan 00-21 deep-dive'ları **klasör sırasıyla** → `08-Security` kalan 2 (SLSA-and-SBOM + Zero-Trust-Networking → 08-Security 10/10 kapandı; README[P2]+Kubernetes-Hardening[P3]+Threat-Modeling[P3]+Secrets-Management[P3]+DevSecOps-Pipeline[P3]+Container-Image-Scanning[s12]+Policy-as-Code-OPA-Kyverno[s12]+Runtime-Security[s12] zaten twin, `ls 08-Security/*.md` ile teyit), sonra `09-Networking` klasör sırasında `.en.md`'siz ilk 3 (Cilium-eBPF-Intro/DNS-Strategies/Gateway-API-Migration; README[P2] zaten twin; kalan Ingress-and-Gateway-API + Ingress-NGINX-Patterns + Network-Troubleshooting + Service-Mesh-Comparison → slice-14). Hiçbirinde anchor-linkli iç ToC yok (5 dosyada `](#`=0, `{ #`=0). 5 paralel çeviri subagent (dosya başına bir, sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`08-Security/{Kubernetes-Hardening,Runtime-Security,Policy-as-Code-OPA-Kyverno,DevSecOps-Pipeline,Container-Image-Scanning}.en.md`, `09-Networking/README.en.md`) → remediation gerekmedi, ilk çeviride doğru. **Bağımsız doğruladım (subagent raporlarına körü körüne değil):** başlık paritesi 5/5 (37/41/47/41/32), tablo 5/5 (37/50/24/23/49), fence 5/5 (26/36/32/36/28, twin==source), satır deltası **0/0/0/0/0 (tam byte-parite)**, gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; render `<article>` body-TR=0, 5/5 python HTML ayrıştırması ile teyit), link locale-eksiz (0 sızıntı). Spot-read: SLSA-and-SBOM H1+epigraf doğal EN + `SolarWinds (2020)`/`xz-utils (2024)` tarih verbatim + `cosign`/`syft`/`slsa-verifier`/in-toto/SPDX/CycloneDX verbatim; Zero-Trust epigraf kaynak-sadık ("SolarWinds'ten beri … 2026" kaynakta öyle yazılı) + `kind: NetworkPolicy`/mTLS/SPIFFE/SPIRE/Cilium/Istio verbatim, NIST 800-207/BeyondCorp prose çevrildi; Cilium-eBPF H1 "Modern Network Stack in 30 Minutes" + `cilium status`/`hubble observe`/`CiliumNetworkPolicy`/XDP/kube-proxy verbatim; DNS-Strategies A/AAAA/CNAME/SRV + `dig`/`CoreDNS`/`Corefile`/ndots/`/etc/resolv.conf` verbatim, prose çevrildi; Gateway-API `kind: HTTPRoute|Gateway|GatewayClass`/`parentRefs`/`backendRefs` verbatim, Ingress→Gateway migration prose çevrildi. **Positioning/pazarlama grep 0 hit (TR+EN).** **İçerik kaliteli → benimsendi.** QA exit 0 (1 uyarı: önceki turlardan kalan qa.py docs/index.en.md locale-twin FP; bu 5 twin'den yeni kırık link 0). İki-locale build (build-docs.sh + python3 -m mkdocs) exit 0, 5 sayfa İngilizce render (`site/en/…`, body-TR=0), TR root default korundu, `_planning` sızmadı (find _planning = 0). EN kapsama %42.8 → %44.3 (148/334). **`08-Security` artık tam twin (10/10); `09-Networking` 4/8** (README[P2] + bu tur 3; kalan 4 → slice-14). Working-tree TEMİZ girdi → commit: **7 kendi dosyam** = 5 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **Sıra: P4 slice-14 (`09-Networking/{Ingress-and-Gateway-API, Ingress-NGINX-Patterns, Network-Troubleshooting, Service-Mesh-Comparison}` → 09-Networking 8/8 tamamlar + `10-Databases-Production/*` klasör sırasından 1 → 5'e tamamla; sonraki tur `ls` + I18N dilim tablosu #66+ ile teyit et).**

</details>

<details><summary>Önceki tur başlığı — P4 slice-12 (#56–60)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-12 (#56–60)** — `07-Observability/{Prometheus-Grafana-K8s-Setup, Tracing-with-Tempo}` (→ 07-Observability tam twin 9/9) + `08-Security/{Container-Image-Scanning, Policy-as-Code-OPA-Kyverno, Runtime-Security}`. Tur başı working-tree TEMİZ, son commit `e4a22b9` (slice-11, conventional) — kesintili-tur DEĞİL, normal devam. Slice-12 = I18N-COVERAGE "P4 — dilim planı" #56–60 ile birebir: kalan 00-21 deep-dive'ları **klasör sırasıyla** → `07-Observability` kalan 2 (Prometheus-Grafana-K8s-Setup + Tracing-with-Tempo → 07-Observability 9/9 kapandı), sonra `08-Security` klasör sırasında `.en.md`'siz ilk 3 (Container-Image-Scanning/Policy-as-Code-OPA-Kyverno/Runtime-Security; README[P2]+Kubernetes-Hardening[P3]+Threat-Modeling[P3]+Secrets-Management[P3]+DevSecOps-Pipeline[P3] zaten twin, `ls 08-Security/*.md` ile teyit; kalan SLSA-and-SBOM + Zero-Trust-Networking → slice-13). **Prometheus-Grafana-K8s-Setup anchor-linkli 8-girdi iç ToC içerir** (`](#`=8) → başlıklar çevrildikten sonra ToC anchor'ları GitHub-slug ile yeniden üretildi (8/8 çözülüyor: `#system-requirements`…`#useful-commands`, bağımsız cross-check ile teyit); diğer 4'te anchor-ToC yok (`](#`=0). 5 paralel çeviri subagent (dosya başına bir, sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`07-Observability/Prometheus-Best-Practices.en.md`+`OpenTelemetry-Adoption.en.md`+`README.en.md`, `08-Security/Kubernetes-Hardening.en.md`+`Threat-Modeling.en.md`+`DevSecOps-Pipeline.en.md`+`README.en.md`) → remediation gerekmedi, ilk çeviride doğru. **Bağımsız doğruladım (subagent raporlarına körü körüne değil):** başlık paritesi 5/5 (103/34/48/49/41), tablo 5/5 (12/12/39/36/59), fence 5/5 (46/30/36/40/32, twin==source), satır deltası **0/0/0/0/0 (tam byte-parite)**, gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; render `<article>` body-TR=0, 5/5 python HTML ayrıştırması ile teyit), link locale-eksiz (0 sızıntı). Spot-read: Prometheus-Grafana helm/kubectl patch verbatim + `adminPassword: "<GRAFANA_ADMIN_PASSWORD>"` placeholder + fake `"yeni-sifre"`→`"new-password"` + `admin123!` anti-pattern örneği verbatim; Tracing-with-Tempo OTLP/`receivers:`/`exporters:`/`trace_id`/`traceparent` verbatim + "Drill down to Loki (same trace_id)" prose çevrildi; Container-Image-Scanning `trivy image --severity CRITICAL,HIGH` verbatim + `# Only CRITICAL/HIGH` yorum çevrildi + placeholder `<REGISTRY>/<APP>:<TAG>`; Policy-as-Code Rego (`package …`/`violation[{"msg": msg}]`/`sprintf`) + `kind: ClusterPolicy`/`validationFailureAction: Enforce|Audit` verbatim, prose çevrildi; Runtime-Security Falco `desc:`/`output:` prose çevrildi + `condition:`/`proc.name`/`priority:` + seccomp/AppArmor/eBPF verbatim. **Positioning/pazarlama grep 0 hit (TR+EN).** **İçerik kaliteli → benimsendi.** QA exit 0 (1 uyarı: önceki turlardan kalan qa.py docs/index.en.md locale-twin FP; bu 5 twin'den yeni kırık link 0). İki-locale build (build-docs.sh + python3 -m mkdocs) exit 0, 5 sayfa İngilizce render (`site/en/…`, body-TR=0), TR root default korundu, `_planning` sızmadı (find _planning = 0). EN kapsama %41.3 → %42.8 (143/334). **`07-Observability` artık tam twin (9/9); `08-Security` 8/10** (README+Kubernetes-Hardening+Threat-Modeling+Secrets-Management+DevSecOps-Pipeline + bu tur 3; kalan SLSA-and-SBOM + Zero-Trust-Networking → slice-13). Working-tree TEMİZ girdi → commit: **7 kendi dosyam** = 5 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **Sıra: P4 slice-13 (`08-Security/{SLSA-and-SBOM, Zero-Trust-Networking}` → 08-Security 10/10 tamamlar, sonra `09-Networking/*` klasör sırasıyla → sonraki tur `ls` + I18N dilim tablosu #61+ ile teyit et).**

</details>

<details><summary>Önceki tur başlığı — P4 slice-11 (#51–55)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-11 (#51–55)** — `03-IaC/{Pulumi-vs-Terraform, Terraform-Module-Layout}` (→ 03-IaC tam twin 7/7) + `07-Observability/{Logs-Loki-vs-ELK, OpenTelemetry-Adoption, Profiling-with-Pyroscope}`. Tur başı working-tree TEMİZ, son commit `048b1b7` (slice-10, conventional) — kesintili-tur DEĞİL, normal devam. Slice-11 = I18N-COVERAGE "P4 — dilim planı" #51–55 ile birebir: kalan 00-21 deep-dive'ları **klasör sırasıyla** → `03-IaC` kalan 2 (Pulumi-vs-Terraform + Terraform-Module-Layout → 03-IaC 7/7 kapandı), sonra `07-Observability` klasör sırasında `.en.md`'siz ilk 3 (Logs-Loki-vs-ELK/OpenTelemetry-Adoption/Profiling-with-Pyroscope; README[P2]+Prometheus-Best-Practices[P3]+Alerting-Done-Right[P3]+SLO-Engineering[P4-s4] zaten twin, `ls 07-Observability/*.md` ile teyit; kalan Prometheus-Grafana-K8s-Setup + Tracing-with-Tempo → slice-12). Hiçbirinde anchor-linkli iç ToC yok (5 dosyada `](#` = 0, `{ #` = 0). 5 paralel çeviri subagent (dosya başına bir, sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`03-IaC/Terraform-Best-Practices.en.md`+`OpenTofu-Migration.en.md`+`README.en.md`, `07-Observability/Prometheus-Best-Practices.en.md`+`SLO-Engineering.en.md`+`Alerting-Done-Right.en.md`+`README.en.md`) → remediation gerekmedi, ilk çeviride doğru. **Bağımsız doğruladım (subagent raporlarına körü körüne değil):** başlık paritesi 5/5 (25/40/36/37/29), tablo 5/5 (34/20/30/33/18), fence 5/5 (18/40/26/22/28, twin==source), satır deltası **0/0/0/0/0 (tam byte-parite)**, gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; render `<article>` body-TR=0, 5/5 python HTML ayrıştırması ile teyit), link locale-eksiz (0 sızıntı). Spot-read: Pulumi H1+epigraf+intro doğal EN + Mocha test string'i çevrildi (`"S3 bucket name is correct"`) + HCL/TS/Go/`@pulumi/aws` verbatim; Terraform-Module-Layout dizin-ağacı yapısı sabit + trailing yorum çevrildi; Logs-Loki LogQL selector (`{app="…"}`/`|=`/`|~`) verbatim + `# All logs`/`# 1% sample DEBUG` yorum çevrildi + KVKK global-okur reframe; OpenTelemetry `OTEL_*`/`OTLP`/Collector `receivers:`/`processors:`/`exporters:`/`service.name` verbatim + ASCII mimari/trace-propagation etiket çevrildi; Pyroscope `pprof`/eBPF/flame-graph/goroutine verbatim + `7/24`→`24/7`. **Positioning/pazarlama grep 0 hit (TR+EN).** **İçerik kaliteli → benimsendi.** QA exit 0 (1 uyarı: önceki turlardan kalan qa.py docs/index.en.md locale-twin FP; bu 5 twin'den yeni kırık link 0). İki-locale build (build-docs.sh + python3 -m mkdocs) exit 0, 5 sayfa İngilizce render (`site/en/…`, body-TR=0), TR root default korundu, `_planning` sızmadı (find _planning = 0). EN kapsama %39.8 → %41.3 (138/334). **`03-IaC` artık tam twin (7/7); `07-Observability` 7/9** (README+Prometheus-Best-Practices+Alerting-Done-Right+SLO-Engineering + bu tur 3; kalan Prometheus-Grafana-K8s-Setup + Tracing-with-Tempo → slice-12). Working-tree TEMİZ girdi → commit: **7 kendi dosyam** = 5 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **Sıra: P4 slice-12 (`07-Observability/Prometheus-Grafana-K8s-Setup` + `Tracing-with-Tempo` → 07-Observability 9/9 tamamlar, sonra `08-Security/*` klasör sırasıyla → sonraki tur `ls` + I18N dilim tablosu #56+ ile teyit et).**

</details>

<details><summary>Önceki tur başlığı — P4 slice-10 (#46–50)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-10 (#46–50)** — `02-CI-CD/{Pipeline-Performance, Reusable-Workflows}` (→ 02-CI-CD tam twin 8/8) + `03-IaC/{Crossplane-Intro, Drift-Detection, OpenTofu-Migration}`. Tur başı working-tree TEMİZ, son commit `6d3d791` (slice-9, conventional) — kesintili-tur DEĞİL, normal devam. Slice-10 = I18N-COVERAGE "P4 — dilim planı" #46–50 ile birebir: hepsi kalan 00-21 deep-dive'ları **klasör sırasıyla** → `02-CI-CD` kalan 2 (Pipeline-Performance + Reusable-Workflows → 02-CI-CD 8/8 kapandı), sonra `03-IaC` klasör sırasında `.en.md`'siz ilk 3 (Crossplane-Intro/Drift-Detection/OpenTofu-Migration; README + Terraform-Best-Practices[slice-8] zaten twin, `ls 03-IaC/*.md` ile teyit; kalan Pulumi-vs-Terraform + Terraform-Module-Layout → slice-11). Hiçbirinde anchor-linkli iç ToC yok (slice-9 Mobile ToC komplikasyonu bu dilimde yok — 5 dosyada `](#` = 0, `{ #` = 0). 5 paralel çeviri subagent (dosya başına bir, sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`02-CI-CD/Pipeline-Patterns.en.md`+`README.en.md`+`GitHub-Actions-Recipes.en.md`, `03-IaC/README.en.md`+`Terraform-Best-Practices.en.md`) → remediation gerekmedi, ilk çeviride doğru. **Bağımsız doğruladım (subagent raporlarına körü körüne değil):** başlık paritesi 5/5 (49/22/29/49/45), tablo 5/5 (3/2/2/3/2), fence 5/5 (46/24/26/24/24, twin==source), satır deltası **0/0/0/0/0 (tam byte-parite)**, gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; render `<article>` body-TR=0, Pipeline-Performance + OpenTofu-Migration python HTML ayrıştırması ile teyit), link locale-eksiz (0 sızıntı). Spot-read: Pipeline-Performance H1+epigraf+intro doğal EN, ASCII test-pyramid etiketleri çevrildi + `${{ }}`/`uses:` verbatim; Reusable-Workflows `workflow_call`/`inputs:`/`outputs:`/`secrets:`/`runs: using: composite` verbatim, yorum `# special repo`/`# appears in the template UI` çevrildi; Crossplane `Composition`/`XRD`/`ProviderConfig`/`apiVersion:`/`kind:` verbatim + decision-tree `YES` etiketi; Drift-Detection `terraform plan -detailed-exitcode`/`driftctl` verbatim + anti-pattern başlığı `Correct`; OpenTofu `BSL`/`MPL 2.0`/`HashiCorp`/`CNCF`/`Linux Foundation` verbatim + 2023/2026 tarihleri korundu, prose çevrildi. **Positioning/pazarlama grep 0 hit (TR+EN).** **İçerik kaliteli → benimsendi.** QA exit 0 (1 uyarı: önceki turlardan kalan qa.py docs/index.en.md locale-twin FP; bu 5 twin'den yeni kırık link 0). İki-locale build (build-docs.sh + python3 -m mkdocs) exit 0, 5 sayfa İngilizce render (`site/en/…`, body-TR=0), TR root default korundu, `_planning` sızmadı (find _planning = 0). EN kapsama %38.3 → %39.8 (133/334). **`02-CI-CD` artık tam twin (8/8); `03-IaC` 5/7** (README + Terraform-Best-Practices[slice-8] + bu tur 3; kalan Pulumi-vs-Terraform + Terraform-Module-Layout → slice-11). Working-tree TEMİZ girdi → commit: **7 kendi dosyam** = 5 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`, `git add -A` KULLANILMADI). **Sıra: P4 slice-11 (`03-IaC/Pulumi-vs-Terraform` + `Terraform-Module-Layout` → 03-IaC 7/7 tamamlar, sonra `07-Observability/*` klasör sırasıyla → sonraki tur `ls` + I18N dilim tablosu #51+ ile teyit et).**

</details>

<details><summary>Önceki tur başlığı — P4 slice-9 (#41–45)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-9 (#41–45)** — `00-Culture/Team-Topologies` (→ 00-Culture tam twin 8/8) + `02-CI-CD/{Caching-Strategies, GitHub-Actions-Recipes, GitLab-CI-Recipes, Mobile-CICD-Flutter}`. Son commit `0a8a788` (slice-8). Bağımsız doğruladım: başlık paritesi 5/5 (30/44/22/24/93), tablo 5/5 (19/13/12/13/25), fence 5/5 (4/56/32/28/52), satır deltası 0/0/0/0/-1, gerçek Türkçe kalıntısı 0, link locale-eksiz. Mobile-CICD-Flutter iç ToC anchor 8/8 yeniden üretildi. Positioning grep 0 hit. `00-Culture` tam twin (8/8); `02-CI-CD` 6/8. EN kapsama %36.8 → %38.3 (128/334). QA exit 0. Commit: 7 kendi dosyam (5 `.en.md` + STATE + I18N-COVERAGE).

</details>

<details><summary>Önceki tur başlığı — P4 slice-8 (#36–40)</summary>

(önceki tur) Faz 9.5 — EN twin **P4 slice-8 (#36–40)** — `04-Containers/Multi-Stage-Builds` (→ 04-Containers tam twin 7/7) + `03-IaC/Terraform-Best-Practices` + `00-Culture/{Documentation-Culture, DORA-SPACE-Metrics, On-Call-Playbook}`. Tur başı working-tree TEMİZ, son commit `f4ee132` (slice-7, conventional) — kesintili-tur DEĞİL, normal devam. Slice-8 = I18N-COVERAGE "P4 — dilim planı" #36–40 ile birebir: #36–37 dilim planından (Multi-Stage-Builds `04-Containers`'ı tamamlar 7/7, Terraform-Best-Practices güçlü pick), #38–40 = kalan 00-21 deep-dive'ları **klasör sırasıyla** → 00-Culture ilk (`ls` ile teyit: 00-Culture'da 4 `.en.md`'siz kaldı, ilk 3 bu dilim; Team-Topologies → slice-9). 5 paralel çeviri subagent (dosya başına bir, sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`04-Containers/Dockerfile-Best-Practices.en.md`, `03-IaC/README.en.md`, `00-Culture/Blameless-Postmortem-Template.en.md`) → remediation gerekmedi, ilk çeviride doğru. Bağımsız doğruladım: başlık paritesi 5/5 (35/53/42/26/36), tablo 5/5 (20/20/19/31/12), fence 5/5 (38/34/14/12/12, twin==source), satır deltası 0/0/+1/0/0 (Documentation prose-wrap), gerçek Türkçe kalıntısı **0**, link locale-eksiz. Spot-read: Multi-Stage Dockerfile `# Build stage`/`# Runtime stage` + `FROM gcr.io/distroless/static-debian12:nonroot`/`COPY --from=builder` verbatim; Documentation ADR/RFC ```markdown template prose çevrildi + kimlik/tarih verbatim; DORA tablo prose + metric adları korundu; On-Call `[ ]` runbook + SEV-1..4 verbatim. **Positioning/pazarlama grep 0 hit.** İçerik kaliteli → benimsendi. QA exit 0 (1 uyarı: docs/index.en.md locale-twin FP; yeni kırık link 0). İki-locale build exit 0, 5 sayfa İngilizce render (EN-marker 149/104/123/128/136), TR root default korundu, `_planning` sızmadı. EN kapsama %35.3 → %36.8 (123/334). **`04-Containers` tam twin (7/7); `00-Culture` 4/8.** Working-tree TEMİZ girdi → commit: **7 kendi dosyam** = 5 yeni `.en.md` + STATE + I18N-COVERAGE (tek tek `git add`). **Sıra: P4 slice-9 (`00-Culture/Team-Topologies` + `02-CI-CD/*` klasör sırasıyla).**

</details>

## Faz durumu

| Faz | Ad | Durum | Not |
|---|---|---|---|
| -1 | Zemin: rebrand + i18n + P0 | ✅ | Tamamlandı: infra + rebrand(in-repo) + konumlandırma + i18n zemini + P0-1..7 |
| 0 | Keşif ve haritalama | ✅ | `GAP-MAP.md` + `MODULE-SPEC.md`. **ONAY ALINDI** — 9 revizyon uygulandı |
| 1 | İskelet | ✅ | 8 rehber + 29 modül iskeleti + 3 capstone. QA exit 0 |
| 2 | Blok A + B (içerik) | ✅ | **Tamam.** A1–A6 + B1–B3 (9 modül) TR içerik, hepsi >300s, QA exit 0 (0 uyarı) |
| 3 | Blok C + D | ✅ | **Tamam.** C0–C4 + D1–D5 (10 modül) içerik. C88·D84=172s (plan tutuyor). QA exit 0 (0 uyarı) |
| 4 | Blok E | ✅ | **Tamam.** E1–E5 (5 modül) içerik. E toplam=64s (revizyon4 planı tutuyor). QA exit 0 (0 uyarı). `INTERVIEW-COVERAGE.md` yazıldı: 15/15 mid-level soru A–E ile eşleşiyor |
| 5 | Lab'ların tamamlanması | ✅ | **Tamam.** L01–L20 (20 build) + K00–K09 (10 kırık) tam. 49 script `bash -n` temiz, kırık lab 4-dosya tam. Blok E lab'ları (L18–L20 + K07–K09) doğrulandı; 30 modül→lab pointer'ı canlı markdown link'e çevrildi. QA exit 0 (0 uyarı) |
| 6 | Değerlendirme | ✅ | **Tamam.** 5 STAGE-EXAM (A–E, blok klasörlerinde) + PLACEMENT 2 kontrol testi dolduruldu + 3 capstone (şartname/kabul/rubrik/portfolyo şablonu). Her sınav sorusu modül kabul kriterine izlenebilir (traceability sütunu). QA exit 0 (0 uyarı) |
| 6.5 | Sertifika katmanı | ✅ | **Tamam.** README + G1/G2/G3 + HOW-TO-CERTIFY (§8.2 9 bölüm/kapı, sürüm uyarısı, domain×modül boşluk sütunu). Redirect + RoadMap/CV-Tips entegrasyonu + DCA legacy notu + çelişki temizliği. G3'te F2→CKS ileri-link + sıra notu (revizyon 7). QA exit 0 (0 uyarı) |
| 7 | Blok F + kariyer köprüsü | ✅ | **Tamam.** F1–F5 içerik (üçüncü bakış çerçevesi) + F1/F2/F4/F5 teslim egzersizleri + PORTFOLIO.md + CV-Tips çift yönlü bağ. F toplam=48s (plan F48 tutuyor). QA exit 0 (0 uyarı) |
| 8 | Entegrasyon | ✅ | **Tamam.** Kök README (patika = Hızlı Başlangıç 1. satır + TOC) · RoadMap "A — Yeni Başlayan" redirect (eski liste `<details>` arşiv) · build-docs.sh: 22-LP `.pages` başlık+iç sıra, kök nav'da RoadMap'ten ÖNCE, `_planning` stage edilmiyor · mkdocs nav_translations EN başlık · **43 deep-dive'a "Önce oku" geri-linki** (kısıt #2 tek istisnası). QA exit 0, iki locale derlendi |
| 9 | Düşmanca gözden geçirme | ✅ | **Tamam.** TROUBLESHOOTING 55 madde · REVIEW-FINDINGS 40 bulgu (6 blok) hepsi kapandı (A5·B8·C7·D8·E6·F6; `⬜` yok, `➖` gerekçeli: A-05/B-04/F-06) · GLOSSARY-COVERAGE.md çıkarıldı → açık terim boşluğu 0. Glossary'ye 6 terim (ack/ADR/Alertmanager/Cognitive load/Reserved Instance/Right-sizing). QA exit 0 |
| 9.5 | A0 + geri-dönük düzeltmeler + EN twin | 🟡 | **İÇERİK %100 TAMAM; Aşama B flip ⏸ TIKANDI (kullanıcı kararı bekliyor — `.local/PAUSE`).** Aşama B (EN varsayılan flip) dokümante yöntemle imkânsız (mkdocs-static-i18n suffix şeması eksiz TR `X.md`'leri default'a bağlar → `default: en` conflict; çözüm korunan dosya rename'i = Kısıt #2 ihlali). 3 seçenek + öneri (Seçenek 1: Aşama A'da kal) → `Açık kararlar`. **A0 TAMAM.** **EN twin: P0 ✅ · P1a ✅ · P1b ✅ · P2 ✅ · P3 ✅ (15/15) · P4 ✅ (slice-26 bitti → **P4 KAPANDI**; 21-Field-Notes **14/14 TAM TWIN** [+system/2+terraform/2; system/ + terraform/ kapandı] → **tüm 00-21 tam twin**; EN %61.7→%62.9 (210/334); 🎯 **Aşama B eşiği %60 AŞILDI + tam twin sağlandı → flip SIRADAKI TUR** [ayrı tur/faz; §Faz-1(c) + §14.1.2]; alttaki detay arşivdir/…)** — (arşiv) P4 slice-15: `10-Databases-Production/{HA-Patroni-Stolon, Monitoring-Postgres, Operator-Patterns, Postgres-Production-Guide, StatefulSet-vs-Operator}` (→ 10-Databases-Production tam twin 9/9) (#71–75; kalan 00-21 klasör sırasıyla → 10-Databases-Production kalan 5 kapandı [9/9]; README[P2]+Backup-Restore-Patterns/Zero-Downtime-Migrations[P3]+Connection-Pooling[s14] zaten twin). Hiçbirinde anchor-ToC yok (`](#`=0). 5 paralel çeviri subagent (sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard → remediation gerekmedi. Bağımsız doğruladım: başlık/tablo/fence paritesi 5/5 (40·27·25·61·22 / 29·21·37·35·27 / 30·30·22·50·18, twin==source), satır deltası **0/0/0/0/0 (tam byte-parite)**, gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; render body-TR=0, Postgres-Production-Guide + Operator-Patterns python HTML ayrıştırması), link locale-eksiz, frontmatter tags verbatim 5/5. Spot-read: HA-Patroni-Stolon `patronictl`/`pg_rewind`/`synchronous_mode`/etcd/HAProxy/watchdog verbatim + alert `SPLIT BRAIN: birden fazla primary`→`multiple primaries`; Monitoring-Postgres `pg_stat_statements`/`pg_stat_activity`/`postgres_exporter`/`n_dead_tup` verbatim; Operator-Patterns CloudNativePG/Crunchy/Zalando + `kind: Cluster|postgresql|PostgresCluster`/pgBackRest verbatim; Postgres-Production-Guide `postgresql.conf`/`shared_buffers`/`work_mem`/`wal_level` + SQL verbatim; StatefulSet-vs-Operator `kind: StatefulSet`/`volumeClaimTemplates` verbatim + ASCII etiketi `StatefulSet oluşturur`→`Creates StatefulSet`. Epigraf figürü kaynak-sadık (HA "6 ay/6 hafta"). **Positioning grep 0 hit.** İçerik kaliteli → benimsendi. `10-Databases-Production` tam twin (9/9). EN kapsama %45.8 → %47.3 (158/334). QA exit 0 (1 uyarı: docs/index.en.md locale-twin FP, önceki turlardan; yeni kırık link 0). İki-locale build exit 0, 5 sayfa İngilizce render (`site/en/10-Databases-Production/…`, body-TR=0), TR root default korundu, `_planning` sızmadı. **Sıra slice-16** (`11-SRE/*` klasör sırasıyla → `13-*` … `16-Cheatsheets/` → `17-Templates/` → `21-Field-Notes/`). <details><summary>slice-14 (#66–70)</summary>bu tur P4 slice-14: `09-Networking/{Ingress-and-Gateway-API, Ingress-NGINX-Patterns, Network-Troubleshooting, Service-Mesh-Comparison}` (→ 09-Networking tam twin 8/8) + `10-Databases-Production/Connection-Pooling` (#66–70; kalan 00-21 klasör sırasıyla → 09-Networking kalan 4 kapandı [8/8], sonra 10-Databases-Production ilk 1; README[P2]+Cilium-eBPF-Intro/DNS-Strategies/Gateway-API-Migration[s13] zaten twin, README[P2]+Backup-Restore-Patterns/Zero-Downtime-Migrations[P3] zaten twin). Hiçbirinde anchor-ToC yok (`](#`=0). 5 paralel çeviri subagent (sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard → remediation gerekmedi. Bağımsız doğruladım: başlık/tablo/fence paritesi 5/5 (17·36·73·39·55 / 17·15·27·55·36 / 10·46·34·24·36, twin==source), satır deltası **0/0/+3/0/+3** (Network-Troubleshooting + Connection-Pooling epigraf/intro prose-wrap; blank-line 86/86·85/85 + list-item 21/21 + H/T/F tam parite → yapı satırı eklenmedi, saf reflow), gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; Service-Mesh tek `-w` eşleşmesi `could've` içindeki `ve` = İngilizce kasılma FP; render body-TR=0, 5/5 python HTML ayrıştırması), link locale-eksiz. Spot-read: Ingress-and-Gateway-API `kind: Ingress|IngressClass|HTTPRoute`/`parentRefs`/`backendRefs` verbatim + ASCII `eski-app`→`old-app` etiket; Ingress-NGINX `nginx.ingress.kubernetes.io/*` annotation (`ssl-redirect`/`limit-rps`/`canary-by-header`) verbatim + `# 10 req/sec/IP` çevrildi; Network-Troubleshooting `dig`/`tcpdump`/`ss`/`conntrack`/`nsenter`/`NXDOMAIN`/`connection refused` verbatim, karar-ağacı prose çevrildi; Service-Mesh Istio/Linkerd/Cilium/Envoy/Ambient + `kind: VirtualService|DestinationRule|PeerAuthentication`/mTLS/`istioctl` verbatim; Connection-Pooling `PgBouncer`/`pgcat`/`Odyssey`/`pool_mode = transaction`/`max_client_conn`/`SHOW POOLS` verbatim + `<DB_HOST>` placeholder. Epigraf istatistikleri kaynak-sadık (30% network-related / 40% pool exhaustion — TR kaynakta zaten var, yeni iddia DEĞİL). **Positioning grep 0 hit.** İçerik kaliteli → benimsendi. `09-Networking` tam twin (8/8); `10-Databases-Production` 4/9. EN kapsama %44.3 → %45.8 (153/334). QA exit 0 (1 uyarı: docs/index.en.md locale-twin FP, önceki turlardan; yeni kırık link 0). İki-locale build exit 0, 5 sayfa İngilizce render (`site/en/…`, body-TR=0), TR root default korundu, `_planning` sızmadı. **Sıra slice-15** (`10-Databases-Production/*` kalan 5 → `11-SRE/*`). </details> <details><summary>slice-13 (#61–65)</summary>bu tur P4 slice-13: `08-Security/{SLSA-and-SBOM, Zero-Trust-Networking}` (→ 08-Security tam twin 10/10) + `09-Networking/{Cilium-eBPF-Intro, DNS-Strategies, Gateway-API-Migration}` (#61–65; kalan 00-21 klasör sırasıyla → 08-Security kalan 2 kapandı [10/10], sonra 09-Networking `.en.md`'siz ilk 3; README[P2]+Kubernetes-Hardening/Threat-Modeling/Secrets-Management/DevSecOps-Pipeline[P3]+Container-Image-Scanning/Policy-as-Code/Runtime-Security[s12] zaten twin). 5 paralel çeviri subagent (sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard → remediation gerekmedi. Bağımsız doğruladım: başlık/tablo/fence paritesi 5/5 (37·41·47·41·32 / 37·50·24·23·49 / 26·36·32·36·28, twin==source), satır deltası **0/0/0/0/0 (tam byte-parite)**, gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; render body-TR=0, 5/5 python HTML ayrıştırması), link locale-eksiz. Hiçbirinde anchor-ToC yok (`](#`=0). Spot-read: SLSA `cosign`/`syft`/`slsa-verifier`/SPDX/CycloneDX + `SolarWinds (2020)`/`xz-utils (2024)` verbatim; Zero-Trust `kind: NetworkPolicy`/mTLS/SPIFFE/SPIRE + NIST 800-207/BeyondCorp prose çevrildi (epigraf kaynak-sadık); Cilium `cilium status`/`hubble observe`/`CiliumNetworkPolicy`/XDP/kube-proxy verbatim; DNS A/AAAA/CNAME/`CoreDNS`/`Corefile`/ndots/`/etc/resolv.conf` verbatim; Gateway-API `kind: HTTPRoute|Gateway|GatewayClass`/`parentRefs`/`backendRefs` verbatim. **Positioning grep 0 hit.** İçerik kaliteli → benimsendi. `08-Security` tam twin (10/10); `09-Networking` 4/8. EN kapsama %42.8 → %44.3 (148/334). QA exit 0 (1 uyarı: docs/index.en.md locale-twin FP, önceki turlardan; yeni kırık link 0). İki-locale build exit 0, 5 sayfa İngilizce render (`site/en/…`, body-TR=0), TR root default korundu, `_planning` sızmadı. **Sıra slice-14** (`09-Networking/*` kalan 4 → `10-Databases-Production/*`). </details> <details><summary>slice-12 (#56–60)</summary>bu tur P4 slice-12: `07-Observability/{Prometheus-Grafana-K8s-Setup, Tracing-with-Tempo}` (→ 07-Observability tam twin 9/9) + `08-Security/{Container-Image-Scanning, Policy-as-Code-OPA-Kyverno, Runtime-Security}` (#56–60; kalan 00-21 klasör sırasıyla → 07-Observability kalan 2 kapandı [9/9], sonra 08-Security ilk 3; README[P2]+Kubernetes-Hardening[P3]+Threat-Modeling[P3]+Secrets-Management[P3]+DevSecOps-Pipeline[P3] zaten twin). Prometheus-Grafana-K8s-Setup anchor-ToC 8/8 regen (`#system-requirements`…`#useful-commands`); diğer 4'te anchor-ToC yok. 5 paralel çeviri subagent (sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard → remediation gerekmedi. Bağımsız doğruladım: başlık/tablo/fence paritesi 5/5 (103·34·48·49·41 / 12·12·39·36·59 / 46·30·36·40·32, twin==source), satır deltası **0/0/0/0/0 (tam byte-parite)**, gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; render body-TR=0, 5/5 python HTML ayrıştırması), link locale-eksiz. Spot-read: Prometheus-Grafana helm/kubectl patch + `<GRAFANA_ADMIN_PASSWORD>` placeholder + `admin123!` anti-pattern verbatim; Tempo OTLP/`trace_id`/`traceparent` verbatim; Container-Image-Scanning `trivy image --severity CRITICAL,HIGH` verbatim + `# Only CRITICAL/HIGH` çevrildi; Policy-as-Code Rego/`kind: ClusterPolicy`/`validationFailureAction: Enforce|Audit` verbatim; Runtime-Security Falco `desc:`/`output:` prose çevrildi + `condition:`/`proc.name`/seccomp/eBPF verbatim. **Positioning grep 0 hit.** `07-Observability` tam twin (9/9); `08-Security` 8/10. EN kapsama %41.3 → %42.8 (143/334). QA exit 0 (1 uyarı: docs/index.en.md locale-twin FP, önceki turlardan; yeni kırık link 0). Kalan **P4 çok turlu** — sıra slice-13 (`08-Security/{SLSA-and-SBOM, Zero-Trust-Networking}` → 08-Security 10/10, sonra `09-Networking/*`). </details> <details><summary>slice-11 (#51–55)</summary> bu tur P4 slice-11: `03-IaC/{Pulumi-vs-Terraform, Terraform-Module-Layout}` (→ 03-IaC tam twin 7/7) + `07-Observability/{Logs-Loki-vs-ELK, OpenTelemetry-Adoption, Profiling-with-Pyroscope}` (#51–55; kalan 00-21 klasör sırasıyla → 03-IaC kalan 2 kapandı [7/7], sonra 07-Observability ilk 3; README[P2]+Prometheus-Best-Practices[P3]+Alerting-Done-Right[P3]+SLO-Engineering[P4-s4] zaten twin). 5 paralel çeviri subagent (sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard → remediation gerekmedi. Bağımsız doğruladım: başlık/tablo/fence paritesi 5/5 (25·40·36·37·29 / 34·20·30·33·18 / 18·40·26·22·28, twin==source), satır deltası **0/0/0/0/0 (tam byte-parite)**, gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; render body-TR=0), link locale-eksiz. Hiçbirinde anchor-linkli iç ToC yok (`](#`=0, `{ #`=0). Spot-read: Pulumi Mocha test string'i çevrildi + HCL/TS/`@pulumi/aws` verbatim; Terraform-Module-Layout dizin-ağacı sabit; Logs-Loki LogQL `{app="…"}`/`|=`/`|~` verbatim + `# All logs` yorum çevrildi + KVKK reframe; OpenTelemetry `OTEL_*`/`OTLP`/Collector `receivers:`/`exporters:`/`service.name` verbatim + ASCII diyagram etiket çevrildi; Pyroscope `pprof`/eBPF/flame-graph verbatim + `7/24`→`24/7`. **Positioning grep 0 hit.** `03-IaC` tam twin (7/7); `07-Observability` 7/9. EN kapsama %39.8 → %41.3 (138/334). QA exit 0 (1 uyarı: docs/index.en.md locale-twin FP, önceki turlardan; yeni kırık link 0). Kalan **P4 çok turlu** — sıra slice-12 (`07-Observability/Prometheus-Grafana-K8s-Setup` + `Tracing-with-Tempo` → 07-Observability 9/9, sonra `08-Security/*`). </details> <details><summary>slice-10 (#46–50)</summary> bu tur P4 slice-10: `02-CI-CD/{Pipeline-Performance, Reusable-Workflows}` (→ 02-CI-CD tam twin 8/8) + `03-IaC/{Crossplane-Intro, Drift-Detection, OpenTofu-Migration}` (#46–50; hepsi kalan 00-21 klasör sırasıyla → 02-CI-CD kalan 2 kapandı, sonra 03-IaC ilk 3; README+Terraform-Best-Practices[slice-8] zaten twin). 5 paralel çeviri subagent (sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard → remediation gerekmedi. Bağımsız doğruladım: başlık/tablo/fence paritesi 5/5 (49·22·29·49·45 / 3·2·2·3·2 / 46·24·26·24·24, twin==source), satır deltası **0/0/0/0/0 (tam byte-parite)**, gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path/proper-noun + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; render body-TR=0), link locale-eksiz. Bu dilimde anchor-linkli iç ToC yok (`](#`=0, `{ #`=0). Spot-read: Pipeline-Performance ASCII test-pyramid etiketi + `${{ }}`/`uses:` verbatim; Reusable-Workflows `workflow_call`/`inputs:`/`composite` verbatim; Crossplane `Composition`/`XRD`/`ProviderConfig`/`apiVersion:`/`kind:` + decision-tree `YES` etiketi; Drift-Detection `terraform plan -detailed-exitcode`/`driftctl` + anti-pattern `Correct`; OpenTofu `BSL`/`MPL 2.0`/`HashiCorp`/`CNCF`/`Linux Foundation` verbatim + 2023/2026 tarih korundu. **Positioning grep 0 hit.** `02-CI-CD` tam twin (8/8); `03-IaC` 5/7. EN kapsama %38.3 → %39.8 (133/334). QA exit 0 (1 uyarı: docs/index.en.md locale-twin FP, önceki turlardan; yeni kırık link 0). Kalan **P4 çok turlu** — sıra slice-11 (`03-IaC/Pulumi-vs-Terraform` + `Terraform-Module-Layout` → 03-IaC 7/7, sonra `07-Observability/*`). </details> <details><summary>slice-9 (#41–45)</summary> bu tur P4 slice-9: `00-Culture/Team-Topologies` (→ 00-Culture tam twin 8/8) + `02-CI-CD/{Caching-Strategies, GitHub-Actions-Recipes, GitLab-CI-Recipes, Mobile-CICD-Flutter}` (#41–45; #41 dilim planından, #42–45 = kalan 00-21 klasör sırasıyla → 01-Linux-Networking tam twin atlandı, 02-CI-CD sırada; Pipeline-Performance + Reusable-Workflows → slice-10). 5 paralel çeviri subagent (sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard → remediation gerekmedi. Bağımsız doğruladım: başlık/tablo/fence paritesi 5/5 (30·44·22·24·93 / 19·13·12·13·25 / 4·56·32·28·52, twin==source), satır deltası 0/0/0/0/-1 (Mobile trailing-nl), gerçek Türkçe kalıntısı **0** (`[ışğİŞĞçöü]` excl path + diakritiksiz TR-fonksiyon-kelime 5/5 temiz; render body-TR=0), link locale-eksiz. **Mobile-CICD-Flutter iç ToC anchor 8/8 yeniden üretildi** (GitHub-slug, başlıklara çözülüyor). Spot-read: Team-Topologies Conway/Skelton + takım-türü adları verbatim + F3 geri-link locale-eksiz; keystore `keytool`/`.jks` verbatim, warning prose çevrildi; GH-Actions `# required for OIDC`/`# cancel the old run…` + anti-pattern tablo `Why it's bad`/`Correct`; bundle-id `com.onmuhasebe.mobile` kaynak-sadık (5/5). **Positioning grep 0 hit.** `00-Culture` tam twin (8/8); `02-CI-CD` 6/8. EN kapsama %36.8 → %38.3 (128/334). QA exit 0 (1 uyarı: docs/index.en.md locale-twin FP, önceki turlardan; yeni kırık link 0). Kalan **P4 çok turlu** — sıra slice-10 (`02-CI-CD/Pipeline-Performance` + `Reusable-Workflows` + `03-IaC/*` kalan 5). </details> <details><summary>slice-8 (#36–40)</summary> bu tur P4 slice-8: `04-Containers/Multi-Stage-Builds` (→ 04-Containers tam twin 7/7) + `03-IaC/Terraform-Best-Practices` + `00-Culture/{Documentation-Culture, DORA-SPACE-Metrics, On-Call-Playbook}` (#36–40; #36–37 dilim planından, #38–40 = kalan 00-21 klasör sırasıyla → 00-Culture ilk; Team-Topologies → slice-9). Bağımsız doğruladım: başlık/tablo/fence paritesi 5/5 (35·53·42·26·36 / 20·20·19·31·12 / 38·34·14·12·12), satır deltası 0/0/+1/0/0, gerçek Türkçe kalıntısı 0, link locale-eksiz. Positioning grep 0 hit. `04-Containers` tam twin (7/7); `00-Culture` 4/8. EN kapsama %35.3 → %36.8 (123/334). QA exit 0. </details> <details><summary>slice-7 (#31–35)</summary> bu tur P4 slice-7: `04-Containers/*` kalan 6'nın ilk 5 (BuildKit-Tips, Container-vs-WASM, Distroless-and-Chainguard, Dockerfile-Best-Practices, Image-Signing-Cosign) (#31–35 = STATE/I18N dilim planıyla birebir; 6. Multi-Stage-Builds → slice-8). Tur başı working-tree TEMİZ, son commit `9324c1e` conventional — kesintili-tur DEĞİL, normal devam. 5 paralel çeviri subagent (sonnet), oturmuş genişletilmiş ruleset + aynı-klasör gold-standard (`04-Containers/README.en.md`) → remediation gerekmedi. Bağımsız doğruladım: başlık/tablo/fence paritesi 5/5 (45·29·37·68·23 / 21·55·33·29·16 / 58·22·20·50·20, twin==source), satır deltası 0/+1/0/0/+1, gerçek Türkçe kalıntısı **0** (rendered body-TR=0 5/5; `[ışğİŞĞçöü]` excl path/Istanbul + diakritiksiz TR-fonksiyon-kelime 5/5 temiz), link locale-eksiz. Spot-read: Dockerfile code-yorumu `# ❌ Kötü`→`# ❌ Bad`/`# ✅ İyi`→`# ✅ Good` + anti-pattern tablo hücresi (`Çok`→`Many`/`kaçın`→`avoid`); BuildKit `# Single build`/`# Daemon-wide` yorumu; Image-Signing Kyverno bloğu (`validationFailureAction: Enforce`/`verifyImages:`) sabit; image ref (`gcr.io/distroless/static-debian12`/`cgr.dev/chainguard/*`) + Dockerfile talimatı + BuildKit token (`--mount=type=cache/secret/ssh`/`buildx`/`--platform`) + Wasm (`Spin`/`WASI`/`.wasm`) + Cosign/Sigstore (`Fulcio`/`Rekor`/`keyless`/`SBOM`) verbatim. **Positioning grep 0 hit** (bu 5 kaynak artifact yoğun; ROI/guarantee prose'u yok). İçerik kaliteli → benimsendi. **`04-Containers` artık 6/7** (Multi-Stage-Builds → slice-8; 05-Kubernetes + 06-GitOps + 12-FinOps tam). EN kapsama %33.8 → %35.3 (118/334). QA exit 0 (1 uyarı: docs/index.en.md locale-twin FP, önceki turlardan; yeni kırık link 0). Kalan **P4 çok turlu** — sıra slice-8 (`04-Containers/Multi-Stage-Builds` + `03-IaC/Terraform-Best-Practices` + kalan 00-21). </details> |

## Sıradaki adım

**⏸ TIKANMA — KULLANICI KARARI BEKLENIYOR (§14.2(b)). Aşama B (EN varsayılan flip) dokümante edilen yöntemle İMKÂNSIZ; `.local/PAUSE` oluşturuldu. Detay + 3 seçenek + öneri → `Açık kararlar` en üst blok.**
Bu tur (slice-26 sonrası, P4 KAPALI) Aşama B flip'ini yürütmeye çalıştım; **empirik olarak** mkdocs `default: tr→en` değişikliğinin build'i **kırdığını** kanıtladım (`Exception: Conflicting files for the default language 'en': choose either 'index.md' or 'index.md' but not both`). Kök sebep: `mkdocs-static-i18n` **suffix şeması** her **eksiz** `X.md` dosyasını **default** locale'e bağlar. Bizim 334 eksiz `X.md`'miz **TR içerik** (Kısıt #2 / §14.4 ile korunuyor — `.tr.md`'ye rename edilemez) + 210'unun `.en.md` ikizi var → `default: en` yapınca ikisi de `en` iddia ediyor → **conflict**; ikizsiz 124 sayfa da İngilizce sayılıp TR içerikle sunulur. Dokümante edilen "tek-satır config flip" bu plugin + kısmi kapsam + korunan-dosya kısıtıyla **çalışmıyor**. Baseline (Aşama A: TR default kök + EN `/en/`) **yeşil bırakıldı** (mkdocs exit 0, qa exit 0, iki-locale render, `_planning` sızmadı, mkdocs.yml git-diff TEMİZ — deney geri alındı). **İçerik işi %100 bitti** (tüm 00-21 tam twin + rehber/omurga twin; site EN kapsamı %62.9). Kalan tek açık kalem = flip, ki o da kullanıcı kararına bağlı (bkz. Açık kararlar).

**(ARŞİV — flip öncesi plan, artık geçersiz yöntem)** Faz 9.5 · EN twin — P4 TAMAM (tüm 00-21 TAM TWIN, 210/334 = %62.9). Planlanmıştı: Aşama B — EN varsayılan flip (KENDİ TURUNDA). ⚠️ Yöntem imkânsız çıktı, yukarıya bak.
P0 + P1a (9) + P1b (35) + P2 (21) + P3 (15) + P4 slice-1..9 (45) +
**P4 slice-10..26 (82)** bitti → **site sayfası 210** (P0 kök README dahil değil, oran dışı). **P4 KAPANDI:**
numaralı klasörlerin (00-21) tamamı tam twin +
`17-Templates/` **tam twin (10/10)** [slice-22 index 5 + slice-23 kalan 4] + `21-Field-Notes/` **tam twin (14/14)** [slice-24: README+ansible/2+kubectl/2; slice-25: network/1+system/4; slice-26 SON: system/2+terraform/2] → **kalan içerik yok, P4 bitti**. `12-FinOps/` **tam twin'li (8/8)**; `06-GitOps/`
**tam twin'li (7/7)**; `05-Kubernetes/` **tam twin'li (7/7)**; `04-Containers/` **tam twin'li (7/7)**;
`00-Culture/` **tam twin'li (8/8)**; `02-CI-CD/` **tam twin'li (8/8)**; `03-IaC/` **tam twin'li (7/7)**;
`07-Observability/` **tam twin'li (9/9)**; `08-Security/` **tam twin'li (10/10)**;
`09-Networking/` **tam twin'li (8/8)**; `10-Databases-Production/` **tam twin'li (9/9)**;
`01-Git-Workflow/` **tam twin'li (6/6)** [slice-16]; `11-SRE/` **tam twin'li (8/8)** [slice-17];
`14-Sustainability/` **tam twin'li (6/6)** [slice-17+18];
`15-AI-LLMOps/` **tam twin'li (8/8)** [slice-18+19+20]; `16-Cheatsheets/` **tam twin'li (10/10)** [slice-20+21];
`17-Templates/` **tam twin'li (10/10)** [kök[P2] + 5 alt-klasör index slice-22 + prometheus-rules/terraform/runbooks×2 slice-23];
`21-Field-Notes/` **tam twin'li (14/14)** [slice-24: README+ansible/2+kubectl/2; slice-25: network/1+system/4; slice-26 SON: system/2+terraform/2].
🎯 **Aşama B eşiği (%60) AŞILDI (%62.9, 210/334) + tüm 00-21 tam twin → ön koşullar tam.** Aşama B (EN varsayılan flip) **bu turda YAPILMADI** (§14.1.2 bir-slice/tur + §Faz-1(c) "şimdi yapma"; flip ayrı bir operasyon) — **SIRADAKI TUR** kendi turunda değerlendir/yürüt, koşul/gerekçe/adımlar `Açık kararlar`da. **P4 çok-turlu twin işi BİTTİ.**

1. **⏸ Aşama B — EN varsayılan flip: DOKÜMANTE EDİLEN YÖNTEM İMKÂNSIZ (bu tur kanıtlandı).**
   Eski plan (a)–(f) — `default: tr→en` taşı — **çalışmıyor**: `mkdocs-static-i18n` 1.3.1 suffix şeması
   eksiz `X.md`'yi default locale'e bağlar; bizim eksiz dosyalar TR + korunuyor → `Exception: Conflicting
   files for the default language 'en'`. Çözüm ancak **rename** (korunan 00-21 `X.md`'lerini `.tr.md`'ye
   taşımak) ile mümkün ki bu **Kısıt #2 / §14.4 kırmızı çizgisi**. Bu bir tek-turda-çözülebilir teknik iş
   değil, **dışa-dönük konumlandırma kararı** → kullanıcıya bırakıldı (`.local/PAUSE`). Seçenekler + öneri
   `Açık kararlar` en üst blokta. **Bu kalem kullanıcı kararı gelene kadar DONMUŞTUR — sonraki tur bu
   maddeye dokunmadan `.local/PAUSE` var mı diye bak; varsa dur.**
2. **Ruleset — slice-2/slice-3'te oturmuş genişletilmiş kural (baştan uygula):** yapı byte-korunur
   (başlık/tablo/kod bloğu+dil-tag/`<details>`/`---`/blockquote/`{ #anchor }`), iç link locale-eksiz
   `.md`, komut/YAML/PromQL/SQL/çıktı **token'ları** verbatim, placeholder EN-kanonik, KVKK/BDDK
   global-okur çerçevesi. **ÇEVRİLİR:** prose + frontmatter `description` + **plain/untagged fenced
   blok içindeki prose** — (a) checklist `[ ]` satırları, (b) ASCII diyagram/tree **etiket** metni
   (box-drawing char'lar sabit), (c) kod yorumları `# …` (marker sabit, `# YANLIŞ`→`# WRONG`,
   `# … için`→`# for …`), (d) `​```markdown` template örnek satırları, (e) Kyverno/Falco
   `message:`/`desc:` prose string değerleri. **YALNIZ gerçek verbatim-artifact korunur** (komut,
   YAML/JSON key, metric/label adı, PromQL, path `/var/…`, URL, link target, kod identifier).
   **Modül DEĞİL** (00-21 deep-dive, `MOD_RE ^[A-F]\d+-` eşleşmez) → qa modül-bütünlük denetimine girmez.
3. **Dilim başına 5 deep-dive, paralel subagent (dosya başına bir).** Nereye gelindiğini STATE'e
   **dosya-adı seviyesinde** yaz. build-docs.sh'e dokunma (`0[0-9]-*/1[0-9]-*/2[0-9]-*` `cp -r`
   özyineli stage — P2/P3'te doğrulandı, ek satır gerekmedi).
4. **Doğrulama (her dilim):** bağımsız orchestrator paritesi (başlık/tablo/fence) +
   `grep -nE '[ışğİŞĞ]' <twin> | grep -vE '/var/|VERB[İI]S'` (gerçek Türkçe kalıntı = 0) +
   link-leak (`.en.md`) + positioning/pazarlama grep (TR+EN) + qa.py + iki-locale build + spot-read.

**P1–P4 taktiği (P0…P3 slice-3'te 8 kez işe yaradı):** dosya başına bir çeviri subagent'ı (sonnet),
**genişletilmiş** ruleset (yapıyı byte-koru; prose + frontmatter description + plain-blok prose çevir;
gerçek kod-artifact + link path'i verbatim; `{ #anchor }` sabit; positioning reframe; placeholder
güvenliği), sonra bağımsız orchestrator doğrulaması (başlık/tablo/fence paritesi + link-leak +
**gerçek-Türkçe-kalıntı grep** + positioning grep) + qa.py + iki-locale build + spot-read. Her tur bir
dilim bitir, STATE'e **dosya-seviyesinde** nereye gelindiğini yaz, commit, dur.

> NOT: **L06 starter app ARTIK VAR** (`labs/build/L06-elle-deploy/starter/app.py` +
> `KURULUM.template.md`) — 9.5 listesinden Faz 9'da düşmüştü, hâlâ mevcut.

> NOT: **`README.en.md` iki anlama gelir.** Kök `README.en.md` (bu tur, GitHub landing, P0) ≠
> `22-Learning-Path/README.en.md` (P1, henüz yok). Karıştırma.

**Yerleşik desenler (sonraki fazlarda referans al):**
- **STAGE-EXAM deseni (Faz 6'da kondu):** frontmatter (`description/level/tags`, `module`
  YOK → qa MOD_RE eşleşmez, modül denetimine girmez) + traceability tablosu (`| # | Soru |
  İzlenebilirlik (modül → kabul kriteri) |`) + uygulamalı görev (kırık lab verify.sh'e
  bağlı) + anti-pattern tablosu + "Geçtin mi?" checklist. **Konum: her blok klasörü içinde
  `STAGE-EXAM.md`.** CURRICULUM geçiş-sinyalleri tablosundan + README adım 6'dan linkli.
- **Capstone deseni (Faz 6'da dolduruldu):** Şartname (teslim edilecek repo içeriği) +
  doğrulanabilir Kabul kriterleri + 0–2 puanlı Rubrik tablosu (geçme eşiği + zorunlu eksen) +
  Portfolyo README şablonu (```markdown code-block, placeholder-güvenli). **`PORTFOLIO.md`
  code-span olarak anılır, LINK DEĞİL** (dosya Faz 7'de doğar; link olsaydı qa kırık-link verirdi).
- Build lab = `README.md` + `starter/` + `solution/` + `verify.sh`. Kırık lab =
  `README.md` (belirti) + `setup.sh` + `hints/hint-1..3.md` + `solution.md` + `verify.sh`.
  Modül→lab: `../labs/build/L##-.../`; lab→modül: `../../../block-x/<ID>-...md`.

> 📌 **Yerel-önce (değişmez):** hiçbir lab gerçek para/bulut şart koşmaz (C4 bütçe alarmı
> `validate/plan` ile yerelde doğrulanır). Sertifika pratik ortamı da yerel-önce (kind/k3s/
> LocalStack) — G# dosyalarında bunu vurgula.

## Açık kararlar

> ⏸️🔴 **TIKANMA / KULLANICI KARARI (bu tur, §14.2(b)) — Aşama B (EN varsayılan flip) dokümante edilen
> yöntemle İMKÂNSIZ. `.local/PAUSE` oluşturuldu. Kullanıcı 3 seçenekten birini seçmeli.**
>
> **Ne denedim (empirik, geri alındı):** `mkdocs.yml` i18n plugin `default: true`'yu `tr`→`en`'e taşıdım,
> `bash scripts/build-docs.sh` (544 md stage) sonrası `python3 -m mkdocs build --clean` çalıştırdım. Build
> **kırıldı**: `Exception: Conflicting files for the default language 'en': choose either 'index.md' or
> 'index.md' but not both`. Sonra `mkdocs.yml`'i `git`-temiz haline geri aldım; baseline (Aşama A) yeniden
> yeşil: mkdocs exit 0 + qa exit 0 + iki-locale render + `_planning` sızmadı + `git diff mkdocs.yml` boş.
>
> **Kök sebep (plugin kaynağı okundu — `mkdocs_static_i18n/{suffix,reconfigure}.py` v1.3.1):** `docs_structure:
> suffix` şemasında **eksiz** (`X.md`, locale-suffix'siz) dosya **her zaman default locale'e** atanır
> (`suffix.py:35,54` → `file_locale = default_language`). Bizim repoda **334 eksiz `X.md` = TR içerik** ve
> bunlardan **210'unun `X.en.md` ikizi** var. `default: en` yapılınca: (1) ikizli 210 sayfada hem `X.md`
> (locale artık `en` sayılır) hem `X.en.md` (locale `en`) aynı `norm_src_uri`'yi `en` diye talep eder →
> `reconfigure.py:586` **conflict exception** (build tamamen kırılır); (2) ikizsiz 124 sayfa İngilizce
> (default) sayılıp **TR içerikle** kök URL'de sunulur, `/tr/` ikizi olmaz. Yani plugin, eksiz dosyaların
> **default dilin içeriği olmasını** zorunlu kılar. Bizde eksiz = TR, ve o dosyalar **Kısıt #2 / §14.4 ile
> korunuyor** (`00-*`…`21-*` altında silme/rename/yeniden-yazma YASAK).
>
> **Neden basit flip mümkün değil:** Gerçek EN-kök için eksiz dosyaların EN olması gerekir → korunan
> `00-21/X.md` (TR) dosyalarını `X.tr.md`'ye **rename** etmek şart. Rename = path silme/değiştirme = **Kısıt
> #2 + §14.4 ihlali** (ayrıca ~924 iç link + GitHub + dış bookmark'lar için kök URL semantiği değişir). Bu,
> otonom modda tek başıma alamayacağım **dışa-dönük konumlandırma kararı**.
>
> **SEÇENEKLER (kullanıcı seçsin):**
> - **Seçenek 1 — Aşama A'da KAL (öneri, sıfır risk).** TR default (kök) + EN `/en/` altında. Şu an
>   canlı/yeşil hâl. Global okur dil-değiştiriciyle `/en/`'e geçer; tüm 00-21 tam twin + rehber twin zaten
>   `/en/`'de. TR, kaynak-ağaçta primary kalır — repo kimliği ("derin TR/EU regülasyon kapsamı") + Kısıt #2
>   ile uyumlu. **İçerik işi bitti; ekstra iş yok.** Kullanıcı "böyle kalsın" derse Faz 9.5 KAPANIR.
> - **Seçenek 2 — EN-önce landing, rename YOK (orta, geri-alınabilir).** `default: tr` korunur (plugin mutlu,
>   korunan dosyalara dokunulmaz). `mkdocs-redirects` (zaten requirements'ta) ile kök `index.md → en/`
>   yönlendirmesi + rozet/`site_url` `/en/`'i işaret eder → ziyaretçi önce İngilizce ana sayfaya düşer, TR
>   tek tık uzakta. **Not:** yalnız ANA SAYFAYI EN yapar; derin sayfalar hâlâ TR-kök + EN-`/en/`. Kısmi ama
>   temiz. Kullanıcı onaylarsa tek turda uygulanır.
> - **Seçenek 3 — Tam plugin-native flip (rename gerekli — Kısıt #2 muafiyeti şart).** 210 ikizli sayfada
>   `X.md`(TR)→`X.tr.md`, `X.en.md`→`X.md`(EN); 124 ikizsiz TR sayfa eksiz kalır (EN-default'ta TR-içerik
>   fallback, `/tr/` ikizi yok). Sonra `default: en`. Gerçek EN-kök verir AMA: (a) korunan 00-21 `X.md`
>   path'lerini siler/taşır = **Kısıt #2 / §14.4'ü kullanıcı açıkça kaldırmadıkça YAPILAMAZ**; (b) ~420 dosya
>   move; (c) mevcut TR bookmark/dış link'lerde kök URL artık EN sunar (breaking); (d) 124 sayfa EN etiketli
>   TR içerik. **Yalnız kullanıcı Kısıt #2'yi bu path-rename için açıkça muaf tutarsa.**
>
> **Benim önerim: Seçenek 1.** Gerekçe: içerik %100 tamam, site iki-dilde çalışıyor, %60 eşiğinin amacı
> (global erişim / İngilizce) `/en/` tam-twin ile zaten karşılanıyor; Seçenek 2/3 dışa-dönük davranışı
> değiştirir ve/veya kırmızı-çizgi muafiyeti ister. Kullanıcı karar verene kadar Aşama A korunur (hiçbir şey
> bozulmadı). `.local/PAUSE` silindiğinde döngü, kullanıcının seçtiği seçenekle devam eder.
>
> ✅ **KARAR (önceki tur, P3 slice-2) — slice-1'in 4 committed twin'i düzeltildi (remediation, scope içi).**
> §14.3 öz-denetim, önceki turların teslim ettiği slice-1 twin'lerinde İngilizce sayfaların içinde Türkçe
> checklist/diyagram/kod-yorumu kalıntısı buldu (plain-blok prose çevrilmemişti). Bunlar `00-21` altında
> ama benim bu faz katmanımda ürettiğim `.en.md` **twin** dosyaları (§14.4'ün koruduğu mevcut TR/kaynak
> dosyalar değil) → düzeltmek kısıt ihlali değil. `git status` bu tur: 5 yeni `.en.md` (`??`) + 4 düzeltilmiş
> `.en.md` (` M`, Pipeline-Patterns/K8s-Hardening/Threat-Modeling/SLI-SLO) + STATE + I18N-COVERAGE. Working-tree
> TEMİZ girdi (` M README.md` yok — kullanıcı önceki turlarda commit'ledi). Detay ↓ "P3 slice-2" bölümü.
>
> ✅ **BENİMSENDİ (önceki tur) — 00–10 `README.en.md` untracked geldi, doğrulanıp commit edildi.** Tur
> başında `git status` 11 untracked `README.en.md` (00-Culture … 10-Databases-Production) gösterdi —
> STATE ise "P2 başlamadı" diyordu. Bu çelişki, önceki **kesintili bir turun** (commit/STATE
> güncellemesi olmadan ölen) P2-dilim-1 işi: structure-preserving çeviriler. Körlemesine commit
> etmedim → **doğruladım** (başlık/tablo paritesi 11/11, link-leak 0, positioning/pazarlama 0,
> 00-Culture + 08/19 spot-read) → kaliteli olduğunu görüp benimseyip 10 yeni dosyayla (11–20)
> birlikte tek P2 commit'ine aldım. Uydurma/yarım değillerdi.
>
> ✅ **ÇÖZÜLDÜ (önceki tur açık kararı) — kök `README.en.md` LinkedIn URL'i.** C+D turundaki
> atanmamış `README.en.md` farkı (`.../in/halilibrahimd` → `.../in/halil-ibrahim-durmus/`)
> kullanıcı tarafından commit'lendi: `3c10144 fix(README): update LinkedIn profile link`. Bilinçli
> kullanıcı düzeltmesiymiş → doğru bırakılmış (tahminle commit/geri-al yapmamıştım).
>
> ✅ **ÇÖZÜLDÜ (P3 slice-1 turu) — `README.md` (TR) working-tree'de kalmadı.** Bu tur başında
> `git status --porcelain` TEMİZ döndü: aşağıdaki ` M README.md` kullanıcı tarafından
> commit'lenmiş (`52e39ff`/`3c10144` LinkedIn düzeltmeleri, TR+EN eşlenik). Bilinçli kullanıcı
> düzeltmesiydi → doğru bırakıldı; artık working-tree'de değil. (Aşağıdaki not tarihsel kayıt.)
>
> ⚠️ **ATANMAMIŞ DEĞİŞİKLİK — kök `README.md` (TR) (P2 turunda BENİM işim DEĞİL).** Tur başında
> `git status --porcelain` yalnız ` M README.md` gösterdi: TR README'de aynı LinkedIn düzeltmesi
> (`.../in/halilibrahimd` → `.../in/halil-ibrahim-durmus/`) — yani kullanıcının `README.en.md`'de
> yaptığı düzeltmenin TR eşleniği. Bu değişikliği YAPMADIM (E+F çeviri kapsamı dışı; hiçbir
> subagent'a atanmadı). Kullanıcının kendi profil URL'i + `README.en.md` commit'iyle tutarlı
> olduğu için **tahminle commit ETMEDİM, geri de ALMADIM** — working-tree'de bırakıldı. **Bu tur da
> aynı (P2):** ` M README.md` hâlâ duruyor; commit'ime dahil etmedim. Bu turun commit'i yalnız **23
> kendi dosyamı** içerir (21 klasör `README.en.md` + STATE + I18N-COVERAGE) — dosyalar tek tek
> `git add` edildi, `git add -A` KULLANILMADI. **Sonraki tur uyarısı:** `git add -A` ile süpürme;
> kullanıcı kararı beklenir (bilinçli düzeltme gibi görünüyor → kullanıcı ayrı commit'ler, değilse
> `git checkout -- README.md`).

### Faz 9.5 · EN twin P4 slice-12 (bu tur — `07-Observability/{Prometheus-Grafana-K8s-Setup, Tracing-with-Tempo}` + `08-Security/*` ilk 3 · #56–60)
- **Dilim = P4 slice-12 (5 dosya), normal devam (kesintili-tur DEĞİL).** Tur başı `git status` TEMİZ, son
  commit `e4a22b9` (slice-11, conventional). I18N-COVERAGE "P4 — dilim planı" #56–60 (deterministik):
  `07-Observability/Prometheus-Grafana-K8s-Setup.md` (659s → `07-Observability` **tam twin 9/9**),
  `07-Observability/Tracing-with-Tempo.md` (334s), `08-Security/Container-Image-Scanning.md` (421s),
  `08-Security/Policy-as-Code-OPA-Kyverno.md` (482s), `08-Security/Runtime-Security.md` (448s).
  **Hepsi kalan 00-21 deep-dive'ları klasör sırasıyla** → `07-Observability` kalan 2 (`ls 07-Observability/*.md`
  ile teyit: README[P2] + Prometheus-Best-Practices/Alerting-Done-Right[P3] + SLO-Engineering[P4-s4] +
  Logs-Loki/OpenTelemetry/Pyroscope[slice-11] zaten twin; `.en.md`'siz kalan tam 2 → 07-Observability 9/9
  kapandı), sonra `08-Security` klasör sırasında `.en.md`'siz ilk 3 (`ls 08-Security/*.md`: README[P2] +
  Kubernetes-Hardening[P3] + Threat-Modeling[P3] + Secrets-Management[P3] + DevSecOps-Pipeline[P3] zaten twin;
  `.en.md`'siz kalan 5'in ilk 3'ü bu dilim; SLSA-and-SBOM + Zero-Trust-Networking → slice-13).
- **⚠️ Prometheus-Grafana-K8s-Setup iç ToC (anchor-linkli):** dosya `## 📋 İçindekiler` bloğunda 8 girdi
  emoji-prefiksli `## <emoji> Başlık`'lara anchor-link veriyor (`](#`=8). Subagent'a başlıkları çevirdikten
  sonra **her ToC anchor'ını GitHub-slug ile yeniden üret** talimatı verildi → 8/8 çözülüyor
  (`#system-requirements`/`#prerequisites`/`#installation-steps`/`#existing-installation-check`/
  `#service-configuration`/`#access-and-usage`/`#troubleshooting`/`#useful-commands`, bağımsız cross-check ile
  teyit: her anchor bir `## <emoji> Başlık`'a denk). **Diğer 4 dosyada anchor-ToC yok** (`](#`=0, `{ #`=0).
- **5 paralel çeviri subagent (dosya başına bir, sonnet) — P0…P4 slice-11 deseni (20. kez).** Oturmuş
  genişletilmiş ruleset baştan verildi + aynı-klasör gold-standard referans (`07-Observability/Prometheus-Best-Practices.en.md` +
  `OpenTelemetry-Adoption.en.md` + `README.en.md`, `08-Security/Kubernetes-Hardening.en.md` + `Threat-Modeling.en.md` +
  `DevSecOps-Pipeline.en.md` + `README.en.md`) → remediation gerekmedi, ilk çeviride doğru.
- **Plain/untagged blok prose doğru çevrildi:** Prometheus-Grafana ASCII/checklist etiketleri + kod-yorumu
  `# Sadece CRITICAL/HIGH`→`# Only CRITICAL/HIGH` + status-script prose + Grafana patch fake-value
  `"yeni-sifre"`→`"new-password"` (kaynakta zaten sahte değer; `admin123!` anti-pattern örneği verbatim);
  Container-Image-Scanning anti-pattern tablo başlığı `Niye kötü`→`Why it's bad`/`Doğru`→`Correct`;
  Policy-as-Code admission-flow + promotion ASCII diyagram etiketleri (`Kullanıcı`→`User`/`7 gün`→`7 days`,
  box-char sabit) + Rego `msg` string kaynakta zaten EN → dokunulmadı; Runtime-Security Falco `desc:`/`output:`
  prose string çevrildi + ASCII diyagram etiketi; `%X`→`X%`, `dk`→`min`. **Yalnız gerçek verbatim-artifact
  korundu:** Trivy/Grype/Snyk (`trivy image`/`--severity CRITICAL,HIGH`/`--ignore-unfixed`/`--format sarif`/
  `--skip-db-update`) + SBOM/Cosign + CVE-id + severity (CRITICAL/HIGH); OPA/Rego (`package …`/
  `violation[{"msg": msg}]`/`input.review.object…`/`sprintf`) + Kyverno (`kind: ClusterPolicy`/
  `validationFailureAction: Enforce|Audit`) + Gatekeeper/ConstraintTemplate/`conftest`; Falco/Tetragon
  (`condition:`/`proc.name`/`evt.type`/`priority:` + seccomp/AppArmor/eBPF/syscall/Sysdig/Tracee); Tempo/OTel
  (`OTLPSpanExporter`/`OTLP`/`receivers:`/`exporters:`/`trace_id`/`span_id`/`traceparent`/Jaeger/Zipkin);
  Prometheus/Grafana/Helm (`helm install/repo/upgrade`/`kube-prometheus-stack`/`kubectl patch`/`kubectl get
  secret`/NodePort/PVC/`adminPassword`/`admin.existingSecret`); placeholder EN-kanonik (`<REGISTRY>`/`<APP>`/
  `<TAG>`/`<IMAGE>`/`<NAMESPACE>`/`<GRAFANA_ADMIN_PASSWORD>`/`<NS>`/`<WAZUH_MANAGER>`/`<TETRAGON_POD>`);
  link-target locale-eksiz (`Kubernetes-Hardening.md`, `SLSA-and-SBOM.md`, `OpenTelemetry-Adoption.md`,
  `Logs-Loki-vs-ELK.md`, `Prometheus-Best-Practices.md`, `../17-Templates/kyverno-policies/`).
- **Bağımsız orchestrator doğrulaması (subagent raporuna körü körüne güvenilmedi):** başlık paritesi 5/5
  (103/34/48/49/41), tablo 5/5 (12/12/39/36/59), fence 5/5 (46/30/36/40/32, twin==source), satır deltası
  **0/0/0/0/0 (tam byte-parite, prose-wrap yok)**, gerçek Türkçe kalıntısı **0** — `[ışğİŞĞçöü]` excl
  path/proper-noun = 0 (5/5) **VE** diakritiksiz TR-fonksiyon-kelime (`için|değil|kullan|hangi|niye|senaryo|
  adım|gerekir|yani|çünkü|olan|dosya|komut|nedir|sunar|şifre|güvenlik`) = 0 (5/5) **VE** render `<article>`
  gövdesi body-TR=0 (5 sayfa python HTML ayrıştırması ile teyit). Link locale-eksiz (0 `.en.md`/`.tr.md`
  sızıntısı, 5/5). Prometheus-Grafana ToC 8 anchor'ının 8'i de çevrilmiş başlığa çözülüyor (bağımsız slug cross-check).
- **Positioning/pazarlama grep bu dilim 0 hit (TR+EN).** `türkçe kaynak|turkish resource/guide/handbook|
  most comprehensive|en kapsamlı|\bROI\b|guarantee|garanti|maaş|salary` → hiçbir twin'de yok.
- **Placeholder güvenliği:** Grafana `adminPassword` twin'de `<GRAFANA_ADMIN_PASSWORD>` placeholder; patch
  `GF_SECURITY_ADMIN_PASSWORD` fake-değeri `"new-password"` (kaynağın `"yeni-sifre"` sahte değerinin çevirisi);
  `admin123!` yalnız anti-pattern örneği (kaynak==twin). Gerçek credential/IP yok.
- **build-docs.sh'e dokunulmadı** — 5 `.en.md` numaralı klasörde (`0[0-9]-*` `cp -r` özyineli) otomatik staged
  (doğrulandı: site_src'te 5 `.en.md` staged); iki-locale build (`build-docs.sh` + `python3 -m mkdocs build --clean`)
  exit 0, 5 sayfa `site/en/…` İngilizce render (body-TR=0), TR root sayfaları (default) korundu, `_planning`
  sızmadı (`find site -path '*_planning*'` = 0). EN kapsama %41.3 → %42.8 (143/334). **`07-Observability` tam
  twin (9/9); `08-Security` 8/10.**
- **QA exit 0 (1 UYARI = önceki turlardan kalan `docs/index.en.md` locale-twin FP, 29 kırık link/1 dosya).**
  Bu turun 5 twin'i **yeni kırık link 0**; sayı değişmedi.
- **Working-tree bu tur TEMİZ girdi** (` M README.md` yok). Commit: **7 kendi dosyam** = 5 yeni `.en.md`
  (P4 slice-12) + STATE + I18N-COVERAGE. Dosyalar tek tek `git add`, `git add -A` KULLANILMADI (§14.4).

### Faz 9.5 · EN twin P4 slice-11 (önceki tur — `03-IaC/{Pulumi-vs-Terraform, Terraform-Module-Layout}` + `07-Observability/*` ilk 3 · #51–55)
- **Dilim = P4 slice-11 (5 dosya), normal devam (kesintili-tur DEĞİL).** Tur başı `git status` TEMİZ, son
  commit `048b1b7` (slice-10, conventional). I18N-COVERAGE "P4 — dilim planı" #51–55 (deterministik):
  `03-IaC/Pulumi-vs-Terraform.md` (340s), `03-IaC/Terraform-Module-Layout.md` (473s → `03-IaC` **tam twin 7/7**),
  `07-Observability/Logs-Loki-vs-ELK.md` (339s), `07-Observability/OpenTelemetry-Adoption.md` (449s),
  `07-Observability/Profiling-with-Pyroscope.md` (275s). **Hepsi kalan 00-21 deep-dive'ları klasör sırasıyla** →
  `03-IaC` kalan 2 (`ls 03-IaC/*.md` ile teyit: README + Terraform-Best-Practices[slice-8] +
  Crossplane/Drift/OpenTofu[slice-10] zaten twin; `.en.md`'siz kalan tam 2 → 03-IaC 7/7 kapandı), sonra
  `07-Observability` klasör sırasında `.en.md`'siz ilk 3 (`ls 07-Observability/*.md`: README[P2] +
  Prometheus-Best-Practices[P3] + Alerting-Done-Right[P3] + SLO-Engineering[P4-s4] zaten twin;
  `.en.md`'siz kalan 5'in ilk 3'ü bu dilim; Prometheus-Grafana-K8s-Setup + Tracing-with-Tempo → slice-12).
- **Hiçbirinde anchor-linkli iç ToC yok** (5 dosyada `](#` = 0, `{ #` = 0) — slice-9 Mobile-CICD-Flutter ToC
  anchor-regen komplikasyonu bu dilimde YOK, daha basit.
- **5 paralel çeviri subagent (dosya başına bir, sonnet) — P0…P4 slice-10 deseni (19. kez).** Oturmuş
  genişletilmiş ruleset baştan verildi + aynı-klasör gold-standard referans (`03-IaC/Terraform-Best-Practices.en.md` +
  `OpenTofu-Migration.en.md` + `README.en.md`, `07-Observability/Prometheus-Best-Practices.en.md` +
  `SLO-Engineering.en.md` + `Alerting-Done-Right.en.md` + `README.en.md`) → remediation gerekmedi, ilk çeviride doğru.
- **Plain/untagged blok prose doğru çevrildi:** Pulumi decision-tree etiketleri + Mocha test bloğundaki
  natural-language string (`"S3 bucket adı doğru"`→`"S3 bucket name is correct"`, hata mesajı
  `Beklenen … gelen`→`Expected … got`); Terraform-Module-Layout dizin-ağacı entry'leri sabit + trailing
  `# comment` annotation çevrildi; Logs-Loki kod-yorumu `# Tüm log`→`# All logs`/`# %1 sample DEBUG, %100 ERROR`→
  `# 1% sample DEBUG, 100% ERROR` + anti-pattern tablo başlığı `Niye kötü`→`Why it's bad`/`Doğru`→`Correct approach`;
  OpenTelemetry ASCII mimari + trace-propagation diyagram etiketleri box-char sabit + anti-pattern başlığı;
  Pyroscope flame-graph diyagram etiketi + `[ ]` checklist + senaryo yürüyüşleri. Yüzde/birim `%X`→`X%`,
  `dk`→`min`, `saat`→`hour`, `gün`→`day`, `7/24`→`24/7`. **Yalnız gerçek verbatim-artifact korundu:**
  HCL/Terraform (`resource`/`module`/`variable`/`output`/`for_each`/`backend`/`terraform init/plan/apply`,
  dizin-ağacı `main.tf`/`variables.tf`/`outputs.tf`/`versions.tf`/`modules/`/`environments/`); Pulumi
  (`pulumi up/preview`/`Pulumi.yaml`/`Pulumi.<stack>.yaml`/`@pulumi/aws`/`pulumi.export`/ComponentResource/
  StackReference); LogQL (`{app="…"}`/`|=`/`|~`/`rate()`/`count_over_time`) + Loki/Grafana/Elasticsearch/
  Logstash/Kibana/OpenSearch/Fluentd/Fluent Bit/Promtail/Vector; OTel (`OTEL_EXPORTER_OTLP_ENDPOINT` +
  diğer `OTEL_*`, `OTLP`/Collector/`receivers:`/`processors:`/`exporters:`/`pipelines:`/`service.name`/
  semantic conventions/resource attributes, Jaeger/Tempo/Zipkin/Prometheus/Grafana); Pyroscope/pprof/
  flame-graph/eBPF/Parca + profil türü (CPU/heap/alloc/goroutine/mutex/block); placeholder EN-kanonik
  (`<VERSION>`/`<REGION>`/`<ACCOUNT>`/`<ORG>`/`<NAMESPACE>`/`<SERVICE>`/`<ENDPOINT>`/`<APP>`); link-target
  locale-eksiz (`Terraform-Best-Practices.md`, `OpenTofu-Migration.md`, `Crossplane-Intro.md`,
  `../22-Learning-Path/block-c-reproducibility/C3-terraform.md`, `OpenTelemetry-Adoption.md`,
  `Tracing-with-Tempo.md`, `Prometheus-Best-Practices.md`, `Logs-Loki-vs-ELK.md`,
  `../19-Compliance/Audit-Evidence-Automation.md`).
- **Bağımsız orchestrator doğrulaması (subagent raporuna körü körüne güvenilmedi):** başlık paritesi 5/5
  (25/40/36/37/29), tablo 5/5 (34/20/30/33/18), fence 5/5 (18/40/26/22/28, twin==source), satır deltası
  **0/0/0/0/0 (tam byte-parite, prose-wrap yok)**, gerçek Türkçe kalıntısı **0** — `[ışğİŞĞçöü]` excl
  path/proper-noun = 0 (5/5) **VE** diakritiksiz TR-fonksiyon-kelime (`için|değil|kullan|hangi|niye|senaryo|
  adım|gerekir|yani|çünkü|olan|dosya|komut|nedir|sunar`) = 0 (5/5) **VE** render `<article>` gövdesi body-TR=0
  (5 sayfa python HTML ayrıştırması ile teyit). Link locale-eksiz (0 `.en.md`/`.tr.md` sızıntısı, 5/5).
- **Positioning/pazarlama grep bu dilim 0 hit (TR+EN).** `türkçe kaynak|turkish resource/guide/handbook|
  most comprehensive|en kapsamlı|\bROI\b|guarantee|garanti|maaş|salary` → hiçbir twin'de yok.
- **build-docs.sh'e dokunulmadı** — 5 `.en.md` numaralı klasörde (`0[0-9]-*` `cp -r` özyineli) otomatik staged
  (doğrulandı: site_src'te 5 `.en.md` staged); iki-locale build (`build-docs.sh` + `python3 -m mkdocs build --clean`)
  exit 0, 5 sayfa `site/en/…` İngilizce render (body-TR=0), TR root sayfaları (default) korundu, `_planning`
  sızmadı (`find site -path '*_planning*'` = 0). EN kapsama %39.8 → %41.3 (138/334). **`03-IaC` tam twin
  (7/7); `07-Observability` 7/9.**
- **QA exit 0 (1 UYARI = önceki turlardan kalan `docs/index.en.md` locale-twin FP, 29 kırık link/1 dosya).**
  Bu turun 5 twin'i **yeni kırık link 0**; sayı değişmedi.
- **Working-tree bu tur TEMİZ girdi** (` M README.md` yok). Commit: **7 kendi dosyam** = 5 yeni `.en.md`
  (P4 slice-11) + STATE + I18N-COVERAGE. Dosyalar tek tek `git add`, `git add -A` KULLANILMADI (§14.4).

### Faz 9.5 · EN twin P4 slice-10 (önceki tur — `02-CI-CD/{Pipeline-Performance, Reusable-Workflows}` + `03-IaC/*` ilk 3 · #46–50)
- **Dilim = P4 slice-10 (5 dosya), normal devam (kesintili-tur DEĞİL).** Tur başı `git status` TEMİZ, son
  commit `6d3d791` (slice-9, conventional). I18N-COVERAGE "P4 — dilim planı" #46–50 (deterministik):
  `02-CI-CD/Pipeline-Performance.md` (408s → `02-CI-CD` 7/8), `02-CI-CD/Reusable-Workflows.md` (383s →
  `02-CI-CD` **tam twin 8/8**), `03-IaC/Crossplane-Intro.md` (379s), `03-IaC/Drift-Detection.md` (330s),
  `03-IaC/OpenTofu-Migration.md` (283s). **Hepsi kalan 00-21 deep-dive'ları klasör sırasıyla** → `02-CI-CD`
  kalan 2 (`ls 02-CI-CD/*.md` ile teyit: `.en.md`'siz kalan tam 2 → 02-CI-CD 8/8 kapandı), sonra `03-IaC`
  klasör sırasında `.en.md`'siz ilk 3 (`ls 03-IaC/*.md`: README + Terraform-Best-Practices[slice-8] zaten twin;
  `.en.md`'siz kalan 5'in ilk 3'ü bu dilim; Pulumi-vs-Terraform + Terraform-Module-Layout → slice-11).
- **Hiçbirinde anchor-linkli iç ToC yok** (5 dosyada `](#` = 0, `{ #` = 0) — slice-9 Mobile-CICD-Flutter ToC
  anchor-regen komplikasyonu bu dilimde YOK, daha basit.
- **5 paralel çeviri subagent (dosya başına bir, sonnet) — P0…P4 slice-9 deseni (18. kez).** Oturmuş
  genişletilmiş ruleset baştan verildi + aynı-klasör gold-standard referans (`02-CI-CD/Pipeline-Patterns.en.md` +
  `README.en.md` + `GitHub-Actions-Recipes.en.md`, `03-IaC/README.en.md` + `Terraform-Best-Practices.en.md`) →
  remediation gerekmedi, ilk çeviride doğru.
- **Plain/untagged blok prose doğru çevrildi:** Pipeline-Performance ASCII test-pyramid + karar-ağacı etiketleri
  (`EVET`→`YES`/`HAYIR`→`NO`, box-char sabit) + kod-yorumu `# stop if one branch breaks`/`# record the duration`;
  Reusable-Workflows yorum `# special repo`/`# appears in the template UI`/`# each repo` + `[ ]` checklist label +
  anti-pattern tablo başlığı `Niye kötü`→`Why it's bad`/`Doğru`→`Correct`; Crossplane karar-ağacı `YES` etiketi;
  Drift-Detection `[ ]` label + anti-pattern `Correct`; OpenTofu prose. Yüzde/birim `%X`→`X%`, `dk`→`min`.
  **Yalnız gerçek verbatim-artifact korundu:** GH-Actions reusable/composite (`uses:`/`with:`/`inputs:`/`outputs:`/
  `secrets:`/`workflow_call`/`${{ }}`/`secrets.`/`permissions:`/`runs: using: composite`, SHA-pin `uses:` ref);
  HCL/Terraform (`terraform plan -detailed-exitcode`/`refresh`/`state`/`apply`, `resource`/`module`/`backend`/
  `lifecycle`); drift tool adı (`driftctl`/`Atlantis`/`env0`/`Spacelift`); Crossplane CRD (`Composition`/
  `CompositeResourceDefinition`/`XRD`/`Claim`/`ProviderConfig`/`ManagedResource`, `apiVersion:`/`kind:`/`spec:`/
  `metadata:`, `provider-aws`/`upbound/…`, `kubectl`/`crossplane` CLI); OpenTofu lisans/org proper-noun (`BSL`/
  `Business Source License`/`MPL 2.0`/`Mozilla Public License`/`HashiCorp`/`OpenTofu`/`tofu`/`terraform`/
  `Linux Foundation`/`CNCF`) + 2023 (lisans değişimi) + 2026 (frontmatter) tarihleri; placeholder EN-kanonik
  (`<VERSION>`/`<REGION>`/`<KMS_KEY_ID>`/`<REGISTRY>`/`<TFSTATE_BUCKET>`/`<ORG>`/`<ACCOUNT>`); link-target
  locale-eksiz (`Pipeline-Patterns.md`, `../01-Git-Workflow/Trunk-Based-Development.md`, `Terraform-Best-Practices.md`,
  `Drift-Detection.md`, `OpenTofu-Migration.md`).
- **Bağımsız orchestrator doğrulaması (subagent raporuna körü körüne güvenilmedi):** başlık paritesi 5/5
  (49/22/29/49/45), tablo 5/5 (3/2/2/3/2), fence 5/5 (46/24/26/24/24, twin==source), satır deltası
  **0/0/0/0/0 (tam byte-parite, prose-wrap yok)**, gerçek Türkçe kalıntısı **0** — `[ışğİŞĞçöü]` excl
  path/proper-noun = 0 (5/5) **VE** diakritiksiz TR-fonksiyon-kelime (`için|değil|kullan|hangi|niye|senaryo|
  adım|gerekir|yani|çünkü|olan|dosya|komut`) = 0 (5/5) **VE** render `<article>` gövdesi body-TR=0
  (Pipeline-Performance + OpenTofu-Migration python HTML ayrıştırması ile teyit). Link locale-eksiz
  (0 `.en.md`/`.tr.md` sızıntısı, 5/5).
- **Positioning/pazarlama grep bu dilim 0 hit (TR+EN).** `türkçe kaynak|turkish resource/guide/handbook|
  most comprehensive|en kapsamlı|\bROI\b|guarantee|garanti|maaş|salary` → hiçbir twin'de yok.
- **build-docs.sh'e dokunulmadı** — 5 `.en.md` numaralı klasörde (`0[0-9]-*` `cp -r` özyineli) otomatik staged
  (doğrulandı: site_src'te 5 `.en.md` staged); iki-locale build (`build-docs.sh` + `python3 -m mkdocs build --clean`)
  exit 0, 5 sayfa `site/en/…` İngilizce render (body-TR=0), TR root sayfaları (default) korundu, `_planning`
  sızmadı (`find site -path '*_planning*'` = 0). EN kapsama %38.3 → %39.8 (133/334). **`02-CI-CD` tam twin
  (8/8); `03-IaC` 5/7.**
- **QA exit 0 (1 UYARI = önceki turlardan kalan `docs/index.en.md` locale-twin FP, 29 kırık link/1 dosya).**
  Bu turun 5 twin'i **yeni kırık link 0**; sayı değişmedi.
- **Working-tree bu tur TEMİZ girdi** (` M README.md` yok). Commit: **7 kendi dosyam** = 5 yeni `.en.md`
  (P4 slice-10) + STATE + I18N-COVERAGE. Dosyalar tek tek `git add`, `git add -A` KULLANILMADI (§14.4).

### Faz 9.5 · EN twin P4 slice-9 (önceki tur — `00-Culture/Team-Topologies` + `02-CI-CD/*` kalan 4 · #41–45)
- **Dilim = P4 slice-9 (5 dosya), normal devam (kesintili-tur DEĞİL).** Tur başı `git status` TEMİZ, son
  commit `0a8a788` (slice-8, conventional). I18N-COVERAGE "P4 — dilim planı" #41–45 (deterministik):
  `00-Culture/Team-Topologies.md` (295s → `00-Culture` **tam twin 8/8**), `02-CI-CD/Caching-Strategies.md`
  (382s), `02-CI-CD/GitHub-Actions-Recipes.md` (434s), `02-CI-CD/GitLab-CI-Recipes.md` (396s),
  `02-CI-CD/Mobile-CICD-Flutter.md` (927s). #41 dilim planından (Team-Topologies `00-Culture`'ı tamamlar);
  **#42–45 = kalan 00-21 deep-dive'ları klasör sırasıyla** → `01-Linux-Networking` tam twin (`.en.md`'siz dosya
  yok → atlandı), `02-CI-CD` sırada (`ls 02-CI-CD/*.md` ile teyit: `.en.md`'siz 4 = Caching/GH-Actions/GitLab/
  Mobile; Pipeline-Patterns[P3]+README[P2] zaten twin; Pipeline-Performance+Reusable-Workflows → slice-10).
- **5 paralel çeviri subagent (dosya başına bir, sonnet) — P0…P4 slice-8 deseni (17. kez).** Oturmuş
  genişletilmiş ruleset baştan verildi + aynı-klasör gold-standard referans (`00-Culture/README.en.md` +
  `On-Call-Playbook.en.md`, `02-CI-CD/Pipeline-Patterns.en.md` + `README.en.md`) → remediation gerekmedi,
  ilk çeviride doğru.
- **⚠️ Mobile-CICD-Flutter iç ToC (anchor-linkli):** dosya `## 📑 İçindekiler` → `## Table of Contents` ile
  açılıyor, 8 girdi numaralı `## N. Başlık`'lara anchor-link veriyor. Subagent'a başlıkları çevirdikten sonra
  **her ToC anchor'ını GitHub-slug ile yeniden üret** talimatı verildi → 8/8 çözülüyor (`#1-accounts-and-memberships`
  … `#8-total-cost-breakdown`, bağımsız cross-check ile teyit: her anchor bir `## N.` başlığına denk).
- **Plain/untagged blok prose doğru çevrildi:** Team-Topologies 2 org-diyagram etiketi (box-char sabit);
  Caching kod-yorumu `# Or:`/`# Cargo target + registry cache`/`# -count=1 disables cache; in production…`;
  GH-Actions `# required for OIDC`/`# automatic node_modules cache`/`# cancel the old run when a new commit arrives`
  + anti-pattern tablo başlığı `Niye kötü`→`Why it's bad`/`Doğru`→`Correct` + 10 satır hücre; GitLab CI yorum/prose;
  Mobile keystore `⚠️` warning prose + `[ ]` label + "Information You'll Be Asked For" listesi. Yüzde/birim
  `%X`→`X%`, `dk`→`min`, `hafta`→`week`. **Yalnız gerçek verbatim-artifact korundu:** Conway's Law/Skelton & Pais/
  *Team Topologies*/Spotify + takım-türü adları (`stream-aligned`/`enabling`/`complicated-subsystem`/`platform` +
  etkileşim modu `Collaboration`/`X-as-a-Service`/`Facilitating`); GH-Actions YAML (`uses:`/`with:`/`permissions:`/
  `${{ }}`/`secrets.`/`id-token: write`, SHA-pin/`<VERSION>` policy); GitLab CI (`$CI_*`/`stages:`/`rules:`/`cache:`/
  `&`anchor/`*`alias/`extends:`); cache token (`actions/cache@`/`--mount=type=cache`/`--cache-from`/`gha`); Flutter/
  Fastlane/Gradle (`keytool -genkey -v -keystore`/`build.gradle`/`key.properties`/`pubspec.yaml`/`.jks`/`.p12`/
  `.mobileprovision`/`Fastfile`/`Podfile`) + servis adı (Firebase/App Store Connect/Google Play Console/Codemagic) +
  bundle-id `com.onmuhasebe.mobile` (kaynak-sadık örnek, 5 kaynakta/5 twin'de — yeni leak değil, reverse-domain app
  identifier); link-target (`SLI-SLO-Error-Budget.md`, `Stakeholder-Management.md`, `../22-Learning-Path/…/F3-platform-idp.md`,
  `Pipeline-Performance.md`, `GitHub-Actions-Recipes.md` dahil locale-eksiz).
- **Bağımsız orchestrator doğrulaması (subagent raporuna körü körüne güvenilmedi):** başlık paritesi 5/5
  (30/44/22/24/93), tablo 5/5 (19/13/12/13/25), fence 5/5 (4/56/32/28/52, twin==source), satır deltası
  0/0/0/0/-1 (Mobile trailing-nl), gerçek Türkçe kalıntısı **0** — `[ışğİŞĞçöü]` excl path/Istanbul = 0 (5/5)
  **VE** diakritiksiz TR-fonksiyon-kelime (`için|değil|kullan|hangi|niye|senaryo|adım|gerekir|üye|hesaplar|…`)
  = 0 (5/5) **VE** render `<article>` gövdesi body-TR=0 (Team-Topologies python HTML ayrıştırması ile teyit).
  Link locale-eksiz (0 `.en.md`/`.tr.md` sızıntısı, 5/5).
- **Positioning/pazarlama grep bu dilim 0 hit (TR+EN).** `türkçe kaynak|turkish resource/guide/handbook|
  most comprehensive|en kapsamlı|\bROI\b|guarantee|garanti|maaş|salary` → hiçbir twin'de yok.
- **build-docs.sh'e dokunulmadı** — 5 `.en.md` numaralı klasörde (`0[0-9]-*` `cp -r` özyineli) otomatik staged
  (doğrulandı: site_src'te 5 `.en.md` staged); iki-locale build (`build-docs.sh` + `python3 -m mkdocs build --clean`)
  exit 0, 5 sayfa `site/en/…` İngilizce render (body-TR=0, Team-Topologies `<article>` TR-token=0), TR root
  sayfaları (default) korundu, `_planning` sızmadı. EN kapsama %36.8 → %38.3 (128/334). **`00-Culture` tam twin
  (8/8); `02-CI-CD` 6/8.**
- **QA exit 0 (1 UYARI = önceki turlardan kalan `docs/index.en.md` locale-twin FP, 29 kırık link/1 dosya).**
  Bu turun 5 twin'i **yeni kırık link 0**; sayı değişmedi.
- **Working-tree bu tur TEMİZ girdi** (` M README.md` yok). Commit: **7 kendi dosyam** = 5 yeni `.en.md`
  (P4 slice-9) + STATE + I18N-COVERAGE. Dosyalar tek tek `git add`, `git add -A` KULLANILMADI (§14.4).

### Faz 9.5 · EN twin P4 slice-8 (önceki tur — `04-Containers/Multi-Stage-Builds` + `03-IaC/Terraform-Best-Practices` + `00-Culture/*` ilk 3 · #36–40)
- **Dilim = P4 slice-8 (5 dosya), normal devam (kesintili-tur DEĞİL).** Tur başı `git status` TEMİZ, son
  commit `f4ee132` (slice-7, conventional). I18N-COVERAGE "P4 — dilim planı" #36–40 (deterministik):
  `04-Containers/Multi-Stage-Builds.md` (377s → `04-Containers` **tam twin 7/7**), `03-IaC/Terraform-Best-Practices.md`
  (573s), `00-Culture/Documentation-Culture.md` (311s), `00-Culture/DORA-SPACE-Metrics.md` (306s),
  `00-Culture/On-Call-Playbook.md` (286s). #36–37 dilim planından (Multi-Stage-Builds `04-Containers`'ı tamamlar,
  Terraform-Best-Practices güçlü pick); **#38–40 = kalan 00-21 deep-dive'ları klasör sırasıyla** → 00-Culture ilk
  (`ls` ile teyit: 00-Culture'da `.en.md`'siz 4 kaldı — Documentation-Culture, DORA-SPACE-Metrics, On-Call-Playbook,
  Team-Topologies; ilk 3 bu dilim, Team-Topologies → slice-9; 01-Linux-Networking `.en.md`'siz dosya yok → atlandı).
- **5 paralel çeviri subagent (dosya başına bir, sonnet) — P0…P4 slice-7 deseni (16. kez).** Oturmuş
  genişletilmiş ruleset baştan verildi + aynı-klasör gold-standard referans (`04-Containers/Dockerfile-Best-Practices.en.md`,
  `03-IaC/README.en.md`, `00-Culture/Blameless-Postmortem-Template.en.md`) → remediation gerekmedi, ilk çeviride doğru.
- **Plain/untagged blok prose doğru çevrildi:** Multi-Stage Dockerfile code-yorumu `# Build stage`/`# Runtime stage`
  + anti-pattern/base-image tablo prose hücreleri; Documentation-Culture **ADR-0042 + RFC-0017 ```markdown template**
  prose'u (`## Context`/`## Decision`/`## Consequences`/`## Alternatives Considered`, `99.99% SLA built-in`, `Cost +30%`,
  `Superseded`/`Accepted` durum etiketi) çevrildi, kimlik/tarih (`@author`/`@reviewer1`/`2026-04-15`) verbatim;
  DORA-SPACE 5 tablo prose hücresi (`Elite`/`High`/`Medium`/`Low` seviye + `N times per day (on-demand)`/`Daily-weekly`/
  `< 1 hour` süre) çevrildi, metric adları sabit; On-Call-Playbook `[ ]` runbook/handoff checklist + escalation-flow
  etiketleri İngilizce. Yüzde/birim `%99.99`→`99.99%`, `dk`→`min`, `hafta`→`week`, `saat`→`hour`.
  **Yalnız gerçek verbatim-artifact korundu:** Dockerfile talimatı (`FROM golang:1.23 AS builder`/`FROM
  gcr.io/distroless/static-debian12:nonroot`/`COPY --from=builder`/`USER nonroot:nonroot`/`ENTRYPOINT`/`WORKDIR`/`RUN`)
  + image ref (`golang:1.23`/`gcr.io/distroless/<TYPE>:nonroot`) + placeholder (`<LANG>`/`<VERSION>`/`<TYPE>`);
  HCL/Terraform (`resource`/`module`/`variable`/`output`/`for_each`/`count`/`backend "s3"`/`lifecycle`,
  `terraform plan/apply/state`) + placeholder (`<COMPANY>`/`<ACCOUNT>`/`<REGION>`/`<AMI>`/`<ORG>`); DORA/SPACE metric
  adları (`Deployment Frequency`/`Lead Time for Changes`/`Change Failure Rate`/`Time to Restore`/`MTTR`/`SPACE` +
  `S/P/A/C/E` sütun kodları); on-call tool adı (PagerDuty/Opsgenie/Grafana OnCall/incident.io/FireHydrant/Rootly/
  Statuspage.io/Cachet) + severity `SEV-1..SEV-4`; ADR/RFC tool adı (adr-tools/MADR) + `docs/adr/` path; link-target
  (`Blameless-Postmortem-Template.md`, `../11-SRE/Incident-Response.md`, `../22-Learning-Path/…/F4-yazma-adr-rfc.md`,
  `../08-Security/Container-Image-Scanning.md`, `../22-Learning-Path/block-c-reproducibility/C1-container.md` dahil
  locale-eksiz).
- **Bağımsız orchestrator doğrulaması (subagent raporuna körü körüne güvenilmedi):** başlık paritesi 5/5
  (35/53/42/26/36), tablo 5/5 (20/20/19/31/12), fence 5/5 (38/34/14/12/12, twin==source), satır deltası
  0/0/+1/0/0 (Documentation-Culture prose-wrap), gerçek Türkçe kalıntısı **0** — `[ışğİŞĞçöü]` excl path/Istanbul
  = 0 (5/5) **VE** diakritiksiz TR-fonksiyon-kelime (`için|değil|kullan|hangi|niye|senaryo|adım|gerekir|yani|olan|
  çünkü|nöbet|imaj`) = 0 (5/5). Link locale-eksiz (0 `.en.md`/`.tr.md` sızıntısı, 5/5).
- **Positioning/pazarlama grep bu dilim 0 hit (TR+EN).** `türkçe kaynak|turkish resource/guide/handbook|
  most comprehensive|en kapsamlı|\bROI\b|guarantee|garanti|maaş|salary` → hiçbir twin'de yok.
- **build-docs.sh'e dokunulmadı** — 5 `.en.md` numaralı klasörde (`0[0-9]-*` `cp -r` özyineli) otomatik staged
  (doğrulandı: site_src'te 5 `.en.md` staged); iki-locale build (`build-docs.sh` + `python3 -m mkdocs build --clean`)
  exit 0, 5 sayfa İngilizce render (EN-marker-lines 149/104/123/128/136), TR root sayfaları (default) korundu,
  `_planning` sızmadı. EN kapsama %35.3 → %36.8 (123/334). **`04-Containers` tam twin (7/7); `00-Culture` 4/8.**
- **QA exit 0 (1 UYARI = önceki turlardan kalan `docs/index.en.md` locale-twin FP, 29 kırık link/1 dosya).**
  Bu turun 5 twin'i **yeni kırık link 0**; sayı değişmedi.
- **Working-tree bu tur TEMİZ girdi** (` M README.md` yok). Commit: **7 kendi dosyam** = 5 yeni `.en.md`
  (P4 slice-8) + STATE + I18N-COVERAGE. Dosyalar tek tek `git add`, `git add -A` KULLANILMADI (§14.4).

### Faz 9.5 · EN twin P4 slice-7 (önceki tur — `04-Containers/*` kalan 6'nın ilk 5 · #31–35)
- **Dilim = P4 slice-7 (5 dosya), normal devam (kesintili-tur DEĞİL).** Tur başı `git status` TEMİZ, son
  commit `9324c1e` (slice-6, conventional). I18N-COVERAGE "P4 — dilim planı" #31–35 (deterministik):
  `04-Containers/BuildKit-Tips.md` (359s), `Container-vs-WASM.md` (337s), `Distroless-and-Chainguard.md` (271s),
  `Dockerfile-Best-Practices.md` (444s), `Image-Signing-Cosign.md` (289s) = `04-Containers` deep-dive'larının
  kalan 6'sının ilk 5'i (`ls 04-Containers/*.md` ile teyit: `.en.md`'siz kalan tam 6; 6. `Multi-Stage-Builds.md`
  → slice-8). README önceki turlarda twin'liydi → **04-Containers bu turla 6/7.**
- **5 paralel çeviri subagent (dosya başına bir, sonnet) — P0…P4 slice-6 deseni (15. kez).** Oturmuş
  genişletilmiş ruleset baştan verildi + aynı-klasör gold-standard referans `04-Containers/README.en.md`
  (+ `05-Kubernetes/Resource-Limits-Guide.en.md`) → remediation gerekmedi, ilk çeviride doğru.
- **Plain/untagged blok prose doğru çevrildi:** Dockerfile code-yorumu `# ❌ Kötü: tüm araçlar imajda kalır`→
  `# ❌ Bad: all tools stay in the image` / `# ✅ İyi: build artifact'ı temiz imaja kopyala`→`# ✅ Good: copy the
  build artifact into a clean image` (emoji-işaretli marker sabit, `# ✅ Exec form` gibi) + anti-pattern/base-image
  tablo hücreleri (`Çok`→`Many`/`Az`→`Few`/`kaçın`→`avoid`/`uygun`→`suitable`/`production sweet spot` sabit);
  BuildKit `# Single build`/`# Daemon-wide (default on Docker 23+)`/`# buildx (multi-platform)`/`# Use TARGETPLATFORM
  for cross-compilation` yorumları; Image-Signing `İmzasız imaj cluster'a girer`→`Unsigned image → deploy rejected`;
  `[ ]` checklist label metni İngilizce. Yüzde/birim `%X`→`X%`, `dk`→`min`, `hafta`→`week`.
  **Yalnız gerçek verbatim-artifact korundu:** image ref (`gcr.io/distroless/static-debian12`/`gcr.io/distroless/base`/
  `cgr.dev/chainguard/*`/`wolfi-base`/`ubuntu:22.04`/`:20-alpine`/`USER 65532`) — bunlar registry path/tag, çeviri değil
  → aynen; Dockerfile talimatları (`FROM`/`RUN`/`COPY`/`ADD`/`USER`/`WORKDIR`/`ENTRYPOINT`/`CMD`/`HEALTHCHECK`/`ARG`/`ENV`)
  + flag (`--chown`/`--from`/`--mount`); BuildKit token (`--mount=type=cache`/`secret`/`ssh`, `# syntax=docker/dockerfile:1.7`,
  `buildx`, `--platform linux/amd64,linux/arm64`, `DOCKER_BUILDKIT`, cache backend `registry`/`gha`/`local`/`inline`);
  Wasm ekosistemi (`Spin`/`wasmCloud`/`Fermyon`/`WASI`/`wasmtime`/`WasmEdge`/`component model`/`.wasm`/`spin up`);
  Cosign/Sigstore (`cosign sign/verify`, `Fulcio`/`Rekor`/`keyless`/`OIDC`/`SBOM`/`SLSA`/`Kyverno verifyImages`/
  `validationFailureAction: Enforce`/`ClusterPolicy`) + digest (`sha256:…`) + SHA-pin action ref; path/URL; link-target
  (`../08-Security/Policy-as-Code-OPA-Kyverno.md` dahil locale-eksiz).
- **Bağımsız orchestrator doğrulaması (subagent raporuna körü körüne güvenilmedi):** başlık paritesi 5/5
  (45/29/37/68/23), tablo 5/5 (21/55/33/29/16), fence 5/5 (58/22/20/50/20, twin==source), satır deltası
  0/+1/0/0/+1 (Container-vs-WASM/Image-Signing trailing-nl+prose-wrap), gerçek Türkçe kalıntısı **0** — rendered
  article `<article>` gövdesi body-TR=0 (5/5, python HTML ayrıştırması ile teyit) **VE** `[ışğİŞĞçöü]` excl
  path/Istanbul + diakritiksiz TR-fonksiyon-kelime (`için|değil|kullan|hangi|niye|senaryo|adım|gerekir|yani|olan`)
  = 0 (5/5). Link locale-eksiz (0 `.en.md`/`.tr.md` sızıntısı, 5/5).
- **Positioning/pazarlama grep bu dilim 0 hit (TR+EN).** `türkçe kaynak|turkish resource/guide/handbook|
  most comprehensive|en kapsamlı|\bROI\b|guarantee|garanti|maaş|salary` → hiçbir twin'de yok. Bu 5 kaynak
  teknik-artifact yoğun (Dockerfile/YAML/tablo/komut/image-ref); slice-6'nın QoS `Guaranteed` + FinOps ROI FP'si
  burada yok.
- **build-docs.sh'e dokunulmadı** — 5 `.en.md` numaralı klasörde (`0[0-9]-*` `cp -r` özyineli) otomatik staged
  (doğrulandı: `site_src/04-Containers/` altında 5 `.en.md` staged); iki-locale build (`build-docs.sh` + `python3
  -m mkdocs build --clean`) exit 0, 5 sayfa `/en/04-Containers/…/` İngilizce render (EN-marker 404/315/394/473/355,
  body-TR=0), TR root sayfaları (default) korundu, `_planning` sızmadı. EN kapsama %33.8 → %35.3 (118/334).
  mkdocs WARNING satırları (CLAUDE.md link, RoadMap anchor, i18n switcher/homepage) önceki durumdan, bu dilimden değil.
- **QA exit 0 (1 UYARI = önceki turlardan kalan `docs/index.en.md` locale-twin FP, 29 kırık link/1 dosya).**
  Bu turun 5 twin'i **yeni kırık link 0**; sayı değişmedi.
- **Working-tree bu tur TEMİZ girdi** (` M README.md` yok). Commit: **7 kendi dosyam** = 5 yeni `.en.md`
  (P4 slice-7) + STATE + I18N-COVERAGE. Dosyalar tek tek `git add`, `git add -A` KULLANILMADI (§14.4).

### Faz 9.5 · EN twin P4 slice-6 (önceki tur — `05-Kubernetes/*` kalan 5 · #26–30)
- **Dilim = P4 slice-6 (5 dosya), normal devam (kesintili-tur DEĞİL).** Tur başı `git status` TEMİZ, son
  commit `50a7a15` (slice-5, conventional). I18N-COVERAGE "P4 — dilim planı" #26–30 (deterministik):
  `05-Kubernetes/HPA-VPA-KEDA.md` (418s), `Multi-Tenancy-Patterns.md` (352s), `Production-Checklist.md` (513s),
  `Resource-Limits-Guide.md` (354s), `Upgrade-Strategy.md` (341s) = `05-Kubernetes` deep-dive'larının kalan 5'i
  → **05-Kubernetes bu turla tam twin (7/7)** (`ls 05-Kubernetes/*.md` ile teyit: `.en.md`'siz kalan tam bu 5;
  README + Debugging-Pods önceki turlar).
- **5 paralel çeviri subagent (dosya başına bir, sonnet) — P0…P4 slice-5 deseni (14. kez).** Oturmuş
  genişletilmiş ruleset baştan verildi + aynı-klasör gold-standard referans `05-Kubernetes/Debugging-Pods.en.md`
  → remediation gerekmedi, ilk çeviride doğru.
- **Plain/untagged blok prose doğru çevrildi:** HPA-VPA-KEDA code-yorumu `# CPU 70% target`/`# fast scale up`/
  `# wait 5 min`/`# max 2x` (marker sabit) + `%70`→`70%` yüzde konvansiyonu; Production-Checklist **çok sayıda
  `[ ]` checklist label** metni İngilizce'ye çevrildi + item-code anchor'ları (A2/D4/C1-C5/E1-E6/F1) sabit +
  QoS-blok ASCII prose (`Request = guaranteed minimum`); Resource-Limits-Guide PromQL yorumu `# CPU p95 (1 hafta)`
  →`# (1 week)` + QoS anlatı; Upgrade-Strategy blue/green ASCII diyagram etiketleri + timeline `Hafta`→`Week`
  (Week 1–4)/`Adım`→`Step` + kapanış italiği + epigraf. Yüzde/birim `%40`→`40%`, `dk`→`min`, `hafta`→`week`.
  **Yalnız gerçek verbatim-artifact korundu:** K8s QoS class literal string'leri (`Guaranteed`/`Burstable`/
  `BestEffort`) — bunlar QoS class adı, çeviri değil → aynen; status/reason (`OOMKilled`/`Evicted`/`Pending`/
  `CrashLoopBackOff`); CRD/kind (`HorizontalPodAutoscaler`/`VerticalPodAutoscaler`/`ScaledObject`/
  `PodDisruptionBudget`/`ResourceQuota`/`LimitRange`/`NetworkPolicy`/`Role`/`RoleBinding`); KEDA/vcluster/Capsule/
  Hierarchical-Namespace tenancy araçları; resource unit (`250m`/`512Mi`/`1Gi`); `{{...}}` + `Europe/Istanbul` tz
  YAML value; kubeadm/eksctl/gcloud/az komut+flag; API group (`autoscaling/v2`, `networking.k8s.io/v1`);
  link-target (`../08-Security/…`, `Production-Checklist.md` dahil locale-eksiz).
- **Bağımsız orchestrator doğrulaması (subagent raporuna körü körüne güvenilmedi):** başlık paritesi 5/5
  (36/34/74/42/60), tablo 5/5 (23/18/36/23/13), fence 5/5 (40/26/62/34/34, twin==source), satır deltası
  -1/0/0/0/+1 (prose-wrap), gerçek Türkçe kalıntısı **0** — rendered article `<article>` gövdesi body-TR=0
  (5/5, python HTML ayrıştırması ile teyit; sayfadaki 7 TR-token tamamen nav/theme chrome'da, Aşama A kısmi
  i18n beklenen) **VE** `[ışğİŞĞ]` excl path/Istanbul + diakritiksiz TR-fonksiyon-kelime (`için|değil|kullan|
  hangi|niye|senaryo|adım|gerekir`) = 0 (5/5). Link locale-eksiz (0 `.en.md`/`.tr.md` sızıntısı, 5/5).
- **Positioning/pazarlama grep hit = kaynak-sadık FP (dokunulmadı), qa scope dışı.** `Guaranteed`/`guaranteed`
  hitleri = K8s **QoS class `Guaranteed`** (kaynakta Production-Checklist 3, Resource-Limits 7) + "guaranteed
  minimum/during voluntary disruption" teknik prose; `Multi-Tenancy-Patterns.en.md:246 "For high-ROI customers"`
  = kaynak:246 `ROI yüksek müşteri için` (ROI kaynakta zaten var, uydurma değil). qa.py `check_marketing` yalnız
  `22-Learning-Path/` tarar → `05-Kubernetes/*.en.md` kapsam DIŞI → flag'lemez, exit 0. (Önceki turların
  FinOps/Platform ROI + Chaos "guarantee" FP'siyle aynı belgeli desen.)
- **build-docs.sh'e dokunulmadı** — 5 `.en.md` numaralı klasörde (`0[0-9]-*` `cp -r` özyineli) otomatik staged
  (doğrulandı: 5 staged); iki-locale build (`build-docs.sh` + `python3 -m mkdocs build --clean`) exit 0, 5 sayfa
  `/en/05-Kubernetes/…/` İngilizce render (EN-marker 123/77/51/61/99, body-TR=0), TR root sayfaları (default)
  korundu, `_planning` sızmadı. EN kapsama %32.3 → %33.8 (113/334). mkdocs INFO satırları (RoadMap TR-anchor)
  önceki durumdan, bu dilimden değil.
- **QA exit 0 (1 UYARI = önceki turlardan kalan `docs/index.en.md` locale-twin FP, 29 kırık link/1 dosya).**
  Bu turun 5 twin'i **yeni kırık link 0**; sayı değişmedi.
- **Working-tree bu tur TEMİZ girdi** (` M README.md` yok). Commit: **7 kendi dosyam** = 5 yeni `.en.md`
  (P4 slice-6) + STATE + I18N-COVERAGE. Dosyalar tek tek `git add`, `git add -A` KULLANILMADI (§14.4).

### Faz 9.5 · EN twin P4 slice-5 (önceki tur — `06-GitOps/*` kalan 4 + `05-Kubernetes/*` ilk 1 · #21–25)
- **Dilim = P4 slice-5 (5 dosya), normal devam (kesintili-tur DEĞİL).** Tur başı `git status` TEMİZ, son
  commit `071a1de` (slice-4 finalize, conventional). I18N-COVERAGE "P4 — dilim planı" #21–25 (deterministik):
  `06-GitOps/ArgoCD-Setup.md` (548s), `Flux-vs-ArgoCD.md` (266s), `Helm-vs-Kustomize-vs-Raw.md` (510s),
  `Secrets-in-GitOps.md` (448s) = `06-GitOps` deep-dive'larının kalan 4'ü → **06-GitOps bu turla tam twin (7/7)**;
  `05-Kubernetes/Debugging-Pods.md` (347s) = `05-Kubernetes` klasör sırasında ilk `.en.md`'siz deep-dive
  (`ls 05-Kubernetes/*.md` ile teyit edildi: yalnız README.en.md vardı).
- **5 paralel çeviri subagent (dosya başına bir, sonnet) — P0…P4 slice-4 deseni (13. kez).** Oturmuş
  genişletilmiş ruleset baştan verildi + aynı-klasör gold-standard referans `06-GitOps/App-of-Apps-Pattern.en.md`
  (Debugging-Pods için ek `08-Security/Kubernetes-Hardening.en.md`) → remediation gerekmedi, ilk çeviride doğru.
- **Plain/untagged blok prose doğru çevrildi:** Secrets-in-GitOps araç-seçim decision-tree `EVET`→`YES`/
  `HAYIR`→`NO` (box-char + araç adları sabit) + kubeseal-akış ASCII diyagramı + minimum-hijyen `[ ]` checklist +
  kod-yorumu `# Plain Secret yaz (Git'e KOYMA!)`→`# Write a plain Secret (do NOT put this in Git!)`;
  Debugging-Pods bash yorumları (`# Önceki crash'in log'u`→`# Log from the previous crash (critical for
  CrashLoopBackOff)`, `# DATABASE_URL belki yanlış`→`# DATABASE_URL might be wrong`) + diyagnostik akış
  etiketleri + heading prose (`Adım`→`Step`, `Senaryo`→`Scenario`); Helm dizin-layout etiketleri; Flux-vs-ArgoCD
  4 karşılaştırma tablosu tüm hücreleri (`Boyut`→`Dimension`, `Sahibi`→`Owner`) + migration timeline (`Hafta`→
  `Week`). Yüzde/birim konvansiyonu `%X`→`X%`, `dk`→`min`, `$X/ay`→`$X/mo`. **Yalnız gerçek verbatim-artifact
  korundu:** K8s status/reason literal string'leri (`CrashLoopBackOff`/`OOMKilled`/`ImagePullBackOff`/`Pending`/
  `Init:Error`/`Evicted`) — bunlar kubectl çıktısı, yorum değil → aynen; Flux/ArgoCD CRD (Kustomization/
  HelmRelease/GitRepository/OCIRepository/Application/ApplicationSet); Secrets tool/CRD (SealedSecret/
  ExternalSecret/ClusterSecretStore/SOPS/age/ESO/argocd-vault-plugin); Helm/Kustomize field (`values`/
  `kustomization.yaml`/`patchesStrategicMerge`); `{{...}}` Go-template; komut+flag; path (`/etc/resolv.conf`/
  `/tmp/heap.hprof`); link-target (`../08-Security/Secrets-Management.md`, `../22-Learning-Path/…/D3-secret-yonetimi.md`
  dahil locale-eksiz + TR-dosya-adı sabit).
- **Bağımsız orchestrator doğrulaması (subagent raporuna körü körüne güvenilmedi):** başlık paritesi 5/5
  (29/24/36/46/84), tablo 5/5 (26/44/37/18/19), fence 5/5 (40/10/38/40/34, twin==source), satır deltası
  0/+1/0/+2/+1 (prose-wrap), gerçek Türkçe kalıntısı **0** (`[ışğİŞĞ]` excl `/var/` = boş, 5/5 **VE** diakritiksiz
  TR-fonksiyon-kelime `için|değil|yok|kullan|hangi|niye|çünkü|öğren|senaryo|adım` = 0, 5/5), link locale-eksiz
  (0 `.en.md`/`.tr.md` sızıntısı, 5/5).
- **Positioning/pazarlama grep bu dilim 0 hit (TR+EN).** `türkçe kaynak|turkish resource/guide/handbook|
  most comprehensive|en kapsamlı|\bROI\b|guarantee|garanti|maaş|salary` → hiçbir twin'de yok. Bu 5 kaynak
  teknik-artifact yoğun (kubectl/YAML/CRD/tablo); slice-1/2'nin FinOps/soft-skill ROI FP'si burada yok.
- **build-docs.sh'e dokunulmadı** — 5 `.en.md` numaralı klasörde (`0[0-9]-*` `cp -r`) otomatik staged;
  iki-locale build (`build-docs.sh` + `python3 -m mkdocs build --clean`) exit 0, 5 sayfa `/en/…/` İngilizce
  render (EN-marker 384/338/322/447/341), TR root sayfaları (default) korundu, `_planning` sızmadı. EN kapsama
  %30.8 → %32.3 (108/334).
- **QA exit 0 (1 UYARI = önceki turlardan kalan `docs/index.en.md` locale-twin FP, 29 kırık link/1 dosya).**
  Bu turun 5 twin'i **yeni kırık link 0**; sayı değişmedi.
- **Working-tree bu tur TEMİZ girdi** (` M README.md` yok). Commit: **7 kendi dosyam** = 5 yeni `.en.md`
  (P4 slice-5) + STATE + I18N-COVERAGE. Dosyalar tek tek `git add`, `git add -A` KULLANILMADI (§14.4).

### Faz 9.5 · EN twin P4 slice-4 (önceki tur — kesintili-tur benimseme + finalize · #16–20)
- **Giriş durumu = kesintili-tur.** Tur başında `git status` TEMİZ ama son commit `cd1efec wip: I18N-COVERAGE
  ara kayıt` (conventional DEĞİL). `git show --stat cd1efec`: 5 `.en.md` (`12-FinOps/Storage-Cost-Optimization`,
  `10-Databases-Production/Zero-Downtime-Migrations`, `07-Observability/SLO-Engineering`,
  `06-GitOps/App-of-Apps-Pattern`, `06-GitOps/ApplicationSet-Patterns`) + I18N-COVERAGE güncellemesi zaten
  commit'liydi — **STATE'in slice-4 planıyla (#16–20) birebir.** Önceki tur slice-4 çevirisini yapıp wip'e
  kaydetmiş ama **bağımsız doğrulama + QA + build + STATE + feat-commit** öncesi ölmüş. Bu, "Açık kararlar"da
  belgeli **kesintili-tur** deseni (P2'de 00–10 README, C+D'de kök README ile aynı).
- **Körlemesine güvenmedim → bağımsız doğruladım (wip'in kendi iddialarına değil, kendi ölçümüme).**
  Başlık paritesi 5/5 (37/28/33/28/27), tablo 5/5 (25/23/17/19/12), fence 5/5 (28/40/26/24/38, **twin==source**),
  satır deltası 0/0/0/0/+1 (ApplicationSet prose-wrap). Gerçek Türkçe kalıntısı **0** — `grep -nE '[ışğİŞĞ]'`
  excl `/var/` = boş (5/5) **VE** diakritiksiz TR-fonksiyon-kelime taraması (`için|değil|yok|kullan|hangi|niye|
  öğren|çünkü|değer`) = 0 (5/5). Link locale-eksiz (0 `.en.md`/`.tr.md` sızıntısı). Positioning/pazarlama
  (TR+EN: `türkçe kaynak|turkish resource|most comprehensive|ROI|guarantee|garanti|maaş`) **0 hit** (bu 5
  kaynak teknik-artifact yoğun; slice-1/2'nin FinOps/soft-skill ROI FP'si burada yok).
- **Spot-read (yapısal-koruma değil, gerçek çeviri teyidi):** App-of-Apps ASCII app-hierarchy tree etiketleri
  İngilizce ("← bootstrap, the single manually created resource", "each one is a separate Application");
  ApplicationSet generator-fan-out tree ("Generator: 5 clusters", "1 Application per cluster") + generator
  adları (List/cluster/git/matrix/scm) **verbatim**; SLO PromQL yorumu `# 5-minute error rate`/`# 1 = normal
  rate, 14 = 14x burn` + SLO birimi `43 min` (dk değil) + `99.9%` yüzde konvansiyonu; Storage kod-yorumu
  `# 40% cheaper`/`# gp2 → gp3: 20% cheaper` + cost-calc `$X/mo`/`savings` + `80%`/`95%`; `kind: Application`/
  `ApplicationSet` + storage type (gp3/io2/st1) + `{{...}}` Go-template + link-target locale-eksiz **verbatim**.
- **İçerik kaliteli → benimsendi (remediation gerekmedi).** Twin'ler + I18N-COVERAGE wip'te zaten commit'li →
  bu turun **feat-commit'i yalnız STATE.md**'yi finalize eder (§14.4: wip'i amend/rewrite YOK — force gerektirir;
  yeni feat-commit ekle, wip+feat çifti kesintiyi dürüstçe kaydeder). I18N-COVERAGE wip'te doğru güncellenmişti
  (slice-4 satırı + dilim planı #16–20 ✅ + kapsam 103/334) → dokunulmadı.
- **QA exit 0** (1 uyarı = önceki turlardan kalan `docs/index.en.md` locale-twin FP, 29 kırık link/1 dosya;
  bu 5 twin'den **yeni kırık link 0**, sayı değişmedi). İki-locale build (`build-docs.sh` + `python3 -m mkdocs
  build --clean`) exit 0, 5 sayfa `/en/…/` İngilizce render (EN-marker 361/354/403/341/299), `_planning`
  sızmadı. EN kapsama %29.3 → %30.8 (103/334). **`12-FinOps` tam twin (8/8)**, `06-GitOps` 3/7.
- **Commit: yalnız STATE.md** (tek dosya `git add`, `git add -A` KULLANILMADI · §14.4). Twin'ler+I18N wip'te.

### Faz 9.5 · EN twin P4 slice-3 (önceki tur — FinOps kalan 5, #11–15)
- **Dilim = P4 slice-3 (5 dosya).** I18N-COVERAGE "P4 — dilim planı" #11–15 (deterministik):
  `12-FinOps/Kubecost-Setup.md` (257s), `PR-Cost-Diff.md` (262s), `Reserved-and-Savings-Plans.md` (235s),
  `Right-Sizing.md` (226s), `Spot-Instance-Strategy.md` (255s) = `12-FinOps` deep-dive'larının kalan 5'i
  (F1 kaynağı). Slice-2'de FinOps ilk 2'si (Cloud-Cost-Allocation, Egress) twin'lenmişti → **FinOps klasörü
  bu turla tam** (7/7). `Right-Sizing` frontmatter `kuculttme` yazım hatası Faz -1'de düzeltilmişti (doğrulandı:
  kaynak "küçültme" diyor) → twin İngilizce "downsizing/right-sizing".
- **5 paralel çeviri subagent (dosya başına bir, sonnet) — P0…P4 slice-2 deseni (11. kez).** Oturmuş
  genişletilmiş ruleset baştan verildi + **aynı-klasör gold-standard referans `Cloud-Cost-Allocation.en.md`**
  gösterildi → remediation gerekmedi, ilk çeviride doğru.
- **Plain/untagged blok prose doğru çevrildi:** Kubecost ASCII allocation-tree (`$32K/ay`→`$32K/mo`,
  box-char + `eks-*` identifier sabit) + kod-yorumu `# %40 verim altı`→`# below 40% efficiency`;
  PR-Cost-Diff decision-tree + iyi/kötü senaryo diyalogları + adoption checklist + shell mesaj
  `%$PERCENT`→`$PERCENT%`; Right-Sizing PromQL yorumu `# CPU p95 (1 hafta)`→`# (1 week)` + SQL yorumu
  `shared_buffers artır`→`increase shared_buffers`; Reserved commitment-vs-PAYG blok (`$69/ay`→`$69/mo`,
  `%38 tasarruf`→`38% savings`, kolon yeniden pad'lendi); Spot cost-calc (`saat`→`hour`, `ay`→`month`,
  `Tasarruf`→`Savings`). Yüzde konvansiyonu `%70`/`%40-50`→`70%`/`40-50%`. Yalnız gerçek verbatim-artifact
  korundu: komut, YAML/JSON key, `kind: VerticalPodAutoscaler`/`NodePool`/`PodDisruptionBudget`, instance
  type (m5.large, i3.2xlarge), `capacity-type: spot`, RI/SP/CUD ürün terimi, PromQL, path, link target
  (`F1-maliyet-finops.md` dahil locale-eksiz).
- **Bağımsız orchestrator doğrulaması (subagent raporuna körü körüne güvenilmedi):** başlık paritesi
  5/5 (24/22/25/30/20), tablo 5/5 (17/10/35/15/29), fence 5/5 (22/26/18/22/18), satır deltası
  0/0/-1/0/0 (Reserved prose-wrap), gerçek Türkçe kalıntısı **0** (`[ışğİŞĞ]` excl `/var/` = boş, 5/5),
  link locale-eksiz (0 sızıntı), positioning (TR-resource) temiz.
- **Pazarlama/ROI grep bu dilim 0 hit — önceki dilimlerin FinOps-ROI FP'si YOK.** Bu 5 kaynak
  teknik-artifact yoğun (komut/YAML/PromQL/tablo); ROI prose'u geçmiyor → §14.3(2) grep tertemiz döndü.
- **build-docs.sh'e dokunulmadı** — 5 `.en.md` numaralı klasörde (`0[0-9]-*/1[0-9]-*` `cp -r`) otomatik
  staged (doğrulandı: 5 staged); iki-locale build (python3 -m mkdocs) exit 0, 5 sayfa `/en/…/` İngilizce
  render (EN-marker 20/27/15/14/16), `_planning` sızmadı. EN kapsama %27.8 → %29.3 (98/334).
- **QA exit 0 (1 UYARI = önceki turlardan kalan `docs/index.en.md` false-positive).** Bu turun 5
  twin'i **yeni kırık link 0**; sayı değişmedi (29 kırık link / 1 dosya).
- **Working-tree bu tur TEMİZ girdi** (` M README.md` yok). Commit: **7 kendi dosyam** = 5 yeni
  `.en.md` (P4 slice-3) + STATE + I18N-COVERAGE. Dosyalar tek tek `git add`, `git add -A` KULLANILMADI (§14.4).

### Faz 9.5 · EN twin P4 slice-2 (önceki tur — count-4 "yakın-kaçıran" #6–10: Platform kalan 3 + FinOps ilk 2)
- **Dilim = P4 slice-2 (5 dosya).** I18N-COVERAGE "P4 — dilim planı" #6–10 (deterministik):
  `13-Platform-Engineering/Internal-Developer-Platform.md` (398s), `Platform-as-Product.md` (285s),
  `Service-Catalog.md` (400s) = Platform kalan 3 (F3 kaynağı) · `12-FinOps/Cloud-Cost-Allocation.md`
  (517s), `Egress-Cost-Reduction.md` (323s) = FinOps ilk 2 (F1 kaynağı). Slice-1'in Platform bölmesiyle
  (Backstage/Golden-Paths) aynı count-tier deseni; FinOps burada başlıyor.
- **5 paralel çeviri subagent (dosya başına bir, sonnet) — P0…P4 slice-1 deseni (10. kez).** Oturmuş
  genişletilmiş ruleset baştan verildi (plain-blok prose çevir, artifact verbatim) + gold-standard
  referans olarak önceki tur twin'i (`Golden-Paths.en.md`) gösterildi → remediation gerekmedi.
- **Plain/untagged blok prose doğru çevrildi (slice-2-original kusuru tekrarlanmadı):**
  Platform-as-Product **7 tag'siz blok** (quarterly survey / NPS trend / roadmap horizons / OKR örneği /
  team roles / beta rollout adımları / checklist) İngilizce'ye çevrildi — spot-read teyit: "Teams open to
  new technology", "Written agreement with the manager". Cloud-Cost-Allocation **ASCII showback-dashboard**
  (satır 206–232): etiketler İngilizce (`Mart 2026`→`March 2026`, `%96`→`96%`, "Top 5 cost drivers"),
  box-drawing char + `eks-prod-cluster`/`rds-payments-primary` identifier + rakam verbatim; strateji
  arrow-diagram padding yeniden hesaplandı. HCL `error_message` string + kod-yorumu (`#`,`--`) çevrildi;
  YAML/JSON/HCL key + `kind:`/`apiVersion:` + SQL identifier + cloud tag KEY + komut verbatim.
- **Bağımsız orchestrator doğrulaması (subagent raporuna körü körüne güvenilmedi):** başlık paritesi
  5/5 (30/32/30/45/37), tablo 5/5 (41/36/38/28/22), fence 5/5 (16/14/26/32/30), satır deltası
  +1/+3/+4/0/0 (prose-wrap; başlık/tablo/fence sabit), gerçek Türkçe kalıntısı **0** (`[ışğİŞĞ]` excl
  `/var/` = boş, 5/5), link locale-eksiz (0 sızıntı), positioning (TR-resource) temiz.
- **Marketing-grep 4 hit = kaynak-sadık teknik FinOps FP (dokunulmadı), qa scope dışı.**
  Platform-as-Product.en.md:211 "ROI: Savings $X…" (kaynak:210 `ROI: "Tasarruf X$…"`) + :283
  "budget with ROI" (kaynak:281 `ROI ile savunabilir`); Egress.en.md:186 "ROI: break-even at > 5TB/month"
  (kaynak:186) + :264 "Direct Connect (on-prem ROI)" (kaynak:264). Hepsi FinOps return-on-investment
  terimi, kaynakta zaten var, uydurma değil. qa.py `check_marketing` yalnız `22-Learning-Path/` tarar →
  `13-Platform-Engineering/`+`12-FinOps/`*.en.md kapsam DIŞI → flag'lemez, exit 0. (Önceki turlarda
  Threat-Modeling/Chaos/Vendor/Stakeholder/Saying-No "ROI/guarantee" ile aynı belgeli desen.)
- **build-docs.sh'e dokunulmadı** — 5 `.en.md` numaralı klasörlerde (`0[0-9]-*/1[0-9]-*` `cp -r`)
  otomatik staged (doğrulandı: 5 staged); iki-locale build (python3 -m mkdocs) exit 0, 5 sayfa
  `/en/…/` İngilizce render (EN-marker 107/92/112/180/66), TR root "Servis Envanteri" ↔ EN `/en/`
  "Service Inventory" (locale split doğru), `_planning` sızmadı. EN kapsama %26.3 → %27.8 (93/334).
- **QA exit 0 (1 UYARI = önceki turlardan kalan `docs/index.en.md` false-positive).** Bu turun 5
  twin'i **yeni kırık link 0**; sayı değişmedi (29 kırık link / 1 dosya).
- **Working-tree bu tur TEMİZ girdi** (` M README.md` yok). Commit: **7 kendi dosyam** = 5 yeni
  `.en.md` (P4 slice-2) + STATE + I18N-COVERAGE. Dosyalar tek tek `git add`, `git add -A` KULLANILMADI (§14.4).

### Faz 9.5 · EN twin P4 slice-1 (önceki tur — count-4 "yakın-kaçıran" başı: 5 deep-dive)
- **Dilim = P4 slice-1 (5 dosya).** P3 (15/15) kapandıktan sonra P4'ün ilk dilimi. §14.1.3
  dosya-seviyesi dilim: kalan ~200+ deep-dive bir tura sığmaz → dilim başına 5. **Sıra deterministik:
  I18N-COVERAGE "P4 — dilim planı" tablosu** (count-4 "yakın-kaçıran" güçten-zayıfa). Slice-1 = ilk 5:
  `20-Soft-Skills/Vendor-Management` (329s), `20-Soft-Skills/Stakeholder-Management` (336s),
  `20-Soft-Skills/Saying-No` (270s) → F5 (stakeholder/vendor/"hayır") "Önce oku" kaynakları · ardından
  `13-Platform-Engineering/Backstage-Setup` (531s), `13-Platform-Engineering/Golden-Paths` (457s) → F3 (IDP/platform).
  Platform-Engineering slice-1/slice-2'ye bölündü (kalan 3 → slice-2), P3'ün count-tier bölmesiyle aynı desen.
- **5 paralel çeviri subagent (dosya başına bir, sonnet) — P0…P3 deseni (9. kez).** Genişletilmiş
  ruleset baştan verildi (plain-blok prose çevir, artifact verbatim) → remediation gerekmedi. Bağımsız
  orchestrator doğrulaması: başlık paritesi 5/5 (32/42/31/40/30), tablo 5/5 (46/60/18/27/34), fence 5/5
  (8/18/16/38/10), gerçek Türkçe kalıntısı **0** (`[ışğİŞĞ]` excl `/var/` = boş, 5/5), link locale-eksiz
  (0 sızıntı), positioning (TR-resource) temiz.
- **Plain-blok prose doğru çevrildi (Saying-No en yoğun):** Saying-No 16 plain fence — dialogue
  senaryoları (`Talep:`→`Request:`/`Yanıt:`→`Response:`, `Yes-If`/`Not-Now`/`Not-Worth-It`/`Direct No`
  etiketleri korunup içerik çevrildi, 3-cümle reçetesi `ANLADIM`→`UNDERSTOOD`) + "Pratik Hale Getirme"
  `[ ]` checklist. Backstage/Golden-Paths: kod-yorumu `# …`, checklist, scaffolder/catalog descriptive
  string değerleri çevrildi; YAML key + `kind:`/`apiVersion:` + `metadata.name` + komut + link-target verbatim.
- **Marketing-grep 4 hit = kaynak-sadık teknik FP (dokunulmadı), qa scope dışı.** Vendor.en.md:30
  "uptime guarantee?" (kaynak:29 `garantisi?`), Stakeholder.en.md:153 "ROI calculation" (kaynak:151
  `ROI hesabı`), Saying-No.en.md:78 "ROI argument" + :85 "ROI 17 months" (kaynak:77/84 `ROI argümanı`/
  `ROI 17 ay`). Hepsi teknik terim, kaynakta zaten var, uydurma değil. qa.py `check_marketing` yalnız
  `22-Learning-Path/` tarar (qa.py:108–115) → `20-Soft-Skills/`+`13-Platform-Engineering/`*.en.md kapsam
  DIŞI → flag'lemez, exit 0. (Önceki turlarda Threat-Modeling/Chaos "ROI" ile aynı belgeli desen.)
- **Türk-iş-kültürü içeriği korundu (positioning kuralı).** Saying-No "Türk iş kültüründe bağlam" →
  "Context in Turkish work culture" olarak çevrildi, silinmedi — global okur için geçerli alan bilgisi
  (hiyerarşik beklenti/yüz kaybı dinamikleri). Hiçbir twin "Turkish resource/guide" demiyor.
- **build-docs.sh'e dokunulmadı** — 5 `.en.md` numaralı klasörlerde (`0[0-9]-*/1[0-9]-*` `cp -r`)
  otomatik staged (doğrulandı: 5 staged); iki-locale build hatasız, 5 sayfa `/en/…/` İngilizce render
  (EN-marker Vendor 85 / Saying-No 26 / Golden-Paths 38). EN kapsama %24.9 → %26.3 (88/334).
- **QA exit 0 (1 UYARI = önceki turlardan kalan `docs/index.en.md` false-positive).** Bu turun 5
  twin'i **yeni kırık link 0**; sayı değişmedi (29 kırık link / 1 dosya).
- **Working-tree bu tur TEMİZ girdi** (` M README.md` yok). Commit: **7 kendi dosyam** = 5 yeni
  `.en.md` (P4 slice-1) + STATE + I18N-COVERAGE. Dosyalar tek tek `git add`, `git add -A` KULLANILMADI (§14.4).

### Faz 9.5 · EN twin P3 slice-3 (önceki tur — deep-dive 11–15 · P3 KAPANDI 15/15)
- **Dilim = P3 slice-3 (son 5/15 deep-dive, count-4 güvenlik/güvenilirlik çekirdeği).** §14.1.3
  dosya-seviyesi dilim: 11→ `08-Security/Secrets-Management` (587s), 12→ `08-Security/DevSecOps-Pipeline`
  (476s), 13→ `11-SRE/Incident-Response` (323s), 14→ `10-Databases-Production/Backup-Restore-Patterns`
  (413s), 15→ `11-SRE/Chaos-Engineering` (343s). I18N-COVERAGE `Slice` kolonuyla birebir. **P3 tamam.**
- **5 paralel çeviri subagent (dosya başına bir) — P0…P3 slice-2 deseni (8. kez).** Bu tur farkı:
  **slice-2'de bulunan genişletilmiş ruleset baştan verildi** (plain-blok prose çevir, artifact
  verbatim) → geriye dönük remediation gerekmedi, ilk çeviride doğru geldi. Bağımsız orchestrator
  doğrulaması: başlık paritesi 5/5 (63/33/30/50/28), tablo 5/5 (45/21/43/42/60), fence 5/5
  (50/28/12/32/20), gerçek Türkçe kalıntısı **0** (`[ışğİŞĞ]` excl `/var/`+VERBİS = boş, 5/5),
  link locale-eksiz (0 sızıntı), positioning/pazarlama (TR+EN) temiz. Satır deltası 0/0/-1/-1/+1.
- **Plain-blok prose doğru çevrildi (slice-2 dersi tuttu):** Secrets-Management decision-tree
  `EVET`→`YES`/`HAYIR`→`NO` + minimum-hijyen `[ ]` checklist; Chaos game-day/adoption `[ ]`
  checklist + kod yorumu `# tek seferlik`→`# one-shot`/`# günlük`→`# daily`; Incident IC-rol ağacı
  + bridge-log + status-page template; Backup 3-2-1 topoloji + drill protokolü. Spot-read: label'lar
  İngilizce, box-drawing char'lar + `kind: PodChaos`/`NetworkChaos` + PromQL `http_5xx_rate > 0.05`
  verbatim.
- **Güvenlik ipliği korundu (§12.4).** Secrets: Vault/ESO/SOPS/Sealed Secrets + audit log shipping;
  DevSecOps-Pipeline: tarama+imzalama (Trivy/Cosign/Kyverno) C2 pipeline devamı çerçevesi; Backup:
  "test edilmemiş backup, backup değildir" + at-rest şifreleme/KMS; Chaos: blast-radius/abort-koşulu.
- **Positioning reframe (EN tarafı):** KVKK global-okur çerçevesiyle ("KVKK (Turkey's Personal Data
  Protection Law, No. 6698)" — Secrets References + Backup anti-pattern/güvenlik tablosu, Incident
  🇹🇷 KVKK notu); TR-spesifik içerik SİLİNMEDİ, recontextualize. Incident'te "Türkçe çevirisi yok"
  ifadesi global okura anlamsız → "open-source, accessible" (1-satır delta buradan). Hiçbir twin
  "Turkish resource/guide" demiyor.
- **`ROI` grep-hit (Chaos-Engineering.en.md:317 "ROI report") = FALSE-POSITIVE, dokunulmadı.** TR
  kaynak line 316 zaten "chaos engineering ROI rapor" içeriyor (yıllık chaos programının getirisi —
  teknik SRE terimi). qa.py `check_marketing` `\bROI\b` yakalar AMA yalnız `22-Learning-Path/` tarar
  (`LP`, qa.py:108–115); `11-SRE/*.en.md` kapsam DIŞI → qa flag'lemez, exit 0. Threat-Modeling.en.md:25
  ROI ile birebir aynı desen (Açık kararlar'da önceden belgeli). Sadık çeviri; kaynak da geçiyor.
- **build-docs.sh'e dokunulmadı** — 5 `.en.md` numaralı klasörlerde (`0[0-9]-*/1[0-9]-*` `cp -r`)
  otomatik staged; iki-locale build hatasız, 5 sayfa `/en/…/` İngilizce render (EN-marker
  176/80/90/135/100), 5 EN + 5 TR (default) index.html mevcut. EN kapsama %23.4 → %24.9 (83/334).
- **QA exit 0 (1 UYARI = önceki turlardan kalan `docs/index.en.md` false-positive).** Bu turun 5
  twin'i **yeni kırık link 0**; sayı değişmedi (29 kırık link / 1 dosya).
- **Working-tree bu tur TEMİZ girdi** (` M README.md` yok). Commit: **7 kendi dosyam** = 5 yeni
  `.en.md` (slice-3) + STATE + I18N-COVERAGE. Dosyalar tek tek `git add`, `git add -A` KULLANILMADI (§14.4).

### Faz 9.5 · EN twin P3 slice-2 (önceki tur — deep-dive 6–10 + plain-blok Türkçe-kalıntı düzeltmesi)
- **Dilim = P3 slice-2 (5/15 deep-dive, count-6 katmanı).** §14.1.3 dosya-seviyesi dilim: 6→
  `20-Soft-Skills/Documentation-as-Communication` (415s), 7→ `16-Cheatsheets/linux-troubleshooting`
  (337s), 8→ `07-Observability/Prometheus-Best-Practices` (395s), 9→ `07-Observability/Alerting-Done-Right`
  (296s), 10→ `00-Culture/Blameless-Postmortem-Template` (224s). I18N-COVERAGE `Slice` kolonuyla birebir.
  Kalan 5 = slice-3 (11–15, count-4 güvenlik/güvenilirlik çekirdeği).
- **5 paralel çeviri subagent (dosya başına bir) — P0…P3 slice-1 deseni (6. kez).** Bağımsız
  orchestrator doğrulaması: başlık paritesi 5/5 (67/72/38/22/20), tablo 5/5 (26/12/12/19/13), fence
  5/5 (20/22/46/22/6), link locale-eksiz (0 sızıntı), positioning/pazarlama (TR+EN) temiz.
- **🔴 BULGU (§14.3 öz-denetim) — plain/untagged fenced blok içi Türkçe kalıntısı.** Documentation
  subagent'ı, slice-1 twin'lerini (Threat-Modeling/K8s-Hardening) örnek alıp **plain untagged ``` blok
  içeriğini "diyagram/artifact" sayıp verbatim** bıraktı — ama o bloklar sadece diyagram değil,
  reponun **checklist** bölümünü (CLAUDE.md her dokümanda zorunlu), ASCII **attack-tree/flow-diagram
  etiketlerini** ve **kod yorumlarını** (`# YANLIŞ`/`# DOĞRU`) içeriyordu. İngilizce twin'de Türkçe
  checklist = okuyucunun duvara çarpması = gerçek kusur (üstelik ilk P3 ruleset'im "yalnız kod-içi `#`
  yorum çevrilir" derken checklist'i dışarıda bırakmıştı — ruleset hatası). Kapsamlı Türkçe-tarama
  (`[ışğİŞĞ]` + TR-fonksiyon-kelime) 5 twin'de 1'i temiz-değil (Documentation, 11 satır) + geriye
  dönük slice-1'de 4/5 dosya (Pipeline-Patterns, K8s-Hardening, Threat-Modeling, SLI-SLO; KVKK temiz).
- **KARAR: slice-1'i de bu tur düzelt (scope gerekçesi).** §14.1.2 "en fazla bir faz" **ileri
  ilerlemeyi** sınırlar (slice-3/P4'e geçme); zaten teslim edilmiş slice-1'in kusurunu §14.3 öz-denetimi
  gereği düzeltmek **aynı fazın (9.5) remediation'ıdır**, yeni dilim değil. Kapsam frontier'ı ilerlemedi
  (hâlâ 10/15). Slice-2'yi doğru teslim edip slice-1'de aynı kusuru bilerek bırakmak daha kötü olurdu
  (§15.4 kandırma-karşıtı ruhu). Bounded + mekanik (prose-only, yapı korunur) → risk düşük.
- **5 remediation subagent (sıkı "plain-blok prose çevir, kod-artifact + link path dokunma" ruleset).**
  Sonuç — 10 twin (5 slice-2 + 4 remediated slice-1 + KVKK dokunulmadı) bağımsız doğrulama:
  başlık/tablo/fence paritesi source ile **10/10 birebir** (satır sayısı source-eşit; twin +prose-wrap
  farkı yalnız KVKK +3/Documentation +4/Prometheus +1 — hepsi prose, kod/tablo/başlık sabit), gerçek
  Türkçe kalıntısı **0** (yalnız `/var/…` path + `VERBİS` özel-isim FP), link-leak 0. Remediation
  ekstra yakaladı: K8s Kyverno `message:` string, SLI-SLO `30 gün`/`43,200 dk` birim'leri,
  Pipeline maturity-level satırları + 11-satırlık checklist tümü.
- **Düzeltilmiş ruleset Sıradaki-adım'a + I18N-COVERAGE'a yazıldı** (slice-3 + P4 baştan doğru yapsın):
  plain-blok içindeki *prose* (checklist/diyagram etiketi/kod yorumu/template örnek/`message:`,`desc:`
  string) İngilizce'ye çevrilir; yalnız komut/YAML-key/metric/PromQL/path/link-target verbatim.
  Doğrulama adımına `grep -nE '[ışğİŞĞ]' <twin> | grep -vE '/var/|VERB[İI]S'` eklendi.
- **build-docs.sh'e dokunulmadı** — 5 slice-2 `.en.md` numaralı klasörlerde (`0[0-9]-*/1[0-9]-*/2[0-9]-*`
  `cp -r`) otomatik staged; iki-locale build hatasız, 5 sayfa `/en/…/` İngilizce render (EN-marker
  spot-check: 17/9/34/25/17 hit). EN kapsama %21.9 → %23.4 (78/334).
- **QA exit 0 (1 UYARI = önceki turlardan kalan `docs/index.en.md` false-positive).** Bu turun 10 twin'i
  (5 yeni + 5 düzeltilmiş) **yeni kırık link 0**; sayı değişmedi (29 kırık link / 1 dosya).
- **Working-tree bu tur TEMİZ girdi** (` M README.md` yok). Commit: **11 kendi dosyam** = 5 yeni `.en.md`
  (slice-2) + 4 düzeltilmiş `.en.md` (slice-1 remediation) + STATE + I18N-COVERAGE. Dosyalar tek tek
  `git add`, `git add -A` KULLANILMADI (§14.4).

### Faz 9.5 · EN twin P3 slice-1 (önceki tur — 5 CLAUDE.md "İyi doküman" örneği)
- **Dilim = P3 slice-1 (5/15 deep-dive).** §14.1.3 dosya-seviyesi dilim: P3'ün 15 deep-dive'ı
  büyük (224–601 satır) → bir tura sığmaz, 3–5'lik dilim. Slice-1 = CLAUDE.md "İyi doküman"
  olarak adlandırılan 5 örnek (`08-Security/Kubernetes-Hardening`, `08-Security/Threat-Modeling`,
  `11-SRE/SLI-SLO-Error-Budget`, `02-CI-CD/Pipeline-Patterns`, `19-Compliance/KVKK-Practical`) —
  STATE'in "bu 5 zaten üst sırada olmalı" ipucuyla birebir. Kalan 10 = slice-2 (6–10) + slice-3 (11–15).
- **15-liste seçim kuralı I18N-COVERAGE.md'ye TABLO olarak yazıldı** (deterministik, sonraki turlar
  okuyup devam eder). count-4 tier'ı 27 dokümanla EŞİT olduğundan pür "head -15" keyfi olurdu →
  belgelenmiş tiebreak: (1) count-6 (7 doküman) → (2) CLAUDE.md 5 örneğinin count-6 dışı kalanı
  (K8s-Hardening/SLI-SLO/Pipeline-Patterns) → (3) kalan 5 slot count-4'ten DevSecOps
  güvenlik+güvenilirlik çekirdeği (Secrets-Management, DevSecOps-Pipeline, Incident-Response,
  Backup-Restore, Chaos). Pipeline-Patterns count-4 ama CLAUDE.md örneği olduğu için 15'e alındı
  (STATE ipucu "5 örnek üst sırada" gereği). Yakın-kaçıranlar (Vendor/Stakeholder/Platform/FinOps
  vb., hepsi count-4) → P4.
- **5 paralel çeviri subagent (dosya başına bir) — P0…P2 deseni tekrar (6. kez).** Ruleset:
  yapı byte-korunur (başlık sayısı/sıra, tablo satır+kolon, kod bloğu+dil-tag, `<details>`, `---`,
  blockquote, `{ #anchor }`), yalnız prose + frontmatter `description` çevrilir; `tags` verbatim;
  iç link locale-eksiz `.md` (`.en.md` DEĞİL), hedef path kaynakla birebir; kod/YAML/PromQL/formül
  verbatim, yalnız kod-içi `#` yorum prose'u çevrilir; epigraf çevrilir; placeholder EN-kanonik.
- **Bağımsız orchestrator doğrulaması (subagent raporuna körü körüne güvenilmedi):** markdown-başlık
  paritesi (`^#{1,6} `) 5/5 (53/40/40/41/41), tablo satır paritesi (`^\|`) 5/5 (42/76/41/25/30),
  link-leak grep 0, positioning grep (TR+EN) 0, §14.3(2) pazarlama grep temiz. **KVKK 417→420 satır**
  (3 satır fark bilinçli: global-okur gloss "KVKK (Turkey's Personal Data Protection Law, No. 6698)"
  + "worked example of how a non-EU data-protection regime is translated into engineering controls" —
  başlık/tablo paritesi bozulmadı, TR içerik silinmedi). Spot-read: KVKK reframe + SLI-SLO epigraf/
  frontmatter İngilizce, kod verbatim → temiz.
- **`ROI` grep-hit (Threat-Modeling.en.md:25) = FALSE-POSITIVE, dokunulmadı.** TR kaynak line 25
  zaten "ROI listesi: yüksek-tehdit / düşük-maliyet kontroller" içeriyor (güvenlik kontrolü ROI'si,
  teknik terim — pazarlama değil). qa.py `check_marketing` `\bROI\b` yakalar AMA yalnız `22-Learning-Path/`
  (`LP`) tarar (qa.py:109 `if not os.path.isdir(LP)` + `md_files(LP)`); `08-Security/*.en.md` bu
  kapsam DIŞI → qa flag'lemez, exit 0. Sadık çeviri; kaynak da geçiyor.
- **build-docs.sh'e dokunulmadı** — deep-dive'lar numaralı klasörlerde (`0[0-9]-*/1[0-9]-*/2[0-9]-*`
  `cp -r` globu, build-docs.sh:68) → 5 `.en.md` otomatik staged (doğrulandı: 5 staged;
  `/en/…/Kubernetes-Hardening/` "hardening", `/en/…/SLI-SLO-Error-Budget/` "error budget" İngilizce
  render). EN kapsama %20.4 → %21.9 (73 site sayfası / 334). Aşama B eşiği (%60) hâlâ uzak.
- **QA'daki 1 UYARI = önceki turlardan kalan `docs/index.en.md` false-positive.** Bu turun 5 twin'i
  **yeni kırık link 0** ekledi; sayı değişmedi (29 kırık link / 1 dosya, birebir aynı).
- **Working-tree bu tur TEMİZ girdi** (` M README.md` yok — kullanıcı önceki turlarda commit'ledi:
  `52e39ff`/`3c10144` LinkedIn düzeltmeleri). Commit yalnız **7 kendi dosyam**: 5 `.en.md` + STATE +
  I18N-COVERAGE. Dosyalar tek tek `git add` edildi, `git add -A` KULLANILMADI (§14.4 alışkanlığı sürdü).

### Faz 9.5 · EN twin P2 (önceki tur — 21 klasör README'si · P2 TAMAMLANDI)
- **Dilim = tüm P2 (21 klasör README'si, `00-Culture` … `20-Soft-Skills`).** README'ler küçük
  (44–119 satır) → §14.1.3 dilimi tek tura sığdı; belgelenmiş 2-dilim planı (00–10 / 11–20) fiilen
  böyle gerçekleşti çünkü **00–10 zaten önceki kesintili turdan hazırdı** (untracked). Bu tur:
  00–10 doğrulanıp benimsendi + 11–20 üretildi = tek P2 commit'i. (21-Field-Notes P2 dışı → P4.)
- **10 paralel çeviri subagent (sonnet), dosya başına bir — P0…P1b deseni tekrar (5. kez).**
  Ruleset: yapı byte-korunur (başlık sayısı/sıra, tablo satır+kolon, kod bloğu, `<details>`, `---`,
  blockquote), yalnız prose + frontmatter `description` çevrilir; iç link locale-eksiz
  (`[x](Kubernetes-Hardening.md)`, `.en.md` DEĞİL), tablo path'leri kaynakla birebir; komut/YAML
  verbatim; positioning reframe; placeholder güvenliği. 10/10 rapor + bağımsız orchestrator
  doğrulaması: başlık/tablo paritesi **21/21** OK, link-leak 0, positioning/pazarlama (TR+EN) 0.
- **`README.en.md` = klasör index'i, MODÜL DEĞİL.** "İçindekiler" tablosu + kısa giriş;
  `MOD_RE ^[A-F]\d+-` eşleşmez → qa modül-bütünlük denetimine girmez. Frontmatter'ları VAR
  (`description`+`tags`) → `description` çevrildi, `tags` verbatim.
- **KVKK/BDDK global-okur reframe (19-Compliance, 20-Soft-Skills).** 19-Compliance twin'inde KVKK
  "AB-dışı bir veri koruma rejimini mühendislik kontrolüne çevirmenin somut örneği" çerçevesiyle;
  TR-spesifik içerik SİLİNMEDİ, recontextualize edildi. Hiçbir twin "Turkish resource/guide" demiyor.
  18-Career twin'inde ünvan-garantisi/maaş/ROI **eklenmedi** (kaynak seviye haritası + comp notları
  sadık çevrildi, uydurma sayı yok).
- **build-docs.sh'e dokunulmadı** — numaralı klasörler `0[0-9]-* 1[0-9]-* 2[0-9]-*` `cp -r` globuyla
  (build-docs.sh:68) özyineli stage oluyor → 21 `.en.md` otomatik staged (doğrulandı: 21 staged;
  `/en/19-Compliance/` "engineering control"+"Turkey-specific notes", `/en/11-SRE/` İngilizce render).
  EN kapsama %14.1 → %20.4 (68 site sayfası / 334).
- **QA'daki 1 UYARI = önceki turlardan kalan `docs/index.en.md` false-positive.** Bu turun 21 twin'i
  **yeni kırık link 0** ekledi; sayı değişmedi (29 kırık link / 1 dosya, birebir aynı).
- **00–10 provenance (Açık kararlar'da kanıtlı):** untracked geldi → doğrulandı → benimsendi.
  ` M README.md` (kullanıcı LinkedIn TR düzeltmesi) commit'e alınmadı (`git add -A` yok).

### Faz 9.5 · EN twin P1b (önceki tur — Blok E+F: 11 modül/exam twin'i · P1b TAMAMLANDI)
- **Dilim = Blok E + Blok F (11 dosya) — P1b'nin son dilimi.** §14.1.3 dosya-seviyesi dilim:
  E1–E5 + Blok E STAGE-EXAM (6) · F1–F5 (5). **Blok F'de STAGE-EXAM YOK** (CURRICULUM: "Block F
  doesn't close with an exam") → P1b toplamı = 30 modül + 5 STAGE-EXAM (A–E) = 35 dosya, hepsi
  bitti. A+B (12) · C+D (12) · E+F (11) turlarının kadans deseni birebir. Sıradaki-adım kuralı 3:
  STAGE-EXAM (Blok E'de VAR) blok twin'iyle birlikte alındı.
- **11 paralel çeviri subagent (sonnet), dosya başına bir — A+B/C+D/P1a/P0 deseni tekrar.** Ruleset:
  yapı byte-korunur (başlık sayısı/sıra, tablo, kod bloğu, `<details>`, `---`, blockquote), yalnız
  prose + frontmatter `description` çevrilir; link hedefi locale-eksiz (`[E1](E1-....md)`, `.en.md`
  DEĞİL); modül→lab/modül→modül path'leri kaynakla birebir; komut/YAML/SQL/çıktı verbatim, yalnız
  kod-içi `#` yorum prose'u çevrildi; kanonik blok adları (E→Ownership, F→Judgment); `~N saat`→`~Nh`;
  placeholder EN-kanonik. 11/11 rapor + bağımsız orchestrator doğrulaması: başlık paritesi 11/11
  (10/10/10/11/10/6 · 10/10/10/10/10), link-leak 0, residual TR-başlık 0, pazarlama/positioning (TR+EN) 0.
- **F-blok ortak `## 🔨 Deliverable exercise` başlığı (5/5 tutarlı).** F1–F5'te `## 🔨 Lab` yerine
  `## 🔨 Teslim edilebilir egzersiz` var (F modülleri "sıralayıcı", lab yok — teslim egzersizi
  var). Kanonik H2 haritasında olmayan bu başlık **5 dosyada da** `## 🔨 Deliverable exercise`
  olarak çevrildi (grep 5/5). Teslim dosya adları (`finops-analiz.md`, `tehdit-modeli.md`,
  `golden-path-onerisi.md`, `karar-yazisi.md`) verbatim korundu — öğrencinin ürettiği çıktı, link değil.
- **Güvenlik ipliği korundu (§12.4).** E4 twin'inde "test edilmemiş backup, backup değildir" +
  backup at-rest şifreleme/erişim kontrolü/audit çerçevesi birebir; F2 twin'inde KVKK→GDPR→SOC 2
  regülasyon→kontrol→kanıt zinciri ve STRIDE korundu (KVKK 6 / GDPR 4 / SOC 2 4 geçiş sayısı).
  Blok E STAGE-EXAM'de güvenlik-iplik çerçevesi (Blok D deseni) taşındı.
- **Positioning reframe (EN tarafı):** F2 KVKK "AB-dışı veri koruma rejiminin mühendislik
  kontrolüne çevrilmesi" olarak global okur çerçevesiyle; hiçbir twin "Turkish resource/guide"
  demiyor (grep temiz). F5 vendor tartışması nötr buy-vs-build ödünleşimi (vendor-övgü tonu yok).
- **Modül twin'i qa `check_modules`'ten MUAF (`LOCALE_RE`, qa.py:156).** qa hâlâ "30 modül" sayar
  (twin'ler modül-bütünlük denetimine girmez) — beklenen davranış. build-docs.sh'e dokunulmadı;
  `block-{e,f}-*` twin'leri `2[0-9]-*` `cp -r` ile özyineli stage oluyor (doğrulandı: 11 staged;
  `/en/…/E1-sli-slo-error-budget/` "When you finish this module", `/en/…/F2-tehdit-uyum/`
  "F — Judgment" ile İngilizce render). EN kapsama %10.8 → %14.1 (47 site sayfası / 334).
- **QA'daki 1 UYARI = önceki turlardan kalan `docs/index.en.md` false-positive.** Bu turun 11 twin'i
  **yeni kırık link 0** ekledi; sayı değişmedi (29 kırık link / 1 dosya, birebir aynı).

### Faz 9.5 · EN twin P1b (önceki tur — Blok C+D: 12 modül/exam twin'i)
- **Dilim = Blok C + Blok D (12 dosya).** §14.1.3 dosya-seviyesi dilim: tüm P1b (30 modül +
  5 STAGE-EXAM = 35 dosya) bir tura sığmaz. A+B önceki tur (12); bu tur C+D (12) — önceki turun
  kadans deseniyle birebir. Kalan E+F (11 dosya) = sıradaki tur(lar). C STAGE-EXAM ve D
  STAGE-EXAM blok twin'iyle birlikte alındı (Sıradaki-adım kuralı 3).
- **12 paralel çeviri subagent (sonnet), dosya başına bir — A+B/P1a/P0 deseni tekrar.** Ruleset:
  yapı byte-korunur (başlık sayısı/sıra, tablo, kod bloğu, `<details>`, `---`), yalnız prose +
  frontmatter `description` çevrilir; link hedefi locale-eksiz (`[C1](C1-container.md)`, `.en.md`
  DEĞİL); modül→lab/modül→modül path'leri kaynakla birebir; komut/YAML/HCL/çıktı verbatim,
  yalnız kod-içi `#` yorum prose'u çevrildi; kanonik blok adları (C→Reproducibility,
  D→Orchestration); `~N saat`→`~Nh`; placeholder adları EN-kanonik (`<HEDEF_IP>`→`<TARGET_IP>`).
  12/12 rapor + bağımsız orchestrator doğrulaması: başlık paritesi 12/12 (16/11/10/11/11/6 ·
  12/11/10/10/11/6), link-leak 0, residual TR-başlık 0, pazarlama/positioning (TR+EN) 0.
- **Güvenlik ipliği korundu (§12.4).** D1 "RBAC + NetworkPolicy ilk günden" çerçevesi ve K04
  kırık-lab referansı, D4 "C2 pipeline'ının devamı (ayrı güvenlik dersi değil)" çerçevesi twin'de
  birebir; `/en/…/D1-k8s-temel/` "RBAC + NetworkPolicy" ile render. D2'deki "garanti" teknik
  anlamda ("guarantee" — K8s requests) çevrildi, pazarlama değil.
- **Modül twin'i qa `check_modules`'ten MUAF (`LOCALE_RE`, qa.py:156).** qa hâlâ "30 modül" sayar
  (twin'ler modül-bütünlük denetimine girmez) — beklenen davranış. İngilizce başlık serbest; yine
  de kaynak modülün bölüm iskeleti korundu (residual TR-başlık grep → 0).
- **build-docs.sh'e dokunulmadı** — `block-*` twin'leri `2[0-9]-*` `cp -r` globuyla özyineli stage
  oluyor (doğrulandı: `site_src/22-Learning-Path/block-{c,d}-*/*.en.md` = 12; `/en/…/C2-ci/`,
  `/en/…/D1-k8s-temel/`, `/en/…/STAGE-EXAM/` İngilizce render). A+B'deki gibi ek satır gerekmedi.
- **EN kapsama %7.2 → %10.8** (36 site sayfası / 334). Aşama B eşiği hâlâ %60.
- **QA'daki 1 UYARI = önceki turdan kalan `docs/index.en.md` false-positive.** Bu turun 12 twin'i
  **yeni kırık link 0** ekledi; sayı değişmedi.

### Faz 9.5 · EN twin P1b (önceki tur — Blok A+B: 12 modül/exam twin'i)
- **Dilim = Blok A + Blok B (12 dosya).** §14.1.3 dosya-seviyesi dilim: tüm P1b (30 modül +
  5 STAGE-EXAM = 35 dosya) bir tura sığmaz. A+B = ilk iki blok, birbirine kapalı set; STAGE-EXAM
  twin'leri blok twin'iyle birlikte alındı (Sıradaki-adım kuralı 3). Kalan C/D/E/F = sıradaki tur(lar).
- **12 paralel çeviri subagent (sonnet), dosya başına bir — P0/P1a deseni tekrar.** Ruleset:
  yapı byte-korunur (başlık sayısı/sıra, tablo, kod bloğu, `<details>`, `---`), yalnız prose +
  frontmatter `description` çevrilir; link hedefi locale-eksiz (`[A2](A2-ag-tcp-ip.md)`, `.en.md`
  DEĞİL); `{ #anchor }` sabit; modül→lab/modül→modül path'leri kaynakla birebir; kod/komut/çıktı
  verbatim; **kod-içi yorum prose'u çevrildi** (P1a COST-GUARDRAILS deseni: `# Open PowerShell…`),
  komut token'ı değil; kanonik blok adları (A→Intuition, B→Visibility); `~N saat`→`~Nh`;
  positioning reframe; placeholder güvenliği. 12/12 rapor: başlık paritesi eşit, link ek-siz.
- **Modül twin'i qa `check_modules`'ten MUAF (`LOCALE_RE`, qa.py:156).** Bu yüzden qa hâlâ
  "30 modül" sayar (twin'ler modül-bütünlük denetimine girmez) — beklenen davranış, eksik değil.
  İngilizce başlık serbest; yine de kaynak modülün bölüm iskeleti (🎯/Önce oku/Kabul/Kendini test/
  Takıldıysan/Sırada) korundu, salt prose çevrildi (residual TR-başlık grep → 0).
- **Blok F'de STAGE-EXAM YOK** (CURRICULUM: "Block F doesn't close with an exam"). P1b toplamı =
  30 modül + 5 STAGE-EXAM (A–E) = 35 dosya. Bu tur 12 bitti; kalan 23 (C/D/E/F).
- **build-docs.sh'e dokunulmadı** — `block-*` `2[0-9]-*` `cp -r` globuyla zaten özyineli stage
  oluyor (doğrulandı: `site_src/22-Learning-Path/block-{a,b}-*/*.en.md` = 12; `/en/…/A1-linux-
  temeli/` İngilizce render). P1a'daki gibi ek satır gerekmedi.
- **EN kapsama %3.6 → %7.2** (24 site sayfası / 334). Aşama B eşiği hâlâ %60.
- **QA'daki 1 UYARI = önceki turdan kalan `docs/index.en.md` false-positive** (P0 Açık
  kararlar'da kanıtla açıklandı). Bu turun 12 twin'i **yeni kırık link 0** ekledi; sayı değişmedi.

### Faz 9.5 · EN twin P1a (önceki tur — 9 rehber dosyası)
- **Dilim seçimi = 9 rehber dosyası (P1'in "P1a" alt-dilimi).** §14.1.3 dosya-seviyesi dilim:
  bir turda tüm P1 (9 rehber + 30 modül + 6 STAGE-EXAM) sığmaz. Rehber dosyaları düşük-riskli
  ve kendi içinde kapalı bir set (birbirine + modüllere link verir, modüller henüz twin'lenmedi
  ama link hedefleri locale-eksiz olduğu için plugin fallback ile çözülür) → temiz kesim. Modül
  twin'leri = P1b, sıradaki tur(lar).
- **9 paralel çeviri subagent (sonnet), dosya başına bir — P0 deseni tekrar.** Her subagent'a
  sıkı ruleset: yapıyı byte-koru, yalnız prose + frontmatter `description` çevir, link hedefi
  locale-eksiz kalır (`[x](PLACEMENT.md)`, `.en.md` DEĞİL), `{ #anchor }` sabit, mermaid node
  ID/edge sabit (yalnız subgraph etiketi çevrilir), kod/komut verbatim, positioning reframe,
  placeholder güvenliği. Hepsi rapor etti: link locale-eksiz, yapı korundu.
- **Kanonik EN blok adları (dizin slug'larından):** A Sezgi→**Intuition**, B Görebilmek→
  **Visibility**, C Tekrarlanabilirlik→**Reproducibility**, D Orkestrasyon→**Orchestration**,
  E Sahiplik→**Ownership**, F Karar→**Judgment**. P1b modül twin'lerinde de bunları kullan.
- **`~Ns` süre gösterimi → `~Nh`** (saat=hours). Twin'lerde tüm süre token'ları çevrildi.
- **PORTFOLIO.md frontmatter'sız** (H1 ile başlar) → twin de frontmatter'sız; "boş description"
  bir kusur değil, kaynakla birebir. Diğer 8 dosyanın `description`'ı İngilizce'ye çevrildi.
- **EN kapsama %0.9 → %3.6** (3 P0 + 9 P1a = 12 site sayfası / 334). Rehber twin'leri `2[0-9]-*`
  `cp -r` ile otomatik stage olur → build-docs.sh'e **ek satır gerekmedi** (P0'daki docs/Glossary
  elle-stage istisnasından farklı; onlar `2[0-9]-*` globu dışındaydı). Aşama B eşiği hâlâ %60.
- **QA'daki 1 UYARI = önceki turdan kalan `docs/index.en.md` false-positive** (P0 Açık
  kararlar'da kanıtla açıklandı). Bu turun 9 twin'i **yeni kırık link 0** ekledi; uyarı hâlâ
  tek dosya (`docs/index.en.md`), sayı değişmedi. İçerik kusuru değil.

### Faz 9.5 · EN twin P0 (önceki tur)
- **Blok kalktı — kullanıcı `qa.py`'yi genişletti (§15.4 sınırı korunarak).** `qa.py:156`
  `LOCALE_RE = \.[a-z]{2}\.md$`; `check_modules` (`qa.py:162`) ve `check_curriculum`
  (`qa.py:228`) artık `.en.md`/`.tr.md`'yi modül denetiminden ayırıyor. Ben `qa.py`'ye
  DOKUNMADIM (§15.4 yasak); kullanıcı yaptı + `.local/PAUSE`'u sildi = döngü devam sinyali
  (§14.2). Faz 2'den beri bekleyen EN twin tıkanması böyle çözüldü.
- **Kapsam = P0 (I18N-COVERAGE öncelik sırası).** Bir turda EN twin katmanının tamamı
  (P0…P4, 300+ sayfa) sığmaz → §14.1.3 dosya-seviyesi dilim. P0 = `README`/`docs-index`/
  `docs-about`/`Glossary` — dokümante edilmiş ilk adım. 4 `.en.md` üretildi.
- **`README.en.md` siteye stage EDİLMEZ (bilinçli).** Site homepage'i `docs/index.md`
  (build-docs.sh:7), README değil. `README.en.md` GitHub landing için — kökte, linkleri
  köke göre çözülür (qa temiz). Coverage oranı SİTE sayfası sayar → README dışı (3/334 ≈ %0.9).
- **build-docs.sh 3 satır eklendi (izinli — infra, qa.py değil, 00-21 değil):**
  `docs/index.en.md`→`index.en.md`, `docs/about.en.md`→`about.en.md`, `Glossary.en.md` stage.
  Numaralı klasörler (`cp -r`) zaten tüm `.en.md`'leri özyineli kopyalar → P1'de ek satır gerekmez.
- **QA'daki 1 UYARI = qa.py false-positive, içerik kusuru DEĞİL (§15.1 → buraya not).**
  `check_links` yalnız `docs/index.md`'yi pop eder (`qa.py:140`), locale twin'ini (`docs/index.en.md`)
  etmez. `docs/index.en.md` site-kökü göreli link kullanır (`00-Culture/` vb. — staged konumda
  `$STAGE/index.en.md` için DOĞRU); kaynak `docs/`'a göre çözülünce 29 "kırık" görünür → LP-dışı
  → UYARI (HATA değil, akış durmaz). **Kanıtlandı:** build sonrası `site/en/08-Security/
  DevSecOps-Pipeline/` vb. hedefler VAR; `/en/index.html` İngilizce intro ile render (TR fallback
  değil). Doğru düzeltme: kullanıcı `qa.py:140`'ı `docs/index.<locale>.md` da pop edecek şekilde
  genişletebilir (analog fix). Ben qa.py'ye dokunamam → not bırakıldı.
- **docs/about.en.md ve Glossary.en.md temiz (uyarı yok):** about yalnız `index.md`'ye linkler
  (`docs/index.md` var → çözülür); Glossary'de iç markdown link yok.
- **Positioning reframe uygulandı (Faz -1(b) kuralı EN tarafında):** hiçbir twin "Türkçe
  kaynak/rehber/yazılır" demiyor → "deep TR/EU regulatory coverage olan handbook". KVKK/BDDK
  içeriği kaldı, global okur çerçevesiyle. Grep doğrulaması temiz.
- **Çeviri subagent deseni (P1'de tekrar kullan):** 4 paralel sonnet subagent, dosya başına bir,
  sıkı ruleset (yapı byte-korunur, yalnız prose+frontmatter description çevrilir, link path'i
  ek-siz korunur, `{ #anchor }` id'leri sabit, placeholder güvenliği). README subagent'ı ToC +
  Quick-Start anchor'larını çevrilen başlık slug'ına göre güncelledi (proaktif, doğru).

### Faz 9.5 (önceki tur — A0 + entegrasyon)
- **A0'ın kapsamı = A1'in ÖNÜ, tekrarı değil (kısıt #1).** A1 process/izin/kullanıcı
  derinliğine iner; A0 ondan önceki katmandır: çalışan terminal + ortam + ergonomi +
  oryantasyon. Kurulum adımları tekrar edilmedi → `COST-GUARDRAILS.md`'ye devredildi.
  §14.3(1): 3 özgün A0 cümlesi repo-genelinde grep → yalnız A0. Gezinme bölümü (`pwd/ls/cd`)
  bilinçli **ergonomik** (dolaşmak), A1'in FHS/find/izin derinliğiyle örtüşmez.
- **A0 lab'sız (C0 deseni):** MODULE-SPEC A0'a L## atamaz; pratik = kabul kriterleri (ortamı
  kur + `uname/whoami/nano/man` ile kanıtla). Uydurma lab linki yok. Kabul kriterleri
  doğrulanabilir (komut çıktısı / yazılı cümle) — "anladım" yok (qa öznel-kriter deseni temiz).
- **Süre: A0 = 6s → Blok A 97 → 103, toplam 477 → 483.** §3.5 dürüst tavan: A0 gerçek iş
  (VM kurulumu + terminal alışkanlığı yeni başlayan için saatler alır), düşük gösterilmedi.
  CURRICULUM'daki stale "~453s modül" figürü de bu tur ~423'e düzeltildi (blok toplamı 417→423).
- **DAG: A0 → A1 geriye işaret ediyor** (rank ("A",0) < ("A",1)) → qa `check_modules` ön-koşul
  denetimi temiz. A0 yeni **tek giriş noktası**; CURRICULUM/PLACEMENT "A1 tek giriş" metinleri
  A0'a güncellendi. Developer/sysadmin rampaları A0'ı atlayabilir (ortam zaten var — PLACEMENT'ta yazılı).
- **MODULE-SPEC'e onay-sonrası ek yazıldı (şeffaflık):** STATE "A0 MODULE-SPEC'te işaretli"
  diyordu ama DEĞİLDİ — A0 Faz 9 review turlarında kararlaştırılan onay-sonrası eklemedir.
  Onaylı 28-modül tablosu **yeniden yazılmadı**; alta ayrı "ONAY SONRASI EK" bölümü eklendi
  (gerekçe + tek-satır tablo + süre etkisi). `_planning` dosyası → site/qa etkisi yok.
- **EN twin = §14.2-b tıkanma (kullanıcı-gated).** BUILD-PROMPT §10 program bitti; kalan tek
  iş EN twin ve o qa.py değişikliği olmadan üretilemez. Bu turda A0 (bloke-olmayan iş) bitirildi,
  sonra `.local/PAUSE` oluşturuldu. Loop kill-switch: kullanıcı qa.py'yi genişletip PAUSE'u silince devam.

### Faz 9 kapanışı (önceki tur — Blok E+F + çıktı kapısı)
- **Giriş durumu = limit-break kurtarma.** Önceki tur (`0de0c00 "wip: Faz 9 ara kayıt (limit
  molası)"`) Blok C+D bulgularını (14) düzeltip commit etmiş (REVIEW-FINDINGS C/D ✅) ama
  STATE Faz-durumu tablosunu güncellememişti; ayrıca Blok E+F için **inline düzeltmeleri
  yapıp commit etmeden** bırakmıştı (E1/E2/E4/E5/F1 working-tree'de M). Bu tur o iş
  doğrulandı, tamamlandı ve kapatıldı — yeniden yazılmadı.
- **E-03 prose köprüyle çözüldü (frontmatter değişmedi):** E2 önkoşulu `[E1,B1]` kaldı;
  E2→E1→B2 transitif (E1 prereq=`[B2,D2]`). E2 "Niye bu" bunu açıkça yazar. Frontmatter'a B2
  eklemek MODULE-SPEC/DAG ile ekstra tutarlılık yükü getirirdi; bağımlılık zaten sağlam →
  düşük-risk prose tercih edildi.
- **`bilişsel yük` Glossary'ye EN-anahtarlı girdi (`Cognitive load`, C bölümü):** Glossary
  EN|TR biçimli; kanonik terim Team Topologies'in "cognitive load"u. TR "bilişsel yük"
  açıklamada geçtiği için metin araması bulur; F3 zaten `Team-Topologies.md`'ye linkli.
- **6 yeni Glossary satırı = kısıt #1 ihlali değil:** hepsi tek-cümle tanım (deep-dive
  tekrarı değil); `Glossary.md` zaten 00-21 dışı kök referans dosyası (qa MOD_RE eşleşmez).
  §14.3(1): 3 yeni tanım cümlesi repo-genelinde grep → yalnız `Glossary.md`.
- **GLOSSARY-COVERAGE.md = çıktı kapısı artefaktı** (`_planning`, siteye stage edilmez):
  16 Faz-9 terimi + blok-içi çekirdek terim envanteri; açık boşluk 0. İki-kaynak kuralı
  (inline gloss ve/veya Glossary) belgeli.

### Faz 9 kararları (önceki tur — Blok A+B review)
- **§9 kapsam kararı (A-05/D-08/C-03'te tekrar eder):** Dört-alan dış-kaynak sözleşmesi
  **yönlendirilmiş dış okuma** linkleri içindir. İhtiyaç-anında tekil referans (man page,
  tool wiki, GitHub release sürüm bakışı) muaf — muafiyet A5 modülünde açıkça yazılı
  ("dört-alanlı sözleşme yönlendirilmiş okuma içindir, tekil arama için değil"). İç repo
  "Önce oku" deep-dive linkleri 3-alanlı hafif formatta kalır (§9 "dış link" der). **İstisna
  C-03:** C0'da Python tutorial'ı C-01 nedeniyle fiilen zorunlu → orada 4 alanla verilmeli.
- **B-04 süre — DEĞİŞMEDİ (gerekçeli ➖):** Denetçi B3=12s'i "şişkin" buldu. §3.5 "süreyi
  kısa göstermek güven kaybının en hızlı yolu" — asıl risk DÜŞÜK tahmin; şişkin tahmin
  öğreneni erken bitirince olumlu. Blok toplamı B36 onaylı plan. Süre = modül + lab + yazım
  + acemi tekrarı. Hours düşürülmedi.
- **A-05 ShellCheck linki — DEĞİŞMEDİ (➖):** §9 muafiyeti in-module belgeli (yukarı).
- **A-02 (A6 unit) L06 app.py ile hizalandı:** app `APP_HOST`/`APP_PORT` okur (`DB_URL`
  değil — `pg_isready` defaults kullanır); app.env'e `APP_PORT` eklendi, `DB_URL` "korunan
  sır örneği" olarak kaldı; `ReadWritePaths` yorumlandı (app diske yazmıyor). Unit artık
  birebir kopyalanınca çalışır.
- **B-01 Prometheus kurulumu B2 §3'e eklendi:** node_exporter reçetesinin yanına tam
  systemd Prometheus (config heredoc + `--config.file`/`--storage.tsdb.path`/9090 + servis
  kullanıcısı). "aynı kalıpla kurulur" tek-cümle geçiştirmesi kaldırıldı. Kısıt #1: temel
  kurulum adımları, `Prometheus-Best-Practices.md` deep-dive'ının (naming/retention/recording
  rules) tekrarı DEĞİL — §14.3(1) grep temiz.
- **REVIEW-FINDINGS.md `_planning`'de** (siteye stage edilmez) — 40 bulgu, blok blok, durum
  kolonlu. Faz 9'un canlı iş listesi burası; her tur güncellenir.

### Faz 8 kapanışı (önceki tur)
- **Geri-link kapsamı = yalnız "Önce oku" tablosunda anılan deep-dive'lar (43 dosya).** §8/§10
  Faz 8 "Hangi deep-dive'lar hangi modülde 'Önce oku'da anılıyorsa onlara. Kapsamı dar tut,
  her dosyaya değil" der. Modüllerin **yalnız `## 📖 Önce oku` bölümünü** ayrıştıran script
  ile 43 hedef bulundu (Kendini-test/Takıldıysan linkleri hariç → daha dar, daha savunulabilir).
  125 deep-dive'ın ~1/3'ü; "her dosyaya değil" kuralına uyar. Çok-modüllü dosyalar (ör.
  Blameless-Postmortem → E3+F4) tüm modülleri linkli listeler.
- **Geri-link = §3 kısıt #2'nin ADLI istisnası.** "00-21 değiştirme, tek istisna Faz 8 dosya
  sonuna tek satır geri-link." 43 dosyaya `---` + tek blockquote (`🎓 Öğrenme Patikası: Bu
  doküman [`X`](...) modülünde "Önce oku" kaynağı...`). İçerik yeniden yazılmadı, salt footer.
  Idempotent script (marker varsa atlar). 46 hedef link (`os.path.exists`) doğrulandı, kırık 0.
- **22-Learning-Path zaten `2[0-9]-*` globuna dahil** (build-docs.sh:58) — doğrulandı, glob
  değişmedi. Eklenen: (a) `_planning` staging'den `rm -rf` (çift emniyet; `exclude_docs`'ta
  da var), (b) özel `.pages` (başlık `🎓 Öğrenme Patikası` + iç sıra: README→rehberler→
  bloklar→capstone/sertifika/lab), (c) 9 alt-klasör başlığı (Blok A..F, Capstone, Sertifika,
  Lab), (d) kök nav'da `22-Learning-Path` **RoadMap'ten önce**.
- **`.pages` başlığı TR, EN nav_translations'ta** (§8 "nav_translations ile EN başlık"):
  `"🎓 Öğrenme Patikası": "🎓 Learning Path"` — mevcut Roadmap/About/Sözlük/Etiketler
  deseniyle birebir. BUILD-PROMPT'taki `🎓 Öğrenme Patikası / Learning Path` ifadesi bu
  iki-dilli çift olarak yorumlandı (RoadMap deseni), tek string değil.
- **RoadMap "A — Yeni Başlayan" eski liste `<details>` arşivinde korundu** (§10 "eski liste
  özet olarak kalır" — silme). Üstüne redirect kutusu: gap #1'i (linux-troubleshooting =
  ileri SRE materyali) açıkça anlatıp patikaya yönlendirir. `🆕 0'dan başlıyorum` kartı da
  patikaya bağlandı. Ünvan/süre iddiası ("90 günde junior") kaldırıldı → patika bunu vaat etmez.
- **`site_src/` + `site/` gitignore'da** — commit'e girmiyor (doğrulandı, git status'ta yok).

### Faz 7 kapanışı (önceki tur)
- **`18-Career/CV-Tips.md` düzenlendi — §10 Faz 7'nin ADLI istisnası.** §3 kısıt #2 "00-21
  değiştirme, tek istisna Faz 8 geri-link" der; ANCAK §10 Faz 7 açıkça "`18-Career/CV-Tips.md`
  ile çift yönlü bağla" diyerek bu dosyayı isimle çağırır (Faz 6.5 de aynı gerekçeyle
  düzenlemişti). Değişiklik minimal: Referanslar listesine **tek satır** PORTFOLIO.md link'i.
  İçerik yeniden yazılmadı.
- **Kısıt #1 (kopyalama değil, LINK) korundu.** F1–F5 "sıralayıcı" modüller: her biri 75–79
  satır (qa `≤220` sıralayıcı eşiğinin çok altında), "Önce oku" tabloları `12-FinOps`/
  `13-Platform-Engineering`/`19-Compliance`/`20-Soft-Skills`/`08-Security` deep-dive'larına
  link veriyor, açıklayıcı içerik tekrar edilmedi. §14.3(1) 4 özgün cümle grep → LP dışı 0.
- **"senior olur" substring tuzağı (qa marketing regex):** PORTFOLIO.md'de ünvan iddiasını
  **reddeden** cümle ilk taslakta "mid/senior olursun demez" yazıyordu; `senior olur`
  substring'i qa.py `check_marketing`'e takılırdı (regex bağlam/negasyon anlamaz). Cümle
  "şu ünvana geçersin gibi bir cümle burada geçmez" olarak yeniden yazıldı. Kandırma değil —
  anlam aynı (ünvan reddi), yalnız yasak substring kaldırıldı.
- **F teslim egzersizleri "yazılı çıktı" ile doğrulanabilir yapıldı (revizyon 9 + §12.3).**
  F1 `finops-analiz.md`, F2 `tehdit-modeli.md`, F3 `golden-path-onerisi.md`, F4 ADR+postmortem,
  F5 `karar-yazisi.md`. Kabul kriterleri dosya varlığı/içerik üzerinden ölçülür, "anladım" yok
  (qa öznel-kriter deseni temiz). §4.5 NOT-YET ilkesi F3'te ("ne zaman erken") pekiştirildi.
- **PORTFOLIO.md CV bulle şablonlarında metrik `<...>` placeholder.** §1 "kaynaksız istatistik
  yok" + CLAUDE.md placeholder güvenliği: uydurma sayı yerine öğrencinin kendi ölçtüğü değeri
  yazacağı `<önce>`/`<sonra>` placeholder'ı. `%X artış` kalıbından kaçınıldı (qa marketing).

### Faz 5 kapanışı (önceki tur)
- **Blok E lab'ları giriş anında zaten commit'liydi (elle/karışık geçmiş) — bu tur
  doğrulandı, yeniden yazılmadı.** `a0994d3` ("ara kayıt (elle)") L18–L20 + K07–K09'u
  ekledi ama K09'un `solution.md`+`verify.sh`'i eksikti; onları **yanlış mesajlı**
  `a6b75ef` commit'i ("Faz 9.5 …") tamamladı — o commit gerçekte Faz 9.5 işi YAPMADI,
  yalnız K09'un 2 dosyasını + STATE'e 9.5 satırını ekledi. **Faz 9.5 hâlâ ⬜** (A0/EN
  twin yapılmadı). Bu tur altı Blok E lab'ı tek tek okundu: anatomi tam, CLAUDE.md tonu,
  güvenlik ipliği (K08 backup erişim/at-rest, K09 blast-radius sınırlı), `bash -n` temiz,
  pazarlama/placeholder sızıntısı yok, özgün (3 cümle repo-genelinde grep → LP dışı 0).
- **30 modül→lab pointer'ı canlı markdown link'e çevrildi (Faz 5 kapanış işi).** Tüm
  L01–L20 + K00–K09 dizinleri artık var; `👉 \`labs/…/\` — Faz 5'te oluşturulacak.`
  code-span'leri `👉 [\`labs/…/\`](../labs/…/)` link'ine dönüştü, "Faz 5'te" ibaresi
  kaldırıldı. A/B görev-taslağı açıklamaları korundu. qa.py link denetimi dizin link'ini
  (`os.path.exists`) kabul ediyor → QA exit 0. Kapsam: yalnız `block-*/` pointer satırları
  (24 dosya, +33/−31), `00-21` ve lab içeriği değişmedi.
- **C0 (ops-python) ayrı lab dizini yok — dürüstçe yeniden çerçevelendi.** MODULE-SPEC C0'a
  L## atamıyor. Pointer, olmayan bir lab'a link vermek yerine "ayrı lab yok; pratik =
  kabul kriterleri; yazdığın aracı C2/L10 pipeline'ında kullanırsın" oldu. Uydurma link yok.
- **D2:52 "garanti ettiği" — teknik (K8s requests), dokunulmadı.** §14.3(2) taraması bunu
  yakalar ama pazarlama değil; bu tur değişmedi (yalnız D2 pointer satırları). Önceden
  kabul edilmiş karar.

### Faz 2'de alınanlar
- **⚠️ EN twin'ler ertelendi — `qa.py` çakışması, İLERİDE KULLANICI MÜDAHALESİ GEREKİR.**
  §7 "iki dil birlikte" kuralı + Faz 1 kararı EN twin öngörüyordu. ANCAK `qa.py`
  (değiştiremediğim dış denetçi) `^[A-F]\d+-` eşleşen **her** dosyada Türkçe bölüm
  başlıklarını (`🎯`, `Kabul kriterleri`, `Sırada`) zorunlu tutar (`qa.py:175`).
  `A1-…en.md` twin'i bu regex'e uyar → İngilizce başlıkla QA **kırılır**; Türkçe
  başlık koyup "İngilizce" demek **kandırma** olur (§15.4 yasak). Repoda 0 adet
  `.en.md` var (Faz -1'den beri). Karar: bu tur **TR içerik** yazıldı (asıl öğretici
  teslimat, QA exit 0); EN twin katmanı ayrı bir i18n turu (P1). Bunun için önce
  **kullanıcı `qa.py`'yi `.en.md` locale dosyalarını modül denetiminden ayırt edecek
  şekilde genişletmeli** (ben `qa.py`'ye dokunamam, §15.4). Sessiz kısıtlama değil,
  görünür eskalasyon. `I18N-COVERAGE.md` P1 durumu bunu yansıtacak.
- **build-docs.sh Bash 3.2 uyumlu yapıldı (taşınabilirlik).** Güncel `qa.py` mkdocs'u
  `python3 -m mkdocs` ile buluyor → `check_build` artık gerçekten çalışıyor. `build-docs.sh`
  `declare -A` (Bash 4+) yüzünden macOS varsayılan Bash 3.2'de patlıyordu (check_build
  ERROR). İki `declare -A` haritası (`TITLES`, `FN_TITLES`) `"anahtar|değer"` indeksli
  diziye çevrildi, Bash-4 guard'ı kaldırıldı. Davranış Bash 4+/CI'da aynı; yerelde artık
  **"Site hatasız derlendi"**. Gerçek build'i çalıştıran düzeltme, QA'yı kandırma değil.
- **A3 örnek IP'leri belge bloğuna çevrildi.** `example.com`'un gerçek IP'si sızmıştı
  → `192.0.2.10` (RFC 5737) + `2001:db8::10` (RFC 3849). `example.com` (RFC 2606 rezerve
  isim) kaldı — placeholder güvenliği korundu (qa leak guard temiz).
- **Modül derinliği revizyon 1 hedefine çekildi.** qa.py 🔴 EKSİK modüller için ~400–700
  satır derinlik denetliyor; ilk taslak (244–335) "ders yeterince derin mi?" uyarısı aldı →
  dördü de **gerçek beginner içerikle** derinleştirildi (A1: stdio/redirect/`PATH`;
  A2: subnet bit-math/NAT/DHCP/ARP + uçtan-uca teşhis; A3: çözümleme zinciri/HTTP
  metod+cookie/TLS el sıkışma; A4: restore/reset/revert/stash/reflog/`.gitignore`).
  **A1–A4: 379/314/316/314 satır** → QA **0 uyarı**.
- **B1–B3 derinlik uyarısı kapatıldı (bu tur), içerik özgün.** Önceki "ara kayıt"
  commit'i (c87c867) A5–B3 gövdelerini yazmış ama STATE'i güncellememişti; B1/B2/B3
  (281/240/231s) qa.py'nin `<300s` "ders yeterince derin mi?" UYARISI'nı tetikliyordu.
  Bu tur üçü de **kısıt #1'i ihlal etmeden** derinleştirildi (357/303/306s, QA 0 uyarı):
  B1'e journalctl derinliği (çıktı biçimi/alan süzgeci/`-b -1`/kalıcı journal/rate-limit) —
  `Logs-Loki-vs-ELK.md`'de yok; B3'e uçtan-uca **DNS** teşhis yürüyüşü (K01 gizli
  sebep setiyle *kasıtlı* örtüşmez) + zaman kutusu/eskalasyon disiplini. **B2 kasıtlı
  kısa/devir:** eklenen içerik `Prometheus-Best-Practices.md`'nin varsaydığı ama
  öğretmediği beginner iskelesi (anlık↔aralık vektör, scrape yaşam döngüsü + meta-metrik,
  `scrape_interval` ödünleşimi) — deep-dive tekrarı DEĞİL (naming/cardinality/histogram/
  recording-rules deep-dive'da kaldı). Üç özgün cümle repoda `grep` ile aranıp
  **bulunmadı**.

### Faz 5'te alınanlar (bu tur — Blok C+D lab'ları)
- **Yerel-önce her lab'da korundu.** C1/C2 docker + yerel `registry:2`; C3/C4 **LocalStack**
  (bulutsuz, `test`/`test` sahte kimlik — leak guard'ın `{12,}` uzunluk eşiğinin altında,
  gerçek credential değil); D1–D5 **kind** + guard'lı `kubectl`. Hiçbir lab gerçek para/bulut
  şart koşmaz (C4 bütçe alarmı hariç, o da `validate/plan` ile yerelde doğrulanır).
- **verify.sh iki mod (A/B deseni sürdü):** mekanik artefakt denetimi (report.txt/manifest
  grep) **+** guard'lı canlı kontrol (docker/kubectl/terraform varsa çalışır, yoksa `⚠️` ile
  atlanır). Böylece hepsi CI'da `bash -n` ve öğrenci makinesinde anlamlı.
- **Lab image sürümleri pinli (placeholder değil):** `postgres:16-alpine`,
  `nginxinc/nginx-unprivileged:1.27-alpine`, `python:3.12-slim`, `registry:2`,
  `busybox:1.36`. Çalışması gereken lab artefaktı reprodüksiyon için gerçek tag ister
  (`:latest` yasak — P0 #4 deseni). GitHub Actions örneklerinde (`ci.yml`) sürümler
  `@<VERSION>` placeholder (CLAUDE.md kuralı; gerçek repoda SHA-pin notu düşüldü).
- **Kırık lab kök sebepleri ayrıştırıldı (çakışma yok):** K02=port eşleme (host:container
  sağ taraf yanlış) · K03=**bayat state lock** (`.terraform.tfstate.lock.info` → force-unlock;
  gap #8) · K04=**çok-arızalı: ImagePullBackOff + izinsiz default-deny NetworkPolicy**
  (güvenlik ipliği) · K05=**çok-arızalı: OOMKilled (32Mi limit) + yanlış probe portu (9999)** ·
  K06=**drift + auto-sync kapalı** (L17 önkoşullu; `syncPolicy.automated` geri açılır).
  K04/K05 D-bloğu için bilerek çok-arızalı (BUILD-PROMPT §7.2 "D ve E'de birden fazla").
- **K06 L17 önkoşullu:** ArgoCD+Git gerçek runtime gerektirdiği için K06 setup, L17'nin
  `argocd/lab-app` Application'ını arar; yoksa "L17'yi tamamla" der (guard). Mekanik QA
  (4 dosya + bash -n) bundan bağımsız geçer. Makul varsayım; dependency zinciri D5-içi.
- **"garanti ed" qa marketing regex çakışması düzeltildi:** L10 README "neyi garanti eder"
  → "neyi kanıtlar". qa.py'nin `garanti ed` deseni bunu yakalıyordu; teknik "garanti"
  (K8s requests, L14) noun kullanımı desende yok, dokunulmadı. §14.3(2) LP `.md` taramasında
  0 hit.
- **Modül→lab pointer'ları bu tur GÜNCELLENMEDİ (bilinçli):** bkz. Sıradaki adım notu.

### Faz 5'te alınanlar (önceki tur — Blok A+B lab'ları)
- **Lab image sürümleri pinlendi (placeholder değil).** L08 compose'da `prom/prometheus:v2.53.0`
  ve `prom/node-exporter:v1.8.2` **gerçek sürümle** pinlendi. CLAUDE.md'nin `<VERSION>` kuralı
  *dokümantasyon snippet'leri* içindir; **çalışması gereken lab artefaktı** reprodüksiyon için
  gerçek tag ister (`:latest` yasak — P0 fix #4 deseni). Placeholder güvenliği (IP/credential)
  korundu; sürüm pin bir ihlal değil.
- **verify.sh iki mod:** (a) mekanik artefakt denetimi — öğrencinin `report.txt`/dosya izinleri/
  git durumu grep'lenir; (b) canlı kontrol — `curl`/`ss`/`systemctl` varsa çalışır, yoksa
  `⚠️` ile **atlanır** (hata değil). Böylece verify.sh hem CI'da (`bash -n`) hem öğrencinin
  makinesinde anlamlı. Öznel "anladım" kriteri yok → qa `check_modules` deseniyle uyumlu.
- **Kırık lab kök sebepleri ayrıştırıldı (çakışma yok):** K00 = eksik `EnvironmentFile`
  (systemd ön-hazırlık hatası); K01 = **port çakışması** (decoy servis 8080'i tutar).
  İkisi de B3 modülünün DNS teşhis yürüyüşünden **kasıtlı farklı** (STATE B3 notu korundu).
- **Lab placeholder güvenliği:** tüm .sh/.yaml/.env örneklerinde yalnız `127.0.0.1`/`10.x`/
  `lab.example` (RFC 2606) + `<DB_PASSWORD>` placeholder. `app.env.example` `.env` uzantısı
  taşımaz (leak guard'ın taradığı uzantı listesinde yok) ama yine de placeholder yazıldı.
  qa leak guard temiz.
- **labs/README.md eklendi** (modül değil → frontmatter gerekmez; MOD_RE eşleşmez). İki lab
  türünün anatomisi + "önce kendin dene" kuralı + bağımlılık notu.

### Önceki fazlardan taşınanlar (hâlâ geçerli)
- **i18n Aşama A:** TR varsayılan (kök), EN `/en/` fallback ile kısmi → boş/kırık EN
  sayfa yok. **Aşama B** (EN varsayılan): EN kapsama ≥ %60 olunca; şimdi değil.
- **9 onay revizyonu (Faz 0/1):** 200-satır tavanı yalnız 🟢; C0 (Python) A5'ten ayrı;
  A4/D1 🔴; süreler A97·B36·C88·D84·E64·F48+capstone60=~477s; K00 (A6) + K02 zorunlu;
  G3 CKS↔F2 Faz 6.5'e ertelendi; CAP1–3 eklendi; F1/F4 teslim egzersizleri işaretli.
- **Lab'lar kod-span olarak referanslı** (markdown link değil) — dizinler Faz 5'te doğar;
  "Önce oku"da yalnız **var olan** deep-dive'lara link.
- **GitHub-side rebrand elle yapılacak (gh CLI yok):** repo rename `DevOps`→`devsecops-handbook`,
  `description`+`topics`. **Custom domain verilmedi** → `site_url` fallback
  `https://halilibrahimd27.github.io/devsecops-handbook/`. Repo rename main'e merge ÖNCE.

## Bu oturumda yapılanlar (Faz 9.5 — EN twin P2: 21 klasör README'si · P2 TAMAMLANDI)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, `.local/PAUSE` yok. Giriş HEAD
`278c953`. Working-tree'de ` M README.md` (kullanıcının LinkedIn TR düzeltmesi — benim işim değil,
bkz. Açık kararlar) **+ 11 untracked `README.en.md` (00–10)** — önceki kesintili turun P2-dilim-1
işi (bkz. Açık kararlar "BENİMSENDİ"). Faz -1…9 hepsi ✅; Faz 9.5 sürüyor (A0 ✅, EN twin
P0/P1a/P1b ✅); sıradaki iş EN twin P2 (21 klasör README'si).

**Bu tur yapılan (Faz 9.5 · EN twin P2 — §14.1.3 dosya-seviyesi · P2 tamam):**
1. **00–10 (11 untracked twin) doğrulandı ve benimsendi.** Başlık/tablo paritesi 11/11, link-leak 0,
   positioning/pazarlama 0; 00-Culture tam + 08-Security/19-Compliance spot-read → kaliteli,
   structure-preserving. Körlemesine değil, doğrulama sonrası benimsendi.
2. **11–20 (10 twin) üretildi** (10 paralel sonnet subagent, dosya başına bir, sıkı ruleset):
   `11-SRE` · `12-FinOps` · `13-Platform-Engineering` · `14-Sustainability` · `15-AI-LLMOps` ·
   `16-Cheatsheets` · `17-Templates` · `18-Career` · `19-Compliance` · `20-Soft-Skills` → `README.en.md`.
3. **`_planning/I18N-COVERAGE.md`:** P2 → ✅ TAMAM; kapsama %14.1 → %20.4 (68/334).
4. **build-docs.sh'e dokunulmadı** — numaralı klasörler `cp -r` (build-docs.sh:68) ile 21 `.en.md`'yi
   özyineli stage ediyor (doğrulandı: `site_src/[0-2][0-9]-*/README.en.md` = 21).

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0 (1 UYARI).** 30 modül, 49 lab scripti, site iki locale hatasız
  derlendi, `_planning` sızmadı. Tek uyarı = önceki turların `docs/index.en.md` false-positive'i
  (29 kırık link / 1 dosya, birebir aynı); **bu turdan yeni kırık link 0**.
- **Yapısal parite (21/21 OK):** `grep -c '^#'` başlık + `grep -c '^|'` tablo satırı kaynak=twin
  (glob loop); link locale-eki grep → 0; positioning/pazarlama (TR+EN) grep → 0; her twin
  frontmatter `description` var (21/21).
- **İki-locale build:** `build-docs.sh` + `mkdocs build --clean` exit 0; 21 twin staged;
  `site/en/19-Compliance/` "engineering control"+"Turkey-specific notes" ile, `site/en/11-SRE/` +
  `site/en/17-Templates/` + `site/en/20-Soft-Skills/` İngilizce render; `_planning` YOK.
- **Spot-read:** `19-Compliance/README.en.md` (KVKK global-okur reframe + cross-ref locale-eksiz) +
  `18-Career/README.en.md` (seviye haritası + comp notları sadık, ünvan/maaş uydurması yok).
- **§14.3(1) tekrar:** çeviri (deep-dive rewrite değil), README index dosyaları. **§14.3(2):**
  TR+EN pazarlama/ünvan → 0. **§14.3(3) süre:** yeni modül yok → kümülatif ~483s sabit.

**Değişen/eklenen dosyalar (bu tur):** 21 × `[0-2][0-9]-*/README.en.md` (00-Culture … 20-Soft-Skills;
11'i untracked benimseme, 10'u yeni) · `_planning/I18N-COVERAGE.md` · `_planning/STATE.md`.
Hepsi `.en.md` twin + `_planning`; **hiçbir 00-21 içerik `.md` dosyası değişmedi**, `qa.py`'ye
dokunulmadı, `build-docs.sh` değişmedi. (` M README.md` commit'e DAHİL EDİLMEDİ — kullanıcı işi.)

---

## Önceki oturum (Faz 9.5 — EN twin P1b: Blok E+F, 11 twin · P1b TAMAMLANDI)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, `.local/PAUSE` yok. Giriş HEAD
`3c10144`. Working-tree'de ` M README.md` (kullanıcının LinkedIn TR düzeltmesi — benim işim değil,
bkz. Açık kararlar). Faz -1…9 hepsi ✅; Faz 9.5 sürüyor (A0 ✅, EN twin P0 ✅, P1a ✅, P1b A+B ✅,
P1b C+D ✅); sıradaki iş EN twin P1b Blok E+F (P1b'nin son dilimi).

**Bu tur yapılan (Faz 9.5 · EN twin P1b · Blok E+F dilimi — §14.1.3 dosya-seviyesi · P1b tamam):**
1. **11 EN twin `.en.md` üretildi** (11 paralel sonnet subagent, dosya başına bir, sıkı ruleset):
   - **Blok E (6):** `block-e-ownership/` → `E1-sli-slo-error-budget.en.md` · `E2-alerting-oncall.en.md` ·
     `E3-incident-postmortem.en.md` · `E4-veritabani-restore.en.md` · `E5-chaos.en.md` · `STAGE-EXAM.en.md`.
   - **Blok F (5):** `block-f-judgment/` → `F1-maliyet-finops.en.md` · `F2-tehdit-uyum.en.md` ·
     `F3-platform-idp.en.md` · `F4-yazma-adr-rfc.en.md` · `F5-stakeholder-vendor.en.md` (**STAGE-EXAM yok**).
2. **`_planning/I18N-COVERAGE.md`:** P1b → ✅ TAMAM (A0…F5 + A–E STAGE-EXAM = 35); kapsama %10.8 → %14.1.
3. **build-docs.sh'e dokunulmadı** — `block-*` twin'leri `2[0-9]-*` `cp -r` ile özyineli stage
   oluyor (doğrulandı: `site_src/22-Learning-Path/block-{e,f}-*/*.en.md` = 11).

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0 (1 UYARI).** 30 modül (twin'ler `LOCALE_RE` ile muaf), 49 lab
  scripti, site iki locale hatasız derlendi, `_planning` sızmadı. Tek uyarı = önceki turların
  `docs/index.en.md` false-positive'i (29 kırık link / 1 dosya, birebir aynı); **bu turdan yeni kırık link 0**.
- **Yapısal parite (11/11 OK):** `grep -cE '^#{1,6} '` başlık sayısı kaynak=twin
  (E: 10/10/10/11/10/6 · F: 10/10/10/10/10); link locale-eki grep → 0; residual TR-başlık grep → 0;
  her twin frontmatter `description` var; F-blok `## 🔨 Deliverable exercise` 5/5; metadata blok adı
  E→Ownership / F→Judgment 11/11; positioning + pazarlama (TR+EN) → 0.
- **İki-locale build:** `build-docs.sh` + `mkdocs build --clean` exit 0; 11 twin staged;
  `site/en/…/block-e-ownership/E1-sli-slo-error-budget/` "When you finish this module" ile,
  `…/block-f-judgment/F2-tehdit-uyum/` "F — Judgment" ile İngilizce render; `…/block-e-ownership/
  STAGE-EXAM/` render; `_planning` YOK (0).
- **Spot-read:** `E4-veritabani-restore.en.md` + `F2-tehdit-uyum.en.md` akıcı/sadık — E4 güvenlik
  ipliği (backup at-rest/erişim/audit) + "untested backup is not a backup" korundu; F2 KVKK→GDPR→
  SOC 2 kontrol zinciri + üçüncü-bakış (risk/uyum) çerçevesi korundu; komut/YAML/SQL verbatim.
- **§14.3(1) tekrar:** çeviri (deep-dive rewrite değil); `check_duplication` exit-0'da geçti.
  **§14.3(2):** TR+EN pazarlama/ünvan → 0. **§14.3(3) süre:** yeni modül yok → kümülatif ~483s sabit.

**Değişen dosyalar (bu tur):** `22-Learning-Path/block-e-ownership/{E1-sli-slo-error-budget,
E2-alerting-oncall,E3-incident-postmortem,E4-veritabani-restore,E5-chaos,STAGE-EXAM}.en.md` (6 yeni) ·
`22-Learning-Path/block-f-judgment/{F1-maliyet-finops,F2-tehdit-uyum,F3-platform-idp,F4-yazma-adr-rfc,
F5-stakeholder-vendor}.en.md` (5 yeni) · `_planning/I18N-COVERAGE.md` · `_planning/STATE.md`.
Hepsi patika-içi `.en.md` twin + `_planning`; **hiçbir 00-21 içerik dosyası değişmedi**, `qa.py`'ye
dokunulmadı, `build-docs.sh` değişmedi. (` M README.md` commit'e DAHİL EDİLMEDİ — kullanıcı işi.)

---

## Önceki oturum (Faz 9.5 — EN twin P1b: Blok C+D, 12 twin)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, temiz tree, `.local/PAUSE` yok.
Giriş HEAD `275e2de`. Faz -1…9 hepsi ✅; Faz 9.5 sürüyor (A0 ✅, EN twin P0 ✅, P1a ✅, P1b A+B ✅);
sıradaki iş EN twin P1b Blok C+D.

**Bu tur yapılan (Faz 9.5 · EN twin P1b · Blok C+D dilimi — §14.1.3 dosya-seviyesi):**
1. **12 EN twin `.en.md` üretildi** (12 paralel sonnet subagent, dosya başına bir, sıkı ruleset):
   - **Blok C (6):** `block-c-reproducibility/` → `C0-ops-python.en.md` · `C1-container.en.md` ·
     `C2-ci.en.md` · `C3-terraform.en.md` · `C4-bulut-butce-alarmi.en.md` · `STAGE-EXAM.en.md`.
   - **Blok D (6):** `block-d-orchestration/` → `D1-k8s-temel.en.md` · `D2-k8s-production.en.md` ·
     `D3-secret-yonetimi.en.md` · `D4-supply-chain.en.md` · `D5-gitops-argocd.en.md` · `STAGE-EXAM.en.md`.
2. **`_planning/I18N-COVERAGE.md`:** P1b → 🟡 Blok A+B+C+D ✅ (24) / kalan E+F (11); kapsama %7.2 → %10.8.
3. **build-docs.sh'e dokunulmadı** — `block-*` twin'leri `2[0-9]-*` `cp -r` ile özyineli stage
   oluyor (doğrulandı: `site_src/22-Learning-Path/block-{c,d}-*/*.en.md` = 12).

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0 (1 UYARI).** 30 modül (twin'ler `LOCALE_RE` ile muaf), 49 lab
  scripti, site iki locale hatasız derlendi, `_planning` sızmadı. Tek uyarı = önceki turun
  `docs/index.en.md` false-positive'i; **bu turdan yeni kırık link 0**.
- **Yapısal parite (12/12 OK):** `grep -cE '^#{1,6} '` başlık sayısı kaynak=twin
  (16/11/10/11/11/6 · 12/11/10/10/11/6); link locale-eki grep → 0; residual TR-başlık grep → 0;
  her twin frontmatter `description` var; positioning + pazarlama (TR+EN) → 0.
- **İki-locale build:** `build-docs.sh` + `mkdocs build --clean` exit 0; `site/en/…/block-d-
  orchestration/D1-k8s-temel/` "RBAC + NetworkPolicy" ile, `…/C2-ci/` "When you finish this
  module" ile İngilizce render; `…/block-d-orchestration/STAGE-EXAM/` render; `_planning` YOK (0).
- **Spot-read:** `D1-k8s-temel.en.md` akıcı/sadık — metadata `**Block:** D — Orchestration ·
  **Duration:** ~28h · **Prerequisites:**`; güvenlik ipliği (RBAC/NetworkPolicy "from day one")
  korundu; kod-içi yorum çevrildi, komut/YAML verbatim.
- **§14.3(1) tekrar:** çeviri (deep-dive rewrite değil); `check_duplication` exit-0'da geçti.
  **§14.3(2):** TR+EN pazarlama/ünvan → 0. **§14.3(3) süre:** yeni modül yok → kümülatif ~483s sabit.

**Değişen dosyalar (bu tur):** `22-Learning-Path/block-c-reproducibility/{C0-ops-python,C1-
container,C2-ci,C3-terraform,C4-bulut-butce-alarmi,STAGE-EXAM}.en.md` (6 yeni) ·
`22-Learning-Path/block-d-orchestration/{D1-k8s-temel,D2-k8s-production,D3-secret-yonetimi,D4-
supply-chain,D5-gitops-argocd,STAGE-EXAM}.en.md` (6 yeni) · `_planning/I18N-COVERAGE.md` ·
`_planning/STATE.md`. Hepsi patika-içi `.en.md` twin + `_planning`; **hiçbir 00-21 içerik dosyası
değişmedi**, `qa.py`'ye dokunulmadı, `build-docs.sh` değişmedi.

---

## Önceki oturum (Faz 9.5 — EN twin P1b: Blok A+B, 12 twin)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, temiz tree, `.local/PAUSE` yok.
Giriş `qa.py` exit 0 (30 modül, 1 uyarı = önceki turun docs/index.en.md false-positive'i).
Faz -1…9 hepsi ✅; Faz 9.5 sürüyor (A0 ✅, EN twin P0 ✅, P1a ✅); sıradaki iş EN twin P1b.

**Bu tur yapılan (Faz 9.5 · EN twin P1b · Blok A+B dilimi — §14.1.3 dosya-seviyesi):**
1. **12 EN twin `.en.md` üretildi** (12 paralel sonnet subagent, dosya başına bir, sıkı ruleset):
   - **Blok A (8):** `block-a-intuition/` → `A0-baslamadan-once.en.md` · `A1-linux-temeli.en.md` ·
     `A2-ag-tcp-ip.en.md` · `A3-ag-dns-http-tls.en.md` · `A4-git-temeli.en.md` · `A5-bash.en.md` ·
     `A6-elle-deploy.en.md` · `STAGE-EXAM.en.md`.
   - **Blok B (4):** `block-b-visibility/` → `B1-log-okuma.en.md` · `B2-metrik-prometheus.en.md` ·
     `B3-ilk-kirik-lab.en.md` · `STAGE-EXAM.en.md`.
2. **`_planning/I18N-COVERAGE.md`:** P1b → 🟡 Blok A+B ✅ (12) / kalan C-F (23); kapsama %3.6 → %7.2.
3. **build-docs.sh'e dokunulmadı** — `block-*` twin'leri `2[0-9]-*` `cp -r` ile özyineli stage
   oluyor (doğrulandı: `site_src/22-Learning-Path/block-{a,b}-*/*.en.md` = 12).

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0 (1 UYARI).** 30 modül (twin'ler `LOCALE_RE` ile muaf), 49 lab
  scripti, site iki locale hatasız derlendi, `_planning` sızmadı. Tek uyarı = önceki turun
  `docs/index.en.md` false-positive'i; **bu turdan yeni kırık link 0**.
- **Yapısal parite (12/12 OK):** `grep -cE '^#{1,6} '` başlık sayısı kaynak=twin
  (25/35/35/37/28/26/27/6 · 38/32/24/6); link locale-eki grep → 0; `.tr.md)` grep → 0; residual
  TR-başlık grep → 0; her twin frontmatter `description` var; positioning + pazarlama (TR+EN) → 0.
- **İki-locale build:** `build-docs.sh` + `mkdocs build --clean` exit 0; `site/en/22-Learning-Path/
  block-a-intuition/A1-linux-temeli/` "When you finish this module" ile İngilizce render;
  `site/en/…/STAGE-EXAM/` + B1 render; `_planning` YOK.
- **Spot-read:** `A1-linux-temeli.en.md` akıcı/sadık — metadata `**Block:** A — Intuition ·
  **Duration:** ~16h`; kod-içi yorum çevrildi (`# See the process chain…`, `← your shell`),
  komut/çıktı verbatim (`ps -o pid,ppid,user,comm --forest`).
- **§14.3(1) tekrar:** 3 özgün EN cümle repo-genelinde grep → yalnız kendi twin'i (deep-dive
  rewrite değil; `check_duplication` exit-0'da geçti). **§14.3(2):** TR+EN pazarlama/ünvan → 0.
  **§14.3(3) süre:** yeni modül yok (çeviri) → kümülatif ~483s sabit.

**Değişen dosyalar (bu tur):** `22-Learning-Path/block-a-intuition/{A0-baslamadan-once,A1-linux-
temeli,A2-ag-tcp-ip,A3-ag-dns-http-tls,A4-git-temeli,A5-bash,A6-elle-deploy,STAGE-EXAM}.en.md`
(8 yeni) · `22-Learning-Path/block-b-visibility/{B1-log-okuma,B2-metrik-prometheus,B3-ilk-kirik-
lab,STAGE-EXAM}.en.md` (4 yeni) · `_planning/I18N-COVERAGE.md` · `_planning/STATE.md`. Hepsi
patika-içi `.en.md` twin + `_planning`; **hiçbir 00-21 içerik dosyası değişmedi**, `qa.py`'ye
dokunulmadı, `build-docs.sh` değişmedi.

---

## Önceki oturum (Faz 9.5 — EN twin P1a: 9 rehber dosyası)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, temiz tree, `.local/PAUSE` yok.
Giriş `qa.py` exit 0 (30 modül, 1 uyarı = önceki turun docs/index.en.md false-positive'i).
Faz -1…9 hepsi ✅; Faz 9.5 sürüyor (A0 ✅, EN twin P0 ✅); sıradaki iş EN twin P1.

**Bu tur yapılan (Faz 9.5 · EN twin P1a dilimi — §14.1.3 dosya-seviyesi):**
1. **9 EN twin `.en.md` üretildi** (9 paralel sonnet subagent, dosya başına bir, sıkı ruleset) —
   `22-Learning-Path/` kökündeki rehber dosyaları:
   `NOT-YET.en.md` · `PLACEMENT.en.md` · `PROGRESS-TEMPLATE.en.md` · `STUDY-METHOD.en.md` ·
   `README.en.md` (LP-klasörü README'si, kök README DEĞİL) · `COST-GUARDRAILS.en.md` ·
   `TROUBLESHOOTING.en.md` (57 belirti→sebep→çözüm girdisi korundu) · `PORTFOLIO.en.md` ·
   `CURRICULUM.en.md` (mermaid node/edge sabit, subgraph etiketleri EN, 30 modül satırı korundu).
2. **`_planning/I18N-COVERAGE.md`:** P1 → P1a ✅ (9 rehber) / P1b ⬜ (30 modül) ayrıldı; kapsama
   %0.9 → %3.6 güncellendi.
3. **build-docs.sh'e dokunulmadı** — rehber twin'leri `2[0-9]-*` `cp -r` ile zaten özyineli
   stage oluyor (doğrulandı: `site_src/22-Learning-Path/*.en.md` = 9 dosya).

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0 (1 UYARI).** 30 modül, 49 lab scripti, site iki locale
  hatasız derlendi, `_planning` sızmadı. Tek uyarı = önceki turun `docs/index.en.md` twin
  false-positive'i; **bu turdan yeni kırık link 0**.
- **Yapısal parite:** 9/9 dosyada H1-H3 başlık sayısı kaynak=twin; link locale-eki grep → 0;
  positioning (Turkish-resource) grep → 0; frontmatter `description` İngilizce (PORTFOLIO
  frontmatter'sız, kaynakla birebir); CURRICULUM mermaid 6 subgraph EN + 30 modül satırı.
- **İki-locale build:** `build-docs.sh` + `mkdocs build --clean` exit 0; `site/en/22-Learning-
  Path/CURRICULUM/` İngilizce render ("Block A — Intuition" HTML'de), `_planning` YOK.
- **Spot-read:** `README.en.md` + `STUDY-METHOD.en.md` (dış-kaynak 4-alan tablosu) akıcı,
  sadık, disclaimer/exception'lar korundu.
- **§14.3(1) tekrar:** twin'ler onaylı LP rehber dosyalarının 1:1 İngilizce çevirisi → deep-dive
  rewrite değil; qa `check_duplication` exit-0'da geçti (İngilizce twin TR deep-dive'la örtüşmez).
- **§14.3(2) pazarlama/ünvan:** TR regex + EN scan (`become senior|guaranteed|salary|most
  comprehensive`) twin'lerde → 0.
- **§14.3(3) süre:** yeni modül yok (çeviri) → kümülatif ~483s sabit.

**Değişen dosyalar (bu tur):** `22-Learning-Path/{NOT-YET,PLACEMENT,PROGRESS-TEMPLATE,STUDY-
METHOD,README,COST-GUARDRAILS,TROUBLESHOOTING,PORTFOLIO,CURRICULUM}.en.md` (9 yeni) ·
`_planning/I18N-COVERAGE.md` · `_planning/STATE.md`. Hepsi patika-içi `.en.md` twin +
`_planning`; **hiçbir 00-21 içerik dosyası değişmedi**, `qa.py`'ye dokunulmadı, `build-docs.sh`
değişmedi.

---

## Önceki oturum (Faz 9.5 — EN twin P0)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, temiz tree. **`.local/PAUSE`
SİLİNMİŞ** (kullanıcı = döngü devam sinyali, §14.2). **`qa.py` DEĞİŞMİŞ** — kullanıcı
`LOCALE_RE` (`qa.py:156`) ekleyip `check_modules`/`check_curriculum`'u locale-farkında yaptı →
Faz 2'den beri bekleyen EN twin bloğu kalktı. Giriş `qa.py` exit 0 (30 modül).

**Bu tur yapılan (Faz 9.5 · EN twin P0 dilimi — §14.1.3 dosya-seviyesi):**
1. **4 EN twin `.en.md` üretildi** (4 paralel sonnet subagent, dosya başına bir, sıkı ruleset):
   - `README.en.md` (210s) — kök GitHub landing; positioning reframe (tagline/felsefe bullet1/
     "66K satır Türkçe"→"66K lines"); ToC + Quick-Start anchor'ları çevrilen slug'a güncellendi.
   - `docs/index.en.md` (330s) — EN hero homepage; TR/EN content-tab tek İngilizce paragrafa
     indirildi, `<span class="en">` tagline promote+span silindi, `{ #flagship/#kategoriler/
     #hizli-basla }` id'leri sabit, TR-spesifik kart global çerçeveye alındı.
   - `docs/about.en.md` (151s) — EN about; mevcut İngilizce tab içeriği promote edildi.
   - `Glossary.en.md` (511s, 310 terim) — başlık/intro reframe (Türkçeleştirme felsefesi
     çıkarıldı), tablo başlığı `| Term | Definition |`, TR açıklamalar İngilizce'ye; TR karşılık
     yararlı yerde parantezde kaldı (KVKK/VERBİS TR-regülasyon bağlamı korundu).
2. **build-docs.sh:** `docs/index.en.md`→`index.en.md`, `docs/about.en.md`→`about.en.md`,
   `Glossary.en.md` stage satırları eklendi (izinli infra; qa.py/00-21 değil).
3. **I18N-COVERAGE.md:** P0 ✅ (2026-07-23), P1 "sıradaki/BLOKE değil", EN oran %0.9 notu.

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0 (1 UYARI).** 30 modül, 49 lab scripti, site iki locale
  hatasız derlendi, `_planning` sızmadı. Tek uyarı = `docs/index.en.md` locale-twin
  false-positive (yukarı Açık kararlar'da kanıtla açıklandı; içerik kusuru değil).
- **Site kanıtı:** `site/en/index.html` İngilizce intro ile render (TR fallback DEĞİL);
  `site/en/{about,Glossary}/` üretildi; EN homepage'in site-kökü göreli linkleri (`08-Security/
  DevSecOps-Pipeline/` vb.) `site/en/…`'de gerçek hedeflere çözülüyor.
- **§14.3(1) tekrar:** `.en.md` twin'ler İngilizce → TR deep-dive'larla `check_duplication`
  örtüşmesi yok (qa temiz). P0 dosyaları LP-dışı zaten duplication denetimine girmez.
- **§14.3(2) pazarlama/ünvan:** twin'lerde "Türkçe kaynak/written in turkish" grep → 0;
  `.en.md` link'lerinde locale eki grep → 0.
- **§14.3(3) süre:** yeni modül yok (çeviri) → kümülatif ~483s sabit.

**Değişen dosyalar (bu tur):** `README.en.md` (yeni) · `docs/index.en.md` (yeni) ·
`docs/about.en.md` (yeni) · `Glossary.en.md` (yeni) · `scripts/build-docs.sh` ·
`22-Learning-Path/_planning/I18N-COVERAGE.md` · `22-Learning-Path/_planning/STATE.md`.
Hepsi kök `.en.md` twin + docs + infra + `_planning`; **hiçbir 00-21 içerik dosyası değişmedi**,
`qa.py`'ye dokunulmadı.

---

## Önceki oturum (Faz 9.5 — A0, KISMEN → PAUSE)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, PAUSE yok, temiz tree,
`qa.py` exit 0 (29 modül). Faz -1…9 hepsi ✅; sıradaki iş Faz 9.5 (A0 + EN twin).

**Bu tur yapılan (§10 sonrası STATE-ek Faz 9.5 · A0 parçası):**
1. **A0 modülü yazıldı** — `block-a-intuition/A0-baslamadan-once.md` (330s, TR, öğretici).
   İçerik: DevSecOps'un şekli · ortam kur (4 parça, COST-GUARDRAILS'e devir) · terminal
   ergonomisi (prompt/`$`↔`#`/Ctrl-C/D/L/Tab/history/kopyala-yapıştır güvenliği) · gezinme
   minimumu (5 komut) · yardım (`--help`/`man`/hata okuma) · nano · patika kullanım kılavuzu.
   Anti-pattern tablosu (8 satır) + doğrulanabilir kabul kriterleri + 3 kendini-test + Takıldıysan.
2. **Entegrasyon (5 dosya):** A1 önkoşulu `[A0]` + "Ön koşul" satırı · CURRICULUM (tablo satırı
   + mermaid `A0-->A1` + toplam 30 modül/~483s + "A0 tek giriş" + description 30) · README
   (yeni-mezun rampası A0 + `A0…F5` + ~483s) · PLACEMENT (rampa tablosu + "emin değilsen A0") ·
   COST-GUARDRAILS başlık `A0/A1`.
3. **MODULE-SPEC onay-sonrası ek** (şeffaflık — A0 review eklemesidir, onaylı 28'in dışı).
4. **`.local/PAUSE` oluşturuldu** — EN twin qa.py-bloke; kullanıcı müdahalesi bekleniyor.

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0.** 30 modül (A0 eklendi), 49 lab scripti `bash -n`, kırık
  iç link yok (A0'ın 5 iç linki + A1↔A0 dahil), site iki locale derlendi, `_planning` sızmadı.
- **İki-locale build:** `build-docs.sh` + `mkdocs build --clean` exit 0; A0 TR'de render, EN
  fallback'te var, `site/`'te `_planning` YOK.
- **§14.3(1) tekrar:** 3 özgün A0 cümlesi grep → yalnız A0 (deep-dive tekrarı yok, kısıt #1).
- **§14.3(2) pazarlama/ünvan:** A0 grep → 0 hit.
- **§14.3(3) süre:** A0=6s; Blok A frontmatter toplamı = 103 (6+16+14+16+12+12+27), CURRICULUM
  ile tutuyor. Kümülatif 477 → 483.

**Değişen dosyalar (bu tur):** `block-a-intuition/A0-baslamadan-once.md` (yeni) ·
`block-a-intuition/A1-linux-temeli.md` (önkoşul) · `CURRICULUM.md` · `README.md` ·
`PLACEMENT.md` · `COST-GUARDRAILS.md` · `_planning/MODULE-SPEC.md` · `_planning/STATE.md` ·
`.local/PAUSE` (yeni). Hepsi patika içi (00-21 değil) + `_planning` + PAUSE.

---

## Önceki oturum (Faz 9 — Blok E+F + çıktı kapısı, KAPANDI)

**Giriş durumu:** `STATE.md` okundu; branch `feat/learning-path`, PAUSE yok. `qa-report.txt`
GEÇTİ ama bayat (son commit sonrası). Working tree'de 5 dosya `M` (E1/E2/E4/E5/F1) —
`0de0c00 "wip: Faz 9 ara kayıt (limit molası)"` turunun **commit edilmemiş** Blok E+F inline
düzeltmeleri. Diff okundu: E-01/E-02/E-04/E-05/E-06 + F-01/F-04 inline zaten uygulanmış; eksik =
Glossary satırları + GLOSSARY-COVERAGE.md + REVIEW-FINDINGS/STATE güncellemesi.

**Bu tur yapılan (§10 Faz 9 kapanışı):**
1. **Glossary'ye 6 terim** (eksik olanlar; grep'te `ack`→Backstage, `ADR`→CIDR/adres,
   `NAT`→alternatifi false-positive'leri elenerek doğrulandı): A bölümü `ack`/`ADR`/
   `Alertmanager`, C bölümü `Cognitive load` (bilişsel yük), R bölümü `Reserved Instance (RI)`/
   `Right-sizing`. `egress`/`NAT`/`burn rate` zaten vardı (C-07/prev), `semver`/`LocalStack`/
   `kind`/`k3s`/`Taint`/`Free tier`/`ICMP` de.
2. **E+F inline düzeltmeleri doğrulandı/kapatıldı:** E-01 (Alertmanager tanım), E-02 (E4 şema
   kabul kriteri), E-03 (E2 prose B2 köprü), E-04 (E1 burn-rate köprü), E-05 (ack gloss),
   E-06 (E5 kabul#3 yumuşatma), F-01 (F1 grep→yazılı "İş tarafı" paragrafı), F-04 (F1 Capstone
   linkleri). REVIEW-FINDINGS E/F blokları `✅`, gerekçeli `➖`: F-06.
3. **`_planning/GLOSSARY-COVERAGE.md` çıkarıldı** (Faz 9 çıktı kapısı) — 16 terim + blok-içi
   çekirdek envanteri, açık boşluk 0.
4. **REVIEW-FINDINGS.md kapanış özeti** (A5·B8·C7·D8·E6·F6, `⬜`=0) + GLOSSARY-COVERAGE gate ✅.

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0.** 29 modül, 49 lab scripti `bash -n`, kırık iç link yok,
  site iki locale derlendi, `_planning` sızmadı.
- **§14.3(1) tekrar:** yeni prose (E1/E2 köprü) + 6 Glossary tanımı → grep repo-genelinde
  yalnız kendi dosyasında; deep-dive tekrarı yok (kısıt #1).
- **§14.3(2) pazarlama/ünvan:** 22-LP grep → yalnız önceden-kabul teknik "garanti" (D2/L14/K05
  `requests`). Yeni pazarlama 0. Geniş tarama (`maaş|ROI|%..artış|en kapsamlı`) temiz.
- **§14.3(3) süre:** yeni modül yok (mevcut E/F modüllerine kısa ekleme + Glossary) →
  kümülatif ~477s sabit.

**Değişen dosyalar (bu tur):** `Glossary.md` · `block-e-ownership/E1,E2,E4,E5` ·
`block-f-judgment/F1` (limit-break'ten devralınan inline'lar + bu tur) · `_planning/REVIEW-
FINDINGS.md` · `_planning/GLOSSARY-COVERAGE.md` (yeni) · `_planning/STATE.md`. `Glossary.md` =
00-21 dışı kök referans (qa MOD_RE eşleşmez); `block-*` = patika içi (00-21 değil).

---

## Önceki oturum (Faz 9 — Blok A+B düşmanca review, KISMEN)

**Giriş durumu:** Faz 8 önceki tur kapanmıştı. `e47d703 "wip: ara kayıt"` commit'i Faz 9'u
başlatmış (TROUBLESHOOTING 55 madde + dağınık modül/verify.sh rötuşları) ama REVIEW-FINDINGS
oluşturmamış ve STATE'i güncellememişti. Bu tur giriş kontrolü: `qa.py` exit 0, PAUSE yok,
branch `feat/learning-path`, temiz tree. TROUBLESHOOTING dolu (55 madde > 40 kapısı) doğrulandı.

**Bu tur yapılan (§10 Faz 9 — yeni başlayan simülasyonu):**
1. **6 paralel "yeni başlayan" denetçisi** (blok başına biri) A1→F5 sırayla okudu; 40 bulgu
   çıktı → `_planning/REVIEW-FINDINGS.md` (8 kategori, önem sıralı, durum kolonlu).
2. **Blok A düzeltildi (5 bulgu):** A-01 COST-GUARDRAILS'e somut Linux kurulum bölümü
   (WSL2/Multipass/VirtualBox); A-02 A6 systemd unit L06 app.py ile hizalandı (kopyalayınca
   çalışır); A-03 A4 `cherry-pick` (öğretilmemiş) → `reset --soft`+`switch`; A-04 ICMP gloss
   + Glossary; A-05 ➖ (§9 muafiyeti belgeli).
3. **Blok B düzeltildi (8 bulgu):** B-01 B2 §3'e tam Prometheus systemd kurulumu; B-02 L08
   Görev 1'e systemd-atlama notu; B-03 node_exporter/Prometheus indirmesi `uname -m`→ARCH
   (arm64 tuzağı); B-05 §5 app-metrik sorgusuna "şimdi no-data" notu; B-06 systemd-tmpfiles
   gloss; B-07 B1 yanlış "K00/K01 disk-dolu" iddiası genelleştirildi; B-04/B-08 ➖ (gerekçe
   Açık kararlar'da).
4. **Glossary.md:** `ICMP` eklendi (A-04). (semver/LocalStack/kind/k3s/NAT/egress/Alertmanager/
   ack/ADR… ilgili blok turlarında eklenecek — REVIEW-FINDINGS'te izli.)

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0.** 29 modül, 49 lab scripti `bash -n`, kırık iç link yok
  (COST-GUARDRAILS→A1 yeni linki dahil), site iki locale derlendi, `_planning` sızmadı.
- **§14.3(1) tekrar:** yeni prose (Prometheus kurulum, Linux setup, glosslar) → 3 özgün cümle
  repo-genelinde grep, yalnız kendi hedef dosyasında. Deep-dive tekrarı yok (kısıt #1).
- **§14.3(2) pazarlama/ünvan:** 22-LP grep → yalnız önceden-kabul teknik "garanti" (K05/L14
  `requests`). Yeni pazarlama 0.
- **§14.3(3) süre:** yeni modül yok (mevcut A/B modüllerine ekleme) → kümülatif ~477s sabit.

**Değişen dosyalar (bu tur):** `_planning/REVIEW-FINDINGS.md` (yeni) · `COST-GUARDRAILS.md` ·
`Glossary.md` · `block-a-intuition/A2,A4,A6` · `block-b-visibility/B1,B2` ·
`labs/build/L08-metrik/README.md` · `_planning/STATE.md`. **`Glossary.md` = 00-21 dışı kök
dosya** (patika terimleri; qa MOD_RE eşleşmez). **`block-*`/`labs` = patika içi** (00-21 değil).

---

## Önceki oturum (Faz 8 — Entegrasyon, KAPANDI)

**Giriş durumu:** Faz 7 önceki tur kapanmıştı (STATE ✅). Bu tur `STATE.md` okundu, QA giriş
kontrolü (`qa.py` exit 0, PAUSE yok, branch `feat/learning-path`, temiz working tree) yapıldı,
Faz 8'e geçildi.

**Bu tur yapılan (§10 Faz 8):**
1. **Kök `README.md`** — patika **Hızlı Başlangıç'ın 1. satırı**: yeni `🎓 Sıfırdan
   başlıyorum` satırı → `22-Learning-Path/README.md`. Eski `🆕 "DevOps nedir?"` satırı
   Modern-DevOps-2026'yı "alanın kuşbakışı" olarak yeniden çerçeveledi (kırık ön-koşul
   zinciri artık beginner'ı yanlış yere yollamıyor). TOC "Yol Haritası & Felsefe"ye de
   patika satırı eklendi (RoadMap'ten önce).
2. **`RoadMap/README.md`** — "A — Yeni Başlayan" patikaya yönlendirildi: intro'ya + section A
   başına redirect kutusu (gap #1'i açıkça anlatır), `🆕 0'dan başlıyorum` kartı patikaya
   bağlandı, **eski 90 günlük haftalık liste `<details>` arşivinde korundu** (silinmedi,
   özetlendi). "90 günde junior" ünvan/süre iddiası kaldırıldı.
3. **`scripts/build-docs.sh`** — (a) `_planning` staging'den `rm -rf` (stage EDİLMEZ); (b)
   `22-Learning-Path/.pages` özel blok: başlık `🎓 Öğrenme Patikası` + iç sıra (README önce);
   (c) 9 alt-klasör başlığı (Blok A..F + Capstone/Sertifika/Lab); (d) kök nav'da
   `22-Learning-Path` **RoadMap'ten ÖNCE**. `2[0-9]-*` globu 22'yi zaten stage ediyor (doğrulandı).
4. **`mkdocs.yml`** — `nav_translations`'a `"🎓 Öğrenme Patikası": "🎓 Learning Path"`.
   `exclude_docs`'ta `_planning` zaten vardı (doğrulandı, dokunulmadı).
5. **43 deep-dive'a geri-link** (§3 kısıt #2 tek istisnası) — yalnız "Önce oku"da anılan
   dosyalara, idempotent script ile dosya sonuna `---` + tek blockquote. Çok-modüllü dosyalar
   tüm modülleri linkler.

**Doğrulama:**
- **`bash scripts/build-docs.sh` + `python3 -m mkdocs build --clean` → exit 0**, iki locale
  (TR kök + EN `/en/`) derlendi. `site/`'te `_planning` YOK; `22-Learning-Path` TR+EN'de var.
  (INFO anchor uyarıları dokunmadığım 3 dosyada — Mobile-CICD/Prometheus-Grafana/Modern-DevOps —
  önceden vardı, error değil.)
- **`python3 .local/qa.py` → exit 0, 0 UYARI.** 29 modül, 49 lab scripti, kırık iç link yok
  (46 geri-link hedefi + README/RoadMap redirect linkleri `os.path.exists` ile doğrulandı).
- **§14.3(1) tekrar:** bu faz yeni modül prose'u yazmadı (salt geri-link footer + nav/README
  config) → deep-dive tekrarı yok; qa `check_duplication` temiz.
- **§14.3(2) pazarlama/ünvan:** düzenlenen dosyalar (README/RoadMap/geri-linkler) grep → 0 hit.
  LP'deki 3 "garanti" = önceden kabul edilmiş teknik K8s usage (D2/L14/K05).
- **§14.3(3) süre:** yeni modül yok → kümülatif değişmedi (~477s).

**Değişen dosyalar (bu tur):** kök `README.md` · `RoadMap/README.md` · `scripts/build-docs.sh` ·
`mkdocs.yml` · **43 deep-dive** (`00-Culture`…`20-Soft-Skills` + `16-Cheatsheets` + `19`/`20`)
geri-link footer'ı · `_planning/STATE.md`. `00-21` edit'leri = §3 kısıt #2'nin **Faz 8 adlı
istisnası** (dosya sonuna tek satır geri-link).

---

## Önceki oturum (Faz 7 — Blok F + kariyer köprüsü, KAPANDI)

**Giriş durumu:** Faz 6.5 önceki tur kapanmıştı (STATE ✅). Bu tur `STATE.md` okundu,
QA giriş kontrolü (`qa.py` exit 0, PAUSE yok) yapıldı, Faz 7'ye geçildi.

**Bu tur yapılan (§10 Faz 7 + §4.2 Blok F + §4.6):**
1. **F1–F5 içeriği yazıldı** (`block-f-judgment/`) — iskeletlerdeki tüm `TODO`'lar dolduruldu.
   Her modül **üçüncü bakış çerçevesiyle** (§4.2 sonu): aynı sistemlere para/organizasyon/risk
   gözüyle dönüş. **F1** maliyet ayrımı + trade-off · **F2** STRIDE tehdit modeli + KVKK/SOC2
   kontrol/kanıt eşleme · **F3** platform/golden-path/Team Topologies (NOT-YET "ne zaman erken"
   pekiştirildi) · **F4** ADR + rubrikli postmortem (yazma egzersizi) · **F5** gerekçeli "hayır"
   + vendor/kilitlenme. Her modül: "Önce oku" (2–3 mevcut deep-dive link), teslim egzersizi,
   **yazılı çıktıyla doğrulanabilir** kabul kriterleri, 3 kendini-test (cevaplar repo linkli),
   4-satır "Takıldıysan" tablosu.
2. **`PORTFOLIO.md` oluşturuldu** (§5 kök dosya) — modül/capstone → CV satırı eşlemesi.
   Kanıt→etki ilkesi, 3 eşleme tablosu (capstone / F eseri / blok→yetenek), 4-adım
   eser→bulle akışı, 8-satır anti-pattern tablosu, checklist, referanslar. Ünvan iddiası
   açıkça reddedildi; CV metrikleri `<...>` placeholder (uydurma sayı yok).
3. **CV-Tips çift yönlü bağ** — `18-Career/CV-Tips.md` Referanslar'a tek satır PORTFOLIO.md
   link'i (PORTFOLIO zaten CV-Tips'e "Deneyim/Yetenekler" bölümlerine link veriyor).
4. **Entegrasyon köprüleri:** `README.md` "Bu klasörde ne var" tablosuna PORTFOLIO.md satırı;
   F5 "Sırada" → PORTFOLIO.md canlı link; CAP1–3 "Faz 7'de eklenecek `PORTFOLIO.md`"
   code-span'leri → canlı link + present tense (dosya artık var).

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0, 0 UYARI.** "5 modülde TODO" notu kayboldu (F1–F5 doldu),
  29 modül bütünlük geçti, 49 lab scripti `bash -n` temiz, site derlendi, `_planning` sızmadı.
- **§14.3(1) tekrar:** F modüllerinden 4 özgün cümle repo-genelinde grep → LP dışında 0 hit.
  qa `check_duplication` (2-ardışık-satır örtüşme) temiz. Kısıt #1 uyumlu (linkler, kopya değil).
- **§14.3(2) pazarlama:** qa `check_marketing` deseni LP'de (`_planning` hariç) → 0 hit.
  PORTFOLIO'daki "senior olur" substring tuzağı önden yakalanıp reddedici cümle yeniden yazıldı.
- **§14.3(3) süre:** F toplam = 10+12+10+10+6 = **48s** — revizyon 4 planı (F48) birebir tutuyor.
  Kümülatif: A97·B36·C88·D84·E64·F48 + capstone60 ≈ 477s (plan sabit).

**Değişen dosyalar (bu tur):** `block-f-judgment/F1..F5.md` (içerik) · `PORTFOLIO.md` (yeni) ·
`README.md` · `capstones/CAP1..CAP3.md` (PORTFOLIO link) · `18-Career/CV-Tips.md` (tek satır) ·
`_planning/STATE.md`. `00-21` edit'i yalnız CV-Tips (§10 Faz 7 adlı istisna) — tek satır geri-link.

---

## Daha önceki oturum (Faz 6.5 — Sertifika katmanı, KAPANDI)

**Giriş durumu — önemli:** Önceki tur kapı dosyalarını (G1/G2/G3 + HOW-TO-CERTIFY +
README) yazmış ve `d18804f` commit'iyle işlemiş ama **STATE'i güncellememişti** (Faz 6.5
hâlâ ⬜). O commit `21-Field-Notes/system/devops-certification-roadmap.md`'yi **sildi**
(221 satır) — §8.1'in istediği gibi *taşımadı*, geriye **yönlendirme bırakmadı** →
`21-Field-Notes/README.md:47` kırık link (qa UYARI). `LANDSCAPE.md` ara dosyası (pazarlama
dolu) commit edilmeden silinmişti. Bu tur önce **gerçek durum doğrulandı** (5 kapı dosyası
okundu: hepsi §8.2 9-bölüm tam, sürüm uyarılı, domain×modül boşluk sütunlu, ton temiz),
sonra **eksik §8 teslimatları tamamlandı**.

**Bu tur yapılan (Faz 6.5 eksiklerini kapatma):**
1. **§8.1 redirect** — `21-Field-Notes/system/devops-certification-roadmap.md` yeniden
   yazıldı: kısa yönlendirme sayfası (frontmatter + tablo → `certifications/` 5 dosyası).
   Eski "48 ayda 10 sertifika" planının kaldırıldığını açıkça söyler. **qa UYARI kayboldu.**
2. **`21-Field-Notes/README.md:47`** — "Senior seviye sertifika kariyer rehberi" →
   "3 sertifika kapısına yönlendirir (3 kapı, 10 değil)". Yanlış çerçeve düzeltildi.
3. **§8.2 entegrasyon — `RoadMap/README.md:179`** anti-pattern satırı: "Bir tane al" →
   "Blok başına 1 kapı — 3 kapı, 10 değil" + `certifications/` linki. Çelişki kalktı.
4. **§8.2 entegrasyon — `18-Career/CV-Tips.md`** §📜 Sertifikalar: 9-sertifika tablosunun
   altına "bu patikanın duruşu koleksiyon değil 3 kapı" kutusu + `certifications/` linki;
   "fark yaratır" pazarlama tonu yumuşatıldı. Tablo "piyasa haritası, yapılacaklar değil".
5. **§8.1 DCA + `certifications/README.md`** — LANDSCAPE'ten kalan çift/kırık-niyet satırı
   (68) kaldırıldı; yeni "🚪 Bu patikanın parçası olmayan sertifikalar" bölümü: CKAD/AWS
   DevOps Pro/GCP/Vault/PCA neden dışarıda + **Docker DCA legacy/tartışmalı statü notu**
   (öneri listesinde yok, kenarda not) + `../NOT-YET.md` linki.

**Doğrulama:**
- **`python3 .local/qa.py` → exit 0, 0 UYARI** (önceki tek UYARI = field-notes kırık link
  artık yok; mkdocs derlendi, `_planning` sızmadı, kırık iç link yok, leak yok).
- **§8.1 no-contradiction sweep:** repoda kalan tüm "10 sertifika / 48 ay / koleksiyon"
  mentionları **anti-pattern çerçevesinde** (NOT-YET satırı, G3 "eleştirdiği koleksiyon",
  README anti-pattern tablosu, redirect açıklaması). Çelişen iki cümle yok.
- **§14.3 otonom denetimler:** (1) tekrar: kapı dosyaları mevcut deep-dive'lara link veriyor,
  yeni açıklayıcı içerik yok (kısıt #1 uyumlu). (2) pazarlama: `grep -iE "maaş|ROI|%..artış|
  en kapsamlı|garanti"` LP'de → yalnız önceden-kabul teknik "garanti" (K8s requests: D2/L14/
  K05) + STATE meta; bu turdan **0 yeni pazarlama**. (3) süre: kapı dosyaları modül değil
  (estimated_hours yok) → N/A. 5 kapı dosyası zaten plana birebir (G1/G2/G3 + HOW-TO + README).

**Değişen dosyalar (bu tur):** `21-Field-Notes/system/devops-certification-roadmap.md` (yeni
redirect) · `21-Field-Notes/README.md` · `RoadMap/README.md` · `18-Career/CV-Tips.md` ·
`22-Learning-Path/certifications/README.md` · `_planning/STATE.md`. **Kapı içeriği (G1/G2/G3/
HOW-TO) `d18804f`'te zaten doğruydu — dokunulmadı.** `00-21` dosya edit'leri §8'in açık
istisnası (§8.1/§8.2 bu dosyaları isimle sayar).
