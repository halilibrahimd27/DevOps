---
description: "Containers: image, layers, multi-stage build, and docker compose — making A6's manual deploy reproducible."
level: C
module: C1
estimated_hours: 14
prerequisites: [A6, B3]
tags: [Learning Path, Containers]
---
# C1 — Containers: Image, Layers, Multi-Stage, Compose

> *"Containers solve 'it worked on my machine' — but you need to have lived that pain in A6 first."*

**Block:** C — Reproducibility · **Duration:** ~14h · **Prerequisites:** [`A6`](../block-a-intuition/A6-elle-deploy.md), [`B3`](../block-b-visibility/B3-ilk-kirik-lab.md)

## 🎯 When you finish this module
- You containerize A6's application into an image and justify its layer and size decisions.
- You produce a small, production-ready image with a multi-stage build.
- You bring up the application + database together with `docker compose`.

## 🧠 Why this, why now
In A6 you set up the service by hand; you had to repeat the same steps on every new
machine. Containers trap that repetition inside an image. C2 (CI) will build this
image automatically, D1 (K8s) will run this image.

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`04-Containers/Dockerfile-Best-Practices.md`](../../04-Containers/Dockerfile-Best-Practices.md) | Dockerfile + layer decisions | ~30 min |
| [`04-Containers/Multi-Stage-Builds.md`](../../04-Containers/Multi-Stage-Builds.md) | small image | ~20 min |

## 🔨 Lab
👉 [`labs/build/L09-container/`](../labs/build/L09-container/)

## 💥 Broken lab
👉 [`labs/broken/K02-container-hatasi/`](../labs/broken/K02-container-hatasi/) — Symptom: "Container doesn't work /
can't connect." (Realistic cause hidden: wrong image tag / port mapping / missing
env.) Container errors are where beginners get stuck most often — that's why this one is mandatory.

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] A6's application runs as an image; `docker compose up` brings up the application + DB together
- [ ] The image got smaller with multi-stage — you can show the before/after size difference in `docker images` output
- [ ] `bash labs/broken/K02-container-hatasi/verify.sh` passes with zero errors after an unassisted fix
- [ ] You **wrote down**, in your own words, why a layer gets cached/invalidated (L09 `report.txt`)

## 🧪 Test yourself
1. What is an image layer? Why does putting dependency installation **before** copying the source code in a Dockerfile shorten build time?
2. Right after `docker run`, the container instantly shows `Exited (0)`. Without looking at the doc, what are your first three checks?
3. You need to shrink a 1.2 GB application image. With multi-stage, which base would you choose between `slim`/distroless, and under what constraint?

<details><summary>Answers</summary>

1. A layer is the read-only set of changes produced by one instruction in a Dockerfile; an image is these layers stacked on top of each other. If dependencies are installed before the source code, then when only the code changes, the dependency layer comes from cache instead of being reinstalled. Detail: [`04-Containers/Dockerfile-Best-Practices.md`](../../04-Containers/Dockerfile-Best-Practices.md).
2. (a) `docker logs <id>` — did the process exit with an error; (b) is `CMD`/`ENTRYPOINT` a long-running process or a command that finishes right away; (c) does the application stay in the foreground or does it daemonize into the background — a container shuts down once its main process ends.
3. Multi-stage pays off in every case (build tools never end up in the final image). The base depends on the constraint: if you need fast debugging/a shell, `slim`; if you want the smallest surface and least exposure, distroless — but distroless has no shell, which makes diagnosis harder. The trade-off is covered in [`04-Containers/Multi-Stage-Builds.md`](../../04-Containers/Multi-Stage-Builds.md).
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| `docker build` reinstalls dependencies every time | `COPY . .` comes before dependency installation | Copy + install just the dependency manifest first, then copy the source |
| Container closes immediately with `Exited (0)` | Main process isn't in the foreground / the command finishes | `docker logs`; verify that `CMD` is a long-running process |
| In `compose`, the application can't connect to the DB | `localhost` was used as the address | Connect to the DB by its compose **service name**; verify they're on the same network |
| Image is much bigger than expected | Single-stage; build tools are in the image | Switch to multi-stage; keep only runtime requirements in the final stage |

## 💼 Portfolio output
A containerized version of the A6 application, brought up with `compose` — showable in your repo.

## ⏭️ Up next
[`C2 — CI`](C2-ci.md)

---

> *"Once an image is built correctly, there's no more myth of the 'machine that works.'"*
