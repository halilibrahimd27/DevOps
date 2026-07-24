---
description: "Practices that turn code review into a knowledge-sharing and quality tool: the 3 purposes of review, the nit/blocker/question category system, and a guide for reviewers and authors."
tags:
  - Git
  - Culture
  - Soft Skills
  - Cheatsheet
---
# Code Review Checklist — Good Review, Good Reviewer

> *"Slapping 'LGTM' on a PR and moving on isn't review; it's **a
> checkbox**. A checkbox doesn't catch quality — **good review** does."*

This guide is a collection of practices that turn code review from a
mechanical approval-machine into a **knowledge-sharing + quality** tool.
Two-way — for reviewer and author alike.

---

## 🎯 The 3 Purposes of Review

1. **Catching bugs** (the least important — that's the tests' job)
2. **Knowledge sharing** — feedback for juniors, spreading the codebase across the team
3. **Design friction** — "don't do it this way, use the pattern over there"

> 🔑 If your reviews only ever say "typo", you're not reviewing —
> you're **typo-proofreading**. If there's no design friction, the
> reviewer isn't engaged.

---

## 🚦 Comment Category System

Signal **how binding** a comment is with a **prefix**:

| Prefix | Meaning |
|---|---|
| **`nit:`** | Nitpick — optional improvement. OK if the author skips it. |
| **`question:`** | A question to understand. Not a blocker. |
| **`suggestion:`** | A suggestion. Think about it, do it, or reject it with a reason. |
| **`blocker:`** | You can't merge this without fixing it. |
| **`praise:`** | "This turned out great" — positive feedback matters too. |

```
nit: `count` reads better than `cnt` for the variable name

question: is this retry policy idempotent? won't it cause issues for POST?

suggestion: `fmt.Errorf("%w", err)` could be used here instead of
            `errors.Wrap`. Standard idiom since Go 1.20+.

blocker: this endpoint returns internal data without authentication;
         we can't leave it like that in real prod.

praise: this test setup is super clean, nice helper function.
```

> 🔑 **`praise`** shouldn't be forgotten — a review that only ever catches
> errors poisons the well. Making positive patterns **visible** is the
> senior's job.

---

## 👤 Checklist for Authors

Before opening a PR, **review your own code:**

### Prep
```
[ ] PR description filled in (from the template)
[ ] Linked issue/JIRA ticket
[ ] Tests added, or a note on why not
[ ] Screenshot / example output (if there's a UI/CLI change)
[ ] Breaking changes tagged with "BREAKING CHANGE:"
[ ] CI green
```

### Code
```
[ ] One concept, one PR (not 3 different things)
[ ] PR size < 400 lines (consider splitting if bigger)
[ ] Commits are meaningful (a clean single commit after squash anyway)
[ ] Comments: don't write WHAT, write WHY (or don't write it)
[ ] Magic number → constant, hardcode → config
[ ] Any new dependency? Why? CVE status?
[ ] Print/console.log debug lines cleaned up
[ ] Try/catch isn't slapped on randomly — can it actually be handled?
[ ] Logging: no PII/secrets, correct severity
[ ] Error messages useful to the user (not a stack trace)
```

### Self-review flow
```
1. Open the PR but don't assign reviewers
2. Look at your own PR in the "Files changed" tab
3. Write a comment on lines you feel need explaining
4. Notice you wrote 3+ comments — that means the code isn't enough on its own
5. Code that needs a comment to be understood = a reader lost
6. Self-review clean → assign reviewers
```

> 🔑 If you're writing 5 explanation comments on a PR, **the code needs
> to be rewritten.**

---

## 👀 Checklist for Reviewers

### First pass: 2-minute overview
```
[ ] Is the PR description clear? Do I understand why this is being done?
[ ] Is test coverage sufficient?
[ ] Does the PR size make sense? (otherwise I can say "too big")
[ ] Are the affected directories expected, or is this scope creep?
[ ] Does it touch a critical path? (auth, payment, data)
```

### Second pass: detailed review

#### 🔧 Logic
```
[ ] Are edge cases considered? (null, empty array, max int, negative)
[ ] Concurrency: race condition? lock? deadlock risk?
[ ] Error handling: does the catch block actually handle the error?
[ ] Off-by-one: <= vs <, range edges
[ ] Time zone: naive datetime or UTC?
[ ] Retry: exponential backoff? max attempts?
[ ] Idempotency: does the same request twice cause a problem?
```

