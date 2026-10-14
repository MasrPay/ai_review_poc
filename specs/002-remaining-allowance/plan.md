# Implementation Plan: Remaining Daily Transfer Allowance

**Branch**: `feature/remaining-allowance` | **Date**: 2026-10-14 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-remaining-allowance/spec.md`

## Summary

Add `TransferValidator.remainingAllowance({required Money sentToday})`. It returns a sealed `AllowanceResult`: either `AllowanceAvailable(remaining)` with `max(dailyLimit - sentToday, 0)`, or `AllowanceRejected(reason)` for a currency mismatch or a negative `sentToday`. It is a pure function in integer minor units that reuses the validator's `dailyLimit` and the same currency check order.

## Technical Context

**Language/Version**: Dart ^3.5.0 (sealed classes and pattern matching available)

**Primary Dependencies**: None new

**Storage**: N/A (pure calculation)

**Testing**: `package:test`

**Target Platform**: Dart package (no Flutter)

**Project Type**: Library

**Performance Goals**: N/A (constant-time arithmetic)

**Constraints**: Integer minor units only; no throwing for expected rejections; no I/O or state

**Scale/Scope**: One method, one small result type, one test file

## Constitution Check

| Principle | Status | Notes |
|---|---|---|
| I. Security first | Pass | No secrets, PCI data or I/O. Rejections carry only an enum reason, so nothing is leaked. |
| I. Regulatory impact section | Pass | Present in the spec. The limit value still comes from Compliance. |
| II. Money in integer minor units | Pass | Uses `Money` throughout. No `double`. |
| II. Idempotent, pure | Pass | Pure function of its inputs (FR-008). |
| II. Currency explicit | Pass | Mismatch returns `currencyMismatch`. The day boundary and time zone belong to the caller (see spec Assumptions). |
| III. Testing | Pass | Tests cover exactly-at-limit, one minor unit above and below, zero, negative, mismatch and overflow-sized values. |
| IV. Simplicity | Pass | No new dependency, no new layer. The method sits next to the existing limit and currency check. |
| V. Failure handling | Pass | Expected failures are values, not exceptions. There are no silent catches. |
| VI. Specs and process | Pass | Ambiguities were resolved through `/speckit-clarify`. |

No violations. No Complexity Tracking needed. Post-design re-check: still passes.

## Project Structure

### Documentation (this feature)

```text
specs/002-remaining-allowance/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── remaining-allowance.md
├── checklists/requirements.md
└── tasks.md             # created by /speckit-tasks
```

### Source Code (repository root)

```text
lib/src/transfer.dart          # add remainingAllowance + AllowanceResult types
test/remaining_allowance_test.dart   # new
```

**Structure Decision**: Keep it in `lib/src/transfer.dart`, which is already exported from `lib/ai_review_poc.dart`, so no new export is needed.

## Points for human review

- **Negative `sentToday` reason**: the plan reuses `TransferDecision.invalidAmount` rather than adding a new enum value. This is distinct from `currencyMismatch` as the spec requires. The alternative is a new `invalidSentToday` value, which would widen the enum that `validate()` consumers see. See research.md.
- **Check order**: a currency mismatch takes precedence over a negative `sentToday`, matching `validate()`.
