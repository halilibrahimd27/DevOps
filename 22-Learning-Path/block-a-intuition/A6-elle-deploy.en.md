---
description: "Stand up an application by hand: VM, nginx, a DB, systemd unit, and logs — NO containers. The anchor of the path."
level: A
module: A6
estimated_hours: 27
prerequisites: [A1, A2, A3, A4, A5]
tags: [Learning Path, Deployment]
---
# A6 — Stand Up an Application by Hand (No Containers)

> *"Only someone who has lived the pain before an abstraction knows what that abstraction actually solves. This module is that pain."*

**Block:** A — Intuition · **Duration:** ~27h · **Prerequisite:** [`A1`](A1-linux-temeli.md), [`A2`](A2-ag-tcp-ip.md), [`A3`](A3-ag-dns-http-tls.md), [`A4`](A4-git-temeli.md), [`A5`](A5-bash.md)

## 🎯 When you finish this module
- You'll stand up nginx + a database + an application on a VM **by hand**, step by step.
- You'll define the application as a `systemd` unit and make it survive a restart (reboot).
- You'll find and read service logs from `journalctl` and nginx's log files, and use that information to narrow down a failure.

## 🧠 Why this, why now
This module is deliberately tedious and **should not be made easier.** Deploy by hand,
break it, fix it by hand. When containers (C1), Terraform (C3), and K8s (D1) show up later,
you'll know from this experience *exactly which manual work* each one eliminates.
The answer to "why containers?" is the pain you go through in this module: dependency
installation, "it worked on my machine," port conflicts, the service not coming up on boot.
In C3 we'll automate all of these steps with Terraform — but if you haven't done what
you're automating by hand once, you can't see what the automation is actually doing.

## 📖 How to study this
Work on a free, local Linux VM. Options (pick one):
- **Multipass** (`multipass launch --name lab`) — fastest, an Ubuntu VM.
- **Vagrant + VirtualBox** — portable, repeatable via a `Vagrantfile`.
- **Proxmox / KVM** — if you have your own server (see [`21-Field-Notes/`](../../21-Field-Notes/README.md)).

Run every command **inside the VM**, not on your host machine. When a step breaks,
check the logs first — don't go looking for a hint. Breaking things is this module's
lesson. Note every step you take in a `KURULUM.md` file — version it with the Git you
learned in A4; these notes are the template you'll turn into Terraform in C3.

## 📚 What you'll build — architecture
```
Internet / browser
        │  :80 / :443
        ▼
   ┌─────────┐      :80/tcp open, everything else closed
   │  nginx  │  ── reverse proxy (forwards the request to the app)
   └────┬────┘
        │  127.0.0.1:<APP_PORT>  (from localhost only)
        ▼
   ┌─────────┐      systemd unit: comes up on boot, restarts on crash
   │  <APP>  │  ── application (Flask/Node — a simple service)
   └────┬────┘
        │  127.0.0.1:5432
        ▼
   ┌──────────────┐
   │ PostgreSQL   │  ── database (listens on localhost only)
   └──────────────┘
```

---

## 1️⃣ Prepare the VM

```bash
multipass launch --name lab --cpus 2 --memory 2G --disk 10G
multipass shell lab                    # enter the VM
sudo apt update && sudo apt -y upgrade # refresh the package list
```

You're inside the VM now. Everything from here on happens here. Verify where you
are with `hostname` and `ip a` (A2).

## 2️⃣ Database: PostgreSQL

```bash
sudo apt -y install postgresql
sudo systemctl status postgresql       # is it running (the status check from A1)
```

Create a separate user and database for the application — don't hand the `postgres`
superuser to the application (least privilege). The `psql <<'SQL' … SQL` pattern below is
a **heredoc**: the `<<` marker feeds the two lines of SQL you write in between to `psql`
as input (a shortcut for running this without connecting to the database by hand).

