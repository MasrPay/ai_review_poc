# Feature 001: Transfer validation

> Baseline spec for the POC. Real specs are generated with `/speckit-specify`.

## User story
As a wallet user, I want transfers checked against my balance and daily limit,
so I can't overdraw or exceed regulatory limits.

## Acceptance criteria
1. Amounts of zero or below are rejected as `invalidAmount`.
2. Amounts above the balance are rejected as `insufficientBalance`.
3. The daily limit is inclusive: `sentToday + amount == dailyLimit` is allowed;
   anything above is rejected as `dailyLimitExceeded`.
4. Any currency mismatch is rejected as `currencyMismatch`.
5. All money uses integer minor units (`Money`); no floating point.

## Edge cases
- Exactly at the limit, one piaster over the limit, zero, negative.

## Security impact
None beyond correct limit enforcement.

## Regulatory impact
Daily limits are regulatory controls; values come from Compliance, not code.
