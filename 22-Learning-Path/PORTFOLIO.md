# PORTFOLIO — Modülden CV Satırına

> *"CV bir iddia listesi değil, bir kanıt dizinidir. Bu patika kanıtları üretir; bu sayfa onları CV satırına çevirir."*

Bu sayfa, patikada **ürettiğin somut eserleri** (capstone repoları, analiz yazıları, postmortem'ler)
CV'de karşılık gelen satıra bağlar. Kime yararlı: bir bloğu bitirmiş ve "bunu CV'ye nasıl
yazarım?" diye soran herkese. Bitirdiğinde, elindeki her artefaktın hangi yetkinliği
kanıtladığını ve bunu görev değil **etki** diliyle nasıl yazacağını bileceksin.

> ⛔ Bu sayfa bir ünvan vaat etmez: "şu bloğu bitirince şu ünvana geçersin" gibi bir
> cümle burada geçmez. Ünvan deneyim, kurum ve piyasayla belirlenir. Burada yalnız
> **kanıtlanabilir yetkinlik** ve onun CV'deki dürüst ifadesi vardır.

---

## 🎯 Temel ilke: kanıt → etki

Bir CV satırının gücü iki şeyden gelir: **kanıtlanabilir** olması (repoya/artefakta işaret eder)
ve **etki** anlatması (ne yaptığın değil, ne değiştiğin). Bu patikanın çıktıları ikisini de verir:
capstone'lar çalışan repo, F modülleri yazılı karar eseri üretir.

| ❌ Görev-bazlı (zayıf) | ✅ Etki-bazlı (kanıtlı) |
|---|---|
| "Terraform kullandım" | "Altyapıyı `apply`/`destroy` idempotent hâle getirdim; sıfırdan kurulum `<önce>` → `<sonra>`" |
| "K8s biliyorum" | "RBAC + NetworkPolicy'yi ilk günden içeren bir deploy kurdum; yetki yüzeyini varsayılan-kapalı yaptım" |
| "Monitoring yaptım" | "Bir arızayı log ve metrikle kanıtladım; SLO ihlalini alarma bağladım" |

> Etki bulle'lerini **kendi ölçtüğün** sayılarla doldur. Ölçmediğin sayıyı yazma — mülakatta
> sorulan ilk şey odur. Sayı yoksa "kurdum/kanıtladım/tekrarlanabilir kıldım" gibi doğrulanabilir
> fiil kullan, uydurma metrik değil.

---

## 🔧 1. Capstone → portfolyo projesi

Capstone'lar CV'nin omurgasıdır: her biri tek bir git reposu, yani **gösterilebilir** kanıt.
Her capstone kendi README şablonunu üretir; buradaki satır onu CV'ye taşır.

| Kaynak | Ürettiğin repo | CV'de karşılık gelen satır türü |
|---|---|---|
| [`Capstone 1`](capstones/CAP1-blok-c-sonu.md) | container + CI + Terraform, `RECREATE.md` ile sıfırdan kurulur | "Bir uygulamayı tekrarlanabilir şekilde kurdum: multi-stage image, sürümlü CI, idempotent IaC" |
| [`Capstone 2`](capstones/CAP2-blok-d-sonu.md) | K8s'e production-grade deploy (RBAC/NetworkPolicy/probe/HPA/GitOps) | "Bir servisi güvenli varsayılanlarla K8s'e aldım; GitOps ile deklaratif yönettim" |
| [`Capstone 3`](capstones/CAP3-blok-e-sonu.md) | SLO + alerting + incident + doğrulanmış restore | "Bir sistemi sahiplendim: SLO tanımladım, bir arızayı yönettim, backup'ı restore ederek doğruladım" |

> 🔒 Repo README'lerinde gerçek IP/domain/credential olmaz (capstone'ların placeholder kuralı).
> Herkese açık bir GitHub reposu paylaşacaksan bu bir sızıntı kontrolüdür, kozmetik değil.

---

## 🔧 2. Blok F eserleri → karar vericiliğin kanıtı

Blok F saf okuma değildir; her modül **yazılı bir eser** teslim eder. Bunlar L2 (karar
vericilik) yarıçapının en somut kanıtıdır — kod değil, muhakeme gösterir.

| Modül | Ürettiğin eser | CV'de karşılık gelen satır türü |
|---|---|---|
| [`F1`](block-f-judgment/F1-maliyet-finops.md) | `finops-analiz.md` — maliyet ayrımı + optimizasyon | "Bir iş yükünün maliyetini bileşenlerine ayırıp bir optimizasyonu sayıyla gerekçelendirdim" |
| [`F2`](block-f-judgment/F2-tehdit-uyum.md) | `tehdit-modeli.md` — STRIDE tablosu + kontrol/kanıt haritası | "Bir servis için tehdit modeli çıkardım; bir regülasyon maddesini somut kontrole bağladım" |
| [`F4`](block-f-judgment/F4-yazma-adr-rfc.md) | bir ADR + rubrikle değerlendirilmiş postmortem | "Mimari kararları ADR olarak yazdım; postmortem'leri suçlamasız ve eyleme dönük tuttum" |
| [`F5`](block-f-judgment/F5-stakeholder-vendor.md) | `karar-yazisi.md` — gerekçeli "hayır" + vendor değerlendirmesi | "Bir vendor kararını kilitlenme riskiyle değerlendirdim; bir isteğe gerekçeli 'hayır' yazdım" |