```bash
sudo -u postgres psql <<'SQL'
CREATE USER appuser WITH PASSWORD '<DB_PASSWORD>';
CREATE DATABASE appdb OWNER appuser;
SQL
```

Test the connection with the **user the application will use**:

```bash
psql "postgresql://appuser:<DB_PASSWORD>@127.0.0.1:5432/appdb" -c "SELECT 1;"
# ?column? \n --- \n 1
```

If `SELECT 1` comes back, the DB is up, the user is right, the port is open. If it
doesn't, go back to A2: is it `connection refused` (service down/port closed), `timed
out` (firewall), or an auth error? Isolate the symptom.

## 3️⃣ Run the application by hand — and watch it die

Writing an application from scratch isn't the point of this module; use a ready-made
example. The lab provides one:
[`labs/build/L06-elle-deploy/starter/app.py`](../labs/build/L06-elle-deploy/starter/app.py)
— a small HTTP service that runs on Python stdlib alone (`/health` → `ok`, `/db` → the
`pg_isready` result). Copy it to your VM (e.g. `/opt/lab-app/app.py`) and first run it
**by hand, in the foreground**:

```bash
cd /opt/lab-app
DB_URL="postgresql://appuser:<DB_PASSWORD>@127.0.0.1:5432/appdb" python3 app.py
# The app is listening on 127.0.0.1:8000... (nginx will face outward)
```

Request it from another terminal (the `curl` from A3):

```bash
curl -s http://127.0.0.1:8000/health   # ok
```

Now close the terminal (`Ctrl+C`) and request it again: **`connection refused`.** The
application died. Here's the problem: a service shouldn't live tied to the session that
started it. `systemd` solves this.

> 🔒 You're seeing the password on the command line — this is temporary. In the
> permanent setup, the password goes into an environment file and the file's permissions
> are locked down (below). Don't leave the secret visible in `ps` (the security note
> from A5).

## 4️⃣ systemd unit: make the service permanent

Turn the application into a service. First give the application **its own, unprivileged
user**:

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin appsvc
```

Environment (secret) file — lock down the permissions:

```bash
sudo tee /etc/app.env >/dev/null <<'ENV'
APP_HOST=127.0.0.1
APP_PORT=8000
DB_URL=postgresql://appuser:<DB_PASSWORD>@127.0.0.1:5432/appdb
ENV
sudo chown appsvc:appsvc /etc/app.env
sudo chmod 600 /etc/app.env            # only the owner can read it (A1 permission model)
```

`app.py` reads `APP_HOST`/`APP_PORT` from this file; `DB_URL` is an example of a
**secret** that needs protecting (permission `600` — only the service user can see it).

Unit file — `/etc/systemd/system/app.service`:

```ini
[Unit]
Description=<APP> application
After=network.target postgresql.service

[Service]
User=appsvc
EnvironmentFile=/etc/app.env
WorkingDirectory=/opt/lab-app
ExecStart=/usr/bin/python3 /opt/lab-app/app.py
Restart=on-failure
# security hardening:
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
# This application doesn't write to disk; if it did, you'd open the writable path here:
# ReadWritePaths=/opt/lab-app/data

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload           # read the new unit
sudo systemctl enable --now app        # start it now + bring it up on boot
sudo systemctl status app              # should show active (running)
```

Now restart the VM (`sudo reboot`), log back in, `curl .../health` — **the application
is up on its own.** That's what `enable` does; `--now` means "also start it right now".

> 🔒 `User=appsvc`, `NoNewPrivileges`, `ProtectSystem=strict` aren't a choice, they're a
> rule. If the application runs as `root`, an attacker who compromises it gets the whole
> VM; with an unprivileged user the blast radius shrinks to the application's own
> directory. This is the same principle that comes back in D1 as K8s's
> `securityContext`/`runAsNonRoot`.

## 5️⃣ nginx: reverse proxy

Don't expose the application directly to the internet; put nginx in front of it. nginx
listens on 80/443 and forwards the request to `127.0.0.1:<APP_PORT>`:

