---
description: "Network II: DNS → HTTP → TLS/certificate — how a name becomes a secure connection, in this order."
level: A
module: A3
estimated_hours: 16
prerequisites: [A2]
tags: [Learning Path, Networking]
---
# A3 — Network II: DNS → HTTP → TLS/Certificate

> *"Whoever knows the path from typing an address in the browser to the encrypted connection solves half of production outages — half of which are DNS."*

**Block:** A — Intuition · **Duration:** ~16h · **Prerequisite:** [`A2`](A2-ag-tcp-ip.md)

## 🎯 When you finish this module
- You trace a name resolution (DNS) step by step, and show where a wrong answer comes from.
- You can read the anatomy of an HTTP request/response (method, status code, header).
- You verify who a TLS certificate is for, who issued it, and how long it's valid.

## 🧠 Why this, why now
This order is deliberate: to understand TLS you need to know HTTP, and to understand
HTTP you need to know DNS. The real service you'll build in A6 will be called by a name
and will present a certificate — you'll recognize that chain from here. Most "site won't
load / certificate error" cases in production break at one of these three links; seeing
which one is the skill. Don't skip — in this order.

## 📖 How to study this
Read the body, run every command. Tools: `dig` (DNS), `curl` (HTTP), `openssl`
(TLS) — present on almost every Linux, or a single package away. You'll build your
own service in A6; for now, run the checks against an existing name (e.g. `example.com` —
the domain the IETF reserved for testing/examples, not owned by any real organization).

## 📚 Concept map
| Term | In one sentence |
|---|---|
| **DNS** | Distributed ledger that translates a name (`example.com`) into an IP |
| **Resolver** | The server that asks the DNS question on your behalf (`/etc/resolv.conf`) |
| **A / AAAA / CNAME** | Name→IPv4 / Name→IPv6 / Name→another-name records |
| **TTL** | How many seconds a DNS answer stays cached |
| **HTTP method** | The intent of the request: `GET` (read), `POST` (send), `PUT`, `DELETE` |
| **Status code** | The outcome of the response: `2xx` OK, `3xx` redirect, `4xx` you, `5xx` server |
| **TLS** | The layer that encrypts the connection and verifies the other side's identity |
| **Certificate** | A name's identity document, signed by a CA (authority) |

---

## 1️⃣ DNS: how a name becomes an IP

Machines speak in IPs (A2), humans in names. DNS is the translation between the two.
When a name is resolved, the resolver walks a chain: root → TLD (`.com`) → the domain's
authoritative server. Most of the time you get the result of that chain **from cache**.

```bash
dig example.com                 # full DNS query and answer
# ;; ANSWER SECTION:
# example.com.   3600  IN  A   192.0.2.10        ← name → IP, TTL=3600s (192.0.2.0/24: RFC 5737 example block)
dig +short example.com          # answer only
dig AAAA example.com            # IPv6 record
dig example.com @1.1.1.1        # ask a specific resolver (Cloudflare)
```

Who does your machine ask the question to? That's decided by `/etc/resolv.conf`
(or systemd-resolved):

```bash
cat /etc/resolv.conf            # nameserver <IP> lines — who am I asking
resolvectl status               # on systems using systemd-resolved
```

### Record types (what you need to know)

| Record | What it does | Example |
|---|---|---|
| `A` | Name → IPv4 | `example.com → 192.0.2.10` |
| `AAAA` | Name → IPv6 | `example.com → 2001:db8::10` |
| `CNAME` | Name → another name (alias) | `www.example.com → example.com` |
| `MX` | The domain's mail server | (email routing) |
| `TXT` | Free text (verification, SPF) | (proof of domain ownership) |

### Resolution chain: root → TLD → authoritative

Resolving a name for the first time walks a chain. `dig +trace example.com` shows
this step by step:

1. **Root servers** (`.`) — answer the question "who's responsible for `.com`?" (they give the TLD servers).
2. **TLD server** (`.com`) — answers the question "who's the authoritative server for `example.com`?"
3. **Authoritative server** — the place that hands out the actual record (`A`, `AAAA`…).

