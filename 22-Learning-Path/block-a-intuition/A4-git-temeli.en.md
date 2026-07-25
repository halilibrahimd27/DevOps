---
description: "Git basics: commit, branch, merge, rebase, and conflict — the change record of code and infrastructure."
level: A
module: A4
estimated_hours: 12
prerequisites: [A1]
tags: [Learning Path, Git]
---
# A4 — Git Basics: Commit, Branch, Merge, Rebase, Conflict

> *"Git isn't a backup tool — it's the record that carries the why of change."*

**Block:** A — Intuition · **Duration:** ~12h · **Prerequisite:** [`A1`](A1-linux-temeli.md)

## 🎯 When you finish this module
- You set up a repo from scratch and build a history with meaningful commits.
- You open a branch, merge it, and resolve a conflict by hand, safely.
- You explain the difference between merge and rebase, and when to use which.

## 🧠 Why this, why now
In C2 (CI) and C3 (Terraform), everything will flow through Git; in GitOps (D5),
Git will be the single source of truth. Building automation on top of this
mechanism before living it by hand, on your own, is flying blind. Once you
understand Git not as a "sequence of magic commands" but as **a commit graph
(DAG)**, every situation you fear (conflict, a "lost" commit, the wrong branch)
turns into an ordinary graph operation.

## 📖 How to study this
Read the body and **run every command in an empty test repo** (open a
playground with `git init`). Learn Git not by memorizing but by continuously
seeing the graph with `git status` and `git log --oneline --graph`. These two
commands are your eyes — look after every step.

## 📚 Concept map
| Term | In one sentence |
|---|---|
| **Commit** | A signed record of the file state at a point in time (snapshot) + message + parent(s) |
| **Working directory** | The actual files you're working on |
| **Staging (index)** | The holding area for changes that will go into the next commit |
| **Branch** | A movable name that points to a commit (`main`, `feature/x`) |
| **HEAD** | Where you currently are — usually the tip of a branch |
| **Merge** | A commit that joins two histories |
| **Rebase** | **Rewriting** commits on top of a different base |
| **Conflict** | Both sides changed the same line differently; Git can't decide, you do |
| **Remote** | Another copy of the repo (`origin`) — GitHub etc. |

---

## 1️⃣ Mental model: snapshots and three areas

Git stores a **complete snapshot** of the files at every commit — not "diffs"
(it computes those itself). Every commit has an identity (hash) and a
**parent**; chained together they form a directed graph (DAG). A branch is
nothing more than a movable label in this graph.

A change passes through three areas before it becomes a commit:

```
working directory  →  staging (index)  →  commit (repo)
   (git add)              (git commit)
```

```bash
git config --global user.name  "<FULL_NAME>"
git config --global user.email "<EMAIL>"      # puts an author on commits
git init                       # create an empty repo (creates a .git directory)
git status                     # what's where: changed, staged, untracked
```

Run `git status` often. The answer to "where am I right now?" is always there.

## 2️⃣ Basic loop: change → stage → commit

```bash
echo "hello" > app.txt
git add app.txt                # stage the change
git commit -m "add app.txt: initial version"
git log --oneline              # view the history as a one-line summary
# a1b2c3d add app.txt: initial version
```

Why is `git add` a separate step? Because **you choose which changes go into
this commit.** Changing two files and committing only one is how you split
related changes into separate, meaningful commits.

### A good commit message — a letter to your future self, six months from now

```
short summary (50 characters, imperative mood: "add", "fix")

After a blank line: WHY you did it. Code already tells you "what";
the commit message carries the "why" — nothing else does.
```

