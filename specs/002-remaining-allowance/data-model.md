# Data Model: Remaining Daily Transfer Allowance

No persisted data. All values are supplied by the caller.

| Type | Kind | Fields / values | Notes |
|---|---|---|---|
| `Money` | existing | `minorUnits: int`, `currency: String` | Reused as is. |
| `TransferValidator` | existing | `dailyLimit: Money` | Gains `remainingAllowance`. |
| `TransferDecision` | existing | unchanged | Only `currencyMismatch` and `invalidAmount` are used as rejection reasons here. |
| `AllowanceResult` | new, sealed | none | Base type for the two cases below. |
| `AllowanceAvailable` | new | `remaining: Money` | Always non-negative. Same currency as the limit. |
| `AllowanceRejected` | new | `reason: TransferDecision` | One of `currencyMismatch`, `invalidAmount`. |

## Rules
- `sentToday.currency != dailyLimit.currency` → `AllowanceRejected(currencyMismatch)`.
- `sentToday.isNegative` → `AllowanceRejected(invalidAmount)`.
- `sentToday >= dailyLimit` → `AllowanceAvailable(Money.zero(currency))`.
- Otherwise → `AllowanceAvailable(dailyLimit - sentToday)`.
