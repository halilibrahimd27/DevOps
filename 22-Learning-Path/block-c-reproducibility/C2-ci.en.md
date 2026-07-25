---
description: "CI: test → build → artifact → registry — running the same steps automatically and verifiably on every commit."
level: C
module: C2
estimated_hours: 16
prerequisites: [A4, C0, C1]
tags: [Learning Path, CI-CD]
---
# C2 — CI: Test → Build → Artifact → Registry

> *"CI is a machine doing — and proving — on every commit what you used to do by hand each time."*

**Block:** C — Reproducibility · **Duration:** ~16h · **Prerequisites:** [`A4`](../block-a-intuition/A4-git-temeli.md), [`C0`](C0-ops-python.md), [`C1`](C1-container.md)

## 🎯 When you finish this module
- You set up a pipeline that automatically runs the test → build → image → registry steps on a commit.
- You publish the build output (artifact/image) to a registry, versioned.
- You read and fix which step a pipeline failure broke at, and why.

## 🧠 Why this, why now
In C1 you produced the image by hand; doing that by hand on every change doesn't
scale. CI ties these steps to every commit. D4 (supply chain: scanning + signing)
**is a continuation of this pipeline**, not a separate lesson.

> 📦 **Registry** = image storage: the place where you publish and keep, with version
> tags, the container images you built in C1 (e.g. GitHub Container Registry / GHCR,
> AWS ECR, Docker Hub). CI's last step *pushes* the image here; K8s (Block D) later
> *pulls* it from here.

## 📖 Read first
| Source | For what | Duration |
|---|---|---|
| [`02-CI-CD/Pipeline-Patterns.md`](../../02-CI-CD/Pipeline-Patterns.md) | pipeline anatomy | ~30 min |
| [`02-CI-CD/GitHub-Actions-Recipes.md`](../../02-CI-CD/GitHub-Actions-Recipes.md) | working examples | ~30 min |

## 🔨 Lab
👉 [`labs/build/L10-ci/`](../labs/build/L10-ci/README.md)

## ✅ Acceptance criteria
Don't move to the next module until all of these are verified:
- [ ] The commit → test → build → registry flow passes green — the pipeline log can be shown
- [ ] The image is published to the registry with a version tag (not `:latest`; e.g. commit SHA / semver — `MAJOR.MINOR.PATCH`, e.g. `1.4.2`)
- [ ] You can read from the log which stage a broken step failed at and why, and fix it — a written diagnosis note
- [ ] You can answer, in writing, for your own pipeline, the question "the pipeline's green, but what did it verify?"

## 🧪 Test yourself
1. A test passes locally but fails in the pipeline. What are the two most common reasons for this?
2. Why is the `:latest` tag banned in production? What's a solid way to version an image?
3. Your pipeline takes 8 minutes and it's slowing the team down. What would your first optimization be, and why?

<details><summary>Answers</summary>

1. (a) Environment difference — a different dependency version, a different env variable, or an installed tool locally; (b) hidden local state — a file/credential present locally that isn't in CI's clean environment. Fix: pin versions with a lock file, log the env CI is using.
2. `:latest` is a mutable reference: the same tag can point to a different image today than tomorrow → you can't tell which version is running, and you can't roll back. Use an immutable identity: commit SHA or semver. Details in [`02-CI-CD/Pipeline-Patterns.md`](../../02-CI-CD/Pipeline-Patterns.md).
3. Cache. Dependency and Docker layer caching is the step doing the most repeated work in most pipelines; parallelizing independent jobs is the second step. "Measure first, then optimize" — see from the log which step is taking long.
</details>

## 🆘 If you're stuck
| Symptom | Likely cause | What to do |
|---|---|---|
| A test that passes locally fails in CI | Environment difference (dependency version, env) | Lock versions; log CI's env; reproduce in a clean environment |
| `docker push` is rejected | Registry authentication missing/wrong | Provide the registry credential as a secret; verify the login step |
| Pipeline builds from scratch on every commit | No cache | Add dependency/layer caching (`02-CI-CD/Caching-Strategies.md`) |
| Build is green but the image doesn't work | Pipeline never actually runs the image | Add a "smoke test" step: bring the container up, run a health check |

## 💼 Portfolio output
A green CI pipeline and versioned images in the registry — a concrete line on your CV.

## ⏭️ Up next
[`C3 — Terraform`](C3-terraform.md)

---

> *"If the pipeline's green you trust it; but if you don't know what it verified, green is just a color."*