```bash
sudo apt -y install nginx
```

`/etc/nginx/sites-available/app`:

```nginx
server {
    listen 80;
    server_name <DOMAIN>;

    location / {
        proxy_pass http://127.0.0.1:<APP_PORT>;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app
sudo nginx -t                          # VALIDATE the config syntax (before deploying)
sudo systemctl reload nginx            # reload without downtime
curl -s http://127.0.0.1/health        # now coming through :80
```

The application should now only listen on `127.0.0.1` (closed to the outside); nginx
is the only external door. Verify this with the `ss -tlnp` from A2: the application's
port is on `127.0.0.1`, nginx's is on `0.0.0.0:80`.

## 6️⃣ Firewall: least exposure

```bash
sudo ufw default deny incoming         # default: close everything
sudo ufw allow 22/tcp                  # SSH (don't lock yourself out!)
sudo ufw allow 80/tcp                  # nginx
sudo ufw enable
sudo ufw status
```

The DB port (5432) and the application port stay **closed to the outside** — they only
talk within localhost. The "least-exposure firewall" principle from A2 becomes concrete
here.

## 7️⃣ Logs: what the system is telling you

When something breaks, the log is the first place you look (a preview of B1):

```bash
sudo journalctl -u app -e             # the application's systemd log, jump to the end
sudo journalctl -u app -f             # follow live (send a request, watch it)
sudo tail -f /var/log/nginx/access.log /var/log/nginx/error.log
```

Narrow down a failure: if `curl` returns 502 → check nginx's `error.log` → you see
"connection refused to 127.0.0.1:<APP_PORT>" → so the application is dead → `systemctl
status app` → `journalctl -u app` → root cause (e.g. wrong DB password). This chain is
the core of all the diagnostic work in blocks B and E.

## 8️⃣ (Optional) TLS

You learned what a certificate is in A3. On a local VM you can practice with a
self-signed certificate; if you have a real domain exposed to the internet, get a free
Let's Encrypt certificate with `certbot`. TLS's depth lives in blocks C and D; here the
goal is just to see nginx listening on `443` and serving the certificate.

---

## 🚫 Anti-pattern table
| Anti-pattern | Why it's bad | Right |
|---|---|---|
| Backgrounding the application with `nohup ./app &` | Doesn't come up on boot, doesn't restart on crash, logs are scattered | `systemd` unit + `enable` + `Restart=on-failure` |
| Running the service as `root` | If compromised, the whole VM goes with it | `User=<unprivileged>` + systemd hardening |
| Exposing the application directly on `0.0.0.0:80` | TLS/rate-limiting/logging aren't centralized, exposed surface | nginx reverse proxy; application on `127.0.0.1` only |
| Hardcoding the password in the unit/code | Leaks into git and into `systemctl cat` | `EnvironmentFile` + `chmod 600` |
| Connecting to the DB with the `postgres` superuser | An application vulnerability hands over the entire DB | Separate `appuser`, privileges scoped to its own DB only |
| Never setting up a firewall / opening every port | DB/internal ports face the internet | `deny incoming` + only 22/80/443 |
| `reload` without running `nginx -t` first | A broken config takes the service down | `nginx -t` first, then `reload` |
| Not documenting the setup | The second setup is painful from scratch | Write every step to `KURULUM.md`, version it with Git |

## 📖 Calibration reference
| Source | For what | Duration |
|---|---|---|
| [`21-Field-Notes/ansible/system-preparation.md`](../../21-Field-Notes/ansible/system-preparation.md) | What a real system-prep note actually looks like | ~20 min |

## 🔨 Lab
👉 [`labs/build/L06-elle-deploy/`](../labs/build/L06-elle-deploy/README.md) — (Task outline: starting
from a blank VM, set up the DB + application + systemd unit + nginx + firewall by hand,
survive a reboot, and write every step to `KURULUM.md`.)

