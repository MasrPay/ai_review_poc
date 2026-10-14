# Setup guide (macOS)

Nothing is assumed to be installed. Every step has a check. Replace
`<ORG>` with your GitHub organization. Never paste keys into chat, files or
command arguments — only into the interactive prompts shown below.

---

## Step 1 — Local tools (≈30 min)

```bash
# 1.1 Git (Xcode Command Line Tools)
xcode-select --install            # skip if already installed
git --version

# 1.2 Homebrew (skip if `brew --version` works) — official installer from https://brew.sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 1.3 GitHub CLI, jq, uv (for Spec Kit)
brew install gh jq uv
gh --version && jq --version && uv --version

# 1.4 Dart SDK (CI language for the POC repo)
brew tap dart-lang/dart
brew install dart
dart --version

# 1.5 Claude Code (you have it; verify and update)
claude --version
claude doctor
claude update
# If missing: curl -fsSL https://claude.ai/install.sh | bash

# 1.6 Spec Kit CLI (official package), then pin the version you got
uv tool install specify-cli
specify version
# Pin for reproducibility, using the version printed above:
# uv tool install --force specify-cli==<VERSION>
```

**GitHub CLI login** (browser flow, no token pasting):

```bash
gh auth login                 # GitHub.com → HTTPS → login with browser
gh auth refresh -s workflow   # needed to push files under .github/workflows
gh auth status
```

## Step 2 — Claude token from your own subscription (≈5 min)

For the POC, CI runs on **your** Claude Team seat, so there's no separate API
billing. On your Mac:

```bash
claude setup-token
```

It opens the browser, you sign in with your Claude account, and it prints a
long-lived token. Keep it in your password manager until Step 4. Never paste it
into chat, files or command arguments.

What this means:
- AI reviews count against **your** usage limits, the same pool you use in
  Claude and Claude Code. If you hit a limit, the AI job fails and the gate
  **fails closed** (nothing slips through; just re-run later).
- The token is tied to you personally. Fine for a one-person POC; for team
  rollout switch to an API key on a company Console workspace (one-line change
  in the workflow, already noted there).
- If the token is ever exposed: delete the GitHub secret and run
  `claude setup-token` again to issue a new one.

## Step 3 — Create the repo and baseline (≈20 min)

```bash
gh repo create <ORG>/ai_review_poc --public \
  --description "AI PR review POC (synthetic code only)" --clone
cd ai_review_poc

# 3.1 Spec Kit FIRST (it writes .claude/skills and .specify/)
specify init --here --integration claude
ls .claude/skills .specify

# 3.2 Unzip this kit on top (our constitution, CLAUDE.md and skill win)
unzip -o ~/Downloads/ai_review_poc_kit.zip -d .

# 3.3 Dart dependencies and a clean baseline
dart pub add --dev lints test
dart format .
dart analyze --fatal-infos
dart test

# 3.4 First commit
git add -A
git commit -m "chore: POC baseline"
git push -u origin main
```

Check that `.specify/memory/constitution.md` is **ours** (it starts with
"Engineering Constitution"). If `specify init` replaced it, re-run 3.2.

## Step 4 — Harden the repo (≈10 min)

```bash
scripts/bootstrap-repo.sh <ORG>/ai_review_poc
```

It prompts once for the Claude token (hidden input). What it changes:

| Setting | Value | Why |
|---|---|---|
| CODEOWNERS | `@TEAM_LEAD` → your username (committed to main) | You own CI, AI config and scripts |
| Allowed actions | GitHub-owned + `anthropics/claude-code-action` + `dart-lang/setup-dart` | No other third-party code can run |
| Default `GITHUB_TOKEN` | read-only | Jobs must request write explicitly |
| Workflows may approve PRs | **off** | AI/automation can never create an APPROVE review |
| Fork PR workflows | need approval for external contributors | Strangers can't spend your minutes or probe the pipeline |
| Auto-merge | off; delete branch on merge | Humans merge, deliberately |
| Secret scanning + push protection | on (free for public repos) | Second layer behind gitleaks |
| Labels | `ai-gate:pass/fail`, `seed:expect-pass/block` | Reporting |
| Secret `CLAUDE_CODE_OAUTH_TOKEN` | set | Only the AI job reads it; forks never get it |
| Branch `develop` | created from main | Second protected branch |
| Ruleset `protect-main-develop` | see below | Enforced merge rules |

**Ruleset** (`.github/rulesets/protect-main-develop.json`), no bypass actors, so
even admins follow it:

| Rule | Effect |
|---|---|
| deletion, non_fast_forward | No branch deletion, no force-push |
| pull_request: 1 approval | Every merge needs a human APPROVE |
| dismiss_stale_reviews_on_push | New commits void earlier approvals |
| require_code_owner_review | Changes to `.github/`, `.claude/`, `CLAUDE.md`, `.specify/memory/`, `scripts/` need **your** approval |
| require_last_push_approval | Whoever pushed last can't be the approver |
| required_review_thread_resolution | Every AI (and human) comment must be resolved |
| required_status_checks: `CI`, `AI Review Gate` (strict, from the GitHub Actions app only) | Both must pass on an up-to-date branch |

> With code-owner + last-push rules, someone other than the pusher must approve.
> Add one teammate as a collaborator with **Write** access for the POC:
> `gh api -X PUT repos/<ORG>/ai_review_poc/collaborators/<THEIR_USERNAME> -f permission=push`

## Step 5 — No Claude GitHub App needed (deliberate)

