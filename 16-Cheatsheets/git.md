# Git Cheatsheet

> *"Git'i kullanmıyorsun, Git seni kullanıyor."* — her senior dev, eninde sonunda

## 🔍 Inspection

```bash
# Status (every command's salvation)
git status
git status -sb            # short branch info
git status --ignored      # gitignore'lanan dosyalar dahil

# Log
git log --oneline --graph --decorate --all
git log --since='2 weeks ago' --author='alice'
git log -p path/to/file               # dosyaya gelen tüm değişiklikler
git log -L :function_name:file.py     # bir fonksiyonun tarihi
git log -S 'searchString'             # bu string'i ekleyen/silen commit'ler
git log --grep='fix.*auth'            # commit message regex

# Show
git show <COMMIT>
git show <COMMIT>:path/to/file        # belirli versiyondaki dosya

# Diff
git diff                              # working vs staged
git diff --staged                     # staged vs HEAD
git diff main..feature                # iki branch arası
git diff --stat                       # özet (dosya başına)
git diff --word-diff                  # kelime bazlı
git diff <COMMIT> -- path/            # belirli yolu

# Blame
git blame file.py
git blame -L 10,20 file.py
git log --follow -p -- file.py        # rename'leri takip et
```

## 🌿 Branches

```bash
# Listele
git branch                 # local
git branch -r              # remote
git branch -a              # tümü
git branch --merged main   # main'e merge olmuş branch'ler
git branch --no-merged     # olmamış (pre-cleanup için altın)

# Oluştur + geç
git switch -c feature/auth          # create + checkout (modern)
git checkout -b feature/auth        # eski yöntem

# Geç
git switch main
git switch -                        # önceki branch'e

# Sil (temizlik)
git branch -d feature/auth          # safe (merged değilse uyarır)
git branch -D feature/auth          # force delete
git push origin --delete feature/auth   # remote'tan sil

# Local'da remote'tan silinenleri temizle
git fetch -p
git branch -vv | grep ': gone]' | awk '{print $1}' | xargs git branch -d

# Rename
git branch -m old-name new-name
git push origin :old-name new-name
```

## 💾 Commit

```bash
# Stage + commit
git add .
git commit -m "feat: add user auth"

# Patch mode (chunk seçerek stage)
git add -p

# Amend (son commit'e ekle / mesaj değiştir)
git commit --amend
git commit --amend --no-edit          # mesajı koru
git commit --amend -m "yeni mesaj"

# Empty commit (deploy trigger için faydalı)
git commit --allow-empty -m "trigger: redeploy"

# Conventional commit örnekleri
git commit -m "feat(auth): add OAuth2 support"
git commit -m "fix(api): handle null in user lookup"
git commit -m "chore(deps): bump axios from 1.4.0 to 1.5.0"
git commit -m "docs: update README quick-start"
git commit -m "refactor(payments): extract validation logic"
git commit -m "perf(query): add index on user_email"
git commit -m "test(auth): cover token expiration paths"
git commit -m "ci: cache npm install in pipeline"
```

## 🔄 Rewrite History (HARİKA ama dikkatli kullan)

```bash
# Interactive rebase (last 5 commits)
git rebase -i HEAD~5
# Açılan editör'de: pick/squash/fixup/reword/drop

# Rebase (branch'i main'in tepesine)
git switch feature/auth
git rebase main

# Rebase + force-push (paylaşılmış branch için)
git push --force-with-lease           # daha güvenli, başkasının commit'ini ezmez
git push --force                      # tehlikeli — başkasının değişikliğini ezer

# Merge yerine rebase varsayılanı
git config --global pull.rebase true

# Squash merge (PR sonrası clean history)
git merge --squash feature/auth
git commit -m "feat: add auth flow"
```

## 🎯 Cherry-pick

```bash
# Tek commit'i bu branch'e al
git cherry-pick <COMMIT>

# Birden fazla
git cherry-pick <COMMIT1> <COMMIT2>
git cherry-pick <COMMIT1>..<COMMIT2>

# Conflict varsa
git cherry-pick --continue
git cherry-pick --abort

# Commit'i pick et ama henüz commit'leme (stage'de bırak)
git cherry-pick -n <COMMIT>
```

## 🔍 Bisect (bug ne zaman geldi?)