#### 📐 Design
```
[ ] Does this function already exist (DRY violation)?
[ ] Single responsibility (SRP) — is the function 100+ lines?
[ ] Is the abstraction at the right level (not premature abstraction)?
[ ] Does it fit existing patterns, or is it dragging in a new one?
[ ] API design: caller-friendly, clear names?
[ ] Backward compat: is a breaking API change unversioned?
```

#### 🛡️ Security
```
[ ] Input validation (schema, max length, content-type)
[ ] SQL: parameterized, no string concatenation?
[ ] XSS: output escaped (is the template engine used correctly)?
[ ] AuthZ: is RBAC defined for the new endpoint?
[ ] Sensitive data doesn't land in logs (token, password, PII)?
[ ] No hardcoded secret/token/IP?
[ ] CORS: is the new route allow-listed?
[ ] Rate limit: did this create a brute-force vector?
[ ] Crypto: bcrypt/argon2 used (not md5/sha1)?
```

#### 🚀 Performance
```
[ ] N+1 query?
[ ] Allocation on the hot path?
[ ] New external call → timeout + retry defined?
[ ] Is cache invalidation correct?
[ ] Is the Big-O reasonable?
[ ] Lazy-load opportunity?
```

#### 🧪 Test
```
[ ] Was a test added for the new behavior?
[ ] Does the existing test still catch regressions?
[ ] Test covers happy path + edge + error?
[ ] Do test names make the behavior clear when read?
[ ] Does the mock/fake represent reality (not over-mocking)?
[ ] Is the test deterministic (time/random frozen)?
```

#### 📜 Observability
```
[ ] Was a metric added for the new feature?
[ ] Correct log severity (info/warn/error)?
[ ] Trace spans in the right places?
[ ] Is an alert needed? No alert but should there be one?
```

---

## 🎯 PR Size — Why It's Critical

| PR lines | Bug-catch rate | Review time |
|---|---|---|
| < 100 | 85% | 5 min |
| 100–400 | 70% | 15 min |
| 400–1000 | 40% | 60+ min |
| 1000+ | 15% | quick "LGTM" |

**Data:** SmartBear research (2008, still holds) — big PRs are
nominally reviewed, not actually reviewed.

### Strategies for splitting a big PR
1. **Vertical slice** — split the feature into small UI + backend + test units
2. **Stacked diffs** — small PRs chained together with Graphite
3. **Refactor first, feature after** — in a separate PR
4. **Feature flag** — half-finished code can be merged

---

## 🤖 What Can Be Delegated to Automation

Having the reviewer do these is a waste of time:

| Task | Tool |
|---|---|
| Format / lint | Prettier, ESLint, gofmt, ruff, black |
| Type check | TypeScript, mypy, sorbet |
| SAST | Semgrep, CodeQL |
| SCA | Trivy, OSV-Scanner |
| Secret scan | gitleaks, trufflehog |
| PR title format | semantic-pr-action |
| PR template filling | `.github/PULL_REQUEST_TEMPLATE.md` |
| Coverage threshold | Codecov, custom CI step |
| Bundle size | size-limit, bundlewatch |

> 🔑 A human reviewer spends their time on **logic + design + knowledge
> sharing**. Reviewing to fix formatting = wasting an engineer's salary.

---

## ⏱️ Response Time Targets

| PR state | Target |
|---|---|
| PR opened → first review | **< 4 hours** (work hours) |
| Review given → author responds | < 1 business day |
| Response given → re-review | < 4 hours |
| Total PR → merge | P50 < 1 day, P95 < 3 days |

Consistent with trunk-based development. Slow review = slow shipping.

> ⚠️ Once the "review queue" hits 10+ PRs, team flow clogs up. Check it in standup.

---

## 🧠 Communication Tone

### ✅ Good
- "I'm a bit confused here, why are we doing it this way?"
- "This approach looks good — did you also consider X as an alternative?"
- "This test is really nice, thanks for doing this 👏"
- "I see a potential race condition here: A, B... could you think it through?"

### ❌ Bad
- "This is wrong." (no reasoning)
- "I've always done it this way." (appeal to authority)
- "Why did you write it like this??" (aggressive)
- "..." (silent rejection)

### Rules for the reviewer
1. **Criticize the code, not the person.**
2. **"The code" instead of "you"**: "you're not handling X" → "X is not handled here"
3. **Justify the "why":** "This shouldn't be done because <X scenario>"
4. **Prefer asking questions:** "Was this intentional?" > "This is wrong"
5. **Be a teacher for juniors, a partner for seniors.**

