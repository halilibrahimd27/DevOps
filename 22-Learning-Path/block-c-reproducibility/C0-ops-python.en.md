---
description: "Python for ops: enough to write an automation script, an API call, and data processing — not teaching the language, getting the job done."
level: C
module: C0
estimated_hours: 30
prerequisites: [A5]
tags: [Learning Path, Python]
---
# C0 — Python for Ops

> *"Bash writes you a line, Python writes you a tool. Knowing the boundary between the two is ops engineering."*

**Block:** C — Reproducibility · **Duration:** ~30h · **Prerequisite:** [`A5`](../block-a-intuition/A5-bash.md)

## 🎯 When you finish this module
- You write a readable CLI tool that takes arguments and handles errors properly.
- You make a request to an HTTP API, process the returned JSON, and produce an output.
- You decide, with reasoning, whether a job should be written in Bash or Python.

## 🧠 Why this, why now
In A5 you saw where Bash gets stuck (complex data, JSON, API). The CI steps in
C2 and later automation work often rest on a Python script. That's why C0 is a
bridge between A5 and C2.

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`A5 — Bash`](../block-a-intuition/A5-bash.md) | Where Bash gets stuck — the boundary where Python starts | ~15 min |
| [`STUDY-METHOD.md`](../STUDY-METHOD.md) | external-source contract — the official Python tour follows this | ~10 min |

There is **no** document in the repo that teaches Python (a deliberate gap). This
module's body gives you the foundation you need for ops **on its own**: the
**Python syntax bridge** below + examples are enough to finish the lab without
leaving. The goal isn't learning the language start to finish, but **enough to
get the job done**.

Deepening your syntax beyond the bridge is **optional** — not required for the
lab. If you do go, the official Python tour is an external source and follows
the four-field contract ([`STUDY-METHOD.md`](../STUDY-METHOD.md)):

| Source | Why you're going | What you'll do there | Duration | Verification on return |
|---|---|---|---|---|
| Official Python tour (`docs.python.org/3/tutorial`) | Take your syntax beyond the bridge (optional) | Read sections 3–5 (numbers/strings/lists, `if`/`for`, dicts) and run the examples in your own interpreter | ~2 hours | You can write, **without looking**, 5 lines that loop over a `dict` with `for` and print with an f-string |

## 🐍 Where Python, where Bash
Learn Python not as a language, but as **the tool that opens up where Bash gets stuck**.

| Job | Where |
|---|---|
| Move files, chain commands, simple filtering (`grep`/`awk`) | **Bash** |
| Multi-step flow, deep `if/else`, proper error handling | **Python** |
| Processing JSON / API responses | **Python** (`jq` in Bash only gets you so far) |
| A tool that will be reused, tested, read by someone else | **Python** |

Rule: if a Bash script goes past 30 lines, or you're parsing JSON in it, stop — this job has already moved to Python.

## 🧩 Python syntax — for people coming from Bash
To be able to read the examples below, **six things** that differ from Bash are
enough. Know these and you finish the lab without leaving; the rest gets looked
up when you need it.

| Bash | Python | Note |
|---|---|---|
| `VAR=value` / `$VAR` | `var = "value"` / `var` | no `$`; you access the variable directly by name |
| `if [ ... ]; then … fi` | `if ...:` + **indentation** | The block opens with `:`; no `fi`/`done` — **indentation** defines the block |
| `for x in ...; do … done` | `for x in ...:` + indentation | same logic, no `do`/`done` |
| (calling an external command) | `import json` | built-in capability comes via `import`, not a separate process |
| `${arr[0]}` | `d["key"]` / `lst[0]` | dictionary (`dict`) and list — access by key/index |
| `"hello $name"` | `f"hello {name}"` | f-string: put a variable/expression inside `{}` |

Two more things:
- **`with open(...) as f:`** — opens the file/connection and **closes it
  automatically** when the block ends; you don't need to clean up by hand like
  in Bash. That's why `urlopen` in Example 2 uses `with`.
- **Indentation is sacred.** What defines a block isn't curly braces, it's the
  whitespace at the start of the line. Mixed tabs/spaces → `IndentationError`.
  Use one style per file (4 spaces).

With just this much, you can read the three examples below line by line.

## 1️⃣ First tool: argument + error + exit code
A good ops tool takes arguments, doesn't swallow errors, and **talks through
its exit code** (0 = success, ≠0 = error). This is the precondition for the
tool being usable in a pipeline (C2).