```bash
# Başlat
git bisect start
git bisect bad                  # şu anki commit bozuk
git bisect good <KNOWN_GOOD>    # bilinen iyi commit

# Git ortayı verir, test et:
./run-tests.sh
# Sonuca göre:
git bisect good      # OK
git bisect bad       # bozuk
# Devam et, git suçlu commit'i bulur

git bisect reset     # bitince

# Otomatik (script'le)
git bisect run ./run-tests.sh
```

## 🧹 Stash (geçici sakla)

```bash
git stash                         # working tree'yi sakla
git stash -u                      # untracked dosyalar dahil
git stash push -m "WIP: refactor" # mesajla
git stash push path/to/file       # sadece bir yolu

git stash list
git stash show
git stash show -p stash@{0}       # diff göster

git stash apply                   # uygula, stash'te kalsın
git stash pop                     # uygula + sil
git stash drop stash@{0}          # belirli stash'i sil
git stash clear                   # tümünü sil
```

## 🆘 Reflog (her şey kayıtlı)

```bash
# Her HEAD hareketinin tarihi (90 gün)
git reflog

# Kaybedilen commit'i bul
git reflog | grep 'feature/auth'
git checkout HEAD@{5}            # 5 hareket önceki HEAD'e

# Sildiğin branch'i geri getir
git reflog                       # commit hash'ini bul
git checkout -b restored <COMMIT>

# Hard reset'i geri al
git reset --hard HEAD@{1}        # hard reset'in 1 hareket öncesi
```

## ↩️ Undo

```bash
# Working dir'deki değişikliği at
git restore file.py              # modern
git checkout -- file.py          # eski

# Staged'i unstage et (working tree'de kalsın)
git restore --staged file.py     # modern
git reset HEAD file.py           # eski

# Son commit'i geri al (değişiklikleri working tree'de tut)
git reset HEAD~                  # default = mixed
git reset --soft HEAD~           # staged'de tut
git reset --hard HEAD~           # her şeyi at (DİKKAT)

# Yayınlanmış commit'i geri al (yeni commit ile)
git revert <COMMIT>              # safe, history'i değiştirmez
```

## 🌊 Worktree (parallel checkout)

```bash
# Aynı repo'da farklı branch'i ayrı klasörde aç (full reload yok)
git worktree add ../app-hotfix hotfix/critical
cd ../app-hotfix

# Listele
git worktree list

# Sil
git worktree remove ../app-hotfix
```

## 🔑 Submodule (ekstra dikkatli)

```bash
git submodule add <URL> path/to/sub
git submodule update --init --recursive
git submodule update --remote --merge        # son commit'leri çek

# Clone with submodules
git clone --recurse-submodules <URL>
```

## 🛠️ Config

```bash
# Global identity
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# Editor
git config --global core.editor vim          # veya nano, code --wait

# Default branch (yeni repo'larda)
git config --global init.defaultBranch main

# Tüm uzaklarda otomatik prune
git config --global fetch.prune true

# Pull için rebase (merge commit spam engelle)
git config --global pull.rebase true

# Force push güvenli
git config --global alias.fpush 'push --force-with-lease'

# Faydalı alias'lar
git config --global alias.st 'status -sb'
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD --stat'
git config --global alias.amend 'commit --amend --no-edit'

# Listele
git config --global --list
```

## 🚨 Acil senaryolar

| Sorun | Çözüm |
|---|---|
| Yanlış branch'e commit yaptım | `git reset --soft HEAD~`, doğru branch'e `switch`, tekrar commit |
| `force push --force` ile başkasının commit'ini sildim | `git reflog` ile remote ref bul, `git push origin <COMMIT>:main` |
| Yanlış dosyayı commit ettim | `git rm --cached <FILE>`, `git commit --amend`, `--force-with-lease push` |
| Merge conflict yedi beni | `git mergetool` (vimdiff/meld) veya `git checkout --theirs/--ours <FILE>` |
| Detached HEAD'te commit yaptım | `git switch -c rescue` ile branch oluştur ve normalleştir |
| Yanlışlıkla `git reset --hard` | `git reflog` → `git reset --hard HEAD@{1}` |
| Büyük dosya yanlışlıkla commit'lendi | `git filter-repo` ile rewrite (BFG'den daha modern) |
| Origin'i değiştirdim, yanlış URL | `git remote set-url origin <NEW_URL>` |
| `.gitignore`'a ekledim ama hâlâ takip ediliyor | `git rm --cached <FILE>`, commit, push |
