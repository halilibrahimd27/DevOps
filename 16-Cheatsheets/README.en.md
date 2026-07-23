---
description: "Index of the DevOps cheatsheet collection: kubectl, docker, git, helm, terraform, aws-cli, and more. Groups frequently used commands for quick access."
tags:
  - Cheatsheet
  - Roadmap
  - Field Notes
---
# 16 · Cheatsheets

> *"It's not knowing but **remembering** that's the skill; the average
> engineer's real edge is a `~/notes` folder organized like a library."*

Each cheatsheet:
- Groups frequently used commands
- So boilerplate doesn't need to be memorized
- Gets found within 5 seconds at the "oh, that was it!" moment

## Table of Contents

| File | Topic |
|---|---|
| [`kubectl.md`](kubectl.md) | Pod debug, rollout, port-forward, kubectx/kubens, JSONPath |
| [`docker.md`](docker.md) | Build, run, exec, networks, volumes, prune, BuildKit |
| [`git.md`](git.md) | Rewrite history, bisect, cherry-pick, reflog, worktree |
| [`helm.md`](helm.md) | Template debug, release, repo, hook, OCI registry |
| [`terraform.md`](terraform.md) | Plan/apply, state ops, import, console, fmt/validate |
| [`aws-cli.md`](aws-cli.md) | EC2/S3/IAM, ssm, sts assume-role, profiles, query |
| [`linux-troubleshooting.md`](linux-troubleshooting.md) | top/htop/iotop, strace, lsof, ss, journalctl |
| [`networking-tools.md`](networking-tools.md) | dig, curl, nc, tcpdump, mtr, ssh tunnel |
| [`vim-survival.md`](vim-survival.md) | "Which hell am I escaping from" — minimum vim guide |

## Quick-access tip

To open these cheatsheets instantly from the terminal:

```bash
# ~/.bashrc or ~/.zshrc
export DEVOPS_NOTES="$HOME/Desktop/DevOps/16-Cheatsheets"
alias k8s-cs='${EDITOR:-vim} $DEVOPS_NOTES/kubectl.md'
alias dk-cs='${EDITOR:-vim} $DEVOPS_NOTES/docker.md'
alias git-cs='${EDITOR:-vim} $DEVOPS_NOTES/git.md'
alias tf-cs='${EDITOR:-vim} $DEVOPS_NOTES/terraform.md'
alias linux-cs='${EDITOR:-vim} $DEVOPS_NOTES/linux-troubleshooting.md'

# interactive search with fzf
cs() {
  local file
  file=$(ls $DEVOPS_NOTES/*.md | fzf --preview 'cat {}')
  [ -n "$file" ] && ${EDITOR:-vim} "$file"
}
```
