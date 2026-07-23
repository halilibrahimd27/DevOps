---
description: "Common error → cause → fix index: the most frequent sticking points along the path, in one place."
tags: [Learning Path, Troubleshooting]
---
# 🆘 Troubleshooting — Common Error → Cause → Fix

> *"Getting stuck on the same error twice isn't learning — it's waste. This page prevents that waste."*

Every module has its own `🆘 If You're Stuck` table; this page collects the sticking points
**common across blocks** in one place. Find the symptom, understand the cause, apply the fix.
Every row starts with a **symptom** — because you see the symptom, not the cause.
Where a broken lab is linked, its `solution.md` walks through the full diagnostic flow.

> ⚠️ All commands below are examples; replace placeholders like `<NAMESPACE>`, `<APP>`, `<POD>`
> with your own values. Output examples are truncated.

---

## 🐧 Block A — Linux, networking, git, manual deploy

| Symptom | Likely cause | What to do |
|---|---|---|
| `curl: (7) Connection refused` | The service isn't listening on that port at all (the app crashed or never started) | `systemctl status <SVC>` → did it start? `ss -tlnp \| grep :<PORT>` → is anything listening? Walk the chain in order: **start → connect**. See [`K00`](labs/broken/K00-systemd-ayaga-kalkmiyor/solution.md) |
| `systemctl start` fails silently, service loops `activating`↔`failed` | `ExecStart` never ran: user/working-directory/`EnvironmentFile` pre-setup blew up | `systemctl status <SVC>` top line + `journalctl -u <SVC> -e`. `status=219/…` → environment setup error. See [`K00`](labs/broken/K00-systemd-ayaga-kalkmiyor/solution.md) |
| `Address already in use` / `EADDRINUSE` | Another process is holding the port (the old process didn't die, or a conflicting service) | `ss -tlnp \| grep :<PORT>` or `sudo lsof -i :<PORT>` → find the holder, kill it if needed. See [`K01`](labs/broken/K01-kirik-vm/solution.md) |
| `Permission denied` when accessing a file | User/group ownership or mode (`rwx`) is wrong; the service user can't read it | `ls -l <FILE>` → owner + mode. Align with `chown <USER>:<GROUP>` / `chmod`. Services run as their own user, not yours |
| `sudo: command not found` / command not found | Not in `PATH`, or the package isn't installed | If `which <COMMAND>` is empty, try `type -a <COMMAND>`; if not installed, install it with your package manager. Verify the search path with `echo $PATH` |
| Disk full: `No space left on device` | Logs/temp files/old images filled the disk | `df -h` (which mount), narrow down with `du -sh /*`; log rotation or `journalctl --vacuum-size=` |
| `git push` → `rejected (non-fast-forward)` | The remote branch is ahead of your local; someone else pushed | `git fetch` → `git rebase origin/<BRANCH>` (resolve conflicts if any) → push again. **Don't use** `--force` |
| `git` "detached HEAD" warning | You checked out a commit directly instead of a branch | Save your work with `git switch -c <NEW_BRANCH>`, or go back with `git switch <BRANCH>` |
| You want to undo the wrong commit | Confusion between `reset` and `revert` | If it hasn't been shared, use `git reset`; if it has, use `git revert <SHA>` to avoid rewriting history. See [`A4`](block-a-intuition/A4-git-temeli.md) |

## 🌐 Block A — Networking, DNS, HTTP, TLS

| Symptom | Likely cause | What to do |
|---|---|---|
| `curl: (6) Could not resolve host` | DNS resolution failed (wrong name, `/etc/resolv.conf`, resolver unreachable) | `dig <DOMAIN>` / `nslookup <DOMAIN>` → does it return an answer? `cat /etc/resolv.conf` → is the resolver correct? If `curl` works with the IP, the problem is DNS. See [`K01`](labs/broken/K01-kirik-vm/solution.md) |
| Ping works but the app won't connect | L3 (IP) is fine, L4/L7 is broken: port closed, firewall, app down | Separate the layers: `ping` (L3) → `nc -vz <HOST> <PORT>` (L4) → `curl` (L7). The first layer that breaks is the cause. See [`A2`](block-a-intuition/A2-ag-tcp-ip.md) |
| `curl: (60) SSL certificate problem` | Certificate chain incomplete, name mismatch, or expired | `openssl s_client -connect <HOST>:443 -servername <HOST>` → chain + `notAfter`. Does the name match the CN/SAN? See [`A3`](block-a-intuition/A3-ag-dns-http-tls.md) |
| `curl` is very slow, then hangs | DNS timeout or wrong routing (wrong gateway) | Measure where it's waiting with `curl -w "dns:%{time_namelookup} conn:%{time_connect}\n"`; verify the gateway with `ip route` |
| HTTP `301/302` loop | http↔https or www redirect is looping back on itself | Trace the `Location` chain with `curl -IL <URL>`; use the correct scheme to break the loop |
| HTTP `403 Forbidden` (application level) | Authorization/file permission or a reverse-proxy rule | Read the server log (`journalctl` / access log); permissions for static files, identity/role for APIs |

## 🔭 Block B — Logs and metrics

| Symptom | Likely cause | What to do |
|---|---|---|
| `journalctl` empty / "No journal files" | Persistent journal is disabled, or the unit name is wrong | `journalctl -u <SVC>` (correct unit), `-b` (this boot), `-b -1` (previous boot). For a persistent journal use `/var/log/journal` |
| The log "isn't saying anything" | The app isn't structured, the level is too high, or it's writing to a file instead of stdout | Lower the log level; find out where it's writing (`systemd` → journald; container → stdout). For what gets logged / doesn't, see [`B1`](block-b-visibility/B1-log-okuma.md) |
| Prometheus target `DOWN` | Scrape address is wrong, `/metrics` doesn't exist, or the network is blocked | Prometheus UI → Status → Targets → error column. Does `curl <TARGET>/metrics` work manually? See [`B2`](block-b-visibility/B2-metrik-prometheus.md) |
| PromQL query returns empty | Metric name/label is wrong, or it hasn't been scraped yet | Verify the metric name via autocomplete; narrow labels with `{job="..."}`; wait at least one scrape interval |
| Metric cardinality explosion, Prometheus slow/OOM | A high-cardinality value was put in a label (user id, request id) | Count the labels; remove the identifier/free-text label. See [`B2`](block-b-visibility/B2-metrik-prometheus.md) |
| "Something's broken but I don't know where" | You're guessing without tying the symptom to evidence | **Narrow it down** with the `status → journalctl → ss/curl` trio; **prove** your hypothesis with logs/metrics. See [`K01`](labs/broken/K01-kirik-vm/solution.md) |

## 📦 Block C — Container, CI, Terraform, cloud

| Symptom | Likely cause | What to do |
|---|---|---|
| Container is `Up` but `curl` returns an empty response | The **container side** of the port mapping doesn't match the port the app is listening on | `docker compose logs <SVC> \| grep listen` → the real port; the right-hand side of `ports: "HOST:CONTAINER"` must match it. See [`K02`](labs/broken/K02-container-hatasi/solution.md) |
| `docker build` rebuilds every layer from scratch | Cache-busting order: `COPY . .` comes before the dependency install | `COPY` the dependency manifest and install first, **then** copy the source. For multi-stage, see [`C1`](block-c-reproducibility/C1-container.md) |
| Image is far bigger than it needs to be | Single-stage build, build tools stayed in the image | Multi-stage: build in one stage, copy only the artifact; use a slim/distroless base |
| `docker run` → `exec format error` | Image architecture (arm64/amd64) doesn't match the machine | Check the architecture with `docker inspect`; pull/build the right architecture with `--platform` |
| You pulled `:latest`, behavior changed | Mutable tag; the underlying image changed silently | Pin a version tag or digest (`@sha256:...`). `:latest` is banned in production. See [`C1`](block-c-reproducibility/C1-container.md) |
| `docker push` in CI → `denied` / `unauthorized` | Registry credentials missing/wrong, or the repo path is wrong | Verify the registry login step; check the `<REGISTRY>/<APP>` path and token permissions. See [`C2`](block-c-reproducibility/C2-ci.md) |
| CI: "it worked on my machine" but the pipeline blows up | Hidden local dependency; the runner is a clean environment | Pin dependencies with a lockfile; run the test in a clean container |
| `Error acquiring the state lock` | An interrupted `apply` died without clearing `.terraform.tfstate.lock.info` (stale lock) | `ps aux \| grep [t]erraform` → if there's no live process, run `terraform force-unlock <ID>` (the ID is in the error message). See [`K03`](labs/broken/K03-terraform-state/solution.md) |
| `terraform plan` shows a change every time | Drift, or a field the provider doesn't normalize | Read the `terraform plan` diff; revert the manual change, or move it into code |
| `terraform apply` corrupted state / deleted the wrong resource | Manual change + state mismatch | Don't panic: `terraform state list/show`; if needed, use `import` to reconcile reality with state. See [`C3`](block-c-reproducibility/C3-terraform.md) |
| Can't connect to LocalStack | Endpoint/region/fake credentials aren't set | `--endpoint-url http://127.0.0.1:4566`, fake `test`/`test` credentials, region set. See [`C4`](block-c-reproducibility/C4-bulut-butce-alarmi.md) |
| Unexpected cloud bill | No budget alarm; a resource was left running | **Budget alarm first** (rule number one), then the resource. Verify locally with `validate/plan`. See [`C4`](block-c-reproducibility/C4-bulut-butce-alarmi.md) |

## ☸️ Block D — Kubernetes, security, GitOps

| Symptom | Likely cause | What to do |
|---|---|---|
| Pod `Pending` | The scheduler can't place it: no resources, node selector/taint, PVC not bound | `kubectl describe pod <POD>` → the last Events line tells you why (Insufficient cpu/memory, unbound PVC, taint) |
| `ImagePullBackOff` / `ErrImagePull` | Image tag doesn't exist, registry is private (no secret), or the name is wrong | `kubectl describe pod <POD>` → Events: full image name + error. Fix the tag/name, or add `imagePullSecrets`. See [`K04`](labs/broken/K04-imagepullbackoff-rbac/solution.md) |
| `CreateContainerConfigError` | `configMapKeyRef`/`secretKeyRef` is asking for a key/resource that doesn't exist | `describe` Events tells you the key name; align it with the actual key in the ConfigMap/Secret. See [`K07`](labs/broken/K07-incident-sim/solution.md) |
| `CrashLoopBackOff` | The container starts but dies immediately (config, dependency, code) | `kubectl logs <POD> --previous` → the dead instance's log; `describe` → Last State/Exit Code |
| `OOMKilled` (Exit Code 137) | The container exceeded its memory **limit**, the kernel killed it | `describe` → Last State: OOMKilled. Raise `limits.memory` to match actual need. See [`K05`](labs/broken/K05-oomkilled-probe/solution.md) |
| Pod is `Running` but `0/1 Ready`, Service sends no traffic | readinessProbe failing (wrong port/path); the Pod never enters `Endpoints` | `describe` → Readiness line; if `kubectl get endpoints <SVC>` is empty, does the probe port match the app's port? See [`K05`](labs/broken/K05-oomkilled-probe/solution.md) |
| Can't reach the Service, `endpoints` is empty | `Service.selector` doesn't match the Pod labels | `kubectl get svc <SVC> -o jsonpath='{.spec.selector}'` ↔ `kubectl get pods --show-labels`. Align the selector with the labels. See [`K07`](labs/broken/K07-incident-sim/solution.md) |
| Pod is healthy but unreachable over the network | A `default-deny` NetworkPolicy with no allow rule is blocking all traffic | `kubectl get networkpolicy -n <NS>`; add the matching **allow** rule (NetworkPolicies are additive). See [`K04`](labs/broken/K04-imagepullbackoff-rbac/solution.md) |
| `Error ... is forbidden` (RBAC) | The ServiceAccount has no Role/Binding for the requested verb/resource | `kubectl auth can-i <VERB> <RESOURCE> --as=system:serviceaccount:<NS>:<SA>`; grant the missing permission with a Role+RoleBinding, no more than needed. See [`D1`](block-d-orchestration/D1-k8s-temel.md) |
| PVC `Pending` | StorageClass missing/wrong, or no matching PV | `kubectl describe pvc <PVC>` → Events; verify the StorageClass name and provisioner |
| You set a Secret as an env var, and it leaked into the logs | Secret as plaintext env var; the app logs its env at startup | Mount the Secret as a file, or disable env logging; never keep plaintext secrets in source. See [`D3`](block-d-orchestration/D3-secret-yonetimi.md) |
| CI's image scan step "passes" but there's no signature | Supply chain was treated as a separate lesson; signing was never wired into the pipeline | Scanning **and** signing must be part of the C2 pipeline, not a separate job bolted on afterward. See [`D4`](block-d-orchestration/D4-supply-chain.md) |
| ArgoCD is `OutOfSync`, not auto-correcting | No `syncPolicy.automated` (manual mode); the cluster was changed by hand (drift) | `kubectl -n argocd get app <APP> -o jsonpath='{.spec.syncPolicy}'`; enable `automated` (+`selfHeal`), or `sync` manually. See [`K06`](labs/broken/K06-argocd-out-of-sync/solution.md) |
| `kubectl` → `Unable to connect / context` | Wrong kubeconfig/context, or the cluster is down | `kubectl config current-context`; for kind, `kind get clusters`; switch the context to the right cluster |

## 🔭 Block E — SLO, alerting, incident, restore

| Symptom | Likely cause | What to do |
|---|---|---|
| Restore "returned successfully" but the target is empty | Backup is schema-only, or the data never landed; the exit code doesn't expose an empty backup | Check `SELECT count(*)`, not the exit code; in the dump file, `grep -c '^COPY '`. See [`K08`](labs/broken/K08-restore-basarisiz/solution.md) |
| Restore `unterminated COPY` / `missing data` | The dump was taken while truncated (`pg_dump` interrupted mid-run) | Check the end of the file (`tail`); verify every time that the backup was taken **in full**. See [`K08`](labs/broken/K08-restore-basarisiz/solution.md) |
| Backup file `Permission denied` | Permissions are `000`/wrong owner — an inaccessible backup is the same as no backup during an incident | `ls -l`; `chmod u+r`; test backup access regularly. See [`E4`](block-e-ownership/E4-veritabani-restore.md) |
| "We have 3 replicas, we're HA" — but restarts cause an outage | `strategy: Recreate` takes down all pods at once; no readinessProbe | `RollingUpdate` + a small `maxUnavailable`; add a readinessProbe; `PodDisruptionBudget`. See [`K09`](labs/broken/K09-chaos-gameday/solution.md) |
| Alerts fire constantly, nobody looks (alert fatigue) | Alerting on a non-causal, non-symptom metric; wrong threshold | Tie alerts to a user-impacting SLI (symptom-based); mute/delete the noisy alert. See [`E2`](block-e-ownership/E2-alerting-oncall.md) |
| Error budget is exhausted but new features keep shipping | SLO policy isn't enforced; the budget is just a report | What stops when the budget runs out must be written down; tie the SLO to an actual decision. See [`E1`](block-e-ownership/E1-sli-slo-error-budget.md) |
| Everyone knows something different during the incident | No timeline is kept; there's no single coordinator | Write a UTC timeline as it happens; separate roles (coordinator/communications). See [`E3`](block-e-ownership/E3-incident-postmortem.md) |
| The postmortem turns into "who made the mistake" | Blame culture; the person is questioned, not the system | Shift the language to the system: "the system allowed this to reach production"; every action item gets an owner + a date. See [`E3`](block-e-ownership/E3-incident-postmortem.md) |

---

## 🚫 Diagnostic anti-patterns

| Anti-pattern | Why it's bad | Do instead |
|---|---|---|
| Guessing the root cause the moment you see a symptom, and starting to "fix" it | You fix the wrong layer and miss the second failure | **Tie** the symptom to the root cause with a command first, then fix it |
| Assuming it works because "Container Up" / "service active" | Being up is not the same as being reachable | Prove reachability with a separate command (`curl`/`endpoints`) |
| Stopping after the first fix on a multi-fault system | A second root cause keeps the symptom alive, and you'll think you "couldn't fix it" | After every fix, measure **which part** of the symptom went away |
| Staring at the `RESTARTS: 12` count looking for an explanation | The number isn't the explanation; the cause is elsewhere | `describe` → `Last State`/Events gives you the reason |
| Opening `solution.md` at the first error | You never exercise your diagnostic muscle | Start with `hint-1` → build your own hypothesis first |
| Calling a restore "successful" based on the exit code | An empty/truncated backup returns 0 errors | Prove the data actually landed with `count(*)` |
| Panicking and manually deleting the `terraform` lock file | The wrong habit on a shared backend | First separate live from stale, then `force-unlock <ID>` |

---

## 📋 Sequence for when you're stuck

```
[ ] Checked the module's own 🆘 If You're Stuck table
[ ] Searched for the symptom on this page
[ ] Tied the symptom to the root cause with a command (didn't guess)
[ ] If in a broken lab: opened the hints/ folder in order (hint-1 → hint-2 → hint-3)
[ ] Could be multi-fault: measured what remained of the symptom after the first fix
[ ] Still stuck: tried to prove my hypothesis with logs + metrics
```

---

> *"A good troubleshooting page doesn't give you the answer — it points you to where to ask the right question."*
