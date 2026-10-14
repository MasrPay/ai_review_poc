# Contract: remainingAllowance

Public API of this library (exported through `package:ai_review_poc/ai_review_poc.dart`).

```dart
AllowanceResult TransferValidator.remainingAllowance({required Money sentToday});

sealed class AllowanceResult {}
final class AllowanceAvailable extends AllowanceResult { final Money remaining; }
final class AllowanceRejected extends AllowanceResult { final TransferDecision reason; }
```

| Input | Output |
|---|---|
| Same currency, `0 <= sentToday <= limit` | `AllowanceAvailable(limit - sentToday)` |
| Same currency, `sentToday > limit` | `AllowanceAvailable(0)` |
| Currency differs | `AllowanceRejected(currencyMismatch)` |
| `sentToday < 0` (same currency) | `AllowanceRejected(invalidAmount)` |

Guarantees: never throws for the cases above, never returns a negative amount, no side effects.