> `git log` is the only place that will carry the answer to "why is this line
> like this?" a year from now. Messages like "change", "fix", "update" destroy
> that answer. For the repo's commit discipline, see
> [`CLAUDE.md`](https://github.com/halilibrahimd27/devsecops-handbook/blob/main/CLAUDE.md) — build the foundation for your post-A6
> habits right here.

## 3️⃣ Branch and merge: working in parallel

A branch lets you work without breaking the main line. When you're done, you
**merge** into the main line.

```bash
git switch -c feature/greeting    # open a new branch and switch to it (old: git checkout -b)
echo "hi" >> app.txt
git commit -am "add greeting line"
git switch main                    # go back to the main line
git merge feature/greeting         # merge feature into main
git log --oneline --graph --all    # see the graph — branching and merging
```

There are two kinds of merge:

| Case | What happens | Result |
|---|---|---|
| **Fast-forward** | If `main` hasn't moved since the feature branched off | The label just slides forward; no extra commit, linear history |
| **Merge commit** | If both sides have moved forward | A merge commit with two parents is born |

Delete the branch once you're done (the label goes away, the commits stay):

```bash
git branch -d feature/greeting    # safely delete a merged branch
```

## 4️⃣ Conflict: Git can't decide, you do

A conflict happens when two branches change **the same line differently**.
This isn't an error, it's normal — Git can't know which one is correct, so it
asks you.

```bash
git merge feature/x
# CONFLICT (content): Merge conflict in app.txt
git status                         # which files conflicted
```

Git leaves markers in the conflicting file:

```
<<<<<<< HEAD
main's version
=======
feature/x's version
>>>>>>> feature/x
```

The fix is manual: open the file, **write the correct result** (delete all
three marker lines), then:

```bash
git add app.txt                    # means "I resolved this conflict"
git commit                         # complete the merge (the message comes pre-filled)
```

> Don't be afraid of conflicts. Read what the markers say: the top is **your**
> side (HEAD), the bottom is the **incoming** side. Write the correct
> combination. If you get confused, `git merge --abort` reverts everything to
> before the merge — there's always a safe way out.

## 5️⃣ Rebase: rewriting history

Merge **joins** two histories with a merge commit; rebase **rewrites** your
commits by moving them onto a different base — the result is a flat, linear
history.

```bash
git switch feature/x
git rebase main                    # move feature commits onto the tip of current main
# if a conflict occurs: resolve → git add → git rebase --continue
```

| | Merge | Rebase |
|---|---|---|
| History | Real (branching visible) | Linear (clean) |
| Commit hashes | Preserved | **Change** (rewritten) |
| When | Merging shared branches | Keeping your own local branch up to date |

### 🔒 Golden rule: don't rebase shared history

Rebasing a branch that others are also working on (pushed) breaks everyone's
history — hashes change, and everyone ends up disconnected. **Rule:** use
rebase only on local commits **you haven't shared with anyone yet.** Merge
what's shared.

## 6️⃣ Remote — briefly (groundwork for C2/D5)

Local is enough for now, but get to know what a remote is for C2 and GitOps:

```bash
git clone <URL>                    # copy the remote repo locally (sets up origin)
git push origin <branch>           # send local commits to the remote
git pull                           # fetch remote commits + merge (fetch + merge)
```

`origin` is the remote repo's alias. In C2, a `push` will trigger the CI
pipeline; in D5, a merge into `main` will mean a deploy to production. That's
why a clean history isn't just aesthetics — it's **automation's input.**

## 7️⃣ Undoing: restore, reset, revert, stash

What scares beginners most is "I did it wrong, how do I undo it". There are
three different kinds of "undo," and mixing them up loses data:

| Command | What it does | When |
|---|---|---|
| `git restore <file>` | **Discard** the change in the working directory (revert to the last commit) | Erasing a mistake you haven't committed yet |
| `git restore --staged <file>` | Remove it from staging (the change stays) | Undoing a wrong `add` |
| `git revert <commit>` | Adds a **new commit that cancels out** that commit | Safe undo in **shared** history |
| `git reset --soft <commit>` | Move HEAD back, leave the changes in staging | Reorganizing recent commits (local) |
| `git reset --hard <commit>` | Move HEAD back, **delete everything** | ⚠️ Local; used wrong, it loses work |

> **The key distinction:** `revert` undoes **by adding** (history is
> preserved, safe when shared). `reset` undoes **by deleting/moving**
> (rewrites history, local only). If a commit has already been pushed, use
> `revert`, not `reset --hard`.

### Set aside temporarily: stash

You're in the middle of something but urgently need to do something else. Set
the unfinished work aside without committing it:

```bash
git stash            # clean the working directory, set changes aside
git switch main      # do the urgent work
git stash pop        # come back, bring back the work you set aside
```

### `.gitignore` — what NOT to track

Some files should never enter the repo: secrets (`.env`), generated output
(`node_modules/`, `__pycache__/`, `site/`), local settings. Exclude these with
`.gitignore`:

```gitignore
.env
*.log
node_modules/
site/
```

> Once a file has been committed, `.gitignore` **won't undo** that (it's
> already tracked). First untrack it with `git rm --cached <file>`, then
> ignore it. For a leaked secret, even this isn't enough: it stays in
> history — **rotate the key.**

### Not lost: reflog

"My commit is gone" is almost never true. `git reflog` keeps every place HEAD
has been; you can recover even from a wrong `reset`:

```bash
git reflog                      # HEAD's full history (most recent moves on top)
git reset --hard <good_hash>    # go back to the solid point you saw in reflog
```

---

