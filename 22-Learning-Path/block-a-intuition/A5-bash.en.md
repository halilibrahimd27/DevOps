---
description: "Bash — just enough shell to get work done: variables, loops, conditionals, pipes, and safe script writing."
level: A
module: A5
estimated_hours: 12
prerequisites: [A1, A4]
tags: [Learning Path, Bash]
---
# A5 — Bash: Just Enough Shell to Get Work Done

> *"You're not learning Bash as a language; you're learning it just enough to automate your daily work."*

**Block:** A — Intuition · **Duration:** ~12h · **Prerequisite:** [`A1`](A1-linux-temeli.md), [`A4`](A4-git-temeli.md)

## 🎯 When you finish this module
- You write a script that takes arguments, contains variables/conditionals/loops, and **stops** on error (`set -euo pipefail`).
- You chain commands with pipes, and summarize a log file in a single line.
- You find where and why a script blows up, and fix it, using `bash -n`/`bash -x`/`shellcheck`.

## 🧠 Why this, why now
In A1 you ran commands one at a time. Typing the same five commands by hand
every morning, though, is an invitation to error by the third day. Bash turns
those five commands into **one repeatable, named** job. Every lab on the path
runs on shell scripts like `setup.sh`/`verify.sh`; in A6, while you spin up
services by hand, you hand the repetitive work off to Bash. This is the most
primitive and most ubiquitous form of automation — your only automation tool
until Terraform (C3) and CI (C2) show up.

## 📖 How to study this
Read the body and **write every example into a file, `chmod +x` it, run it.**
Learn Bash by running it and watching the output, not by reasoning it out in
your head. After writing each script, check its syntax with `bash -n script.sh`;
when you get stuck, trace its flow line by line with `bash -x script.sh`. These
two commands are your eyes.

## 📚 Concept map
| Term | In one sentence |
|---|---|
| **Shebang** (`#!/usr/bin/env bash`) | The file's first line; tells which interpreter will run it |
| **Variable** | `AD=değer` (NO space around the equals sign); used as `"$AD"` |
| **Quoting** | `"$AD"` — use the variable inside quotes; the most common mistake is leaving it unquoted |
| **Exit code** | Every command's return code, 0–255; `0` = success, anything else = failure (`$?`) |
| **Pipe** (`\|`) | Connects one command's output to the next one's input |
| **Redirect** (`>`, `>>`, `2>`) | Redirects output/errors to a file |
| **Command substitution** `$(...)` | Embeds a command's output into a variable/line |
| **`set -euo pipefail`** | The seatbelt that stops a script at its first error |

---

## 1️⃣ First script: shebang, permission, execution

A script is a text file containing commands to be run in sequence. Its first
line is the **shebang**, and it says who's going to run it:

```bash
#!/usr/bin/env bash
echo "hello, $(whoami)"
```

```bash
chmod +x selam.sh      # make it executable (the x permission from A1)
./selam.sh             # run it
# hello, <USER>
```

`#!/usr/bin/env bash` finds `bash` via `PATH` instead of a fixed path
(`/bin/bash`) — portable across different systems. You need the `./` because
the shell doesn't search your current directory in `PATH` (the `PATH` topic
from A1; that's by design, for security).

## 2️⃣ Variables and quoting — the most common mistake

```bash
AD="John Doe"           # NO space on either side of the equals sign
echo "Hello $AD"         # Hello John Doe
echo 'Hello $AD'         # Hello $AD  (single quotes: no expansion at all)
```

Rule: **always use the variable inside double quotes** — `"$AD"`. Leave it
unquoted and Bash splits the value on whitespace and expands characters like
`*` inside it into file names:

```bash
DOSYA="report 2024.txt"
rm $DOSYA               # ❌ tries to delete TWO files named "report" and "2024.txt"
rm "$DOSYA"             # ✅ one file, with a space in its name
```

> 🔒 An unquoted variable isn't just a "style" mistake — it's a **security
> hole**. Using a value from external input (a file name, user data) without
> quotes opens the door to command injection. The rule is simple: **every `$`
> inside double quotes.**

## 3️⃣ Exit code: every command has an answer

Every command returns a code between 0 and 255 when it finishes. `0` means
success, anything else means failure. The previous command's code sits in
`$?`:

```bash
grep "error" app.log
echo $?                # 0 → found, 1 → not found, 2 → grep itself blew up
```

Exit code is how a script **makes decisions**; conditionals and `set -e` are
built on top of it.

```bash
mkdir /tmp/deneme && cd /tmp/deneme   # && : run the right side only if the left succeeds
komut_a || echo "a failed"             # || : run the right side only if the left FAILS
```

## 4️⃣ Conditionals: test, `[[ ]]`, if

```bash
if [[ -f "$DOSYA" ]]; then
  echo "$DOSYA exists"
elif [[ -d "$DOSYA" ]]; then
  echo "$DOSYA is a directory"
else
  echo "$DOSYA doesn't exist"
fi
```

