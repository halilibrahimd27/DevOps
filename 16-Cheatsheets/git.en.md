---
description: "Git practical command notes: status and log inspection, history editing, bisect, cherry-pick, reflog and worktree. Tips senior devs use daily."
tags:
  - Cheatsheet
  - Git
---
# Git Cheatsheet

> *"You're not using Git — Git is using you."* — every senior dev, eventually

## 🔍 Inspection

```bash
# Status (every command's salvation)
git status
git status -sb            # short branch info
git status --ignored      # includes gitignored files

# Log
git log --oneline --graph --decorate --all
git log --since='2 weeks ago' --author='alice'
git log -p path/to/file               # all changes made to a file
git log -L :function_name:file.py     # history of a function
git log -S 'searchString'             # commits that added/removed this string
git log --grep='fix.*auth'            # commit message regex

# Show
git show <COMMIT>
git show <COMMIT>:path/to/file        # file at a specific version

# Diff
git diff                              # working vs staged
git diff --staged                     # staged vs HEAD
git diff main..feature                # between two branches
git diff --stat                       # summary (per file)
git diff --word-diff                  # word-level
git diff <COMMIT> -- path/            # a specific path

# Blame
git blame file.py
git blame -L 10,20 file.py
git log --follow -p -- file.py        # follow renames
```

## 🌿 Branches

```bash
# List
git branch                 # local
git branch -r              # remote
git branch -a              # all
git branch --merged main   # branches merged into main
git branch --no-merged     # not merged (gold for pre-cleanup)

# Create + switch
git switch -c feature/auth          # create + checkout (modern)
git checkout -b feature/auth        # old way

# Switch
git switch main
git switch -                        # to the previous branch

# Delete (cleanup)
git branch -d feature/auth          # safe (warns if not merged)
git branch -D feature/auth          # force delete
git push origin --delete feature/auth   # delete from remote

# Clean up locals deleted on the remote
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

# Patch mode (stage by selecting chunks)
git add -p

# Amend (add to last commit / change message)
git commit --amend
git commit --amend --no-edit          # keep the message
git commit --amend -m "new message"

# Empty commit (useful for triggering a deploy)
git commit --allow-empty -m "trigger: redeploy"

# Conventional commit examples
git commit -m "feat(auth): add OAuth2 support"
git commit -m "fix(api): handle null in user lookup"
git commit -m "chore(deps): bump axios from 1.4.0 to 1.5.0"
git commit -m "docs: update README quick-start"
git commit -m "refactor(payments): extract validation logic"
git commit -m "perf(query): add index on user_email"
git commit -m "test(auth): cover token expiration paths"
git commit -m "ci: cache npm install in pipeline"
```

## 🔄 Rewrite History (GREAT but use carefully)

```bash
# Interactive rebase (last 5 commits)
git rebase -i HEAD~5
# In the editor that opens: pick/squash/fixup/reword/drop

# Rebase (branch onto the tip of main)
git switch feature/auth
git rebase main

# Rebase + force-push (for a shared branch)
git push --force-with-lease           # safer, won't clobber someone else's commit
git push --force                      # dangerous — clobbers someone else's changes

# Rebase as the default instead of merge
git config --global pull.rebase true

# Squash merge (clean history after a PR)
git merge --squash feature/auth
git commit -m "feat: add auth flow"
```

## 🎯 Cherry-pick

```bash
# Bring a single commit onto this branch
git cherry-pick <COMMIT>

# Multiple
git cherry-pick <COMMIT1> <COMMIT2>
git cherry-pick <COMMIT1>..<COMMIT2>

# If there's a conflict
git cherry-pick --continue
git cherry-pick --abort

# Pick the commit but don't commit yet (leave it staged)
git cherry-pick -n <COMMIT>
```

## 🔍 Bisect (when did the bug appear?)

