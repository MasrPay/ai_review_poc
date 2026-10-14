# CLAUDE.md — ai_review_poc

## Project
- **Purpose:** Proof of concept for an AI-assisted PR review workflow. Synthetic code only — no company code, customer data or real credentials.
- **Domain rules:** FinTech. Security and correctness outrank speed.

## Stack
- Dart package (no Flutter), tested with `package:test`.
- Money is modeled in integer minor units (`Money`), never `double`.

## Commands
```bash
dart pub get
dart format .                       # CI runs: dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
```
Run format, analyze and test before declaring a task done.

## Layout
- `lib/src/` — implementation (`money.dart`, `transfer.dart`)
- `test/` — unit tests
- `specs/` — Spec Kit feature specs (spec.md, plan.md, tasks.md)
- `.specify/memory/constitution.md` — non-negotiable engineering rules
- `.github/workflows/pr-pipeline.yml` — CI, policy, secret scan, AI review, gate
- `scripts/` — policy check, bootstrap, seeded test PRs, metrics

## Workflow
1. Every code change starts from a Spec Kit spec in `specs/`.
2. `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-analyze` → `/speckit-implement`.
3. A human approves the plan before implementation.
4. Spec, plan and tasks are committed with the PR. PR body carries `Spec: specs/<feature>/spec.md`.

## Always
- Follow `.specify/memory/constitution.md`. If a request conflicts with it, stop and say so.
- Read the relevant code before changing or judging it.
- Write or update tests for every behavior change.
- Keep changes scoped to the task.

## Never
- Read, print or commit secrets, keys, keystores or `.env` files.
- Push, merge, approve PRs or change branch protection. Humans do that.
- Disable tests, linters or checks to make something pass.
- Edit `.github/`, `.claude/`, `CLAUDE.md`, `.specify/memory/` or `scripts/` unless the task is explicitly about them.