### Rules for the author
1. **Don't get defensive.** The reviewer is a partner, not a "bad detective."
2. **Ask directly:** "Could you re-explain what I'm not getting?"
3. **You can reject a suggestion** but justify it: "I'm not taking this suggestion because of X."
4. **If the discussion drags on, hop on video chat:** 3+ comments = talk for 5 min.

---

## 🛠️ CODEOWNERS — Auto-Assign the Right Reviewer

```
# .github/CODEOWNERS

# Default
*                       @platform-team

# Specific paths
/api/                   @backend-team
/web/                   @frontend-team
/infra/                 @platform-team
/docs/                  @docs-team

# Critical = extra reviewer
/api/auth/              @backend-team @security-team
/api/payments/          @backend-team @payments-team @security-team

# Specific files
*.tf                    @platform-team
Dockerfile              @platform-team @security-team
.github/workflows/      @platform-team
```

With **`Require code owner reviews`** enabled in branch protection:
- A PR touching a path gets auto-assigned to that team
- Extra eyes on critical areas are guaranteed

---

## 📝 PR Description Template

```markdown
## Why?
<what's the problem, why are we solving it, what metric/feedback prompted it>

## What?
<summary: what was done, which approach was chosen>

## Alternative approaches (if considered)
- A: <brief>
- B: <brief>
- Chosen: <reasoning>

## Test
- [ ] Unit test added
- [ ] Integration test updated
- [ ] Manual test: <steps>

## Risk
<what this could break on deploy, how to roll back>

## Screenshots (if UI)
<…>

## Linked issues
Closes #123
```

> 🔑 If the answer to "Why?" doesn't get written into the PR, whoever
> runs `git blame` 6 months from now has lost the "why we did it this way."

---

## 🧪 Pair / Mob Programming as an Alternative

Code review = asynchronous pair programming. Sometimes real-time is better:

| Scenario | Preference |
|---|---|
| Junior is learning | Pair (sync) |
| Complex design decision | Mob (3-4 people, sync) |
| Small bug fix | PR (async) |
| Large refactor | PR + tech design doc first |
| Time-sensitive prod fix | Pair → 1 reviewer approval |

---

## 🚫 Anti-Pattern Table

| Anti-pattern | Why it's bad | Correct |
|---|---|---|
| Just "LGTM" | No review happened, just a label | Substantive comment, at least 1 |
| Senior always reviews 4 hours later | Bottleneck | Round-robin, CODEOWNERS |
| 1500-line PR | Not actually read | < 400 lines, split it |
| Reviewer fights with formatting | Waste of human time | Pre-commit + CI lint |
| No "why like this?" question, always "LGTM" | No knowledge sharing | A culture of asking questions |
| Comment is aggressive | Toxic culture, everyone gets defensive | "Code, not person" |
| 4 reviewers assigned to the author | Diffusion of responsibility | 1 + CODEOWNERS spot |
| No `nit:` prefix | Author thinks everything is a blocker | Prefix system |
| Re-review 2 days later | Trunk-based becomes impossible | < 4 hour target |
| Author doesn't notify the reviewer of a change | Reviewer reads a stale state | "Re-review please, comments addressed" |

---

## 📋 Review Culture Health Check

```
[ ] Average PR < 400 lines
[ ] PR → first review P50 < 4 hours
[ ] PR → merge P50 < 1 day
[ ] Review comments: 30%+ "question/suggestion" (not just "blocker")
[ ] Praise / positive comments are visible
[ ] CODEOWNERS up to date + extra reviewer on critical paths
[ ] Reviewer rotation (no single person is a bottleneck)
[ ] Automation: lint, format, SAST, SCA — no human commenting on these
[ ] PR template used, "Why?" filled in
[ ] Linked issue/ticket
[ ] Quarterly: review the review metrics (lead time, comment volume)
[ ] Juniors get teaching-oriented reviews (link, doc, example)
```

---

## 📚 References

- **Google Engineering Practices** — google.github.io/eng-practices/review
- **Conventional Comments** — conventionalcomments.org
- **What to look for in a code review** — Trisha Gee
- **The Pull Request Review Process** — Jessica Joy Kerr
- [`Trunk-Based-Development.md`](Trunk-Based-Development.md)
- [`Conventional-Commits.md`](Conventional-Commits.md)
- [`PR-Templates-and-Automation.md`](PR-Templates-and-Automation.md)

---

> *"The quality of review is the barometer of team culture. A team where
> PRs pass by 'LGTM stamping' is the **6-months-ago** version of the team
> that says 'nobody caught this' in a postmortem 6 months from now."*