The most commonly used tests:

| Test | True when |
|---|---|
| `[[ -f path ]]` | File exists and is a regular file |
| `[[ -d path ]]` | Directory exists |
| `[[ -z "$x" ]]` | `$x` is empty |
| `[[ -n "$x" ]]` | `$x` is non-empty |
| `[[ "$a" == "$b" ]]` | Strings are equal |
| `[[ "$a" -eq "$b" ]]` | Numbers are equal |

> `[[ ]]` (double brackets, Bash-specific) is safer than `[ ]`: an unquoted
> variable inside it doesn't get word-split. Use `[[ ]]` in every conditional
> you write from now on.

## 5️⃣ Loops: for, while, reading line by line

```bash
for svc in nginx postgresql app; do
  systemctl is-active "$svc"          # each service's status (you'll learn systemctl in A6;
done                                  # what matters here is the `for` loop pattern)
```

Reading a file **line by line**, safely (the foundation of log processing):

```bash
while IFS= read -r line; do
  echo "line: $line"
done < app.log
```

`IFS=` and `read -r` together: preserve leading/trailing whitespace, don't
mangle `\` escapes. Memorize this pattern — it's the correct way to read a
file.

## 6️⃣ Functions and arguments

You pass values into your script from outside; they arrive as `$1`, `$2`…
`$@` is all of them, `$#` is the count.

```bash
#!/usr/bin/env bash
deploy() {
  local app="$1"                       # local: scope the variable to the function
  local ver="$2"
  echo "deploy: ${app} version ${ver}"
}

if [[ $# -lt 2 ]]; then                 # check the argument count
  echo "usage: $0 <APP> <VERSION>" >&2   # error message to stderr
  exit 1
fi
deploy "$1" "$2"
```

`$0` is the script's own name; reference it in usage messages. Write error
messages to stderr with `>&2` — that way they don't get mixed into a pipe
(the stdio split from A1).

## 7️⃣ Safe scripts: `set -euo pipefail`

Bash's default behavior is **forgiving**, and that's dangerous: a command
blows up and the script carries on as if nothing happened. Put this line at
the top of every script that matters:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

| Flag | What it does | Why |
|---|---|---|
| `-e` | **Stop immediately** when a command fails | Avoid ending up in a half-done, inconsistent state |
| `-u` | **Treat** use of an undefined variable **as an error** | `rm -rf "$DIR/"` — disaster if `$DIR` is empty; `-u` catches it |
| `-o pipefail` | Count the pipe as failed if **any** link in it blows up | `cmd \| tee` — normally returns 0 even if `cmd` blows up; this fixes that |

One exception to `-e`: if you know a command **might** fail, mark it
explicitly:

```bash
if grep -q "error" app.log; then echo "error found"; fi   # grep returning 1 is normal
komut_riskli || true                                    # "if this blows up, don't care"
```

> 🔒 Don't embed secrets in a script, and don't pass them as arguments
> either. Command-line arguments are **visible to everyone** in `ps aux`
> output. Read the secret from an environment variable (`"$DB_PASSWORD"`) or
> a file; don't write it into the script (we'll go deeper on this in D3).
> Open a temp file with `mktemp` and clean it up on exit:

```bash
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT      # clean up tmp no matter how the script ends
```

## 8️⃣ Text processing: summarize a log in one line

A pipe chains small tools together into a powerful sequence. Find the top 5
paths that get the most 404s in an access log:

```bash
grep ' 404 ' access.log \
  | awk '{print $7}' \
  | sort | uniq -c \
  | sort -rn | head -5
#   87 /old-page
#   40 /favicon.ico
#   ...
```

Link by link: `grep` filters → `awk` grabs field 7 (the path) → `sort | uniq -c`
counts → `sort -rn` sorts high to low → `head -5` takes the top five. Build
this chain and understand it by watching each link's output one at a time.
This is the foundation of reading logs (B1).

## 9️⃣ Debugging: what to do when it blows up

| Tool | What for |
|---|---|
| `bash -n script.sh` | Check the **syntax** without running it (the lab QA uses this) |
| `bash -x script.sh` | Show each line, with variables expanded, **as it runs** |
| `shellcheck script.sh` | Statically catches classic mistakes like unquoted variables and wrong tests |

Install `shellcheck` and run every script through it — it catches most of the
mistakes you make before you ever see them.

---