Your resolver (the server in `/etc/resolv.conf`) is the **recursive** resolver that
walks this chain on your behalf; you usually get the result from cache. When you change
a record, the answer to "why am I still getting the old answer" is **cache** + **TTL** at
one of these layers. By asking the authoritative server directly with
`dig example.com @<authoritative_ns>`, you separate whether the problem is in the actual
record or in a cache somewhere along the way.

### Why DNS is such a frequent cause of outages

```bash
dig +short example.com          # if it returns empty: no record / wrong resolver
getent hosts example.com        # how the system actually resolves it (including /etc/hosts)
```

Two traps: **(1) TTL/cache** — you changed the record but the old answer is still
cached; it doesn't propagate until the TTL expires. **(2) `/etc/hosts` shadowing** — a
line in this file takes precedence over DNS; a forgotten `/etc/hosts` entry is the
classic answer to the mystery of "why is it going to the wrong IP."

> Remember the observation from A2: "`ping IP` works, `ping name` doesn't." That's
> exactly where the problem was — DNS. Now you can prove it with `dig`.

## 2️⃣ HTTP: the anatomy of a request and a response

The name became an IP, the TCP connection was established (A2). Now the language
spoken is HTTP. An HTTP exchange consists of a **request** and a **response**; both
have headers and (often) a body.

```bash
curl -v http://example.com      # -v: shows request + response headers raw
# > GET / HTTP/1.1               ← request line: method + path + version
# > Host: example.com            ← request header
# < HTTP/1.1 200 OK              ← response line: version + status code
# < Content-Type: text/html      ← response header
curl -I https://example.com     # -I: response headers only (HEAD request)
curl -s -o /dev/null -w "%{http_code}\n" https://example.com   # status code only
```

### Methods and idempotency

The method states the request's **intent**. The ones you'll see most:

| Method | Intent | Idempotent? |
|---|---|---|
| `GET` | Read, no side effect | Yes (repeating gives same result) |
| `POST` | Create a new resource/action | **No** (repeat = second record) |
| `PUT` | Replace the resource entirely | Yes |
| `DELETE` | Delete the resource | Yes (deleted stays deleted) |

**Idempotency** — "does sending the same request twice cause harm?" — is a practical
question: when a request times out and gets retried, `GET`/`PUT`/`DELETE` are safe, while
`POST` can produce a duplicate record. This distinction matters when designing
retries/automation (C2, block E).

### Session: how a cookie is carried

HTTP is **stateless** (every request is independent). The feeling of "I'm logged in,
I'm remembered" comes from a **cookie**: the server hands out a session ID with
`Set-Cookie`, and the browser sends it back with the `Cookie` header on every subsequent
request. In a "why do I keep getting logged out" or "sessions are getting mixed up
between users" incident, these two headers are the first place to look.

### Status codes — read the class, don't memorize

| Class | Meaning | Common example |
|---|---|---|
| `2xx` | Success | `200 OK`, `201 Created` |
| `3xx` | Redirect | `301` permanent, `302` temporarily moved |
| `4xx` | **Client** error (you) | `400` bad request, `401` unauthenticated, `403` forbidden, `404` not found |
| `5xx` | **Server** error | `500` blew up internally, `502/503` backend gone/busy |

Internalize the distinction: **`4xx` is a problem in your request** (wrong path,
missing credentials), **`5xx` is a problem on the server** (the app crashed, the backend
is down). A `502 Bad Gateway` says nginx couldn't reach the app behind it — once you
connect the two yourself in A6, this code will click.

### Headers tell the story

The `Host` header says which site you're requesting (one IP can host many sites).
`Content-Type` carries the body's type, `Location` where a `3xx` redirects to, and
`Set-Cookie` the session info. In an incident, reading the headers always beats
guessing.

## 3️⃣ TLS: encryption + identity

HTTP is plain text; anyone in between can read it. HTTPS = HTTP + **TLS**. TLS does
two jobs: **(1) encryption** (so no one can eavesdrop) and **(2) authentication** (is the
other side really `example.com`?). The second happens via a **certificate**.

A certificate says: *"A trusted authority (CA) verified that this entity owns this
name (`example.com`); valid until this date."* Your browser/OS carries a list of CAs it
trusts; if the certificate is signed up to that chain, you get the green lock.

