# Feature Specification: Remaining Daily Transfer Allowance

**Feature Branch**: `feature/remaining-allowance`

**Created**: 2026-10-14

**Status**: Draft

**Input**: User description: "Add a function that returns the remaining daily transfer allowance: daily limit minus amount sent today, never below zero, same currency rules as TransferValidator."

## Clarifications

### Session 2026-10-14

- Q: When the daily limit and the amount sent today are in different currencies, how should the function report it? → A: Return a result carrying either the allowance or `TransferDecision.currencyMismatch`.
- Q: If the amount sent today is negative, should the function reject it, treat it as zero, or use it as given? → A: Reject it as invalid input, with a distinct result in the same result type (not `currencyMismatch`).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See how much I can still send today (Priority: P1)

As a wallet user, I want to know how much more I can transfer today before hitting my daily limit, so I can plan a transfer without having it rejected.

**Why this priority**: This is the whole feature. It turns the existing pass/fail daily-limit check into a number users and other features can show or reason about.

**Independent Test**: Provide a daily limit and an amount already sent today in the same currency, and verify the returned remaining allowance equals limit minus sent.

**Acceptance Scenarios**:

1. **Given** a daily limit of 1,000.00 EGP and 300.00 EGP sent today, **When** the remaining allowance is requested, **Then** it is 700.00 EGP.
2. **Given** a daily limit of 1,000.00 EGP and nothing sent today, **When** the remaining allowance is requested, **Then** it is 1,000.00 EGP.
3. **Given** a daily limit of 1,000.00 EGP and exactly 1,000.00 EGP sent today, **When** the remaining allowance is requested, **Then** it is 0.00 EGP.

---

### User Story 2 - Never show a negative allowance (Priority: P1)

As a wallet user, I never want to see a negative remaining allowance, even if my sent total is above the limit (for example after the limit was lowered).

**Why this priority**: A negative allowance is wrong financial output and would confuse users and downstream logic.

**Independent Test**: Provide an amount sent today greater than the daily limit and verify the result is zero.

**Acceptance Scenarios**:

1. **Given** a daily limit of 1,000.00 EGP and 1,000.01 EGP sent today, **When** the remaining allowance is requested, **Then** it is 0.00 EGP.
2. **Given** a daily limit of 500.00 EGP and 2,000.00 EGP sent today, **When** the remaining allowance is requested, **Then** it is 0.00 EGP.

---

### User Story 3 - Same currency rules as transfer validation (Priority: P1)

As a compliance owner, I want the allowance to apply the same currency rules as transfer validation, so the two can never disagree about whether amounts are comparable.

**Why this priority**: Mixing currencies silently would produce a meaningless number in a regulated limit calculation.

**Independent Test**: Provide a daily limit and a sent-today amount in different currencies and verify the mismatch is reported the same way transfer validation treats a currency mismatch.

**Acceptance Scenarios**:

1. **Given** a daily limit in EGP and a sent-today amount in USD, **When** the remaining allowance is requested, **Then** no allowance amount is produced and the result is `TransferDecision.currencyMismatch`, the same outcome transfer validation gives.

---

### Edge Cases

- Sent today is exactly equal to the limit: result is zero.
- Sent today is one minor unit (piaster) below the limit: result is one minor unit.
- Sent today is one minor unit above the limit: result is zero, not negative.
- Sent today is zero: result equals the full limit.
- Daily limit is zero: result is zero.
- Sent today is negative: rejected as invalid input with its own result, distinct from `currencyMismatch`; no allowance amount is produced.
- Both a currency mismatch and a negative amount sent today: currency mismatch is reported first, matching the check order in transfer validation.
- Very large amounts: arithmetic must not overflow or lose precision.
- Result currency always equals the input currency.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a way to obtain the remaining daily transfer allowance from a daily limit and the amount already sent today.
- **FR-002**: The remaining allowance MUST equal the daily limit minus the amount sent today when the amount sent is at or below the limit.
- **FR-003**: The remaining allowance MUST be zero, never negative, when the amount sent today exceeds the daily limit.
- **FR-004**: The result MUST be expressed in the same currency as the inputs and in integer minor units; no floating-point arithmetic.
- **FR-005**: If the daily limit and the amount sent today are in different currencies, the system MUST NOT produce an allowance amount and MUST return `TransferDecision.currencyMismatch` as the result, without throwing. A successful result carries the allowance amount.
- **FR-006**: The currency rules MUST match those of transfer validation: all amounts compared must share one currency.
- **FR-007**: A negative amount sent today MUST be rejected as invalid input: no allowance amount is produced and the result is distinct from `currencyMismatch`, without throwing.
- **FR-008**: The calculation MUST be a pure function of its inputs: no stored state, no side effects, and the same inputs always give the same result.

### Key Entities

- **Daily limit**: Maximum total a user may send per day (inclusive), supplied by the caller, sourced from Compliance.
- **Amount sent today**: Total already sent in the current day, supplied by the caller.
- **Remaining allowance**: Non-negative amount that can still be sent today, in the same currency as the limit.

## Security Impact

Low. Pure calculation with no I/O, no stored data, and no sensitive data. The main risk is wrong financial output: a negative or inflated allowance could mislead users or downstream checks. Inputs must be validated per the clarified decisions above, and errors must not leak internals.

## Regulatory Impact

The daily limit is a regulatory control. This feature only reports headroom against a limit; it does not set or change limit values, which come from Compliance. Whether any Central Bank of Egypt requirement governs how remaining allowance is shown to users is not assumed here and must be confirmed with Compliance.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of tested cases, remaining allowance equals the limit minus the sent amount, floored at zero.
- **SC-002**: The allowance is never negative across all tested boundary cases: exactly at limit, one minor unit below, one minor unit above, and zero.
- **SC-003**: In 100% of tested currency-mismatch cases, no allowance amount is produced.
- **SC-004**: For any amount at or under the allowance, transfer validation does not reject it for the daily limit; for any amount above it, it does.

## Assumptions

- "Amount sent today" and the day boundary (including time zone) are determined by the caller; this feature does not compute "today".
- The daily limit is inclusive, consistent with transfer validation.
- Balance is out of scope: the allowance reflects only the daily limit, not available funds.
- Amounts use the existing integer minor-unit money model.
- Persistence, notifications, UI and limit configuration are out of scope.

## Open Questions

None. Both questions were resolved in the 2026-10-14 clarification session.