The AI job passes the repo's own short-lived `GITHUB_TOKEN` to the action
(`github_token: ${{ github.token }}`), so comments appear as
`github-actions[bot]`. This is a least-privilege choice:

- The official Claude GitHub App can only be installed with its **full**
  permission set (Contents, Pull requests, Issues, Actions, Workflows… write),
  and the repo setting that forbids approvals does **not** apply to app tokens.
- `GITHUB_TOKEN` here has only `contents: read` + `pull-requests: write`, and the
  repo forbids it from approving. So the AI can comment, but cannot approve,
  push or merge.

Don't run `/install-github-app` for this repo. If inline comments ever fail to
post on Day 3, check the AI Review log first; installing the app is the
fallback, at the cost of the guarantee above.

## Step 6 — Verify the protection (≈10 min)

```bash
# Direct push to main must be rejected
git commit --allow-empty -m "test: direct push" && git push origin main   # expect: rejected
git reset --hard HEAD~1

# Ruleset is active
gh api repos/<ORG>/ai_review_poc/rulesets --jq '.[] | {name, enforcement}'

# Actions settings
gh api repos/<ORG>/ai_review_poc/actions/permissions/workflow
```

## Step 7 — First real PR with Spec Kit (≈30 min)

```bash
git fetch origin
git checkout -b feature/first-spec origin/develop
claude
```

Inside Claude Code:

```text
/speckit-specify Add a function that returns the remaining daily transfer allowance (daily limit minus sent today, never below zero).
/speckit-clarify
/speckit-plan
/speckit-tasks
/speckit-analyze
/speckit-implement
```

Then check where Spec Kit wrote the spec (`git status`). If it is **not**
`specs/<something>/spec.md`, update `SPEC_PATTERN` in
`scripts/policy-check.sh` (that change needs your code-owner approval, which is
the point).

```bash
dart format . && dart analyze --fatal-infos && dart test
git add -A && git commit -m "feat: remaining daily allowance" && git push -u origin HEAD
gh pr create --base develop --fill
gh pr checks --watch
```

Open the PR on GitHub: you should see the inline AI comments, the five jobs,
and the gate summary under **Checks → PR Pipeline → AI Review Gate → Summary**.

## Step 8 — Seed the test PRs

```bash
git checkout main && git pull
scripts/seed-test-prs.sh <ORG>/ai_review_poc t01 t02 t03 t04 t05
scripts/seed-test-prs.sh <ORG>/ai_review_poc t06 t07 t08 t09 t10
scripts/poc-metrics.sh  <ORG>/ai_review_poc
```

## Optional — Microsoft Teams and CodeArts (Day 9)

**Teams channel notification** (no app registration needed):
1. In the Teams channel → **Workflows** → template *"Post to a channel when a
   webhook request is received"* → copy the URL.
2. `gh secret set TEAMS_WEBHOOK_URL --repo <ORG>/ai_review_poc` (paste at the prompt).

The gate then posts PASS/FAIL with a link. Unset = silently skipped.

**CodeArts story IDs**: require an ID in every PR title, for traceability:

```bash
gh variable set STORY_ID_REGEX --repo <ORG>/ai_review_poc --body '\[[A-Z]+-[A-Z0-9]+\]'
```

Adjust the regex once you confirm your CodeArts ID format. Unset = check skipped.
Two-way CodeArts sync (pulling stories via its API) is out of POC scope.

## Permissions: per job

| Job | Token permissions | Secrets | Why |
|---|---|---|---|
| Policy Checks | `contents: read` | none | read the diff |
| CI | `contents: read` | none | build and test |
| Secret Scan | `contents: read` | none | scan commits |
| AI Review | `contents: read`, `pull-requests: write`, `issues: read` | `CLAUDE_CODE_OAUTH_TOKEN` | read the code; post inline comments. Can't approve (repo setting), push or merge (no `contents: write`) |
| AI Review Gate | `pull-requests: write` | `TEAMS_WEBHOOK_URL` (optional) | set the `ai-gate:*` label only |

The workflow starts from `permissions: {}`, so any permission not listed is denied.
All third-party actions are pinned to full commit SHAs.

## Costs

- **GitHub Actions**: standard runners are free for public repos.
- **Claude**: during the POC, runs use your subscription (no per-token bill).
  Usage controls: Sonnet model, `--max-turns 30`, 20-minute timeout, AI
  skipped when cheap checks fail, in-flight runs cancelled when a PR gets a new
  push. If a usage limit is reached, the gate **fails closed**.

## Known limits (be explicit with your team)

1. `pull_request` workflows run the **PR's own copy** of the workflow, so a PR
   can edit the gate (test T08). The real control is the ruleset:
   code-owner review on `.github/` plus a human approval.
2. The required checks are pinned to the GitHub Actions app
   (`"integration_id": 15368` in the ruleset), so nobody can satisfy them by
   posting a fake status with the same name. Verify on Day 3 from a real run:
   `gh api repos/<ORG>/ai_review_poc/commits/<SHA>/check-runs --jq '.check_runs[] | {name, app_id: .app.id, app: .app.slug}'`.
   If the ID differs, the checks will never turn green and merges stay blocked
   (fails safe). Fix the ID in the JSON and re-run bootstrap.
3. AI output is probabilistic. The gate only trusts a schema-validated verdict
   plus deterministic checks, and humans still approve.
4. Public repo: logs and AI comments are public. Synthetic code only.
5. Moving to private repos requires GitHub **Team** (rulesets aren't enforced
   on private repos with GitHub Free).