## 🚫 Anti-pattern table
| Anti-pattern | Why it's bad | Right |
|---|---|---|
| "change", "fix", "wip" commit messages | Destroys the "why"; history becomes unreadable | Imperative summary + why in the body |
| Everything in one giant commit | Makes undoing/reviewing impossible | Split related changes into separate, atomic commits |
| Rebasing a shared/pushed branch | Breaks everyone's history | Merge what's shared; rebase only locally |
| Blindly using `--theirs`/`--ours` on conflicts | You pick the wrong side and lose data | Read the markers, write the correct **combination** by hand |
| Committing secrets (passwords, `.env`, keys) | Permanent in history; hard to remove | `.gitignore` + secrets management (D3); rotate the key if it leaks |
| `git push --force` (on a shared branch) | Deletes someone else's work | `--force-with-lease`, and only on your own branch |
| Blindly staging everything with `git add .` | Lets in files/secrets you didn't want | Check what you staged with `git status`/`git diff --staged` |
| Putting large binary files in the repo | Bloats the repo, slows down cloning | Artifacts go to the registry (C2); repo holds only source |

## 📖 Further reading (not now, later)
| Source | For what | When |
|---|---|---|
| [`01-Git-Workflow/Trunk-Based-Development.md`](../../01-Git-Workflow/Trunk-Based-Development.md) | Team workflow: short-lived branches, frequent merges | **Before C2** — read before starting CI |
| `git help <command>` (e.g. `git help rebase`) | The official, complete reference for every command | When you're curious about a behavior |

## 🔨 Lab
👉 [`labs/build/L04-git/`](../labs/build/L04-git/README.md) — (Task outline: a repo from
scratch, two branches, deliberately create and resolve a conflict; do the same
work once with merge and once with rebase, and see the difference in the
graph.)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] You opened two branches, deliberately created a conflict on the same line, resolved it by hand, and showed the result with `git log --oneline --graph`.
- [ ] You moved a branch onto current `main` with `git rebase`; you showed how the history (hashes) changes compared to a merge.
- [ ] You **wrote up** the "merge or rebase" decision on an example, including the **golden rule** (don't rebase what's shared).
- [ ] You wrote a commit message in "summary + why" form and explained the difference from a bad example ("fix") **in writing**.

## 🧪 Test yourself
1. Why is `git add` a separate step from `git commit`? Explain with a useful example.
2. **Scenario:** `git merge feature` gave a "CONFLICT". No panic — what do you do, step by step, and if you think it's going wrong, what's your safe way out?
3. **Design:** You and a teammate are working on a shared `feature/api` branch (you've both pushed). You want to sync it with current `main`. Merge or rebase, and why?

<details><summary>Answers</summary>

1. Because **you choose which changes go into the commit.** Example: while fixing a bug, you also notice a typo. You want to commit them separately: `git add bugfix-file && git commit -m "..."`, then `git add typo-file && git commit -m "..."`. Staging makes this separation possible; commits stay atomic and readable.

2. (a) `git status` — which files conflicted. (b) Open each conflicting file, read the `<<<<<<<`/`=======`/`>>>>>>>` markers, write the correct combination, delete the markers. (c) `git add <file>` (resolved), then `git commit`. Safe exit: `git merge --abort` — reverts everything to before the merge, nothing is lost.

3. **Merge.** The branch is shared (you've both pushed); rebase rewrites history, changes the hashes of your teammate's commits, and leaves them disconnected — a violation of the golden rule. Pull `main` in with `git switch feature/api && git merge main`; resolve if there's a conflict. You'd save rebase only for commits that are **your own, not yet pushed.**

</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| `CONFLICT (content)` | Both sides changed the same line | Resolve the markers by hand → `git add` → `git commit` |
| Committed on the wrong branch | Forgot to `switch` | See the commit with `git log`; undo it with `git reset --soft HEAD~1` (the change stays), switch with `git switch <correct-branch>` and commit again |
| "My commit disappeared" | A branch/HEAD move or a reset | `git reflog` — HEAD's full history; the commit is right there |
| Stuck mid-`rebase` | A conflict is waiting to be resolved | Resolve → `git add` → `git rebase --continue`; exit: `--abort` |
| `push` rejected (non-fast-forward) | The remote has commits newer than yours | `git pull` first (fetch+merge), then `push` |
| Accidentally committed a secret | No `.gitignore` / `git add .` | **Rotate** (invalidate) the leaked secret; removing it from history isn't enough |

## 💼 Portfolio output
A clean Git history and the habit of meaningful commit messages — visible and
reviewed in every repo output that follows (A6, C2, C3, D5).

## ⏭️ Up next
[`A5 — Bash`](A5-bash.md)

---

> *"A good commit history is a letter written to you, six months from now."*
