# 16 · Cheatsheets

> *"Bilmek değil, **hatırlamak** yetenektir; ortalama mühendisin gerçek
> üstünlüğü kütüphane gibi düzenlenmiş `~/notes` klasörüdür."*

Her bir cheatsheet:
- Sık kullanılan komutları gruplar
- Boilerplate ezbere bilinmesi gerekmesin
- "Aha şuydu!" anında 5 sn içinde bulunur

## İçindekiler

| Dosya | Konu |
|---|---|
| [`kubectl.md`](kubectl.md) | Pod debug, rollout, port-forward, kubectx/kubens, JSONPath |
| [`docker.md`](docker.md) | Build, run, exec, networks, volumes, prune, BuildKit |
| [`git.md`](git.md) | Rewrite history, bisect, cherry-pick, reflog, worktree |
| [`helm.md`](helm.md) | Template debug, release, repo, hook, OCI registry |
| [`terraform.md`](terraform.md) | Plan/apply, state ops, import, console, fmt/validate |
| [`aws-cli.md`](aws-cli.md) | EC2/S3/IAM, ssm, sts assume-role, profiles, query |
| [`linux-troubleshooting.md`](linux-troubleshooting.md) | top/htop/iotop, strace, lsof, ss, journalctl |
| [`networking-tools.md`](networking-tools.md) | dig, curl, nc, tcpdump, mtr, ssh tunnel |
| [`vim-survival.md`](vim-survival.md) | "Hangi cehennemden kaçayım" — minimum vim guide |

## Hızlı erişim önerisi

Bu cheatsheet'leri terminalde anında açmak için:

```bash
# ~/.bashrc veya ~/.zshrc
export DEVOPS_NOTES="$HOME/Desktop/DevOps/16-Cheatsheets"
alias k8s-cs='${EDITOR:-vim} $DEVOPS_NOTES/kubectl.md'
alias dk-cs='${EDITOR:-vim} $DEVOPS_NOTES/docker.md'
alias git-cs='${EDITOR:-vim} $DEVOPS_NOTES/git.md'
alias tf-cs='${EDITOR:-vim} $DEVOPS_NOTES/terraform.md'
alias linux-cs='${EDITOR:-vim} $DEVOPS_NOTES/linux-troubleshooting.md'

# fzf ile interaktif arama
cs() {
  local file
  file=$(ls $DEVOPS_NOTES/*.md | fzf --preview 'cat {}')
  [ -n "$file" ] && ${EDITOR:-vim} "$file"
}
```
