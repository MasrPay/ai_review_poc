# AI PR Review — Proof of Concept

A minimal, fail-closed pipeline that reviews every PR with deterministic checks
plus Claude, and reports a single pass/fail status. **The AI never approves,
merges, or bypasses branch rules.** A human approval is always required.

Synthetic code only (a small Dart "money and transfers" package). Public repo,
so GitHub Free enforces the branch rules.

## How a PR flows

```text
PR opened / updated  (base: main or develop)
        │
        ├── Policy Checks ── spec linked? sensitive files? story ID? (bash, no secrets)
        ├── CI ──────────── dart format / analyze --fatal-infos / test
        └── Secret Scan ─── gitleaks on the PR's commits (checksum-verified binary)
                 │
       all three passed AND same-repo AND not draft?
                 │ yes                                   │ no
                 ▼                                       │
          AI Review (Claude Code Action, read-only)      │
          - reads CLAUDE.md, constitution, spec, diff    │
          - posts inline findings on the PR              │
          - returns JSON verdict (schema-validated)      │
                 │                                       │
                 ▼                                       ▼
          AI Review Gate (deterministic, no AI, no API key) ── FAIL unless every
          check succeeded AND verdict=approve AND 0 blockers AND 0 majors
          AND spec coverage full / not applicable
                 │
                 ▼
          Ruleset on main + develop: required checks (CI, AI Review Gate)
          + 1 human approval + code-owner approval for CI/AI config
          + last-push approval + all review threads resolved → human merges
```

## What "approval" means here

| Thing | Who | Formal GitHub review state? | Blocks merge? |
|---|---|---|---|
| Inline AI comments | `github-actions[bot]` (repo token, comment-only) | No (comments only) | Only via "resolve all threads" |
| `AI Review Gate` check | GitHub Actions | No — it's a status check | Yes (required check) |
| `ai-gate:pass` label | GitHub Actions | No — informational | No |
| Human approval | Teammate / you | **Yes — APPROVE** | Yes (required) |

Workflows are explicitly **not allowed** to submit APPROVE reviews in this repo
(`can_approve_pull_request_reviews=false`), and the AI job uses only that
workflow token (no Claude GitHub App), so the setting covers it.

## Contents

| Path | Purpose |
|---|---|
| `docs/SETUP.md` | Step-by-step install and configuration, with every permission explained |
| `docs/TEST-PLAN.md` | Seeded PRs and fail-closed tests, with pass criteria |
| `docs/POC-PLAN.md` | 10-working-day plan and success criteria |
| `.github/workflows/pr-pipeline.yml` | The whole pipeline |
| `.claude/skills/pr-review/SKILL.md` | Review instructions, severity and verdict rules |
| `.specify/memory/constitution.md` | Engineering rules the review enforces |
| `.github/rulesets/protect-main-develop.json` | Branch rules (applied by bootstrap) |
| `scripts/bootstrap-repo.sh` | One-time repo hardening |
| `scripts/seed-test-prs.sh` | Opens the 10 test PRs |
| `scripts/poc-metrics.sh` | Scores results → `reports/` |