## 💥 Broken lab
👉 [`labs/broken/K00-systemd-ayaga-kalkmiyor/`](../labs/broken/K00-systemd-ayaga-kalkmiyor/README.md) — Symptom: "the systemd
service won't come up." The cause is hidden (port conflict / wrong `ExecStart` path /
permissions / missing `EnvironmentFile`). Requires no K8s knowledge; debugging intuition
starts right here.

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] `systemctl is-enabled app` → `enabled` and `systemctl is-active app` → `active`; the application is up on its own after a VM reboot.
- [ ] `curl -s http://127.0.0.1/health` returns `200` and the expected body through nginx; you've shown with `ss -tlnp` that the application listens only on `127.0.0.1` and nginx on `0.0.0.0:80`.
- [ ] You solved the K00 broken lab using at most `hint-1`/`hint-2`; you wrote down the root cause and the diagnostic flow.
- [ ] You **wrote** a few sentences answering "which steps took the most time, and exactly how does the container (C1) change this."

## 🧪 Test yourself
1. What's the difference between `systemctl enable app` and `systemctl start app`? Which one makes it survive a reboot?
2. **Scenario:** `curl http://127.0.0.1/health` → `502 Bad Gateway`. The service doesn't come up on boot. What are your first three checks, in what order?
3. **Design:** Why put the application behind nginx instead of exposing it directly on `:80`? Write at least two reasons.

<details><summary>Answers</summary>

1. `start` starts the application **now** but isn't persistent; it won't come back after a reboot. `enable` links the unit to the boot target (`multi-user.target`), so it starts automatically on every boot. `enable` is what lets it survive a reboot; `enable --now` does both at once.

2. (a) `sudo systemctl status app` → is the service `active` or `failed`? (b) If not `active`, `sudo journalctl -u app -e` → why did the application exit (port conflict? couldn't connect to the DB? wrong path?). (c) If `active`, the problem is in the proxy: `sudo tail /var/log/nginx/error.log` → can nginx reach the application, and does `ss -tlnp` show the application actually listening on that port? 502 = "nginx is there but can't reach the application behind it".

3. At least two: (a) **Single external door** — TLS termination, rate limiting, and access logging are collected in one place; the application stays simple. (b) **Security** — the application only listens on `127.0.0.1`, not directly exposed to the internet; the attack surface shrinks to nginx. (c) You can route multiple applications by path through a single IP/port. (d) You can manage connections on the nginx side while restarting/replacing the application.

</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| `systemctl status app` → `failed` | `ExecStart` path is wrong / file isn't executable | `journalctl -u app -e`; check the path and `chmod +x` |
| `active` but `curl` → `connection refused` | The application is listening on a different address/port | See the actual listening address with `ss -tlnp` (A2) |
| `502 Bad Gateway` | nginx can't reach the application | `error.log`; is the application up on `127.0.0.1:<APP_PORT>` |
| Application starts, dies immediately | Can't connect to the DB / `EnvironmentFile` is missing | `journalctl -u app`; also test the connection with `psql` |
| No service after reboot | Not `enable`d | `systemctl enable app`; verify with `is-enabled` |
| You got locked out of SSH, can't get into the VM | `ufw` closed port 22 | Get in through the VM console (Multipass/Proxmox), `ufw allow 22` |
| `Address already in use` | Port conflict (K00's classic cause) | Find who's holding it with `ss -tlnp \| grep <PORT>` |

## 💼 Portfolio output
A service deployed by hand, managed by systemd, running behind nginx, plus your
`KURULUM.md` setup notes. This is the foundation you'll turn into Terraform in C3 and
K8s in D1 — the first concrete output where you can say "I took something to
production with my own hands."

## ⏭️ Up next
[`B1 — Reading Logs`](../block-b-visibility/B1-log-okuma.md)

---

> *"An A6 made easier undermines the whole path. The tedium here is left in on purpose."*