> F3'ün çıktısı (`golden-path-onerisi.md`) bir platform önerisi taslağıdır; CV satırından çok,
> platform/IDP konusunda **muhakeme** gösteren bir yazı örneğidir — mülakatta paylaşılır.

---

## 🔧 3. Bloklar → yetenek bölümü

CV'nin "Yetenekler" bölümünü doldururken hangi bloğun neyi kanıtladığını bil. Aşağıdaki
eşleme, [`CV-Tips.md`](../18-Career/CV-Tips.md) → "Yetenekler — Kategorize" bölümünü besler.

| Blok | Kanıtladığın alan | Dürüst seviye ifadesi |
|---|---|---|
| A–B | Linux, ağ, git, gözlemlenebilirlik temeli | temel — "kullanabilirim, arızasını daraltabilirim" |
| C | Container, CI, IaC, bulut temeli | orta — "tekrarlanabilir kurabilirim" |
| D | K8s, RBAC/NetworkPolicy, secret, supply chain, GitOps | orta-ileri — "güvenli varsayılanlarla işletebilirim" |
| E | SLO, alerting, incident, restore | ileri — "bir sistemi sahiplenebilirim" |
| F | FinOps, tehdit/uyum, platform, yazma, karar | karar — "hangi sistemin var olması gerektiğine tartışabilirim" |

> "Advanced / intermediate / basic" dürüst etikettir; "expert" iddiası mülakatta sorgulanır.
> Bir alanı ancak o bloğun kabul kriterlerini ve capstone'unu geçtiysen "orta/ileri" yaz.

---

## 🔧 4. Eseri CV bulle'ına çevir — 4 adım

1. **Artefaktı seç:** hangi capstone/yazı? (Kanıt buraya işaret edecek.)
2. **Etkiyi bul:** ne değişti? Sıfırdan kurulum süresi, arıza tespiti, güvenlik yüzeyi, maliyet.
3. **Ölç:** kendi ortamında `<önce>` ve `<sonra>` değerini yaz. Ölçemiyorsan doğrulanabilir fiil kullan.
4. **STAR'a sık:** durum → görev → eylem → sonuç; en güçlü bulle en üste. Detay: [`CV-Tips.md`](../18-Career/CV-Tips.md) → "Deneyim Bölümü".

---

## 🚫 Anti-Pattern Tablosu

| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "K8s, Docker, Terraform, AWS…" araç kusması | Ne yaptığını göstermez, herkes yazar | Aracı bir etkiye bağla: "X ile Y'yi kurdum, Z değişti" |
| Ölçmediğin metrik yazmak | Mülakatta ilk sorulan; çökersin | Yalnız kendi ölçtüğün sayı; yoksa doğrulanabilir fiil |
| Capstone repolarına link vermemek | Kanıtsız iddia = boş iddia | GitHub linki ver; README yabancı biri için anlaşılır olsun |
| Repoda gerçek IP/credential | Sızıntı; güvenlik farkındalığı yok görünür | Placeholder + referanslı sır (capstone kuralı) |
| Ünvan iddiası ("senior-level altyapı") | Ünvanı sen değil piyasa verir | Yetkinliği yaz: "bir sistemi sahiplendim" |
| Blok bitmeden "ileri" seviye yazmak | Kabul kriteri geçilmedi, blöf | Seviyeyi bloğun capstone'una bağla |
| Her role aynı CV | Etki bağlamı kaybolur | Artefaktları hedef role göre öne çıkar |
| F eserlerini gizlemek | Karar muhakemesi görünmez kalır | ADR/postmortem'i yazı örneği olarak paylaş |

---

## 📋 Checklist

```
[ ] Her capstone bir public (veya paylaşılabilir) repo; README yabancı biri için yeterli
[ ] Repolarda gerçek IP/domain/credential YOK (placeholder + referanslı sır)
[ ] Her CV bulle'ı bir artefakta işaret ediyor (kanıtlanabilir)
[ ] Sayılar kendi ölçtüğün; uydurma metrik yok
[ ] Seviye etiketleri bloğun capstone'una dayanıyor (blöf yok)
[ ] Ünvan iddiası yok; yetkinlik dili var
[ ] F eserleri (ADR/postmortem/karar yazısı) yazı örneği olarak hazır
[ ] CV, hedef role göre önceliklendirilmiş
```

---

## 📚 Referanslar

- [`18-Career/CV-Tips.md`](../18-Career/CV-Tips.md) — CV yapısı, etki-bazlı bulle, yetenek kategorileri
- [`capstones/`](capstones/) — CAP1–CAP3 şartnameleri + portfolyo README şablonları
- [`README.md`](README.md) → Dürüst tavan — son iki kapının niçin kendi kendine geçilemediği
- [`block-f-judgment/`](block-f-judgment/) — F1–F5, karar vericiliğin yazılı eserleri

---

> *"En iyi CV satırı, mülakatta 'bunu anlat' dendiğinde açıp gösterebildiğindir."*