```bash
# Who the certificate belongs to, who signed it, valid until when
echo | openssl s_client -connect example.com:443 -servername example.com 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates
# subject=CN=example.com          ← who it's for
# issuer=C=US, O=DigiCert Inc...   ← who signed it (CA)
# notBefore=... notAfter=...       ← validity window

curl -v https://example.com 2>&1 | grep -E "subject:|issuer:|expire"
```

### How the handshake works — roughly

Once the TCP connection is established (A2), the TLS handshake begins:

1. **ClientHello** — the client proposes the TLS version and cipher suites it supports.
2. **ServerHello + certificate** — the server announces its choice and presents its **certificate**.
3. **Verification** — the client verifies the certificate up the trust chain (CA): is
   the signature valid, does the name match, has it expired?
4. **Key agreement** — both sides agree on a shared session key that will encrypt
   subsequent traffic. Everything after this is encrypted.

Critical point: step 3 is where the `notAfter`/name/chain checks happen — the three
certificate errors blow up exactly here. `openssl s_client -connect <host>:443
-servername <host>` runs this handshake by hand and shows the output of every step;
`-servername` (SNI) is required for the right certificate to be presented (one IP can
host many sites).

### The three most common certificate errors

| Error | What it means | Cause |
|---|---|---|
| **certificate has expired** | `notAfter` is in the past | Renewal was forgotten — a **time** error |
| **name does not match** | Name in certificate ≠ requested name | Wrong certificate being presented — a **name** error |
| **unable to get local issuer** | Signature chain can't be completed | Intermediate certificate missing — a **chain** error |

> This is what the epigraph is saying: certificate errors are often not a security
> attack, but a **time / name / chain** error. Reading which one it is from the `openssl`
> output is how you solve it without panicking. (This three-way split comes back in D3
> secret management and F2 compliance.)

## 4️⃣ Put the chain together: what happens when you enter a URL

When you type `https://example.com/health`, in order:

1. **DNS** — `example.com` resolves to an IP (`dig`).
2. **TCP** — a connection is made to that IP's port `443`, three-way handshake (A2).
3. **TLS** — the certificate is presented, verified, an encrypted channel is established.
4. **HTTP** — `GET /health HTTP/1.1` is sent, a response (`200`, body) comes back.

Each step is a separate failure point. When diagnosing, find **which step it stopped
at**; don't try to solve everything at once:

```bash
dig +short example.com                              # 1. is DNS resolving
nc -vz example.com 443                               # 2. is there TCP to the port (A2)
echo | openssl s_client -connect example.com:443 -servername example.com 2>/dev/null | head   # 3. is TLS establishing
curl -sS -o /dev/null -w "%{http_code}\n" https://example.com/health   # 4. what does HTTP say
```

These four commands split "the site won't load" into four separate, provable
questions. This is what an engineer does instead of guessing.

## 5️⃣ Diagnostic reflex — practical examples

| Symptom | Which link | First command |
|---|---|---|
| "Server not found" / name doesn't resolve | DNS | is `dig +short <name>` empty |
| Connection timeout | TCP/network (A2) | `nc -vz <name> 443` |
| "Connection not secure" / certificate warning | TLS | `openssl s_client ...` → expired/name/chain? |
| `502`/`503` page | HTTP/backend | `curl -v` → server up, backend gone |
| `404` | HTTP/application | Wrong path; see the requested path with `curl -v` |

---

## 🚫 Anti-pattern table
| Anti-pattern | Why it's bad | Right |
|---|---|---|
| Bypassing a certificate error with `-k`/`--insecure` | Turns off verification, hides the error; becomes a habit | Read the error (time/name/chain), fix the root cause |
| Assuming a DNS change "propagates instantly" | The old answer stays cached until the TTL expires | Know the TTL, plan changes with a low TTL, verify with `dig` |
| Treating `4xx` and `5xx` both as just "error" | Loses the client-vs-server distinction | `4xx` = look at the request, `5xx` = look at the server/backend |
| A forgotten `/etc/hosts` entry | Silently shadows DNS, sends you to the wrong IP | Verify the real resolution with `getent hosts <name>` |
| Sending a secret/password over HTTP | Anyone in between reads it | Always TLS; plain HTTP only for local/temporary use |
| Tracking certificate expiry by hand | Sooner or later it's forgotten, production goes down | Automatic renewal + an expiry **alert** (in E2) |
| Testing HTTPS with `ping` | `ping` is ICMP; says nothing about TLS/HTTP | Test the layer with `curl`/`openssl` |

