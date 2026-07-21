# L04 — Referans çözüm

> **Önce kendin dene.** Conflict'i bir kez kontrollü çözersen, gerçek bir PR'da
> gördüğünde elin titremez.

## 1. Kurulum
```bash
bash starter/init-lab.sh && cd repo
```

## 2. Conflict üret ve çöz (merge yolu)
```bash
git switch -c feature-merge
sed -i.bak 's/durum: taslak/durum: hazır/' notlar.md && rm -f notlar.md.bak
git commit -aqm "feature: durum=hazır"

git switch main
sed -i.bak 's/durum: taslak/durum: incelemede/' notlar.md && rm -f notlar.md.bak
git commit -aqm "main: durum=incelemede"

git merge feature-merge          # CONFLICT: notlar.md
# notlar.md açılır; <<<<<<< ======= >>>>>>> işaretlerini sil, doğru satırı bırak:
#   durum: hazır
git add notlar.md
git commit -qm "merge: conflict çözüldü (durum=hazır)"
```
`git log --oneline --graph` → dallanıp birleşen bir grafik + **merge commit**.

## 3. Aynı işi rebase ile
```bash
git switch -c feature-rebase
printf 'ek: rebase denemesi\n' >> notlar.md
git commit -aqm "feature-rebase: ek satır"

git switch main
printf 'ek: main tarafı\n' >> notlar.md
git commit -aqm "main: ek satır"

git switch feature-rebase
git rebase main                  # commit'i main'in tepesine taşır
# Conflict çıkarsa çöz → git add → git rebase --continue
```
`git log --oneline --graph` → **doğrusal** geçmiş, merge commit yok.

## 4. Fark

| | merge | rebase |
|---|---|---|
| Geçmiş | Dallanma korunur, **merge commit** eklenir | **Doğrusal**, temiz |
| Commit'ler | Değişmez | **Yeniden yazılır** (yeni hash) |
| Ne zaman | Paylaşılmış dalları birleştirirken, gerçek tarihi korumak isteyince | Kendi lokal dalını `main`'in tepesine taşıyıp temiz PR açarken |
| Tehlike | Grafik "spagetti"leşebilir | **Paylaşılmış** dalı rebase etmek başkasının kopyasını bozar |

> Kural: yerelde temizlemek için rebase, paylaşımı birleştirmek için merge.
> Push edilmiş bir dalı asla rebase etme.
