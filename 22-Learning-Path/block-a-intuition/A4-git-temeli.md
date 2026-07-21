---
description: "Git temeli: commit, branch, merge, rebase ve conflict — kodun ve altyapının değişim kaydı."
level: A
module: A4
estimated_hours: 12
prerequisites: [A1]
tags: [Learning Path, Git]
---
# A4 — Git Temeli: Commit, Branch, Merge, Rebase, Conflict

> *"Git bir yedekleme aracı değil, değişimin niçin'ini taşıyan kayıttır."*

**Blok:** A — Sezgi · **Süre:** ~12 saat · **Ön koşul:** [`A1`](A1-linux-temeli.md)

## 🎯 Bu modülü bitirdiğinde
- Sıfırdan bir repo kurar, anlamlı commit'lerle bir geçmiş oluşturursun.
- Branch açar, merge eder ve bir conflict'i elle, güvenle çözersin.
- Merge ile rebase arasındaki farkı ve ne zaman hangisini kullanacağını açıklarsın.

## 🧠 Niye bu, niye şimdi
C2'de (CI) ve C3'te (Terraform) her şey Git üzerinden akacak; GitOps'ta (D5) Git
tek gerçek kaynak olacak. Bu mekanizmayı önce elle, tek başına yaşamadan otomasyon
üzerine kurmak kör uçmaktır. Git'i "sihirli komutlar dizisi" olarak değil, **bir
commit grafiği (DAG)** olarak anladığında, korktuğun her durum (conflict, "kayıp"
commit, yanlış branch) sıradan bir grafik işlemine döner.

## 📖 Nasıl çalışılır
Gövdeyi oku ve **her komutu boş bir test reposunda** çalıştır (`git init` ile bir
oyun alanı aç). Git'i ezberleyerek değil, `git status` ve `git log --oneline --graph`
ile grafiği sürekli görerek öğren. Bu iki komut senin gözündür; her adımdan sonra bak.

## 📚 Kavram haritası
| Terim | Bir cümlede |
|---|---|
| **Commit** | Bir andaki dosya durumunun (snapshot) imzalı kaydı + mesaj + ana(lar) |
| **Working directory** | Üzerinde çalıştığın gerçek dosyalar |
| **Staging (index)** | Bir sonraki commit'e girecek değişikliklerin bekleme alanı |
| **Branch** | Bir commit'e işaret eden, hareket edebilen isim (`main`, `feature/x`) |
| **HEAD** | Şu an nerede olduğun — genelde bir branch'in ucu |
| **Merge** | İki geçmişi birleştiren commit |
| **Rebase** | Commit'leri başka bir taban üstüne **yeniden yazma** |
| **Conflict** | İki tarafın aynı satırı farklı değiştirmesi; Git karar veremez, sen verirsin |
| **Remote** | Reponun başka bir kopyası (`origin`) — GitHub vb. |

---

## 1️⃣ Zihinsel model: snapshot'lar ve üç alan

Git her commit'te dosyaların **tam bir fotoğrafını** (snapshot) saklar — "farkları"
değil (farkları o hesaplar). Her commit'in bir kimliği (hash) ve bir **anası** vardır;
zincirlenince yönlü bir grafik (DAG) oluşur. Bir branch, bu grafikte hareket eden bir
etiketten ibarettir.

Bir değişiklik commit olana kadar üç alandan geçer:

```
working directory  →  staging (index)  →  commit (repo)
   (git add)              (git commit)
```

```bash
git config --global user.name  "<AD_SOYAD>"
git config --global user.email "<EPOSTA>"     # commit'lere yazarını koyar
git init                       # boş bir repo yarat (.git dizini oluşur)
git status                     # nerede ne var: değişen, stage'lenen, takip edilmeyen
```

`git status`'u sık sık çalıştır. "Şu an ne durumdayım?" sorusunun cevabı hep oradadır.

## 2️⃣ Temel döngü: değiştir → stage → commit