```bash
# Start
git bisect start
git bisect bad                  # current commit is broken
git bisect good <KNOWN_GOOD>    # known good commit

# Git gives you the midpoint, test it:
./run-tests.sh
# Based on the result:
git bisect good      # OK
git bisect bad       # broken
# Continue, git finds the culprit commit

git bisect reset     # when done

# Automatic (with a script)
git bisect run ./run-tests.sh
```

## 🧹 Stash (stash temporarily)

```bash
git stash                         # stash the working tree
git stash -u                      # including untracked files
git stash push -m "WIP: refactor" # with a message
git stash push path/to/file       # only a single path

git stash list
git stash show
git stash show -p stash@{0}       # show diff

git stash apply                   # apply, keep it in stash
git stash pop                     # apply + delete
git stash drop stash@{0}          # delete a specific stash
git stash clear                   # delete all
```

## 🆘 Reflog (everything is recorded)

```bash
# History of every HEAD movement (90 days)
git reflog

# Find a lost commit
git reflog | grep 'feature/auth'
git checkout HEAD@{5}            # to HEAD 5 movements ago

# Restore a branch you deleted
git reflog                       # find the commit hash
git checkout -b restored <COMMIT>

# Undo a hard reset
git reset --hard HEAD@{1}        # 1 movement before the hard reset
```

## ↩️ Undo

```bash
# Discard a change in the working dir
git restore file.py              # modern
git checkout -- file.py          # old

# Unstage staged changes (keep them in the working tree)
git restore --staged file.py     # modern
git reset HEAD file.py           # old

# Undo the last commit (keep changes in the working tree)
git reset HEAD~                  # default = mixed
git reset --soft HEAD~           # keep them staged
git reset --hard HEAD~           # discard everything (CAUTION)

# Undo a published commit (with a new commit)
git revert <COMMIT>              # safe, doesn't change history
```

## 🌊 Worktree (parallel checkout)

```bash
# Open a different branch of the same repo in a separate folder (no full reload)
git worktree add ../app-hotfix hotfix/critical
cd ../app-hotfix

# List
git worktree list

# Remove
git worktree remove ../app-hotfix
```

## 🔑 Submodule (extra careful)

```bash
git submodule add <URL> path/to/sub
git submodule update --init --recursive
git submodule update --remote --merge        # pull the latest commits

# Clone with submodules
git clone --recurse-submodules <URL>
```

## 🛠️ Config

```bash
# Global identity
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# Editor
git config --global core.editor vim          # or nano, code --wait

# Default branch (in new repos)
git config --global init.defaultBranch main

# Auto-prune on all remotes
git config --global fetch.prune true

# Rebase for pull (avoid merge commit spam)
git config --global pull.rebase true

# Safe force push
git config --global alias.fpush 'push --force-with-lease'

# Useful aliases
git config --global alias.st 'status -sb'
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD --stat'
git config --global alias.amend 'commit --amend --no-edit'

# List
git config --global --list
```

## 🚨 Emergency scenarios

| Issue | Solution |
|---|---|
| Committed to the wrong branch | `git reset --soft HEAD~`, `switch` to the right branch, commit again |
| Deleted someone else's commit with `force push --force` | Find the remote ref with `git reflog`, `git push origin <COMMIT>:main` |
| Committed the wrong file | `git rm --cached <FILE>`, `git commit --amend`, `--force-with-lease push` |
| A merge conflict got me | `git mergetool` (vimdiff/meld) or `git checkout --theirs/--ours <FILE>` |
| Committed in detached HEAD | Create a branch with `git switch -c rescue` and normalize |
| Accidental `git reset --hard` | `git reflog` → `git reset --hard HEAD@{1}` |
| Large file accidentally committed | Rewrite with `git filter-repo` (more modern than BFG) |
| Changed origin, wrong URL | `git remote set-url origin <NEW_URL>` |
| Added to `.gitignore` but still tracked | `git rm --cached <FILE>`, commit, push |
