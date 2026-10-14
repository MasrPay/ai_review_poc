---

description: "Task list for Remaining Daily Transfer Allowance"
---

# Tasks: Remaining Daily Transfer Allowance

**Input**: Design documents from `/specs/002-remaining-allowance/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/remaining-allowance.md

**Tests**: Required. Constitution III and CLAUDE.md demand tests for every behavior change, so test tasks come before implementation tasks in each story.

**Organization**: Grouped by user story. All three stories extend one method in one file, so the stories are implemented in order and there is almost no parallelism.

## Format: `[ID] [P?] [Story] Description`

## Path Conventions

- Source: `lib/src/transfer.dart` (exported via `lib/ai_review_poc.dart`)
- Tests: `test/remaining_allowance_test.dart` (new)

## Phase 1: Setup

- [X] T001 Confirm a clean baseline: run `dart pub get`, `dart analyze --fatal-infos` and `dart test` from the repo root and record that all pass before any change.

## Phase 2: Foundational

- [X] T002 Create `test/remaining_allowance_test.dart` with the imports used by `test/transfer_test.dart` (`package:ai_review_poc/ai_review_poc.dart`, `package:test/test.dart`), a `const TransferValidator(dailyLimit: Money.major(1000, 'EGP'))` fixture and a `main()` containing one group, `remainingAllowance`. No test cases yet.

## Phase 3: User Story 1 - See how much I can still send today (P1) 🎯 MVP

**Goal**: Return limit minus sent for same-currency, non-negative inputs at or below the limit.

**Independent Test**: Limit 1,000.00 EGP and 300.00 sent returns `AllowanceAvailable` with 700.00 EGP.

- [X] T003 [US1] In `test/remaining_allowance_test.dart` add tests: sent 300.00 → `AllowanceAvailable(Money.major(700, 'EGP'))`; sent zero → full limit; sent exactly the limit → 0.00 EGP; sent 1 minor unit below the limit → 1 minor unit. Run `dart test test/remaining_allowance_test.dart` and confirm it fails (the symbols don't exist yet).
- [X] T004 [US1] In `lib/src/transfer.dart` add `sealed class AllowanceResult`, `final class AllowanceAvailable extends AllowanceResult` (field `final Money remaining`, `==`/`hashCode`/`toString` so tests can compare) and `final class AllowanceRejected extends AllowanceResult` (field `final TransferDecision reason`, same members), per `contracts/remaining-allowance.md`. Add the doc comment `Spec: specs/002-remaining-allowance/spec.md`.
- [X] T005 [US1] In `lib/src/transfer.dart` add `AllowanceResult remainingAllowance({required Money sentToday})` to `TransferValidator`. For this story: return `AllowanceAvailable(dailyLimit - sentToday)`. Integer minor units only, no `double`.
- [X] T006 [US1] Run `dart test test/remaining_allowance_test.dart` and confirm the T003 tests pass.

**Checkpoint**: Basic allowance works.

## Phase 4: User Story 2 - Never show a negative allowance (P1)

**Goal**: Zero, never negative, when sent exceeds the limit.

**Independent Test**: Limit 1,000.00 EGP and 1,000.01 sent returns 0.00 EGP.

- [X] T007 [US2] In `test/remaining_allowance_test.dart` add tests: sent 1 minor unit above the limit → `Money.zero('EGP')`; sent 2,000.00 against a 500.00 limit → zero; a validator with a zero limit and zero sent → zero; very large sent (e.g. `Money(9007199254740991, 'EGP')`) → zero. Confirm the above-limit tests fail.
- [X] T008 [US2] In `lib/src/transfer.dart` change `remainingAllowance`: if `sentToday >= dailyLimit` return `AllowanceAvailable(Money.zero(dailyLimit.currency))`, otherwise `AllowanceAvailable(dailyLimit - sentToday)`. Compare before subtracting; do not use `max(0, limit - sent)` (research.md decision 4).
- [X] T009 [US2] Run `dart test test/remaining_allowance_test.dart` and confirm all US1 and US2 tests pass.

## Phase 5: User Story 3 - Same currency rules as transfer validation (P1)

**Goal**: Mismatch returns `currencyMismatch`. A negative sent amount is rejected as `invalidAmount`. Neither throws.

**Independent Test**: EGP limit with USD sent returns `AllowanceRejected(TransferDecision.currencyMismatch)`.

- [X] T010 [US3] In `test/remaining_allowance_test.dart` add tests: EGP limit with USD sent → `AllowanceRejected(TransferDecision.currencyMismatch)` and does not throw; `Money(-1, 'EGP')` sent → `AllowanceRejected(TransferDecision.invalidAmount)`; negative USD sent (both problems) → `currencyMismatch` first; the rejection reason for a negative amount is not `currencyMismatch`. Confirm they fail.
- [X] T011 [US3] In `lib/src/transfer.dart` add to the start of `remainingAllowance`: if `sentToday.currency != dailyLimit.currency` return `AllowanceRejected(TransferDecision.currencyMismatch)`; then if `sentToday.isNegative` return `AllowanceRejected(TransferDecision.invalidAmount)`. Currency check first, matching `validate()`.
- [X] T012 [US3] In `test/remaining_allowance_test.dart` add a consistency test for SC-004: for several `sentToday` values (0, 300.00, exactly the limit, above the limit) with a large balance, a transfer of exactly the remaining amount is not `dailyLimitExceeded` from `validate()` (skip the zero-remaining case, where `validate()` returns `invalidAmount`), and a transfer one minor unit larger is `dailyLimitExceeded`.
- [X] T013 [US3] Run `dart test test/remaining_allowance_test.dart` and confirm all tests pass.

## Phase 6: Polish and Cross-Cutting

- [X] T014 Run `dart format .`, `dart analyze --fatal-infos` and `dart test`, and fix any findings in the files touched by this feature without disabling any check.
- [X] T015 Walk through `specs/002-remaining-allowance/quickstart.md` scenarios 1 to 5 and confirm each is covered by a test; add any missing case to `test/remaining_allowance_test.dart`.
- [X] T016 Confirm the PR body will carry `Spec: specs/002-remaining-allowance/spec.md` and that spec, plan and tasks are committed with the code. Do not push or merge.

## Dependencies and Execution Order

- Phase 1 → Phase 2 → US1 → US2 → US3 → Polish.
- US2 and US3 edit the same method that US1 creates, so they run in order, not in parallel.
- Within each story: test task (red) → implementation task → run (green).

## Parallel Opportunities

Essentially none: every code task edits `lib/src/transfer.dart` or `test/remaining_allowance_test.dart`. T001 could run alongside reading the design docs, which is trivial.

## Implementation Strategy

- **MVP**: Phases 1 to 3 (US1). Note that this is not safe to ship alone, because a result above the limit would be negative until US2 lands. Treat US1 and US2 as the minimum releasable unit.
- Deliver incrementally, with the test run after each story.