```bash
echo "merhaba" > app.txt
git add app.txt                # değişikliği staging'e al
git commit -m "app.txt eklendi: ilk sürüm"
git log --oneline              # geçmişi tek satırlık özet olarak gör
# a1b2c3d app.txt eklendi: ilk sürüm
```

`git add` neden ayrı bir adım? Çünkü **hangi değişikliklerin bu commit'e gireceğini
sen seçersin.** İki dosyayı değiştirip yalnız birini commit'lemek, birbiriyle ilgili
değişiklikleri ayrı, anlamlı commit'lere bölmenin yoludur.

### İyi commit mesajı — altı ay sonraki sana mektup

```
kısa özet (50 karakter, emir kipi: "ekle", "düzelt")

Boş satırdan sonra: NİÇİN yaptığın. Kod "ne"yi zaten söyler;
commit mesajı "niçin"i taşır — bunu başka hiçbir yer taşımaz.
```

> `git log`, bir yıl sonra "bu satır neden böyle?" sorusunun cevabını taşıyacak tek
> yerdir. "değişiklik", "fix", "update" gibi mesajlar o cevabı yok eder. Reponun
> commit disiplini için [`CLAUDE.md`](../../CLAUDE.md) ve A6 sonrası alışkanlıkların
> temelini burada kur.

## 3️⃣ Branch ve merge: paralel çalışma

Bir branch, ana hattı bozmadan çalışmanı sağlar. İşin bitince ana hatta **merge**
edersin.

```bash
git switch -c feature/selamlama   # yeni branch aç ve ona geç (eski: git checkout -b)
echo "selam" >> app.txt
git commit -am "selamlama satırı eklendi"
git switch main                    # ana hatta dön
git merge feature/selamlama        # feature'ı main'e birleştir
git log --oneline --graph --all    # grafiği gör — dallanma ve birleşme
```

İki merge biçimi vardır:

| Durum | Ne olur | Sonuç |
|---|---|---|
| **Fast-forward** | `main`, feature'dan bu yana hiç ilerlemediyse | Etiket ileri kayar; ekstra commit yok, düz geçmiş |
| **Merge commit** | Her iki taraf da ilerlediyse | İki ana'sı olan bir birleştirme commit'i doğar |

Branch'i işin bitince sil (etiket gider, commit'ler kalır):

```bash
git branch -d feature/selamlama    # merge edilmiş branch'i güvenle sil
```

## 4️⃣ Conflict: Git karar veremez, sen verirsin

Conflict, iki branch **aynı satırı farklı** değiştirdiğinde olur. Bu bir hata değil,
normaldir — Git hangisinin doğru olduğunu bilemez ve sana sorar.

```bash
git merge feature/x
# CONFLICT (content): Merge conflict in app.txt
git status                         # hangi dosyalar çakıştı
```

Çakışan dosyada Git işaretçiler bırakır:

```
<<<<<<< HEAD
main'deki hâli
=======
feature/x'teki hâli
>>>>>>> feature/x
```

Çözüm elle: dosyayı aç, **doğru sonucu yaz** (üç işaretçi satırını da sil), sonra:

```bash
git add app.txt                    # "bu çakışmayı çözdüm" demek
git commit                         # merge'ü tamamla (mesaj hazır gelir)
```

> Conflict'ten korkma. İşaretçilerin ne dediğini oku: yukarısı **senin** tarafın
> (HEAD), aşağısı **gelen** taraf. Doğru birleşimi yaz. Karıştıysan `git merge --abort`
> her şeyi merge öncesine geri alır — güvenli çıkış her zaman var.

## 5️⃣ Rebase: geçmişi yeniden yazmak

Merge iki geçmişi bir birleştirme commit'iyle **bağlar**; rebase, commit'lerini başka
bir taban üstüne **taşıyarak yeniden yazar** — sonuç düz, doğrusal bir geçmiş.

```bash
git switch feature/x
git rebase main                    # feature commit'lerini güncel main'in ucuna taşı
# çakışma olursa: çöz → git add → git rebase --continue
```