## 📖 Further reading (not now, later)
| Source | For what | When |
|---|---|---|
| `man dig`, `man curl`, `man openssl` | Full reference for sub-commands | When you're curious about a flag |
| [`08-Security/`](../../08-Security/) folder | The security depth of TLS/PKI | **After block D** — certificate management is there |

## 🔨 Lab
👉 [`labs/build/L03-dns-http-tls/`](../labs/build/L03-dns-http-tls/) — (Task outline: resolve
a name, read the HTTP response headers, verify the certificate's expiry/owner;
deliberately break DNS and TLS and diagnose each separately.)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] You resolved a domain with `dig +short` and read its answer (IP + TTL); you showed which resolver you're asking via `/etc/resolv.conf`.
- [ ] You read an HTTP response's status code and at least two headers with `curl -v`/`curl -I`, and **wrote down** what the `2xx/3xx/4xx/5xx` class means.
- [ ] You extracted a TLS certificate's subject/issuer/validity dates with `openssl`; you **wrote down** what each of the expired/name/chain errors means.
- [ ] You ran a diagnostic sequence that splits "the site won't load" into separate questions using four commands (DNS → TCP → TLS → HTTP).

## 🧪 Test yourself
1. `dig +short shop.example.com` returns empty but `dig +short example.com` gives an IP. What do you conclude, and what are your next two checks?
2. **Scenario:** The browser says "your connection is not private." In the `openssl s_client` output, `notAfter` is yesterday's date. What's the problem, how do you verify it, what's the permanent fix?
3. **Design:** An internal service (only on the company network) needs to serve HTTPS but can't get a certificate from a public CA. How do you verify identity, and what's the tradeoff?

<details><summary>Answers</summary>

1. The `shop` subdomain has **no A/CNAME record** (or a wrong one). Checks: (a) `dig shop.example.com ANY`/`CNAME` — is there no record at all, or is it wrong; (b) `dig shop.example.com @<authoritative_ns>` — separate whether the problem is resolver cache or a genuinely missing record. Trying HTTP/TLS against a name that doesn't resolve to an IP is pointless; the chain broke at DNS.

2. **The certificate has expired** (`notAfter` is in the past) — a time error, not an attack. Verify: see `notAfter` with `openssl s_client -connect <host>:443 2>/dev/null | openssl x509 -noout -dates`. Permanent fix: renew the certificate **and** automate renewal + set up an expiry alert (E2). Manual tracking gets forgotten sooner or later.

3. Set up your own (private) CA for the internal service and sign the certificate with it, then add that CA to the trust store of the client machines/services. Tradeoff: you gain full control and independence from the internet, but you manage the CA yourself — key security, renewal, and trust distribution are your responsibility. `-k`/`--insecure` is not a solution; build the right trust instead of turning off verification.

</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| `dig` empty `ANSWER` | No record / wrong resolver / cache | `dig <name> @1.1.1.1`, `getent hosts <name>` |
| Going to the wrong IP | `/etc/hosts` is shadowing | `getent hosts <name>`; check `/etc/hosts` |
| `curl` hangs, no response | TCP/network layer (A2) | `nc -vz <name> 443`, then `ip route` |
| `curl: (60) SSL certificate problem` | expired / name / chain | determine which one with `openssl s_client ...` |
| `502 Bad Gateway` | Front end is up, backend is gone | Check the backend service (you'll connect it in A6) |
| `dig: command not found` | Package missing | `sudo apt install dnsutils` (Debian/Ubuntu) |

## 💼 Portfolio output
No direct output; used in A6's service + name + certificate setup and in block E
incident work.

## ⏭️ Up next
[`A4 — Git Fundamentals`](A4-git-temeli.md)

---

> *"A certificate error is not a security issue but, most of the time, a time/name/chain error — being able to see which one is the skill."*