```python
#!/usr/bin/env python3
import argparse, sys

def main():
    p = argparse.ArgumentParser(description="Lists large files in a directory")
    p.add_argument("path")
    p.add_argument("--min-mb", type=int, default=100)
    args = p.parse_args()
    ok = do_scan(args.path, args.min_mb)   # the actual job
    if not ok:
        print("ERROR: could not read directory", file=sys.stderr)
        sys.exit(1)            # the pipeline sees this and breaks the step

if __name__ == "__main__":
    main()
```

`argparse` gives you `--help`, type checking, and readable errors for free — don't parse arguments out of `sys.argv` by hand.

## 2️⃣ Requesting an API, processing JSON
Half of ops work is asking an API and processing the reply. Two rules: **set a
timeout** (otherwise the script hangs forever) and **check the status code**.

```python
import json, urllib.request

req = urllib.request.Request(
    "https://api.example.com/v1/status",
    headers={"Authorization": "Bearer <TOKEN>"},
)
with urllib.request.urlopen(req, timeout=10) as r:
    data = json.load(r)

for svc in data["services"]:
    if svc["state"] != "healthy":
        print(f"{svc['name']}: {svc['state']}")
```

The `requests` library writes this more concisely, but it's a dependency; for small jobs, the stdlib `urllib` is enough. Justify whichever one you pick.

## 3️⃣ Don't swallow errors, talk through the exit code
The most frequent ops mistake: `except: pass`. This makes the error invisible;
the script looks "successful" but the job didn't get done.

```python
try:
    result = do_work()
except FileNotFoundError as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(2)              # catch only the error you expect, not everything
```

Tell the caller **what happened** with `sys.exit(code)` — a silent failure is the most expensive kind of error.

## 4️⃣ Dependencies and readability
- **Virtual environment:** `python3 -m venv .venv && source .venv/bin/activate`. Don't install packages into the system Python.
- **Pin it:** write the package you use into `requirements.txt` — so the C2 pipeline installs the same version.
- **Keep it small:** your goal isn't a product, it's finishing a repetitive job. Have one script do one thing, and do it well.

## 🔨 Lab
There's no separate lab directory — this module's practice is the **acceptance
criteria** below: write a CLI with `argparse` + a script that fetches JSON.
You'll later put the tool you write here into a pipeline in the
[`C2`](C2-ci.md) CI lab ([`L10`](../labs/build/L10-ci/README.md)).

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] You wrote a working CLI tool with `argparse` that has argument + error handling and returns a zero/non-zero exit code
- [ ] You wrote a script that fetches JSON from an API and summarizes it, with timeout + status checking — its output can be shown
- [ ] "Why did I write this job in Python instead of Bash (or vice versa)" — written justification
- [ ] You **wrote**, in your own words, why swallowing errors with `except: pass` is dangerous (in your tool's README/notes)

## 🧪 Test yourself
1. When do you move a script from Bash to Python? Give two concrete signals.
2. Why is `except: pass` not just a mistake in ops, but a trap?
3. Your tool will eventually run in a **CI step** (you'll see CI in
   [`C2`](C2-ci.md) — for now just know it as "a sequence of commands that runs
   automatically on every commit"). What two things make it usable smoothly in
   that sequence ("pipeline-friendly"), and why?

<details><summary>Answers</summary>

1. (a) When a Bash script grows past 30+ lines and its `if/else` gets deep; (b) when you're parsing a JSON/API response (`jq` only gets you so far). A third signal: if the tool will be tested or read by someone else.
2. It makes the error invisible: the script looks successful (exit 0) but the job didn't get done — the most expensive error is the silent one. Catch only the error you expect, and report the rest to the caller with `sys.exit(≠0)`.
3. (a) **Exit code:** 0 for success, ≠0 for error — the pipeline looks at this to break/pass the step; (b) **stderr:** writing the error separately from stdout keeps logs from getting mixed up with output. Without both, the tool fails silently.
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| `ModuleNotFoundError` | Package is in system Python / venv not active | Create + activate a venv; `pip install`; write it into `requirements.txt` |
| Script hangs on an API call | No timeout | `urlopen(..., timeout=10)`; put a timeout on every network call |
| Script is "successful" but the job wasn't done | `except: pass` swallowed the error | Catch only the expected error; report with `sys.exit(≠0)` |
| CLI arguments are parsed by hand, fragile | Manual parsing with `sys.argv` | Use `argparse` — free `--help` + type checking |

## 💼 Portfolio output
A small but real ops tool (e.g. a health-check / report script).

## ⏭️ Up next
[`C1 — Container`](C1-container.md)

---

> *"Learn Python not like a software engineer, but like an operator: your goal isn't a product, it's finishing the repetitive job."*