## 🚫 Anti-pattern table
| Anti-pattern | Why it's bad | Right |
|---|---|---|
| Unquoted variable (`rm $x`) | Splits on whitespace, `*` expands, open to injection | Every `$` inside double quotes: `"$x"` |
| No `set -euo pipefail` | A command blows up, script carries on in a half-done state | Add it right after the first line of every script that matters |
| Embedding a secret in a script / passing it as an argument | Leaks via `ps`/history/git | Read it from an environment variable or a file (D3) |
| `AD = değer` (space around the equals sign) | Bash thinks it's a command, doesn't run | `AD=değer` — no space |
| Walking files with `for f in $(ls)` | Breaks on spaces/special names | `for f in *.log` (glob) or `find ... -print0 \| xargs -0` |
| `cat file \| grep x` | Unnecessary `cat`; one extra process | `grep x file` |
| Writing error messages to stdout | Gets mixed into the pipe/data stream | `echo "error" >&2` (stderr) |
| Sprinkling in `echo` instead of `bash -x` | Slow, messy, forgotten | Trace line by line with `bash -x`, scan with `shellcheck` |
| Naming a temp file by hand (`/tmp/x`) | Collisions + litter left behind on exit | Clean up with `mktemp` + `trap ... EXIT` |

## 📖 Further reading (not now, later)
> These aren't a guided step — they're references you open **when you need
> them** (the four-field external-source contract is for guided-reading
> links, not for one-off lookups like this). Duration: 2–5 min each, you're
> looking up a single question.

| Source | What for | When to open it |
|---|---|---|
| `man bash` / `help set` | The official reference for every behavior | When you're wondering what a flag does |
| [ShellCheck wiki](https://www.shellcheck.net/wiki/) | Explanation of the warning code `shellcheck` gives you (e.g., SC2086) | When `shellcheck` gives a warning, look up that code |

## 🔨 Lab
👉 [`labs/build/L05-bash/`](../labs/build/L05-bash/README.md) — (Task draft: a script
that takes two arguments, uses `set -euo pipefail`, summarizes a log file and
writes the result to a report file, and passes `shellcheck` clean.)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] You wrote a script that takes at least one argument, prints a usage message and exits with `exit 1` when an argument is missing, and passes `bash -n` clean.
- [ ] You wrote a command that summarizes a log file with a **single-line** pipe chain, and showed its output.
- [ ] You explained **in writing**, with one example each, why every one of the three flags in `set -euo pipefail` is necessary.
- [ ] `shellcheck script.sh` found at least one warning in one of your scripts, you fixed the warning, and got clean output.

## 🧪 Test yourself
1. What's the difference between `rm $DOSYA` and `rm "$DOSYA"`? What does each one do when `DOSYA="a b"`?
2. **Scenario:** A script was written without `set -e`; the `cd /veri` command partway through it failed, but the script kept going and ran `rm -rf ./*`. What happened, and how would `set -euo pipefail` have prevented it?
3. **Design:** You're about to write a backup script that needs a DB password. Where do you put the password, where do you **never** put it, and why?

<details><summary>Answers</summary>

1. `rm $DOSYA` unquoted: Bash splits the value `"a b"` on whitespace and tries to delete **two** files named `a` and `b` (and expands characters like `*` into file names, if present). `rm "$DOSYA"` quoted: takes the value as a single whole, deleting the **one** file whose name has a space in it. Rule: every `$` inside double quotes.

2. `cd /veri` failed (the directory doesn't exist), but the script stayed in the wrong (still the old) directory, and `rm -rf ./*` ran there and deleted the wrong files. Had `set -e` been on, the script would have stopped the instant `cd` blew up, and `rm` would never have run. `set -u` would also have caught an empty `$DIR` variable on top of that. Together, the two shut down this entire class of disaster.

3. I'd read the password from an **environment variable** (`"$DB_PASSWORD"`) or from a file with restricted permissions. I'd **never** hardcode it into the script (it leaks into git), pass it as a command-line argument (visible to everyone in `ps aux`), or print it to a log. We'll go deeper on secret management in D3; the principle starts here: a secret doesn't go into code.

</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| `command not found: ./script.sh` | No execute permission, or wrong directory | `chmod +x script.sh`; run it with `./` |
| `AD: command not found` | `AD = değer` (assignment with a space) | `AD=değer` — no space around the equals sign |
| Variable split unexpectedly | Unquoted `$x` | Use `"$x"` everywhere |
| `unbound variable` | `set -u` + an undefined variable | Define the variable, or give it `"${x:-default}"` |
| Pipe blew up but the script kept going | No `pipefail` | Add `set -o pipefail` |
| Script stopped silently partway through | `set -e` + an expected failure | Mark the expected failure with `\|\| true` or an `if` |
| Can't see why it blew up | Running blind | Trace it line by line with `bash -x script.sh` |

## 💼 Portfolio output
A handful of reusable helper scripts (a summarizer, a validator) — the
infrastructure for automating your own work from A6 onward. Keep them in a
repo using the Git you learned in A4.

## ⏭️ Up next
[`A6 — Manual Deploy`](A6-elle-deploy.md)

---

> *"If you're doing something by hand for the second time, put it into a script before the third."*