| | Merge | Rebase |
|---|---|---|
| Geçmiş | Gerçek (dallanma görünür) | Doğrusal (temiz) |
| Commit hash'leri | Korunur | **Değişir** (yeniden yazılır) |
| Ne zaman | Paylaşılan branch'leri birleştirirken | Kendi yerel branch'ini güncel tutarken |

### 🔒 Altın kural: paylaşılan geçmişi rebase etme

Başkalarının da üzerinde olduğu (push edilmiş) bir branch'i rebase etmek, herkesin
geçmişini bozar — hash'ler değişir, herkes kopuk kalır. **Kural:** rebase'i yalnız
**henüz kimseyle paylaşmadığın** yerel commit'lerde kullan. Paylaşılanı merge et.

## 6️⃣ Remote — kısaca (C2/D5 için zemin)

Şimdilik yerel yetiyor; ama C2 ve GitOps için remote'un ne olduğunu tanı:

```bash
git clone <URL>                    # uzak repoyu yerele kopyala (origin ayarlanır)
git push origin <branch>           # yerel commit'leri uzağa gönder
git pull                           # uzaktakileri getir + birleştir (fetch + merge)
```

`origin` uzak reponun takma adıdır. C2'de bir `push`, CI pipeline'ını tetikleyecek;
D5'te `main`'e bir merge, üretime deploy anlamına gelecek. O yüzden temiz geçmiş
sadece estetik değil — **otomasyonun girdisi.**

---

## 🚫 Anti-pattern tablosu
| Anti-pattern | Niye kötü | Doğru |
|---|---|---|
| "değişiklik", "fix", "wip" commit mesajları | "Niçin"i yok eder; geçmiş okunmaz olur | Emir kipi özet + gövdede niçin |
| Her şeyi tek dev commit'te | Geri almayı/incelemeyi imkânsızlaştırır | İlgili değişiklikleri ayrı, atomik commit'lere böl |
| Paylaşılan/push'lanmış branch'i rebase etmek | Herkesin geçmişini bozar | Paylaşılanı merge et; rebase yalnız yerelde |
| Conflict'te `--theirs`/`--ours` körlemesine | Yanlış tarafı seçip veri kaybedersin | İşaretçileri oku, doğru **birleşimi** elle yaz |
| Sırları (parola, `.env`, anahtar) commit'lemek | Geçmişte kalıcıdır; silmek zordur | `.gitignore` + sır yönetimi (D3); sızarsa anahtarı döndür |
| `git push --force` (paylaşılan branch'e) | Başkasının işini siler | `--force-with-lease` ve yalnız kendi branch'inde |
| `git add .` ile her şeyi kör stage'lemek | İstemediğin dosya/sır girer | Ne stage'lediğini `git status`/`git diff --staged` ile gör |
| Büyük ikili dosyaları repoya koymak | Repo şişer, klonlama yavaşlar | Artefaktları registry'ye (C2); repo'da yalnız kaynak |

## 📖 İleri okuma (şimdi değil, sonra)
| Kaynak | Ne için | Ne zaman |
|---|---|---|
| [`01-Git-Workflow/Trunk-Based-Development.md`](../../01-Git-Workflow/Trunk-Based-Development.md) | Takım workflow'u: kısa ömürlü branch, sık merge | **C2'den önce** — CI'a girmeden oku |
| `git help <komut>` (örn. `git help rebase`) | Her komutun resmi, tam referansı | Bir davranışı merak ettiğinde |

## 🔨 Lab
👉 `labs/build/L04-git/` — Faz 5'te oluşturulacak. (Görev taslağı: sıfırdan repo,
iki branch, bilerek bir conflict üret ve çöz; aynı işi bir kez merge, bir kez rebase
ile yapıp grafik farkını gör.)

