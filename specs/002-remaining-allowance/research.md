# Research: Remaining Daily Transfer Allowance

No NEEDS CLARIFICATION items remained after `/speckit-clarify`. Design decisions follow.

## 1. Where the function lives
- **Decision**: An instance method on `TransferValidator`.
- **Rationale**: It already owns `dailyLimit` and the currency rules. The allowance and `validate()` then share one source of truth, which supports SC-004.
- **Alternatives**: A top-level function taking `dailyLimit` as a parameter (a second place to get the limit wrong); a new `AllowanceCalculator` class (speculative abstraction, rejected by Constitution IV).

## 2. Result shape
- **Decision**: `sealed class AllowanceResult` with `AllowanceAvailable(Money remaining)` and `AllowanceRejected(TransferDecision reason)`.
- **Rationale**: The clarified answer requires "an allowance or `currencyMismatch`". A sealed class makes callers handle both cases and prevents reading an amount from a rejection.
- **Alternatives**: Nullable `Money` (loses the reason); throwing `ArgumentError` (rejected in clarification).

## 3. Reason for negative `sentToday`
- **Decision**: Reuse `TransferDecision.invalidAmount`.
- **Rationale**: It already means "an amount input is invalid", it is distinct from `currencyMismatch`, and it avoids widening a public enum.
- **Alternative**: Add `invalidSentToday`. More precise, but a public enum change. Flagged for the plan reviewer.

## 4. Clamping and overflow
- **Decision**: If `sentToday >= dailyLimit`, return `Money.zero(currency)`. Otherwise return `dailyLimit - sentToday`. Compare before subtracting.
- **Rationale**: Subtraction happens only when it is non-negative and bounded by `dailyLimit`. Dart ints are 64-bit on the VM, and a negative `sentToday` is rejected before subtraction, so there is no overflow path.
- **Alternatives**: `max(0, limit - sent)`, which can overflow for extreme inputs.

## 5. Check order
- **Decision**: Currency first, then negative `sentToday`, then the calculation.
- **Rationale**: Matches `validate()`, so both report the same first problem.
