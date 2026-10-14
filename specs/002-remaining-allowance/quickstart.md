# Quickstart: Validating Remaining Allowance

Prerequisites: Dart SDK ^3.5.0.

```bash
dart pub get
dart format .
dart analyze --fatal-infos
dart test test/remaining_allowance_test.dart
dart test
```

Expected: format and analyze are clean, and all tests pass, including the existing transfer and money tests.

Scenarios to confirm (see [contracts/remaining-allowance.md](contracts/remaining-allowance.md)):
1. Limit 1,000.00 EGP, sent 300.00 → remaining 700.00 EGP.
2. Sent exactly the limit → 0.00. One piaster over → 0.00.
3. Limit EGP, sent USD → `currencyMismatch`.
4. Negative sent → rejected, not `currencyMismatch`.
5. For a sample of `sentToday`, a transfer of exactly the remaining amount is not rejected by `validate()` for the daily limit, and one piaster more is (SC-004).