## ✅ Kabul kriterleri
Hepsi doğrulanmadan sonraki modüle geçme:
- [ ] İki branch açıp aynı satırda bilerek bir conflict ürettin, elle çözdün ve `git log --oneline --graph` ile sonucu gösterdin.
- [ ] Bir branch'i `git rebase` ile güncel `main` üstüne taşıdın; geçmişin merge'e kıyasla nasıl değiştiğini (hash'ler) gösterdin.
- [ ] "Merge mi rebase mi" kararını, **altın kuralı** (paylaşılanı rebase etme) da içerecek şekilde bir örnek üzerinde **yazdın**.
- [ ] Bir commit mesajını "özet + niçin" biçiminde yazıp, kötü bir örnekle ("fix") farkını **yazılı** açıkladın.

## 🧪 Kendini test et
1. `git add` neden `git commit`'ten ayrı bir adım? Bunu bir işine yarar örnekle açıkla.
2. **Senaryo:** `git merge feature` "CONFLICT" verdi. Panik yok — sırayla ne yaparsın, ve yanlış gittiğini düşünürsen güvenli çıkışın ne?
3. **Tasarım:** Ekip arkadaşınla ortak bir `feature/api` branch'i üzerinde çalışıyorsunuz (ikiniz de push ettiniz). Sen onu güncel `main` ile senkronlamak istiyorsun. Merge mi rebase mi, niçin?

<details><summary>Cevaplar</summary>

1. Çünkü **hangi değişikliklerin commit'e gireceğini sen seçersin.** Örnek: bir bug'ı düzeltirken bir de yazım hatası fark ettin. İkisini ayrı commit'lemek istersin: `git add bugfix-dosyası && git commit -m "..."`, sonra `git add typo-dosyası && git commit -m "..."`. Staging bu ayrımı mümkün kılar; commit'ler atomik ve okunur kalır.

2. (a) `git status` — hangi dosyalar çakıştı. (b) Her çakışan dosyayı aç, `<<<<<<<`/`=======`/`>>>>>>>` işaretçilerini oku, doğru birleşimi yaz, işaretçileri sil. (c) `git add <dosya>` (çözüldü), sonra `git commit`. Güvenli çıkış: `git merge --abort` — her şeyi merge öncesine döndürür, hiçbir şey kaybolmaz.

3. **Merge.** Branch paylaşılmış (ikiniz de push ettiniz); rebase geçmişi yeniden yazar, arkadaşının commit'lerinin hash'lerini değiştirir ve onu kopuk bırakır — altın kuralın ihlali. `git switch feature/api && git merge main` ile main'i içeri al; conflict olursa çöz. Rebase'i yalnız **kendine ait, henüz push etmediğin** commit'lerde saklardın.

</details>

## 🆘 Takıldıysan
| Belirti | Muhtemel sebep | Ne yap |
|---|---|---|
| `CONFLICT (content)` | İki taraf aynı satırı değiştirdi | İşaretçileri elle çöz → `git add` → `git commit` |
| Yanlış branch'te commit'ledim | `switch` unutuldu | `git log` ile commit'i gör; `git switch` + `git cherry-pick` ya da `reset --soft` |
| "Commit'im kayboldu" | Branch/HEAD kaydı ya da reset | `git reflog` — HEAD'in tüm geçmişi; commit orada durur |
| `rebase` ortasında kaldım | Çakışma çözülmeyi bekliyor | Çöz → `git add` → `git rebase --continue`; çıkış: `--abort` |
| `push` reddedildi (non-fast-forward) | Uzakta senden yeni commit var | Önce `git pull` (getir+birleştir), sonra `push` |
| Yanlışlıkla sır commit'ledim | `.gitignore` yoktu / `git add .` | Sızan sırrı **döndür** (invalidate); geçmişten silmek yetmez |

## 💼 Portfolyo çıktısı
Temiz bir Git geçmişi ve anlamlı commit mesajları alışkanlığı — sonraki tüm repo
çıktılarında (A6, C2, C3, D5) görünür ve incelenir.

## ⏭️ Sırada
[`A5 — Bash`](A5-bash.md)

---

> *"İyi bir commit geçmişi, altı ay sonraki sana yazılmış bir mektuptur."*
